package org.ovirt.engine.locks.generator

import java.io.File
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.nodemodel.ICompositeNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.ovirt.engine.locks.locks.Command
import org.ovirt.engine.locks.locks.Lock
import org.ovirt.engine.locks.locks.Scope
import org.ovirt.engine.locks.locks.Message

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class LocksGenerator implements IGenerator {
	private Resource resource;
	
	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		var path = 'org.ovirt.engine.core.bll.'.replaceAll('\\.', File.separator) + 'Locks.aj'
		fsa.generateFile(path, resource.compile)
	}

	def compile(Resource resource) {
		this.resource = resource
	'''
        package org.ovirt.engine.core.bll;

        import java.util.*;

        import org.aspectj.lang.annotation.BridgedSourceLocation;
        import org.ovirt.engine.core.common.action.LockProperties;
        import org.ovirt.engine.core.common.action.LockProperties.Scope;
        import org.ovirt.engine.core.common.locks.LockingGroup;
        import org.ovirt.engine.core.bll.CommandBase;
        import org.ovirt.engine.core.utils.lock.EngineLock;
        import org.ovirt.engine.core.common.utils.Pair;
        import org.ovirt.engine.core.common.action.VdcReturnValueBase;
        import org.ovirt.engine.core.common.businessentities.IVdsAsyncCommand;
        import org.ovirt.engine.core.common.errors.EngineMessage;

        public privileged aspect Locks {

            /** Infrastructure Code **/

            /** Acquire locks */
            boolean around(CommandBase commandBase): execution(* CommandBase.acquireLock()) && this(commandBase) {
                LockProperties lockProperties = commandBase.getLockProperties();
                boolean returnValue = true;
                if (!Scope.None.equals(lockProperties.getScope())) {
                    commandBase.releaseLocksAtEndOfExecute = Scope.Execution.equals(lockProperties.getScope());
                    if (!lockProperties.isWait()) {
                        returnValue = commandBase.acquireLockInternal();
                    } else {
                        commandBase.acquireLockAndWait();
                    }
                }
                return returnValue;
            }
	
            boolean around(CommandBase command): execution(* acquireLockInternal()) && this(command) {
                // if commandLock is null then we acquire new lock, otherwise probably we got lock from caller command.
                if (command.context.getLock() == null) {
                    EngineLock lock = command.buildLock();
                    if (lock != null) {
                        Pair<Boolean, Set<String>> lockAcquireResult = command.getLockManager().acquireLock(lock);
                        if (lockAcquireResult.getFirst()) {
                            command.log.info("Lock Acquired to object '{}'", lock);
                            command.context.withLock(lock);
                        } else {
                            command.log.info("Failed to Acquire Lock to object '{}'", lock);
                            command.getReturnValue().getValidationMessages()
                            .addAll(command.extractVariableDeclarations(lockAcquireResult.getSecond()));
                            return false;
                        }
                    }
                }
                return true;
            }

            void around(CommandBase command): execution(* acquireLockAndWait()) && this(command) {
                // if commandLock is null then we acquire new lock, otherwise probably we got lock from caller command.
                if (command.context.getLock() == null) {
                    Map<String, Pair<String, String>> exclusiveLocks = command.getExclusiveLocks();
                    if (exclusiveLocks != null) {
                        EngineLock lock = new EngineLock(exclusiveLocks, null);
                        command.log.info("Before acquiring and wait lock '{}'", lock);
                        command.getLockManager().acquireLockWait(lock);
                        command.context.withLock(lock);
                        command.log.info("Lock-wait acquired to object '{}'", lock);
                    }
                }
            }

            /** Release locks if validation fails */
            boolean around(CommandBase command): execution(* internalValidate()) && this(command) {
                boolean result = false;
                try {
                   result = proceed(command);
                }
                finally {
                   if (!result) {
                      command.freeLock();
                   }
                }
                return result;
            }

            /** How to release locks */
            void around(CommandBase command): execution(* freeLock()) && this(command) {
                if (command.context.getLock() != null) {
                    command.getLockManager().releaseLock(command.context.getLock());
                    command.log.info("Lock freed to object '{}'", command.context.getLock());
                    command.context.withLock(null);
                    // free other locks here to guarantee they will be freed only once
                    command.freeCustomLocks();
                }
            }

            /** Release locks after the synchronous phase */
            VdcReturnValueBase around(CommandBase command): execution(* executeAction()) && this(command) {
                try {
                   return proceed(command);
                }
                finally {
                   command.freeLockExecute();
                }
            }

            /** Release locks after the asynchronous phase */
            void around(CommandBase command): execution(* endActionInTransactionScope()) && this(command) {
                try {
                   proceed(command);
                }
                finally {
                   command.freeLockEndAction();
                }
            }

            /** Acquire locks for the asynchronous part */
            VdcReturnValueBase around(CommandBase commandBase): execution(* endAction()) && this(commandBase) {
                VdcReturnValueBase result = null;
                try {
                    commandBase.initiateLockEndAction();
                    result = proceed(commandBase);
                } finally {
                    commandBase.freeLockEndAction();
                }
                return result;
            }

            private void CommandBase.freeLockExecute() {
                if (releaseLocksAtEndOfExecute || !getSucceeded() ||
                        (noAsyncOperations() && !(this instanceof IVdsAsyncCommand))) {
                    freeLock();
                }
            }

            /**
             * If the command has more than one task handler, we can reach the end action
             * phase and in that phase execute the next task handler. In that case, we
             * don't want to release the locks, so we ask whether we're not in execute state.
             */
            private void CommandBase.freeLockEndAction() {
                if (getActionState() != CommandActionState.EXECUTE) {
                    freeLock();
                }
            }

            /**
             * The following method should initiate a lock , in order to release it at endAction()
             */
            private void CommandBase.initiateLockEndAction() {
                if (context.getLock() == null) {
                    LockProperties lockProperties = getLockProperties();
                    if (Scope.Command.equals(lockProperties.getScope())) {
                        context.withLock(buildLock());
                    }
                }
            }

            private EngineLock CommandBase.buildLock() {
                EngineLock lock = null;
                Map<String, Pair<String, String>> exclusiveLocks = getExclusiveLocks();
                Map<String, Pair<String, String>> sharedLocks = getSharedLocks();
                if (exclusiveLocks != null || sharedLocks != null) {
                    lock = new EngineLock(exclusiveLocks, sharedLocks);
                }
                return lock;
            }

            /** Command Locks **/

        «FOR command:resource.allContents.filter(typeof(Command)).toIterable»
            /** «command.type.qualifiedName» **/
            «command.compile»
        «ENDFOR»
        }
	'''
	}

	def compile(Command command)
	'''
    «NodeModelUtils.getNode(command).toSourcePosition»
    LockProperties around(LockProperties lockProperties, «command.type.qualifiedName» command): execution(* applyLockProperties(..)) && args(lockProperties) && target(command) {
        return lockProperties«command.scope.compile»«command.isWait.compile»;
    }

    «IF NodeModelUtils.getNode(command.exclusiveLocks) != null»
        «NodeModelUtils.getNode(command.exclusiveLocks).toSourcePosition»
        Map<String, Pair<String, String>> around(«command.type.qualifiedName» command): execution(* getExclusiveLocks()) && target(command) {
            Map<String, Pair<String, String>> locks = new HashMap<String, Pair<String, String>>();

            «FOR lock:command.exclusiveLocks.locks»
                «lock.compile(command)»
            «ENDFOR»

            return locks;
        }
    «ENDIF»

    «IF NodeModelUtils.getNode(command.sharedLocks) != null»
        «NodeModelUtils.getNode(command.sharedLocks).toSourcePosition»
        Map<String, Pair<String, String>> around(«command.type.qualifiedName» command): execution(* getSharedLocks()) && target(command) {
            Map<String, Pair<String, String>> locks = new HashMap<String, Pair<String, String>>();

            «FOR lock:command.sharedLocks.locks»
               «lock.compile(command)»
            «ENDFOR»

            return locks;
        }
    «ENDIF»

	'''

	def compile(Lock lock, Command command)
	'''
	   «IF lock.isConditional»if (command.«lock.condition.simpleName»())«ENDIF»
       locks.put(command.«lock.id.simpleName»().toString(),
           LockMessagesMatchUtil.makeLockingPair(LockingGroup.«lock.group.simpleName»,
            «IF command.message != null»«command.message.compile»«ELSE»EngineMessage.ACTION_TYPE_FAILED_OBJECT_LOCKED«ENDIF»));
	'''

	def compile(Scope scope)
	'''.withScope(Scope.«IF scope == Scope.ASYNC»Command«ELSEIF scope == Scope.SYNC»Execution«ELSE»None«ENDIF»)'''

	def compile(boolean wait)
	'''.withWait(«IF wait»true«ELSE»false«ENDIF»)'''

    def compile(Message message)
    '''"«message.type.simpleName»"«FOR v:message.vars»+"$«v.key» "+command.«v.value.simpleName»()«ENDFOR»'''

	def toSourcePosition(ICompositeNode node)
	'''@BridgedSourceLocation(line=«node.startLine», file="«resource.URI.toPlatformString(true)»", module="ovirt.locks")'''
}

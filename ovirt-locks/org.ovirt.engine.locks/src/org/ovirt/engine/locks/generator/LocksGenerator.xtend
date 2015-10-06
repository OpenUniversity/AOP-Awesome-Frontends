/*
 * generated by Xtext
 */
package org.ovirt.engine.locks.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.nodemodel.ICompositeNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.ovirt.engine.locks.locks.Command
import org.ovirt.engine.locks.locks.Lock
import org.ovirt.engine.locks.locks.Scope

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class LocksGenerator implements IGenerator {
	private Resource resource;
	
	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		this.resource = resource
		fsa.generateFile("org/ovirt/engine/core/bll/Locks.aj",
			'''
				package org.ovirt.engine.core.bll;
				
				import java.util.*;
				import org.openu.awesome.platform.SourcePosition;
				import org.ovirt.engine.core.common.action.LockProperties;
				import org.ovirt.engine.core.common.action.LockProperties.Scope;
				import org.ovirt.engine.core.common.locks.LockingGroup;

				public privileged aspect Locks {
					«FOR command:resource.allContents.filter(typeof(Command)).toIterable»
						«command.compile»
					«ENDFOR»
				}
			'''
		)
	}

	def compile(Command command) '''
		«NodeModelUtils.getNode(command).toSourcePosition»
		LockProperties around(LockProperties lockProperties): execution(* applyLockProperties(lockProperties)) {
			return lockProperties«command.scope.compile»«command.isWait.compile»;
		}

		«NodeModelUtils.getNode(command.exclusiveLocks).toSourcePosition»
		Map<String, Pair<String, String>> around(«command.type.qualifiedName» command): execution(* getExclusiveLocks()) && target(command) {
	        MapMap<String, Pair<String, String>> locks = new HashMapMap<String, Pair<String, String>>();

	        «FOR lock:command.exclusiveLocks.locks»
	        	«lock.compile»
	        «ENDFOR»

			return locks;
	    }
	
		«NodeModelUtils.getNode(command.sharedLocks).toSourcePosition»
	    Map<String, Pair<String, String>> around(«command.type.qualifiedName» command)): execution(* getSharedLocks()) && target(command) {
	        MapMap<String, Pair<String, String>> locks = new HashMapMap<String, Pair<String, String>>();

	        «FOR lock:command.sharedLocks.locks»
	        	«lock.compile»
	        «ENDFOR»

	        return locks;
	    }
    	
	'''
	
	def compile(Lock lock) '''
		locks.put(command.«lock.id.simpleName»(),
			LockMessagesMatchUtil.makeLockingPair(LockingGroup.«lock.group.simpleName», command.«lock.message.simpleName»()));
	'''
	
	def compile(Scope scope)
	'''.withScope(Scope.«IF scope == Scope.COMMAND»Command«ELSEIF scope == Scope.EXECUTION»Execution«ELSE»None«ENDIF»)'''
	
	def compile(boolean wait)
	'''.withWait(«IF wait»true«ELSE»false«ENDIF»)'''

	def toSourcePosition(ICompositeNode node) '''
		@SourcePosition(startLine=«node.startLine», endList=«node.endLine», offset=«node.offset», endOffset=«node.endOffset», file=«resource.URI.path»)
	'''
}

/*
 * generated by Xtext 2.9.0
 */
package com.mucommander.auditing.generator

import java.io.File
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import com.mucommander.auditing.auditLog.Command
import org.eclipse.xtext.nodemodel.ICompositeNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import com.mucommander.auditing.auditLog.Case
import com.mucommander.job.FileJobState
import com.mucommander.auditing.auditLog.State
import org.eclipse.xtext.common.types.JvmField

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class AuditLogGenerator extends AbstractGenerator {
	private Resource resource;

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		var path = 'com.mucommander.job.'.replaceAll('\\.', File.separator) + 'Logs.aj'
		fsa.generateFile(path, resource.compile)
	}

	def compile(Resource resource) {
		this.resource = resource;
		'''
		    package com.mucommander.job;

		    import org.aspectj.lang.annotation.BridgedSourceLocation;

		    public privileged aspect Logs {
		      «FOR command:resource.allContents.filter(typeof(Command)).toIterable»
		        «command.compile»
		      «ENDFOR»
		      
		      private void audit(AuditLogMessage msg) {
		      		System.out.println(msg);
		      }
		    }

		'''
	}

	def compile(Command command) '''
	
	     «FOR acase:command.cases»
	     «IF command.cases.exists[c|c.state == State.START]»
	     «NodeModelUtils.getNode(command).toSourcePosition»
	     after(«command.type.qualifiedName» job): execution(void start()) && this(job) {
	       «FOR start:command.cases.filter[c|c.state == State.START]»
	         «start.compile»
	       «ENDFOR»
	     }
	     «ENDIF»
	     «IF command.cases.exists[c|c.state == State.FINISH || c.state == State.INTERRUPT]»
	     «NodeModelUtils.getNode(command).toSourcePosition»
	     after(«command.type.qualifiedName» job): execution(void run()) && this(job) {
	       if (job.getState() == FileJobState.INTERRUPTED) {
	         «FOR interrupt:command.cases.filter[c|c.state == State.INTERRUPT]»
	           «interrupt.compile»
	         «ENDFOR»
	       } else {
	         «FOR finish:command.cases.filter[c|c.state == State.FINISH]»
	           «finish.compile»
	         «ENDFOR»
	       }
	     }
	     «ENDIF»
      «IF command.cases.exists[c|c.state == State.PAUSE || c.state == State.RESUME]»
	     «NodeModelUtils.getNode(command).toSourcePosition»
	     after(«command.type.qualifiedName» job): execution(void setPaused(boolean)) && this(job) {
	     	 if (job.getState() == FileJobState.PAUSED) {
	     	   «FOR pause:command.cases.filter[c|c.state == State.PAUSE]»
	     	     «pause.compile»
	     	   «ENDFOR»
	       } else {
	         «FOR resume:command.cases.filter[c|c.state == State.RESUME]»
	           «resume.compile»
	         «ENDFOR»
	       }
	     }
	     «ENDIF»
	     «ENDFOR»
			   
	'''

 def compile(Case acase) '''
	         if (true«FOR field:acase.fields»«field.compile»«ENDFOR») {
	           audit(AuditLogMessage.«acase.msg.simpleName»);
	           return;
	         }
 '''

 def compile(JvmField field)
 ''' && command.«field.simpleName»'''

	def toSourcePosition(ICompositeNode node)
	'''@BridgedSourceLocation(line=«node.startLine», file="«resource.URI.toPlatformString(true)»", module="jobs.audit")'''
}
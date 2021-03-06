package com.mucommander.auditing.generator

import com.mucommander.auditing.auditLog.Case
import com.mucommander.auditing.auditLog.Command
import com.mucommander.auditing.auditLog.State
import com.mucommander.job.AuditLogMessage
import java.io.File
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.common.types.JvmFeature
import org.eclipse.xtext.common.types.JvmField
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.nodemodel.ICompositeNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

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

		    import org.aspectj.lang.annotation.*;

      @HideType
		    public privileged aspect Logs {
		      «FOR command:resource.allContents.filter(typeof(Command)).toIterable»
		        «command.compile»
		      «ENDFOR»

        @HideMethod
		      private void audit(String msg, Object... args) {
		      		System.out.println(
		      		new java.text.SimpleDateFormat("yyyy/MM/dd HH:mm:ss ").format(new java.util.Date()) +
		      		java.text.MessageFormat.format(msg, args));
		      }
		    }

		'''
	}

	def compile(Command command) '''
	
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
			   
	'''

 def compile(Case acase) '''
	         if (true«FOR field:acase.fields»«field.compile»«ENDFOR») {
	           audit("«AuditLogMessage.valueOf(acase.msg.simpleName).toString»"«FOR variable:acase.vars»«variable.compileVar»«ENDFOR»);
	           return;
	         }
 '''

 def compile(JvmField field)
 ''' && job.«field.simpleName»'''

 def compileVar(JvmFeature field)
 ''', job.«field.simpleName»'''

	def toSourcePosition(ICompositeNode node)
	'''@BridgedSourceLocation(line=«node.startLine», file="«resource.URI.toPlatformString(true)»", module="jobs.audit")'''
}

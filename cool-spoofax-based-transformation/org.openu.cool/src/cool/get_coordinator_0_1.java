package cool;

import org.strategoxt.stratego_lib.*;
import org.strategoxt.java_front.*;
import org.strategoxt.stratego_gpp.*;
import org.strategoxt.stratego_sglr.*;
import org.strategoxt.lang.*;
import org.spoofax.interpreter.terms.*;
import static org.strategoxt.lang.Term.*;
import org.spoofax.interpreter.library.AbstractPrimitive;
import java.util.ArrayList;
import java.lang.ref.WeakReference;

@SuppressWarnings("all") public class get_coordinator_0_1 extends Strategy 
{ 
  public static get_coordinator_0_1 instance = new get_coordinator_0_1();

  @Override public IStrategoTerm invoke(Context context, IStrategoTerm term, IStrategoTerm g_23)
  { 
    context.push("get_coordinator_0_1");
    Fail140:
    { 
      term = getfirst_1_0.instance.invoke(context, g_23, lifted7.instance);
      if(term == null)
        break Fail140;
      context.popOnSuccess();
      if(true)
        return term;
    }
    context.popOnFailure();
    return null;
  }
}
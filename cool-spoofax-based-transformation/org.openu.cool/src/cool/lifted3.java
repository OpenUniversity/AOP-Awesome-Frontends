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

@SuppressWarnings("all") final class lifted3 extends Strategy 
{ 
  public static final lifted3 instance = new lifted3();

  @Override public IStrategoTerm invoke(Context context, IStrategoTerm term)
  { 
    Fail207:
    { 
      IStrategoTerm term103 = term;
      Success131:
      { 
        Fail208:
        { 
          term = aspectj_to_box_0_0.instance.invoke(context, term);
          if(term == null)
            break Fail208;
          if(true)
            break Success131;
        }
        term = java_to_box_0_0.instance.invoke(context, term103);
        if(term == null)
          break Fail207;
      }
      if(true)
        return term;
    }
    return null;
  }
}
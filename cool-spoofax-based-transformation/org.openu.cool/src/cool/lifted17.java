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

@SuppressWarnings("all") final class lifted17 extends Strategy 
{ 
  TermReference p_26;

  @Override public IStrategoTerm invoke(Context context, IStrategoTerm term)
  { 
    Fail191:
    { 
      IStrategoTerm a_27 = null;
      if(term.getTermType() != IStrategoTerm.APPL || transform._consMethodAdditions_4 != ((IStrategoAppl)term).getConstructor())
        break Fail191;
      a_27 = term.getSubterm(0);
      if(p_26.value == null)
        break Fail191;
      term = hashtable_put_0_2.instance.invoke(context, p_26.value, a_27, a_27);
      if(term == null)
        break Fail191;
      if(true)
        return term;
    }
    return null;
  }
}
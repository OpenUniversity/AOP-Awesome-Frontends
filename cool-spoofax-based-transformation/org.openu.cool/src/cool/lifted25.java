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

@SuppressWarnings("all") final class lifted25 extends Strategy 
{ 
  TermReference v_28;

  @Override public IStrategoTerm invoke(Context context, IStrategoTerm term)
  { 
    ITermFactory termFactory = context.getFactory();
    Fail186:
    { 
      IStrategoTerm r_29 = null;
      r_29 = term;
      term = gen_method_state_name_0_1.instance.invoke(context, r_29, v_28.value);
      if(term == null)
        break Fail186;
      term = termFactory.makeAppl(transform._consInvoke_2, new IStrategoTerm[]{cool.constMethod5, (IStrategoTerm)termFactory.makeListCons(termFactory.makeAppl(transform._consExprName_1, new IStrategoTerm[]{termFactory.makeAppl(transform._consId_1, new IStrategoTerm[]{term})}), (IStrategoList)cool.constNil0)});
      if(true)
        return term;
    }
    return null;
  }
}


import farcek.Parser;
import farcek.Parser as P;

enum SExp {
  NilExp;
  SymbolExp(s:String);
  StringExp(s:String);
  NumberExp(n:Float);
  ConsExp(head:SExp, tail:SExp);  
}

class SExpParse {

  public var parser : Parser<SExp>;

  public function new () {
    var nilExp = P.bracket(P.char("("),P.spaces(),P.char(")")).then(P.result(NilExp));

    var legalOpSymbols = "!@#$%^*-+/<>?";
    
    var opSymbol = P.oneOf( legalOpSymbols ).many1().fmap( function (a) {
	return SymbolExp( a.join("") );
      });
    
    // varSymbol must start with letter
    var varSymbol = P.letter().bind( function (l) {
	return P.alphanum().or( P.oneOf(legalOpSymbols) ).many().fmap( function (ln) {
	    return SymbolExp( l + ln.join("") );
	  });
      });

    var symbolExp = opSymbol.or( varSymbol );

    var notQuote = function (s:String) {return s.charAt(0) != '"';};
    
    var stringExp = P.bracket(P.char('"'),
			      P.sat( notQuote ).many(),
			      P.char('"')).fmap(function (a) {
				  return StringExp(a.join(""));
				});

    var numberExp = P.digit().many1().bind(function (ds) {
	return P.char('.').then(P.digit().many1()).ornot().fmap(function (mds) {
	    return switch (mds) {
	    case None: {
	      NumberExp( Std.parseFloat( ds.join("")) );
	    }
	    case Some( ds2 ): {
	      NumberExp( Std.parseFloat( ds.join("") + "." + ds2.join("") ));
	    }
	    };
	  });
      });

    var atomExp = P.choice([nilExp,symbolExp,stringExp,numberExp]);

    var consing = function (exps : Array<SExp>) {
      var e = NilExp;
      while (exps.length > 0) e = ConsExp(exps.pop(), e);
      return e;
    };

    var open = P.spaceBracket(P.char('('));
    var close = P.spaceBracket(P.char(')'));
    
    var consExp = P.nested(open,close,P.spaceBracket(atomExp),consing);
    
    parser = atomExp.or(consExp);
  }

  public static function main () {

    var p = new SExpParse();

    trace(P.run( p.parser, "()"));
    trace(P.run( p.parser, "33.45"));
    trace(P.run( p.parser, "33"));    
    trace(P.run( p.parser, "cool"));
    trace(P.run( p.parser, '"cool"'));
    trace(P.run( p.parser, "(1 2 3)"));
    trace(P.run( p.parser, "(1 (a b) 3)"));
    trace(P.run( p.parser, '((1) (a b) 3 "tres cool")'));
    trace(P.run( p.parser, '(())'));

  }


}





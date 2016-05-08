package farcek;

import haxe.ds.Option;
import haxe.ds.Either;

using Lambda; 

/**

The Parsed type contains the state of a successful parse.  It is a
type alias for `{parsed: A, leftOver: String}`

**/

enum ParseError {
  NoParseAt( s : String );
  EmptyParse;
}

typedef Parsed<A> = {parsed : A, leftOver : String}

class Parser<A> {

  private var parser : String -> Array<Parsed<A>>;

  /**
     
     `parse( s )` returns an array containing every valid parse of its
     input `s`. 

     Most of the time you do not need to use this method, and should
     probably use [Parser.run](#run) instead.

  **/
  
  public function parse(s) {
    return parser(s);
  }

  /**
     
     Hopefully you never need to manually instantiate a parser.
     `farcek` provides a number of utility methods for "building up"
     complex parsers from simple parts.

  **/
  
  public function new (p : String -> Array<Parsed<A>>) {
    parser = p;
  }

  /**
     
     `strict` is used when you desire throw an error on a failed parse
     at a point.  The error is an enum:

     `NoParseAt( s : String)` 

     where `s` is the offending string.  This is useful for getting
     some feedback about where in your parse string you went wrong.

     It should be noted that the `strict` parse is not always
     desirable.  For instance doing
     `myparser.strict().or( myotherparser )` is generally a bad idea.
     If `myparser` fails an error will be thrown instead of moving on
     to `myotherparser` as expected.  It would be better to do:

     `myparser.or( myotherparser ).strict()`, which will ensure that
     an error is thrown when neither parser parses.  Even so, `strict`
     should be used with caution.
     


   **/

  public function strict () : Parser<A> {
    var that = this;
    return new Parser(function (s) {
	var results = that.parse( s );
	if (results.length == 0) throw NoParseAt( s );
	return results;
      });
  }
  
  /**

     The `bind` method is the bread and butter of so-called "monadic"
     parsing.  `bind` is what lets us build up complex parsers by
     allowing the results of earlier parsers to affect the context in
     which future parsers operate.  

     If `f` has type `A -> Parser<B>`, then calling `this.bind( f )`
     returns a `Parser<B>`.  

     Another way to think about it is that, using `bind`, we can
     create new parsers that depend on the results of other parsers.

     [feedTo](#feedTo) is an alias for `bind`

   **/
  
  public function bind<B> (f : A -> Parser<B>) : Parser<B> {
    return new Parser(function (s) {
	var results = [];
	for (p in parse(s))
	  results = results.concat ( (f(p.parsed)).parse (p.leftOver) );
	return results;
      });
  }

  /**

     An alias for [bind](#bind).

   **/
  
  
  public function feedTo (f) {return bind( f );}

  /**

     `then` is like `bind` except that it ignores the result of `this`
     parser and simply moves along to the next parser.  It is useful
     for chaining parsers.

     For example, `Parser.string("this").then(Parser.string("works"))`
     will parse the string `"thisworks"` and return the string
     `"works"`.

   **/
  
  public function then<B> ( p : Parser<B>) : Parser<B> {
    return bind(function (a) {return p;});
  }

  /**
     `or` is an alias for [plus](#plus).
   **/
  public function or (p2) {return plus(p2);}

  /**

     The `plus` method lets you provide alternates to your parser.
     
     `P.run( a.plus( b ), mystring)` will first attempt to parse
     `mystring` with `a`. If the parse fails, then `mystring` will be
     fed instead to `b`.

     E.g.

     `Parser.string("a").plus( Parser.string("an") )` will parse
     either English indefinite article.

     

   **/
  
  public function plus (p2: Parser<A>) : Parser<A> {
    var that = this;
    return new Parser(function (s) {
	return that.parse(s).concat( p2.parse(s) );
      });
  }


  /**
     `lazyPlus` is like `plus` except that it accepts a thunk instead
     of a parser, and only evaluates if `this` parse returned no
     results.

   **/

  public function lazyPlus (thunk: Void -> Parser<A>) : Parser<A> {
    return new Parser(function (s) {
	var res = this.parse(s);
	if (res.length > 0) return res;
	return thunk().parse(s);
      });
  }
  
  /**

     The `many` method will run `this` parser zero or more times and
     return an array of the results.

   **/
  
  public function many () : Parser<Array<A>> {
    var rep = bind( function ( r ) {
	return many().bind(function ( rs ) {
	    return result([r].concat( rs ));
	  });
      });
    return rep.plus( result( [] ));
  }

  /**

     `many1` is like [many](#many) except that it fails if `this`
     cannot parse the input at least once.

   **/
  
  public function many1 () : Parser<Array<A>> {
    return bind(function (r) {
	return many().bind(function (rs) {
	    return result([r].concat(rs));
	  });
      });
  }

  /**
     Makes `this` parser optional, and returns `None` in the case that
     the parser does not accept the current input. Otherwise, if
     `this` would have parsed and returned an `a`, `this.ornot()` will
     parse and return a `Some(a)`.
     
   **/

  public function ornot () : Parser<Option<A>> {
    return fmap(function (r) {
	return Some(r);
      }).orelse(None);
  }
  
  /**

     The `fmap` method transforms the output of a successful parse.

   **/
  
  public function fmap<B>  (f : A -> B) : Parser<B> {
    return bind(function (a) {return result( f( a ));});
  }

  /**

     `this.tryWithDefault(v)` will simply return a parser that returns
     `v` if `this` fails.  Its implementation uses [plus](#plus) and
     [result](#result).

   **/
  
  public function tryWithDefault (v : A) : Parser<A> {
    return plus( result( v ));
  }

  /**

     An alias for [tryWithDefault](#orelse).

   **/

  public function orelse (v : A) {return tryWithDefault( v );}
  
  // static utility functions


  /** 
      
      `Parser.result( x )` will succeed for every string, consuming no
      input, and will always return `x`.  At first look this may not
      seem very useful, but simple combinator allows us to inject
      results into our large, complex parsers.

      Here is an example:

      `var one = Parser.string( "one" ).then( Parser.result( 1 ));`

      The `one` parser will parse the string one, and upon doing so,
      will parse nothing at all to return the integer `1`.

   **/
  public static function result<B> (v : B) : Parser<B> {
    return new Parser(function (s) {
	return [{parsed : v, leftOver : s}];
      });
  }

  public static function zero<B> () : Parser<B> {
    return new Parser(function (s) {
	return [];
      });
  }

  /**
     
     The `item` combinator returns a _wildcard_ parser, that accepts
     and returns any character.

   **/
  
  public static function item () : Parser<String> {
    return new Parser(function (s) {
	return if (s == "") []
	  else [ {parsed : s.charAt(0) , leftOver : s.substr(1)} ];
      });
  }

  /**
     
     The `sat( p )` combinator accepts and returns a character `c` for
     which `p( c )` is `True`.

   **/
  
  public static function sat (p : String -> Bool) : Parser<String> {
    return item().bind(function (c) {
	return if (p( c )) result( c ) else zero();
      });
  }

  /**
     
     The `oneOf` combinator allows us to specify a class of characters
     by providing a string. `oneOf("abcd")` for example will parse any
     of `"a"`, `"b"`, `"c"`, or `"d"`.

   **/
  
  public static function oneOf (s : String) : Parser<String> {
    return sat(function (c) {return s.indexOf(c) > -1;});
  }

  /**

     The `choice` combinator is a short cut for a chain of
     [plus](#plus)es.  

   **/
  
  // assumes that a.length > 0
  public static function choice<B> (a : Array<Parser<B>>) : Parser<B> {
    var f = a.shift();
    for (p in a) f = f.plus(p);
    return f;
  }

  /**

     `choiceWithDefault(a,b)` is a shortcut for a
     `choice(a).tryWithDefault(b)`.  

     See [choice](#choice) and [tryWithDefault](#tryWithDefault) for
     more.

   **/
  
  public static function choiceWithDefault<B> (a : Array<Parser<B>>,
					       b : B) : Parser<B> {
    return choice( a ).tryWithDefault( b );
  }

  /**

     `stringChoice( a )` will parse any one of the strings provided in
     the array `a`.

   **/
  
  public static function stringChoice (a : Array<String>) : Parser<String> {
    return choice( a.map( Parser.string ));
  }

  /**

     The `char( c )` combinator will parse the character `c`.

   **/
  
  public static function char (c : String) : Parser<String> {
    return sat(function (c1) {return c1 == c;});
  }

  private static var digits = ['0','1','2','3','4','5','6','7','8','9'];

  /**

     The `digit()` method returns a parser that accepts any numeric
     digit.

   **/

  public static function digit () : Parser<String> {
    return sat(function (c) {
	return digits.indexOf(c) > -1;
      });
  }

  /**

     The `lower()` method returns a parser that accepts any lowercase
     ascii character.

   **/
  
  public static function lower () : Parser<String> {
    return sat(function (c) {
	var code = c.charCodeAt(0);
	return code >= ("a".charCodeAt(0)) && code <= ("z".charCodeAt(0));
      });
  }

  /**

     The `upper()` method returns a parser that accepts any uppercase
     ascii character.

   **/
  
  public static function upper () : Parser<String> {
    return sat(function (c) {
	var code = c.charCodeAt(0);
	return code >= ("A".charCodeAt(0)) && code <= ("Z".charCodeAt(0));
      });
  }

  /**

     The `letter()` method returns a parser that accepts any
     alphabetic ascii letter character.

   **/
  
  public static function letter () : Parser<String> {
    return upper().plus(lower());
  }

  /**
     The `alphanum()` method returns a parser that accepts any
     alphanumeric ascii character.

   **/
  
  public static function alphanum () : Parser<String> {
    return letter().plus(digit());
  }

  /**

     The `word()` method returns a parser that accepts and returns any
     string of letters.

   **/
  
  public static function word () : Parser<String> {
    var neWord = letter().bind(function (l) {
	return word().bind(function (ls) {
	    return result(l + ls);
	  });
      });
    return neWord.plus(result(""));
  }

  /**

     Calling the `string( s )` method returns a parser that accepts
     and returns the string `s`.

   **/
  
  public static function string (t : String) : Parser <String> {
    return if (t == "") result("")
      else char(t.charAt(0)).bind(function (a) {
	  return string(t.substr(1)).bind(function (b) {
	      return result(t);
	    });
	});
  }

  /**
     
     The `spaces()` method returns a parser that accepts zero or more
     space characters. This DOES NOT include tabs or newlines.

   **/
  
  public static function spaces () : Parser<String> {
    return char(" ").many().fmap(function (s) {return s.join("");});
  }


  /**

     The `bracket` combinator allows us to run a parser on some input
     that is delimited in some way.

     `Parser.bracket( l, p, r)` is a parser that returns the value of
     `p`, delimited on the left by `l` and on the right by `r`

   **/
  
  public static function bracket<B> (o : Parser<String>,
				     i : Parser<B>,
				     c : Parser<String>) : Parser<B> {

    return o.bind(function (o1) {
	return i.bind(function (i1) {
	    return c.bind(function (c1) {
		return result(i1);
	      });
	  });
      });
  }

  /**

     `spaceBracket( i )` is is a shortcut for `bracket(spaces(), i, spaces())`

     See [bracket](#bracket)

   **/
  
  public static function spaceBracket<B> (i : Parser<B>) : Parser<B> {
    return bracket( spaces(), i, spaces());
  }

  /**

     `chainOpLeft( values, operator)` accepts a sequence of `value`s
     separated by `operator`s.  Here, `operator` returns a left
     associative operation which is used to combine the values
     returned by `value` parses.

     If you want the right associative version, see
     [chainOpRight](#chainOpRight)

   **/
  
  public static function chainOpLeft<B> (b : Parser<B>,
					 o : Parser<B -> B -> B>) : Parser<B> {
    var manyOps = o.bind(function (op) {
	return b.bind(function (b1) {
	    return result( op.bind(_, b1));
	  });
      }).many();

    return b.bind(function (b0) {
	return manyOps.bind(function (ps) {
	    var res = b0;
	    for (p in ps) res = p(res);
	    return result(res);
	  });
      });
  }

  /**

     `chainOpRight` is the right associative version of
     [chainOpLeft](#chainOpLeft)

   **/
  
  public static function chainOpRight<B> (b : Parser<B>,
					  o : Parser<B -> B -> B>) : Parser<B> {
    var manyOps = b.bind(function (b1) {
	return o.bind(function (op) {
	    return result( op.bind(b1) );
	  });
      }).many();

    return manyOps.bind(function (ops) {
	return b.bind(function (b1) {
	    var res = b1;
	    ops.reverse();
	    for (op in ops) res = op(res);
	    return result(res);
	  });
      });
  }


  /**

     `sepBy( b, sep )` accepts a sequence of one or more `b`'s
     separated by `sep`s, and returns an array of the `b`'s returned
     values

   **/

  public static function sepBy<B> (b : Parser<B>,
				   sep : Parser<String>) : Parser<Array<B>> {
    var tail = sep.then(b).many();
    return b.bind(function (b1) {
	return tail.bind(function (a) {
	    a.unshift( b1 );
	    return result(a);
	  });
      });
  }


  /**
     
     Accepts a string and a value and creates a parser that returns
     the given value on successful parse of the provided string.

   **/

  public static function stringTo<B> (s : String, b : B) : Parser<B> {
    return string( s ).then( result( b ) );
  }

  /**
     The argument `a` must be of length greater than 1.

     The homogeneous sequence combinator.  Given an array of parsers
     of the same type, it returns a parser that will parse each in
     sequence, returning the value parsed by the last parser.  

     Essentially just a shortcut for a sequence of [then](#then)'s.
    
   **/
  
  public static function homSeq<B> (a : Array<Parser<B>> ) : Parser<B> {
    var f = a.shift();
    for (p in a) f = f.then(p);
    return f;
  }

  /**
     an alias for `homSeq`
   **/

  public static function seq<B> (a : Array<Parser<B>>) : Parser<B> {
    return homSeq( a );
  }
  
  /**

     `nested` makes use of `lazyPlus` to facilitate nested parses.

     A nested parse begins with a parse according to `o`. Next, zero
     or more *p* or recursive alls to `nested` are parsed until a `c`
     is parsed.  At that point the collected `Z` are combined with
     `comb`.  

   **/

  public static function nested<Z> (o: Parser<String>, c: Parser<String>,
				    p: Parser<Z>, comb: Array<Z> -> Z) :Parser<Z> {
    var rec = function () { return nested(o,c,p,comb);};
    
    var closer = function (ignore) {
      return p.lazyPlus(rec).many().bind(function (az) {
	  return c.then(result( comb(az)));
	});
    };

    return o.bind(closer);
    
  }

  
  /**
     Just a helper function that takes a word and wraps it in a called
     to `spaceBracket`.  Handy for defining keywords.

   **/

  public static function kwd (s : String) : Parser<String> {
    return spaceBracket( string( s ) );
  }

  /**

     When one of several keywords will do.  `altKwds` wraps a call to
     `stringChoice` in  a `spaceBracket`.  See `kwd` too.

   **/

  public static function altKwds (a : Array<String>) : Parser<String> {
    return spaceBracket( stringChoice( a ) );
  }
  
  /**

     A convenience method to run a parser on a string and return its
     the value of its first successful parse.

   **/
  
  public static function run<B> (p : Parser<B>, s : String) : Option<B> {
    var res = p.parse(s);
    return if (res.length == 0 /*|| res[0].leftOver.length > 0 */) None
      else Some(res[0].parsed);
  }


  public static function runE<B> (p : Parser<B>, s : String) : Either<ParseError,B> {
    try {
      var res = p.parse( s );
      return if (res.length == 0) Left( EmptyParse ) else Right( res[0].parsed );
    } catch (e : ParseError) {
      return Left( e );
    }
  }
}

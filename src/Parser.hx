
import haxe.ds.Option;

typedef Parsed<A> = {parsed : A, leftOver : String}

class Parser<A> {

  var parser : String -> Array<Parsed<A>>;

  public function parse(s) {
    return parser(s);
  }

  public function new (p : String -> Array<Parsed<A>>) {
    parser = p;
  }

  public function bind<B> (f : A -> Parser<B>) : Parser<B> {
    return new Parser(function (s) {
	var results = [];
	for (p in parse(s))
	  results = results.concat ( (f(p.parsed)).parse (p.leftOver) );
	return results;
      });
  }

  public function plus (p2: Parser<A>) : Parser<A> {
    return new Parser(function (s) {
	return parse(s).concat( p2.parse(s) );
      });
  }

  public function many () : Parser<Array<A>> {
    var rep = bind(function (r) {
	return many().bind(function (rs) {
	    return result([r].concat(rs));
	  });
      });
    return rep.plus(result([]));
  }

  public function many1 () : Parser<Array<A>> {
    return bind(function (r) {
	return many().bind(function (rs) {
	    return result([r].concat(rs));
	  });
      });
  }

  public function fmap<B>  (f : A -> B) : Parser<B> {
    return bind(function (a) {return result( f( a ));});
  }

  // static utility functions

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

  public static function item () : Parser<String> {
    return new Parser(function (s) {
	return if (s == "") []
	  else [ {parsed : s.charAt(0) , leftOver : s.substr(1)} ];
      });
  }

  public static function sat (p : String -> Bool) : Parser<String> {
    return item().bind(function (c) {
	return if (p( c )) result( c ) else zero();
      });
  }

  public static function char (c : String) : Parser<String> {
    return sat(function (c1) {return c1 == c;});
  }

  private static var digits = ['0','1','2','3','4','5','6','7','8','9'];
  public static function digit () : Parser<String> {
    return sat(function (c) {
	return digits.indexOf(c) > -1;
      });
  }

  public static function lower () : Parser<String> {
    return sat(function (c) {
	var code = c.charCodeAt(0);
	return code >= ("a".charCodeAt(0)) && code <= ("z".charCodeAt(0));
      });
  }

  public static function upper () : Parser<String> {
    return sat(function (c) {
	var code = c.charCodeAt(0);
	return code >= ("A".charCodeAt(0)) && code <= ("Z".charCodeAt(0));
      });
  }

  public static function letter () : Parser<String> {
    return upper().plus(lower());
  }

  public static function alphanum () : Parser<String> {
    return letter().plus(digit());
  }

  public static function word () : Parser<String> {
    var neWord = letter().bind(function (l) {
	return word().bind(function (ls) {
	    return result(l + ls);
	  });
      });
    return neWord.plus(result(""));
  }

  public static function string (t : String) : Parser <String> {
    return if (t == "") result("")
      else char(t.charAt(0)).bind(function (a) {
	  return string(t.substr(1)).bind(function (b) {
	      return result(t);
	    });
	});
  }

  public static function spaces () : Parser<Array<String>> {
    return char(" ").many1();
  }

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


  public static function run<B> (p : Parser<B>, s : String) : Option<B> {
    var res = p.parse(s);
    return if (res.length == 0 || res[0].leftOver.length > 0) None
      else Some(res[0].parsed);
  }
  
}

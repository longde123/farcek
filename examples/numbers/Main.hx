
using Lambda;
import farcek.Parser as P;

class Main {

  public static function calc (s : String)  {
    // utility parsers //

    var natural = P.digit().many1().fmap(function (a) {
	return Std.parseInt( a.join("") );
      });

    var ones = P.choice([P.string("one").then(P.result(1)),
			 P.string("two").then(P.result(2)),
			 P.string("three").then(P.result(3)),
			 P.string("four").then(P.result(4)),
			 P.string("five").then(P.result(5)),
			 P.string("six").then(P.result(6)),
			 P.string("seven").then(P.result(7)),
			 P.string("eight").then(P.result(8)),
			 P.string("nine").then(P.result(9))
			 ]);
    
    var teens = P.choice([P.string("ten").then(P.result(10)),
			  P.string("eleven").then(P.result(11)),
			  P.string("twelve").then(P.result(12)),
			  P.string("thirteen").then(P.result(13)),
			  P.string("fourteen").then(P.result(14)),
			  P.string("fifteen").then(P.result(15)),
			  P.string("sixteen").then(P.result(16)),
			  P.string("seventeen").then(P.result(17)),
			  P.string("eighteen").then(P.result(18)),
			  P.string("nineteen").then(P.result(19)),
			  ]);
    
    var twenty = P.string("twenty").then(P.result(20));
    var thirty = P.string("thirty").then(P.result(30));
    var forty = P.string("forty").then(P.result(40));
    var fifty = P.string("fifty").then(P.result(50));
    var sixty = P.string("sixty").then(P.result(60));
    var seventy = P.string("seventy").then(P.result(70));
    var eighty = P.string("eighty").then(P.result(80));
    var ninety = P.string("ninety").then(P.result(90));

    var multOfTen = P.choice([twenty, thirty, forty, fifty,
			      sixty,  seventy, eighty, ninety]);
    
    var hyphenatedNumber = multOfTen.bind(function (m) {
	return P.string("-").then(ones).fmap(function (o) {
	    return m + o;
	  });
      });
    
    var number : Parser<Int> = P.choice([hyphenatedNumber,
					 multOfTen,
					 teens,
					 ones,
					 natural]);
    

    var spaceBracket = function (p) {
      return P.bracket(P.spaces(), p, P.spaces());
    };
    
    var times100 = P.result(function (n) {return n * 100;});
    var hundred = spaceBracket( P.string("hundred") ).then( times100 );
    var hundreds = number.bind(function (m) {
	return hundred.bind(function (hunds) {
	    return number.tryWithDefault(0).fmap(function (n) {
		return hunds(m) + n;
	      });
	  });
      });
    
    var times1000 = P.result(function (n) {return n * 1000;});
    var thousand = spaceBracket( P.string("thousand") ).then( times1000);
    
    var timesAMillion = P.result(function (n) {return n * 1000000;});
    var million = spaceBracket( P.string("million") ).then( timesAMillion );
    
    var timesABillion = P.result(function (n) {return n * 1000000000;});
    var billion = spaceBracket( P.string("billion") ).then( timesABillion );
    
    var identMult = P.result(function(n) {return n;});
    
    var multiplier = P.choice([thousand, million, billion, identMult]);
    
    var multipliedNumber = hundreds.plus(number).bind(function (n) {
	return multiplier.fmap(function (f) {return f( n );});
      });

    var fullNumber = multipliedNumber.many1().fmap(function (a) {
	return a.fold(function (m,n) {return m + n;}, 0);
      });

    return P.run( fullNumber, s);
  }

  public static function main () {
    var tryit = function (s, v) {
      trace("-------------------------------");
      switch ( calc( s )) {
      case Some( n ): {
	trace(s + " == " + Std.string(n));
	trace(n == v);
      }
      case None: trace("No Parse" );
      }
    };

    tryit("one", 1);
    tryit("22", 22);
    tryit("six", 6);
    tryit("sixteen", 16);
    tryit("sixty", 60);
    tryit("sixty-one", 61);
    tryit("three hundred fifteen", 315);
    tryit("three hundred fifteen thousand", 315000);
    tryit("seventy-two thousand seven hundred twenty-one", 72721);
    tryit("five million two hundred thirty-eight thousand nine hundred seventy-six", 5238976);
    tryit("four hundred million six hundred ninety-nine", 400000699);
    tryit("33 million 4 hundred sixteen thousand 1", 33416001);
  }
}
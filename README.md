# Farcek

*a small parser combinator library inspired by Parsec*

`farcek` is a Haxe-flavored homâge to Haskell's
[parsec](https://hackage.haskell.org/package/parsec), a monadic parser
comibinator library, and has been written to closely follow
[this paper](http://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf) by
Hutton and Meijer.  `farcek` lets the programmer define small
composible parsers that can return language level-values, making
`farcek` ideal for tasks like custom embedded scripting and string
validation.  The library prioritizes for ease of use over performance.

## a small example

In the following example, we create a small language for doing
additive arithmetic.
```haxe
   
import farcek.Parser;

class Main {
  public static function main () {
   
	// first we define our operators.

	var add = Parser.char("+").fmap(function (s) {
	    return function (x, y) {return x + y;};
	  });
	  
    // Lets break it down.  The Parser.char static method accepts
    // a single character string, and creates a parser that will
    // match that string.

	// Parser.char("+") will parse a "+" will return a "+". This
    // isn't very useful in itself, what we'd like is to interpret
    // the occurrance of a "+" as an addition operator.  The fmap
    // method maps the return value of a parser to a different
    // return value. In the above case, we map the string "+" to 
	// a function that accepts two numbers and adds them up.
	
	var sub = Parser.char("-").fmap(function (s) {
	    return function (x, y) {return x - y;};
      });
	  
    // Now we can combine the add and sub parsers into a single
    // parser that matches either one. We do this using the `plus`
    // method.
	
	var op = add.plus(sub);

    // Onward, matching natural numbers
		
	var natural = Parser.digit().many1().fmap(function (a) {
	    return Std.parseInt( a.join("") );
	  });
	  
    // Parser.digit is a convenience static method that returns a
    // parser that matches a single ascii digit.  The many1 method
    // returns a new parser that matches the initial parser (in
    // this case, a digit) several times and returns an array of
    // the matches.  Finally, we use fmap to turn the array 
    // of digit characters into an integer.
	
	var chain = Parser.chainOpLeft(natural, op);
	
	// chainOpLeft combines two parsers and returns a third.  
    // The resulting parser will match strings that begin and end with
	// the first parser, separated and combined with matches of the
	// second.  E.g. "1+3-4+5" will match, but "+4+3" will not.
	
	var subExpr = chain.plus(Parser.bracket(Parser.char("("),
	                                        chain,
										    Parser.char(")")));
										   
    // we want to match "1+2+4" as well as "(1+2+3)"
	
	var expr = Parser.chainOpLeft(subExpr, op);
	
	// that's it! now we can parse arithmetical strings!. The run
    // static method takes a parser and a string and returns an Option
	
	trace( Parser.run(expr, "1-(2-4)") );      // 3
	trace( Parser.run(expr, "1-2-4") );        // -5
	trace( Parser.run(expr, "4+5+(10-5)+1") ); // 15
	
  }
}

```

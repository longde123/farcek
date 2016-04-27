
A Parser for S-Expressions
===========================

Here is an example that parses strings like

```
((1) (a b) 3 "tres cool")
```

And returns parses that look like:

```haxe

ConsExp(ConsExp(NumberExp(1),
		NilExp),
	ConsExp(ConsExp(SymbolExp("a"),
			ConsExp(SymbolExp("b"),
				NilExp)),
		ConsExp(NumberExp(3),
			ConsExp(StringExp("tres cool"),
				NilExp))))

```

which are defined by the following little `enum`:

```haxe

enum SExp {
  NilExp;
  SymbolExp(s:String);
  StringExp(s:String);
  NumberExp(n:Float);
  ConsExp(head:SExp, tail:SExp);
}

```

The only interesting bit
------------------------

The only interesting part of this example involves the use of
`Parser.nested`.  Here is the chunk of code that uses `nested`:

```haxe
   // a parser for each of our atoms
    var atomExp = P.choice([nilExp,symbolExp,stringExp,numberExp]);

   // a function for combining arrays of expressions into a ConsExp
    var consing = function (exps : Array<SExp>) {
      var e = NilExp;
      while (exps.length > 0) e = ConsExp(exps.pop(), e);
      return e;
    };

    var open = P.spaceBracket(P.char('('));
    var close = P.spaceBracket(P.char(')'));
    
	// our call to nested
    var consExp = P.nested(open,close,P.spaceBracket(atomExp),consing);
    
```

Nested works by defining a thunk that contains a call to itself, using
the exact same arguments that you pass in.  In our case, it will then
parse an `open` followed by *either* zero or more `atomExp` *or* will
encounter another `open` and recurse.  Whenever a `close` is
encountered, the array of `atomExp`s already collected will be
combined using `consing` above. 




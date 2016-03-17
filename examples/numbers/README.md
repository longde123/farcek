## Number Parsing Example

Here is a parser that accepts strings like `"five million two hundred thirty-eight thousand nine hundred seventy-six"` returns the integer `5238976`.

To run the example code, just cd into this directory and do something like

```bash

haxe -cp ../../src -main Main -python main.py
python3 main.py


```

### Digging into the example

An educational use of the `bind` and `fmap` combinators occurs in the
`hyphenatedNumber` parser found on line 49 of the example. Its purpose
is to accept a word like `"twenty-five"` and return the number `25`.

Its definition looks like this:

```haxe

var hyphenatedNumber = multOfTen.bind(function (m) {
	return P.string("-").then(ones).fmap(function (o) {
	    return m + o;
	  });
  });


```

Lets break it down.  The definition of `hyphenatedNumber` makes use of
a couple of other parsers that are defined earlier in the file.  

First, the `ones` parser accepts any of the the strings `"one"`
,`"two"`, up to `"nine"` and returns the respectively designated
integer values.  Next, the `multOfTen` parser operates similarly to
`ones`, but it accpets the words `"twenty"`, `"thirty"`, and so on up
to `"ninety"`, returning `20`, `30`, ... up to `90` respectively.

In order to parse a string like `"twenty-five"` we must first parse a
multiple of ten with `multOfTen`. If `multOfTen` parses successfully,
we end up with an integer, call it `m`, and some leftover input.  We
pass the result of our `multOfTen` parser, using `bind`, to a function
that accepts `m`, allowing us to make use of that value later on.  

We now must keep parsing. Hopefully, the next thing we see after our
multiple of ten is a `"-"`. Anticipating, the next parser we see
inside the `bind` argument starts with `P.string("-")`.  

After the hypen we want to parse with `ones`.  Here we use `fmap` to
caputre the result of `ones` in order to add it to the result of
`multOfTen`.  Here is a summary of the steps:


1. `"twenty-five"` becomes `20` after `multOfTen` with `"-five"`
   leftover. We bind `20` to `m` in the function argument passed to
   `bind`.
2. `P.string("-")` accepts the `"-"` in `"-five"` leaving `"five"`
   left to parse.
3. `"five"` becomes `5` after `ones`, and `5` gets bound to `o` in the
   function argument we pass to `fmap`.
4. finally, we add `m` and `o` to return `25`.  Note that the type of
   `hyphenatedNumber` is `Parser<Int>`.

Why did we use `fmap` instead of `bind` after `P.string("-")`? The
main reason is that we're done parsing.  By the time we get to parsing
the "five" we just want to transform the output without parsing any
more input. However, it turns out that `fmap` is implemented in terms
of `bind`, so we used it afterall!


### The output of the example


Running the test file should output something like:

```bash

-------------------------------
one == 1
True
-------------------------------
22 == 22
True
-------------------------------
six == 6
True
-------------------------------
sixteen == 16
True
-------------------------------
sixty == 60
True
-------------------------------
sixty-one == 61
True
-------------------------------
three hundred fifteen == 315
True
-------------------------------
three hundred fifteen thousand == 315000
True
-------------------------------
seventy-two thousand seven hundred twenty-one == 72721
True
-------------------------------
five million two hundred thirty-eight thousand nine hundred seventy-six == 5238976
True
-------------------------------
four hundred million six hundred ninety-nine == 400000699
True

```

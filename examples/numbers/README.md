## Number Parsing Example

Here is a parser that accepts strings like `"five million two hundred thirty-eight thousand nine hundred seventy-six"` returns the integer `5238976`.

To run the example code, just cd into this directory and do something like

```bash

haxe -cp ../../src -main Main -python main.py
python3 main.py


```

which is what I do on my system.  Then running the test file should
output something like:

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

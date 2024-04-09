# BFCompiler in assembly
A project using mostly assembly to parse BrainF**k code and print the output of the code to the standard output.

If you are not familiar with BF: it is an extremely simple yet turing-complete esoteric programming language. You can read about it [here](https://en.wikipedia.org/wiki/Brainfuck).

The assembly code basically gets a string containing a BF code, and executes it. It uses 256 byte cells instead of 30,000, mostly because I did not need 30,000. When it comes to reading input with the ',' character, the input can only be one character (0-255), it cannot take numbers like 65, it will be read as '6'. 

Have fun playing with it!

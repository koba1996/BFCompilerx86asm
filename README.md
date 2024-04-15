# BFCompiler in assembly
A project using mostly assembly to parse BrainF**k code and print the output of the code to the standard output.

If you are not familiar with BF: it is an extremely simple yet turing-complete esoteric programming language. You can read about it [here](https://en.wikipedia.org/wiki/Brainfuck).

The new version works with files as input and output. You must provide a code.txt file that contains the BF code, and you can optionally provide an input.txt file that contains inputs. When using the read input command, the code will read the input file char by char if provided, otherwise will fail with an error. The output will be printed into the output.txt file. The file will be overwritten, if already exists.

Have fun playing with it!

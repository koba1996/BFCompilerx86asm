// if you nasm and gcc you do:
// nasm -fwin32 compiler.asm
// gcc main.c compiler.obj -o main
// main

#include <stdio.h>

extern void compile(char *code);

int main(int argc, char **argv)
{
    compile(">++++++++[<+++++++++>-]<.>++++[<+++++++>-]<+.+++++++..+++.>>++++++[<+++++++>-]\
    <++.------------.>++++++[<+++++++++>-]<+.<.+++.------.--------.>>>++++[<++++++++>-]<+.");
    return 0;
}
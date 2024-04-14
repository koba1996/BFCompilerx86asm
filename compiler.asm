    global _compile

    extern _printf
    extern _getchar
    extern _fopen
    extern _fclose
    extern _fputc
    extern _fgetc
    extern _malloc
    extern _calloc
    extern _free

    section .data

read: db 'r', 0
write db 'w', 0
input: db 'input.txt', 0
code: db 'code.txt', 0
output: db 'output.txt', 0
files_opened: db 'Files opened and created successfully', 10, 'Parsing...', 10, 0
exit: db 'Program exited successfully. Press enter to close the window!', 10, 0
exiterr: db 'Program exited with errors. Press enter to close the window!', 10, 0
inputwarn: db 'Warning: could not open input.txt', 10, 0
inputerr: db 'Error: cannot read from input.txt', 10, 0 
codeerr: db 'Error: could not open code.txt', 10, 0
outputerr: db 'Error: could not create output.txt', 10, 0
memerr: db 'Error: accessing memory outside of your territory', 10, 0
bopenerr: db 'Error: not closing bracket that was opened', 10, 0
bcloseerr: db 'Error: closing bracket that was not opened', 10, 0
ping: db 'ping', 10, 0

    section .text

_compile:
    push ebp
    mov ebp, esp

    push dword 0                    ; pointer
    push dword 1                    ; we are not inside a loop
    push dword [ebp + 8]            ; storage-size
    call open_files
    cmp eax, 0
    je end_new
    push eax                        ; *int files

    call read_code

    push eax                        ; code address

    push files_opened
    call _printf

    mov eax, [esp + 12]
    mov dword [esp], eax
    call create_storage
    mov [esp], eax                  ; storage address

    mov eax, esp
    add eax, 20
    push eax                        ; pointer address

    call parse_code_new
    mov [esp + 24], eax
    add esp, 4
    call _free
    add esp, 4
    call _free
    add esp, 4
    call close_files
    add esp, 4
end_new:
    add esp, 8
    cmp dword [esp], 0
    je exit_no_errors
    push exiterr
    jmp exit_finally
exit_no_errors:
    push exit
exit_finally:
    call _printf
    add esp, 8
    call _getchar
    pop ebp
    ret

parse_code_new:
    push ebp                        ; void parse_code(int* index, char* storage, char* code, int* files, int storage_size, int outer)
    mov ebp, esp                    ; files = [FILE* code, FILE* output, FILE* input]

    push dword 0                    ; local variable that stores errors
iterate:
    push dword [ebp + 16]
parse_char_new:
    mov eax, [esp]
    push dword [eax]
    cmp byte [esp], 0
    je check_brackets_closed
    cmp byte [esp], '+'
    je plus_new
    cmp byte [esp], '-'
    je minus_new
    cmp byte [esp], '<'
    je left_new
    cmp byte [esp], '>'
    je right_new
    cmp byte [esp], '['
    je open_new
    cmp byte [esp], ']'
    je close_new
    cmp byte [esp], '.'
    je print_char_new
    cmp byte [esp], ','
    je read_char_new
next_char:
    add esp, 4
    inc dword [esp]
    jmp parse_char_new
finish_iteration_with_err:
    inc dword [esp + 8]
finish_iteration:
    add esp, 8
    pop eax
    pop ebp
    ret

plus_new:
    mov eax, [ebp + 12]
    mov edx, [ebp + 8]
    mov edx, [edx]
    add eax, edx
    inc byte [eax]
    jmp next_char

minus_new:
    mov eax, [ebp + 12]
    mov edx, [ebp + 8]
    mov edx, [edx]
    add eax, edx
    dec byte [eax]
    jmp next_char

left_new:
    mov eax, [ebp + 8]
    cmp dword [eax], 0
    je err_mem
    dec dword [eax]
    jmp next_char

right_new:
    mov eax, [ebp + 8]
    mov edx, [eax]
    inc edx
    cmp edx, [ebp + 24]
    je err_mem
    inc dword [eax]
    jmp next_char

open_new:
    mov eax, [ebp + 12]
    mov edx, [ebp + 8]
    mov edx, [edx]
    add eax, edx
    cmp byte [eax], 0
    je find_close_new
    push dword 0                    ; we are inside a loop
    push dword [ebp + 24]           ; storage size
    push dword [ebp + 20]           ; files
    mov eax, [esp + 16]
    inc eax
    push eax                        ; code starting address
    push dword [ebp + 12]           ; storage address
    push dword [ebp + 8]            ; pointer address
    call parse_code_new
    add esp, 24
    cmp eax, 0
    je find_close_new
    jmp finish_iteration_with_err
find_close_new:
    inc dword [esp + 4]
    mov eax, [esp + 4]
    mov al, [eax]
    cmp al, ']'
    je next_char
    jmp find_close_new

close_new:
    cmp dword [ebp + 28], 1
    je err_close
    mov eax, [ebp + 12]
    mov edx, [ebp + 8]
    mov edx, [edx]
    add eax, edx
    cmp byte [eax], 0
    je finish_iteration
    add esp, 8
    jmp iterate

print_char_new:
    mov eax, [ebp + 20]
    add eax, 4
    mov eax, [eax]
    push dword eax
    mov eax, [ebp + 12]
    mov edx, [ebp + 8]
    mov edx, [edx]
    add eax, edx
    push dword 0
    mov eax, [eax]
    add byte [esp], al
    call _fputc
    add esp, 8
    jmp next_char

read_char_new:
    mov eax, [ebp + 20]
    add eax, 8
    mov eax, [eax]
    push dword eax
    cmp dword [esp], 0
    je cannot_read_char
    call _fgetc
    inc eax
    cmp eax, 0
    je cannot_read_char
    dec eax
    mov [esp], eax
    mov eax, [ebp + 12]
    mov edx, [ebp + 8]
    mov edx, [edx]
    add eax, edx
    mov edx, [esp]
    mov byte [eax], dl
    add esp, 4
    jmp next_char

check_brackets_closed:
    cmp dword [ebp + 28], 1
    je finish_iteration
    jmp err_open

cannot_read_char:
    push inputerr
    call _printf
    add esp, 8
    jmp finish_iteration_with_err

print_ping:
    push ping                       ; for debugging purposes, if you do not have a proper debugger
    call _printf                    ; you can call it anywhere in the code to print ping
    add esp, 4                      ; this way you can see after which line the code terminates
    ret

err_open:
    push bopenerr                   ; print error if a bracket was not opened
    call _printf
    add esp, 4
    jmp finish_iteration_with_err

err_close:
    push bcloseerr                  ; print error if a bracket was not closed
    call _printf
    add esp, 4
    jmp finish_iteration_with_err

err_mem:
    push memerr                     ; print error if the pointer wanders outside of storage
    call _printf
    add esp, 4
    jmp finish_iteration_with_err

open_files:
    push ebp
    mov ebp, esp

    push dword 12
    call _malloc
    mov ebx, eax

    mov dword [esp], code
    call open_file
    mov dword [ebx], eax
    cmp dword [ebx], 0
    jne open_output
    mov dword [esp], codeerr
    call _printf
    mov [esp], ebx
    call _free
    add esp, 4
    mov eax, 0
    jmp finish_opening
open_output:
    mov dword [esp], output
    call create_file
    mov dword [ebx + 4], eax
    cmp dword [ebx + 4], 0
    jne open_input
    mov dword [esp], outputerr
    call _printf
    mov eax, [ebx]
    mov [esp], eax
    call _fclose
    mov [esp], ebx
    call _free
    add esp, 4
    mov eax, 0
    jmp finish_opening
open_input:
    mov dword [esp], input
    call open_file
    mov dword [ebx + 8], eax
    add esp, 4
    cmp dword [ebx + 8], 0
    jne no_error_while_opening
    push inputwarn
    call _printf
    add esp, 4
no_error_while_opening:
    mov eax, ebx
finish_opening:
    pop ebp
    ret

open_file:
    push ebp                        ; file* open_file(char* name)
    mov ebp, esp

    push dword read
    mov eax, [ebp + 8]
    push eax
    call _fopen
    add esp, 8

    pop ebp
    ret

create_file:
    push ebp                        ; file* create_file(char* name)
    mov ebp, esp

    push dword write
    mov eax, [ebp + 8]
    push eax
    call _fopen
    add esp, 8

    pop ebp
    ret

close_files:
    push ebp
    mov ebp, esp

    mov ebx, [ebp + 8]
    push dword [ebx]
    call _fclose
    mov eax, [ebx + 4]
    mov [esp], eax
    call _fclose
    mov eax, [ebx + 8]
    mov [esp], eax
    cmp dword [esp], 0
    je free_files
    call _fclose
free_files:
    mov [esp], ebx
    call _free
    add esp, 4
    pop ebp
    ret

read_code:
    push ebp
    mov ebp, esp

    mov ebx, [ebp + 8]
    mov ebx, [ebx]
    push dword 1024                 ; TODO: make it dynamic
    call _malloc
    mov [esp], eax
    push eax
    push ebx
read_one_char:
    call _fgetc
    mov edx, eax
    mov ebx, edx
    add ebx, 1
    cmp dword ebx, 0
    je end_read
    mov eax, [esp + 4]
    mov byte [eax], dl
    inc eax
    mov [esp + 4], eax
    jmp read_one_char
end_read:
    add esp, 4
    mov eax, [esp]
    mov byte [eax], 0
    add esp, 4
    mov eax, [esp]
    add esp, 4
    pop ebp
    ret

create_storage:
    push ebp
    mov ebp, esp

    push dword [ebp + 8]
    push dword 1
    call _calloc
    add esp, 8

    pop ebp
    ret
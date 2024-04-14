    global _compile

    extern _printf
    extern _getchar
    extern _fopen
    extern _fclose
    extern _fputc
    extern _fgetc
    extern _malloc
    extern _free

    section .data

read: db 'r', 0
write db 'w', 0
int: db '%d', 10, 0
input: db 'input.txt', 0
code: db 'code.txt', 0
output: db 'output.txt', 0
files_opened: db 'Files opened and created successfully', 10, 'Parsing...', 10, 0
exit: db 'Program exited successfully. Press enter to close the window!', 10, 0
inputerr: db 'Warning: could not open input.txt', 10, 0
inputerr2: db 'Error: cannot read from input.txt', 10, 0 
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
    call open_files
    cmp eax, 0
    je end
    push eax

    call read_code

    mov ebx, eax                ; ebx stores the address of the code
    push ebx

    push files_opened
    call _printf
    add esp, 4

    sub esp, 256                ; create 256 bytes of storage for data (real BF uses like 32k but we do not need that much now)

    mov dword ecx, 0
make_it_zero:                   ; start with a storage full of zeros
    cmp dword ecx, 256          ; TODO: make storage size dynamic
    je parse_code               ; when finished preparing the storage, start parsing the code
    mov dword [esp + ecx], 0
    add ecx, 4
    jmp make_it_zero

finish_parsing:
    cmp dword [esp], 0          ; if some brackets were not closed, free the stack and print error
    jne free_stack_after_error
    add esp, 8                  ; free pointer and loop-stack size
    add esp, 256                ; free storage
    call _free
    add esp, 4
    call close_files
    add esp, 4
end:
    mov esp, ebp
    push exit
    call _printf
    add esp, 4
    call _getchar
    pop ebp
    ret

parse_code:
    push dword 0                ; pointer
    push dword 0                ; loop-stack size
parse_char:
    cmp byte [ebx], 0           
    je finish_parsing           ; when reached end of string, finish parsing
    cmp byte [ebx], '+'         ; until then handle every character properly
    je plus
    cmp byte [ebx], '-'
    je minus
    cmp byte [ebx], '<'
    je left
    cmp byte [ebx], '>'
    je right
    cmp byte [ebx], '['
    je open
    cmp byte [ebx], ']'
    je close
    cmp byte [ebx], '.'
    je print_char
    cmp byte [ebx], ','
    je read_char                ; any other character is comment by BF definition and will be ignored
inc_ebx:
    inc ebx
    jmp parse_char

plus:
    call get_pointer_address    ; increase the value of the data pointed by the pointer
    inc byte [eax]
    jmp inc_ebx

minus:
    call get_pointer_address    ; decrease the value of the data pointed by the pointer
    dec byte [eax]
    jmp inc_ebx

left:
    call get_pointer            ; decrease the value of the pointer
    cmp dword [eax], 0          ; if we are at the 0th element already, throw error
    je err_mem
    dec dword [eax]
    jmp inc_ebx

right:
    call get_pointer            ; increase the value of the pointer
    cmp dword [eax], 255        ; if we are at the 255th element already, throw error
    je err_mem                  ; if you wish to use bigger storage, increase this limit too
    inc dword [eax]
    jmp inc_ebx

open:
    call get_pointer_address    ; if the value pointed by the pointer is zero, skip the content
    cmp byte [eax], 0
    je find_close
    push dword [esp]            ; otherwise remember the loop opening address
    add dword [esp], 4
    mov [esp + 4], ebx
    jmp inc_ebx

close:
    cmp dword [esp], 0          ; if we did not open any loops, throw an error
    je err_open                 
    call get_pointer_address
    cmp byte [eax], 0           ; if the value pointed by the pointer is zero, forget the opening address
    je remove_open
    mov ebx, [esp + 4]          ; otherwise go back where the loop was opened
    jmp inc_ebx

print_char:
    call get_pointer_address    ; print out the value pointed by the pointer as char
    mov dl, [eax]
    mov eax, 0
    mov al, dl
    push dword 0
    push eax
    call get_files_address
    mov eax, [eax]
    add eax, 4
    mov eax, [eax]
    mov [esp + 4], eax
    call _fputc
    add esp, 8
    jmp inc_ebx

read_char:
    call get_files_address
    mov eax, [eax]
    add eax, 8
    mov eax, [eax]
    push eax
    cmp dword [esp], 0
    je cannot_read_char
    call _fgetc                 ; read a character from the output
    inc eax
    cmp eax, 0
    je cannot_read_char
    dec eax
    mov edx, eax
    add esp, 4
    call get_pointer_address
    mov byte [eax], dl          ; and store it where the pointer points
    jmp inc_ebx

cannot_read_char:
    push inputerr2
    call _printf
    add esp, 8
    jmp finish_parsing

find_close:
    cmp byte [ebx], 0           ; skip through the content of the loop, find the next ']'
    je err_open
    cmp byte [ebx], ']'
    je inc_ebx
    inc ebx
    jmp find_close

remove_open:
    sub dword [esp], 4          ; forget the address of the last '[' character as we left the loop
    mov edx, [esp]
    add esp, 4
    mov [esp], edx
    jmp inc_ebx

print_ping:
    push ping                   ; for debugging purposes, if you do not have a proper debugger
    call _printf                ; you can call it anywhere in the code to print ping
    add esp, 4                  ; this way you can see after which line the code terminates
    ret

get_pointer:
    mov eax, esp                ; because of the call of this subroutine esp points 4 bytes lower than our loop-stack size data
    add eax, 8                  ; jump to the 0th element of loop-stack
    add eax, [esp + 4]          ; skip the loop-stack, so now we are sitting on the pointer
    ret

get_pointer_address:
    mov eax, esp                ; because of the call of this subroutine esp points 4 bytes lower than our loop-stack size data
    add eax, 8                  ; jump to the 0th element of loop-stack
    add eax, [esp + 4]          ; skip the loop-stack, so now we are sitting on the pointer
    add eax, [eax]              ; increase our position with the value of the pointer
    add eax, 4                  ; and jump one dword ahead since we were sitting on the pointer, not on the 0th element
    ret

get_files_address:
    mov eax, ebp
    sub eax, 4
    ret

free_stack_after_error:
    add esp, [esp]              ; free the loop-stack in case of early termination
    mov dword [esp], 0
    jmp err_open

err_open:
    push bopenerr               ; print error if a bracket was not opened
    call _printf
    add esp, 4
    jmp finish_parsing

err_close:
    push bcloseerr              ; print error if a bracket was not closed
    call _printf
    add esp, 4
    jmp finish_parsing

err_mem:
    push memerr                 ; print error if the pointer wanders outside of storage
    call _printf
    add esp, 4
    jmp finish_parsing

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
    push inputerr
    call _printf
    add esp, 4
no_error_while_opening:
    mov eax, ebx
finish_opening:
    pop ebp
    ret

open_file:
    push ebp                    ; file* open_file(char* name)
    mov ebp, esp

    push dword read
    mov eax, [ebp + 8]
    push eax
    call _fopen
    add esp, 8

    pop ebp
    ret

create_file:
    push ebp                    ; file* create_file(char* name)
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
    push dword 1024
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
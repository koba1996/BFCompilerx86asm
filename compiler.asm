    global _compile

    extern _printf
    extern _putchar
    extern _getchar

    section .data

memerr: db 10, 'Error: accessing memory outside of your territory', 0
bopenerr: db 10, 'Error: not closing bracket that was opened', 0
bcloseerr: db 10, 'Error: closing bracket that was not opened', 0
charthirteen: db '[13]', 0
ping: db 'ping', 10, 0

    section .text

_compile:
    push ebp
    mov ebp, esp

    mov ebx, dword[ebp + 8]     ; ebx stores the address of the code

    sub esp, 256                ; create 256 bytes of storage for data (real BF uses like 32k but we do not need that much now)

    mov dword ecx, 0
make_it_zero:                   ; start with a storage full of zeros
    cmp dword ecx, 256
    je parse_code               ; when finished preparing the storage, start parsing the code
    mov dword [esp + ecx], 0
    add ecx, 4
    jmp make_it_zero

finish_parsing:
    cmp dword [esp], 0          ; if some brackets were not closed, free the stack and print error
    jne free_stack_after_error
    add esp, 8                  ; free pointer and loop-stack size
    add esp, 256                ; free storage

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
    mov al, [eax]
    cmp al, 13                  ; char 13 is something messy, it gets back to the start of the line,
    je print_char_thirteen      ; and starts overwriting existing characters, so we will not support it
    push eax
    call _putchar
    add esp, 4
    jmp inc_ebx

read_char:
    call _getchar               ; read a character from the output
    mov edx, eax
    call get_pointer_address
    mov byte [eax], dl          ; and store it where the pointer points
    jmp inc_ebx

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

print_char_thirteen:
    push charthirteen           ; instead of printing ASCII char 13 we print '[13]'
    call _printf
    add esp, 4
    jmp inc_ebx

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

assume cs:code, ds:data

data segment
    A db 6
    B db 2
    C db 1
    D db 2
    res db ?
    dec_str db 6 dup ('$')
    hex_str db 4 dup ('$')
    newline db 13, 10, '$'
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    ; Вычисляем a/b
    mov al, A
    mov ah, 0
    mov bl, B
    div bl
    mov cl, al

    ; Вычисляем d/c
    mov al, D
    mov ah, 0
    mov bl, C
    div bl

    ; Складываем и декрементируем
    add cl, al
    dec cl
    mov res, cl

    ; Преобразуем в десятичную строку
    mov al, res
    mov ah, 0
    mov si, offset dec_str + 5  ; Начинаем с конца буфера
    mov cx, 10
    mov byte ptr [si], '$'

dec_loop:
    xor dx, dx
    div cx
    add dl, '0'
    dec si
    mov [si], dl
    test ax, ax
    jnz dec_loop

    ; Вывод десятичного результата
    mov dx, si
    call print_string

    ; Вывод перевода строки
    mov dx, offset newline
    call print_string

    ; Преобразуем в шестнадцатеричную систему
    mov al, res
    mov ah, 0
    mov si, offset hex_str + 2  ; Начинаем с конца буфера
    mov byte ptr [si], '$'
    mov cx, 16

hex_loop:
    xor dx, dx
    div cx
    cmp dl, 10
    jb hex_digit
    add dl, 'A' - 10
    jmp hex_store
hex_digit:
    add dl, '0'
hex_store:
    dec si
    mov [si], dl
    test ax, ax
    jnz hex_loop

    ; Вывод шестнадцатеричного результата
    mov dx, si
    call print_string

    ; Завершаем программу
    mov ax, 4c00h
    int 21h

print_string proc
    mov ah, 09h
    int 21h
    ret
print_string endp

code ends
end start

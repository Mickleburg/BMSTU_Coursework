assume cs:code, ds:data

data segment
    arr dw 13, 10, 5, 35, 6
    n   dw ($-arr)/2
    dec_str db 6 dup ('$')
    space db ' $'
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    ; Инициализация
    mov cx, n       ; cx счетчик цикла
    dec cx
    jz print_array  ; Переходим к печати если массив из 1 элемента

    mov si, offset arr ; si - первый эл-т массива
    mov ax, [si]      ; рабочий максимум
    add si, 2

update_loop:
    ; сравниваем элемент с максимум
    cmp [si], ax
    jle not_greater     ; [si] <= ax

    ; элемент > максимума
    mov ax, [si]

not_greater:
    ; обновляем эл-т
    mov [si], ax

    ; часть цикла:
    add si, 2
    loop update_loop

print_array:
    mov si, offset arr
    mov cx, n

print_loop:
    mov ax, [si]
    mov di, offset dec_str + 5
    mov byte ptr [di], '$'

    mov bx, 10
dec_convert:
    xor dx, dx
    div bx
    add dl, '0'
    dec di
    mov [di], dl
    test ax, ax
    jnz dec_convert

    mov dx, di
    mov ah, 09h
    int 21h

    dec cx
    jz exit

    mov dx, offset space
    mov ah, 09h
    int 21h

    add si, 2
    jmp print_loop

exit:
    mov ax, 4c00h
    int 21h

code ends
end start

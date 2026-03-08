assume cs:code, ds:data

data segment
    dummy db 0Dh, 0Ah, '$'
    string1 db 100, 99 dup (0)    ; строка для поиска
    string2 db 100, 99 dup (0)    ; символы для поиска
    result_msg db "Result: $"
    not_found_msg db "No match found$"
    newline db 0Dh, 0Ah, '$'
data ends

code segment

; char *strpbrk(const char *str1, const char *str2);
strpbrk proc
    push bp
    mov bp, sp

    ; Получаем аргументы из стека
    mov si, [bp+6]   ; str1
    mov di, [bp+4]   ; str2

    ; Проходим по каждому символу str1
str1_loop:
    mov al, [si]     ; текущий символ из str1
    cmp al, '$'      ; конец строки?
    je not_found     ; если да - символ не найден:(

    ; Сохраняем текущую позицию в str1
    mov bx, si

    ; Проверяем, есть ли этот символ в str2
    mov di, [bp+4]   ; сбрасываем указатель str2

str2_loop:
    mov ah, [di]     ; символ из str2
    cmp ah, '$'      ; конец строки str2?
    je next_char     ; если да, переходим к следующему символу str1

    cmp al, ah       ; сравниваем символы
    je found         ; если равны успеех

    inc di           ; следующий символ str2
    jmp str2_loop

next_char:
    mov si, bx       ; восстанавливаем указатель str1
    inc si           ; следующий символ str1
    jmp str1_loop

found:
    mov ax, bx       ; возвращаем указатель на найденный символ
    jmp exit

not_found:
    xor ax, ax

exit:
    pop bp
    ret 4
strpbrk endp

; Функция для вывода числа
; void print_number(int num)
print_number proc
    push bp
    mov bp, sp

    mov ax, [bp+4]   ; получаем число
    mov cx, 0        ; счетчик цифр

    ; Если число 0, обрабатываем отдельно
    cmp ax, 0
    jne convert_loop
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp print_exit

convert_loop:
    xor dx, dx
    mov bx, 10
    div bx
    push dx
    inc cx           ; увеличиваем счетчик
    test ax, ax
    jnz convert_loop

    ; Выводим цифры
print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop

print_exit:
    pop bp
    ret 2
print_number endp

start:
    mov ax, data
    mov ds, ax

    ;  Первая строка
    mov dx, offset string1
    mov ah, 0Ah
    int 21h

    ; доабвляем символ конца строки
    mov si, offset string1 + 1
    mov cl, [si]     ; фактическая длина
    xor ch, ch
    inc si
    add si, cx
    mov byte ptr [si], '$'

    ;   Перевод строки
    mov dx, offset dummy
    mov ah, 09h
    int 21h

    ; Ввод второй строки (символы для поиска)
    mov dx, offset string2
    mov ah, 0Ah
    int 21h

    ; Добавляем символ конца строки
    mov si, offset string2 + 1
    mov cl, [si]     ; фактическая длина
    xor ch, ch
    inc si
    add si, cx
    mov byte ptr [si], '$'

    ; Перевод строки
    mov dx, offset dummy
    mov ah, 09h
    int 21h

    ; Вызов strpbrk
    push offset string1 + 2  ; указатель на начало строки
    push offset string2 + 2  ; указатель на символы для поиска
    call strpbrk

    ; Проверяем результат
    test ax, ax
    jz no_match

    ;  индекс
    mov bx, ax
    mov ax, offset string1 + 2
    sub bx, ax

    ; сообщение
    mov dx, offset result_msg
    mov ah, 09h
    int 21h

    ; Выводим индекс
    push bx
    call print_number

    jmp exit_program

no_match:
    mov dx, offset not_found_msg
    mov ah, 09h
    int 21h

exit_program:

    ; Перевод строик
    mov dx, offset newline
    mov ah, 09h
    int 21h

    mov ah, 4ch
    int 21h

code ends
end start

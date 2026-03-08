.MODEL small
.STACK 256

.DATA
    ; Максимальное количество разрядов числа (больше 11 для чисел > 32 бит)
    MAX_DIGITS      EQU 16

    ; Буферы для ввода строк (знак + цифры + Enter + запас)
    buffer1         DB MAX_DIGITS + 3 DUP(0)
    buffer2         DB MAX_DIGITS + 3 DUP(0)

    ; Массивы цифр чисел
    num1            DB MAX_DIGITS DUP(0)
    num2            DB MAX_DIGITS DUP(0)
    result          DB MAX_DIGITS + 1 DUP(0)

    ; Флаги знаков: 0 = положительное, 1 = отрицательное
    sign1           DB 0
    sign2           DB 0
    sign_res        DB 0

    ; Длины чисел
    len1            DW 0
    len2            DW 0
    len_res         DW 0

    ; Строка для вывода результата
    out_str         DB MAX_DIGITS + 2 DUP(0)

    ; Сообщения
    msg_input1      DB 'Enter first hex number: $'
    msg_input2      DB 'Enter second hex number: $'
    msg_result      DB 'Result: $'
    msg_error       DB 'Error: invalid character!$'
    msg_newline     DB 13, 10, '$'

.CODE

;------------------------------------------------------------
; Вывод строки на экран
; Вход: DX = адрес строки с '$'
;------------------------------------------------------------
print_str PROC
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
print_str ENDP

;------------------------------------------------------------
; Ввод строки с клавиатуры
; Вход: DI = адрес буфера
; Выход: AX = длина введенной строки
;------------------------------------------------------------
input_str PROC
    push bx
    push cx
    push di

    xor cx, cx              ; счетчик символов

input_loop:
    mov ah, 01h             ; ввод символа с эхом
    int 21h

    cmp al, 13              ; Enter?
    je input_done

    cmp cx, MAX_DIGITS + 1  ; проверка переполнения буфера
    jae input_loop          ; игнорируем лишние символы

    mov [di], al
    inc di
    inc cx
    jmp input_loop

input_done:
    mov byte ptr [di], 0    ; завершающий ноль
    mov ax, cx

    pop di
    pop cx
    pop bx
    ret
input_str ENDP

;------------------------------------------------------------
; Преобразование ASCII в цифру 0-15
; Вход: AL = ASCII символ
; Выход: AL = цифра, CF = 1 если ошибка
;------------------------------------------------------------
ascii_to_digit PROC
    cmp al, '0'
    jb atd_check_upper
    cmp al, '9'
    ja atd_check_upper
    sub al, '0'
    clc
    ret

atd_check_upper:
    cmp al, 'A'
    jb atd_check_lower
    cmp al, 'F'
    ja atd_check_lower
    sub al, 'A'
    add al, 10
    clc
    ret

atd_check_lower:
    cmp al, 'a'
    jb atd_error
    cmp al, 'f'
    ja atd_error
    sub al, 'a'
    add al, 10
    clc
    ret

atd_error:
    stc
    ret
ascii_to_digit ENDP

;------------------------------------------------------------
; Преобразование цифры в ASCII
; Вход: AL = цифра 0-15
; Выход: AL = ASCII символ
;------------------------------------------------------------
digit_to_ascii PROC
    cmp al, 10
    jb dta_digit
    add al, 'A' - 10
    ret
dta_digit:
    add al, '0'
    ret
digit_to_ascii ENDP

;------------------------------------------------------------
; Парсинг строки в массив цифр
; Вход: SI = адрес буфера, DI = адрес массива цифр
;       BX = адрес переменной знака, DX = адрес переменной длины
; Выход: CF = 1 если ошибка
;------------------------------------------------------------
parse_number PROC
    push ax
    push cx
    push si
    push di

    mov byte ptr [bx], 0    ; знак = положительный

    ; Проверяем знак
    mov al, [si]
    cmp al, '-'
    jne parse_check_plus
    mov byte ptr [bx], 1    ; отрицательное
    inc si
    jmp parse_start

parse_check_plus:
    cmp al, '+'
    jne parse_start
    inc si

parse_start:
    ; Находим длину числа
    push si
    xor cx, cx
parse_len_loop:
    mov al, [si]
    cmp al, 0
    je parse_len_done
    inc cx
    inc si
    jmp parse_len_loop

parse_len_done:
    pop si

    ; Проверка на пустое число
    cmp cx, 0
    je parse_error_pop

    ; Проверка на слишком длинное число
    cmp cx, MAX_DIGITS
    ja parse_error_pop

    ; Сохраняем длину
    push di                 ; сохраняем начало массива
    mov word ptr [bx+2], cx ; длина (bx+2 это len1 или len2)

    ; Заполняем массив нулями
    push cx
    push di
    mov cx, MAX_DIGITS
    xor al, al
parse_zero_loop:
    mov [di], al
    inc di
    dec cx
    jnz parse_zero_loop
    pop di
    pop cx

    ; Вычисляем начальную позицию в массиве (выравнивание вправо)
    mov ax, MAX_DIGITS
    sub ax, cx
    add di, ax

    ; Преобразуем символы в цифры
parse_convert_loop:
    mov al, [si]
    cmp al, 0
    je parse_done

    call ascii_to_digit
    jc parse_error

    mov [di], al
    inc si
    inc di
    jmp parse_convert_loop

parse_error:
    pop di                  ; убираем сохраненный di
    stc
    jmp parse_exit

parse_error_pop:
    stc
    jmp parse_exit

parse_done:
    pop di                  ; убираем сохраненный di
    clc

parse_exit:
    pop di
    pop si
    pop cx
    pop ax
    ret
parse_number ENDP

;------------------------------------------------------------
; Сравнение двух чисел по модулю
; Вход: SI = num1, DI = num2
; Выход: флаги как после CMP (num1 vs num2)
;------------------------------------------------------------
compare_nums PROC
    push ax
    push cx
    push si
    push di

    mov cx, MAX_DIGITS
cmp_loop:
    mov al, [si]
    cmp al, [di]
    jne cmp_done
    inc si
    inc di
    dec cx
    jnz cmp_loop
    ; Числа равны
cmp_done:
    pop di
    pop si
    pop cx
    pop ax
    ret
compare_nums ENDP

;------------------------------------------------------------
; Сложение двух чисел (без учета знака)
; Вход: SI = первое число, DI = второе число, BX = результат
;------------------------------------------------------------
add_nums PROC
    push ax
    push cx
    push si
    push di
    push bx

    ; Начинаем с младших разрядов (справа)
    add si, MAX_DIGITS - 1
    add di, MAX_DIGITS - 1
    add bx, MAX_DIGITS - 1

    mov cx, MAX_DIGITS
    clc                     ; очищаем флаг переноса

add_loop:
    mov al, [si]
    adc al, [di]

    ; Проверяем переполнение
    cmp al, 16
    jb add_no_carry
    sub al, 16
    ; CF будет установлен автоматически при следующем ADC
    stc
    jmp add_store
add_no_carry:
    clc
add_store:
    mov [bx], al

    dec si
    dec di
    dec bx
    dec cx
    jnz add_loop

    pop bx
    pop di
    pop si
    pop cx
    pop ax
    ret
add_nums ENDP

;------------------------------------------------------------
; Вычитание: результат = SI - DI (предполагается SI >= DI)
; Вход: SI = уменьшаемое, DI = вычитаемое, BX = результат
;------------------------------------------------------------
sub_nums PROC
    push ax
    push cx
    push si
    push di
    push bx

    ; Начинаем с младших разрядов (справа)
    add si, MAX_DIGITS - 1
    add di, MAX_DIGITS - 1
    add bx, MAX_DIGITS - 1

    mov cx, MAX_DIGITS
    clc                     ; очищаем флаг заёма

sub_loop:
    mov al, [si]
    sbb al, [di]

    ; Проверяем заём
    jnc sub_no_borrow
    add al, 16              ; компенсируем заём
    stc                     ; устанавливаем флаг для следующего SBB
    jmp sub_store
sub_no_borrow:
    clc
sub_store:
    mov [bx], al

    dec si
    dec di
    dec bx
    dec cx
    jnz sub_loop

    pop bx
    pop di
    pop si
    pop cx
    pop ax
    ret
sub_nums ENDP

;------------------------------------------------------------
; Главная процедура вычисления
;------------------------------------------------------------
calculate PROC
    ; Определяем операцию на основе знаков
    mov al, sign1
    xor al, sign2
    jnz calc_different_signs

    ; Одинаковые знаки - сложение модулей
    mov sign_res, 0
    mov al, sign1
    mov sign_res, al        ; знак результата = знак операндов

    lea si, num1
    lea di, num2
    lea bx, result
    call add_nums
    jmp calc_done

calc_different_signs:
    ; Разные знаки - вычитание модулей
    lea si, num1
    lea di, num2
    call compare_nums

    ja calc_num1_bigger
    jb calc_num2_bigger

    ; Числа равны - результат 0
    mov sign_res, 0
    lea bx, result
    mov cx, MAX_DIGITS
    xor al, al
calc_zero_loop:
    mov [bx], al
    inc bx
    dec cx
    jnz calc_zero_loop
    jmp calc_done

calc_num1_bigger:
    ; |num1| > |num2|, результат = num1 - num2, знак = sign1
    mov al, sign1
    mov sign_res, al
    lea si, num1
    lea di, num2
    lea bx, result
    call sub_nums
    jmp calc_done

calc_num2_bigger:
    ; |num2| > |num1|, результат = num2 - num1, знак = sign2
    mov al, sign2
    mov sign_res, al
    lea si, num2
    lea di, num1
    lea bx, result
    call sub_nums

calc_done:
    ret
calculate ENDP

;------------------------------------------------------------
; Формирование и вывод результата
;------------------------------------------------------------
output_result PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    lea si, result
    lea di, out_str

    ; Добавляем знак минус если нужно
    cmp sign_res, 0
    je out_no_sign

    ; Проверяем, что результат не ноль
    push si
    mov cx, MAX_DIGITS
    xor al, al
out_check_zero:
    cmp [si], al
    jne out_add_minus
    inc si
    dec cx
    jnz out_check_zero
    pop si
    jmp out_no_sign         ; результат = 0, минус не нужен

out_add_minus:
    pop si
    mov byte ptr [di], '-'
    inc di

out_no_sign:
    ; Пропускаем ведущие нули
    mov cx, MAX_DIGITS
out_skip_zeros:
    cmp byte ptr [si], 0
    jne out_copy_digits
    inc si
    dec cx
    jnz out_skip_zeros

    ; Все нули - выводим один ноль
    mov byte ptr [di], '0'
    inc di
    jmp out_finish

out_copy_digits:
    ; Копируем оставшиеся цифры
out_copy_loop:
    mov al, [si]
    call digit_to_ascii
    mov [di], al
    inc si
    inc di
    dec cx
    jnz out_copy_loop

out_finish:
    mov byte ptr [di], '$'

    ; Выводим результат
    lea dx, msg_result
    call print_str
    lea dx, out_str
    call print_str
    lea dx, msg_newline
    call print_str

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
output_result ENDP

;------------------------------------------------------------
; Главная программа
;------------------------------------------------------------
main PROC
    mov ax, @data
    mov ds, ax

    ; Ввод первого числа
    lea dx, msg_input1
    call print_str
    lea di, buffer1
    call input_str
    lea dx, msg_newline
    call print_str

    ; Ввод второго числа
    lea dx, msg_input2
    call print_str
    lea di, buffer2
    call input_str
    lea dx, msg_newline
    call print_str

    ; Парсинг первого числа
    lea si, buffer1
    lea di, num1
    lea bx, sign1
    call parse_number
    jc error_exit

    ; Парсинг второго числа
    lea si, buffer2
    lea di, num2
    lea bx, sign2
    call parse_number
    jc error_exit

    ; Вычисление
    call calculate

    ; Вывод результата
    call output_result

    jmp normal_exit

error_exit:
    lea dx, msg_error
    call print_str
    lea dx, msg_newline
    call print_str

normal_exit:
    mov ax, 4C00h
    int 21h
main ENDP

END main

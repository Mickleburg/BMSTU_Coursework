.MODEL SMALL
.STACK 256

.DATA
    MAX_DIGITS      EQU 20
    MAX_RESULT      EQU 42

    buffer1         DB 25, 0, 25 DUP('$')
    buffer2         DB 25, 0, 25 DUP('$')

    num1            DB MAX_DIGITS DUP(0)
    num2            DB MAX_DIGITS DUP(0)
    result          DB MAX_RESULT DUP(0)

    sign1           DB 0
    sign2           DB 0
    sign_result     DB 0

    len1            DW 0
    len2            DW 0
    len_result      DW 0

    result_str      DB MAX_RESULT+2 DUP('$')

    operation       DB 0
    shift_pos       DW 0

    msg_input1      DB 'Enter first number: $'
    msg_input2      DB 'Enter second number: $'
    msg_result      DB 'Result: $'
    msg_error       DB 'Error: invalid character!$'
    msg_newline     DB 13, 10, '$'
    msg_menu        DB 'Select operation:', 13, 10
                    DB '1 - Addition', 13, 10
                    DB '2 - Multiplication', 13, 10
                    DB 'Your choice: $'
    msg_invalid_op  DB 'Invalid operation!$'

.CODE

PRINT MACRO str
    PUSH AX
    PUSH DX
    MOV AH, 09h
    LEA DX, str
    INT 21h
    POP DX
    POP AX
ENDM

START:
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

    PRINT msg_menu

    MOV AH, 01h
    INT 21h

    CMP AL, '1'
    JE op_add
    CMP AL, '2'
    JE op_mul

    PRINT msg_newline
    PRINT msg_invalid_op
    JMP exit_prog

op_add:
    MOV operation, 1
    JMP continue_input

op_mul:
    MOV operation, 2

continue_input:
    PRINT msg_newline

    PRINT msg_input1
    LEA DX, buffer1
    MOV AH, 0Ah
    INT 21h
    PRINT msg_newline

    PRINT msg_input2
    LEA DX, buffer2
    MOV AH, 0Ah
    INT 21h
    PRINT msg_newline

    CALL ClearArrays

    LEA SI, buffer1 + 2
    LEA DI, num1
    LEA BX, sign1
    LEA CX, len1
    CALL ParseNumber
    JC error_exit

    LEA SI, buffer2 + 2
    LEA DI, num2
    LEA BX, sign2
    LEA CX, len2
    CALL ParseNumber
    JC error_exit

    CMP operation, 1
    JE do_addition
    CMP operation, 2
    JE do_multiplication
    JMP error_exit

do_addition:
    CALL DoAddition
    JMP show_result

do_multiplication:
    CALL DoMultiplication
    JMP show_result

show_result:
    PRINT msg_result
    CALL PrintResult
    PRINT msg_newline
    JMP exit_prog

error_exit:
    PRINT msg_error
    PRINT msg_newline

exit_prog:
    MOV AH, 4Ch
    INT 21h

;========================================
ClearArrays PROC
    PUSH AX
    PUSH CX
    PUSH DI

    XOR AL, AL

    LEA DI, num1
    MOV CX, MAX_DIGITS
clr_n1:
    MOV [DI], AL
    INC DI
    LOOP clr_n1

    LEA DI, num2
    MOV CX, MAX_DIGITS
clr_n2:
    MOV [DI], AL
    INC DI
    LOOP clr_n2

    LEA DI, result
    MOV CX, MAX_RESULT
clr_res:
    MOV [DI], AL
    INC DI
    LOOP clr_res

    MOV sign1, 0
    MOV sign2, 0
    MOV sign_result, 0

    POP DI
    POP CX
    POP AX
    RET
ClearArrays ENDP

;========================================
ParseNumber PROC
    PUSH AX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV DX, CX
    MOV BYTE PTR [BX], 0

    MOV AL, [SI]
    CMP AL, '-'
    JNE pn_check_plus
    MOV BYTE PTR [BX], 1
    INC SI
    JMP pn_count

pn_check_plus:
    CMP AL, '+'
    JNE pn_count
    INC SI

pn_count:
    PUSH SI
    XOR CX, CX

pn_count_loop:
    MOV AL, [SI]
    CMP AL, 13
    JE pn_count_done
    CMP AL, 0
    JE pn_count_done
    CMP AL, '$'
    JE pn_count_done
    INC CX
    INC SI
    JMP pn_count_loop

pn_count_done:
    PUSH BX
    MOV BX, DX
    MOV [BX], CX
    POP BX
    POP SI

    CMP CX, 0
    JE pn_error

    MOV AX, MAX_DIGITS
    SUB AX, CX
    ADD DI, AX

pn_convert:
    JCXZ pn_done
    MOV AL, [SI]
    CMP AL, '0'
    JB pn_error
    CMP AL, '9'
    JA pn_error
    SUB AL, '0'
    MOV [DI], AL
    INC SI
    INC DI
    DEC CX
    JMP pn_convert

pn_done:
    CLC
    JMP pn_exit

pn_error:
    STC

pn_exit:
    POP DI
    POP SI
    POP DX
    POP AX
    RET
ParseNumber ENDP

;========================================
CompareNumbers PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    LEA SI, num1
    LEA DI, num2
    MOV CX, MAX_DIGITS

cmp_loop:
    MOV AL, [SI]
    CMP AL, [DI]
    JNE cmp_done
    INC SI
    INC DI
    LOOP cmp_loop
    XOR AX, AX

cmp_done:
    POP DI
    POP SI
    POP CX
    POP AX
    RET
CompareNumbers ENDP

;========================================
DoAddition PROC
    PUSH AX
    PUSH SI
    PUSH DI

    MOV AL, sign1
    XOR AL, sign2
    JNZ add_diff_signs

    MOV AL, sign1
    MOV sign_result, AL
    CALL AddNumbers
    JMP add_done

add_diff_signs:
    CALL CompareNumbers
    JC add_num2_big
    JZ add_equal

    MOV AL, sign1
    MOV sign_result, AL
    LEA SI, num1
    LEA DI, num2
    CALL SubtractNumbers
    JMP add_done

add_num2_big:
    MOV AL, sign2
    MOV sign_result, AL
    LEA SI, num2
    LEA DI, num1
    CALL SubtractNumbers
    JMP add_done

add_equal:
    MOV sign_result, 0
    MOV len_result, 1

add_done:
    POP DI
    POP SI
    POP AX
    RET
DoAddition ENDP

;========================================
AddNumbers PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI

    LEA SI, num1 + MAX_DIGITS - 1
    LEA DI, num2 + MAX_DIGITS - 1
    LEA BX, result + MAX_RESULT - 1

    MOV CX, MAX_DIGITS
    XOR AH, AH

addn_loop:
    MOV AL, [SI]
    ADD AL, [DI]
    ADD AL, AH
    XOR AH, AH
    CMP AL, 10
    JB addn_no_carry
    SUB AL, 10
    MOV AH, 1
addn_no_carry:
    MOV [BX], AL
    DEC SI
    DEC DI
    DEC BX
    LOOP addn_loop

    MOV [BX], AH

    CALL CalcResultLen

    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
AddNumbers ENDP

;========================================
SubtractNumbers PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ADD SI, MAX_DIGITS - 1
    ADD DI, MAX_DIGITS - 1
    LEA BX, result + MAX_RESULT - 1

    MOV CX, MAX_DIGITS
    XOR DH, DH

subn_loop:
    MOV AL, [SI]
    MOV DL, [DI]
    ADD DL, DH
    XOR DH, DH
    CMP AL, DL
    JAE subn_no_borrow
    ADD AL, 10
    MOV DH, 1
subn_no_borrow:
    SUB AL, DL
    MOV [BX], AL
    DEC SI
    DEC DI
    DEC BX
    LOOP subn_loop

    CALL CalcResultLen

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SubtractNumbers ENDP

;========================================
; DoMultiplication - умножение столбиком
;========================================
DoMultiplication PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP

    ; Знак результата = XOR знаков операндов
    MOV AL, sign1
    XOR AL, sign2
    MOV sign_result, AL

    ; Очищаем result
    LEA DI, result
    MOV CX, MAX_RESULT
    XOR AL, AL
mul_clr:
    MOV [DI], AL
    INC DI
    LOOP mul_clr

    ; BP = смещение (позиция в result справа)
    XOR BP, BP

    ; Внешний цикл: по каждой цифре num2 (справа налево)
    MOV CX, MAX_DIGITS

mul_outer:
    PUSH CX

    ; Получаем цифру num2[MAX_DIGITS - 1 - BP]
    MOV AX, MAX_DIGITS - 1
    SUB AX, BP
    LEA SI, num2
    ADD SI, AX
    MOV DL, [SI]             ; DL = текущая цифра num2

    CMP DL, 0
    JNE mul_do_digit         ; Если не 0, умножаем
    JMP mul_next_outer       ; Иначе пропускаем

mul_do_digit:
    ; Позиция записи в result: MAX_RESULT - 1 - BP
    MOV AX, MAX_RESULT - 1
    SUB AX, BP
    LEA BX, result
    ADD BX, AX               ; BX = указатель на текущую позицию result

    XOR DH, DH               ; DH = перенос
    MOV CX, MAX_DIGITS

mul_inner:
    PUSH CX

    ; Получаем цифру num1[CX - 1]
    MOV AX, CX
    DEC AX
    LEA SI, num1
    ADD SI, AX
    MOV AL, [SI]             ; AL = цифра num1

    ; Умножаем: AX = AL * DL
    MUL DL                   ; AH:AL = результат (0..81)

    ; Добавляем перенос
    ADD AL, DH
    ADC AH, 0

    ; Добавляем к текущей позиции result
    ADD AL, [BX]
    ADC AH, 0

    ; Нормализуем: цифра должна быть 0-9
    XOR DH, DH               ; Новый перенос

mul_norm:
    CMP AL, 10
    JB mul_norm_done
    SUB AL, 10
    INC DH
    JMP mul_norm

mul_norm_done:
    ADD DH, AH               ; Добавляем старший байт к переносу
    MOV [BX], AL             ; Записываем цифру

    DEC BX                   ; Следующая позиция влево
    POP CX
    DEC CX
    JNZ mul_inner

    ; Записываем финальный перенос
mul_carry:
    CMP DH, 0
    JE mul_carry_done
    MOV AL, [BX]
    ADD AL, DH
    XOR DH, DH
    CMP AL, 10
    JB mul_carry_ok
    SUB AL, 10
    MOV DH, 1
mul_carry_ok:
    MOV [BX], AL
    DEC BX
    JMP mul_carry

mul_carry_done:

mul_next_outer:
    INC BP                   ; Следующее смещение
    POP CX
    DEC CX
    JNZ mul_outer

    ; Вычисляем длину результата
    CALL CalcResultLen

    ; Если результат 0, знак положительный
    CMP len_result, 1
    JNE mul_done
    LEA SI, result + MAX_RESULT - 1
    CMP BYTE PTR [SI], 0
    JNE mul_done
    MOV sign_result, 0

mul_done:
    POP BP
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DoMultiplication ENDP

;========================================
; CalcResultLen - вычисление длины результата
;========================================
CalcResultLen PROC
    PUSH AX
    PUSH CX
    PUSH SI

    LEA SI, result
    MOV CX, MAX_RESULT

crl_skip:
    CMP CX, 1
    JE crl_found
    MOV AL, [SI]
    CMP AL, 0
    JNE crl_found
    INC SI
    DEC CX
    JMP crl_skip

crl_found:
    MOV len_result, CX

    POP SI
    POP CX
    POP AX
    RET
CalcResultLen ENDP

;========================================
PrintResult PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    LEA DI, result_str

    ; Проверяем на ноль
    LEA SI, result
    MOV CX, MAX_RESULT
    XOR AH, AH
pr_chk0:
    MOV AL, [SI]
    OR AH, AL
    INC SI
    LOOP pr_chk0

    CMP AH, 0
    JE pr_zero

    ; Знак минус если нужно
    CMP sign_result, 1
    JNE pr_no_minus
    MOV BYTE PTR [DI], '-'
    INC DI
pr_no_minus:

    ; Находим первую ненулевую цифру
    LEA SI, result
    MOV CX, MAX_RESULT
pr_find:
    MOV AL, [SI]
    CMP AL, 0
    JNE pr_copy
    INC SI
    DEC CX
    JMP pr_find

pr_copy:
    CMP CX, 0
    JE pr_end
    MOV AL, [SI]
    ADD AL, '0'
    MOV [DI], AL
    INC SI
    INC DI
    DEC CX
    JMP pr_copy

pr_end:
    MOV BYTE PTR [DI], '$'
    JMP pr_print

pr_zero:
    LEA DI, result_str
    MOV BYTE PTR [DI], '0'
    MOV BYTE PTR [DI+1], '$'

pr_print:
    PRINT result_str

    POP DI
    POP SI
    POP CX
    POP AX
    RET
PrintResult ENDP

END START

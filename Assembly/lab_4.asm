.MODEL small
.STACK 100h

.DATA
X    DW 1234h       ; младшее слово 32-бит переменной
     DW 5678h       ; старшее слово

Result DW 0
       DW 0

; Макрос PUSHM X - загрузка
; Сначала старшее слово (будет глубже), потом младшее (на вершине)
PUSHM MACRO X
    push    word ptr X+2    ; старшее слово
    push    word ptr X      ; младшее слово
ENDM

; Макрос POPM X - извлечение
; Обратный порядок: сначала младшее, потом старшее
POPM MACRO X
    pop     word ptr X   ; младшке слово
    pop     word ptr X+2    ; старшее слово
ENDM

; Макрос CALLM P - вызов процедуры без использования CALL
; Кладём адрес возврата на стек и делаем JMP
CALLM MACRO P
    LOCAL RETADDR
    mov     ax, OFFSET RETADDR  ;  адрес возврата в AX
    push    ax                   ; Кладём на стек
    jmp     P         ; переходим к процедуре
RETADDR:
ENDM

; Макрос RETM N - возврат из процедуры без использования RET
; N - необязательный параметр (количество байт для очистки)
RETM MACRO N
    pop     bx                      ; извлекаем адрес возврата
    IFB <N>
            ;; N не указан - просто возврат
    ELSE
        IF N GT 0
            add sp, N   ; очищаем N байт параметров
        ENDIF
    ENDIF
    jmp     bx              ; Переход по адресу возврата
ENDM

; Макрос LOOPM L - цикл по CX без использования LOOP
LOOPM MACRO L
    dec     cx       ; CX = CX - 1
    jnz     L        ; если CX != 0, переход на метку L
ENDM

.CODE

; Тестовая процедура без параметров
TestProc PROC
    mov     ax, 1111h       ; какое-то действие
    RETM                    ; возврат без параметра
TestProc ENDP

; Тестовая процедура с параметром (2 байта на стеке)
TestProc2 PROC
    push    bp
    mov     bp, sp
    mov     ax, [bp+4]      ; получаем параметр
    pop     bp
    RETM    2               ; возврат с очисткой 2 байт
TestProc2 ENDP

MAIN PROC
    mov     ax, @data
    mov     ds, ax

    ;PUSHM/POPM
    PUSHM   X               ; кладём X (32 бита) на стек
    POPM    Result         ; Извлекаем в Result

    ;CALLM/RETM без параметра
    CALLM   TestProc

    ;Тест CALLM/RETM с параметром
    mov     ax, 5555h
    push    ax           ; параметр для процедуры
    CALLM   TestProc2

    ; Тест LOOPM
    mov     cx, 3         ; счётчик цикла
    xor     dx, dx        ; DX = 0
LoopStart:
    inc     dx              ; DX = DX + 1
    LOOPM   LoopStart       ; повторить пока CX != 0
    ; После цикла DX = 3


    mov     ax, 4C00h
    int     21h
MAIN ENDP

END MAIN

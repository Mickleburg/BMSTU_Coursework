
; TASM:
; TASM /m PM.asm
; TLINK /x /3 PM.obj
; PM.exe

; MASM:
; ML /c PM.asm
; LINK PM.obj,,NUL,,,
; PM.exe

        .386p                                           ; разрешить привилегированные инструкции i386

; СЕГМЕНТ КОДА (для Real Mode)
; ----------------------------------------------------------------------------------
RM_CODE     segment     para public 'CODE' use16
        assume      CS:RM_CODE,SS:RM_STACK
@@start:
                    mov                 AX,03h
                    int                 10h            ; текстовый режим 80x25 + очистка экрана

; открываем линию А20 (для 32-х битной адресации):
        in      AL,92h
        or      AL,2
        out     92h,AL

; вычисляем линейный адрес метки ENTRY_POINT (точка входа в защищенный режим):
        xor     EAX,EAX             ; обнуляем регистра EAX
        mov     AX,PM_CODE          ; AX = номер сегмента PM_CODE
        shl     EAX,4               ; EAX = линейный адрес PM_CODE
        add     EAX,offset ENTRY_POINT      ; EAX = линейный адрес ENTRY_POINT
        mov     dword ptr ENTRY_OFF,EAX     ; сохраняем его в переменной
; (кстати, подобный "трюк" называется SMC или Self Modyfing Code - самомодифицирующийся код)

; теперь надо вычислить линейный адрес GDT (для загрузки регистра GDTR):
        xor     EAX,EAX
        mov     AX,RM_CODE          ; AX = номер сегмента RM_CODE
        shl     EAX,4               ; EAX = линейный адрес RM_CODE
        add     AX,offset GDT           ; теперь EAX = линейный адрес GDT

; линейный адрес GDT кладем в заранее подготовленную переменную:
        mov     dword ptr GDTR+2,EAX
; а подобный трюк назвать SMC уже нельзя, потому как по сути мы модифицируем данные <img src="styles/smiles_s/smile3.gif" class="mceSmilie" alt=":smile3:" title="Smile3    :smile3:">

; собственно, загрузка регистра GDTR:
        lgdt        fword ptr GDTR

; запрет маскируемых прерываний:
        cli

; запрет немаскируемых прерываний:
        in      AL,70h
        or      AL,80h
        out     70h,AL

; переключение в защищенный режим:
        mov     EAX,CR0
        or      AL,1
        mov     CR0,EAX

; загрузить новый селектор в регистр CS
        db      66h             ; префикс изменения разрядности операнда
        db      0EAh                ; опкод команды JMP FAR
ENTRY_OFF   dd      ?               ; 32-битное смещение
        dw      00001000b           ; селектор первого дескриптора (CODE_descr)

; ТАБЛИЦА ГЛОБАЛЬНЫХ ДЕСКРИПТОРОВ:
GDT:
; нулевой дескриптор (обязательно должен присутствовать в GDT!):
NULL_descr  db      8 dup(0)
CODE_descr  db      0FFh,0FFh,00h,00h,00h,10011010b,11001111b,00h
DATA_descr  db      0FFh,0FFh,00h,00h,00h,10010010b,11001111b,00h
GDT_size    equ         $-GDT               ; размер GDT

GDTR        dw      GDT_size-1          ; 16-битный лимит GDT
        dd      ?               ; здесь будет 32-битный линейный адрес GDT
RM_CODE         ends
; -----------------------------------------------------------------------------



; СЕГМЕНТ СТЕКА (для Real Mode)
; -----------------------------------------------------------------------------
RM_STACK       segment          para stack 'STACK' use16
            db     100h dup(?)         ; 256 байт под стек - это даже много
RM_STACK       ends
; -----------------------------------------------------------------------------



; СЕГМЕНТ КОДА (для Protected Mode)
; -----------------------------------------------------------------------------
PM_CODE     segment     para public 'CODE' use32
        assume      CS:PM_CODE,DS:PM_DATA
ENTRY_POINT:
; загрузим сегментные регистры селекторами на соответствующие дескрипторы:
                 mov           AX,00010000b      ; селектор на второй дескриптор (DATA_descr)
     mov           DS,AX                         ; в DS его
     mov           ES,AX                         ; его же - в ES

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; создать каталог страниц
                mov        EDI,00100000h               ; его физический адрес - 1 Мб
    mov        EAX,00101007h               ; адрес таблицы 0 = 1 Мб + 4 Кб
    stosd                              ; записать первый элемент каталога
    mov        ECX,1023                    ; остальные элементы каталога -
    xor        EAX,EAX                     ; нули
    rep                 stosd
; заполнить таблицу страниц 0
                mov        EAX,00000007h               ; 0 - адрес страницы 0
    mov        ECX,1024                    ; число страниц в таблице
fill_page_table:
    stosd                              ; записать элемент таблицы
    add        EAX,00001000h               ; добавить к адресу 4096 байтов
    loop                fill_page_table        ; и повторить для всех элементов
; поместить адрес каталога страниц в CR3
                mov        EAX,00100000h               ; базовый адрес = 1 Мб
    mov        CR3,EAX
; включить страничную адресацию,
                mov        EAX,CR0
 or        EAX,80000000h
     mov           CR0,EAX
; а теперь изменить физический адрес страницы 12000h на 0B8000h
                mov        EAX,000B8007h
    mov        ES:00101000h+012h*4,EAX
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; вывод mes1 по стандартному адресу (начало видеопамяти 0B8000h)
    mov        EDI,0B8000h                 ; для команды movsw, EDI = начало видепамяти
    mov            ESI,PM_DATA                 ;
    shl            ESI,4
    add            ESI,offset mes1             ; ESI = адрес начала mes1
     mov           ECX,mes1_len                 ; длина текста в ECX
    rep            movsw                       ; DS:ESI (наше сообщение) -> ES:EDI
                                               ; (видеопамять)

; вывод mes2 по НЕСТАНДАРТНОМУ АДРЕСУ 12000h:
                mov            EDI,0120A0h     ; 12000h (уже можешь считать, что это
                                               ; 0B8000h) + A0h
                mov            ESI,PM_DATA
                shl            ESI,4
                add            ESI,offset mes2 ; ESI = адрес начала mes2
                mov            ECX,mes2_len     ; длина текста в ECX
                rep            movsw           ; DS:ESI (наше сообщение) -> ES:12000h
                                               ;(типа видеопамять)

    jmp            $                           ; погружаемся в вечный цикл
PM_CODE         ends
; -------------------------------------------------------------------------------------


; СЕГМЕНТ ДАННЫХ (для Protected Mode)
; -------------------------------------------------------------------------------------
PM_DATA         segment        para public 'DATA' use32
        assume         CS:PM_DATA

; сообщение, которое мы будем выводить на экран (оформим его в виде блока повторений irpc):
mes1:
irpc            mes1,          <This string was outputted to standart adress 0B8000h...>
                 db            '&mes1&',0Dh
endm
mes2:
irpc            mes2,          <And this one - to dummy adress 0120A0h. Cool? Now press RESET...>
                db             '&mes2&',0Bh
endm
mes1_len		equ			   55
mes2_len         equ           64                  ; длина в байтах
PM_DATA         ends
; ----------------------------------------------------------------------------------------------
                end         @@start

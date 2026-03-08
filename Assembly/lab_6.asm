        .386p

MY_NUMBER       equ     20

RM_CODE     segment     para public 'CODE' use16
        assume      CS:RM_CODE,SS:RM_STACK
@@start:
        mov     AX,03h
        int     10h

        in      AL,92h
        or      AL,2
        out     92h,AL

        xor     EAX,EAX
        mov     AX,PM_CODE
        shl     EAX,4
        add     EAX,offset ENTRY_POINT
        mov     dword ptr ENTRY_OFF,EAX

        xor     EAX,EAX
        mov     AX,RM_CODE
        shl     EAX,4
        add     AX,offset GDT
        mov     dword ptr GDTR+2,EAX

        lgdt    fword ptr GDTR

        cli
        in      AL,70h
        or      AL,80h
        out     70h,AL

        mov     EAX,CR0
        or      AL,1
        mov     CR0,EAX

        db      66h
        db      0EAh
ENTRY_OFF   dd      ?
        dw      00001000b

GDT:
NULL_descr  db      0,0,0,0,0,0,0,0
CODE_descr  db      0FFh,0FFh,00h,00h,00h,10011010b,11001111b,00h
DATA_descr  db      0FFh,0FFh,00h,00h,00h,10010010b,11001111b,00h
CUSTOM1_descr   db      0FFh,00Fh,00h,00h,14h,10010010b,01000000b,00h
INVALID1_descr  db      14h,00h,78h,56h,34h,10010010b,00100000b,12h
INVALID2_descr  db      20h,00h,00h,00h,00h,10001000b,00000000b,00h

GDT_size    equ     $-GDT
GDT_entries equ     GDT_size / 8

GDTR        dw      GDT_size-1
            dd      ?

RM_CODE     ends

RM_STACK    segment     para stack 'STACK' use16
            db      100h dup(?)
RM_STACK    ends

PM_CODE     segment     para public 'CODE' use32
            assume      CS:PM_CODE,DS:PM_DATA
ENTRY_POINT:
        mov     AX,00010000b
        mov     DS,AX
        mov     ES,AX
        mov     FS,AX
        mov     GS,AX
        mov     SS,AX

        xor     EAX,EAX
        mov     AX,PM_DATA
        shl     EAX,4
        mov     dword ptr DS:[data_seg_base],EAX

        xor     EAX,EAX
        mov     AX,RM_CODE
        shl     EAX,4
        add     EAX,offset GDT
        mov     dword ptr DS:[gdt_linear_addr],EAX

        mov     EDI,00100000h
        mov     EAX,00101007h
        stosd
        mov     ECX,1023
        xor     EAX,EAX
        rep     stosd

        mov     EDI,00101000h
        mov     EAX,00000007h
        mov     ECX,1024
fill_page_table:
        stosd
        add     EAX,00001000h
        loop    fill_page_table

        mov     EAX,000B8007h
        mov     dword ptr DS:[00101000h + MY_NUMBER*4],EAX

        mov     EAX,00100000h
        mov     CR3,EAX
        mov     EAX,CR0
        or      EAX,80000000h
        mov     CR0,EAX

        mov     EBX,MY_NUMBER
        shl     EBX,12

        mov     ESI,dword ptr DS:[gdt_linear_addr]
        mov     ECX,GDT_entries

        mov     EDI,EBX
        xor     EBP,EBP
        mov     byte ptr DS:[current_color],0Fh

process_descriptors:
        push    ECX
        push    ESI

        mov     EAX,dword ptr DS:[ESI]
        mov     dword ptr DS:[desc_low],EAX
        mov     EAX,dword ptr DS:[ESI+4]
        mov     dword ptr DS:[desc_high],EAX

        mov     AL,'D'
        call    print_char
        mov     EAX,EBP
        call    print_digit
        mov     AL,':'
        call    print_char
        mov     AL,' '
        call    print_char

        mov     EAX,dword ptr DS:[desc_low]
        shr     EAX,16
        and     EAX,0FFFFh
        mov     EDX,dword ptr DS:[desc_high]
        mov     ECX,EDX
        and     EDX,0FFh
        shl     EDX,16
        or      EAX,EDX
        and     ECX,0FF000000h
        or      EAX,ECX
        mov     dword ptr DS:[desc_base],EAX

        mov     EAX,dword ptr DS:[desc_low]
        and     EAX,0FFFFh
        mov     EDX,dword ptr DS:[desc_high]
        shr     EDX,16
        and     EDX,0Fh
        shl     EDX,16
        or      EAX,EDX
        mov     dword ptr DS:[desc_limit],EAX

        mov     EAX,dword ptr DS:[desc_high]
        mov     EDX,EAX
        shr     EAX,8
        mov     byte ptr DS:[desc_access],AL
        shr     EDX,16
        mov     byte ptr DS:[desc_gran],DL

        cmp     EBP,0
        jne     not_null_desc

        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_null
        call    print_string
        jmp     next_descriptor

not_null_desc:
        mov     DL,byte ptr DS:[desc_gran]
        test    DL,00100000b
        jz      bit21_ok

        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_invalid_bit21
        call    print_string
        jmp     print_base_limit

bit21_ok:
        mov     AL,byte ptr DS:[desc_access]
        test    AL,80h
        jz      not_present

        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_present
        call    print_string
        jmp     check_system_bit

not_present:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_not_present
        call    print_string
        jmp     print_base_limit

check_system_bit:
        mov     AL,byte ptr DS:[desc_access]
        test    AL,10h
        jnz     segment_descriptor

        mov     AL,byte ptr DS:[desc_access]
        and     AL,0Fh
        mov     byte ptr DS:[sys_type],AL

        cmp     AL,0
        je      invalid_sys_type
        cmp     AL,8
        je      invalid_sys_type
        cmp     AL,0Ah
        je      invalid_sys_type
        cmp     AL,0Dh
        je      invalid_sys_type

        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_system
        call    print_string
        mov     AL,byte ptr DS:[sys_type]
        call    print_hex_byte
        mov     AL,')'
        call    print_char
        jmp     print_base_limit

invalid_sys_type:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_invalid_systype
        call    print_string
        mov     AL,byte ptr DS:[sys_type]
        call    print_hex_byte
        mov     AL,')'
        call    print_char
        jmp     print_base_limit

segment_descriptor:
        mov     AL,byte ptr DS:[desc_access]
        test    AL,08h
        jnz     code_segment

        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_data
        call    print_string

        mov     AL,byte ptr DS:[desc_access]
        test    AL,04h
        jz      expand_up
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_expand_down
        call    print_string
        jmp     check_data_write
expand_up:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_expand_up
        call    print_string

check_data_write:
        mov     AL,byte ptr DS:[desc_access]
        test    AL,02h
        jz      data_readonly
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_writable
        call    print_string
        jmp     check_accessed
data_readonly:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_readonly
        call    print_string
        jmp     check_accessed

code_segment:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_code
        call    print_string

        mov     AL,byte ptr DS:[desc_access]
        test    AL,04h
        jz      non_conforming
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_conforming
        call    print_string
        jmp     check_code_read
non_conforming:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_non_conforming
        call    print_string

check_code_read:
        mov     AL,byte ptr DS:[desc_access]
        test    AL,02h
        jz      code_exec_only
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_readable
        call    print_string
        jmp     check_accessed
code_exec_only:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_exec_only
        call    print_string

check_accessed:
        mov     AL,byte ptr DS:[desc_access]
        test    AL,01h
        jz      not_accessed_seg
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_accessed
        call    print_string
        jmp     print_base_limit
not_accessed_seg:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_not_accessed
        call    print_string

print_base_limit:
        call    goto_next_line
        mov     AL,' '
        call    print_char
        call    print_char

        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_base
        call    print_string
        mov     EAX,dword ptr DS:[desc_base]
        call    print_hex32
        mov     AL,' '
        call    print_char

        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_limit
        call    print_string
        mov     EAX,dword ptr DS:[desc_limit]
        mov     DL,byte ptr DS:[desc_gran]
        test    DL,80h
        jz      limit_gran_byte
        inc     EAX
        shl     EAX,12
        jmp     print_limit_value
limit_gran_byte:
        inc     EAX
print_limit_value:
        call    print_hex32

        mov     AL,' '
        call    print_char
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_gran
        call    print_string
        mov     DL,byte ptr DS:[desc_gran]
        test    DL,80h
        jz      gran_byte
        mov     AL,'4'
        call    print_char
        mov     AL,'K'
        call    print_char
        jmp     print_dpl
gran_byte:
        mov     AL,'1'
        call    print_char
        mov     AL,'B'
        call    print_char

print_dpl:
        mov     AL,' '
        call    print_char
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_dpl
        call    print_string
        mov     AL,byte ptr DS:[desc_access]
        shr     AL,5
        and     AL,3
        add     AL,'0'
        call    print_char

        mov     AL,' '
        call    print_char
        mov     DL,byte ptr DS:[desc_gran]
        test    DL,40h
        jz      is_16bit
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_32bit
        call    print_string
        jmp     print_avl
is_16bit:
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_16bit
        call    print_string

print_avl:
        mov     AL,' '
        call    print_char
        mov     ESI,dword ptr DS:[data_seg_base]
        add     ESI,offset str_avl
        call    print_string
        mov     DL,byte ptr DS:[desc_gran]
        test    DL,10h
        jz      avl_zero
        mov     AL,'1'
        jmp     print_avl_val
avl_zero:
        mov     AL,'0'
print_avl_val:
        call    print_char

next_descriptor:
        call    goto_next_line

        mov     AL,byte ptr DS:[current_color]
        inc     AL
        cmp     AL,10h
        jb      color_not_wrap
        mov     AL,09h
color_not_wrap:
        mov     AH,AL
        and     AH,0Fh
        cmp     AH,0
        jne     color_ok
        inc     AL
color_ok:
        mov     byte ptr DS:[current_color],AL

        pop     ESI
        add     ESI,8
        inc     EBP
        pop     ECX
        dec     ECX
        jnz     process_descriptors

        jmp     $

print_char:
        push    EAX
        push    EDX
        mov     DL,byte ptr DS:[current_color]
        mov     AH,DL
        mov     word ptr ES:[EDI],AX
        add     EDI,2
        pop     EDX
        pop     EAX
        ret

print_string:
        push    EAX
ps_loop:
        mov     AL,byte ptr DS:[ESI]
        test    AL,AL
        jz      ps_done
        call    print_char
        inc     ESI
        jmp     ps_loop
ps_done:
        pop     EAX
        ret

print_hex32:
        push    EAX
        push    EBX
        push    ECX
        push    EDX
        mov     EDX,EAX
        mov     ECX,8
ph_loop:
        rol     EDX,4
        mov     AL,DL
        and     AL,0Fh
        cmp     AL,10
        jb      ph_digit
        add     AL,'A'-10
        jmp     ph_print
ph_digit:
        add     AL,'0'
ph_print:
        call    print_char
        dec     ECX
        jnz     ph_loop
        pop     EDX
        pop     ECX
        pop     EBX
        pop     EAX
        ret

print_hex_byte:
        push    EAX
        push    ECX
        push    EDX
        mov     DL,AL
        mov     ECX,2
phb_loop:
        rol     DL,4
        mov     AL,DL
        and     AL,0Fh
        cmp     AL,10
        jb      phb_digit
        add     AL,'A'-10
        jmp     phb_print
phb_digit:
        add     AL,'0'
phb_print:
        call    print_char
        dec     ECX
        jnz     phb_loop
        pop     EDX
        pop     ECX
        pop     EAX
        ret

print_digit:
        push    EAX
        and     AL,0Fh
        cmp     AL,10
        jb      pd_ok
        add     AL,'A'-10
        jmp     pd_print
pd_ok:
        add     AL,'0'
pd_print:
        call    print_char
        pop     EAX
        ret

goto_next_line:
        push    EAX
        push    EBX
        push    EDX
        mov     EAX,EDI
        mov     EBX,MY_NUMBER
        shl     EBX,12
        sub     EAX,EBX
        xor     EDX,EDX
        push    ECX
        mov     ECX,160
        div     ECX
        pop     ECX
        inc     EAX
        cmp     EAX,25
        jb      gnl_ok
        xor     EAX,EAX
gnl_ok:
        push    ECX
        mov     ECX,160
        imul    EAX,ECX
        pop     ECX
        mov     EBX,MY_NUMBER
        shl     EBX,12
        add     EAX,EBX
        mov     EDI,EAX
        pop     EDX
        pop     EBX
        pop     EAX
        ret

PM_CODE     ends

PM_DATA     segment     para public 'DATA' use32
            assume      CS:PM_DATA

data_seg_base   dd      0
gdt_linear_addr dd      0
desc_low        dd      0
desc_high       dd      0
desc_base       dd      0
desc_limit      dd      0
desc_access     db      0
desc_gran       db      0
sys_type        db      0
current_color   db      0Fh

str_null            db      'NULL descriptor',0
str_present         db      'P:1 ',0
str_not_present     db      'P:0 NOT PRESENT',0
str_system          db      'SYSTEM (type:',0
str_invalid_bit21   db      '** INVALID: bit21=1 **',0
str_invalid_systype db      '** INVALID: reserved sys type (',0
str_code            db      'CODE ',0
str_data            db      'DATA ',0
str_conforming      db      'Conf ',0
str_non_conforming  db      'NonConf ',0
str_readable        db      'R ',0
str_exec_only       db      'ExecOnly ',0
str_expand_up       db      'ExpUp ',0
str_expand_down     db      'ExpDown ',0
str_writable        db      'W ',0
str_readonly        db      'RO ',0
str_accessed        db      'A ',0
str_not_accessed    db      'NA ',0
str_base            db      'Base:',0
str_limit           db      'Lim:',0
str_gran            db      'G:',0
str_dpl             db      'DPL:',0
str_32bit           db      '32b',0
str_16bit           db      '16b',0
str_avl             db      'AVL:',0

PM_DATA     ends

            end     @@start

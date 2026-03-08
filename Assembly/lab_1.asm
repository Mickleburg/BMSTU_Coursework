assume cs: code, ds: data

data segment
A db 6
B db 2
C db 1
D db 2
res db ?
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    ; вычисляем a/b
    mov al, A
    mov ah, 0
    mov bl, B
    div bl      ; al = ax / bl, ah = ax % bl
    mov cl, al

    ; вычисляем d/c
    mov al, D
    mov ah, 0
    mov bl, C
    div bl

    ; складываем и декрементируем
    add cl, al
    dec cl

    ; сохраняем результат, также результат лежит в cx
    mov res, cl

    mov ax, 4c00h
    int 21h
code ends
end start

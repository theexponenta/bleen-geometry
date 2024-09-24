

; eax - number
; ecx - buffer
proc Strings.NumToString uses ebx
    mov ebx, 10
    xor edx, edx

    .CountDigitsLoop:
        div ebx

        add edx, '0'
        mov [ecx], dx
        add ecx, 2

        test eax, eax
        jne .CountDigitsLoop

    ret
endp

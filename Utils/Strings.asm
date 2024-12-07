

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


proc Strings.IsDigit Char
    mov eax, [Char]

   cmp ax, '0'
   jb .NotDigit
   cmp ax, '9'
   ja .NotDigit

   stc
   ret

   .NotDigit:
       clc
       ret
endp


proc Strings.IsLetter Char
    mov eax, [Char]
    or eax, 32
    cmp eax, 'a'
    jb .NotLetter
    cmp eax, 'z'
    ja .NotLetter

    stc
    ret

    .NotLetter:
        clc
        ret
endp


proc Strings.IsAlphanumeric Char
    stdcall Strings.IsLetter, [Char]
    jc .Alphanumeric
    stdcall Strings.IsDigit, [Char]
    jc .Alphanumeric

    clc
    ret

    .Alphanumeric:
        stc
        ret
endp


proc Strings.StringToFloat uses esi edi, strBuffer, strLen, numBuffer
     local multiplier1 dd 10.0
     local multiplier2 dd 0.1
     local currentDigit dw ?

     mov esi, [strBuffer]
     mov edi, [numBuffer]
     mov ecx, [strLen]

     fldz

     xor edx, edx
     cmp [esi], byte '-'
     jne .WholePartLoop

     inc esi
     dec ecx
     inc edx
     .WholePartLoop:
         movzx eax, byte [esi]
         inc esi
         cmp eax, '.'
         jne @F

         dec ecx
         jmp .ConvertFractionalPart

         @@:
         stdcall Strings.IsDigit, eax
         jnc .ReturnError

         fmul [multiplier1]
         sub ax, '0'
         mov [currentDigit], ax
         fiadd [currentDigit]
         loop .WholePartLoop

     .ConvertFractionalPart:
     cmp ecx, 0
     je .ReturnSuccess
     .FractionalPartLoop:
         movzx eax, byte [esi]
         inc esi

         stdcall Strings.IsDigit, eax
         jnc .ReturnError

         sub ax, '0'
         mov [currentDigit], ax
         fild [currentDigit]
         fmul [multiplier2]
         faddp

         fld [multiplier2]
         fdiv [multiplier1]
         fstp [multiplier2]
         loop .FractionalPartLoop

     .ReturnSuccess:
         test edx, edx
         jz @F
         fchs

         @@:
         fstp dword [edi]
         stc
         jmp .Return

     .ReturnError:
         fstp st0
         clc
         jmp .Return

      .Return:
          ret
endp


proc Strings.StringsEqual uses esi edi, str1Buf, str1Len, str2Buf, str2Len
   mov eax, [str1Len]
   cmp eax, [str2Len]
   jne .NotEqual

   mov esi, [str1Buf]
   mov edi, [str2Buf]
   mov ecx, [str1Len]
   inc ecx
   repe cmpsb
   cmp ecx, 0
   jne .NotEqual
   .Equal:
      stc
      jmp .Return

   .NotEqual:
      clc
      jmp .Return

   .Return:
       ret
endp
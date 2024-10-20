
; eax - num
; eax - result
proc Math.CountDigits uses ebx
    mov ebx, 10
    xor edx, edx
    xor ecx, ecx

    .CountDigitsLoop:
        inc ecx
        div ebx

        test eax, eax
        jne .CountDigitsLoop

    mov eax, ecx
    ret
endp


; st0 - result
proc Math.Distance X1, Y1, X2, Y2
    fld [X1]
    fsub [X2]
    fmul st0, st0
    fld [Y1]
    fsub [Y2]
    fmul st0, st0
    faddp
    fsqrt

    ret
endp


; Calculates max(st0, st1), stores result in st0
; and deletes another number from the FPU stack
proc Math.FPUMax
    fcomi st0, st1
    jbe .Return

    fxch st1

    .Return:
    fstp st0
    ret
endp


; Calculates min(st0, st1), stores result in st0
; and deletes another number from the FPU stack
proc Math.FPUMin
    fcomi st0, st1
    jae .Return

    fxch st1

    .Return:
    fstp st0
    ret
endp


; eax - integer number
proc Math.IntToFloat
   locals
       FloatValue dd ?
   endl

   mov [FloatValue], eax
   fild [FloatValue]
   fstp [FloatValue]
   mov eax, [FloatValue]

   ret
endp


; eax - number
; Returns 1 if number > 0, -1 if number < 0, 0 if number is 0
proc Math.Sign
    test eax, eax
    jz .Return

    cdq
    or edx, 1
    mov eax, edx

   .Return:
   ret
endp


proc Math.Pow Base, Exponent
    locals
        IntExp dd ?
    endl

  fld     [Exponent]
  fld     st0            ;{copy to st(1)}
  fabs                   ;{abs(exp)}
  fild     [MaxInt]
  fcompp                 ;{leave exp in st0}
  fstsw   ax
  sahf
  jb      .RealPower    ;{exp > MaxInt}
  fld     st             ;{exp in st0 and st1}
  frndint                ;{round(exp)}
  fcomp                  ;{compare exp and round(exp)}
  fstsw   ax
  sahf
  jne     .RealPower
  fistp   [IntExp]
  mov     eax, [IntExp]    ;{eax=Integer(Exponent)}
  mov     ecx, eax
  cdq
  fld1                   ;{Result=1}
  xor     eax, edx
  sub     eax, edx       ;{abs(exp)}
  jz      .Exit
  fld     [Base]
  jmp     .Entry
.Loop:
  fmul    st, st         ;{Base * Base}
.Entry:
  shr     eax, 1
  jnc     .Loop
  fmul    st1, st      ;{Result * X}
  jnz     .Loop
  fstp    st
  cmp     ecx, 0
  jge     .Exit
  fld1
  fdivrp                 ;{1/Result}
  jmp     .Exit
.RealPower:
  fld     [Base]
  ftst
  fstsw   ax
  sahf
  jz      .Done
  fldln2
  fxch
  fyl2x
  fxch
  fmulp   st1, st
  fldl2e
  fmulp   st1, st
  fld     st0
  frndint
  fsub    st1, st
  fxch    st1
  f2xm1
  fld1
  faddp   st1, st
  fscale
.Done:
  fstp    st1
.Exit:
 ret
endp


; X1, Y1, X2, Y2 - coordinates of two points defining the line
; X, Y - coordinates to calculate distance from
proc Math.DistanceLinePoint X1, Y1, X2, Y2, X, Y
    ; Let (x_d, y_d) be a direction vector of the line (x_d = X2 - X1, y_d = Y2 - Y1)
    ; (X, Y) is the point to check
    ; Let (x_m, y_m) be a vector from (X, Y) to (X1, Y1) (x_m = X1 - X, y_m = X1 - Y)
    ;
    ;
    ; So, distance between the line and the point is calculated as
    ; D = abs(x_d * y_m - y_d * x_m) / sqrt(x_d^2 + y_d^2)

    ; Calculate direction vector of line (x_d, y_d)
    fld [X2]
    fsub [X1]
    fld [Y2]
    fsub [Y1]

    ; Caclculate (x_m, y_m)
    fld [X1]
    fsub [X]
    fld [Y1]
    fsub [Y]

    ; Caclucalte x_d * y_m
    fld st3 ; x_d
    fmulp st1, st0 ; * y_m

    ; Calculate y_d * x_m
    fld st2 ; y_d
    fmulp st2, st0 ; * x_m

    ; Caclucalte abs(x_d * y_m - y_d * x_m)
    fsubp
    fabs

    ; Caclucalte sqrt(x_d^2 + y_d^2)
    fld st2
    fmulp st3, st0
    fld st1
    fmulp st2, st0

    ; Move abs(x_d * y_m - y_d * x_m) to st2 to be able to add x_d^2 and y_d^2
    fxch st2
    faddp
    fsqrt

    ; Resutlting distance
    fdivp

    ret
endp


proc Math.IsSegmentOnPosition X1, Y1, X2, Y2, X, Y, Width
    ; Let d be a distance between point (X, Y) and segement line
    ; Let X1, X2 be x-coordinates of segment edge points
    ; Let w be width of segment line
    ;
    ; Segment is on given position if the following conditions are met:
    ;
    ; min(X1, X2) <= X <= max(X1, X2)
    ; d <= w

    ; To determine if the segment is on given position,
    ; we need to calculate distance between point and the line of the segment,
    ; then compare it with width of the segment, and finally determine if
    ; x-coordinate of the given point lies between x1 and x2

    ; Caclulate min(X1, X2) and max(X1, X2)
    fld [X1]
    fld [X2]
    fld st0
    fld st2
    stdcall Math.FPUMin
    fxch st2
    stdcall Math.FPUMax

    fld [X]

    mov eax, 1

    fcomi st0, st1
    jbe @F

    xor eax, eax
    jmp .EndXCheck

    @@:
    fcomi st0, st2
    jae .EndXCheck

    xor eax, eax

    .EndXCheck:
        fstp st0
        fstp st0
        fstp st0
        test eax, eax
        jz .Return

    ; Resutlting distance
    stdcall Math.DistanceLinePoint, [X1] ,[Y1], [X2], [Y2], [X], [Y]
    fld [Width]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


; st0 - number
; 2 lower bits of eax - mode
proc Math.RoundWithMode
    locals
        PrevCW dw ?
        TempCW dw ?
    endl

    fstcw [PrevCW]
    fstcw [TempCW]
    movzx edx, [TempCW]
    and edx, 1111_0011_1111_1111b
    shl eax, 10
    or edx, eax
    mov [TempCW], dx
    fldcw [TempCW]

    frndint

    fldcw [PrevCW]

    ret
endp


; st0 - number to trunc
proc Math.Trunc
    mov eax, 11b
    call Math.RoundWithMode
    ret
endp


; st0 - number to ceil
proc Math.Ceil
    mov eax, 10b
    call Math.RoundWithMode
    ret
endp


proc Math.Floor
    mov eax, 01b
    call Math.RoundWithMode
    ret
endp


proc Math.Round
    mov eax, 00b
    call Math.RoundWithMode
    ret
endp


; st0 - number
proc Math.Log10
    fldlg2
    fxch
    fyl2x
    ret
endp


; Returns: eax - Rotated X coordinate
;          edx - Rotated Y coordinate
proc Math.RotatePoint, X, Y, Angle, OrgX, OrgY
    locals
        RotatedX dd ?
        RotatedY dd ?
    endl

    fld [X]
    fsub [OrgX]
    fld [Y]
    fsub [OrgY]
    fld [Angle]
    fsincos

    fld st3
    fmul st0, st1
    fld st3
    fmul st0, st3
    fsubp
    fadd [OrgX]

    fld st4
    fmul st0, st3
    fld st4
    fmul st0, st3
    faddp
    fadd [OrgY]

    fstp [RotatedY]
    fstp [RotatedX]
    mov eax, [RotatedX]
    mov edx, [RotatedY]

    fstp st0
    fstp st0
    fstp st0
    fstp st0
    ret
endp


; eax - number
proc Math.IntToStr uses edi, pBuffer
    mov edi, [pBuffer]
    cmp eax, 0
    jge @F

    mov byte [edi], '-'
    inc edi
    neg eax

    @@:
    push -1 ; marker of end
    mov ecx, 10
    xor edx, edx
    .GetDigitsLoop:
        div ecx
        push edx
        xor edx, edx
        test eax, eax
        jnz .GetDigitsLoop

    .WriteDigitsLoop:
        pop eax
        cmp eax, -1
        je .Finish

        add eax, '0'
        mov byte [edi], al
        inc edi
        jmp .WriteDigitsLoop

    .Finish:
    mov byte [edi], 0
    ret
endp


; st0 - number to convert
proc Math.FloatToStr uses edi, pBuffer, Precision
    locals
        IntPart dd ?
        Ten dq 10f
        Digit dd ?
        PrevCW dw ?
        TempCW dw ?
        IsNegative db 0
    endl

    fstcw [PrevCW]

    mov edi, [pBuffer]

    fldz
    fcomip st0, st1
    jbe @F

    mov byte [edi], '-'
    inc edi
    fabs
    mov [IsNegative], 1

    @@:
    ;fild [MaxInt]
    ;fcomip st0, st1
    ;jb .BigNumber

    ;fld st0
    ;call Math.Trunc
    ;fistp [IntPart]
    ;mov eax, [IntPart]
    ;stdcall Math.IntToStr, edi

    ;xor eax, eax
    ;mov ecx, -1
    ;cld
    ;repnz scasb
    ;dec edi

    ;jmp .ExtractFractionalPart

    ; If number is bigger than MaxInt, extract its digits using FPU instructions
    .BigNumber:
        push -1
        fld st0
        .ExtractDigitstLoop:
            fld st0
            fdiv [Ten]
            call Math.Trunc
            fmul [Ten]
            fsubr st0, st1
            call Math.Trunc
            fistp [Digit]
            push [Digit]
            fdiv [Ten]
            fld1
            fcomip st0, st1
            jbe .ExtractDigitstLoop

        fstp st0
        .WriteIntegerPartLoop:
            pop eax
            cmp eax, -1
            je .ExtractFractionalPart

            add eax, '0'
            mov byte [edi], al
            inc edi
            jmp .WriteIntegerPartLoop

    .ExtractFractionalPart:
        mov ecx, [Precision]
        test ecx, ecx
        jz .Finish

        mov byte [edi], '.'
        inc edi

        fld st0
        call Math.Trunc
        fsubr st0, st1
        .ExtractFractionalPartLoop:
            fmul [Ten]
            fabs
            fld st0
            call Math.Trunc
            fistp [Digit]
            mov eax, [Digit]
            add eax, '0'
            mov byte [edi], al
            inc edi
            fld st0
            call Math.Trunc
            fsubp st1, st0
            loop .ExtractFractionalPartLoop

        fstp st0

    .Finish:
    cmp [IsNegative], 0
    je @F

    fchs

    @@:
    mov byte [edi], 0
    fldcw [PrevCW]
    ret
endp


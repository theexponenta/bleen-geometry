
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

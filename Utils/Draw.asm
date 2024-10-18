

proc Draw.Circle, hdc, X, Y, Radius
    fld [X]
    fistp [X]
    fld [Y]
    fistp [Y]

    mov eax, [X]
    mov edx, [Y]
    mov ecx, [Radius]

    add edx, ecx ; Lower-right Y
    add eax, ecx ; Lower-right X
    push edx eax
    shl ecx, 1
    sub edx, ecx ; Upper-left Y
    sub eax, ecx ; Upper-left X
    push edx eax [hdc]
    invoke Ellipse

    ret
endp


proc Draw.Ellipse, hdc, CenterX, CenterY, SemiMinor, SemiMajor
    mov eax, [CenterX]
    mov edx, [CenterY]
    add eax, [SemiMajor]
    add edx, [SemiMinor]
    push edx eax
    mov ecx, [SemiMajor]
    shl ecx, 1
    sub eax, ecx
    mov ecx, [SemiMinor]
    shl ecx, 1
    sub edx, ecx
    push edx eax
    push [hdc]
    invoke Ellipse

    ret
endp


proc Draw.Line uses ebx, hdc, X1, Y1, X2, Y2, Width, Color
    invoke CreatePen, PS_SOLID, [Width], [Color]
    mov ebx, eax
    invoke SelectObject, [hdc], eax

    fld [X1]
    fistp [X1]
    fld [X2]
    fistp [X2]
    fld [Y1]
    fistp [Y1]
    fld [Y2]
    fistp [Y2]

    invoke MoveToEx, [hdc], [X1], [Y1], NULL
    invoke LineTo, [hdc], [X2], [Y2]

    invoke GetStockObject, DC_PEN
    invoke SelectObject, [hdc], eax
    invoke DeleteObject, ebx

    ret
endp


; eax - Color
; edx - Opacity
proc Draw.GetColorWithOpacity
    and eax, 0xFFFFFF
    shl edx, 24
    or eax, edx

   ret
endp

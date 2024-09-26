
proc Draw.Circle, hdc, X, Y, Radius
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


proc Draw.Line uses ebx, pGdipGraphics, X1, Y1, X2, Y2, Width, Color
    locals
        GpPen dd ?
    endl

    lea eax, [GpPen]
    invoke GdipCreatePen1, [Color], [Width], NULL, eax
    mov ebx, eax
    ;invoke SelectObject, [hdc], eax

    invoke GdipDrawLineI, [pGdipGraphics], [GpPen], [X1], [Y1], [X2], [Y2]
    ;invoke MoveToEx, [hdc], [X1], [Y1], NULL
    ;invoke LineTo, [hdc], [X2], [Y2]

    invoke GdipDeletePen, [GpPen]

    ;invoke GetStockObject, DC_PEN
    ;invoke SelectObject, [hdc], eax
    ;invoke DeleteObject, ebx

    ret
endp

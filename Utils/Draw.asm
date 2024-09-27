
proc Draw.Circle pGdipGraphics, X, Y, Radius, Width, Color
    locals
        GpPen dd ?
    endl

    lea eax, [GpPen]
    invoke GdipCreatePen1, [Color], [Width], NULL, eax

    mov eax, [X]
    mov ecx, [Y]
    mov edx, [Radius]

    sub ecx, edx ; Upper-left Y
    sub eax, edx ; Upper-left X
    shl edx, 1

    invoke GdipDrawEllipseI, [pGdipGraphics], [GpPen], eax, ecx, edx, edx
    invoke GdipDeletePen, [GpPen]

    ret
endp


proc Draw.FillCircle pGdipGraphics, X, Y, Radius, Color
    locals
        GpBrush dd ?
    endl

    lea eax, [GpBrush]
    invoke GdipCreateSolidFill, [Color], eax

    mov eax, [X]
    mov ecx, [Y]
    mov edx, [Radius]

    sub ecx, edx ; Upper-left Y
    sub eax, edx ; Upper-left X
    shl edx, 1

    invoke GdipFillEllipseI, [pGdipGraphics], [GpBrush], eax, ecx, edx, edx
    invoke GdipDeleteBrush, [GpBrush]

    ret
endp



proc Draw.Line uses ebx, pGdipGraphics, X1, Y1, X2, Y2, Width, Color
    locals
        GpPen dd ?
    endl

    lea eax, [GpPen]
    invoke GdipCreatePen1, [Color], [Width], NULL, eax
    invoke GdipDrawLineI, [pGdipGraphics], [GpPen], [X1], [Y1], [X2], [Y2]
    invoke GdipDeletePen, [GpPen]

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

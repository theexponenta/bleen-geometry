
proc Draw.Circle pGdipGraphics, X, Y, Radius, Width, Color
    locals
        GpPen dd ?
        Two dq 2f
    endl

    lea eax, [GpPen]
    invoke GdipCreatePen1, [Color], [Width], NULL, eax

    fld [Radius]
    fld [X]
    fsub st0, st1
    fstp [X]
    fld [Y]
    fsub st0, st1
    fstp [Y]
    fld [Two]
    fmulp
    fstp [Radius]

    invoke GdipDrawEllipse, [pGdipGraphics], [GpPen], [X], [Y], [Radius], [Radius]
    invoke GdipDeletePen, [GpPen]

    ret
endp


proc Draw.FillCircle pGdipGraphics, X, Y, Radius, Color
    locals
        GpBrush dd ?
        Two dq 2f
    endl

    lea eax, [GpBrush]
    invoke GdipCreateSolidFill, [Color], eax

    fld [Radius]
    fld [X]
    fsub st0, st1
    fstp [X]
    fld [Y]
    fsub st0, st1
    fstp [Y]
    fld [Two]
    fmulp
    fstp [Radius]

    invoke GdipFillEllipse, [pGdipGraphics], [GpBrush], [X], [Y], [Radius], [Radius]
    invoke GdipDeleteBrush, [GpBrush]

    ret
endp



proc Draw.Line uses ebx, pGdipGraphics, X1, Y1, X2, Y2, Width, Color
    locals
        GpPen dd ?
    endl

    lea eax, [GpPen]
    invoke GdipCreatePen1, [Color], [Width], NULL, eax
    invoke GdipDrawLine, [pGdipGraphics], [GpPen], [X1], [Y1], [X2], [Y2]
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

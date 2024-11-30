
proc Segment.Create Id, pName, pCaption, Point1Id, Point2Id, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_SEGMENT, [pName], [pCaption]

    mov eax, [Point1Id]
    mov [ebx + Segment.Point1Id], eax

    mov eax, [Point2Id]
    mov [ebx + Segment.Point2Id], eax

    mov eax, [Width]
    mov [ebx + Segment.Width], eax

    mov eax, [Color]
    mov [ebx + Segment.Color], eax

    ret
endp


proc Segment.Draw uses ebx edi, hdc
    locals
        X1 dd ?
        Y1 dd ?
        X2 dd ?
        Y2 dd ?

        SelectedWidth dd ?
    endl

    mov eax, [ebx + Segment.Point1Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov ecx, [eax + Point.Y]
    mov [ebx + Segment.Point1.x], edx
    mov [ebx + Segment.Point1.y], ecx
    stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
    mov [X1], edx
    mov [Y1], eax

    mov eax, [ebx + Segment.Point2Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov ecx, [eax + Point.Y]
    mov [ebx + Segment.Point2.x], edx
    mov [ebx + Segment.Point2.y], ecx
    stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
    mov [X2], edx
    mov [Y2], eax

    cmp [ebx + Segment.IsSelected], 0
    jz @F

    fild [ebx + Segment.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    stdcall Draw.Line, [hdc], [X1], [Y1], [X2], [Y2], [SelectedWidth], GeometryObject.SelectedLineColor

    @@:
    stdcall Draw.Line, [hdc], [X1], [Y1], [X2], [Y2], GeometryObject.DefaultLineWidth, [ebx + Segment.Color]

    .Return:
    ret
endp


proc Segment.IsOnPosition uses edi, X, Y
    locals
        X1 dd ?
        Y1 dd ?
        X2 dd ?
        Y2 dd ?
        WidthScaled dd ?
    endl

    fild [ebx + Segment.Width]
    fdiv [Scale]
    fstp [WidthScaled]

    stdcall Math.IsSegmentOnPosition, [ebx + Segment.Point1.x], [ebx + Segment.Point1.y], [ebx + Segment.Point2.x], [ebx + Segment.Point2.y], \
                                      [X], [Y], [WidthScaled]

    ret
endp


; edx - dX
; ecx - dY
proc Segment.Move uses esi
    mov esi, ebx

    mov eax, [esi + Segment.Point1Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    mov eax, [esi + Segment.Point2Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

   ret
endp


proc Segment.ToString, pBuffer
    mov eax, [ebx + Segment.Point2Id]
    stdcall Main.FindPointById
    push [eax + GeometryObject.pName]

    mov eax, [ebx + Segment.Point1Id]
    stdcall Main.FindPointById
    push [eax + GeometryObject.pName]

    cinvoke sprintf, [pBuffer], Segment.StrFormat ; Format arguments are pushed above
    add esp, 4*2

    ret
endp
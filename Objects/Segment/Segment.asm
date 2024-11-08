
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
    stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
    mov [X1], edx
    mov [Y1], eax

    mov eax, [ebx + Segment.Point2Id]
    call Main.FindPointById
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
    stdcall Draw.Line, [hdc], [X1], [Y1], [X2], [Y2], [ebx + Segment.Width], [ebx + Segment.Color]

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

    mov eax, [ebx + Segment.Point1Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov [X1], edx
    mov edx, [eax + Point.Y]
    mov [Y1], edx

    mov eax, [ebx + Segment.Point2Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov [X2], edx
    mov edx, [eax + Point.Y]
    mov [Y2], edx

    fild [ebx + Segment.Width]
    fdiv [Scale]
    fstp [WidthScaled]

    stdcall Math.IsSegmentOnPosition, [X1] ,[Y1], [X2], [Y2], [X], [Y], [WidthScaled]

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

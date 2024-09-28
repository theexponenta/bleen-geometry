
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

    mov eax, [ebx + Segment.Color]
    mov edx, GeometryObject.SelectedLineShadowOpacity
    call Draw.GetColorWithOpacity
    fld dword [ebx + Segment.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fstp [SelectedWidth]
    stdcall Draw.Line, [DrawArea.pGdipGraphics], [X1], [Y1], [X2], [Y2], [SelectedWidth], eax

    @@:
    stdcall Draw.Line, [DrawArea.pGdipGraphics], [X1], [Y1], [X2], [Y2], GeometryObject.DefaultLineWidth, [ebx + Segment.Color]

    .Return:
    ret
endp


proc Segment.IsOnPosition uses edi, X, Y
    locals
        X1 dd ?
        Y1 dd ?
        X2 dd ?
        Y2 dd ?
    endl

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

    ;mov edi, [ebx + Segment.AttachedPointsIds.Ptr]

    ;mov eax, [edi]
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
    fld [ebx + Segment.Width]
    fdiv [Scale]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


; edx - dX
; ecx - dY
proc Segment.Move ; uses esi
    ;call GeometryObject.Move
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

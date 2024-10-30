
proc PolylineObj.Create uses ebx, Id, pName, pCaption, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_POLYLINE, [pName], [pCaption]

    mov eax, [Width]
    mov [ebx + PolylineObj.Width], eax

    mov eax, [Color]
    mov [ebx + PolylineObj.Color], eax

    add ebx, PolylineObj.PointsIds
    stdcall Vector.Create, 4, 0, PolylineObj.PointsIds.InitialCapacity

    ret
endp


proc PolylineObj.Draw uses esi, hdc
    locals
        CurPoint POINT ?
        SelectedWidth dd ?
        hPenMain dd ?
        hPenSelected dd 0
    endl

    mov esi, [ebx + PolylineObj.PointsIds.Ptr]
    mov ecx, [ebx + PolylineObj.PointsIds.Length]
    cmp ecx, 2
    jb .Return

    .PushPoints:
        mov eax, [esi]

        push ecx
        stdcall Main.FindPointById
        stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
        pop ecx

        mov [CurPoint.x], edx
        mov [CurPoint.y], eax
        fld [CurPoint.x]
        fistp [CurPoint.x]
        fld [CurPoint.y]
        fistp [CurPoint.y]

        push [CurPoint.y] [CurPoint.x]

        add esi, 4
        loop .PushPoints

    cmp [ebx + PolylineObj.IsSelected], 0
    jz @F

    fild [ebx + PolylineObj.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    invoke CreatePen, PS_SOLID, [SelectedWidth], GeometryObject.SelectedLineColor
    mov [hPenSelected], eax
    invoke SelectObject, [hdc], eax

    mov eax, esp
    invoke Polyline, [hdc], eax, [ebx + PolylineObj.PointsIds.Length]

    invoke DeleteObject, [hPenSelected]

    @@:
    invoke CreatePen, PS_SOLID, [ebx + PolylineObj.Width], [ebx + PolylineObj.Color]
    mov [hPenMain], eax
    invoke SelectObject, [hdc], eax

    mov ecx, [ebx + PolylineObj.PointsIds.Length]
    mov eax, esp
    push ecx
    invoke Polyline, [hdc], eax, ecx
    pop ecx

    shl ecx, 2
    add esp, ecx

    invoke DeleteObject, [hPenMain]

    .Return:
    ret
endp


proc PolylineObj.Move uses esi edi ebx
    mov esi, [ebx + PolylineObj.PointsIds.Ptr]
    mov edi, [ebx + PolylineObj.PointsIds.Length]

    .MoveLoop:
        mov eax, [esi]

        push edx ecx
        call Main.FindPointById
        pop ecx edx

        mov ebx, eax
        call Point.Move

        add esi, 4
        sub edi, 1
        jnz .MoveLoop

    ret
endp


proc PolylineObj.IsOnPosition uses esi, X, Y
    local WidthScaled dd ?

    ;stdcall Math.IsSegmentOnPosition, [X1] ,[Y1], [X2], [Y2], [X], [Y], [WidthScaled]

    fild [ebx + Segment.Width]
    fdiv [Scale]
    fstp [WidthScaled]

    mov esi, [ebx + PolylineObj.PointsIds.Ptr]
    mov ecx, [ebx + PolylineObj.PointsIds.Length]
    sub ecx, 1

    .CheckSegementsLoop:
        push [WidthScaled]
        push [Y]
        push [X]

        mov eax, [esi]
        push ecx
        call Main.FindPointById
        pop ecx

        push [eax + Point.Y]
        push [eax + Point.X]

        mov eax, [esi + 4]
        push ecx
        call Main.FindPointById
        pop ecx

        push [eax + Point.Y]
        push [eax + Point.X]

        stdcall Math.IsSegmentOnPosition
        test eax, eax
        jnz .Return

        add esi, 4
        loop .CheckSegementsLoop

     xor eax, eax

    .Return:
    ret
endp


proc PolylineObj.DependsOnObject uses esi, Id
    mov eax, [Id]
    mov esi, [ebx + PolylineObj.PointsIds.Ptr]
    mov ecx, [ebx + PolylineObj.PointsIds.Length]

    .CheckPointsLoop:
        cmp eax, [esi]
        je .Finish
        add esi, 4
        loop .CheckPointsLoop

    .Finish:
    mov eax, ecx ; If found, ecx is nonzero
    ret
endp


proc CircleWithCenter.Create Id, pName, pCaption, CenterPointId, SecondPointId, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_CIRCLE_WITH_CENTER, [pName], [pCaption]
    
    mov eax, [CenterPointId]
    mov [ebx + CircleWithCenter.CenterPointId], eax

    mov eax, [SecondPointId]
    mov [ebx + CircleWithCenter.SecondPointId], eax

    mov eax, [Width]
    mov [ebx + CircleWithCenter.Width], eax

    mov eax, [Color]
    mov [ebx + CircleWithCenter.Color], eax

    ret
endp


proc CircleWithCenter.Draw hdc
    locals
        Radius dd ?
        CenterX dd ?
        CenterY dd ?

        hPenMain dd ?
        hPenSelected dd 0

        SelectedWidth dd ?
    endl

    ; Calculate radius + save center points
    mov eax, [ebx + CircleWithCenter.CenterPointId]
    stdcall Main.FindPointById
    stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
    push eax edx
    mov [CenterX], edx
    mov [CenterY], eax
    mov eax, [ebx + CircleWithCenter.SecondPointId]
    stdcall Main.FindPointById
    stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
    push eax edx
    stdcall Math.Distance
    fistp [Radius]

    invoke GetStockObject, NULL_BRUSH
    invoke SelectObject, [hdc], eax

    cmp [ebx + Segment.IsSelected], 0
    jz @F


    fild [ebx + Segment.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    invoke CreatePen, PS_SOLID, [SelectedWidth], GeometryObject.SelectedLineColor
    mov [hPenSelected], eax
    invoke SelectObject, [hdc], eax

    stdcall Draw.Circle, [hdc], [CenterX], [CenterY], [Radius]


    @@:
    invoke CreatePen, PS_SOLID, [ebx + CircleWithCenter.Width], [ebx + CircleWithCenter.Color]
    mov [hPenMain], eax
    invoke SelectObject, [hdc], eax

    stdcall Draw.Circle, [hdc], [CenterX], [CenterY], [Radius]

    invoke GetStockObject, DC_PEN
    invoke SelectObject, [hdc], eax

    invoke DeleteObject, [hPenMain]
    cmp [hPenSelected], 0
    je .Return

    invoke DeleteObject, [hPenSelected]

    .Return:
    ret
endp


proc CircleWithCenter.IsOnPosition X, Y
    locals
        CenterX dd ?
        CenterY dd ?
        WidthScaled dd ?
    endl

    ; Let x0, y0 be coordinates of circle center,
    ; X, Y - coordinates of given point, r - radius of circle
    ; w - width of circle line
    ;
    ; Circle is on positiob (X, Y) if:
    ; r - w <= sqrt((x0 - X)^2 + (y0 - Y)^2) <= r + w

    fild [ebx + CircleWithCenter.Width]
    fdiv [Scale]
    fstp [WidthScaled]

    mov eax, [ebx + CircleWithCenter.CenterPointId]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov ecx, [eax + Point.Y]
    mov [CenterX], edx
    mov [CenterY], ecx
    push ecx edx

    mov eax, [ebx + CircleWithCenter.SecondPointId]
    stdcall Main.FindPointById
    push [eax + Point.Y] [eax + Point.X]

    stdcall Math.Distance
    fsub [WidthScaled]

    ; Calculate sqrt((x0 - X)^2 + (y0 - Y)^2)
    fld [CenterX]
    fsub [X]
    fmul st0, st0
    fld [CenterY]
    fsub [Y]
    fmul st0, st0
    faddp
    fsqrt

    fcomi st0, st1
    jb .ReturnFalse

    ; The first value on the stack is r - w
    ; We add w*2 to it to get r + w and then
    ; compare it with distance
    fld [WidthScaled]
    fadd st2, st0
    faddp st2, st0

    fcomi st0, st1
    ja .ReturnFalse

    mov eax, 1
    jmp .Return

    .ReturnFalse:
        xor eax, eax

    .Return:
    fstp st0
    fstp st0
    ret
endp


proc CircleWithCenter.Move uses ebx edi
    mov esi, ebx

    mov eax, [esi + CircleWithCenter.CenterPointId]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    mov eax, [esi + CircleWithCenter.SecondPointId]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

   ret
endp


proc PerpendicularBisector.Create, Id, pName, pCaption, Point1Id, Point2id, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_PERPENDICULAR_BISECTOR, [pName], [pCaption]

    mov eax, [Point1Id]
    mov [ebx + PerpendicularBisector.Point1Id], eax

    mov eax, [Point2id]
    mov [ebx + PerpendicularBisector.Point2Id], eax

    mov eax, [Width]
    mov [ebx + PerpendicularBisector.Width], eax

    mov eax, [Color]
    mov [ebx + PerpendicularBisector.Color], eax

    ret
endp


proc PerpendicularBisector.Update
    locals
        Point1 POINT ?
        Point2 POINT ?
        CenterPoint POINT ?

        Two dd 2f
    endl

    mov eax, [ebx + PerpendicularBisector.Point1Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Point1.x], edx
    mov edx, [eax + Point.Y]
    mov [Point1.y], edx

    mov eax, [ebx + PerpendicularBisector.Point2Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Point2.x], edx
    mov edx, [eax + Point.Y]
    mov [Point2.y], edx

    fld [Point2.x]
    fadd [Point1.x]
    fdiv [Two]
    fst [CenterPoint.x]
    fst [ebx + PerpendicularBisector.Vector.Point1.x]
    fld [Point2.y]
    fadd [Point1.y]
    fdiv [Two]
    fst [CenterPoint.y]
    fst [ebx + PerpendicularBisector.Vector.Point1.y]

    fld [Point2.x]
    fsub [Point1.x]
    fld [Point2.y]
    fsub [Point1.y]
    ftst
    fstsw ax
    sahf
    jnz @F

    fld1
    fadd st0, st3
    fstp [ebx + PerpendicularBisector.Vector.Point2.y]
    mov eax, [CenterPoint.x]
    mov [ebx + PerpendicularBisector.Vector.Point2.x], eax
    fstp st0
    fstp st0
    jmp .Return

    @@:
    mov [ebx + PerpendicularBisector.Vector.Point2.x], 0f
    fdivp
    fmul st0, st2
    fadd st0, st1
    fstp [ebx + PerpendicularBisector.Vector.Point2.y]

    .Return:
    fstp st0
    fstp st0
    ret
endp


proc PerpendicularBisector.Draw, hDC
    locals
        BorderPoint1 POINT ?
        BorderPoint2 POINT ?

        SelectedWidth dd ?
    endl

    stdcall PerpendicularBisector.Update

    lea edx, [BorderPoint1]
    lea eax, [BorderPoint2]
    push eax edx

    stdcall Main.ToScreenPosition, [ebx + PerpendicularBisector.Vector.Point1.x], [ebx + PerpendicularBisector.Vector.Point1.y]
    push eax edx

    stdcall Main.ToScreenPosition, [ebx + PerpendicularBisector.Vector.Point2.x], [ebx + PerpendicularBisector.Vector.Point2.y]
    push eax edx

    stdcall Line.GetLineBorderPoints ; All the 2 arguments are pushed above

    cmp [ebx + PerpendicularBisector.IsSelected], 0
    je @F

    fild [ebx + PerpendicularBisector.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], \
                       [SelectedWidth], GeometryObject.SelectedLineColor

    @@:
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], \
                       [ebx + PerpendicularBisector.Width], [ebx + PerpendicularBisector.Color]


    ret
endp


proc PerpendicularBisector.IsOnPosition X, Y
    stdcall Math.DistanceLinePoint, [ebx + Perpendicular.Vector.Point1.x], [ebx + Perpendicular.Vector.Point1.y], \
                                    [ebx + Perpendicular.Vector.Point2.x], [ebx + Perpendicular.Vector.Point2.y], \
                                    [X], [Y]


    fild [ebx + PerpendicularBisector.Width]
    fdiv [Scale]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


proc PerpendicularBisector.Move uses esi ebx
    mov esi, ebx

    mov eax, [esi + PerpendicularBisector.Point1Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    mov eax, [esi + PerpendicularBisector.Point2Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    ret
endp


proc PerpendicularBisector.ToString, pBuffer
    invoke lstrcpyW, [pBuffer], PerpendicularBisector.StrFormat
    invoke lstrlenW, PerpendicularBisector.StrFormat

    ret
endp
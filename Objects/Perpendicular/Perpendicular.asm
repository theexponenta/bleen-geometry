
proc Perpendicular.Create, Id, pName, pCaption, Point1Id, LineObjectId, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_PERPENDICULAR, [pName], [pCaption]

    mov eax, [Point1Id]
    mov [ebx + Perpendicular.PointId], eax

    mov eax, [LineObjectId]
    mov [ebx + Perpendicular.LineObjectId], eax

    mov eax, [Width]
    mov [ebx + Perpendicular.Width], eax

    mov eax, [Color]
    mov [ebx + Perpendicular.Color], eax

    ret
endp


proc Perpendicular.Draw, hDC
    locals
        PerpendicularPoint POINT ?
        LineObject.Point1 POINT ?
        LineObject.Point2 POINT ?

        pLineObject dd ?

        BorderPoint1 POINT ?
        BorderPoint2 POINT ?

        SelectedWidth dd ?
    endl

    mov eax, [ebx + Perpendicular.PointId]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [PerpendicularPoint.x], edx
    mov [ebx + Perpendicular.Vector.Point1.x], edx
    mov edx, [eax + Point.Y]
    mov [ebx + Perpendicular.Vector.Point1.y], edx
    mov [PerpendicularPoint.y], edx

    stdcall Main.GetObjectById, [ebx + Perpendicular.LineObjectId]
    mov [pLineObject], eax

    mov edx, [eax + Line.Point1.x]
    mov ecx, [eax + Line.Point1.y]
    mov [LineObject.Point1.x], edx
    mov [LineObject.Point1.y], ecx

    mov edx, [eax + Line.Point2.x]
    mov ecx, [eax + Line.Point2.y]
    mov [LineObject.Point2.x], edx
    mov [LineObject.Point2.y], ecx

    fld [LineObject.Point2.x]
    fsub [LineObject.Point1.x]
    fld [LineObject.Point2.y]
    fsub [LineObject.Point1.y]
    ftst
    fstsw ax
    sahf
    jnz @F

    fld1
    fadd [PerpendicularPoint.y]
    fstp [ebx + Perpendicular.Vector.Point2.y]
    mov eax, [PerpendicularPoint.x]
    mov [ebx + Perpendicular.Vector.Point2.x], eax
    fstp st0
    fstp st0
    jmp .DrawLine

    @@:
    mov [ebx + Perpendicular.Vector.Point2.x], 0f
    fdivp
    fmul [PerpendicularPoint.x]
    fadd [PerpendicularPoint.y]
    fstp [ebx + Perpendicular.Vector.Point2.y]

    .DrawLine:
    stdcall Main.ToScreenPosition, [PerpendicularPoint.x], [PerpendicularPoint.y]
    mov [PerpendicularPoint.x], edx
    mov [PerpendicularPoint.y], eax

    stdcall Main.ToScreenPosition, [ebx + Perpendicular.Vector.Point2.x], [ebx + Perpendicular.Vector.Point2.y]

    lea ecx, [BorderPoint2]
    push ecx
    lea ecx, [BorderPoint1]
    push ecx
    stdcall Line.GetLineBorderPoints, [PerpendicularPoint.x], [PerpendicularPoint.y], edx, eax ; Other 2 arguments are pushed above

    cmp [ebx + Perpendicular.IsSelected], 0
    je @F

    fild [ebx + Perpendicular.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], [SelectedWidth], GeometryObject.SelectedLineColor

    @@:
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], \
                       [ebx + Perpendicular.Width], [ebx + Perpendicular.Color]


    ret
endp


proc Perpendicular.IsOnPosition X, Y
    stdcall Math.DistanceLinePoint, [ebx + Perpendicular.Vector.Point1.x], [ebx + Perpendicular.Vector.Point1.y], \
                                    [ebx + Perpendicular.Vector.Point2.x], [ebx + Perpendicular.Vector.Point2.y], \
                                    [X], [Y]


    fild [ebx + Perpendicular.Width]
    fdiv [Scale]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


proc Perpendicular.Move uses esi ebx
    mov esi, ebx

    mov eax, [esi + Perpendicular.PointId]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    ret
endp


proc Perpendicular.ToString, pBuffer
    mov eax, [ebx + Perpendicular.PointId]
    stdcall Main.FindPointById
    push [eax + GeometryObject.pName]

    cinvoke sprintf, [pBuffer], Perpendicular.StrFormat ; Format arguments are pushed above
    add esp, 4

    ret
endp
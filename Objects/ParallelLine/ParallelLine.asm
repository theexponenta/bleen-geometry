
proc ParallelLine.Create, Id, pName, pCaption, PointId, LineObjectId, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_PARALLEL_LINE, [pName], [pCaption]

    mov eax, [PointId]
    mov [ebx + ParallelLine.PointId], eax

    mov eax, [LineObjectId]
    mov [ebx + ParallelLine.LineObjectId], eax

    mov eax, [Width]
    mov [ebx + ParallelLine.Width], eax

    mov eax, [Color]
    mov [ebx + ParallelLine.Color], eax

    ret
endp


proc ParallelLine.Update
    locals
        ParralelLinePoint POINT ?
        LineObject.Point1 POINT ?
        LineObject.Point2 POINT ?

        pLineObject dd ?
    endl

    mov eax, [ebx + ParallelLine.PointId]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [ebx + ParallelLine.Vector.Point1.x], edx
    mov edx, [eax + Point.Y]
    mov [ebx + ParallelLine.Vector.Point1.y], edx

    stdcall Main.GetObjectById, [ebx + ParallelLine.LineObjectId]
    mov [pLineObject], eax

    mov edx, [eax + Line.Point1.x]
    mov ecx, [eax + Line.Point1.y]
    mov [LineObject.Point1.x], edx
    mov [LineObject.Point1.y], ecx

    mov edx, [eax + Line.Point2.x]
    mov ecx, [eax + Line.Point2.y]
    mov [LineObject.Point2.x], edx
    mov [LineObject.Point2.y], ecx

    mov [ebx + ParallelLine.Vector.Point2.x], 0f

    fld [LineObject.Point2.y]
    fsub [LineObject.Point1.y]
    fld [LineObject.Point2.x]
    fsub [LineObject.Point1.x]
    fdivp
    fmul [ebx + ParallelLine.Vector.Point1.x]
    fchs
    fadd [ebx + ParallelLine.Vector.Point1.y]
    fstp [ebx + ParallelLine.Vector.Point2.y]

    ret
endp


proc ParallelLine.Draw, hDC
    locals
        BorderPoint1 POINT ?
        BorderPoint2 POINT ?

        SelectedWidth dd ?
    endl

    stdcall ParallelLine.Update

    lea eax, [BorderPoint1]
    lea edx, [BorderPoint2]
    push edx eax

    stdcall Main.ToScreenPosition, [ebx + ParallelLine.Vector.Point1.x], [ebx + ParallelLine.Vector.Point1.y]
    push eax edx

    stdcall Main.ToScreenPosition, [ebx + ParallelLine.Vector.Point2.x], [ebx + ParallelLine.Vector.Point2.y]
    push eax edx

    stdcall Line.GetLineBorderPoints ; All the 2 arguments are pushed above

    cmp [ebx + ParallelLine.IsSelected], 0
    je @F

    fild [ebx + ParallelLine.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], [SelectedWidth], GeometryObject.SelectedLineColor

    @@:
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], \
                       [ebx + ParallelLine.Width], [ebx + ParallelLine.Color]


    ret
endp


proc ParallelLine.IsOnPosition X, Y
    stdcall Math.DistanceLinePoint, [ebx + ParallelLine.Vector.Point1.x], [ebx + ParallelLine.Vector.Point1.y], \
                                    [ebx + ParallelLine.Vector.Point2.x], [ebx + ParallelLine.Vector.Point2.y], \
                                    [X], [Y]


    fild [ebx + ParallelLine.Width]
    fdiv [Scale]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


proc ParallelLine.Move uses esi ebx
    mov esi, ebx

    mov eax, [esi + ParallelLine.PointId]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    ret
endp


proc ParallelLine.ToString, pBuffer
    mov eax, [ebx + ParallelLine.PointId]
    stdcall Main.FindPointById
    push [eax + GeometryObject.pName]

    cinvoke swprintf, [pBuffer], ParallelLine.StrFormat ; Format arguments are pushed above
    add esp, 4

    ret
endp
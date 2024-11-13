
proc Parabola.Create, Id, pName, pCaption, FocusPointId, LineObjectId, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_PARABOLA, [pName], [pCaption]
    
    mov eax, [FocusPointId]
    mov [ebx + Parabola.FocusPointId], eax

    mov eax, [LineObjectId]
    mov [ebx + Parabola.LineObjectId], eax

    mov eax, [Width]
    mov [ebx + Parabola.Width], eax

    mov eax, [Color]
    mov [ebx + Parabola.Color], eax

    ret
endp


proc Parabola.Draw uses ebx, hDC
    locals
        FocusPoint POINT ?
        FocusPointRotated POINT ?
        pLineObject dd ?
        pFocusPoint dd ?
        DirectrixPoint1 POINT ?
        DirectrixPoint1Rotated POINT ?
        DirectrixPoint2 POINT ?
        DirectrixPoint2Rotated POINT ?
        Angle dd ?
        P dd ?
        PrevWorldTransform XFORM ?
        NewWorldTransform XFORM ?
        hPenMain dd ?
        hPenSelected dd ?
        SelectedWidth dd ?

        CurrentX dd ?
        CurrentY dd ?

        Two dq 2f
    endl

    mov eax, [ebx + Parabola.FocusPointId]
    stdcall Main.FindPointById
    mov [pFocusPoint], eax
    mov edx, [eax + Point.X]
    mov [FocusPoint.x], edx
    mov edx, [eax + Point.Y]
    mov [FocusPoint.y], edx

    stdcall Main.GetObjectById, [ebx + Parabola.LineObjectId]
    mov [pLineObject], eax

    mov eax, [eax + Line.Point1Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [DirectrixPoint1.x], edx
    mov edx, [eax + Point.Y]
    mov [DirectrixPoint1.y], edx

    mov eax, [pLineObject]
    mov eax, [eax + Line.Point2Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [DirectrixPoint2.x], edx
    mov edx, [eax + Point.Y]
    mov [DirectrixPoint2.y], edx

    fld [DirectrixPoint2.y]
    fsub [DirectrixPoint1.y]
    fld [DirectrixPoint2.x]
    fsub [DirectrixPoint1.x]
    fpatan
    fst [Angle]
    fchs
    fsincos

    fst [NewWorldTransform.eM11]
    fstp [NewWorldTransform.eM22]
    fst [NewWorldTransform.eM12]
    fchs
    fstp [NewWorldTransform.eM21]

    invoke CreatePen, PS_SOLID, [ebx + EllipseObj.Width], [ebx + EllipseObj.Color]
    mov [hPenMain], eax
    invoke SelectObject, [hDC], eax

    stdcall Main.ToScreenPosition, [FocusPoint.x], [FocusPoint.y]
    mov [FocusPoint.x], edx
    mov [FocusPoint.y], eax

    stdcall Main.ToScreenPosition, [DirectrixPoint1.x], [DirectrixPoint1.y]
    mov [DirectrixPoint1.x], edx
    mov [DirectrixPoint1.y], eax

    ;stdcall Main.ToScreenPosition, [DirectrixPoint2.x], [DirectrixPoint2.y]
    ;mov [DirectrixPoint2.x], edx
    ;mov [DirectrixPoint2.y], eax

    stdcall Math.RotatePoint, [FocusPoint.x], [FocusPoint.y], [Angle], 0f, 0f
    ; OR
    ;stdcall Math.RotatePoint, [FocusPoint.x], [FocusPoint.y], [Angle], [DirectrixPoint1.x], [DirectrixPoint1.y]
    mov [FocusPointRotated.x], eax
    mov [FocusPointRotated.y], edx
    fldz
    fst [NewWorldTransform.eDy]
    fstp [NewWorldTransform.eDx]
    ;fld [FocusPoint.x]
    ;fsub [FocusPointRotated.x]
    ;fstp [NewWorldTransform.eDx]
    ;fld [FocusPoint.y]
    ;fsub [FocusPointRotated.y]
    ;fstp [NewWorldTransform.eDy]

    ;stdcall Draw.Circle, [hDC], [FocusPointRotated.x], [FocusPointRotated.y], 6

    stdcall Math.RotatePoint, [DirectrixPoint1.x], [DirectrixPoint1.y], [Angle], 0f, 0f
    mov [DirectrixPoint1Rotated.x], eax
    mov [DirectrixPoint1Rotated.y], edx
    ;fld [DirectrixPoint1.x]
    ;fsub [DirectrixPoint1Rotated.x]
    ;fstp [NewWorldTransform.eDx]
    ;fld [DirectrixPoint1.y]
    ;fsub [DirectrixPoint1Rotated.y]
    ;fstp [NewWorldTransform.eDy]

    ;stdcall Draw.Circle, [hDC], [DirectrixPoint1Rotated.x], [DirectrixPoint1Rotated.y], 6

    ;stdcall Math.RotatePoint, [DirectrixPoint2.x], [DirectrixPoint2.y], [Angle], 0f, 0f
    ;mov [DirectrixPoint2Rotated.x], eax
    ;mov [DirectrixPoint2Rotated.y], edx

    ;stdcall Draw.Circle, [hDC], [DirectrixPoint2Rotated.x], [DirectrixPoint2Rotated.y], 6

    fld [FocusPointRotated.y]
    fsub [DirectrixPoint1Rotated.y]
    ;fsub [DirectrixPoint1.y]

    ; p / 2 + y0
    fld st0
    fdiv [Two]
    ;fchs
    fadd [DirectrixPoint1Rotated.y]

    ; 1 / 2p
    fxch
    fmul [Two]
    fld1
    fdivrp
    ;fchs

    ; x3
    fld [FocusPointRotated.x]

    lea eax, [PrevWorldTransform]
    invoke GetWorldTransform, [hDC], eax

    mov ecx, [DrawArea.Width]
    xor edx, edx
    xor eax, eax
    .GeneratePointsLoop:
        mov [CurrentX], eax
        fild [CurrentX]
        fsub st0, st1
        fmul st0, st0
        fmul st0, st2
        fadd st0, st3
        fistp [CurrentY]

        push [CurrentY] eax

        add eax, 3
        add edx, 1
        cmp eax, ecx
        jle .GeneratePointsLoop

    ;mov eax, esp
    push edx
    ;invoke Polyline, [hDC], eax, edx
    lea eax, [NewWorldTransform]
    invoke SetWorldTransform, [hDC], eax

    pop edx
    cmp [ebx + Parabola.IsSelected], 0
    jz @F

    push edx
    fild [ebx + Parabola.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    invoke CreatePen, PS_SOLID, [SelectedWidth], GeometryObject.SelectedLineColor
    mov [hPenSelected], eax
    invoke SelectObject, [hDC], eax

    pop edx
    mov eax, esp
    push edx
    invoke Polyline, [hDC], eax, edx
    invoke DeleteObject, [hPenSelected]
    pop edx

    @@:
    push edx
    invoke SelectObject, [hDC], [hPenMain]
    pop edx

    mov eax, esp
    push edx
    invoke Polyline, [hDC], eax, edx
    pop edx

    shl edx, 3
    add esp, edx

    ;mov ebx, [pLineObject]
    ;stdcall Segment.Draw, [hDC]
    ;mov ebx, [pFocusPoint]
    ;stdcall Point.Draw, [hDC]

    lea eax, [PrevWorldTransform]
    invoke SetWorldTransform, [hDC], eax

    invoke DeleteObject, [hPenMain]

    fstp st0
    fstp st0
    fstp st0

    .Return:
    ret
endp


proc Parabola.Move uses esi ebx
    mov esi, ebx

    mov eax, [esi + Parabola.FocusPointId]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    push edx ecx
    stdcall Main.GetObjectById, [esi + Parabola.LineObjectId]
    mov ebx, eax
    pop ecx edx
    call GeometryObject.Move

    ret
endp


proc Parabola.IsOnPosition X, Y
    locals
        FocusPoint POINT ?
        pLineObject dd ?
        DirectrixPoint1 POINT ?
        DirectrixPoint2 POINT ?
    endl

    mov eax, [ebx + Parabola.FocusPointId]
    stdcall Main.FindPointById
    stdcall Math.Distance, [X], [Y], [eax + Point.X], [eax + Point.Y]

    push [Y]
    push [X]

    stdcall Main.GetObjectById, [ebx + Parabola.LineObjectId]
    mov [pLineObject], eax

    mov eax, [eax + Line.Point1Id]
    stdcall Main.FindPointById
    push [eax + Point.Y]
    push [eax + Point.X]

    mov eax, [pLineObject]
    mov eax, [eax + Line.Point2Id]
    stdcall Main.FindPointById
    push [eax + Point.Y]
    push [eax + Point.X]

    stdcall Math.DistanceLinePoint ; All the arguments are pushed above

    fsubp
    fabs

    xor eax, eax

    fild [ebx + Parabola.Width]
    fdiv [Scale]
    fcomip st0, st1
    jb .Return

    mov eax, 1

    .Return:
    fstp st0
    ret
endp

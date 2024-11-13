
proc EllipseObj.Create Id, pName, pCaption, FocusPoint1Id, FocusPoint2Id, CircumferencePointId, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_ELLIPSE, [pName], [pCaption]
    
    mov eax, [FocusPoint1Id]
    mov [ebx + EllipseObj.FocusPoint1Id], eax

    mov eax, [FocusPoint2Id]
    mov [ebx + EllipseObj.FocusPoint2Id], eax

    mov eax, [CircumferencePointId]
    mov [ebx + EllipseObj.CircumferencePointId], eax

    mov eax, [Width]
    mov [ebx + EllipseObj.Width], eax

    mov eax, [Color]
    mov [ebx + EllipseObj.Color], eax

    ret
endp


proc EllipseObj.Draw hdc
    locals
        PrevWorldTranform XFORM ?
        NewWorldTransform XFORM ?

        Focus1 POINT ?
        Focus1Rotated POINT ?
        Focus2 POINT ?
        CircumferencePoint POINT ?
        SemiMajorLength dd ?
        SemiMinorLength dd ?
        FocalDistance dd ?
        Center POINT ?
        Angle dd ?

        hPenMain dd ?
        hPenSelected dd 0
        SelectedWidth dd ?

        Two dd 2f
    endl

    mov eax, [ebx + EllipseObj.FocusPoint1Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Focus1.x], edx
    mov edx, [eax + Point.Y]
    mov [Focus1.y], edx

    mov eax, [ebx + EllipseObj.FocusPoint2Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Focus2.x], edx
    mov edx, [eax + Point.Y]
    mov [Focus2.y], edx

    mov eax, [ebx + EllipseObj.CircumferencePointId]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [CircumferencePoint.x], edx
    mov edx, [eax + Point.Y]
    mov [CircumferencePoint.y], edx

    stdcall Math.Distance, [Focus1.x], [Focus1.y], [Focus2.x], [Focus2.y]
    fdiv [Two]
    fld st0
    fmul [Scale]
    fstp [FocalDistance]
    fmul st0, st0

    stdcall Math.Distance, [CircumferencePoint.x], [CircumferencePoint.y], [Focus1.x], [Focus1.y]
    stdcall Math.Distance, [CircumferencePoint.x], [CircumferencePoint.y], [Focus2.x], [Focus2.y]
    faddp
    fdiv [Two]
    fld st0
    fmul [Scale]
    fistp [SemiMajorLength]

    fmul st0, st0
    fsubrp
    fsqrt
    fmul [Scale]
    fistp [SemiMinorLength]

    fld [Focus1.y]
    fsub [Focus2.y]
    fld [Focus2.x]
    fsub [Focus1.x]
    fpatan
    fst [Angle]
    fsincos

    fst [NewWorldTransform.eM11]
    fstp [NewWorldTransform.eM22]
    fst [NewWorldTransform.eM12]
    fchs
    fstp [NewWorldTransform.eM21]

    stdcall Main.ToScreenPosition, [Focus1.x], [Focus1.y]
    mov [Center.x], edx
    mov [Center.y], eax
    fld [Center.x]
    fst [Focus1.x]
    fadd [FocalDistance]
    fistp [Center.x]
    fld [Center.y]
    fist [Center.y]
    fstp [Focus1.y]

    stdcall Math.RotatePoint, [Focus1.x], [Focus1.y], [Angle], 0f, 0f
    mov [Focus1Rotated.x], eax
    mov [Focus1Rotated.y], edx
    fld [Focus1.x]
    fsub [Focus1Rotated.x]
    fstp [NewWorldTransform.eDx]
    fld [Focus1.y]
    fsub [Focus1Rotated.y]
    fstp [NewWorldTransform.eDy]

    lea eax, [PrevWorldTranform]
    invoke GetWorldTransform, [hdc], eax

    lea eax, [NewWorldTransform]
    invoke SetWorldTransform, [hdc], eax

    invoke GetStockObject, NULL_BRUSH
    invoke SelectObject, [hdc], eax

    cmp [ebx + EllipseObj.IsSelected], 0
    jz @F

    fild [ebx + EllipseObj.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    invoke CreatePen, PS_SOLID, [SelectedWidth], GeometryObject.SelectedLineColor
    mov [hPenSelected], eax
    invoke SelectObject, [hdc], eax

    stdcall Draw.Ellipse, [hdc], [Center.x], [Center.y], [SemiMinorLength], [SemiMajorLength]

    @@:
    invoke CreatePen, PS_SOLID, [ebx + EllipseObj.Width], [ebx + EllipseObj.Color]
    mov [hPenMain], eax
    invoke SelectObject, [hdc], eax

    stdcall Draw.Ellipse, [hdc], [Center.x], [Center.y], [SemiMinorLength], [SemiMajorLength]

    lea eax, [PrevWorldTranform]
    invoke SetWorldTransform, [hdc], eax

    invoke GetStockObject, DC_PEN
    invoke SelectObject, [hdc], eax

    invoke DeleteObject, [hPenMain]
    cmp [hPenSelected], 0
    je .Return

    invoke DeleteObject, [hPenSelected]

    .Return:
    ret
endp


proc EllipseObj.Move uses esi ebx
    mov esi, ebx

    mov eax, [esi + EllipseObj.FocusPoint1Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    mov eax, [esi + EllipseObj.FocusPoint2Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    mov eax, [esi + EllipseObj.CircumferencePointId]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    ret
endp


proc EllipseObj.IsOnPosition X, Y
    locals
        Focus1 POINT ?
        Focus2 POINT ?
        CircumferencePoint POINT ?

        Two dd 2f
    endl

    mov eax, [ebx + EllipseObj.FocusPoint1Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Focus1.x], edx
    mov edx, [eax + Point.Y]
    mov [Focus1.y], edx

    mov eax, [ebx + EllipseObj.FocusPoint2Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Focus2.x], edx
    mov edx, [eax + Point.Y]
    mov [Focus2.y], edx

    mov eax, [ebx + EllipseObj.CircumferencePointId]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [CircumferencePoint.x], edx
    mov edx, [eax + Point.Y]
    mov [CircumferencePoint.y], edx

    stdcall Math.Distance, [CircumferencePoint.x], [CircumferencePoint.y], [Focus1.x], [Focus1.y]
    stdcall Math.Distance, [CircumferencePoint.x], [CircumferencePoint.y], [Focus2.x], [Focus2.y]
    faddp

    stdcall Math.Distance, [X], [Y], [Focus1.x], [Focus1.y]
    stdcall Math.Distance, [X], [Y], [Focus2.x], [Focus2.y]
    faddp

    fsubp
    fabs

    xor eax, eax

    fild [ebx + EllipseObj.Width]
    fdiv [Scale]
    fcomip st0, st1
    jb .Return

    mov eax, 1

    .Return:
    fstp st0
    ret
endp

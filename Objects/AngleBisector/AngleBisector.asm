
proc AngleBisector.Create Id, pName, pCaption, Point1Id, Point2Id, Point3Id, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_ANGLE_BISECTOR, [pName], [pCaption]

    mov eax, [Point1Id]
    mov [ebx + AngleBisector.Point1Id], eax

    mov eax, [Point2Id]
    mov [ebx + AngleBisector.Point2Id], eax

    mov eax, [Point3Id]
    mov [ebx + AngleBisector.Point3Id], eax

    mov eax, [Width]
    mov [ebx + AngleBisector.Width], eax

    mov eax, [Color]
    mov [ebx + AngleBisector.Color], eax

    ret
endp


proc AngleBisector.Draw, hDC
    locals
        Point1 POINT ?
        Point2 POINT ?
        Point3 POINT ?

        BorderPoint1 POINT ?
        BorderPoint2 POINT ?

       SelectedWidth dd ?
    endl

    mov eax, [ebx + AngleBisector.Point1Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Point1.x], edx
    mov edx, [eax + Point.Y]
    mov [Point1.y], edx

    mov eax, [ebx + AngleBisector.Point2Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Point2.x], edx
    mov edx, [eax + Point.Y]
    mov [Point2.y], edx

    mov eax, [ebx + AngleBisector.Point3Id]
    stdcall Main.FindPointById
    mov edx, [eax + Point.X]
    mov [Point3.x], edx
    mov edx, [eax + Point.Y]
    mov [Point3.y], edx

    fld [Point1.x]
    fsub [Point2.x]
    fld [Point1.y]
    fsub [Point2.y]
    fld st1
    fmul st0, st0
    fld st1
    fmul st0, st0
    faddp
    fsqrt
    fdiv st2, st0
    fdivp

    fld [Point3.x]
    fsub [Point2.x]
    fld [Point3.y]
    fsub [Point2.y]
    fld st1
    fmul st0, st0
    fld st1
    fmul st0, st0
    faddp
    fsqrt
    fdiv st2, st0
    fdivp

    fadd st2, st0
    fxch
    fadd st3, st0
    fstp st0
    fstp st0

    fld [Point2.x]
    fld [Point2.y]
    fadd st2, st0
    fxch
    fadd st3, st0
    fstp st0
    fstp st0

    mov eax, [Point2.x]
    mov [ebx + AngleBisector.Vector.Point1.x], eax
    mov edx, [Point2.y]
    mov [ebx + AngleBisector.Vector.Point1.y], edx

    fstp [ebx + AngleBisector.Vector.Point2.y]
    fstp [ebx + AngleBisector.Vector.Point2.x]

    stdcall Main.ToScreenPosition, [Point2.x], [Point2.y]
    mov [Point2.x], edx
    mov [Point2.y], eax

    stdcall Main.ToScreenPosition, [ebx + AngleBisector.Vector.Point2.x], [ebx + AngleBisector.Vector.Point2.y]

    lea ecx, [BorderPoint2]
    push ecx
    lea ecx, [BorderPoint1]
    push ecx
    stdcall Line.GetLineBorderPoints, [Point2.x], [Point2.y], edx, eax ; Other 2 arguments are pushed above

    cmp [ebx + AngleBisector.IsSelected], 0
    je @F

    fild [ebx + AngleBisector.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], [SelectedWidth], GeometryObject.SelectedLineColor

    @@:
    stdcall Draw.Line, [hDC], [BorderPoint1.x], [BorderPoint1.y], [BorderPoint2.x], [BorderPoint2.y], [ebx + AngleBisector.Width], [ebx + AngleBisector.Color]

    ret
endp


proc AngleBisector.IsOnPosition X, Y
    stdcall Math.DistanceLinePoint, [ebx + AngleBisector.Vector.Point1.x], [ebx + AngleBisector.Vector.Point1.y], \
                                    [ebx + AngleBisector.Vector.Point2.x], [ebx + AngleBisector.Vector.Point2.y], \
                                    [X], [Y]


    fild [ebx + AngleBisector.Width]
    fdiv [Scale]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


proc AngleBisector.Move
    ret
endp
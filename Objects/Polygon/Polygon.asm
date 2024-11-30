
proc PolygonObj.Create uses ebx, Id, pName, pCaption, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_POLYGON, [pName], [pCaption]

    mov eax, [Width]
    mov [ebx + PolygonObj.Width], eax

    mov eax, [Color]
    mov [ebx + PolygonObj.Color], eax

    add ebx, PolygonObj.SegmentsIds
    stdcall Vector.Create, 4, 0, PolygonObj.SegmentsIds.InitialCapacity

    ret
endp


proc PolygonObj.Draw uses esi, hdc
    locals
        SelectedWidth dd ?
        hPenSelected dd ?
        pCurrentSegment dd ?
        CurPoint POINT ?
    endl

    cmp [ebx + PolygonObj.IsSelected], 0
    je .Return

    mov esi, [ebx + PolygonObj.SegmentsIds.Ptr]
    mov ecx, [ebx + PolygonObj.SegmentsIds.Length]

    .PushPoints:
        push ecx
        stdcall Main.GetObjectById, [esi]
        mov [pCurrentSegment], eax

        mov eax, [eax + Segment.Point1Id]
        call Main.FindPointById
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

    mov ecx, [ebx + PolygonObj.SegmentsIds.Length]
    sub ecx, 1
    shl ecx, 3
    mov eax, [esp + ecx]
    mov edx, [esp + ecx + 4]
    push edx eax

    fild [ebx + PolygonObj.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    invoke CreatePen, PS_SOLID, [SelectedWidth], GeometryObject.SelectedLineColor
    mov [hPenSelected], eax
    invoke SelectObject, [hdc], eax

    mov eax, esp
    mov ecx, [ebx + PolygonObj.SegmentsIds.Length]
    add ecx, 1
    invoke Polyline, [hdc], eax, ecx

    invoke DeleteObject, [hPenSelected]

    .Return:
    ret
endp


proc PolygonObj.Move uses esi edi ebx
    mov edi, [ebx + PolygonObj.SegmentsIds.Length]
    mov esi, [ebx + PolygonObj.SegmentsIds.Ptr]

    .MoveSegmentsLoop:
        mov eax, [esi]

        push edx ecx
        stdcall Main.GetObjectById, eax
        mov eax, [eax + Segment.Point1Id]
        call Main.FindPointById
        pop ecx edx

        push edx ecx
        mov ebx, eax
        call Point.Move
        pop ecx edx

        add esi, 4
        sub edi, 1
        jnz .MoveSegmentsLoop

    ret
endp


proc PolygonObj.IsOnPosition uses esi edi, X, Y
    locals
        SegmentPoint1 POINT ?
        SegmentPoint2 POINT ?
        pCurrentSegment dd ?
    endl

    mov ecx, [ebx + PolygonObj.SegmentsIds.Length]
    mov esi, [ebx + PolygonObj.SegmentsIds.Ptr]
    xor edi, edi

    .CheckLoop:
        push ecx

        stdcall Main.GetObjectById, [esi]
        mov [pCurrentSegment], eax

        mov eax, [eax + Segment.Point1Id]
        call Main.FindPointById

        mov edx, [eax + Point.X]
        mov [SegmentPoint1.x], edx
        mov edx, [eax + Point.Y]
        mov [SegmentPoint1.y], edx

        mov eax, [pCurrentSegment]
        mov eax, [eax + Segment.Point2Id]
        call Main.FindPointById

        mov edx, [eax + Point.X]
        mov [SegmentPoint2.x], edx
        mov edx, [eax + Point.Y]
        mov [SegmentPoint2.y], edx

        fld [SegmentPoint1.y]
        fld [SegmentPoint2.y]
        fld st0
        fld st2
        stdcall Math.FPUMin
        fxch st2
        stdcall Math.FPUMax

        mov eax, 1
        fld [Y]

        fcomi st0, st1
        jbe @F

        xor eax, eax
        jmp .EndYCheck

        @@:
        fcomi st0, st2
        jae .EndYCheck

        xor eax, eax

        .EndYCheck:
            fstp st0
            fstp st0
            fstp st0
            test eax, eax
            jz @F

        fld [SegmentPoint2.x]
        fsub [SegmentPoint1.x]
        fld [SegmentPoint2.y]
        fsub [SegmentPoint1.y]
        fdivp
        fld [Y]
        fsub [SegmentPoint1.y]
        fmulp
        fadd [SegmentPoint1.x]

        fld [X]
        fcomip st0, st1
        fstp st0
        ja @F

        add edi, 1

        @@:
        add esi, 4
        pop ecx
        sub ecx, 1
        jnz .CheckLoop

    mov eax, edi
    and eax, 1

    .Finish:
    ret
endp


proc PolygonObj.DependsOnObject uses esi, Id
    mov eax, [Id]
    mov esi, [ebx + PolygonObj.SegmentsIds.Ptr]
    mov ecx, [ebx + PolygonObj.SegmentsIds.Length]
    test ecx, ecx
    jz .Finish

    .CheckPointsLoop:
        cmp eax, [esi]
        je .Finish
        add esi, 4
        loop .CheckPointsLoop

    .Finish:
    mov eax, ecx ; If found, ecx is nonzero
    ret
endp


proc PolygonObj.Destroy uses ebx esi
    mov esi, [ebx + PolygonObj.SegmentsIds.Ptr]
    test esi, esi
    jz .Return

    mov ecx, [ebx + PolygonObj.SegmentsIds.Length]
    test ecx, ecx
    jz .Return

    ; Id = 0 is a mark for procedure Main.DeleteObjectById to delete dependent objects
    .MarkSegmentsToDelete:
        push ecx
        stdcall Main.GetObjectById, [esi]
        pop ecx

        test eax, eax
        jz .NextIteration

        mov [eax + Segment.Id], 0

        .NextIteration:
        add esi, 4
        loop .MarkSegmentsToDelete

    add ebx, PolygonObj.SegmentsIds
    call Vector.Destroy

    .Return:
    ret
endp


proc PolygonObj.ToString, pBuffer
    invoke lstrcpyA, [pBuffer], PolygonObj.StrFormat
    invoke lstrlenA, PolygonObj.StrFormat

    ret
endp
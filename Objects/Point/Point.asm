
proc Point.Create uses ebx, Id, pName, pCaption, X, Y, Color, Size, pParentObject
    stdcall GeometryObject.Create, [Id], OBJ_POINT, [pName], [pCaption]

    mov eax, [X]
    mov [ebx + Point.X], eax
    
    mov eax, [Y]
    mov [ebx + Point.Y], eax
    
    mov eax, [Color]
    mov [ebx + Point.Color], eax
    
    mov eax, [Size]
    mov [ebx + Point.Size], eax

    mov eax, [Size]
    mov [ebx + Point.Size], eax

    mov [ebx + Point.IntersectionId], 0
    mov [ebx + Point.ParentObjectId], 0
    mov [ebx + Point.IsHiddenByIntersection], 0
    mov byte [ebx + Point.ConstructType], 0
    mov [ebx + Point.ConstructObject1Id], 0

    mov eax, [pParentObject]
    test eax, eax
    jz .Return

    mov edx, [eax + GeometryObject.Id]
    mov [ebx + Point.ParentObjectId], edx
    mov ebx, eax
    stdcall GeometryObject.AttachPoint, [Id]

    .Return:
    ret
endp


proc Point.Draw uses edi, hdc
    locals
        CenterX dd ?
        CenterY dd ?
    endl

    ; Uninitialized points have Id = 0
    ; They are used when user needs to select a point to end
    ; adding a new object
    ; Unitialized points are not painted
    cmp [ebx + Point.Id], 0
    je .Return

    mov edi, [hdc]

    invoke GetStockObject, DC_BRUSH
    invoke SelectObject, edi, eax
    invoke SelectObject, edi, [Point.BorderPen]

    invoke SetDCBrushColor, edi, [ebx + Point.Color]

    ; Circle
    stdcall Main.ToScreenPosition, [ebx + Point.X], [ebx + Point.Y]
    mov [CenterX], edx
    mov [CenterY], eax
    mov eax, [ebx + Point.Size]
    stdcall Draw.Circle, edi, [CenterX], [CenterY], eax

    cmp [ebx + Point.IsSelected], 1
    jne @F

    ; Circle for selected point
    invoke GetStockObject, NULL_BRUSH
    invoke SelectObject, edi, eax

    invoke CreatePen, PS_SOLID, Point.SelectedBorderSize, [ebx + Point.Color]
    mov [Point.SelectedBorderPen], eax
    invoke SelectObject, edi, eax

    mov eax, [ebx + Point.Size]
    shl eax, 1
    stdcall Draw.Circle, edi, [CenterX], [CenterY], eax

    invoke GetStockObject, DC_PEN
    invoke DeleteObject, [Point.SelectedBorderPen]

    @@:
    ; Name
    fld [CenterX]
    fistp [CenterX]
    fld [CenterY]
    fistp [CenterY]
    invoke SetTextColor, edi, [ebx + Point.Color]
    mov eax, [CenterX]
    add eax, Point.NameTextOffset
    mov ecx, [CenterY]
    sub ecx, Point.NameTextOffset

    ; Get delphi-string length
    mov edx, [ebx + Point.pName]
    mov edx, [edx - 4]

    invoke TextOutW, edi, eax, ecx, [ebx + Point.pName], edx

    .Return:
    ret
endp


; eax - Point num
; Returns pointer to string in eax
proc Point.PointNumToName uses ebx
    local LetterIndex dd ?

    xor edx, edx
    mov ebx, 26
    div ebx

    ; Count name characters in ecx
    mov ecx, 1
    test eax, eax
    je .MakeString

    mov [LetterIndex], eax

    push eax edx ecx
    call Math.CountDigits
    pop ecx
    add ecx, eax
    inc ecx ; Count _ character
    pop edx eax

    .MakeString:
    mov ebx, ecx
    shl ebx, 1
    add ebx, 7 ; 4 for length before string, 2 for zero character
    push edx ecx
    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, ebx
    pop ecx edx
    add edx, 'A'

    mov [eax], ecx
    mov [eax + 4], dx
    cmp ecx, 1
    je .Return

    mov [eax + 6], word '_'

    ; eax + 8 - place to start write letter index
    mov ecx, eax
    add ecx, 8
    push eax
    mov eax, [LetterIndex]
    stdcall Strings.NumToString
    pop eax

    .Return:
    add eax, 4 ; Delphi-string pointer points to the beginning of the string, leaving 4 bytes of length behind
    ret
endp


; edx - dX
; ecx - dY
proc Point.Move uses edx ecx
    locals
        Delta dd ?
        NewX dd ?
        NewY dd ?
    endl

    cmp [ebx + Point.IntersectionId], 0
    jne .Return

    mov [Delta], edx
    fld [Delta]
    fadd [ebx + Point.X]
    fstp [NewX]
    mov edx, [NewX]
    mov [Delta], ecx
    fld [Delta]
    fadd [ebx + Point.Y]
    fstp [NewY]
    mov ecx, [NewY]

    cmp [ebx + Point.ParentObjectId], 0
    je .WriteNewCoordinates

    stdcall Point.AdjustAttachedPoint, edx, ecx
    test eax, eax
    jz .Return

    .WriteNewCoordinates:
    mov [ebx + Point.X], edx
    mov [ebx + Point.Y], ecx

    .Return:
    ret
endp


proc Point.IsOnPosition X, Y
    fld [X]
    fld [Y]

    fld [ebx + Point.X]
    fsub st0, st2
    fmul st0, st0
    fld [ebx + Point.Y]
    fsub st0, st2
    fmul st0, st0
    faddp
    fsqrt

    fild [ebx + Point.Size]
    fcomip st, st1
    fstp st0
    jae .ReturnTrue

    xor eax, eax
    jmp .Return

    .ReturnTrue:
    mov eax, 1

    .Return:
    ret
endp



proc Point.ToString, pBuffer
    cinvoke swprintf, [pBuffer], Point.StrFormat, [ebx + Point.pName]
    ret
endp


proc Point.Update uses ebx esi
    cmp [ebx + Point.ParentObjectId], 0
    je @F

    stdcall Point.AdjustAttachedPoint, [ebx + Point.X], [ebx + Point.Y]
    test eax, eax
    jz .Return

    mov [ebx + Point.X], edx
    mov [ebx + Point.Y], ecx

    @@:
    cmp byte [ebx + Point.ConstructType], 0
    je .Return

    stdcall Main.GetObjectById, [ebx + Point.ConstructObject1Id]
    test eax, eax
    jz .Return

    mov esi, ebx
    mov ebx, eax
    stdcall Segment.Update

    fld1
    fld1
    faddp

    fld [ebx + Segment.Point1.x]
    fadd [ebx + Segment.Point2.x]
    fdiv st0, st1
    fstp [esi + Point.X]

    fld [ebx + Segment.Point1.y]
    fadd [ebx + Segment.Point2.y]
    fdiv st0, st1
    fstp [esi + Point.Y]

    fstp st0

    .Return:
    ret
endp


proc Point.AdjustAttachedPoint, X, Y
    locals
       pParentObject dd ?
    endl

    stdcall Main.GetObjectById, [ebx + Point.ParentObjectId]
    test eax, eax
    jz .DetachPoint

    mov [pParentObject], eax

    movzx edx, byte [eax + GeometryObject.Type]
    stdcall GeometryObject.IsLineObjectType, edx
    test eax, eax
    jz @F

    stdcall Point._AdjustLineObjectPoint, [pParentObject], [X], [Y]
    jmp .Return

    @@:
    cmp edx, OBJ_POLYGON
    jne @F

    stdcall Point._AdjustPolygonPoint, [pParentObject], [X], [Y]
    jmp .Return

    @@:
    cmp edx, OBJ_CIRCLE_WITH_CENTER
    jne @F

    stdcall Point._AdjustCirclePoint, [pParentObject], [X], [Y]
    jmp .Return

    @@:
    .DetachPoint:
    mov [ebx + Point.ParentObjectId], 0

    .Return:
    ret
endp


proc Point._AdjustLineObjectPoint uses ebx, pObject, X, Y
    locals
        AdjustedPoint POINT ?
    endl

    mov eax, [pObject]

    stdcall Math.GetNearestPointOnLine, [X], [Y], [eax + Line.Point1.x], [eax + Line.Point1.y],  [eax + Line.Point2.x], [eax + Line.Point2.y]

    mov ebx, [pObject]
    cmp byte [ebx + GeometryObject.Type], OBJ_SEGMENT
    jne @F

    stdcall Segment.IsPointOnSegment
    test eax, eax
    jz .Return

    @@:
    fst [AdjustedPoint.y]
    fxch
    fst [AdjustedPoint.x]

    mov edx, [AdjustedPoint.x]
    mov ecx, [AdjustedPoint.y]
    mov eax, 1

    .Return:
    fstp st0
    fstp st0
    ret
endp


proc Point._AdjustPolygonPoint uses ebx, pObject, X, Y
    mov ebx, [pObject]
    stdcall PolygonObj.IsOnPosition, [X], [Y]
    test eax, eax
    jz .Return

    mov edx, [X]
    mov ecx, [Y]
    mov eax, 1

    .Return:
    ret
endp


proc Point._AdjustCirclePoint uses esi, pObject, X, Y
    locals
        CenterPoint POINT ?
        NewPoint POINT ?
    endl

    mov esi, [pObject]
    stdcall Main.GetObjectById, [esi + CircleWithCenter.CenterPointId]

    mov edx, [eax + Point.X]
    mov ecx, [eax + Point.Y]
    mov [CenterPoint.x], edx
    mov [CenterPoint.y], ecx

    stdcall Main.GetObjectById, [esi + CircleWithCenter.SecondPointId]

    mov edx, [CenterPoint.x]
    mov ecx, [CenterPoint.y]
    stdcall Math.Distance, edx, ecx, [eax + Point.X], [eax + Point.Y]
    stdcall Math.Distance, edx, ecx, [X], [Y]
    fdivp

    fld [X]
    fsub [CenterPoint.x]
    fmul st0, st1
    fadd [CenterPoint.x]
    fstp [NewPoint.x]

    fld [Y]
    fsub [CenterPoint.y]
    fmul st0, st1
    fadd [CenterPoint.y]
    fstp [NewPoint.y]

    fstp st0

    mov edx, [NewPoint.x]
    mov ecx, [NewPoint.y]

    .Return:
    ret
endp
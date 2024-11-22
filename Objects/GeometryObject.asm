
proc GeometryObject.Create uses ebx, Id, Type, pName, pCaption
    mov eax, [Id]
    mov [ebx + GeometryObject.Id], eax
    
    mov eax, [Type]
    mov [ebx + GeometryObject.Type], al

    mov eax, [pName]
    mov [ebx + GeometryObject.pName], eax

    mov eax, [pCaption]
    mov [ebx + GeometryObject.pCaption], eax

    mov [ebx + GeometryObject.IsSelected], 0
    mov [ebx + GeometryObject.IsHidden], 0

    add ebx, GeometryObject.AttachedPointsIds
    stdcall Vector.Create, 4, 0, GeometryObject.AttachedPointsIds.DefaultCapacity

    ret
endp


proc GeometryObject.AddAttachedPoint uses ebx, PointId
    add ebx, GeometryObject.AttachedPointsIds
    stdcall Vector.PushValue, [PointId]

    ret
endp


; eax - Index
; edx - Id
proc GeometryObject.SetAttachedPoint
    mov ecx, [ebx + GeometryObject.AttachedPointsIds.Ptr]
    mov [ecx + eax*4], edx

    ret
endp


; edx - dX
; ecx - dY
proc GeometryObject.Move uses ebx edi esi
    mov esi, [ebx + GeometryObject.AttachedPointsIds.Length]
    test esi, esi
    jz @F

    mov edi, [ebx + GeometryObject.AttachedPointsIds.Ptr]
    .MoveLoop:
        mov eax, [edi]
        push ecx edx
        call Main.FindPointById
        pop edx ecx
        mov ebx, eax
        call Point.Move
        add edi, 4

        dec esi
        jnz .MoveLoop

    @@:
    movzx eax, byte[ebx + GeometryObject.Type]
    dec eax
    shl eax, 2
    add eax, Objects.MoveProcedures
    call dword[eax]

    .Return:
    ret
endp


proc GeometryObject.IsDependableObjectType, Type
    mov edx, [Type]
    mov eax, 1

    cmp edx, OBJ_POINT
    je .Return

    cmp edx, OBJ_INTERSECTION
    je .Return

    stdcall GeometryObject.IsLineObjectType, edx

    .Return:
    ret
endp


proc GeometryObject.IsLineObjectType, Type
    mov edx, [Type]
    mov eax, 1

    cmp edx, OBJ_LINE
    je .Return

    cmp edx, OBJ_SEGMENT
    je .Return

    cmp edx, OBJ_ANGLE_BISECTOR
    je .Return

    cmp edx, OBJ_PERPENDICULAR
    je .Return

    cmp edx, OBJ_PERPENDICULAR_BISECTOR
    je .Return

    xor eax, eax

    .Return:
    ret
endp


proc GeometryObject.DependsOnObject, Id
    movzx eax, byte [ebx + GeometryObject.Type]

    cmp eax, OBJ_POLYLINE
    jne @F

    stdcall PolylineObj.DependsOnObject, [Id]
    jmp .Return

    @@:
    cmp eax, OBJ_POLYGON
    jne @F

    stdcall PolygonObj.DependsOnObject, [Id]
    jmp .Return

    @@:
    cmp eax, OBJ_INTERSECTION
    jne @F

    stdcall Intersection.DependsOnObject, [Id]
    jmp .Return

    @@:
    mov edx, Objects.DependencyObjectsIdsOffsets
    dec eax
    shl eax, 2

    mov edx, [edx + eax]
    mov ecx, [edx]
    test ecx, ecx
    jz .ReturnFalse

    add edx, 4
    .CheckDependencyLoop:
        mov eax, [edx]
        mov eax, [ebx + eax]
        cmp eax, [Id]
        je .ReturnTrue
        add edx, 4
        loop .CheckDependencyLoop

    .ReturnFalse:
    xor eax, eax
    jmp .Return

    .ReturnTrue:
    mov eax, 1

    .Return:
    ret
endp


proc GeometryObject.GetEditableProperties
    movzx eax, byte [ebx + GeometryObject.Type]
    dec eax
    shl eax, 2
    add eax, Objects.EditableProperties
    mov eax, [eax]
    ret
endp


; pNewName - Delphi-string
proc GeometryObject.SetName uses esi edi, pNewName
    mov eax, [ebx + GeometryObject.pName]
    sub eax, 4
    invoke HeapFree, [hProcessHeap], 0, eax

    mov esi, [pNewName]
    sub esi, 4
    mov edi, [esi]
    shl edi, 1 ; Unicode
    add edi, 4 ; 4 bytes for length of string

    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, edi
    mov edx, eax
    add edx, 4
    mov [ebx + GeometryObject.pName], edx
    invoke RtlMoveMemory, eax, esi, edi

    ret
endp


proc GeometryObject.Destroy
    movzx eax, [ebx + GeometryObject.Type]

    cmp eax, OBJ_POLYGON
    jne .Return

    call PolygonObj.Destroy

    .Return:
    ret
endp


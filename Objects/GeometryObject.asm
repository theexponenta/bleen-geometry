
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

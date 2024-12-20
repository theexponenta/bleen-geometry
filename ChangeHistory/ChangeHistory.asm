
proc ChangeHistory.Create uses ebx, Capacity
    stdcall ChangeHistory._SetInitialFieldValues

    add ebx, ChangeHistory.History
    stdcall Vector.Create, sizeof.ChangeHistoryRecord, 0, [Capacity]

    ret
endp


proc ChangeHistory._SetInitialFieldValues
    mov [ebx + ChangeHistory.CurrentGroupId], 0
    mov [ebx + ChangeHistory.TotalRecordsCount], 0
    mov [ebx + ChangeHistory.PoppedRecordsCount], 0

    ret
endp


proc ChangeHistory.StartNewGroup
    inc [ebx + ChangeHistory.CurrentGroupId]
    mov eax, [ebx + ChangeHistory.CurrentGroupId]
    ret
endp


proc ChangeHistory.AddChange uses ebx, Type, pObject
    locals
        NewRecord ChangeHistoryRecord ?
        SizeofObject dd ?
    endl

    mov eax, [Type]
    mov [NewRecord.Type], al
    mov eax, [ebx + ChangeHistory.CurrentGroupId]
    mov [NewRecord.GroupId], eax

    mov edx, [pObject]
    movzx eax, byte [edx + GeometryObject.Type]
    dec eax
    shl eax, 2
    add eax, Objects.StructSizes
    mov ecx, [eax]
    mov [SizeofObject], ecx

    push ebx

    lea ebx, [NewRecord.Object]
    stdcall ByteArray.Create, 0, ecx
    stdcall ByteArray.PushSequence, [pObject], [SizeofObject]

    pop ebx

    mov eax, [ebx + ChangeHistory.TotalRecordsCount]
    mov ecx, [ebx + ChangeHistory.PoppedRecordsCount]
    sub eax, ecx
    inc eax
    mov [ebx + ChangeHistory.TotalRecordsCount], eax

    test ecx, ecx
    jz @F

    dec eax
    stdcall ChangeHistory._DestroyByteArrays, eax

    @@:
    lea eax, [NewRecord]
    add ebx, ChangeHistory.History
    stdcall Vector.Push, eax

    ret
endp


proc ChangeHistory.AddChangeRecord, pChangeRecord
    add ebx, ChangeHistory.History
    stdcall Vector.Push, [pChangeRecord]
    sub ebx, ChangeHistory.History

    ret
endp


proc ChangeHistory._DestroyByteArrays uses ebx, StartFromIndex
    mov ecx, [ebx + ChangeHistory.History.Length]
    add ecx, [ebx + ChangeHistory.PoppedRecordsCount]
    jz .Return

    mov eax, [StartFromIndex]
    sub ecx, eax

    mov ebx, [ebx + ChangeHistory.History.Ptr]
    add ebx, ChangeHistoryRecord.Object
    imul eax, sizeof.ChangeHistoryRecord
    add ebx, eax
    .DestroyLoop:
        push ecx
        stdcall ByteArray.Destroy
        pop ecx

        add ebx, sizeof.ChangeHistoryRecord
        loop .DestroyLoop

    .Return:
    ret
endp


proc ChangeHistory.PopOne
    add ebx, ChangeHistory.History
    stdcall Vector.Pop
    sub ebx, ChangeHistory.History

    ret
endp


proc ChangeHistory.PopGroup uses ebx esi edi
    mov eax, [ebx + ChangeHistory.History.Length]
    test eax, eax
    jz .Return

    mov ecx, eax
    mov esi, [ebx + ChangeHistory.History.Ptr]
    dec eax
    imul eax, sizeof.ChangeHistoryRecord
    add esi, eax
    mov edi, [esi + ChangeHistoryRecord.GroupId]
    add ebx, ChangeHistory.History

    .PopLoop:
        push ecx
        stdcall Vector.Pop
        sub esi, sizeof.ChangeHistoryRecord
        pop ecx

        mov eax, [esi + ChangeHistoryRecord.GroupId]
        cmp edi, eax
        jne .Return

        mov edi, eax
        inc [ebx - ChangeHistory.History + ChangeHistory.PoppedRecordsCount]
        loop .PopLoop

    .Return:
    ret
endp


proc ChangeHistory.Clear uses ebx
    stdcall ChangeHistory._DestroyByteArrays, 0
    stdcall ChangeHistory._SetInitialFieldValues

    add ebx, ChangeHistory.History
    stdcall Vector.Clear

    ret
endp


proc ChangeHistory.ClearNoDestroy uses ebx
    stdcall ChangeHistory._SetInitialFieldValues

    add ebx, ChangeHistory.History
    stdcall Vector.Clear

    ret
endp


proc ChangeHistory.Destroy uses ebx
    stdcall ChangeHistory._DestroyByteArrays, 0

    add ebx, ChangeHistory.History
    stdcall Vector.Destroy

    ret
endp

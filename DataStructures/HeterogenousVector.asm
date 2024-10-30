
proc HeterogenousVector.Create uses ebx, Capacity
    mov eax, [Capacity]
    mov [ebx + HeterogenousVector.Capacity], eax

    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, eax
    mov [ebx + HeterogenousVector.Ptr], eax

    mov [ebx + HeterogenousVector.TotalSize], 0

    add ebx, HeterogenousVector.Sizes
    stdcall Vector.Create, HeterogenousVector.BytesForElementSize, 0, HeterogenousVector.IntitialElementsCapacity

    ret
endp


proc HeterogenousVector._Reallocate uses edi esi, RequiredSize
    mov esi, [RequiredSize]

    mov edi, esi
    shl edi, 1
    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, edi
    push eax
    invoke RtlMoveMemory, eax, [ebx + HeterogenousVector.Ptr], esi
    invoke HeapFree, [hProcessHeap], 0, [ebx + HeterogenousVector.Ptr]
    pop eax
    mov [ebx + HeterogenousVector.Ptr], eax
    mov [ebx + HeterogenousVector.Capacity], edi

    ret
endp


proc HeterogenousVector.Push uses ebx edi, pElem, Size
    mov eax, [ebx + HeterogenousVector.Sizes.Ptr]
    mov ecx, [ebx + HeterogenousVector.Sizes.Length]
    xor edx, edx
    test ecx, ecx
    jz .CheckCapacity

    dec ecx
    .CountOffsetLoop:
        mov edi, [eax + ecx*HeterogenousVector.BytesForElementSize]
        add edx, edi

        dec ecx
        jns .CountOffsetLoop

    .CheckCapacity:
    mov ecx, edx
    add ecx, [Size]
    cmp ecx, [ebx + HeterogenousVector.Capacity]
    jbe .Push

    push edx
    stdcall HeterogenousVector._Reallocate, ecx
    pop edx

    .Push:
    mov eax, [ebx + HeterogenousVector.Ptr]
    add eax, edx
    push eax
    invoke RtlMoveMemory, eax, [pElem], [Size]
    mov eax, [Size]
    add [ebx + HeterogenousVector.TotalSize], eax

    add ebx, HeterogenousVector.Sizes
    lea eax, [Size]
    stdcall Vector.Push, eax

    pop eax
    ret
endp


proc HeterogenousVector.Pop uses ebx
    mov ecx, [ebx + HeterogenousVector.Sizes.Length]
    dec ecx
    mov eax, [ebx + HeterogenousVector.Sizes.Ptr]
    mov eax, [eax + ecx*HeterogenousVector.BytesForElementSize]
    sub [ebx + HeterogenousVector.TotalSize], eax

    add ebx, HeterogenousVector.Sizes
    stdcall Vector.Pop

    ret
endp


proc HeterogenousVector.DeleteByIndex uses edi, Index
    mov ecx, [Index]
    mov eax, ecx
    inc eax
    cmp eax, [ebx + HeterogenousVector.Sizes.Length]
    jne .BeforeCountOffsetLoop

    call HeterogenousVector.Pop
    jmp .Return

    .BeforeCountOffsetLoop:
    xor eax, eax
    mov edx, [ebx + HeterogenousVector.Sizes.Ptr]

    test ecx, ecx
    jz .AfterCountOffsetLoop

    .CountOffsetLoop:
        add eax, dword [edx]
        add edx, 4
        loop .CountOffsetLoop

    .AfterCountOffsetLoop:
        mov edi, dword [edx]
        mov ecx, [ebx + HeterogenousVector.TotalSize]
        sub ecx, eax
        sub ecx, edi
        push ecx ; Length

        mov edx, [ebx + HeterogenousVector.Ptr]
        add edx, eax
        mov ecx, edx
        add ecx, edi
        push ecx ; *Source
        push edx ; *Destination

        invoke RtlMoveMemory ; All the arguments are pushed above

        sub [ebx + HeterogenousVector.TotalSize], edi
        add ebx, HeterogenousVector.Sizes
        stdcall Vector.DeleteByIndex, [Index]
        sub ebx, HeterogenousVector.Sizes

    .Return:
    ret
endp


proc HeterogenousVector.PtrByIndex, Index
    mov ecx, [Index]
    mov eax, [ebx + HeterogenousVector.Ptr]
    test ecx, ecx
    jz .Return

    mov edx, [ebx + HeterogenousVector.Sizes.Ptr]
    .CountPtrLoop:
        add eax, [edx]
        add edx, 4
        loop .CountPtrLoop

    .Return:
    ret
endp


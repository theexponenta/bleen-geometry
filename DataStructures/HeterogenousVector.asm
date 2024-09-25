
proc HeterogenousVector.Create uses ebx, Capacity
    mov eax, [Capacity]
    mov [ebx + HeterogenousVector.Capacity], eax

    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, eax
    mov [ebx + HeterogenousVector.Ptr], eax

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
        movzx edi, word[eax + ecx*HeterogenousVector.BytesForElementSize]
        add edx, edi

        dec ecx
        js .CheckCapacity
        jmp .CountOffsetLoop

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

    add ebx, HeterogenousVector.Sizes
    lea eax, [Size]
    stdcall Vector.Push, eax

    pop eax
    ret
endp


proc HeterogenousVector.Pop uses ebx
    add ebx, HeterogenousVector.Sizes
    stdcall Vector.Pop

    ret
endp


proc ByteArray.Create, Capacity
    mov eax, [Capacity]
    mov [ebx + ByteArray.Capacity], eax
    mov [ebx + ByteArray.Size], 0

    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, eax
    mov [ebx + ByteArray.Ptr], eax

    ret
endp


proc ByteArray._Reallocate uses esi edi
    mov esi, [ebx + ByteArray.Capacity]
    shl esi, 1
    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, esi
    mov edi, eax

    shr esi, 1
    invoke RtlMoveMemory, edi, [ebx + ByteArray.Ptr], esi
    invoke HeapFree, [hProcessHeap], 0, [ebx + ByteArray.Ptr]

     shl [ebx + ByteArray.Capacity], 1
     mov [ebx + ByteArray.Ptr], edi

    ret
endp


proc ByteArray.PushSequence uses esi, pSequence, SequenceSize
    mov esi, [SequenceSize]
    mov edx, esi
    add edx, [ebx + ByteArray.Size]
    cmp edx, [ebx + ByteArray.Capacity]
    jbe @F

    stdcall ByteArray._Reallocate

    @@:

    mov eax, [ebx + ByteArray.Ptr]
    add eax, [ebx + ByteArray.Size]
    invoke RtlMoveMemory, eax, [pSequence], esi

    add [ebx + ByteArray.Size], esi

    ret
endp


; ax - word
proc ByteArray.PushWord uses esi
    mov esi, [ebx + ByteArray.Size]
    add esi, 2
    cmp esi, [ebx + ByteArray.Capacity]
    jbe @F

    push eax
    stdcall ByteArray._Reallocate
    pop eax

    @@:

    mov esi, [ebx + ByteArray.Ptr]
    add esi, [ebx + ByteArray.Size]
    mov word [esi], ax
    add [ebx + ByteArray.Size], 2

    ret
endp


; al - byte
proc ByteArray.PushByte uses esi
    mov esi, [ebx + ByteArray.Size]
    add esi, 1
    cmp esi, [ebx + ByteArray.Capacity]
    jbe @F

    push eax
    stdcall ByteArray._Reallocate
    pop eax

    @@:

    mov esi, [ebx + ByteArray.Ptr]
    add esi, [ebx + ByteArray.Size]
    mov byte [esi], al
    add [ebx + ByteArray.Size], 1

    ret
endp


proc ByteArray.Destroy
    invoke HeapFree, [hProcessHeap], [ebx + ByteArray.Ptr]

    ret
endp
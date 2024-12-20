proc Vector.Create ElementSize, Length, Capacity
     mov eax, [ElementSize]
     mov [ebx + Vector.ElementSize], eax

     mov eax, [Length]
     mov [ebx + Vector.Length], eax
     mov eax, [Capacity]
     mov [ebx + Vector.Capacity], eax
     mov [ebx + Vector.Ptr], 0

     mov edx, eax
     imul edx, [ElementSize]
     invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, edx
     mov [ebx + Vector.Ptr], eax

     ret
endp


proc Vector._Reallocate uses esi edi
     mov esi, [ebx + Vector.Capacity]
     imul esi, [ebx + Vector.ElementSize]
     shl esi, 1
     invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, esi
     mov edi, eax

     shr esi, 1
     invoke RtlMoveMemory, edi, [ebx + Vector.Ptr], esi
     invoke HeapFree, [hProcessHeap], 0, [ebx + Vector.Ptr]

     shl [ebx + Vector.Capacity], 1
     mov [ebx + Vector.Ptr], edi

     ret
endp


proc Vector.Push pElement
     mov eax, [ebx + Vector.Length]
     cmp eax, [ebx + Vector.Capacity]
     jb .Push

     push eax
     stdcall Vector._Reallocate
     pop eax

     .Push:
     imul eax, [ebx + Vector.ElementSize]
     add eax, [ebx + Vector.Ptr]
     push eax
     invoke RtlMoveMemory, eax, [pElement], [ebx + Vector.ElementSize]
     inc dword[ebx + Vector.Length]

     pop eax
     ret
endp


proc Vector.PushValue Value
     lea eax, [Value]
     stdcall Vector.Push, eax
     ret
endp


proc Vector.Pop
     ; Decrement length, but if length is 0, it must stay 0
     ; Here is a way to do it without branching
     mov eax, [ebx + Vector.Length]
     dec eax
     cdq
     xor eax, edx
     mov [ebx + Vector.Length], eax

     ret
endp


proc Vector.Unpop
    inc [ebx + Vector.Length]
    ret
endp


proc Vector.DeleteByIndex, Index
     mov eax, [Index]
     imul eax, [ebx + Vector.ElementSize]
     add eax, [ebx + Vector.Ptr]
     mov edx, eax
     add edx, [ebx + Vector.ElementSize]

     mov ecx, [ebx + Vector.Length]
     sub ecx, [Index]
     imul ecx, [ebx + Vector.ElementSize]

     invoke RtlMoveMemory, eax, edx, ecx
     dec [ebx + Vector.Length]

     ret
endp


proc Vector.Clear
    mov [ebx + Vector.Length], 0
    ret
endp


proc Vector.Destroy
    call Vector.Clear
    mov [ebx + Vector.Capacity], 0
    invoke HeapFree, [hProcessHeap], 0, [ebx + Vector.Ptr]
    mov [ebx + Vector.Ptr], 0
    ret
endp


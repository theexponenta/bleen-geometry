
proc LinkedList.Create uses edi, pLinkedList
     mov edi, [pLinkedList]
     xor eax, eax
     mov dword [edi + LinkedList.Length], eax
     mov [edi + LinkedList.pHead], eax
     ret
endp


proc LinkedList.Add uses edi ebx, pLinkedList, pElem
     mov edi, [pLinkedList]

     invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, sizeof.LinkedListNode
     mov ebx, eax
     mov eax, [pElem]
     mov [ebx + LinkedListNode.pElem], eax
     mov eax, [edi + LinkedList.pHead]
     mov [ebx + LinkedListNode.pNext], eax
     mov [edi + LinkedList.pHead], ebx
     inc [edi + LinkedList.Length]

     ret
endp


proc LinkedList.Delete uses esi ebx edx, pLinkedList, pElem
     mov esi, [pLinkedList]
     mov ebx, [pElem]

     mov eax, [esi + LinkedList.pHead]
     xor edx, edx
     .FindLoop:
         test eax, eax
         jz .Return

         cmp [eax + LinkedListNode.pElem], ebx
         je .Delete

         mov edx, eax
         mov eax, [eax + LinkedListNode.pNext]
         jmp .FindLoop

    .Delete:
        mov ebx, [eax + LinkedListNode.pNext]
        test edx, edx
        jz .DeleteHead

        mov [edx + LinkedListNode.pNext], ebx
        jmp @F

        .DeleteHead:
        mov [esi + LinkedList.pHead], ebx

        @@:
        invoke HeapFree, [hProcessHeap], 0, eax
        dec dword[esi + LinkedList.Length]


     .Return:
     ret
endp
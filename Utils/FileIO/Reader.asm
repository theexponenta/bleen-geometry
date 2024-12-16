
proc FileReader.Read uses ebx esi, lpFileName, pPoints, pObjects, pNextPointNum, pNextObjectId, pTranslateX, pTranslateY, pScale
    locals
        hFile dd ?
        ParamsBuffer dd 5 dup(?)
        NumberOfBytesRead dd ?
    endl

    invoke CreateFileW, [lpFileName], GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov [hFile], eax
    mov esi, eax

    lea edx, [ParamsBuffer]
    lea ecx, [NumberOfBytesRead]
    invoke ReadFile, eax, edx, 4*5, ecx, NULL

    mov eax, [ParamsBuffer]
    mov edx, [pNextPointNum]
    mov [edx], eax

    mov eax, [ParamsBuffer + 4]
    mov edx, [pNextObjectId]
    mov [edx], eax

    mov eax, [ParamsBuffer + 8]
    mov edx, [pTranslateX]
    mov [edx], eax

    mov eax, [ParamsBuffer + 12]
    mov edx, [pTranslateY]
    mov [edx], eax

    mov eax, [ParamsBuffer + 16]
    mov edx, [pScale]
    mov [edx], eax

    mov ebx, [pPoints]
    lea eax, [NumberOfBytesRead]
    invoke ReadFile, [hFile], ebx, sizeof.Vector - 4, eax, NULL
    stdcall Vector.Create, [ebx + Vector.ElementSize], [ebx + Vector.Length], [ebx + Vector.Capacity]

    mov ecx, [ebx + Vector.Length]
    test ecx, ecx
    jz .ReadObjects

    mov ebx, [ebx + Vector.Ptr]
    .ReadPointsLoop:
        push ecx
        stdcall FileReader.ReadGeometryObject, esi, ebx
        pop ecx

        add ebx, sizeof.Point
        loop .ReadPointsLoop


    .ReadObjects:
    mov ebx, [pObjects]
    lea eax, [NumberOfBytesRead]
    invoke ReadFile, [hFile], ebx, sizeof.HeterogenousVector - sizeof.Vector - 4, eax, NULL
    stdcall HeterogenousVector.Allocate, [ebx + HeterogenousVector.Capacity]

    mov eax, ebx
    add eax, HeterogenousVector.Sizes
    stdcall FileReader.ReadVector, eax

    mov ecx, [ebx + HeterogenousVector.Sizes.Length]
    test ecx, ecx
    jz .End

    mov esi, [ebx + HeterogenousVector.Ptr]
    mov edi, [ebx + HeterogenousVector.Sizes.Ptr]
    mov ebx, [hFile]
    .ReadObjectsLoop:
        push ecx
        stdcall FileReader.ReadGeometryObject, ebx, esi
        pop ecx

        add esi, [edi]
        add edi, 4
        loop .ReadObjectsLoop

    .End:
    invoke CloseHandle, [hFile]
    ret
endp


proc FileReader.ReadGeometryObject uses ebx esi, hFile, pGeometryObject
    locals
        NumberOfBytesRead dd ?
    endl

    mov ebx, [pGeometryObject]
    mov esi, [hFile]

    lea eax, [NumberOfBytesRead]
    invoke ReadFile, [hFile], ebx, sizeof.GeometryObject - sizeof.Vector - 4*2, eax, NULL

    stdcall FileReader.ReadDelphiString
    mov [ebx + GeometryObject.pName], eax
    stdcall FileReader.ReadDelphiString
    mov [ebx + GeometryObject.pCaption], eax

    mov eax, ebx
    add eax, GeometryObject.AttachedPointsIds
    stdcall FileReader.ReadVector, eax

    movzx eax, byte [ebx + GeometryObject.Type]
    lea edx, [NumberOfBytesRead]
    add ebx, sizeof.GeometryObject

    cmp eax, OBJ_PLOT
    jne @F

    invoke ReadFile, esi, ebx, sizeof.Plot - sizeof.GeometryObject - sizeof.ByteArray - 4, edx, NULL
    stdcall FileReader.ReadCString
    mov [ebx + Plot.pEquationStr - sizeof.GeometryObject], eax
    add ebx, Plot.RPN - sizeof.GeometryObject
    stdcall FileReader.ReadByteArray, ebx

    jmp .Return

    @@:
    cmp eax, OBJ_POLYGON
    jne @F

    invoke ReadFile, esi, ebx, sizeof.PolygonObj - sizeof.GeometryObject - sizeof.Vector, edx, NULL
    add ebx, PolygonObj.SegmentsIds - sizeof.GeometryObject
    stdcall FileReader.ReadVector, ebx

    jmp .Return

    @@:
    cmp eax, OBJ_POLYLINE
    jne @F

    invoke ReadFile, esi, ebx, sizeof.PolylineObj - sizeof.GeometryObject - sizeof.Vector, edx, NULL
    add ebx, PolylineObj.PointsIds - sizeof.GeometryObject
    stdcall FileReader.ReadVector, ebx

    jmp .Return

    @@:
    sub eax, 1
    shl eax, 2
    add eax, Objects.StructSizes
    mov ecx, [eax]
    sub ecx, sizeof.GeometryObject
    lea edx, [NumberOfBytesRead]
    invoke ReadFile, esi, ebx, ecx, edx, NULL

    .Return:
    ret
endp


; ----- All the functions below accept hFile parameter in ESI register -----


; Returns pointer to newly allocated string
proc FileReader.ReadDelphiString
    locals
        NumberOfBytesRead dd ?
        Length dd ?
        pStr dd ?
    endl

    lea ecx, [Length]
    lea eax, [NumberOfBytesRead]
    invoke ReadFile, esi, ecx, 4, eax, NULL

    mov ecx, [Length]
    shl ecx, 1 ; Unicode
    add ecx, 6 ; 4 bytes for length, 2 for 0 character
    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, ecx
    mov [pStr], eax

    mov ecx, [Length]
    mov [eax], ecx
    add eax, 4

    shl ecx, 1
    lea edx, [NumberOfBytesRead]
    invoke ReadFile, esi, eax, ecx, edx, NULL

    mov eax, [pStr]
    add eax, 4
    ret
endp


; Returns pointer to newly allocated string
proc FileReader.ReadCString
    locals
        NumberOfBytesRead dd ?
        Length dd ?
        pStr dd ?
    endl

    lea ecx, [Length]
    lea eax, [NumberOfBytesRead]
    invoke ReadFile, esi, ecx, 4, eax, NULL

    mov ecx, [Length]
    shl ecx, 1 ; Unicode
    add ecx, 2 ; 2 bytes for 0 character
    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, ecx
    mov [pStr], eax

    mov ecx, [Length]
    shl ecx, 1
    lea edx, [NumberOfBytesRead]
    invoke ReadFile, esi, eax, ecx, edx, NULL

    mov eax, [pStr]
    ret
endp


proc FileReader.ReadVector uses ebx, pVector
    locals
        NumberOfBytesRead dd ?
    endl

    mov ebx, [pVector]
    lea eax, [NumberOfBytesRead]
    invoke ReadFile, esi, ebx, sizeof.Vector - 4, eax, NULL
    stdcall Vector.Create, [ebx + Vector.ElementSize], [ebx + Vector.Length], [ebx + Vector.Capacity]

    mov ecx, [ebx + Vector.Length]
    test ecx, ecx
    jz .Return

    imul ecx, [ebx + Vector.ElementSize]
    lea eax, [NumberOfBytesRead]
    invoke ReadFile, esi, [ebx + Vector.Ptr], ecx, eax, NULL

    .Return:
    ret
endp


proc FileReader.ReadByteArray uses ebx, pBytearray
    locals
        NumberOfBytesRead dd ?
    endl

    mov ebx, [pBytearray]
    lea eax, [NumberOfBytesRead]
    invoke ReadFile, esi, ebx, sizeof.ByteArray - 4, eax, NULL
    stdcall ByteArray.Create, [ebx + ByteArray.Size], [ebx + ByteArray.Capacity]

    lea eax, [NumberOfBytesRead]
    invoke ReadFile, esi, [ebx + ByteArray.Ptr], [ebx + ByteArray.Size], eax, NULL

    ret
endp

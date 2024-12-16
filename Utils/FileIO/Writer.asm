

proc FileWriter.Save uses esi edi ebx, lpFileName, pPoints, pObjects, NextPointNum, NextObjectId, TranslateX, TranslateY, Scale
    locals
        hFile dd ?
        NumbersOfBytesWritten dd ?
    endl

    invoke CreateFileW, [lpFileName], GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov [hFile], eax
    mov esi, eax

    lea ecx, [NextPointNum]
    lea edx, [NumbersOfBytesWritten]
    invoke WriteFile, esi, ecx, 4*5, edx, NULL

    mov eax, [pPoints]
    lea edx, [NumbersOfBytesWritten]
    invoke WriteFile, esi, eax, sizeof.Vector - 4, edx, NULL

    mov eax, [pPoints]
    mov ecx, [eax + Vector.Length]
    test ecx, ecx
    jz .WriteObjects
    mov ebx, [eax + Vector.Ptr]
    .WritePointsLoop:
        push ecx
        stdcall FileWriter.WriteGeometryObject, esi, ebx
        pop ecx

        add ebx, sizeof.Point
        loop .WritePointsLoop

    .WriteObjects:
    lea edx, [NumbersOfBytesWritten]
    invoke WriteFile, esi, [pObjects], sizeof.HeterogenousVector - sizeof.Vector - 4, edx, NULL

    mov eax, [pObjects]
    add eax, HeterogenousVector.Sizes
    stdcall FileWriter.WriteVector, eax

    mov ebx, [hFile]
    mov eax, [pObjects]
    mov ecx, [eax + HeterogenousVector.Sizes.Length]
    test ecx, ecx
    jz .Return
    mov esi, [eax + HeterogenousVector.Ptr]
    mov edi, [eax + HeterogenousVector.Sizes.Ptr]
    .WriteObjectsLoop:
        push ecx
        stdcall FileWriter.WriteGeometryObject, ebx, esi
        pop ecx

        add esi, [edi]
        add edi, 4
        loop .WriteObjectsLoop

    invoke FlushFileBuffers, [hFile]
    invoke CloseHandle, [hFile]

    .Return:
    ret
endp


proc FileWriter.WriteGeometryObject uses ebx edi esi, hFile, pGeometryObject
    locals
        NumbersOfBytesWritten dd ?
    endl

    mov ebx, [pGeometryObject]
    lea edi, [NumbersOfBytesWritten]
    mov esi, [hFile]

    invoke WriteFile, esi, ebx, sizeof.GeometryObject - sizeof.Vector - 4*2, edi, NULL

    stdcall FileWriter.WriteDelphiString, [ebx + GeometryObject.pName]
    stdcall FileWriter.WriteDelphiString, [ebx + GeometryObject.pCaption]

    mov eax, ebx
    add eax, GeometryObject.AttachedPointsIds
    stdcall FileWriter.WriteVector, eax

    movzx eax, byte [ebx + GeometryObject.Type]
    add ebx, sizeof.GeometryObject

    cmp eax, OBJ_PLOT
    jne @F

    invoke WriteFile, esi, ebx, sizeof.Plot - sizeof.GeometryObject - sizeof.ByteArray - 4, edi, NULL
    stdcall FileWriter.WriteCString, [ebx + Plot.pEquationStr - sizeof.GeometryObject]
    add ebx, Plot.RPN - sizeof.GeometryObject
    stdcall FileWriter.WriteByteArray, ebx

    jmp .Return

    @@:
    cmp eax, OBJ_POLYGON
    jne @F

    invoke WriteFile, esi, ebx, sizeof.PolygonObj - sizeof.GeometryObject - sizeof.Vector, edi, NULL
    add ebx, PolygonObj.SegmentsIds - sizeof.GeometryObject
    stdcall FileWriter.WriteVector, ebx

    jmp .Return

    @@:
    cmp eax, OBJ_POLYLINE
    jne @F

    invoke WriteFile, esi, ebx, sizeof.PolylineObj - sizeof.GeometryObject - sizeof.Vector, edi, NULL
    add ebx, PolylineObj.PointsIds - sizeof.GeometryObject
    stdcall FileWriter.WriteVector, ebx

    jmp .Return

    @@:
    sub eax, 1
    shl eax, 2
    add eax, Objects.StructSizes
    mov ecx, [eax]
    sub ecx, sizeof.GeometryObject
    invoke WriteFile, [hFile], ebx, ecx, edi, NULL

    .Return:
    ret
endp


; ----- All the functions below accept hFile parameter in ESI register -----


proc FileWriter.WriteVector, pVector
    locals
        NumbersOfBytesWritten dd ?
    endl

    lea eax, [NumbersOfBytesWritten]
    invoke WriteFile, esi, [pVector], sizeof.Vector - 4, eax, NULL

    mov eax, [pVector]
    mov ecx, [eax + Vector.ElementSize]
    test ecx, ecx
    jz .Return

    imul ecx, [eax + Vector.Length]

    lea edx, [NumbersOfBytesWritten]
    invoke WriteFile, esi, [eax + Vector.Ptr], ecx, edx, NULL

    .Return:
    ret
endp


proc FileWriter.WriteDelphiString, pStr
    locals
        NumbersOfBytesWritten dd ?
        Zero dd 0
    endl

    lea eax, [NumbersOfBytesWritten]
    mov edx, [pStr]
    test edx, edx
    jz .EmptyString

    sub edx, 4
    mov ecx, [edx]
    shl ecx, 1 ; Unicode
    add ecx, 4 ; For string length
    jmp .Write

    .EmptyString:
    lea edx, [Zero]
    mov ecx, 4

    .Write:
    invoke WriteFile, esi, edx, ecx, eax, NULL

    ret
endp


proc FileWriter.WriteCString, pStr
    locals
        NumbersOfBytesWritten dd ?
        Length dd ?
    endl

    invoke lstrlenW, [pStr]
    mov [Length], eax

    lea edx, [NumbersOfBytesWritten]
    lea ecx, [Length]
    invoke WriteFile, esi, ecx, 4, edx, NULL

    mov eax, [Length]
    shl eax, 1 ; Unicode
    lea edx, [NumbersOfBytesWritten]
    invoke WriteFile, esi, [pStr], eax, edx, NULL

    ret
endp


proc FileWriter.WriteByteArray, pBytearray
    locals
        NumbersOfBytesWritten dd ?
    endl

    lea eax, [NumbersOfBytesWritten]
    invoke WriteFile, esi, [pBytearray], sizeof.ByteArray - 4, eax, NULL

    mov eax, [pBytearray]
    mov ecx, [eax + ByteArray.Size]
    test ecx, ecx
    jz .Return

    lea edx, [NumbersOfBytesWritten]
    invoke WriteFile, esi, [eax + ByteArray.Ptr], ecx, edx, NULL

    .Return:
    ret
endp

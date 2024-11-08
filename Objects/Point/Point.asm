
proc Point.Create Id, pName, pCaption, X, Y, Color, Size, ParentObjectId
    stdcall GeometryObject.Create, [Id], OBJ_POINT, [pName], [pCaption]

    mov eax, [X]
    mov [ebx + Point.X], eax
    
    mov eax, [Y]
    mov [ebx + Point.Y], eax
    
    mov eax, [Color]
    mov [ebx + Point.Color], eax
    
    mov eax, [Size]
    mov [ebx + Point.Size], eax

    mov eax, [Size]
    mov [ebx + Point.Size], eax

    mov eax, [ParentObjectId]
    mov [ebx + Point.ParentObjectId], eax

    ret
endp


proc Point.Draw uses edi, hdc
    locals
        CenterX dd ?
        CenterY dd ?
    endl

    ; Uninitialized points have Id = 0
    ; They are used when user needs to select a point to end
    ; adding a new object
    ; Unitialized points are not painted
    cmp [ebx + Point.Id], 0
    je .Return

    mov edi, [hdc]

    invoke GetStockObject, DC_BRUSH
    invoke SelectObject, edi, eax
    invoke SelectObject, edi, [Point.BorderPen]

    invoke SetDCBrushColor, edi, [ebx + Point.Color]

    ; Circle
    stdcall Main.ToScreenPosition, [ebx + Point.X], [ebx + Point.Y]
    mov [CenterX], edx
    mov [CenterY], eax
    mov eax, [ebx + Point.Size]
    stdcall Draw.Circle, edi, [CenterX], [CenterY], eax

    cmp [ebx + Point.IsSelected], 1
    jne @F

    ; Circle for selected point
    invoke GetStockObject, NULL_BRUSH
    invoke SelectObject, edi, eax

    invoke CreatePen, PS_SOLID, Point.SelectedBorderSize, [ebx + Point.Color]
    mov [Point.SelectedBorderPen], eax
    invoke SelectObject, edi, eax

    mov eax, [ebx + Point.Size]
    shl eax, 1
    stdcall Draw.Circle, edi, [CenterX], [CenterY], eax

    invoke GetStockObject, DC_PEN
    invoke DeleteObject, [Point.SelectedBorderPen]

    @@:
    ; Name
    fld [CenterX]
    fistp [CenterX]
    fld [CenterY]
    fistp [CenterY]
    invoke SetTextColor, edi, [ebx + Point.Color]
    mov eax, [CenterX]
    add eax, Point.NameTextOffset
    mov ecx, [CenterY]
    sub ecx, Point.NameTextOffset

    ; Get delphi-string length
    mov edx, [ebx + Point.pName]
    mov edx, [edx - 4]

    invoke TextOutW, edi, eax, ecx, [ebx + Point.pName], edx

    .Return:
    ret
endp


; eax - Point num
; Returns pointer to string in eax
proc Point.PointNumToName uses ebx
    local LetterIndex dd ?

    xor edx, edx
    mov ebx, 26
    div ebx

    ; Count name characters in ecx
    mov ecx, 1
    test eax, eax
    je .MakeString

    mov [LetterIndex], eax

    push eax edx ecx
    call Math.CountDigits
    pop ecx
    add ecx, eax
    inc ecx ; Count _ character
    pop edx eax

    .MakeString:
    mov ebx, ecx
    shl ebx, 1
    add ebx, 4 ; for length before string
    push edx ecx
    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, ebx
    pop ecx edx
    add edx, 'A'

    mov [eax], ecx
    mov [eax + 4], dx
    cmp ecx, 1
    je .Return

    mov [eax + 6], word '_'

    ; eax + 8 - place to start write letter index
    mov ecx, eax
    add ecx, 8
    push eax
    mov eax, [LetterIndex]
    stdcall Strings.NumToString
    pop eax

    .Return:
    add eax, 4 ; Delphi-string pointer points to the beginning of the string, leaving 4 bytes of length behind
    ret
endp


; edx - dX
; ecx - dY
proc Point.Move
    locals
        delta dd ?
    endl

    mov [delta], edx
    fld [delta]
    fadd [ebx + Point.X]
    fstp [ebx + Point.X]
    mov [delta], ecx
    fld [delta]
    fadd [ebx + Point.Y]
    fstp [ebx + Point.Y]

    ret
endp


proc Point.IsOnPosition X, Y
    fld [X]
    fld [Y]

    fld [ebx + Point.X]
    fsub st0, st2
    fmul st0, st0
    fld [ebx + Point.Y]
    fsub st0, st2
    fmul st0, st0
    faddp
    fsqrt

    fild [ebx + Point.Size]
    fcomip st, st1
    fstp st0
    jae .ReturnTrue

    xor eax, eax
    jmp .Return

    .ReturnTrue:
    mov eax, 1

    .Return:
    ret
endp


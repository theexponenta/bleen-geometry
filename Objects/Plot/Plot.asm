
proc Plot.Create uses ebx, Id, pName, pCaption, PlotType, pEquationStr, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_PLOT, [pName], [pCaption]

    mov eax, [Width]
    mov [ebx + Plot.Width], eax

    mov eax, [Color]
    mov [ebx + Plot.Color], eax

    mov eax, [PlotType]
    mov byte [ebx + Plot.PlotType], al

    mov eax, [pEquationStr]
    mov [ebx + Plot.pEquationStr], eax

    add ebx, Plot.RPN
    stdcall ByteArray.Create, 64

    ret
endp


proc Plot.Draw uses edi esi, hDC
    locals
        PrevYScreen dd ?
        PrevXScreen dd ?
        CurXScreen dd ?
        CurYScreen dd ?

        CurXPlane dd ?

        hPen dd ?
        hPenSelected dd ?
        SelectedWidth dd ?
    endl

    invoke CreatePen, PS_SOLID, [ebx + Plot.Width], [ebx + Plot.Color]
    mov [hPen], eax
    invoke SelectObject, [hDC], eax

    ; esi
    ; bit 0 - 1 if current point visible, 0 otherwise
    ; bit 1 - 0 if no points are pushed yet, 1 otherwise
    ; bit 2 - if object is selected
    ; bit 3 - 1 if current point is undefined, 0 otherwise
    mov esi, 1

    cmp [ebx + Plot.IsSelected], 0
    je @F

    or esi, 100b

    fild [ebx + Plot.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    invoke CreatePen, PS_SOLID, [SelectedWidth], GeometryObject.SelectedLineColor
    mov [hPenSelected], eax

    @@:
    mov ecx, [DrawArea.Width]
    sub ecx, [ObjectsListWindow.Width]
    shr ecx, 1
    xor edi, edi

    fild [DrawArea.Height]
    fldz

    .DrawLoop:
        fist [CurXScreen]
        fld st0
        fsub [Translate.x]
        fdiv [Scale]
        fstp [CurXPlane]

        lea eax, [ebx + Plot.RPN]
        push ecx
        stdcall MathParser.Calculate, eax, [CurXPlane]
        pop ecx

        fstsw ax
        fclex
        and ax, 1
        cwde
        shl eax, 3
        or esi, eax
        test eax, eax
        jnz .CurrentPointInvisible

        fmul [Scale]
        fsubr [Translate.y]
        fist [CurYScreen]

        fldz
        fcomip st0, st1
        ja .CurrentPointInvisible
        fcomi st0, st2
        ja .CurrentPointInvisible

        ; If current point is visible, push prev point if:
        ;     prev point is invisible - bit0=0
        ;     prev point is defined - bit3=0
        mov edx, esi
        test edx, 1001b
        jnz @F

        push [PrevYScreen]
        push [PrevXScreen]
        add edi, 1

        @@:
        push [CurYScreen]
        push [CurXScreen]
        add edi, 1

        or esi, 11b
        and esi, not 1000b
        jmp .NextIteration

        .CurrentPointInvisible:
        mov edx, esi
        and esi, not 1
        test edx, 1
        jz .DrawChunk

        push [CurYScreen]
        push [CurXScreen]
        add edi, 1

        .DrawChunk:
        cmp edi, 2
        jb .ClearStack

        test esi, 100b
        jz .DrawUnselected

        push ecx
        invoke SelectObject, [hDC], [hPenSelected]
        pop ecx
        mov eax, esp
        push ecx
        invoke Polyline, [hDC], eax, edi
        invoke SelectObject, [hDC], [hPen]
        pop ecx

        .DrawUnselected:
        mov eax, esp
        push ecx
        invoke Polyline, [hDC], eax, edi
        pop ecx

        .ClearStack:
        shl edi, 3
        add esp, edi
        xor edi, edi

        .NextIteration:
        fistp [PrevYScreen]
        fist [PrevXScreen]
        fadd [Plot.ScreenStep]
        sub ecx, 1
        jnz .DrawLoop

    test edi, edi
    jz .ClearResources

    test esi, 100b
    jz @F

    invoke SelectObject, [hDC], [hPenSelected]
    mov eax, esp
    invoke Polyline, [hDC], eax, edi
    invoke SelectObject, [hDC], [hPen]

    @@:
    mov eax, esp
    invoke Polyline, [hDC], eax, edi
    shl edi, 3
    add esp, edi

    .ClearResources:
    invoke DeleteObject, [hPen]
    test esi, 100b
    jz .Finish

    invoke DeleteObject, [hPenSelected]

    .Finish:
    fstp st0
    fstp st0
    ret
endp


proc Plot.IsOnPosition, X, Y
    lea eax, [ebx + Plot.RPN]
    stdcall MathParser.Calculate, eax, [X]
    fsub [Y]
    fabs

    xor eax, eax

    fild [ebx + Plot.Width]
    fdiv [Scale]
    fcomip st0, st1
    jb .Return

    mov eax, 1

    .Return:
    fstp st0
    ret
endp


proc Plot.Move
    ret
endp


proc Plot.ToString, pBuffer
    cinvoke swprintf, [pBuffer], Plot.StrFormat, [ebx + Plot.pEquationStr]
    ret
endp


proc Plot.Destroy uses ebx
    add ebx, Plot.RPN
    stdcall ByteArray.Destroy

    ret
endp
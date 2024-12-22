
proc Plot.Create uses ebx, Id, pName, pCaption, PlotType, pXEquationStr, pYEquationStr, tMin, tMax, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_PLOT, [pName], [pCaption]

    mov eax, [Width]
    mov [ebx + Plot.Width], eax

    mov eax, [Color]
    mov [ebx + Plot.Color], eax

    mov eax, [PlotType]
    mov byte [ebx + Plot.PlotType], al

    mov eax, [pXEquationStr]
    mov [ebx + Plot.pXEquationStr], eax

    mov eax, [pYEquationStr]
    mov [ebx + Plot.pYEquationStr], eax

    mov eax, [tMin]
    mov [ebx + Plot.tmin], eax

    mov eax, [tMax]
    mov [ebx + Plot.tmax], eax

    add ebx, Plot.RPNY
    stdcall ByteArray.Create, 0, 64
    sub ebx, Plot.RPNY

    cmp [PlotType], Plot.Type.Parametric
    jne .Return

    add ebx, Plot.RPNX
    stdcall ByteArray.Create, 0, 64

    .Return:
    ret
endp


proc Plot.DrawRegular uses edi esi, hDC
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

        lea eax, [ebx + Plot.RPNY]
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


proc Plot.DrawParametric uses edi, hDC
    locals
        PointsCount dd ?
        CurT dd ?
        CurXScreen dd ?
        CurYScreen dd ?
        hPen dd ?
    endl

    invoke CreatePen, PS_SOLID, [ebx + Plot.Width], [ebx + Plot.Color]
    mov [hPen], eax
    invoke SelectObject, [hDC], eax

    fld [ebx + Plot.tmax]
    fsub [ebx + Plot.tmin]

    mov ecx, [DrawArea.Width]
    sub ecx, [ObjectsListWindow.Width]
    shr ecx, 1
    mov [PointsCount], ecx

    fidiv [PointsCount]

    fld [ebx + Plot.tmin]

    .DrawLoop:
        fst [CurT]

        push ecx

        lea eax, [ebx + Plot.RPNX]
        stdcall MathParser.Calculate, eax, [CurT]
        fmul [Scale]
        fsubr [Translate.x]
        fistp [CurXScreen]

        lea eax, [ebx + Plot.RPNY]
        stdcall MathParser.Calculate, eax, [CurT]
        fmul [Scale]
        fsubr [Translate.y]
        fistp [CurYScreen]

        pop ecx

        push [CurYScreen] [CurXScreen]

        fadd st0, st1
        loop .DrawLoop

    mov eax, esp
    mov edi, [PointsCount]
    invoke Polyline, [hDC], eax, edi
    shl edi, 3
    add esp, edi

    invoke DeleteObject, [hPen]

    fstp st0
    fstp st0
    ret
endp


proc Plot.Draw, hDC
    mov eax, [hDC]

    cmp byte [ebx + Plot.PlotType], Plot.Type.Regular
    jne @F

    stdcall Plot.DrawRegular, eax
    jmp .Return

    @@:
    stdcall Plot.DrawParametric, eax

    .Return:
    ret
endp


proc Plot.IsOnPosition, X, Y
    xor eax, eax
    cmp byte [ebx + Plot.PlotType], Plot.Type.Parametric
    je .Return

    lea eax, [ebx + Plot.RPNY]
    stdcall MathParser.Calculate, eax, [X]
    fsub [Y]
    fabs

    xor eax, eax

    fild [ebx + Plot.Width]
    fdiv [Scale]
    fcomip st0, st1
    jb .Finish

    mov eax, 1

    .Finish:
    fstp st0
    .Return:
    ret
endp


proc Plot.Move
    ret
endp


proc Plot.ToString, pBuffer
    cmp byte [ebx + Plot.PlotType], Plot.Type.Regular
    jne @F

    cinvoke swprintf, [pBuffer], Plot.StrFormatRegular, [ebx + Plot.pYEquationStr]
    jmp .Return

    @@:
    cinvoke swprintf, [pBuffer], Plot.StrFormatParametric, [ebx + Plot.pXEquationStr], [ebx + Plot.pYEquationStr]

    .Return:
    ret
endp


proc Plot.Destroy uses ebx
    add ebx, Plot.RPNY
    stdcall ByteArray.Destroy
    sub ebx, Plot.RPNY

    cmp byte [ebx + Plot.PlotType], Plot.Type.Parametric
    jne .Return

    add ebx, Plot.RPNX
    stdcall ByteArray.Destroy

    .Return:
    ret
endp
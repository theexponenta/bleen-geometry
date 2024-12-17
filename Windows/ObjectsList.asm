
proc ObjectsListWindow.WindowProc uses ebx esi edi, hWnd, wmsg, wparam, lparam
    locals
        ScrollbarInfo SCROLLBARINFO ?
    endl

    mov eax, [wmsg]

    cmp eax, WM_PAINT
    je .Wmpaint
    cmp eax, WM_DESTROY
    je .Wmdestroy
    cmp eax, WM_CREATE
    je .Wmcreate
    cmp eax, WM_VSCROLL
    je .Wmvscroll
    cmp eax, WM_MOUSEWHEEL
    je .Wmmousewheel
    cmp eax, WM_SIZE
    je .Wmsize
    cmp eax, WM_LBUTTONDOWN
    je .Wmlbuttondown
    cmp eax, WM_LBUTTONDBLCLK
    je .Wmlbuttondblclk

    invoke DefWindowProc, [hWnd], [wmsg], [wparam], [lparam]
    jmp .Return

    .Wmcreate:
        invoke CreatePen, PS_SOLID, ObjectsListWindow.VisibilityCircleBorderWidth, ObjectsListWindow.VisibilityCircleColor
        mov [ObjectsListWindow.hVisibilityCirclePen], eax
        invoke CreateSolidBrush, ObjectsListWindow.VisibilityCircleColor
        mov [ObjectsListWindow.hVisibilityCircleFilledBrush], eax
        invoke CreateSolidBrush, 0xFFFFFF
        mov [ObjectsListWindow.hVisibilityCircleWhiteBrush], eax
        invoke CreatePen, PS_SOLID, ObjectsListWindow.SeparatorWidth, ObjectsListWindow.SeparatorColor
        mov [ObjectsListWindow.hSeparatorPen], eax
        invoke CreateSolidBrush, 0x00F0F0F0
        mov [ObjectsListWindow.hBackgroundBrush], eax

        jmp .Return_0

    .Wmpaint:
        invoke BeginPaint, [hWnd], ObjectsListWindow.PaintStruct
        stdcall ObjectsListWindow._Paint, eax
        invoke EndPaint, [hWnd], ObjectsListWindow.PaintStruct

        jmp .Return_0

    .Wmvscroll:
        movzx eax, word [wparam]
        mov ecx, [ObjectsListWindow.CurrentScroll]

        cmp eax, SB_LINEDOWN
        jne @F
        add ecx, ObjectsListWindow.ScrollStep
        jmp .SetScroll

        @@:
        cmp eax, SB_LINEUP
        jne @F
        add ecx, -ObjectsListWindow.ScrollStep
        jmp .SetScroll

        @@:
        cmp eax, SB_THUMBTRACK
        jne @F

        movzx ecx, word [wparam + 2]
        jmp .SetScroll

        @@:
        .SetScroll:

        stdcall ObjectsListWindow._SetScroll, ecx

        jmp .Return_0

    .Wmmousewheel:
        mov ecx, ObjectsListWindow.ScrollStep
        mov ax, word [wparam + 2]
        cmp ax, 0
        jl @F

        neg ecx

        @@:
        add ecx, [ObjectsListWindow.CurrentScroll]
        stdcall ObjectsListWindow._SetScroll, ecx

        jmp .Return_0

    .Wmsize:
        mov [ScrollbarInfo.cbSize], sizeof.SCROLLBARINFO
        lea eax, [ScrollbarInfo]
        invoke GetScrollBarInfo, [hWnd], OBJID_VSCROLL, eax

        movzx eax, word [lparam]
        add eax, [ScrollbarInfo.dxyLineButton]
        movzx edx, word [lparam + 2]
        mov [ObjectsListWindow.Width], eax
        mov [ObjectsListWindow.Height], edx
        stdcall ObjectsListWindow._SetScrollPageAndRange
        stdcall ObjectsListWindow.Redraw

        jmp .Return_0

    .Wmlbuttondown:
        movzx edx, byte [lparam]
        cmp edx, ObjectsListWindow.VisibilityCircleSectionWidth
        ja .Return_0

        movzx eax, word [lparam + 2]
        stdcall ObjectsListWindow._GetIndexByYPosition, eax
        stdcall ObjectsListWindow._ToggleHideObject, eax
        stdcall DrawArea.Redraw
        stdcall ObjectsListWindow.Redraw

        jmp .Return_0

    .Wmlbuttondblclk:
        movzx edx, byte [lparam]
        cmp edx, ObjectsListWindow.VisibilityCircleSectionWidth
        jb .Return_0

        movzx eax, word [lparam + 2]
        stdcall ObjectsListWindow._GetIndexByYPosition, eax
        cmp eax, -1
        je .Return_0

        stdcall ObjectsListWindow._GetObjectByIndex, eax
        stdcall ObjectSettingsWindow.EditObject, eax

        jmp .Return_0

    .Wmdestroy:
        invoke DeleteObject, [ObjectsListWindow.hVisibilityCirclePen]
        invoke DeleteObject, [ObjectsListWindow.hVisibilityCircleWhiteBrush]
        invoke DeleteObject, [ObjectsListWindow.hVisibilityCircleFilledBrush]
        invoke DeleteObject, [ObjectsListWindow.hSeparatorPen]
        invoke DeleteObject, [ObjectsListWindow.hBackgroundBrush]

        jmp .Return_0


    .Return_0:
    xor eax, eax

    .Return:
    ret
endp


proc ObjectsListWindow._SetScroll, Value
    locals
        ScrollInfo SCROLLINFO ?
    endl

    mov ecx, [Value]
    cmp ecx, 0
    jge @F

    xor ecx, ecx
    jmp .WriteNewScroll

    @@:
    mov eax, [ObjectsListWindow.CurrentListHeight]
    sub eax, [ObjectsListWindow.Height]
    cmp ecx, eax
    jle .WriteNewScroll

    mov ecx, eax

    .WriteNewScroll:
    mov [ObjectsListWindow.CurrentScroll], ecx
    stdcall ObjectsListWindow.Redraw

    mov [ScrollInfo.cbSize], sizeof.SCROLLINFO
    mov [ScrollInfo.fMask], SIF_POS
    mov eax, [ObjectsListWindow.CurrentScroll]
    mov [ScrollInfo.nPos], eax
    lea edx, [ScrollInfo]
    invoke SetScrollInfo, [ObjectsListWindow.hWnd], SB_VERT, edx, TRUE

    ret
endp


proc ObjectsListWindow._SetScrollPageAndRange
    locals
        ScrollInfo SCROLLINFO ?
    endl

    mov [ScrollInfo.cbSize], sizeof.SCROLLINFO
    mov [ScrollInfo.fMask], SIF_RANGE or SIF_PAGE or SIF_POS
    mov [ScrollInfo.nMin], 0
    mov eax, [ObjectsListWindow.Height]
    mov [ScrollInfo.nPage], eax
    mov eax, [ObjectsListWindow.CurrentListHeight]
    mov [ScrollInfo.nMax], eax

    mov edx, [ObjectsListWindow.CurrentListHeight]
    sub edx, [ObjectsListWindow.Height]

    mov ecx, [ObjectsListWindow.CurrentScroll]
    cmp ecx, edx
    jbe @F

    mov ecx, edx

    @@:
    mov [ScrollInfo.nPos], ecx
    mov [ObjectsListWindow.CurrentScroll], ecx

    lea eax, [ScrollInfo]
    invoke SetScrollInfo, [ObjectsListWindow.hWnd], SB_VERT, eax, TRUE

    ret
endp


proc ObjectsListWindow._GetIndexByYPosition, YPos
    xor edx, edx
    mov eax, [YPos]
    add eax, [ObjectsListWindow.CurrentScroll]
    mov ecx, ObjectsListWindow.ListItemHeight
    div ecx

    mov edx, [Points.Length]
    add edx, [Objects.Sizes.Length]
    sub edx, 1
    cmp edx, eax
    jge .Return

    mov eax, -1

    .Return:
    ret
endp


; Returns pointer to object
proc ObjectsListWindow._GetObjectByIndex uses ebx, Index
    mov eax, [Index]

    cmp eax, [Points.Length]
    jae @F

    imul eax, eax, sizeof.Point
    add eax, [Points.Ptr]
    jmp .Return

    @@:
    sub eax, [Points.Length]
    mov ebx, Objects
    stdcall HeterogenousVector.PtrByIndex, eax

    .Return:
    ret
endp


proc ObjectsListWindow._ToggleHideObject, Index
    stdcall ObjectsListWindow._GetObjectByIndex, [Index]
    xor byte [eax + GeometryObject.IsHidden], 1

    ret
endp


proc ObjectsListWindow._DrawListItem uses ebx, hDC, pObject
    locals
        StrBuffer db 256 dup(?)
        CurrentHeightMinusScroll dd ?
    endl

    mov eax, [ObjectsListWindow.CurrentListHeight]
    sub eax, [ObjectsListWindow.CurrentScroll]
    mov [CurrentHeightMinusScroll], eax

    invoke SelectObject, [hDC], [ObjectsListWindow.hVisibilityCirclePen]

    mov ebx, [pObject]

    cmp byte [ebx + GeometryObject.IsHidden], 0
    je .ObjectVisible

    invoke SelectObject, [hDC], [ObjectsListWindow.hVisibilityCircleWhiteBrush]
    jmp @F

    .ObjectVisible:
    invoke SelectObject, [hDC], [ObjectsListWindow.hVisibilityCircleFilledBrush]

    @@:
    mov edx, [CurrentHeightMinusScroll]
    add edx, ObjectsListWindow.ListItemPadding
    mov eax, edx
    add eax, ObjectsListWindow.VisibilityCircleRadius * 2
    invoke Ellipse, [hDC], ObjectsListWindow.ListItemMarginLeft, edx, \
                    ObjectsListWindow.ListItemMarginLeft + ObjectsListWindow.VisibilityCircleRadius * 2, eax

    lea eax, [StrBuffer]
    stdcall GeometryObject.ToString, eax
    lea edx, [StrBuffer]
    mov ecx, [CurrentHeightMinusScroll]
    add ecx, ObjectsListWindow.ListItemPadding
    invoke TextOutW, [hDC], ObjectsListWindow.VisibilityCircleSeparatorXOffset + ObjectsListWindow.TextMarginLeft, ecx, edx, eax

    invoke SelectObject, [hDC], [ObjectsListWindow.hSeparatorPen]

    invoke MoveToEx, [hDC], ObjectsListWindow.VisibilityCircleSeparatorXOffset, [CurrentHeightMinusScroll], NULL
    add [ObjectsListWindow.CurrentListHeight], ObjectsListWindow.ListItemHeight
    add [CurrentHeightMinusScroll], ObjectsListWindow.ListItemHeight
    invoke LineTo, [hDC],  ObjectsListWindow.VisibilityCircleSeparatorXOffset, [CurrentHeightMinusScroll]

    invoke MoveToEx, [hDC], 0, [CurrentHeightMinusScroll], NULL
    invoke LineTo, [hDC], [ObjectsListWindow.Width], [CurrentHeightMinusScroll]

    ret
endp


proc ObjectsListWindow._DrawObjectsList uses ebx esi, hDC
    mov [ObjectsListWindow.CurrentListHeight], 0

    mov ecx, [Points.Length]
    test ecx, ecx
    jz @F

    mov ebx, [Points.Ptr]
    .DrawPointsListLoop:
        push ecx
        stdcall ObjectsListWindow._DrawListItem, [hDC], ebx
        pop ecx

        add ebx, sizeof.Point
        loop .DrawPointsListLoop

    @@:
    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .Return

    mov esi, [Objects.Sizes.Ptr]
    mov ebx, [Objects.Ptr]
    .DrawListLoop:
        push ecx
        stdcall ObjectsListWindow._DrawListItem, [hDC], ebx
        pop ecx

        add ebx, [esi]
        add esi, HeterogenousVector.BytesForElementSize
        loop .DrawListLoop

    .Return:
    ret
endp


proc ObjectsListWindow._Clear, hDC
    invoke GetStockObject, NULL_PEN
    invoke SelectObject, [hDC], eax
    invoke SelectObject, [hDC], [ObjectsListWindow.hBackgroundBrush]
    invoke Rectangle, [hDC], 0, 0, [ObjectsListWindow.Width], [ObjectsListWindow.Height]

    .Return:
    ret
endp


proc ObjectsListWindow._Paint uses esi, hDC
    mov esi, eax
    invoke SetBkMode, esi, TRANSPARENT
    stdcall ObjectsListWindow._Clear, esi
    stdcall ObjectsListWindow._DrawObjectsList, esi

    mov eax, [ObjectsListWindow.Height]
    cmp eax, [ObjectsListWindow.CurrentListHeight]
    jae .DisableScrollBar

    stdcall ObjectsListWindow._SetScrollPageAndRange
    invoke ShowScrollBar, [ObjectsListWindow.hWnd], SB_VERT, TRUE

    jmp .Return

    .DisableScrollBar:
    invoke ShowScrollBar, [ObjectsListWindow.hWnd], SB_VERT, FALSE

    .Return:
    ret
endp


proc ObjectsListWindow.Redraw
    mov byte [ObjectsListWindow.NeedsRedraw], 0
    invoke InvalidateRect, [ObjectsListWindow.hWnd], NULL, FALSE
    ret
endp


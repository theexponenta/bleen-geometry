
proc PlotEquationInputWindow.WindowProc uses ebx esi edi, hWnd, wmsg, wparam, lparam
    mov eax, [wmsg]

    cmp eax, WM_COMMAND
    je .Wmcommand
    cmp eax, WM_KEYDOWN
    je .Wmkeydown

    invoke DefWindowProc, [hWnd], [wmsg], [wparam], [lparam]
    jmp .Return

    .Wmkeydown:
        cmp [wparam], VK_RETURN
        jne .Return_0

        stdcall PlotEquationInputWindow.Submit

        jmp .Return_0

    .Wmcommand:
        cmp word [wparam], PlotEquationInputWindow.OkButton.hMenu
        jne @F

        stdcall PlotEquationInputWindow.Submit
        jmp .Return_0

        @@:
        cmp word [wparam + 2], CBN_SELCHANGE
        jne .Return_0

        xor eax, eax
        invoke SendMessage, [lparam], CB_GETCURSEL, eax, eax
        inc eax
        stdcall PlotEquationInputWindow._ChangePlotType, eax

        jmp .Return_0

    .Return_0:
    xor eax, eax

    .Return:
    ret
endp


proc PlotEquationInputWindow.ForwardWmKeydownSubclassProc hWnd, wmsg, wparam, lparam, uIdSubclass, dwRefData
    mov eax, [wmsg]

    cmp eax, WM_KEYDOWN
    jne @F

    invoke GetParent, [hWnd]
    invoke SendMessage, eax, [wmsg], [wparam], [lparam]

    @@:
    invoke DefSubclassProc, [hWnd], [wmsg], [wparam], [lparam]

    ret
endp


proc PlotEquationInputWindow._DestroyChildWindowEnumProc, hWnd, lParam
    invoke DestroyWindow, [hWnd]
    ret
endp


proc PlotEquationInputWindow._IncreaseYOffset, hWnd, MarginBottom
    stdcall WinAPIUtils.GetWindowHeight, [hWnd]
    add eax, [PlotEquationInputWindow.CurrentYOffset]
    add eax, [MarginBottom]
    mov [PlotEquationInputWindow.CurrentYOffset], eax
    ret
endp


proc PlotEquationInputWindow._AddStaticControl, hwnd, pText
    locals
        Size SIZE ?
    endl

    lea edx, [Size]
    stdcall WinAPIUtils.GetTextSize, [hwnd], [pText], edx

    invoke CreateWindowEx, 0, STATICCLASSNAME, [pText], WS_VISIBLE or WS_CHILD, \
                           PlotEquationInputWindow.Padding, [PlotEquationInputWindow.CurrentYOffset], \
                           [Size.cx], [Size.cy], [hwnd], NULL, [hInstance], NULL

    stdcall PlotEquationInputWindow._IncreaseYOffset, eax, PlotEquationInputWindow.StaticMarginBottom

    ret
endp


proc PlotEquationInputWindow._AddPlotTypeComboBox, hWndParent, SelectedPlotType
    stdcall PlotEquationInputWindow._AddStaticControl, [hWndParent], PlotEquationInputWindow.PlotType

    invoke CreateWindowExW, 0, COMBOBOXCLASSNAME, NULL, WS_VISIBLE or WS_CHILD or CBS_DROPDOWNLIST, \
                            PlotEquationInputWindow.Padding, [PlotEquationInputWindow.CurrentYOffset], \
                            PlotEquationInputWindow.ComboBoxWidth, PlotEquationInputWindow.ComboBoxHeight, \
                            [hWndParent], NULL, [hInstance], NULL

    mov [PlotEquationInputWindow.PlotTypeComboBox], eax

    invoke SendMessage, [PlotEquationInputWindow.PlotTypeComboBox], CB_ADDSTRING, 0, PlotEquationInputWindow.PlotType.Regular
    invoke SendMessage, [PlotEquationInputWindow.PlotTypeComboBox], CB_ADDSTRING, 0, PlotEquationInputWindow.PlotType.Parametric

    mov eax, [SelectedPlotType]
    dec eax
    invoke SendMessage, [PlotEquationInputWindow.PlotTypeComboBox], CB_SETCURSEL, eax, 0

    stdcall PlotEquationInputWindow._IncreaseYOffset, [PlotEquationInputWindow.PlotTypeComboBox], PlotEquationInputWindow.DefaultMarginBottom

    ret
endp


proc PlotEquationInputWindow._AddInput, hWndParent, pCaption, AutoWidth, Width
    locals
        TextSize SIZE ?
        InputHwnd dd ?
    endl

    lea edx, [TextSize]
    stdcall WinAPIUtils.GetTextSize, [hWndParent], [pCaption], edx

    invoke CreateWindowEx, 0, STATICCLASSNAME, [pCaption], WS_VISIBLE or WS_CHILD, \
                           PlotEquationInputWindow.Padding, [PlotEquationInputWindow.CurrentYOffset], \
                           [TextSize.cx], [TextSize.cy], [hWndParent], NULL, [hInstance], NULL

    mov eax, PlotEquationInputWindow.Padding + PlotEquationInputWindow.StaticMarginRight
    add eax, [TextSize.cx]

    mov edx, [Width]
    cmp [AutoWidth], 0
    je @F

    mov edx, PlotEquationInputWindow.Width - PlotEquationInputWindow.Padding * 2 - PlotEquationInputWindow.StaticMarginRight
    sub edx, [TextSize.cx]

    @@:
    invoke CreateWindowEx, 0, EDITCLASSNAME, NULL, WS_VISIBLE or WS_CHILD or WS_BORDER or ES_AUTOHSCROLL, \
                           eax, [PlotEquationInputWindow.CurrentYOffset], \
                           edx, PlotEquationInputWindow.InputHeight, [hWndParent], NULL, [hInstance], NULL
    mov [InputHwnd], eax

    invoke SetWindowSubclass, eax, PlotEquationInputWindow.ForwardWmKeydownSubclassProc, 1, eax

    stdcall PlotEquationInputWindow._IncreaseYOffset, [InputHwnd], PlotEquationInputWindow.DefaultMarginBottom

    mov eax, [InputHwnd]

    ret
endp


proc PlotEquationInputWindow.AddControls, hWndParent, PlotType

    stdcall PlotEquationInputWindow._AddPlotTypeComboBox, [hWndParent], [PlotType]

    cmp [PlotType], Plot.Type.Regular
    jne .Parametric

    stdcall PlotEquationInputWindow._AddInput, [hWndParent], PlotEquationInputWindow.yEquals, TRUE, eax
    mov [PlotEquationInputWindow.InputY.hWnd], eax
    invoke SetFocus, eax

    jmp @F

    .Parametric:
    stdcall PlotEquationInputWindow._AddInput, [hWndParent], PlotEquationInputWindow.xOftEquals, TRUE, eax
    mov [PlotEquationInputWindow.InputX.hWnd], eax
    invoke SetFocus, eax

    stdcall PlotEquationInputWindow._AddInput, [hWndParent], PlotEquationInputWindow.yOftEquals, TRUE, eax
    mov [PlotEquationInputWindow.InputY.hWnd], eax

    stdcall PlotEquationInputWindow._AddInput, [hWndParent], PlotEquationInputWindow.t_min, FALSE, PlotEquationInputWindow.tParameterInputWidth
    mov [PlotEquationInputWindow.InputTmin.hWnd], eax

    stdcall PlotEquationInputWindow._AddInput, [hWndParent], PlotEquationInputWindow.t_max, FALSE, PlotEquationInputWindow.tParameterInputWidth
    mov [PlotEquationInputWindow.InputTmax.hWnd], eax

    @@:

    invoke CreateWindowEx, 0, BUTTONCLASSNAME, PlotEquationInputWindow.Buttons.OK.Text, WS_VISIBLE or WS_CHILD, \
                           PlotEquationInputWindow.Width - PlotEquationInputWindow.Padding - PlotEquationInputWindow.OkButtonWidth, \
                           [PlotEquationInputWindow.CurrentYOffset], \
                           PlotEquationInputWindow.OkButtonWidth, PlotEquationInputWindow.OkButtonHeight, \
                           [hWndParent], PlotEquationInputWindow.OkButton.hMenu, [hInstance], NULL

    stdcall PlotEquationInputWindow._IncreaseYOffset, eax, PlotEquationInputWindow.DefaultMarginBottom
    add [PlotEquationInputWindow.CurrentYOffset], PlotEquationInputWindow.DefaultMarginBottom

    ret
endp


proc PlotEquationInputWindow._GetNumberFromEdit, hWndEdit
    locals
        Number dd ?
        TextLength dd ?
        BufferSize dd ?
    endl

    invoke GetWindowTextLengthW, [hWndEdit]
    test eax, eax
    jz .Return

    mov [TextLength], eax

    inc eax
    stdcall Math.AlignToStackSize, eax

    mov [BufferSize], eax
    sub esp, eax

    mov edx, esp
    invoke GetWindowTextA, [hWndEdit], edx, eax

    mov edx, esp
    stdcall MathParser.EvalConstantExpression, edx

    .Return:
    add esp, [BufferSize]
    ret
endp


proc PlotEquationInputWindow._GetPlotEquationFromEdit uses esi, hWndEdit
    locals
        pBuffer dd ?
    endl

    invoke GetWindowTextLengthW, [hWndEdit]
    add eax, 1
    mov esi, eax
    shl esi, 1
    invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, esi
    mov [pBuffer], eax
    invoke GetWindowTextA, [hWndEdit], eax, esi

    mov eax, [pBuffer]

    ret
endp


proc PlotEquationInputWindow.Submit uses esi edi
    locals
        pXBuffer dd 0
        pYBuffer dd 0
        TextLength dd ?
        Tmin dd ?
        Tmax dd ?
        PlotType dd ?
    endl

    xor eax, eax
    invoke SendMessage, [PlotEquationInputWindow.PlotTypeComboBox], CB_GETCURSEL, eax, eax
    inc eax

    mov [PlotType], eax
    cmp eax, Plot.Type.Parametric
    jne @F

    stdcall PlotEquationInputWindow._GetNumberFromEdit, [PlotEquationInputWindow.InputTmin.hWnd]
    mov esi, PlotEquationInputWindow.InvalidTmin
    test eax, eax
    jz .Error

    fstp [Tmin]

    stdcall PlotEquationInputWindow._GetNumberFromEdit, [PlotEquationInputWindow.InputTmax.hWnd]
    mov esi, PlotEquationInputWindow.InvalidTmax
    test edx, edx
    jz .Error

    fstp [Tmax]

    stdcall PlotEquationInputWindow._GetPlotEquationFromEdit, [PlotEquationInputWindow.InputX.hWnd]
    mov [pXBuffer], eax

    @@:
    stdcall PlotEquationInputWindow._GetPlotEquationFromEdit, [PlotEquationInputWindow.InputY.hWnd]
    mov [pYBuffer], eax

    stdcall Main.AddPlot, [PlotType], [pXBuffer], [pYBuffer], [Tmin], [Tmax]
    mov edi, eax

    invoke GetWindowTextLengthW, [PlotEquationInputWindow.InputY.hWnd]
    add eax, 1
    invoke GetWindowTextW, [PlotEquationInputWindow.InputY.hWnd], [pYBuffer], eax

    cmp [PlotType], Plot.Type.Parametric
    jne @F

    invoke GetWindowTextLengthW, [PlotEquationInputWindow.InputX.hWnd]
    add eax, 1
    invoke GetWindowTextW, [PlotEquationInputWindow.InputX.hWnd], [pXBuffer], eax

    @@:
    mov esi, PlotEquationInputWindow.InvalidExpression
    test edi, edi
    jz .Error

    stdcall DrawArea.Redraw
    stdcall ObjectsListWindow.Redraw
    invoke DestroyWindow, [PlotEquationInputWindow.hWnd]
    jmp .Return

    .Error:
    cmp [pXBuffer], 0
    je @F

    invoke HeapFree, [hProcessHeap], 0, [pXBuffer]

    @@:
    cmp [pYBuffer], 0
    je @F

    invoke HeapFree, [hProcessHeap], 0, [pYBuffer]

    @@:
    invoke MessageBox, [PlotEquationInputWindow.hWnd], esi, PlotEquationInputWindow.Error, MB_OK or MB_ICONERROR
    invoke SetFocus, [PlotEquationInputWindow.InputY.hWnd]

    .Return:
    ret
endp


proc PlotEquationInputWindow._ChangePlotType, PlotType
    invoke EnumChildWindows, [PlotEquationInputWindow.hWnd], PlotEquationInputWindow._DestroyChildWindowEnumProc, eax

    mov [PlotEquationInputWindow.CurrentYOffset], PlotEquationInputWindow.Padding
    stdcall PlotEquationInputWindow.AddControls, [PlotEquationInputWindow.hWnd], [PlotType]

    mov eax, [PlotEquationInputWindow.hWnd]
    invoke SetWindowPos, eax, eax, eax, eax, PlotEquationInputWindow.Width, [PlotEquationInputWindow.CurrentYOffset], \
                         SWP_NOZORDER or SWP_NOMOVE or SWP_SHOWWINDOW

    ret
endp


proc PlotEquationInputWindow.Show
    locals
        WorkArea RECT ?
    endl

    invoke CreateWindowEx, 0, PlotEquationInputWindow.wcexClass.ClassName, PlotEquationInputWindow.Title, \
                           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_POPUP, 0, 0, 0, 0, \
                           [MainWindow.hwnd], NULL, [hInstance], NULL

    mov [PlotEquationInputWindow.hWnd], eax

    stdcall PlotEquationInputWindow._ChangePlotType, Plot.Type.Regular

    lea eax, [WorkArea]
    invoke SystemParametersInfoA, SPI_GETWORKAREA, 0, eax, 0

    mov edx, [WorkArea.bottom]
    sub edx, [PlotEquationInputWindow.CurrentYOffset]
    shr edx, 1

    mov ecx, [WorkArea.right]
    shr ecx, 1
    sub ecx, PlotEquationInputWindow.Width / 2

    invoke SetWindowPos, [PlotEquationInputWindow.hWnd], eax, ecx, edx, eax, eax, SWP_NOZORDER or SWP_NOSIZE or SWP_SHOWWINDOW

    ret
endp
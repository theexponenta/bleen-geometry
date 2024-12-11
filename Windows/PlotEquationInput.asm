
proc PlotEquationInputWindow.WindowProc uses ebx esi edi, hWnd, wmsg, wparam, lparam
    locals
        pEquationBuffer dd ?
    endl

    mov eax, [wmsg]

    cmp eax, WM_CREATE
    je .Wmcreate
    cmp eax, WM_COMMAND
    je .Wmcommand

    invoke DefWindowProc, [hWnd], [wmsg], [wparam], [lparam]
    jmp .Return

    .Wmcreate:
        stdcall PlotEquationInputWindow.AddControls, [hWnd]
        jmp .Return_0

    .Wmcommand:
        cmp [wparam], PlotEquationInputWindow.OkButton.hMenu
        jne .Return_0

        invoke GetWindowTextLengthW, [PlotEquationInputWindow.Input.hWnd]
        add eax, 1
        mov esi, eax
        invoke HeapAlloc, [hProcessHeap], HEAP_ZERO_MEMORY, eax
        mov [pEquationBuffer], eax
        invoke GetWindowTextA, [PlotEquationInputWindow.Input.hWnd], eax, esi

        stdcall Main.AddPlot, Plot.Type.Regular, [pEquationBuffer]
        mov edi, eax
        invoke GetWindowTextW, [PlotEquationInputWindow.Input.hWnd], [pEquationBuffer], esi

        test edi, edi
        jz @F

        stdcall DrawArea.Redraw
        stdcall ObjectsListWindow.Redraw
        invoke DestroyWindow, [hWnd]
        jmp .Return_0

        @@:
        invoke HeapFree, [hProcessHeap], [pEquationBuffer]

        jmp .Return_0

    .Return_0:
    xor eax, eax

    .Return:
    ret
endp


proc PlotEquationInputWindow.AddControls, hWndParent

    invoke CreateWindowEx, 0, EDITCLASSNAME, NULL, WS_VISIBLE or WS_CHILD or WS_BORDER, \
                           PlotEquationInputWindow.Padding, PlotEquationInputWindow.Padding, \
                           PlotEquationInputWindow.Width - PlotEquationInputWindow.Padding * 2 , \
                           PlotEquationInputWindow.InputHeight, [hWndParent], NULL, [hInstance], NULL

    mov [PlotEquationInputWindow.Input.hWnd], eax

    invoke CreateWindowEx, 0, BUTTONCLASSNAME, PlotEquationInputWindow.Buttons.OK.Text, WS_VISIBLE or WS_CHILD, \
                           PlotEquationInputWindow.Width - PlotEquationInputWindow.Padding - PlotEquationInputWindow.OkButtonWidth, \
                           PlotEquationInputWindow.Padding + PlotEquationInputWindow.InputHeight + PlotEquationInputWindow.InputMarginBottom, \
                           PlotEquationInputWindow.OkButtonWidth, PlotEquationInputWindow.OkButtonHeight, \
                           [hWndParent], PlotEquationInputWindow.OkButton.hMenu, [hInstance], NULL

    ret
endp


proc PlotEquationInputWindow.Show, pPlotObj
    locals
        WorkArea RECT ?
    endl

    mov eax, [pPlotObj]
    mov [PlotEquationInputWindow.pPlotObj], eax

    invoke CreateWindowEx, 0, PlotEquationInputWindow.wcexClass.ClassName, PlotEquationInputWindow.Title, \
                           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_POPUP, 0, 0, 0, 0, \
                           [MainWindow.hwnd], NULL, [hInstance], NULL

    mov [PlotEquationInputWindow.hWnd], eax

    lea eax, [WorkArea]
    invoke SystemParametersInfoA, SPI_GETWORKAREA, 0, eax, 0

    mov edx, [WorkArea.bottom]
    shr edx, 1
    sub edx, PlotEquationInputWindow.Height / 2

    mov ecx, [WorkArea.right]
    shr ecx, 1
    sub ecx, PlotEquationInputWindow.Width / 2

    mov eax, [PlotEquationInputWindow.hWnd]
    invoke SetWindowPos, eax, eax, ecx, edx, PlotEquationInputWindow.Width, PlotEquationInputWindow.Height, SWP_NOZORDER or SWP_SHOWWINDOW

    ret
endp
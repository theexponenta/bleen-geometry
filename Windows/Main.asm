
proc MainWindow.WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
    locals
        ClientRect RECT ?
    endl

    mov eax, [wmsg]

    cmp eax, WM_MOUSEMOVE
    je .Wmmousemove
    cmp eax, WM_SIZE
    je .Wmsize
    cmp eax, WM_LBUTTONDOWN
    je .Wmlbuttondown
    cmp eax, WM_LBUTTONUP
    je .Wmlbuttonup
    cmp eax, WM_COMMAND
    je .Wmcommand
    cmp eax, WM_KEYDOWN
    je .Wmkeydown
    cmp eax, WM_KEYUP
    je .Wmkeyup
    cmp eax, WM_DESTROY
    je .Wmdestroy
    cmp eax, WM_CREATE
    je .Wmcreate

    .Defwndproc:
        invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
        jmp .Return

    .Wmcreate:
        stdcall MainWindow.CreateToolbar, [hwnd]
        jmp .Return_0

    .Wmcommand:
        movzx eax, word [wparam]
        cmp eax, TOOL_PLOT
        jne @F

        stdcall PlotEquationInputWindow.Show
        jmp .Return_0

        @@:
        mov [CurrentToolId], eax
        mov [CurrentStateId], 1
        stdcall Main.UnselectObjects
        jmp .Return_0

    .Wmkeydown:
        cmp [wparam], VK_CONTROL
        jne @F

        mov [CtrlKeyPressed], 1

        @@:
        invoke PostMessage, [DrawArea.hwnd], [wmsg], [wparam], [lparam]
        jmp .Return_0

    .Wmkeyup:
        mov [CtrlKeyPressed], 0
        jmp .Return_0

    .Wmmousemove:
        movzx esi, word [lparam]

        cmp byte [MainWindow.IsResizing], 0
        je @F

        lea edx, [ClientRect]
        invoke GetClientRect, [hwnd], edx
        mov eax, [ClientRect.bottom]
        sub eax, [ClientRect.top]
        sub eax, MainWindow.ToolbarHeight

        mov edx, esi
        sub edx, MainWindow.SplitterBarWidth
        invoke SetWindowPos, [ObjectsListWindow.hWnd], HWND_BOTTOM, ebx, ebx, edx, eax, \
                             SWP_NOMOVE or SWP_NOREPOSITION or SWP_NOZORDER

        mov eax, esi
        add eax, MainWindow.SplitterBarWidth
        invoke MoveWindow, [DrawArea.hwnd], eax, MainWindow.ToolbarHeight, [DrawArea.Width], [DrawArea.Height], TRUE
        jmp .Return_0

        @@:
        stdcall MainWindow._IsAboveSplitterBar, esi
        test eax, eax
        jz .Return_0

        invoke SetCursor, [MainWindow.hSplitterCursor]

        jmp .Return_0

    .Wmlbuttondown:
        movzx eax, word [lparam]
        stdcall MainWindow._IsAboveSplitterBar, eax
        test eax, eax
        jz .Return_0

        invoke SetCursor, [MainWindow.hSplitterCursor]
        mov byte [MainWindow.IsResizing], 1
        invoke SetCapture, [hwnd]

        jmp .Return_0

    .Wmlbuttonup:
        invoke ReleaseCapture
        mov byte [MainWindow.IsResizing], 0
        jmp .Return_0

    .Wmsize:
        invoke SendMessage, [MainWindow.Toolbar.hwnd], WM_SIZE, 0, 0

        lea edx, [ClientRect]
        invoke GetClientRect, [hwnd], edx
        mov eax, [ClientRect.bottom]
        sub eax, [ClientRect.top]
        sub eax, MainWindow.ToolbarHeight
        invoke SetWindowPos, [ObjectsListWindow.hWnd], HWND_BOTTOM, ebx, ebx, [ObjectsListWindow.Width], eax, \
                             SWP_NOMOVE or SWP_NOREPOSITION or SWP_NOZORDER
        jmp .Return_0

    .Wmdestroy:
        invoke PostQuitMessage,0

    .Return_0:
        xor eax, eax

    .Return:
        ret
endp


proc MainWindow._IsAboveSplitterBar, XPos
    xor eax, eax

    mov ecx, [XPos]
    mov edx, [ObjectsListWindow.Width]
    sub edx, MainWindow.SplitterBarWidth
    cmp ecx, edx
    jb .Return

    add edx, MainWindow.SplitterBarWidth * 2
    cmp ecx, edx
    ja .Return

    mov eax, 1

    .Return:
    ret
endp


proc MainWindow.CreateToolbar uses esi edi ebx, hwnd
     invoke ImageList_Create, MainWindow.Toolbar.BitmapSize, MainWindow.Toolbar.BitmapSize, ILC_COLOR16 or ILC_MASK, MainWindow.Toolbar.ButtonsCount, 0
     mov edi, eax

     mov ebx, MainWindow.Toolbar.Buttons
     xor ecx, ecx
     .AddImagesLoop:
         push ecx
         invoke LoadBitmap, [hInstance], [ebx + TBBUTTON.idCommand]
         invoke ImageList_Add, edi, eax, NULL
         pop ecx

         add ebx, sizeof.TBBUTTON
         inc ecx
         cmp ecx, MainWindow.Toolbar.ButtonsCount
         jb .AddImagesLoop

     invoke CreateWindowEx, 0, TOOLBARCLASSNAME, NULL, WS_CHILD or WS_VISIBLE or TBSTYLE_FLAT, \
                            0, 0, 0, 0, [hwnd], NULL, [hInstance], NULL
     mov [MainWindow.Toolbar.hwnd], eax
     mov esi, eax

     invoke SendMessage, esi, TB_SETIMAGELIST, 0, edi
     invoke SendMessage, esi, TB_BUTTONSTRUCTSIZE, sizeof.TBBUTTON, 0
     invoke SendMessage, esi, TB_ADDBUTTONS, MainWindow.Toolbar.ButtonsCount, MainWindow.Toolbar.Buttons

     ret
endp


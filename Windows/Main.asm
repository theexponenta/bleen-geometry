
proc MainWindow.WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
    mov eax, [wmsg]

    cmp eax, WM_DESTROY
    je .Wmdestroy
    cmp eax, WM_CREATE
    je .Wmcreate
    cmp eax, WM_COMMAND
    je .Wmcommand
    cmp eax, WM_KEYDOWN
    je .Wmkeydown
 
    .Defwndproc:
        invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
        jmp .Return

    .Wmcreate:
        invoke SystemParametersInfo, SPI_GETWORKAREA, NULL, WorkArea, 0

        mov eax, [WorkArea.right]
        sub eax, DrawArea.OffsetX
        mov [DrawArea.Width], eax
        mov eax, [WorkArea.bottom]
        mov [DrawArea.Height], eax
        invoke CreateWindowEx, 0, DrawArea.wcexClass.ClassName, NULL, WS_CHILD or WS_VISIBLE, DrawArea.OffsetX, DrawArea.OffsetY, \
                               [DrawArea.Width], [DrawArea.Height], [hwnd], NULL, [hInstance], NULL
        mov [DrawArea.hwnd], eax
        stdcall DrawArea.Clear, [DrawArea.MemDC]

        stdcall MainWindow.CreateToolbar, [hwnd]

        jmp .Return_0

    .Wmcommand:
        movzx eax, word [wparam]
        mov [CurrentToolId], eax
        mov [CurrentStateId], 1
        jmp .Return_0

    .Wmkeydown:
        invoke PostMessage, [DrawArea.hwnd], [wmsg], [wparam], [lparam]
        jmp .Return_0

    .Wmdestroy:
        invoke PostQuitMessage,0

    .Return_0:
        xor eax, eax

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

     invoke CreateWindowEx, 0, TOOLBARCLASSNAME, NULL, WS_CHILD or WS_VISIBLE, \
                            0, 0, 0, 0, [hwnd], NULL, [hInstance], NULL
     mov [MainWindow.Toolbar.hwnd], eax
     mov esi, eax

     invoke SendMessage, esi, TB_SETIMAGELIST, 0, edi
     invoke SendMessage, esi, TB_BUTTONSTRUCTSIZE, sizeof.TBBUTTON, 0
     invoke SendMessage, esi, TB_ADDBUTTONS, MainWindow.Toolbar.ButtonsCount, MainWindow.Toolbar.Buttons

     invoke SendMessage, esi, WM_SIZE, 0, 0

     ret
endp


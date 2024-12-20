
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

        test eax, MENU_BIT
        jz .NotAMenu

        xor eax, MENU_BIT
        sub eax, 1
        shl eax, 2
        add eax, MainWindow.MenuCommandProcedures
        call dword [eax]
        jmp .Return_0

        .NotAMenu:
        cmp eax, TOOL_PLOT
        jne @F

        stdcall PlotEquationInputWindow.Show
        jmp .Return_0

        @@:
        mov [CurrentToolId], eax
        mov [CurrentStateId], 1
        stdcall Main.UnselectObjects
        stdcall Main.ClearTempHistory
        jmp .Return_0

    .Wmkeydown:
        invoke GetKeyState, VK_CONTROL
        test eax, 0x8000
        jz .PostToDrawArea

        mov [CtrlKeyPressed], 1
        mov eax, [wparam]

        cmp eax, 'S'
        jne .CheckOpen

        cmp [FileOpened], 0
        je .SaveAs

        stdcall MainWindow.Save
        jmp .PostToDrawArea

        .SaveAs:
        stdcall MainWindow.SaveAs
        jmp .PostToDrawArea

        .CheckOpen:
        cmp eax, 'O'
        jne .CheckUndo

        stdcall MainWindow.OpenFile
        jmp .PostToDrawArea

        .CheckUndo:
        cmp eax, 'Z'
        jne .PostToDrawArea

        stdcall Main.UndoMainHistory
        stdcall DrawArea.Redraw
        stdcall ObjectsListWindow.Redraw

        .PostToDrawArea:
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


proc MainWindow._FillOPENFILENAMEStructure, pOfn, pFilename
    mov eax, [pOfn]
    invoke RtlZeroMemory, eax, sizeof.OPENFILENAME

    mov edx, [pOfn]
    mov [edx + OPENFILENAME.lStructSize], sizeof.OPENFILENAME
    mov eax, [MainWindow.hwnd]
    mov [edx + OPENFILENAME.hwndOwner], eax
    mov eax, [pFilename]
    mov [edx + OPENFILENAME.lpstrFile], eax
    mov [edx + OPENFILENAME.nMaxFile], MAX_FILENAME_LENGTH

    ret
endp


proc MainWindow.SaveAs
    locals
        Ofn OPENFILENAME ?
        Filename du MAX_FILENAME_LENGTH dup(?)
    endl

    lea eax, [Ofn]
    lea edx, [Filename]
    stdcall MainWindow._FillOPENFILENAMEStructure, eax, edx

    mov word [Filename], 0

    lea eax, [Ofn]
    invoke GetSaveFileNameW, eax
    test eax, eax
    jz .Return

    lea eax, [Filename]
    stdcall FileWriter.Save, eax, Points, Objects, [NextPointNum], [NextObjectId], [Translate.x], [Translate.y], [Scale]

    lea eax, [Filename]
    stdcall Main.SetOpenedFile, eax

    .Return:
    ret
endp


proc MainWindow.Save
    cmp [FileOpened], 0
    je .Return

    stdcall FileWriter.Save, OpenFileName, Points, Objects, [NextPointNum], [NextObjectId], [Translate.x], [Translate.y], [Scale]

    .Return:
    ret
endp


proc MainWindow.OpenFile
    locals
        Ofn OPENFILENAME ?
        Filename du MAX_FILENAME_LENGTH dup(?)
    endl

    lea eax, [Ofn]
    lea edx, [Filename]
    stdcall MainWindow._FillOPENFILENAMEStructure, eax, edx

    mov word [Filename], 0

    lea eax, [Ofn]
    invoke GetOpenFileNameW, eax
    test eax, eax
    jz .Return

    stdcall Main.DestroyAll

    lea eax, [Filename]
    stdcall FileReader.Read, eax, Points, Objects, NextPointNum, NextObjectId, Translate.x, Translate.y, Scale

    lea eax, [Filename]
    stdcall Main.SetOpenedFile, eax

    stdcall DrawArea.Redraw
    stdcall ObjectsListWindow.Redraw

    .Return:
    ret
endp

proc MainWindow.Exit
    invoke DestroyWindow, [MainWindow.hwnd]
    ret
endp
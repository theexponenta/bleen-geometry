

proc ObjectSettingsWindow.WindowProc uses ebx esi edi, hWnd, wmsg, wparam, lparam
    mov eax, [wmsg]

    cmp eax, WM_CREATE
    je .Wmcreate
    cmp eax, WM_HSCROLL
    je .Wmhscroll
    cmp eax , WM_COMMAND
    je .Wmcommand
    cmp eax, WM_CLOSE
    je .Wmclose

    invoke DefWindowProc, [hWnd], [wmsg], [wparam], [lparam]
    jmp .Return

    .Wmcreate:
        invoke EnableWindow, [MainWindow.hwnd], FALSE
        jmp .Return_0

    .Wmhscroll:
        stdcall ObjectSettingsWindow._UpdateTrackbarValueStaticControl, [lparam]
        jmp .Return_0

    .Wmcommand:
        mov eax, [wparam]
        cmp eax, ObjectSettingsWindow.Buttons.OK.hMenu
        jne .Return_0
        mov byte [ObjectsListWindow.NeedsRedraw], 1
        stdcall ObjectSettingsWindow._Submit
        invoke EnableWindow, [MainWindow.hwnd], TRUE
        stdcall DrawArea.Redraw
        stdcall ObjectsListWindow.Redraw
        invoke DestroyWindow, [hWnd]
        jmp .Return_0

    .Wmclose:
        invoke EnableWindow, [MainWindow.hwnd], TRUE
        invoke DestroyWindow, [hWnd]
        jmp .Return_0

    .Return_0:
    xor eax, eax

    .Return:
    ret
endp


proc ObjectSettingsWindow.ColorPickerWindowProc uses ebx esi edi, hWnd, wmsg, wparam, lparam
    locals
        hBrush dd ?
        hDC dd ?
        PaintStruct PAINTSTRUCT ?
        WindowRect RECT ?
        ChooseColorStruct CHOOSECOLOR ?
    endl

    mov eax, [wmsg]

    cmp eax, WM_PAINT
    je .Wmpaint
    cmp eax, WM_LBUTTONUP
    je .Wmlbuttonup

    invoke DefWindowProc, [hWnd], [wmsg], [wparam], [lparam]
    jmp .Return

    .Wmpaint:
        lea eax, [WindowRect]
        invoke GetWindowRect, [hWnd], eax

        lea eax, [PaintStruct]
        invoke BeginPaint, [hWnd], eax
        mov [hDC], eax

        invoke CreateSolidBrush, [ObjectSettingsWindow.ChosenColor]
        lea edx, [PaintStruct]
        invoke SelectObject, [hDC], eax

        mov eax, [WindowRect.right]
        sub eax, [WindowRect.left]
        mov edx, [WindowRect.bottom]
        sub edx, [WindowRect.top]

        invoke Rectangle, [hDC], 0, 0, eax, edx
        lea eax, [PaintStruct]
        invoke EndPaint, [hWnd], eax

        invoke DeleteObject, [hBrush]

        jmp .Return_0

    .Wmlbuttonup:
        mov [ChooseColorStruct.lStructSize], sizeof.CHOOSECOLOR
        mov eax, [hWnd]
        mov [ChooseColorStruct.hwndOwner], eax
        mov eax, [hInstance]
        mov [ChooseColorStruct.hInstance], eax
        mov [ChooseColorStruct.lpCustColors], ObjectSettingsWindow.CustColors
        mov eax, [ObjectSettingsWindow.ChosenColor]
        mov [ChooseColorStruct.rgbResult], eax
        mov [ChooseColorStruct.Flags], CC_FULLOPEN or CC_RGBINIT

        lea eax, [ChooseColorStruct]
        invoke ChooseColorW, eax
        mov eax, [ChooseColorStruct.rgbResult]
        mov [ObjectSettingsWindow.ChosenColor], eax
        invoke InvalidateRect, [hWnd], NULL, FALSE
        jmp .Return_0

    .Return_0:
    xor eax, eax

    .Return:
    ret
endp


proc ObjectSettingsWindow._GetWindowHeight, hwnd
    locals
        WindowRect RECT ?
    endl

    lea eax, [WindowRect]
    invoke GetWindowRect, [hwnd], eax
    mov eax, [WindowRect.bottom]
    sub eax, [WindowRect.top]

    ret
endp


proc ObjectSettingsWindow._IncreaseYOffset, hwnd, MarginBottom
    stdcall ObjectSettingsWindow._GetWindowHeight, [hwnd]
    add eax, [ObjectSettingsWindow.CurrentYOffset]
    add eax, [MarginBottom]
    mov [ObjectSettingsWindow.CurrentYOffset], eax
    ret
endp


proc ObjectSettingsWindow._AddFieldInputControl uses ebx, hWnd, Property, FieldOffset
    locals
        Control ObjectFieldInputControl ?
    endl

    mov eax, [hWnd]
    mov [Control.hWnd], eax

    mov eax, [Property]
    mov [Control.EditableProperty], eax

    mov eax, [FieldOffset]
    mov [Control.FieldOffset], eax

    mov ebx, ObjectSettingsWindow.Controls
    lea eax, [Control]
    stdcall Vector.Push, eax

    ret
endp


proc ObjectSettingsWindow._AddStaticControl, hwnd, pText
    locals
        hDC dd ?
        Size SIZE ?
    endl

    invoke GetDC, [hwnd]
    mov [hDC], eax

    invoke lstrlenW, [pText]
    lea edx, [Size]
    invoke GetTextExtentPoint32W, [hDC], [pText], eax, edx

    invoke CreateWindowEx, 0, STATICCLASSNAME, [pText], WS_VISIBLE or WS_CHILD, \
                           ObjectSettingsWindow.PaddingLeft, [ObjectSettingsWindow.CurrentYOffset], \
                           [Size.cx], [Size.cy], [hwnd], NULL, [hInstance], NULL

    stdcall ObjectSettingsWindow._IncreaseYOffset, eax, ObjectSettingsWindow.StaticControlMarginBottom

    ret
endp


proc ObjectSettingsWindow._AddEditControl, hwnd, Property, FieldOffset, pText
    locals
        ControlHwnd dd ?
    endl

    invoke CreateWindowEx, 0, EDITCLASSNAME, [pText], WS_VISIBLE or WS_CHILD or WS_BORDER, \
                           ObjectSettingsWindow.PaddingLeft, [ObjectSettingsWindow.CurrentYOffset], ObjectSettingsWindow.EditControl.Width, \
                           ObjectSettingsWindow.EditControl.Height, [hwnd], NULL, [hInstance], NULL
    mov [ControlHwnd], eax

    stdcall ObjectSettingsWindow._IncreaseYOffset, eax, ObjectSettingsWindow.OtherControlMarginBottom
    stdcall ObjectSettingsWindow._AddFieldInputControl, [ControlHwnd], [Property], [FieldOffset]

    ret
endp


proc ObjectSettingsWindow._FindTrackbarValueStaticControl uses esi, hWndTrackbar
    mov ecx, [ObjectSettingsWindow.TrackbarsValueControls.Length]
    test ecx, ecx
    jz .Return

    mov esi, [ObjectSettingsWindow.TrackbarsValueControls.Ptr]
    .FindLoop:
        mov eax, [esi + TrackbarValueControl.hWndTrackbar]
        cmp eax, [hWndTrackbar]
        mov eax, [esi + TrackbarValueControl.hWndStatic]
        je .Return

        add esi, sizeof.TrackbarValueControl
        loop .FindLoop

    xor eax, eax

    .Return:
    ret
endp


proc ObjectSettingsWindow._UpdateTrackbarValueStaticControl, hWndTrackbar
    locals
        Buffer db 10 dup(?)
        hDCStatic dd ?
        Size SIZE ?
        hWndStatic dd ?
    endl

    stdcall ObjectSettingsWindow._FindTrackbarValueStaticControl, [hWndTrackbar]
    test eax, eax
    jz .Return

    mov [hWndStatic], eax

    invoke SendMessage, [hWndTrackbar], TBM_GETPOS, ebx, ebx
    lea edx, [Buffer]
    stdcall Math.IntToStr, edx

    invoke GetDC, [hWndStatic]
    mov [hDCStatic], eax

    lea eax, [Buffer]
    invoke lstrlenA, eax
    lea edx, [Size]
    lea ecx, [Buffer]
    invoke GetTextExtentPoint32A, [hDCStatic], ecx, eax, edx

    mov eax, [Size.cy]
    shl eax, 16
    or eax, [Size.cx]
    invoke SendMessage, [hWndStatic], WM_SIZE, SIZE_RESTORED, eax

    lea eax, [Buffer]
    invoke SetWindowTextA, [hWndStatic], eax

    invoke ReleaseDC, [hDCStatic]

    .Return:
    ret
endp


proc ObjectSettingsWindow._AddTrackbarValueStaticControl uses ebx, hWndParent, hWndTrackbar
    locals
        TrackbarValue TrackbarValueControl ?
    endl

    mov eax, [hWndTrackbar]
    mov [TrackbarValue.hWndTrackbar], eax

    invoke CreateWindowEx, 0, STATICCLASSNAME, NULL, WS_VISIBLE or WS_CHILD, \
                           ObjectSettingsWindow.PaddingLeft + ObjectSettings.TrackbarWidth + ObjectSettingsWindow.TrackbarValueStaticOffset, \
                           [ObjectSettingsWindow.CurrentYOffset], ObjectSettingsWindow.TrackbarValueStaticControlWidth, \
                           ObjectSettingsWindow.TrackbarValueStaticControlHeight, [hWndParent], NULL, [hInstance], NULL

    mov [TrackbarValue.hWndStatic], eax
    mov ebx, ObjectSettingsWindow.TrackbarsValueControls
    lea eax, [TrackbarValue]
    stdcall Vector.Push, eax

    stdcall ObjectSettingsWindow._UpdateTrackbarValueStaticControl, [hWndTrackbar]

    ret
endp


proc ObjectSettingsWindow._AddTrackbarControl uses ebx, hWnd, Property, FieldOffset, InitialValue, MinValue, MaxValue
    locals
        hWndTrackbar dd ?
    endl

    invoke CreateWindowEx, 0, TRACKBARCLASSNAME, NULL, WS_VISIBLE or WS_CHILD or TBS_NOTICKS, \
                           ObjectSettingsWindow.PaddingLeft, [ObjectSettingsWindow.CurrentYOffset], \
                           ObjectSettings.TrackbarWidth, ObjectSettings.TrackbarHeight, [hWnd], NULL, [hInstance], NULL

    mov [hWndTrackbar], eax

    mov edx, [MaxValue]
    shl edx, 16
    or edx, [MinValue]
    invoke SendMessage, eax, TBM_SETRANGE, TRUE, edx

    invoke SendMessage, [hWndTrackbar], TBM_SETPOS, TRUE, [InitialValue]

    stdcall ObjectSettingsWindow._AddFieldInputControl, [hWndTrackbar], [Property], [FieldOffset]
    stdcall ObjectSettingsWindow._AddTrackbarValueStaticControl, [hWnd], [hWndTrackbar]
    stdcall ObjectSettingsWindow._IncreaseYOffset, [hWndTrackbar], ObjectSettingsWindow.OtherControlMarginBottom

    ret
endp


proc ObjectSettingsWindow._AddColorPickerControl, hWndParent, InitialColor
    locals
        hWndColorPicker dd ?
    endl

    invoke CreateWindowEx, 0, ObjectSettingsWindow.ColorPickerWndClassName, NULL, WS_VISIBLE or WS_CHILD, \
                           ObjectSettingsWindow.PaddingLeft, [ObjectSettingsWindow.CurrentYOffset], \
                           ObjectSettingsWindow.ColorPickerWidth, ObjectSettingsWindow.ColorPickerHeight, [hWndParent], NULL, [hInstance], NULL

    mov [hWndColorPicker], eax
    stdcall ObjectSettingsWindow._AddFieldInputControl, eax, PROP_COLOR, PROP_COLOR.Offset
    stdcall ObjectSettingsWindow._IncreaseYOffset, [hWndColorPicker], ObjectSettingsWindow.OtherControlMarginBottom

    mov eax, [InitialColor]
    mov [ObjectSettingsWindow.ChosenColor], eax

    ret
endp


proc ObjectSettingsWindow._AddVisibilityCheckbox, hWndParent, IsChecked
    locals
        hWndCheckbox dd ?
    endl

    invoke CreateWindowEx, 0, BUTTONCLASSNAME, ObjectSettingsWindow.VisibilityCheckboxText, BS_AUTOCHECKBOX or WS_VISIBLE or WS_CHILD, \
                           ObjectSettingsWindow.PaddingLeft, [ObjectSettingsWindow.CurrentYOffset], \
                           ObjectSettingsWindow.CheckboxWidth, ObjectSettingsWindow.CheckboxHeight, [hWndParent], NULL, [hInstance], NULL

    mov [hWndCheckbox], eax
    stdcall ObjectSettingsWindow._AddFieldInputControl, eax, PROP_VISIBLE, GeometryObject.IsHidden

    mov edx, BST_UNCHECKED
    cmp [IsChecked], 0
    je @F

    mov edx, BST_CHECKED

    @@:
    invoke SendMessage, [hWndCheckbox], BM_SETCHECK, edx, 0
    stdcall ObjectSettingsWindow._IncreaseYOffset, [hWndCheckbox], ObjectSettingsWindow.VisibilityCheckboxMarginBottom

    ret
endp


proc ObjectSettingsWindow._AddButtons, hWndParent
    invoke CreateWindowEx, 0, BUTTONCLASSNAME, ObjectSettingsWindow.Buttons.OK.Text, WS_VISIBLE or WS_CHILD, \
                           ObjectSettingsWindow.Width - ObjectSettingsWindow.DistanceBetweenButtons, \
                           [ObjectSettingsWindow.CurrentYOffset], ObjectSettingsWindow.ButtonWidth, ObjectSettingsWindow.ButtonHeight, \
                           [hWndParent], ObjectSettingsWindow.Buttons.OK.hMenu, [hInstance], NULL

    stdcall ObjectSettingsWindow._IncreaseYOffset, eax, ObjectSettingsWindow.OtherControlMarginBottom

    ret
endp


proc ObjectSettingsWindow._AddControls uses ebx, hWnd, EditableProperties
    mov eax, [ObjectSettingsWindow.pObject]
    movzx edx, byte [eax + GeometryObject.IsHidden]
    xor edx, 1
    stdcall ObjectSettingsWindow._AddVisibilityCheckbox, [hWnd], edx

    test [EditableProperties], PROP_NAME
    jz @F

    stdcall ObjectSettingsWindow._AddStaticControl, [hWnd], ObjectSettingsWindow.NameEditLabelText
    mov eax, [ObjectSettingsWindow.pObject]
    stdcall ObjectSettingsWindow._AddEditControl, [hWnd], PROP_NAME, PROP_NAME.Offset, [eax + PROP_NAME.Offset]

    @@:
    test [EditableProperties], PROP_CAPTION
    jz @F

    stdcall ObjectSettingsWindow._AddStaticControl, [hWnd], ObjectSettingsWindow.CaptionEditLabelText
    stdcall ObjectSettingsWindow._AddEditControl, [hWnd], PROP_CAPTION, PROP_CAPTION.Offset, NULL

    @@:
    test [EditableProperties], PROP_SIZE
    jz @F

    stdcall ObjectSettingsWindow._AddStaticControl, [hWnd], ObjectSettingsWindow.SizeTrackbarLabelText
    mov eax, [ObjectSettingsWindow.pObject]
    stdcall ObjectSettingsWindow._AddTrackbarControl, [hWnd], PROP_SIZE, PROP_SIZE.Offset, [eax + PROP_SIZE.Offset], \
                                                      PROP_SIZE.MinValue, PROP_SIZE.MaxValue

    @@:
    test [EditableProperties], PROP_COLOR
    jz @F

    stdcall ObjectSettingsWindow._AddStaticControl, [hWnd], ObjectSettingsWindow.ColorPickerLabelText
    mov eax, [ObjectSettingsWindow.pObject]
    stdcall ObjectSettingsWindow._AddColorPickerControl, [hWnd], [eax + PROP_COLOR.Offset]

    @@:
    stdcall ObjectSettingsWindow._AddButtons, [hWnd]

    ret
endp

proc ObjectSettingsWindow._Submit uses esi ebx
    locals
        StringBuffer db 72 dup(?)
    endl

    mov ecx, [ObjectSettingsWindow.Controls.Length]
    test ecx, ecx
    jz .Return

    mov esi, [ObjectSettingsWindow.Controls.Ptr]
    mov ebx, [ObjectSettingsWindow.pObject]
    .SetValuesLoop:
        push ecx
        mov eax, [esi + ObjectFieldInputControl.EditableProperty]

        cmp eax, PROP_VISIBLE
        jne @F

        invoke SendMessage, [esi + ObjectFieldInputControl.hWnd], BM_GETCHECK, 0, 0
        xor edx, edx
        cmp eax, BST_CHECKED
        je .SetIsHidden

        mov edx, 1

        .SetIsHidden:
        mov byte [ebx + GeometryObject.IsHidden], dl
        jmp .NextIteration

        cmp eax, PROP_NAME
        jne @F

        lea eax, [StringBuffer + 4]
        invoke GetWindowTextW, [esi + ObjectFieldInputControl.hWnd], eax, 65
        mov dword [StringBuffer], eax
        invoke GetLastError
        lea eax, [StringBuffer + 4]
        stdcall GeometryObject.SetName, eax
        jmp .NextIteration

        @@:
        cmp eax, PROP_SIZE
        jne @F

        invoke SendMessage, [esi + ObjectFieldInputControl.hWnd], TBM_GETPOS, ebx, ebx
        mov [ebx + PROP_SIZE.Offset], eax
        jmp .NextIteration

        @@:
        cmp eax, PROP_COLOR
        jne @F

        mov eax, [ObjectSettingsWindow.ChosenColor]
        mov [ebx + PROP_COLOR.Offset], eax
        jmp .NextIteration

        @@:
        .NextIteration:
        add esi, sizeof.ObjectFieldInputControl
        pop ecx
        loop .SetValuesLoop

    .Return:
    ret
endp


proc ObjectSettingsWindow.EditObject uses ebx, pObject
    locals
        hWnd dd ?
        WorkArea RECT ?
    endl

    mov eax, [pObject]
    mov [ObjectSettingsWindow.pObject], eax

    mov [ObjectSettingsWindow.CurrentYOffset], ObjectSettingsWindow.InitialYOffset

    mov ebx, ObjectSettingsWindow.Controls
    stdcall Vector.Clear

    mov ebx, ObjectSettingsWindow.TrackbarsValueControls
    stdcall Vector.Clear

    invoke CreateWindowEx, 0, ObjectSettingsWindow.wcexClass.ClassName, ObjectSettingsWindow.Title, \
                           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_POPUP, 0, 0, 0, 0, \
                           [DrawArea.hwnd], NULL, [hInstance], NULL

    mov [hWnd], eax

    mov ebx, [pObject]
    stdcall GeometryObject.GetEditableProperties

    stdcall ObjectSettingsWindow._AddControls, [hWnd], eax

    lea eax, [WorkArea]
    invoke SystemParametersInfoA, SPI_GETWORKAREA, 0, eax, 0

    ; uFlags
    push SWP_NOZORDER or SWP_SHOWWINDOW

    ; cy
    mov eax, [ObjectSettingsWindow.CurrentYOffset]
    add eax, ObjectSettingsWindow.PaddingBottom
    push eax

    ; cx
    push ObjectSettingsWindow.Width

    ; Y
    mov eax, [WorkArea.bottom]
    shr eax, 1
    mov ecx, [ObjectSettingsWindow.CurrentYOffset]
    shr ecx, 1
    sub eax, ecx
    push eax

    ; X
    mov eax, [WorkArea.right]
    shr eax, 1
    sub eax, ObjectSettingsWindow.Width / 2
    push eax

    mov eax, [hWnd]
    invoke SetWindowPos, eax, eax ; Other arguments are pushed above

    mov eax, [hWnd]
    ret
endp




proc DrawArea.WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
    locals
        TransitionMessage dd ?
    endl

    mov eax, [wmsg]
    cmp eax, WM_CREATE
    je .Wmcreate
    cmp eax, WM_DESTROY
    je .Return_0
    cmp eax, WM_PAINT
    je .Wmpaint
    cmp eax, WM_RBUTTONDOWN
    je .Wmrbuttondown
    cmp eax, WM_LBUTTONDOWN
    je .Wmlbuttondown
    cmp eax, WM_LBUTTONUP
    je .Wmlbuttonup
    cmp eax, WM_MOUSEMOVE
    je .Wmmousemove
    cmp  eax, WM_MOUSEWHEEL
    je .Wmmousewheel
    cmp eax, WM_KEYDOWN
    je .Wmkeydown
    cmp eax, WM_COMMAND
    je .Wmcommand
    cmp eax, WM_DESTROY
    je .Wmdestroy

    .Defwndproc:
        invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
        jmp .Return

    .Wmcreate:
        invoke GetDC, [hwnd]
        mov [DrawArea.hDC], eax

        invoke CreateCompatibleDC, eax
        mov [DrawArea.MainBufferDC], eax

        invoke CreateCompatibleBitmap, [DrawArea.hDC], [DrawArea.Width], [DrawArea.Height]
        invoke SelectObject, [DrawArea.MainBufferDC], eax

        invoke CreateCompatibleDC, [DrawArea.hDC]
        mov [DrawArea.AxesGridBufferDC], eax
        invoke CreateCompatibleBitmap, [DrawArea.hDC], [DrawArea.Width], [DrawArea.Height]
        invoke SelectObject, [DrawArea.AxesGridBufferDC], eax
        stdcall DrawArea.Clear, [DrawArea.AxesGridBufferDC]

        stdcall DrawArea.CreateMainPopupMenu

        jmp .Return_0

    .Wmpaint:
        invoke BeginPaint, [DrawArea.hwnd], DrawArea.PaintStruct
        invoke BitBlt, eax, 0, 0, [DrawArea.Width], [DrawArea.Height], [DrawArea.MainBufferDC], 0, 0, SRCCOPY
        invoke EndPaint, [DrawArea.hwnd], DrawArea.PaintStruct

        jmp .Return_0

    .Wmmousewheel:
        movsx eax, word [wparam + 2]
        call Math.Sign

        movzx edx, word [lparam]
        movzx ecx, word [lparam + 2]
        stdcall Main.Scale, edx, ecx, eax
        xor eax, eax
        jmp .Redraw

    .Wmkeydown:
         mov eax, [wparam]
         mov [TransitionMessage], eax
         jmp .Transition

    .Wmcommand:
        movzx eax, word [wparam]
        cmp eax, 1
        jnz .Return_0

        xor dword [ShowAxes], 1
        mov eax, [ShowAxes]
        shl eax, 3 ; because MF_CHECKED = 8
        invoke CheckMenuItem, [DrawArea.MainPopupMenu.Handle], 1, eax
        invoke DrawMenuBar, [DrawArea.MainPopupMenu.Handle]
        jmp .Redraw

    .Wmrbuttondown:
        invoke GetWindowRect, [hwnd], DrawArea.Rect

        movzx eax, word [lparam]
        add eax, [DrawArea.Rect.left]
        movzx edx, word [lparam + 2]
        add edx, [DrawArea.Rect.top]
        invoke TrackPopupMenu, [DrawArea.MainPopupMenu.Handle], TPM_RIGHTALIGN or TPM_TOPALIGN, eax, edx, 0, [hwnd], 0

    .Wmlbuttondown:
    .Wmlbuttonup:
    .Wmmousemove:
         mov eax, [wmsg]
         mov [TransitionMessage], eax

         movzx eax, word [lparam]
         call Math.IntToFloat
         mov [CurrentMouseScreenPoint.X], eax
         mov edx, eax

         movzx eax, word [lparam + 2]
         call Math.IntToFloat
         mov [CurrentMouseScreenPoint.Y], eax

         stdcall Main.ToPlanePosition, edx, eax
         mov [CurrentMousePlanePoint.X], edx
         mov [CurrentMousePlanePoint.Y], eax

     .Transition:
     stdcall Main.Transition, [TransitionMessage]
     test eax, eax
     jz .Return

     .Redraw:
     stdcall DrawArea.Redraw
     jmp .Return_0

     .Wmdestroy:
         invoke DestroyMenu, [DrawArea.MainPopupMenu.Handle]

    .Return_0:
        xor eax, eax

    .Return:
        ret
endp


proc DrawArea.CreateMainPopupMenu uses ebx
   invoke CreatePopupMenu
   mov [DrawArea.MainPopupMenu.Handle], eax
   mov ebx, eax

   invoke AppendMenu, ebx, MF_STRING or MF_UNCHECKED, 1, DrawArea.MainPopupMenu.String.ShowAxes
   invoke DrawMenuBar, ebx

   ret
endp


proc DrawArea.Clear uses esi edi, hdc
     invoke SelectObject, [hdc], [hbrWhite]
     invoke SelectObject, [hdc], [hpWhite]
     invoke Rectangle, [hdc], 0, 0, [DrawArea.Width], [DrawArea.Height]
     ret
endp


proc DrawArea.DrawPoints uses ebx, hdc
    mov ebx, [Points.Ptr]
    mov ecx, [Points.Length]

    test ecx, ecx
    jz .Return

    .DrawLoop:
        push ecx
        stdcall Point.Draw, [hdc]
        pop ecx

        add ebx, sizeof.Point
        loop .DrawLoop

    .Return:
    ret
endp


proc DrawArea.Redraw uses ebx edi
    stdcall DrawArea.Clear, [DrawArea.MainBufferDC]

    cmp [ShowAxes], 0
    je .DrawObjects

    cmp [AxesAndGridNeedRedraw], 0
    je @F

    stdcall DrawArea.Clear, [DrawArea.AxesGridBufferDC]
    stdcall DrawArea.DrawAxes, [DrawArea.AxesGridBufferDC]
    mov [AxesAndGridNeedRedraw], 0

    @@:
    invoke BitBlt, [DrawArea.MainBufferDC], 0, 0, [DrawArea.Width], [DrawArea.Height], [DrawArea.AxesGridBufferDC], 0, 0, SRCCOPY

    .DrawObjects:
    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .DrawPoints

    mov edi, [Objects.Sizes.Ptr]
    mov ebx, [Objects.Ptr]

    .DrawLoop:
        push ecx
        movzx eax, byte [ebx + GeometryObject.Type]
        dec eax
        shl eax, 2
        add eax, Objects.DrawProcedures
        stdcall dword [eax], [DrawArea.MainBufferDC]
        pop ecx

        add ebx, [edi]
        add edi, HeterogenousVector.BytesForElementSize
        loop .DrawLoop

     .DrawPoints:
     stdcall DrawArea.DrawPoints, [DrawArea.MainBufferDC]

    .Return:
    invoke InvalidateRect, [DrawArea.hwnd], NULL, FALSE
    ret
endp


proc DrawArea.DrawAxes hdc
    locals
        Two dq 2f
        X dd ?
        Y dd ?
        Width dd ?
        Height dd ?
    endl

    fild [DrawArea.Width]
    fstp [Width]
    fild [DrawArea.Height]
    fst [Height]

    ; X-axis
    fdiv [Two]
    fmul [Scale]
    fadd [Translate.y]
    fldz
    fcomip st0, st1
    ja @F
    fld [Height]
    fcomip st0, st1
    jb @F

    fst [Y]
    stdcall Draw.Line, [hdc], 0, [Y], [Width], [Y], DrawArea.AxesWidth, DrawArea.AxesColor

    @@:
    fstp st0
    ; Y-axis
    fld [Width]
    fdiv [Two]
    fmul [Scale]
    fadd [Translate.x]
    fldz
    fcomip st0, st1
    ja .Return
    fld [Width]
    fcomip st0, st1
    jb .Return

    fst [X]
    stdcall Draw.Line, [hdc], [X], 0, [X], [Height], DrawArea.AxesWidth, DrawArea.AxesColor

    .Return:
    fstp st0
    ret
endp





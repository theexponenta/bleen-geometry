
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

    .Defwndproc:
        invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
        jmp .Return

    .Wmcreate:
        invoke GetDC, [hwnd]
        mov [DrawArea.hDC], eax

        invoke CreateCompatibleDC, eax
        mov [DrawArea.MemDC], eax

        invoke CreateCompatibleBitmap, [DrawArea.hDC], [DrawArea.Width], [DrawArea.Height]
        invoke SelectObject, [DrawArea.MemDC], eax

        jmp .Return_0

    .Wmpaint:
        invoke BeginPaint, [DrawArea.hwnd], DrawArea.PaintStruct
        invoke BitBlt, eax, 0, 0, [DrawArea.Width], [DrawArea.Height], [DrawArea.MemDC], 0, 0, SRCCOPY
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

    .Wmrbuttondown:
    .Wmlbuttondown:
    .Wmlbuttonup:
    .Wmmousemove:
         mov eax, [wmsg]
         mov [TransitionMessage], eax

         movzx edx, word [lparam]
         mov [CurrentMouseScreenPoint.X], edx
         movzx eax, word [lparam + 2]
         mov [CurrentMouseScreenPoint.Y], eax

         stdcall Main.ToPlanePosition, edx, eax
         mov [CurrentMousePlanePoint.X], edx
         mov [CurrentMousePlanePoint.Y], eax

     .Transition:
     stdcall Main.Transition, [TransitionMessage]
     test eax, eax
     jz .Return

     .Redraw:
     stdcall DrawArea.Redraw, [DrawArea.MemDC]
     jmp .Return

    .Return_0:
        xor eax, eax

    .Return:
        ret
endp


proc DrawArea.Clear uses esi edi, hdc
     invoke SelectObject, [hdc], [hbrWhite]
     invoke SelectObject, [hdc], [hpWhite]
     invoke Rectangle, [hdc], 0, 0, [DrawArea.Width], [DrawArea.Height]
     ret
endp


proc DrawArea._DrawPoints uses ebx, hdc
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


proc DrawArea.Redraw uses ebx edi, hdc
    stdcall DrawArea.Clear, [hdc]

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
        stdcall dword [eax], [hdc]
        pop ecx

        add ebx, [edi]
        add edi, HeterogenousVector.BytesForElementSize
        loop .DrawLoop

     .DrawPoints:
     stdcall DrawArea._DrawPoints, [hdc]

    .Return:
    invoke InvalidateRect, [DrawArea.hwnd], NULL, 0
    ret
endp





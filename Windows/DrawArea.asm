
proc DrawArea.WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
    locals
        TransitionMessage dd ?
        WidthHalf dd ?
        HeightHalf dd ?
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
        mov eax, [DrawArea.Width]
        shr eax, 1
        mov [WidthHalf], eax
        mov eax, [DrawArea.Height]
        shr eax, 1
        mov [HeightHalf], eax

        invoke GetDC, [hwnd]
        mov [DrawArea.hDC], eax

        invoke CreateCompatibleDC, eax
        mov [DrawArea.MainBufferDC], eax
        invoke SetGraphicsMode, eax, GM_ADVANCED
        ;invoke SetMapMode, [DrawArea.MainBufferDC], MM_ANISOTROPIC
        ;mov edx, [DrawArea.Height]
        ;neg edx
        ;push edx
        ;invoke SetViewportExtEx, [DrawArea.MainBufferDC], [DrawArea.Width], edx, NULL
        ;pop edx
        ;invoke SetWindowExtEx, [DrawArea.MainBufferDC], [DrawArea.Width], edx, NULL
        ;invoke SetViewportOrgEx, [DrawArea.MainBufferDC], [WidthHalf], [HeightHalf], NULL
        invoke CreateCompatibleBitmap, [DrawArea.hDC], [DrawArea.Width], [DrawArea.Height]
        invoke SelectObject, [DrawArea.MainBufferDC], eax

        invoke CreateCompatibleDC, [DrawArea.hDC]
        mov [DrawArea.AxesGridBufferDC], eax
        ;invoke SetMapMode, eax, MM_ANISOTROPIC
        ;mov edx, [DrawArea.Height]
        ;neg edx
        ;push edx
        ;invoke SetViewportExtEx, [DrawArea.AxesGridBufferDC], [DrawArea.Width], edx, NULL
        ;pop edx
        ;invoke SetWindowExtEx, [DrawArea.MainBufferDC], [DrawArea.Width], edx, NULL
        ;invoke SetViewportOrgEx, [DrawArea.AxesGridBufferDC], [WidthHalf], [HeightHalf], NULL
        invoke CreateCompatibleBitmap, [DrawArea.hDC], [DrawArea.Width], [DrawArea.Height]
        invoke SelectObject, [DrawArea.AxesGridBufferDC], eax
        stdcall DrawArea.Clear, [DrawArea.AxesGridBufferDC]

        stdcall DrawArea.CreateMainPopupMenu
        stdcall DrawArea.CreateObjectPopupMenu

        invoke CreateFont, DrawArea.AxisTickFontSize, 0, 0, 0, FW_EXTRALIGHT, FALSE, FALSE, FALSE, DEFAULT_CHARSET, \
                           OUT_OUTLINE_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, VARIABLE_PITCH, NULL
        mov [DrawArea.AxesTickFont], eax

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

        cmp eax, DrawArea.ObjectPopupMenu.Commands.Settings
        jne @F

        stdcall ObjectSettingsWindow.EditObject, [ObjectSettingsWindow.pObject]
        jmp .Return_0

        @@:
        cmp eax, DrawArea.MainPopupMenu.Commands.ShowAxes
        jne @F

        stdcall DrawArea.ToggleMainMenuCheckItem, DrawArea.MainPopupMenu.Commands.ShowAxes, ShowAxes
        jmp .DrawMenu

        @@:
        cmp eax, DrawArea.MainPopupMenu.Commands.ShowGrid
        jne @F

        stdcall DrawArea.ToggleMainMenuCheckItem, DrawArea.MainPopupMenu.Commands.ShowGrid, ShowGrid
        jmp .DrawMenu

        @@:
        cmp eax, DrawArea.MainPopupMenu.Commands.SnapToGrid
        jne .Return_0

        stdcall DrawArea.ToggleMainMenuCheckItem, DrawArea.MainPopupMenu.Commands.SnapToGrid, SnapToGrid

        .DrawMenu:
        invoke DrawMenuBar, [DrawArea.MainPopupMenu.Handle]
        jmp .Redraw

    .Wmrbuttondown:
        invoke GetWindowRect, [hwnd], DrawArea.Rect

        movzx eax, word [lparam + 2]
        call Math.IntToFloat
        push eax
        movzx eax, word [lparam]
        call Math.IntToFloat
        push eax

        stdcall Main.GetObjectOnPosition
        mov ecx, [DrawArea.MainPopupMenu.Handle]
        test eax, eax
        jz @F

        mov [ObjectSettingsWindow.pObject], eax
        mov ecx, [DrawArea.ObjectPopupMenu.Handle]

        @@:
        movzx eax, word [lparam]
        movzx edx, word [lparam + 2]
        add eax, [DrawArea.Rect.left]
        add edx, [DrawArea.Rect.top]
        invoke TrackPopupMenu, ecx, TPM_RIGHTALIGN or TPM_TOPALIGN, eax, edx, 0, [hwnd], 0

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
         invoke DeleteObject, [DrawArea.AxesTickFont]

    .Return_0:
        xor eax, eax

    .Return:
        ret
endp


proc DrawArea.CreateMainPopupMenu uses ebx
   invoke CreatePopupMenu
   mov [DrawArea.MainPopupMenu.Handle], eax
   mov ebx, eax

   invoke AppendMenu, ebx, MF_STRING or MF_UNCHECKED, DrawArea.MainPopupMenu.Commands.ShowAxes, DrawArea.MainPopupMenu.Strings.ShowAxes
   invoke AppendMenu, ebx, MF_STRING or MF_UNCHECKED, DrawArea.MainPopupMenu.Commands.ShowGrid, DrawArea.MainPopupMenu.Strings.ShowGrid
   invoke AppendMenu, ebx, MF_STRING or MF_CHECKED, DrawArea.MainPopupMenu.Commands.SnapToGrid, DrawArea.MainPopupMenu.Strings.SnapToGrid
   invoke DrawMenuBar, ebx

   ret
endp


proc DrawArea.ToggleMainMenuCheckItem, CommandId, pVarToToggle
    mov eax, [pVarToToggle]
    xor dword [eax], 1

    mov eax, [eax]
    shl eax, 3 ; because MF_CHECKED = 8
    invoke CheckMenuItem, [DrawArea.MainPopupMenu.Handle], [CommandId], eax

    mov [AxesAndGridNeedRedraw], 1
    ret
endp


proc DrawArea.CreateObjectPopupMenu uses ebx
    invoke CreatePopupMenu
    mov [DrawArea.ObjectPopupMenu.Handle], eax
    mov ebx, eax

    invoke AppendMenu, ebx, MF_STRING or MF_UNCHECKED, DrawArea.ObjectPopupMenu.Commands.Settings, \
                       DrawArea.ObjectPopupMenu.Strings.Settings
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
       cmp byte [ebx + GeometryObject.IsHidden], 0
       jne .NextIteration

        push ecx
        stdcall Point.Draw, [hdc]
        pop ecx

        .NextIteration:
        add ebx, sizeof.Point
        loop .DrawLoop

    .Return:
    ret
endp


proc DrawArea.Redraw uses ebx edi
    stdcall DrawArea.Clear, [DrawArea.MainBufferDC]

    cmp [AxesAndGridNeedRedraw], 0
    je .CopyToMainBuffer

    mov [AxesAndGridNeedRedraw], 0
    stdcall DrawArea.Clear, [DrawArea.AxesGridBufferDC]

    cmp [ShowGrid], 0
    je @F

    stdcall DrawArea.DrawGrid, [DrawArea.AxesGridBufferDC]

    @@:
    cmp [ShowAxes], 0
    je .CopyToMainBuffer

    stdcall DrawArea.DrawAxes, [DrawArea.AxesGridBufferDC]

    .CopyToMainBuffer:
    invoke BitBlt, [DrawArea.MainBufferDC], 0, 0, [DrawArea.Width], [DrawArea.Height], [DrawArea.AxesGridBufferDC], 0, 0, SRCCOPY

    .DrawObjects:
    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .DrawPoints

    mov edi, ecx
    sub edi, 1
    shl edi, 2
    add edi, [Objects.Sizes.Ptr]
    mov ebx, [Objects.Ptr]
    add ebx, [Objects.TotalSize]
    sub ebx, [edi]

    .DrawLoop:
        cmp byte [ebx + GeometryObject.IsHidden], 0
        jne .NextIteration

        push ecx
        movzx eax, byte [ebx + GeometryObject.Type]
        dec eax
        shl eax, 2
        add eax, Objects.DrawProcedures
        stdcall dword [eax], [DrawArea.MainBufferDC]
        pop ecx

        .NextIteration:
        sub edi, HeterogenousVector.BytesForElementSize
        sub ebx, [edi]
        loop .DrawLoop

     .DrawPoints:
     stdcall DrawArea.DrawPoints, [DrawArea.MainBufferDC]

    .Return:
    invoke InvalidateRect, [DrawArea.hwnd], NULL, FALSE
    ret
endp


proc DrawArea.DrawAxes hdc
    locals
        X dd ?
        Y dd ?
        Width dd ?
        Height dd ?
    endl

    fild [DrawArea.Width]
    fstp [Width]
    fild [DrawArea.Height]
    fstp [Height]

    ; X-axis
    fld [Translate.y]
    fldz
    fcomip st0, st1
    ja @F
    fld [Height]
    fcomip st0, st1
    jb @F

    fstp [Y]
    stdcall Draw.Line, [hdc], 0, [Y], [Width], [Y], DrawArea.AxesWidth, DrawArea.AxesColor
    stdcall DrawArea.DrawAxisTicks, [hdc], DrawArea.XAxis
    fldz ; Push something on stack to let next instruction to pop it

    @@:
    fstp st0
    ; Y-axis
    fld [Translate.x]
    fldz
    fcomip st0, st1
    ja .Return
    fld [Width]
    fcomip st0, st1
    jb .Return

    fst [X]
    stdcall Draw.Line, [hdc], [X], 0, [X], [Height], DrawArea.AxesWidth, DrawArea.AxesColor
    fstp st0
    stdcall DrawArea.DrawAxisTicks, [hdc], DrawArea.YAxis
    fldz

    .Return:
    fstp st0
    ret
endp


proc DrawArea._GetAxisTicksStep
    locals
        MinAxisLength dd ?
        Log10Length dd ?
    endl

    fild [MinDistanceBetweenTicks]
    fdiv [Scale]

    ; Minimum of height and width witout branching
    mov eax, [DrawArea.Height]
    mov ecx, [DrawArea.Width]
    sub eax, ecx
    cdq
    add eax, ecx
    xor eax, ecx
    and eax, edx
    xor eax, ecx
    mov [MinAxisLength], eax

    ; Trunc(Lg(MinAxisLength / Scale)) - 1
    fild [MinAxisLength]
    fdiv [Scale]
    call Math.Log10
    fld1
    fsubp
    call Math.Floor
    fstp [Log10Length]

    ; Let's call the value in st0 after this procedure "Pow10"
    stdcall Math.Pow, 10f, [Log10Length]

    fld st0 ; Copy Pow10, now Pow10 is in st0 and st1

    ; Check Multiplier=1
    fcomi st0, st2
    jae @F

    fadd st0, st1 ; Pow10*2
    ; Check Multiplier=2
    fcomi st0, st2
    jae @F

    fadd st0, st0 ; st0=Pow10*4
    fadd st0, st1 ; st0=Pow10*5

    @@:
    fxch ; Move Pow10 to st0 from st1
    fstp st0 ; Pop Pow10

    fxch ; Move MinDistanceBetweenTicks / Scale to st0 from st1
    fstp st0 ; Pop MinDistanceBetweenTicks / Scale

    .Finish:
    ; Precision
    fld [Log10Length]
    fldz
    call Math.FPUMin
    fchs

    ret
endp


; Returns coordinates of nearist grid node: edx - x-coordinate, eax - y-coordinate
proc DrawArea.GetNearestGridNode, X, Y
    locals
        NearestX dd ?
        NearestY dd ?
    endl

    stdcall DrawArea._GetAxisTicksStep, DrawArea.XAxis
    fstp st0 ; Pop precision

    ; Start x coordinate
    fld [Translate.x]
    fchs
    fdiv [Scale]
    fdiv st0, st1
    call Math.Ceil
    fmul st0, st1

    fld [X]
    fsub st0, st1
    fdiv st0, st2
    fld st0
    call Math.Ceil
    fmul st0, st3
    fadd st0, st2
    fxch
    call Math.Floor
    fmul st0, st3
    fadd st0, st2
    fld [X]
    fld st0
    fsub st0, st3
    fabs
    fxch
    fsub st0, st2
    fabs
    fcomip st0, st1
    fstp st0
    jae @F

    fxch

    @@:
    fstp st0
    fxch st2
    fstp st0
    fstp st0

    stdcall DrawArea._GetAxisTicksStep, DrawArea.YAxis
    fstp st0 ; Pop precision

    fld [Translate.y]
    fisub [DrawArea.Height]
    fdiv [Scale]
    fdiv st0, st1
    call Math.Ceil
    fmul st0, st1

    fld [Y]
    fsub st0, st1
    fdiv st0, st2
    fld st0
    call Math.Ceil
    fmul st0, st3
    fadd st0, st2
    fxch
    call Math.Floor
    fmul st0, st3
    fadd st0, st2
    fld [Y]
    fld st0
    fsub st0, st3
    fabs
    fxch
    fsub st0, st2
    fabs
    fcomip st0, st1
    fstp st0
    jae @F

    fxch

    @@:
    fstp st0
    fxch st2
    fstp st0
    fstp st0

    fstp [NearestY]
    fstp [NearestX]

    mov eax, [NearestY]
    mov edx, [NearestX]

    ret
endp


proc DrawArea._GetAxisTicksCalculations, AxisType, pOutTotalTicksCount, pOutPrecision
    locals
        MinAxisLength dd ?
        AxisLength dd ?
        TranslateValue dd ?
        PointStructureOffset dd ?
        Precision dd ?
        Log10Length dd ?
        TotalTicksCount dd ?
    endl

    mov eax, [DrawArea.Width]
    mov [AxisLength], eax
    fld [Translate.x]
    fstp [TranslateValue]

    mov eax, [AxisType]
    cmp eax, DrawArea.XAxis
    je @F
    cmp eax, DrawArea.YAxis
    jne .Return

    mov eax, [DrawArea.Height]
    mov [AxisLength], eax
    fld [Translate.y]
    fstp [TranslateValue]

    @@:
    mov edx, [AxisType]
    shl edx, 2
    push edx

    stdcall DrawArea._GetAxisTicksStep

    fistp [Precision]
    mov ecx, [pOutPrecision]
    test ecx, ecx
    jz @F

    mov eax, [Precision]
    mov [ecx], eax

    @@:
    ; Step (screen)
    fld st0
    fmul [Scale]
    cmp [AxisType], DrawArea.YAxis
    jne @F
    fchs

    @@:
    ; Ticks count
    fild [AxisLength]
    fdiv st0, st1
    fabs
    call Math.Ceil
    fistp [TotalTicksCount]

    mov ecx, [pOutTotalTicksCount]
    test ecx, ecx
    jz @F

    mov eax, [TotalTicksCount]
    mov [ecx], eax

    @@:
    ; Starting number of steps
    ; Can be negative, calculated as n = Ceil(LeftmostCoordintae / Step),
    ; where LeftmostCoordinate = -Translate.x / Scale for X-axis
    ; and   LeftmostCoordinate = (Translate.y - AxisLength) / Scale for Y-axis
    fld [TranslateValue]
    fldz
    cmp [AxisType], DrawArea.XAxis
    je @F

    fiadd [AxisLength]
    fxch

    @@:
    fsubrp
    fdiv [Scale]
    fdiv st0, st2
    call Math.Ceil

    ; Start coordinate (Screen)
    fld st0
    fmul st0, st3
    fmul [Scale]
    cmp [AxisType], DrawArea.YAxis
    jne @F
    fchs

    @@:
    fadd [TranslateValue]

    .Return:
    pop edx
    ret
endp


proc DrawArea.DrawAxisTicks uses edi esi ebx, hdc, AxisType
    locals
        PointStructureOffset dd ?
        Precision dd ?
        StringBuffer db 32 dup(?)
        PrevTextAlign dd ?
        PrevFont dd ?
        TotalTicksCount dd ?
        CurrentTicksCount dd ?
        CurrentTickValue dq ?
        CurrentTickMarkPoint POINT ?
        CurrentTickLabelPoint POINT ?
        hPen dd ?
    endl

    lea edi, [StringBuffer]
    mov esi, [hdc]

    invoke CreatePen, PS_SOLID, DrawArea.AxesWidth, DrawArea.AxesColor
    mov [hPen], eax
    invoke SelectObject, esi, eax

    lea eax, [TotalTicksCount]
    lea edx, [Precision]
    stdcall DrawArea._GetAxisTicksCalculations, [AxisType], eax, edx
    mov [PointStructureOffset], edx

    ; Move plane start coordinate to st0 from st1
    fxch

    neg edx
    fld dword [Translate + 4 + edx]
    fist dword [CurrentTickMarkPoint + 4 + edx]
    fistp dword [CurrentTickLabelPoint + 4 + edx]
    add dword [CurrentTickLabelPoint + 4 + edx], DrawArea.TickLabelDistanceFromAxis

    invoke GetTextAlign, esi
    mov [PrevTextAlign], eax
    OBJ_FONT = 6
    invoke GetCurrentObject, esi, OBJ_FONT
    mov [PrevFont], eax

    invoke SelectObject, esi, [DrawArea.AxesTickFont]
    invoke SetTextAlign, esi, TA_CENTER
    invoke SetTextColor, esi, DrawArea.AxesColor

    mov ecx, [TotalTicksCount]
    mov [CurrentTicksCount], 0
    .DrawTicksLoop:
        push ecx

        fld st0
        fiadd [CurrentTicksCount]
        call Math.Round
        fmul st0, st4

        fst [CurrentTickValue]
        cinvoke sprintf, edi, DrawArea.TickLabelFormat, dword [CurrentTickValue], dword [CurrentTickValue + 4]
        invoke lstrlenA, edi
        fstp st0

        fxch

        mov edx, [PointStructureOffset]
        fist dword [CurrentTickLabelPoint + edx]
        fist dword [CurrentTickMarkPoint + edx]

        push edx
        invoke TextOutA, esi, [CurrentTickLabelPoint.x], [CurrentTickLabelPoint.y], edi, eax
        invoke MoveToEx, esi, [CurrentTickMarkPoint.x], [CurrentTickMarkPoint.y], NULL
        pop edx

        neg edx
        add dword [CurrentTickMarkPoint + 4 + edx], DrawArea.AxisTickLength
        push edx
        invoke LineTo, esi, [CurrentTickMarkPoint.x], [CurrentTickMarkPoint.y]
        pop edx
        sub dword [CurrentTickMarkPoint + 4 + edx], DrawArea.AxisTickLength

        pop ecx

        fadd st0, st2
        fxch
        add [CurrentTicksCount], 1
        sub ecx, 1
        jnz .DrawTicksLoop

    .Finish:
    invoke SetTextAlign, [PrevTextAlign]
    invoke SelectObject, esi, [PrevFont]

    invoke GetStockObject, DC_PEN
    invoke SelectObject, esi, eax
    invoke DeleteObject, [hPen]

    fstp st0
    fstp st0
    fstp st0
    fstp st0
    .Return:
    ret
endp


proc DrawArea.DrawGrid uses edi, hdc
    locals
        TotalGridLinesCount dd ?
        CurrentCoordinate dd ?
        hPen dd ?
    endl

    mov esi, [hdc]

    invoke CreatePen, PS_SOLID, DrawArea.GridLinesWidth, DrawArea.GridLinesColor
    mov [hPen], eax
    invoke SelectObject, esi, eax

    lea eax, [TotalGridLinesCount]
    stdcall DrawArea._GetAxisTicksCalculations, DrawArea.XAxis, eax, NULL
    mov ecx, [TotalGridLinesCount]
    .DrawVeritcalLinesLoop:
        push ecx

        fist [CurrentCoordinate]
        invoke MoveToEx, esi, [CurrentCoordinate], 0, NULL
        invoke LineTo, esi, [CurrentCoordinate], [DrawArea.Height]

        pop ecx
        fadd st0, st2
        loop .DrawVeritcalLinesLoop

    fstp st0
    fstp st0
    fstp st0
    fstp st0

    lea eax, [TotalGridLinesCount]
    stdcall DrawArea._GetAxisTicksCalculations, DrawArea.YAxis, eax, NULL
    mov ecx, [TotalGridLinesCount]
    .DrawHorizontalLinesLoop:
        push ecx

        fist [CurrentCoordinate]
        invoke MoveToEx, esi, 0, [CurrentCoordinate], NULL
        invoke LineTo, esi, [DrawArea.Width], [CurrentCoordinate]

        pop ecx
        fadd st0, st2
        loop .DrawHorizontalLinesLoop

    fstp st0
    fstp st0
    fstp st0
    fstp st0

    invoke GetStockObject, DC_PEN
    invoke SelectObject, [hdc], eax
    invoke DeleteObject, [hPen]

    ret
endp

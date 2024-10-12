format PE GUI 5.0
entry WinMain

include 'win32w.inc'
include 'DataStructures/Vector.inc'
include 'DataStructures/HeterogenousVector.inc'
include 'DataStructures/LinkedList.inc'
include 'Objects/Objects.inc'
include 'ObjectsAddProc.asm'
include 'Tools/Tools.inc'


section '.text' code readable executable


proc WinMain
    local Msg MSG
    local CW dw ?

    fstcw [CW]
    mov ax, [CW]
    and ax, 1111_1100_1111_1111b
    or ax, 11b shl 8
    mov [CW], ax
    fldcw [CW]

    invoke GetProcessHeap
    mov [hProcessHeap], eax
    
    mov ebx, Objects
    stdcall HeterogenousVector.Create, 255

    mov ebx, SelectedObjectsIds
    stdcall Vector.Create, 4, 0, 40
    mov ebx, SelectedObjectsPtrs
    stdcall Vector.Create, 4, 0, 40

    mov ebx, Points
    stdcall Vector.Create, sizeof.Point, 0, 26

    invoke CreateSolidBrush, 0xFFFFFF
    mov [hbrWhite], eax
    invoke CreatePen, PS_SOLID, 1, 0xFFFFFF
    mov [hpWhite], eax
    invoke CreatePen, PS_SOLID, Point.BorderSize, 0
    mov [Point.BorderPen], eax

    invoke GetModuleHandle, 0
    mov [hInstance], eax
    mov [WindowClass.hInstance], eax

    invoke LoadIcon, 0, IDI_APPLICATION
    mov [WindowClass.hIcon], eax
    invoke LoadCursor, 0, IDC_ARROW
    mov [WindowClass.hCursor], eax

    mov [WindowClass.lpfnWndProc], MainWindow.WindowProc
    mov [WindowClass.lpszClassName], MainWindow.wcexClass.ClassName
    invoke RegisterClassEx, WindowClass
    test eax, eax
    jz .Error

    mov [WindowClass.lpfnWndProc], DrawArea.WindowProc
    mov [WindowClass.lpszClassName], DrawArea.wcexClass.ClassName
    mov eax, [hbrWhite]
    mov [WindowClass.hbrBackground], eax
    invoke RegisterClassEx, WindowClass
    test eax, eax
    jz .Error

    invoke CreateWindowEx, 0, MainWindow.wcexClass.ClassName, MainWindow.Title, \
        WS_OVERLAPPEDWINDOW, 0, 0, 100, 100, \
        NULL, NULL, [hInstance], NULL

    test eax, eax
    jz .Error

    mov [MainWindow.hwnd], eax
    invoke ShowWindow, eax, SW_MAXIMIZE

    lea edi, [Msg]
    .MessageLoop:
        invoke PeekMessage, edi, NULL, 0, 0, PM_NOREMOVE
        test eax, eax
        jz .NoMessages

        invoke GetMessage, edi, NULL, 0, 0
        test eax, eax
        jz .EndLoop

        invoke TranslateMessage, edi
        invoke DispatchMessage, edi
        jmp .MessageLoop

    .NoMessages:
        jmp .MessageLoop

    .Error:
        invoke MessageBox, NULL, Error, NULL, MB_ICONERROR + MB_OK

    .EndLoop:
        invoke ExitProcess, [Msg.wParam]
endp


proc Main._FindTransitionProc uses esi ebx, pTransitions, MessageCode
    mov esi, [pTransitions]
    mov ebx, [MessageCode]

    .FindLoop:
        mov eax, [esi]
        test eax, eax
        jz .Return

        cmp eax, ebx
        jz .ReturnFound

        add esi, 8
        jmp .FindLoop


    .ReturnFound:
        add esi, 4
        mov eax, [esi]

    .Return:
    ret
endp


; Returns 1 if transition was made, 0 otherwise
proc Main.Transition MessageCode
    mov eax, [CurrentToolId]
    dec eax
    shl eax, 2
    add eax, Tools.States.Transitions
    mov eax, [eax]

    mov ecx, [CurrentStateId]
    dec ecx
    shl ecx, 2
    add eax, ecx

    stdcall Main._FindTransitionProc, dword [eax], [MessageCode]
    test eax, eax
    jz .Return

    ; If we want transition to exist, but it just does nothing,
    ; we use number 1 as procedure pointer
    cmp eax, 1
    je .Return

    call eax
    mov eax, 1

    .Return:
    ret
endp


; eax - Point id
; Returns pointer to Point object in eax , 0 if not found
proc Main.FindPointById uses esi
    test eax, eax
    jnz @F

    mov eax, CurrentMousePlanePoint
    jmp .Return

    @@:
    mov ecx, [Points.Length]

    test ecx, ecx
    jz .ReturnNotFound

    mov esi, [Points.Ptr]

    .FindLoop:
        cmp eax, [esi + Point.Id]
        je .ReturnFound
        add esi, sizeof.Point
        loop .FindLoop

    .ReturnNotFound:
        xor eax, eax
        jmp .Return

    .ReturnFound:
        mov eax, esi

    .Return:
        ret
endp


; eax - Point id
; Returns index of point in Points vector, -1 if not found
proc Main.FindPointIndexById uses esi
   mov esi, eax
   mov ecx, [Points.Length]
   test ecx, ecx
   jz .ReturnNotFound

   xor eax, eax
   mov edx, [Points.Ptr]
   .FindLoop:
       cmp [edx + Point.Id], esi
       je .Return

       add edx, sizeof.Point
       inc eax
       loop .FindLoop

    .ReturnNotFound:
        mov eax, -1

   .Return:
   ret
endp


; Translates plane position to screen poisition
; Returns result in edx:eax, where edx - x-coordinate on screen, eax - y-coordinate on screen
proc Main.ToScreenPosition, X, Y
    fld [Scale]
    fld [X]
    fld [Y]
    fmul st0, st2
    fadd [Translate.y]
    fstp [Y]
    fmul st0, st1
    fadd [Translate.x]
    fstp [X]
    fstp st0

    mov edx, [X]
    mov eax, [Y]

    ret
endp


; Translates screen position to plane position
; Returns result in edx:eax, where edx - x-coordinate on plane, eax - y-coordinate on plane
proc Main.ToPlanePosition, X, Y
    fld [Scale]
    fld [X]
    fsub [Translate.x]
    fld [Y]
    fsub [Translate.y]
    fdiv st0, st2
    fstp [Y]
    fdiv st0, st1
    fstp [X]
    fstp st0

    mov edx, [X]
    mov eax, [Y]

    ret
endp



; Returns pointer to Point object if found, 0 otherwise
proc Main.FindPointOnPosition uses esi, X, Y
    mov ecx, [Points.Length]

    ; Use 0 value as return value, i.e. instead of jmp .ReturnNotFound,
    ; because here we dont't need to clear FPU stack
    mov eax, ecx
    test eax, eax
    jz .Return

    mov esi, [Points.Ptr]

    stdcall Main.ToPlanePosition, [X], [Y]
    mov [X], edx
    mov [Y], eax

    fld [X]
    fld [Y]

    .FindLoop:
        fld [esi + Point.X]
        fsub st0, st2
        fmul st0, st0
        fld [esi + Point.Y]
        fsub st0, st2
        fmul st0, st0
        faddp
        fsqrt

        fild [esi + Point.Size]
        fdiv [Scale]
        fcomip st, st1
        fstp st0
        jae .ReturnFound

        add esi, sizeof.Point
        loop .FindLoop

    jmp .ReturnNotFound

    .ReturnFound:
        mov eax, esi
        jmp .ClearFPUAndReturn

    .ReturnNotFound:
        xor eax, eax

    .ClearFPUAndReturn:
        fstp st0
        fstp st0

     .Return:
     ret
endp


; Returns pointer to Point object if found, otherwise returns CurrentMouseScreenPoint
proc Main.GetPointOnPosition, X, Y
    stdcall Main.FindPointOnPosition, [X], [Y]
    test eax, eax
    jnz .Return

    mov eax, CurrentMousePlanePoint

    .Return:
    ret
endp


proc Main.GetObjectOnPosition uses ebx edi, X, Y
    stdcall Main.FindPointOnPosition, [X], [Y]
    test eax, eax
    jnz .Return

    stdcall Main.ToPlanePosition, [X], [Y]
    mov [X], edx
    mov [Y], eax

    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .ReturnNotFound

    mov ebx, [Objects.Ptr]
    mov edi, [Objects.Sizes.Ptr]
    .FindLoop:
        push ecx
        movzx eax, byte [ebx + GeometryObject.Type]
        dec eax
        shl eax, 2
        add eax, Objects.IsOnPositionProcedures
        stdcall dword [eax], [X], [Y]
        test eax, eax
        jnz .ReturnFound

        pop ecx

        add ebx, [edi]
        add edi, HeterogenousVector.BytesForElementSize
        loop .FindLoop

    .ReturnNotFound:
        xor eax, eax
        jmp .Return

    .ReturnFound:
        mov eax, ebx

    .Return:
    ret
endp


proc Main.AddSelectedObject uses ebx, pObject
    mov ebx, SelectedObjectsPtrs
    stdcall Vector.PushValue, [pObject]

    mov eax, [pObject]
    mov ebx, SelectedObjectsIds
    stdcall Vector.PushValue, [eax + GeometryObject.Id]

    ret
endp


proc Main.UnselectObjects uses ebx
    mov ecx, [SelectedObjectsPtrs.Length]
    test ecx, ecx
    jz .Return

    mov edx, [SelectedObjectsPtrs.Ptr]
    .UnselectLoop:
        mov eax, [edx]
        mov byte[eax + GeometryObject.IsSelected], 0
        add edx, 4
        loop .UnselectLoop

    mov ebx, SelectedObjectsPtrs
    stdcall Vector.Clear
    mov ebx, SelectedObjectsIds
    stdcall Vector.Clear

    .Return:
    ret
endp


; Direction: 1 -- zoom in, -1 -- zoom out
proc Main.Scale, X, Y, Direction
    fld [ScaleStepCoefficient]
    cmp eax, 0
    jg @F

    fld1
    fdivrp st1, st0

    @@:
    fild [X]
    fsub [Translate.x]
    fld1
    fld st2
    fsubp
    fmulp
    fadd [Translate.x]
    fstp [Translate.x]

    fild [Y]
    fsub [Translate.y]
    fld1
    fld st2
    fsubp
    fmulp
    fadd [Translate.y]
    fstp [Translate.y]

    fld [Scale]
    fmulp st1, st0
    fstp [Scale]

    mov [AxesAndGridNeedRedraw], 1
    ret
endp


; Get pointer to object by id, 0 if not found
proc Main.GetObjectById uses edi, Id
    mov eax, [Id]
    stdcall Main.FindPointById
    test eax, eax
    jnz .Return

    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .ReturnNotFound

    mov edi, [Id]
    mov edx, [Objects.Sizes.Ptr]
    mov eax, [Objects.Ptr]
    .FindLoop:
        cmp edi, [eax + GeometryObject.Id]
        je .Return

        add eax, [edx]
        add edx, 4
        loop .FindLoop

    .ReturnNotFound:
    xor eax, eax

    .Return:
    ret
endp


; Get index of object in Objects vector
;
; eax -- index. -1 if not found
; edx - pointer to object. Undefined if not found. Check eax!
proc Main.GetObjectIndexById uses ebx edi, Id
    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .ReturnNotFound

    xor eax, eax
    mov edi, [Id]
    mov edx, [Objects.Sizes.Ptr]
    mov ebx, [Objects.Ptr]
    .FindLoop:
        cmp edi, [ebx + GeometryObject.Id]
        je .Return

        add ebx, [edx]
        add edx, 4
        inc eax
        loop .FindLoop

    .ReturnNotFound:
    mov eax, -1

    .Return:
    mov edx, ebx
    ret
endp


proc Main._MarkDependentObjectsToDelete uses ebx, Id
    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .Return

    mov ebx, [Objects.Ptr]
    mov edx, [Objects.Sizes.Ptr]
    .MarkObjectsToDeleteLoop:
        push edx ecx
        stdcall GeometryObject.DependsOnObject, [Id]
        pop ecx edx
        test eax, eax
        jz @F

        mov [ebx + GeometryObject.Id], 0
        movzx eax, [ebx + GeometryObject.Type]
        stdcall GeometryObject.IsDependableObjectType, eax
        test eax, eax
        jz @F

        push edx ecx
        stdcall Main._MarkDependentObjectsToDelete, [ebx + GeometryObject.Id]
        pop ecx edx

        @@:
        add ebx, [edx]
        add edx, 4
        loop .MarkObjectsToDeleteLoop

    .Return:
    ret
endp


proc Main.DeleteObjectById uses ebx esi, Id
    mov eax, [Id]
    stdcall Main.FindPointIndexById
    cmp eax, -1
    je .TryDeleteAnotherObject

    mov ebx, Points
    mov esi, OBJ_POINT
    stdcall Vector.DeleteByIndex, eax
    jmp .DeleteDependentObjects

    .TryDeleteAnotherObject:
        stdcall Main.GetObjectIndexById, [Id]
        cmp eax, -1
        je .Return

        movzx esi, byte [edx + GeometryObject.Type]
        mov ebx, Objects
        stdcall HeterogenousVector.DeleteByIndex, eax

    stdcall GeometryObject.IsDependableObjectType, esi
    test eax, eax
    jz .Return

    .DeleteDependentObjects:
    cmp [Objects.Sizes.Length], 0
    je .Return
    stdcall Main._MarkDependentObjectsToDelete, [Id]

    mov ecx, [Objects.Sizes.Length]
    mov esi, [Objects.Ptr]
    mov edx, [Objects.Sizes.Ptr]
    mov ebx, Objects
    xor eax, eax
    .DeleteMarkedObjectsLoop:
        cmp [esi + GeometryObject.Id], 0
        jne @F

        push eax ecx edx
        stdcall HeterogenousVector.DeleteByIndex, eax
        pop edx ecx eax
        dec eax

        @@:
        add esi, [edx]
        add edx, 4
        inc eax
        loop .DeleteMarkedObjectsLoop

    .Return:
    ret
endp


include 'Utils/Draw.asm'
include 'Utils/Math.asm'
include 'Utils/Strings.asm'
include 'DataStructures/Vector.asm'
include 'DataStructures/HeterogenousVector.asm'
include 'DataStructures/LinkedList.asm'
include 'Windows/Main.asm'
include 'Windows/DrawArea.asm'
include 'Objects/Objects.asm'
include 'Tools/Tools.asm'


section '.data' data readable writeable

  hInstance dd ?
  hProcessHeap dd ?

  Error du 'Error', 0
  TOOLBARCLASSNAME du TOOLBAR_CLASS, 0

  WindowClass WNDCLASSEX sizeof.WNDCLASSEX, 0, NULL, 0, 0, NULL, NULL, NULL, \
                         COLOR_BTNFACE + 1, NULL, NULL

  DC_BRUSH = 18
  DC_PEN = 19

  hpWhite dd ?
  hbrWhite dd ?

  Points Vector ?
  NextPointNum dd 0

  Objects HeterogenousVector ?
  NextObjectId dd 1

  SelectedObjectsIds Vector ?
  SelectedObjectsPtrs Vector ?

  CurrentToolId dd 1
  CurrentStateId dd 1

  CurrentMouseScreenPoint Point 0, OBJ_POINT, 0, 0, 0, 0, 0f, 0f
  CurrentMousePlanePoint Point 0, OBJ_POINT, 0, 0, 0, 0, 0f, 0f

  Translate POINT 0f, 0f
  Scale dq 1.0
  ScaleStepCoefficient dq 1.1

  InitialXWidth dd 30f
  MinDistanceBetweenTicks dd 50

  CtrlKeyPressed dd 0

  ShowAxes dd 0
  AxesAndGridNeedRedraw dd 1

  MaxInt dd 2147483647

  include 'Windows/Main.d'
  include 'Windows/DrawArea.d'
  include 'Tools/Tools.d'
  include 'Objects/Objects.d'

section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
          user32, 'USER32.DLL',\
          comctl32, 'COMCTL32.DLL', \
          gdi32, 'GDI32.DLL', \
          gdiplus, 'GDIPLUS.dll'

  include 'api\kernel32.inc'

  include 'api\user32.inc'
  include 'api\comctl32.inc'
  include 'api\gdi32.inc'


section '.rsrc' resource data readable

    directory RT_BITMAP, toolbar_images

    resource toolbar_images, \
             TOOL_MOVE, LANG_NEUTRAL, move_icon, \
             TOOL_POINT, LANG_NEUTRAL, point_icon, \
             TOOL_SEGMENT, LANG_NEUTRAL, segment_icon, \
             TOOL_CIRCLE_WITH_CENTER, LANG_NEUTRAL, circle_with_center_icon, \
             TOOL_LINE, LANG_NEUTRAL, line_icon

    bitmap move_icon, 'icons/move.bmp'
    bitmap point_icon, 'icons/point.bmp'
    bitmap segment_icon, 'icons/segment.bmp'
    bitmap circle_with_center_icon, 'icons/circle_with_center.bmp'
    bitmap line_icon, 'icons/line_icon.bmp'

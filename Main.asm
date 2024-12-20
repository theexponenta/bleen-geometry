format PE GUI 5.0
entry WinMain

include 'win32w.inc'
include './Equates/GDI.inc'
include './Equates/Winuser.inc'
include 'DataStructures/Vector.inc'
include 'DataStructures/HeterogenousVector.inc'
include 'DataStructures/LinkedList.inc'
include 'DataStructures/ByteArray.inc'
include 'Objects/Objects.inc'
include 'ObjectsAddProc.asm'
include 'Tools/Tools.inc'
include 'Windows/ObjectSettings.inc'
include 'Utils/MathParser/MathParser.inc'
include 'ChangeHistory/ChangeHistory.inc'


section '.text' code readable executable


proc WinMain
    local Msg MSG
    local CW dw ?

    invoke GetProcessHeap
    mov [hProcessHeap], eax

    fstcw [CW]
    mov ax, [CW]
    and ax, 1111_1100_1111_1111b
    or ax, 11b shl 8
    mov [CW], ax
    fldcw [CW]
    
    mov ebx, Objects
    stdcall HeterogenousVector.Create, 4096

    mov ebx, SelectedObjectsIds
    stdcall Vector.Create, 4, 0, 40
    mov ebx, SelectedObjectsPtrs
    stdcall Vector.Create, 4, 0, 40

    mov ebx, Points
    stdcall Vector.Create, sizeof.Point, 0, 26

    mov ebx, MainHistory
    stdcall ChangeHistory.Create, ChangeHistory.InitialCapacity
    mov ebx, TempHistory
    stdcall ChangeHistory.Create, ChangeHistory.InitialCapacity

    mov ebx, ObjectSettingsWindow.Controls
    stdcall Vector.Create, sizeof.ObjectFieldInputControl, 0, ObjectSettingsWindow.Controls.InitialCapacity

    mov ebx, ObjectSettingsWindow.TrackbarsValueControls
    stdcall Vector.Create, sizeof.TrackbarValueControl, 0, ObjectSettingsWindow.TrackbarsValueControls.InitialCapacity

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

    invoke LoadCursor, NULL, IDC_SIZEWE
    mov [MainWindow.hSplitterCursor], eax

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

    mov [WindowClass.lpfnWndProc], ObjectsListWindow.WindowProc
    mov [WindowClass.lpszClassName], ObjectsListWindow.wcexClass.ClassName
    mov [WindowClass.hbrBackground], COLOR_BTNFACE + 1
    mov [WindowClass.style], CS_DBLCLKS
    invoke RegisterClassEx, WindowClass
    test eax, eax
    jz .Error

    mov [WindowClass.style], 0
    mov [WindowClass.lpfnWndProc], ObjectSettingsWindow.WindowProc
    mov [WindowClass.lpszClassName], ObjectSettingsWindow.wcexClass.ClassName
    mov [WindowClass.hbrBackground], COLOR_BTNFACE + 1
    invoke RegisterClassEx, WindowClass
    test eax, eax
    jz .Error

    mov [WindowClass.style], 0
    mov [WindowClass.lpfnWndProc], PlotEquationInputWindow.WindowProc
    mov [WindowClass.lpszClassName], PlotEquationInputWindow.wcexClass.ClassName
    mov [WindowClass.hbrBackground], COLOR_BTNFACE + 1
    invoke RegisterClassEx, WindowClass
    test eax, eax
    jz .Error

    mov [WindowClass.lpfnWndProc], ObjectSettingsWindow.ColorPickerWindowProc
    mov [WindowClass.lpszClassName], ObjectSettingsWindow.ColorPickerWndClassName
    invoke LoadCursor, NULL, IDC_HAND
    mov [WindowClass.hCursor], eax
    invoke RegisterClassEx, WindowClass
    test eax, eax
    jz .Error

    stdcall Main.CreateWindows

    lea edi, [Msg]
    .MessageLoop:
        invoke GetMessage, edi, NULL, 0, 0
        test eax, eax
        jz .EndLoop

        invoke TranslateMessage, edi
        invoke DispatchMessage, edi
        jmp .MessageLoop

    .Error:
        invoke MessageBox, NULL, Error, NULL, MB_ICONERROR + MB_OK

    .EndLoop:
        invoke ExitProcess, [Msg.wParam]
endp


proc Main.CreateWindows
    locals
        ClientRect RECT ?
        ClientWidth dd ?
        ClientHeight dd ?
    endl

    invoke LoadMenuA, [hInstance], IDR_MENU
    mov [MainWindow.hMainMenu], eax
    invoke CreateWindowEx, 0, MainWindow.wcexClass.ClassName, MainWindow.Title, WS_OVERLAPPEDWINDOW, \
                           0, 0, eax, edx, NULL, eax, [hInstance], NULL

    mov [MainWindow.hwnd], eax
    invoke ShowWindow, eax, SW_MAXIMIZE

    lea edx, [ClientRect]
    invoke GetClientRect, [MainWindow.hwnd], edx

    mov eax, [ClientRect.right]
    sub eax, [ClientRect.left]
    mov [ClientWidth], eax
    mov [DrawArea.Width], eax

    mov edx, [ClientRect.bottom]
    sub edx, [ClientRect.top]
    mov [ClientHeight], edx

    sub edx, MainWindow.ToolbarHeight
    mov [DrawArea.Height], edx

    stdcall Main.InitTransformParams

    mov ecx, [ObjectsListWindow.Width]
    add ecx, MainWindow.SplitterBarWidth
    invoke CreateWindowEx, 0, DrawArea.wcexClass.ClassName, NULL, WS_CHILD or WS_VISIBLE, ecx, \
                           MainWindow.ToolbarHeight, eax, edx, [MainWindow.hwnd], NULL, [hInstance], NULL

    mov [DrawArea.hwnd], eax
    stdcall DrawArea.Clear, [DrawArea.MainBufferDC]

    mov eax, [ClientHeight]
    sub eax, MainWindow.ToolbarHeight
    mov [ObjectsListWindow.Height], eax
    invoke CreateWindowEx, 0, ObjectsListWindow.wcexClass.ClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER, 0, MainWindow.ToolbarHeight, \
                           [ObjectsListWindow.Width], [DrawArea.Height], [MainWindow.hwnd], NULL, [hInstance], NULL

    mov [ObjectsListWindow.hWnd], eax

    ret
endp


proc Main.InitTransformParams
    fild [DrawArea.Width]
    fisub [ObjectsListWindow.Width]
    fld [InitialXWidth]
    fdivp
    fstp [Scale]

    fld1
    fadd st0, st0
    fild [DrawArea.Width]
    fisub [ObjectsListWindow.Width]
    fdiv st0, st1
    fstp [Translate.x]
    fild [DrawArea.Height]
    fdiv st0, st1
    fstp [Translate.y]
    fstp st0

    ret
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


; A tool must call this function after it finished adding object
proc Main.ToolAddedObject
    mov byte [ObjectsListWindow.NeedsRedraw], 1
    stdcall Main._MergeTempAndMainHistory
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
    fsubr [Translate.y]
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
    fld [Translate.y]
    fsub [Y]
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

    mov edi, ecx
    sub edi, 1
    shl edi, 2
    add edi, [Objects.Sizes.Ptr]
    mov ebx, [Objects.Ptr]
    add ebx, [Objects.TotalSize]
    sub ebx, [edi]

    .FindLoop:
        cmp byte [ebx + GeometryObject.IsHidden], 0
        jne @F

        movzx eax, byte [ebx + GeometryObject.Type]
        dec eax
        shl eax, 2
        add eax, Objects.IsOnPositionProcedures
        push ecx
        stdcall dword [eax], [X], [Y]
        pop ecx
        test eax, eax
        jnz .ReturnFound

        @@:
        sub edi, HeterogenousVector.BytesForElementSize
        sub ebx, [edi]
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
    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .UnselectPoints
    mov edx, [Objects.Sizes.Ptr]
    mov eax, [Objects.Ptr]
    .UnselectObjectLoop:
        mov byte [eax + GeometryObject.IsSelected], 0
        add eax, [edx]
        add edx, 4
        loop .UnselectObjectLoop

    .UnselectPoints:
    mov ecx, [Points.Length]
    test ecx, ecx
    jz @F
    mov eax, [Points.Ptr]
    .UnselectPointsLoop:
        mov byte [eax + Point.IsSelected], 0
        add eax, sizeof.Point
        loop .UnselectPointsLoop

    @@:
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


proc Main._MarkDependtendPointsToDelete uses ebx, Id
    mov ecx, [Points.Length]
    test ecx, ecx
    jz .Return

    mov ebx, [Points.Ptr]
    .MarkPointsLoop:
        cmp [ebx + GeometryObject.ToBeDeleted], 0
        jne .NextIteration

        push ecx

        stdcall GeometryObject.DependsOnObject, [Id]
        test eax, eax
        jz @F

        mov byte [ebx + GeometryObject.ToBeDeleted], 1
        stdcall Main.MarkDependentObjectsToDelete, [ebx + GeometryObject.Id]

        @@:
        pop ecx

        .NextIteration:
        add ebx, sizeof.Point
        loop .MarkPointsLoop

    .Return:
    ret
endp


proc Main.MarkDependentObjectsToDelete uses ebx, Id
    stdcall Main._MarkDependtendPointsToDelete, [Id]

    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .Return

    mov ebx, [Objects.Ptr]
    mov edx, [Objects.Sizes.Ptr]
    .MarkObjectsToDeleteLoop:
        push edx ecx
        stdcall GeometryObject.DependsOnObject, [Id]
        test eax, eax
        jz .NextIteration

        movzx eax, [ebx + GeometryObject.Type]
        stdcall GeometryObject.IsDependableObjectType, eax
        test eax, eax
        jz @F

        stdcall Main.MarkDependentObjectsToDelete, [ebx + GeometryObject.Id]

        @@:
        stdcall GeometryObject.Destroy
        mov byte [ebx + GeometryObject.ToBeDeleted], 1

        .NextIteration:
        pop ecx edx
        add ebx, [edx]
        add edx, 4
        loop .MarkObjectsToDeleteLoop

    .Return:
    ret
endp


proc Main._DeleteObjectByIndex uses ebx, Index
    mov ebx, Objects
    stdcall HeterogenousVector.PtrByIndex, [Index]
    mov ebx, eax
    stdcall GeometryObject.Destroy
    mov ebx, Objects
    stdcall HeterogenousVector.DeleteByIndex, [Index]

    ret
endp


proc Main.DeleteObjectById uses ebx esi edi, Id
    locals
        ObjectIndex dd ?
        IsPoint db ?
    endl

    mov ebx, MainHistory
    stdcall ChangeHistory.StartNewGroup

    mov [IsPoint], 0
    mov eax, [Id]
    stdcall Main.FindPointIndexById
    cmp eax, -1
    je .TryDeleteAnotherObject

    mov [IsPoint], 1
    mov [ObjectIndex], eax
    mov esi, OBJ_POINT
    jmp @F

    .TryDeleteAnotherObject:
    stdcall Main.GetObjectIndexById, [Id]
    cmp eax, -1
    je .Return

    mov [ObjectIndex], eax
    movzx esi, byte [edx + GeometryObject.Type]

    @@:
    stdcall ChangeHistory.AddChange, ChangeHistoryRecord.Type.DELETE_OBJECT, edx
    stdcall GeometryObject.IsDependableObjectType, esi
    test eax, eax
    jnz .MarkDependentObjects
    cmp esi, OBJ_POLYGON
    jne .DeleteRequestedObject

    .MarkDependentObjects:
    cmp [Objects.Sizes.Length], 0
    je .DeleteRequestedObject
    stdcall Main.MarkDependentObjectsToDelete, [Id]

    .DeleteRequestedObject:
    cmp [IsPoint], 0
    je @F

    mov ebx, Points
    stdcall Vector.DeleteByIndex, [ObjectIndex]
    jmp .DeleteMarkedObjects

    @@:
    stdcall Main._DeleteObjectByIndex, [ObjectIndex]

    .DeleteMarkedObjects:
    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz .DeleteMarkedPoints

    mov edi, [Objects.Ptr]
    mov edx, [Objects.Sizes.Ptr]
    mov ebx, Objects
    xor eax, eax
    .DeleteMarkedObjectsLoop:
        cmp byte [edi + GeometryObject.ToBeDeleted], 0
        je @F

        push eax ecx edx
        push eax
        mov ebx, MainHistory
        stdcall ChangeHistory.AddChange, ChangeHistoryRecord.Type.DELETE_OBJECT, edi
        pop eax
        mov ebx, Objects
        stdcall Main._DeleteObjectByIndex, eax
        pop edx ecx eax
        jmp .ObjectDeleted

        @@:
        add edi, [edx]
        add edx, 4
        inc eax

        .ObjectDeleted:
        loop .DeleteMarkedObjectsLoop

    .DeleteMarkedPoints:
    mov ecx, [Points.Length]
    test ecx, ecx
    jz .Return

    mov edi, [Points.Ptr]
    mov ebx, Points
    xor esi, esi
    .DeleteMarkedPointsLoop:
        cmp byte [edi + GeometryObject.ToBeDeleted], 0
        je @F

        push ecx
        mov ebx, MainHistory
        stdcall ChangeHistory.AddChange, ChangeHistoryRecord.Type.DELETE_OBJECT, edi
        mov ebx, Points
        stdcall Vector.DeleteByIndex, esi
        pop ecx
        jmp .PointDeleted

        @@:
        add edi, sizeof.Point
        add esi, 1
        .PointDeleted:
        loop .DeleteMarkedPointsLoop

    mov byte [ObjectsListWindow.NeedsRedraw], 1

    .Return:
    ret
endp


proc Main._DeleteOnlyOneObjectById uses ebx, Id
    mov eax, [Id]
    stdcall Main.FindPointIndexById
    cmp eax, -1
    je .NotAPoint

    mov ebx, Points
    stdcall Vector.DeleteByIndex, eax
    jmp .Return

    .NotAPoint:
    stdcall Main.GetObjectIndexById, [Id]
    cmp eax, -1
    je .Return

    stdcall Main._DeleteObjectByIndex, eax

    .Return:
    ret
endp


proc Main._DeletePointsWithIntersectionId uses ebx edi esi, IntersectionId
    mov ecx, [Points.Length]
    test ecx, ecx
    jz .Return

    mov esi, [IntersectionId]
    mov edi, [Points.Ptr]
    mov ebx, Points
    xor eax, eax
    .DeleteLoop:
        cmp [edi + Point.IntersectionId], esi
        jne @F

        push eax ecx
        stdcall Vector.DeleteByIndex, eax
        pop ecx eax
        jmp .PointDeleted

        @@:
        add edi, sizeof.Point
        inc eax
        .PointDeleted:
        loop .DeleteLoop

    .Return:
    ret
endp


proc Main.DestroyAll uses ebx esi
    mov ebx, [Points.Ptr]
    mov ecx, [Points.Length]
    test ecx, ecx
    jz @F

    .PointLoop:
        push ecx
        stdcall GeometryObject.Destroy
        pop ecx

        add ebx, sizeof.Point
        loop .PointLoop

    @@:
    mov ebx, Points
    stdcall Vector.Destroy

    mov ecx, [Objects.Sizes.Length]
    test ecx, ecx
    jz @F

    mov ebx, [Objects.Ptr]
    mov esi, [Objects.Sizes.Ptr]
    .ObjectsLoop:
        push ecx
        stdcall GeometryObject.Destroy
        pop ecx

        add ebx, [esi]
        add esi, 4
        loop .ObjectsLoop

    @@:
    mov ebx, Objects
    stdcall HeterogenousVector.Destroy

    mov ebx, SelectedObjectsIds
    stdcall Vector.Destroy

    mov ebx, SelectedObjectsPtrs
    stdcall Vector.Destroy

    mov ebx, MainHistory
    stdcall ChangeHistory.Clear

    mov ebx, TempHistory
    stdcall ChangeHistory.Clear

    ret
endp


proc Main.SetOpenedFile uses esi edi, pFilename
    cld
    mov ecx, MAX_FILENAME_LENGTH / 4
    mov esi, [pFilename]
    mov edi, OpenFileName
    rep movsd

    mov [FileOpened], 1

    invoke EnableMenuItem, [MainWindow.hMainMenu], IDM_SAVE, MF_ENABLED

    ret
endp


proc Main.StartNewTempChangeGroup uses ebx
    mov ebx, TempHistory
    stdcall ChangeHistory.StartNewGroup

    ret
endp


proc Main._UndoChange uses ebx, pChangeRecord
    mov eax, [pChangeRecord]
    movzx edx, byte [eax + ChangeHistoryRecord.Type]
    mov eax, [eax + ChangeHistoryRecord.Object.Ptr]
    mov byte [eax + GeometryObject.ToBeDeleted], 0

    cmp edx, ChangeHistoryRecord.Type.ADD_OBJECT
    jne @F

    push eax
    stdcall Main._DeleteOnlyOneObjectById, [eax + GeometryObject.Id]
    pop eax

    cmp byte [eax + GeometryObject.Type], OBJ_INTERSECTION
    jne .Return

    stdcall Main._DeletePointsWithIntersectionId, [eax + GeometryObject.Id]

    jmp .Return

    @@:
    cmp edx, ChangeHistoryRecord.Type.DELETE_OBJECT
    jne @F

    movzx edx, byte [eax + GeometryObject.Type]

    cmp edx, OBJ_POINT
    jne .NotAPoint

    mov ebx, Points
    stdcall Vector.Push, eax
    jmp .Return

    .NotAPoint:
    mov ecx, edx
    dec ecx
    shl ecx, 2
    add ecx, Objects.StructSizes

    mov ebx, Objects
    stdcall HeterogenousVector.Push, eax, [ecx]

    @@:
    .Return:
    ret
endp


proc Main._UndoHistory uses ebx esi edi, pHistory
    mov ebx, [pHistory]

    mov eax, [ebx + ChangeHistory.History.Length]
    test eax, eax
    jz .Return

    mov ecx, eax
    mov esi, [ebx + ChangeHistory.History.Ptr]
    dec eax
    imul eax, sizeof.ChangeHistoryRecord
    add esi, eax
    mov edi, [esi + ChangeHistoryRecord.GroupId]

    .UndoLoop:
        push ecx
        stdcall Main._UndoChange, esi
        stdcall ChangeHistory.PopOne
        pop ecx
        sub esi, sizeof.ChangeHistoryRecord

        mov eax, [esi + ChangeHistoryRecord.GroupId]
        cmp edi, eax
        jne .Return

        mov edi, eax
        loop .UndoLoop

    .Return:
    ret
endp


proc Main._MergeTempAndMainHistory uses ebx esi edi
    mov ebx, MainHistory
    stdcall ChangeHistory.StartNewGroup
    mov edi, eax

    mov esi, [TempHistory.History.Ptr]
    mov ecx, [TempHistory.History.Length]
    .MergeLoop:
        push ecx
        mov [esi + ChangeHistoryRecord.GroupId], edi
        stdcall ChangeHistory.AddChangeRecord, esi
        pop ecx

        add esi, sizeof.ChangeHistoryRecord
        loop .MergeLoop

    mov ebx, TempHistory
    stdcall ChangeHistory.ClearNoDestroy

    ret
endp


proc Main.UndoMainHistory
    stdcall Main._UndoHistory, MainHistory
    ret
endp


proc Main.UndoTempHistory uses ebx
    stdcall Main._UndoHistory, TempHistory

    mov ebx, TempHistory
    stdcall ChangeHistory.Clear

    ret
endp


proc Main.ClearTempHistory uses ebx
    mov ebx, TempHistory
    stdcall ChangeHistory.Clear

    ret
endp


include 'Utils/Draw.asm'
include 'Utils/Math.asm'
include 'Utils/Strings.asm'
include 'Utils/MathParser/MathParser.asm'
include 'DataStructures/Vector.asm'
include 'DataStructures/HeterogenousVector.asm'
include 'DataStructures/LinkedList.asm'
include 'DataStructures/ByteArray.asm'
include 'Windows/Main.asm'
include 'Windows/DrawArea.asm'
include 'Windows/ObjectSettings.asm'
include 'Windows/ObjectsList.asm'
include 'Windows/PlotEquationInput.asm'
include 'Objects/Objects.asm'
include 'Tools/Tools.asm'
include 'Utils/FileIO/Writer.asm'
include 'Utils/FileIO/Reader.asm'
include 'ChangeHistory/ChangeHistory.asm'


section '.data' data readable writeable

  hInstance dd ?
  hProcessHeap dd ?

  Error du 'Error', 0

  TOOLBARCLASSNAME du TOOLBAR_CLASS, 0
  TRACKBARCLASSNAME du TRACKBAR_CLASS, 0
  STATICCLASSNAME du "static", 0
  EDITCLASSNAME du "edit", 0
  BUTTONCLASSNAME du "button", 0
  EDITCLASSNAME_ASCII db "edit", 0

  WindowClass WNDCLASSEX sizeof.WNDCLASSEX, 0, NULL, 0, 0, NULL, NULL, NULL, \
                         COLOR_BTNFACE + 1, NULL, NULL

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

  CurrentMouseScreenPoint Point 0, OBJ_POINT, 0, 0, 0, 0, 0, 0, 0f, 0f
  CurrentMousePlanePoint Point 0, OBJ_POINT, 0, 0, 0, 0, 0, 0, 0f, 0f

  Translate POINT 0f, 0f
  Scale dd 1.0
  ScaleStepCoefficient dq 1.1f

  InitialXWidth dd 30f
  MinDistanceBetweenTicks dd 50
  MaxGridSnapDistance dd 15f

  CtrlKeyPressed dd 0

  ShowAxes dd 0
  ShowGrid dd 0
  SnapToGrid dd 1
  AxesAndGridNeedRedraw dd 1

  MaxInt dd 2147483647

  MAX_FILENAME_LENGTH = 256
  FileOpened db 0
  OpenFileName du MAX_FILENAME_LENGTH dup(?)

  MainHistory ChangeHistory ?
  TempHistory ChangeHistory ?

  include 'Windows/Main.d'
  include 'Windows/DrawArea.d'
  include 'Windows/ObjectSettings.d'
  include 'Windows/ObjectsList.d'
  include 'Windows/PlotEquationInput.d'
  include 'Tools/Tools.d'
  include 'Objects/Objects.d'
  include 'Utils/MathParser/MathParser.d'

section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
          user32, 'USER32.DLL',\
          comctl32, 'COMCTL32.DLL', \
          comctl32_, 'COMCTL32.DLL', \
          gdi32, 'GDI32.DLL', \
          gdiplus, 'GDIPLUS.dll', \
          msvcrt, 'msvcrt.dll', \
          comdlg32, 'Comdlg32.dll'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  include 'api\comctl32.inc'
  include 'api\gdi32.inc'

  import msvcrt, \
         sprintf, 'sprintf', \
         swprintf, 'swprintf'

  import comdlg32, \
         ChooseColorW, 'ChooseColorW', \
         GetSaveFileNameW, 'GetSaveFileNameW', \
         GetOpenFileNameW, 'GetOpenFileNameW'

  import comctl32_, \
         DefSubclassProc, 'DefSubclassProc', \
         SetWindowSubclass, 'SetWindowSubclass'


section '.rsrc' resource data readable

    directory RT_BITMAP, toolbar_images, \
              RT_MENU, menus

    resource toolbar_images, \
             TOOL_MOVE, LANG_NEUTRAL, move_icon, \
             TOOL_POINT, LANG_NEUTRAL, point_icon, \
             TOOL_SEGMENT, LANG_NEUTRAL, segment_icon, \
             TOOL_CIRCLE_WITH_CENTER, LANG_NEUTRAL, circle_with_center_icon, \
             TOOL_LINE, LANG_NEUTRAL, line_icon, \
             TOOL_ELLIPSE, LANG_NEUTRAL, ellipse_icon, \
             TOOL_POLYLINE, LANG_NEUTRAL, polyline_icon, \
             TOOL_POLYGON, LANG_NEUTRAL, polygon_icon, \
             TOOL_PARABOLA, LANG_NEUTRAL, parabola_icon, \
             TOOL_INTERSECTION, LANG_NEUTRAL, intersection_icon, \
             TOOL_ANGLE_BISECTOR, LANG_NEUTRAL, angle_bisector_icon, \
             TOOL_PERPENDICULAR, LANG_NEUTRAL, perpendicular_icon, \
             TOOL_PERPENDICULAR_BISECTOR, LANG_NEUTRAL, perpendicular_bisector_icon, \
             TOOL_PARALLEL_LINE, LANG_NEUTRAL, parallel_line_icon, \
             TOOL_PLOT, LANG_NEUTRAL, plot_icon, \
             TOOL_MIDPOINT_OR_CENTER, LANG_NEUTRAL, midpoint_or_center_icon

    bitmap move_icon, 'icons/move.bmp'
    bitmap point_icon, 'icons/point.bmp'
    bitmap segment_icon, 'icons/segment.bmp'
    bitmap circle_with_center_icon, 'icons/circle_with_center.bmp'
    bitmap line_icon, 'icons/line_icon.bmp'
    bitmap ellipse_icon, 'icons/ellipse_icon.bmp'
    bitmap polyline_icon, 'icons/polyline_icon.bmp'
    bitmap polygon_icon, 'icons/polygon_icon.bmp'
    bitmap parabola_icon, 'icons/parabola_icon.bmp'
    bitmap intersection_icon, 'icons/intersection_icon.bmp'
    bitmap angle_bisector_icon, 'icons/angle_bisector_icon.bmp'
    bitmap perpendicular_icon, 'icons/perpendicular_icon.bmp'
    bitmap perpendicular_bisector_icon, 'icons/perpendicular_bisector_icon.bmp'
    bitmap parallel_line_icon, 'icons/parallel_line_icon.bmp'
    bitmap midpoint_or_center_icon, 'icons/midpoint_or_center_icon.bmp'
    bitmap plot_icon, 'icons/plot_icon.bmp'

    IDR_MENU = 3

    resource menus,\
             IDR_MENU, LANG_ENGLISH+SUBLANG_DEFAULT, main_menu

    MENU_BIT = 2 shl 7
    IDM_OPEN = 1 or MENU_BIT
    IDM_SAVE = 2 or MENU_BIT
    IDM_SAVE_AS = 3 or MENU_BIT
    IDM_EXIT = 4 or MENU_BIT

    menu main_menu
        menuitem '&File', 0, MFR_POPUP + MFR_END
                 menuitem '&Open', IDM_OPEN
                 menuitem <'&Save', 9, 'Ctrl+S'>, IDM_SAVE, , MFS_GRAYED
                 menuitem '&Save as', IDM_SAVE_AS
                 menuitem 'E&xit', IDM_EXIT, MFR_END


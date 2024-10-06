

proc MoveTool.SelectObjects
    mov [MoveTool.WasMoved], 0

    stdcall Main.GetObjectOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .SetTranslateCanvas

    cmp [eax + GeometryObject.IsSelected], 0
    jne .ObjectSelected

    cmp [CtrlKeyPressed], 0
    jne .SelectObejct
    push eax
    stdcall Main.UnselectObjects
    pop eax

    .SelectObejct:
    mov [eax + GeometryObject.IsSelected], 1
    stdcall Main.AddSelectedObject, eax

    .ObjectSelected:
    mov [CurrentStateId], MoveTool.States.MoveObjects
    jmp .Finish

    .SetTranslateCanvas:
    mov [CurrentStateId], MoveTool.States.TranslateCanvas

    .Finish:
    mov eax, [CurrentMouseScreenPoint.X]
    mov [MoveTool.PrevPoint.x], eax
    mov eax, [CurrentMouseScreenPoint.Y]
    mov [MoveTool.PrevPoint.y], eax
    ret
endp


proc MoveTool.SetSelectObjects
    cmp [CurrentStateId], MoveTool.States.TranslateCanvas
    jne @F
    cmp [MoveTool.WasMoved], 0
    jne @F

    stdcall Main.UnselectObjects

    @@:
    mov [CurrentStateId], MoveTool.States.SelectObjects
    ret
endp


proc MoveTool.TranslateCanvas
    mov [AxesAndGridNeedRedraw], 1
    mov [MoveTool.WasMoved], 1

    fld [CurrentMouseScreenPoint.X]
    fsub [MoveTool.PrevPoint.x]
    fadd [Translate.x]
    fstp [Translate.x]

    fld [CurrentMouseScreenPoint.Y]
    fsub [MoveTool.PrevPoint.y]
    fadd [Translate.y]
    fstp [Translate.y]

    mov eax, [CurrentMouseScreenPoint.X]
    mov [MoveTool.PrevPoint.x], eax
    mov eax, [CurrentMouseScreenPoint.Y]
    mov [MoveTool.PrevPoint.y], eax

    ret
endp


proc MoveTool.MoveObjects uses ebx edi esi
    locals
        deltaX dd ?
        deltaY dd ?
    endl

    mov [AxesAndGridNeedRedraw], 1
    mov [MoveTool.WasMoved], 1

    fld [CurrentMouseScreenPoint.X]
    fsub [MoveTool.PrevPoint.x]
    fld [CurrentMouseScreenPoint.Y]
    fsub [MoveTool.PrevPoint.y]
    fld [Scale]
    fdiv st1, st0
    fdiv st2, st0
    fstp st0
    fstp [deltaY]
    fstp [deltaX]

    mov ecx, [SelectedObjectsPtrs.Length]
    mov edi, [SelectedObjectsPtrs.ElementSize]
    mov esi, [SelectedObjectsPtrs.Ptr]
    .MoveLoop:
        push ecx
        mov ebx, [esi]
        mov edx, [deltaX]
        mov ecx, [deltaY]
        stdcall GeometryObject.Move
        pop ecx

        add esi, edi
        loop .MoveLoop

    mov eax, [CurrentMouseScreenPoint.X]
    mov [MoveTool.PrevPoint.x], eax
    mov eax, [CurrentMouseScreenPoint.Y]
    mov [MoveTool.PrevPoint.y], eax

    .Return:
    ret
endp


proc MoveTool.DeleteSelectedObjects uses ebx edi esi
    mov ecx, [SelectedObjectsIds.Length]
    test ecx, ecx
    jz .Return

    mov edi, [SelectedObjectsIds.ElementSize]
    mov esi, [SelectedObjectsIds.Ptr]
    .DeleteLoop:
        push ecx
        stdcall Main.GetObjectById, [esi]
        test eax, eax
        jz @F

        stdcall Main.DeleteObjectById, [eax + GeometryObject.Id]

        @@:
        pop ecx
        add esi, edi
        loop .DeleteLoop

    stdcall Main.UnselectObjects

    .Return:
    ret
endp


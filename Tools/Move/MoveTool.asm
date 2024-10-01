

proc MoveTool.SelectObject
    stdcall Main.UnselectObjects

    stdcall Main.GetObjectOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .SetTranslateCanvas

    mov [MoveTool.pSelectedObject], eax
    mov [eax + GeometryObject.IsSelected], 1

    stdcall Main.AddSelectedObject, eax

    mov [CurrentStateId], MoveTool.States.MoveObject
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


proc MoveTool.SetSelectObject
    mov [CurrentStateId], MoveTool.States.SelectObject
    ret
endp


proc MoveTool.TranslateCanvas
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


proc MoveTool.MoveObject uses ebx
    locals
        deltaX dd ?
        deltaY dd ?
    endl

    mov ebx, [MoveTool.pSelectedObject]
    test ebx, ebx
    jz .Return

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

    mov edx, [deltaX]
    mov ecx, [deltaY]
    stdcall GeometryObject.Move

    mov eax, [CurrentMouseScreenPoint.X]
    mov [MoveTool.PrevPoint.x], eax
    mov eax, [CurrentMouseScreenPoint.Y]
    mov [MoveTool.PrevPoint.y], eax

    .Return:
    ret
endp


proc MoveTool.DeleteSelectedObjects uses ebx edi esi
    mov ecx, [SelectedObjects.Length]
    test ecx, ecx
    jz .Return

    mov edi, [SelectedObjects.ElementSize]
    mov esi, [SelectedObjects.Ptr]
    .DeleteLoop:
        push ecx
        mov eax, [esi]
        stdcall Main.DeleteObjectById, [eax + GeometryObject.Id]
        pop ecx
        add esi, edi
        loop .DeleteLoop

    stdcall Main.UnselectObjects

    .Return:
    ret
endp


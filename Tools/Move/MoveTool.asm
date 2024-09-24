

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
    locals
        deltaX dd ?
        deltaY dd ?
    endl

    mov edx, [CurrentMouseScreenPoint.X]
    sub edx, [MoveTool.PrevPoint.x]
    mov ecx, [CurrentMouseScreenPoint.Y]
    sub ecx, [MoveTool.PrevPoint.y]

    add [Translate.x], edx
    add [Translate.y], ecx

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

    mov edx, [CurrentMouseScreenPoint.X]
    sub edx, [MoveTool.PrevPoint.x]
    mov ecx, [CurrentMouseScreenPoint.Y]
    sub ecx, [MoveTool.PrevPoint.y]

    mov [deltaX], edx
    mov [deltaY], ecx
    fild [deltaX]
    fild [deltaY]
    fld [Scale]
    fdiv st1, st0
    fdiv st2, st0
    fstp st0
    fistp [deltaY]
    fistp [deltaX]

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


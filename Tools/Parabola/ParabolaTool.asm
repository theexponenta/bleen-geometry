
proc ParabolaTool.SelectDirectrix
    mov eax, [NextObjectId]
    mov [ParabolaTool.NextObjectIdBeforeTool], eax

    stdcall Main.GetObjectOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .Return

    movzx edx, byte [eax + GeometryObject.Type]
    cmp edx, OBJ_LINE
    je @F
    cmp edx, OBJ_SEGMENT
    jne .Return

    @@:
    mov [ParabolaTool.pDirectrixLineObject], eax
    mov [CurrentStateId], ParabolaTool.States.SelectFocus
    mov byte [eax + GeometryObject.IsSelected], 1

    .Return:
    ret
endp


proc ParabolaTool.SelectFocus uses esi
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz @F

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    @@:
    mov esi, [ParabolaTool.pDirectrixLineObject]
    stdcall Main.AddParabola, [eax + Point.Id], [esi + GeometryObject.Id]
    mov byte [esi + GeometryObject.IsSelected], 0
    mov [CurrentStateId], ParabolaTool.States.SelectDirectrix
    mov [ParabolaTool.NextObjectIdBeforeTool], 0

    .Return:
    ret
endp


proc ParabolaTool.Cancel
    ret
endp

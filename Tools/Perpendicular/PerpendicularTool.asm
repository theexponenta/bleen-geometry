
proc PerpendicularTool.SelectLine
    mov eax, [NextObjectId]
    mov [PerpendicularTool.NextObjectIdBeforeTool], eax

    stdcall Main.GetObjectOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .Return

    movzx edx, byte [eax + GeometryObject.Type]
    push eax
    stdcall GeometryObject.IsLineObjectType, edx
    pop eax
    test eax, eax
    jz .Return

    @@:
    mov [PerpendicularTool.pLineObject], eax
    mov [CurrentStateId], PerpendicularTool.States.SelectPoint
    mov byte [eax + GeometryObject.IsSelected], 1

    .Return:
    ret
endp


proc PerpendicularTool.SelectPoint uses esi
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz @F

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    @@:
    mov esi, [PerpendicularTool.pLineObject]
    stdcall Main.AddPerpendicular, [eax + Point.Id], [esi + GeometryObject.Id]
    mov byte [esi + GeometryObject.IsSelected], 0
    mov [PerpendicularTool.pLineObject], 0
    mov [CurrentStateId], PerpendicularTool.States.SelectLine
    mov [PerpendicularTool.NextObjectIdBeforeTool], 0

    stdcall Main.ToolAddedObject

    .Return:
    ret
endp


proc PerpendicularTool.Cancel
    mov eax, [PerpendicularTool.pLineObject]
    test eax, eax
    je @F

    mov byte [eax + GeometryObject.IsSelected], 0
    mov [PerpendicularTool.pLineObject], 0
    mov [PerpendicularTool.NextObjectIdBeforeTool], 0

    @@:
    mov [CurrentStateId], PerpendicularTool.States.SelectLine
    ret
endp

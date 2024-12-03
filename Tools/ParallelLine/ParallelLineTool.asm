
proc ParallelLineTool.SelectLine
    mov eax, [NextObjectId]
    mov [ParallelLineTool.NextObjectIdBeforeTool], eax

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
    mov [ParallelLineTool.pLineObject], eax
    mov [CurrentStateId], ParallelLineTool.States.SelectPoint
    mov byte [eax + GeometryObject.IsSelected], 1

    .Return:
    ret
endp


proc ParallelLineTool.SelectPoint uses esi
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz @F

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    @@:
    mov esi, [ParallelLineTool.pLineObject]
    stdcall Main.AddParallelLine, [eax + Point.Id], [esi + GeometryObject.Id]
    mov byte [esi + GeometryObject.IsSelected], 0
    mov [ParallelLineTool.pLineObject], 0
    mov [CurrentStateId], ParallelLineTool.States.SelectLine
    mov [ParallelLineTool.NextObjectIdBeforeTool], 0

    stdcall Main.ToolAddedObject

    .Return:
    ret
endp


proc ParallelLineTool.Cancel
    mov eax, [ParallelLineTool.pLineObject]
    test eax, eax
    je @F

    mov byte [eax + GeometryObject.IsSelected], 0
    mov [ParallelLineTool.pLineObject], 0
    mov [ParallelLineTool.NextObjectIdBeforeTool], 0

    @@:
    mov [CurrentStateId], ParallelLineTool.States.SelectLine
    ret
endp

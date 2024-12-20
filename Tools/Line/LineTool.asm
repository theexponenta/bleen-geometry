
proc LineTool.SelectPoint1
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .AddSegment

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .AddSegment:
        mov eax, [eax + Point.Id]
        stdcall Main.AddLine, eax, 0
        mov [LineTool.pTempLine], eax

    ret
endp


proc LineTool.Cancel uses ebx
   mov [CurrentStateId], LineTool.States.SelectPoint1
   stdcall Main.UndoTempHistory

   ret
endp


proc LineTool.SetSelectPoint1
    mov [CurrentStateId], LineTool.States.SelectPoint1
    ret
endp


proc LineTool.SetSelectPoint2
    mov [CurrentStateId], LineTool.States.SelectPoint2
    ret
endp


proc LineTool.SelectPoint2
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .SetSecondLinePoint

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .SetSecondLinePoint:
        mov eax, [eax + Point.Id]
        mov edx, [LineTool.pTempLine]
        mov [edx + Line.Point2Id], eax

    stdcall Main.ToolAddedObject
    ret
endp



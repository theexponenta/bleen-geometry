
proc SegmentTool.SelectPoint1
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .AddSegment

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .AddSegment:
        mov eax, [eax + Point.Id]
        stdcall Main.AddSegment, eax, 0, GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor
        mov [SegmentTool.pTempSegment], eax

    ret
endp


proc SegmentTool.Cancel uses ebx
   stdcall Main.UndoTempHistory
   mov [CurrentStateId], SegmentTool.States.SelectPoint1

   ret
endp


proc SegementTool.SetSelectPoint1
    mov [CurrentStateId], SegmentTool.States.SelectPoint1
    ret
endp


proc SegementTool.SetSelectPoint2
    mov [CurrentStateId], SegmentTool.States.SelectPoint2
    ret
endp


proc SegmentTool.SelectPoint2
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .SetSecondSegmentPoint

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .SetSecondSegmentPoint:
        mov eax, [eax + Point.Id]
        mov edx, [SegmentTool.pTempSegment]
        mov [edx + Segment.Point2Id], eax

    stdcall Main.ToolAddedObject

    ret
endp




proc PerpendicularBisectorTool.SelectPointOrSegment
    stdcall Main.GetObjectOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .Return

    movzx edx, [eax + GeometryObject.Type]
    cmp edx, OBJ_SEGMENT
    jne @F

    stdcall Main.AddPerpendicularBisector, [eax + Segment.Point1Id], [eax + Segment.Point2Id]
    jmp .Return

    @@:
    cmp edx, OBJ_POINT
    jne .Return

    mov edx, [eax + Point.Id]
    stdcall Main.AddPerpendicularBisector, edx, 0
    mov [PerpendicularBisectorTool.pTempPerpendicularBisector], eax
    mov [CurrentStateId], PerpendicularBisectorTool.States.SelectSecondPoint

    .Return:
    ret
endp


proc PerpendicularBisectorTool.SelectSecondPoint
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .Return

    mov edx, [PerpendicularBisectorTool.pTempPerpendicularBisector]
    mov eax, [eax + Point.Id]
    mov [edx + PerpendicularBisector.Point2Id], eax
    mov [CurrentStateId], PerpendicularBisectorTool.States.SelectPointOrSegment

    stdcall Main.ToolAddedObject

    .Return:
    ret
endp


proc PerpendicularBisectorTool.Cancel uses ebx
    mov ebx, Objects
    stdcall Vector.Pop

    ret
endp
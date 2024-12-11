
proc MidpointOrCenterTool.SelectObject
    stdcall Main.GetObjectOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .Return

    cmp byte [eax + GeometryObject.Type], OBJ_SEGMENT
    jne .Return

    stdcall Main.AddMidpoint, eax
    stdcall Main.ToolAddedObject

    .Return:
    ret
endp

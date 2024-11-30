
proc PointTool.PlacePoint
    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0
    stdcall Main.ToolAddedObject
    ret
endp


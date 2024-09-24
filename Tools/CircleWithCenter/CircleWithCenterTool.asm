
proc CircleWithCenterTool.SelectCenterPoint
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .AddCircle

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .AddCircle:
        mov eax, [eax + Point.Id]
        stdcall Main.AddCircleWithCenter, eax, 0
        mov [CircleWithCenterTool.pTempCircle], eax

    ret
endp


proc CircleWithCenterTool.SetSelectCenterPoint
    mov [CurrentStateId], CircleWithCenterTool.States.SelectCenterPoint
    ret
endp


proc CircleWithCenterTool.SetSelectSecondPoint
    mov [CurrentStateId], CircleWithCenterTool.States.SelectSecondPoint
    ret
endp


proc CircleWithCenterTool.SelectSecondPoint
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .SetSecondPoint

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .SetSecondPoint:
        mov eax, [eax + Point.Id]
        mov edx, [CircleWithCenterTool.pTempCircle]
        mov [edx + CircleWithCenter.SecondPointId], eax

    ret
endp


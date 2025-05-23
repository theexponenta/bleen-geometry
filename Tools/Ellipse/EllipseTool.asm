
proc EllipseTool.SelectNextPoint
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .PointSelected

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .PointSelected:
        mov eax, [eax + Point.Id]
        mov ecx, [EllipseTool.SelectedPointsCount]
        imul ecx, 4
        mov [EllipseTool.SelectedPointsIds + ecx], eax

        add [EllipseTool.SelectedPointsCount], 1
        mov ecx, [EllipseTool.SelectedPointsCount]

        cmp ecx, 3
        jne @F

        mov edx, [EllipseTool.pTempEllipse]
        mov [edx + EllipseObj.CircumferencePointId], eax
        mov [EllipseTool.SelectedPointsCount], 0
        stdcall Main.ToolAddedObject
        jmp .Return

        @@:
        cmp ecx, 2
        jne .Return

        stdcall Main.AddEllipse, [EllipseTool.SelectedPointsIds], [EllipseTool.SelectedPointsIds + 4], 0
        mov [EllipseTool.pTempEllipse], eax

    .Return:
    ret
endp


proc EllipseTool.Cancel
    mov [EllipseTool.SelectedPointsCount], 0
    stdcall Main.UndoTempHistory

    .Return:
    ret
endp

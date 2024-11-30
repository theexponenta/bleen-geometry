
proc AngleBisectorTool.SelectNextPoint
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .PointSelected

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .PointSelected:
        mov eax, [eax + Point.Id]
        mov edx, [AngleBisectorTool.SelectedPointsCount]
        mov ecx, edx
        shl edx, 2
        mov [AngleBisectorTool.SelectedPointsIds + edx], eax

        add [AngleBisectorTool.SelectedPointsCount], 1
        add ecx, 1

        cmp ecx, 3
        jne @F

        mov [AngleBisectorTool.SelectedPointsCount], 0
        mov edx, [AngleBisectorTool.pTempAngleBisector]
        mov [edx + AngleBisector.Point3Id], eax
        stdcall Main.ToolAddedObject
        jmp .Return

        @@:
        cmp ecx, 2
        jne .Return

        stdcall Main.AddAngleBisector, [AngleBisectorTool.SelectedPointsIds], [AngleBisectorTool.SelectedPointsIds + 4], 0
        mov [AngleBisectorTool.pTempAngleBisector], eax

    .Return:
    ret
endp


proc AngleBisectorTool.Cancel
    mov ecx, [AngleBisectorTool.SelectedPointsCount]
    test ecx, ecx
    jz .Return

    cmp ecx, 2
    jb @F

    mov ebx, Objects
    stdcall HeterogenousVector.Pop

    @@:
    mov ebx, Points
    .DeletePointsLoop:
        stdcall Main.DeleteLastPoint
        loop .DeletePointsLoop

    mov [AngleBisectorTool.SelectedPointsCount], 0

    .Return:
    ret
endp

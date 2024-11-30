
proc PolygonTool.SelectNextPoint uses ebx esi
    cmp [PolygonTool.PolygonId], 0
    jne @F

    mov eax, [NextObjectId]
    mov [PolygonTool.NextObjectIdBeforeTool], eax

    stdcall Main.AddPolygon
    mov edx, [eax + PolygonObj.Id]
    mov [PolygonTool.PolygonId], edx
    mov [PolygonTool.pPolygon], eax

    @@:
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .PointSelected

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .PointSelected:
        mov esi, [eax + Point.Id]
        mov eax, [PolygonTool.pPolygon]
        cmp [eax + PolygonObj.SegmentsIds.Length], 1
        jb .SaveFirstPointId

        mov eax, [PolygonTool.pPrevSegment]
        mov [eax + Segment.Point2Id], esi
        cmp esi, [PolygonTool.FirstPointId]
        jne .AddNextSegment

        mov [PolygonTool.PolygonId], 0
        stdcall Main.ToolAddedObject
        jmp .Return

        .SaveFirstPointId:
        mov [PolygonTool.FirstPointId], esi

        .AddNextSegment:
        stdcall Main.AddSegment, esi, 0, GeometryObject.DefaultLineWidth, PolygonObj.DefaultColor
        mov [PolygonTool.pPrevSegment], eax
        stdcall Main.GetObjectById, [PolygonTool.PolygonId]
        mov [PolygonTool.pPolygon], eax
        mov ebx, eax
        add ebx, PolygonObj.SegmentsIds
        mov eax, [PolygonTool.pPrevSegment]
        stdcall Vector.PushValue, [eax + Segment.Id]

        mov [PolygonTool.PrevPointId], esi

    .Return:
    ret
endp


proc PolygonTool.Cancel uses ebx
    cmp [PolygonTool.PolygonId], 0
    je .Return

    stdcall Main.GetObjectById, [PolygonTool.PolygonId]
    mov [PolygonTool.pPolygon], eax
    mov ecx, [NextObjectId]
    sub ecx, [PolygonTool.NextObjectIdBeforeTool]
    sub ecx, [eax + PolygonObj.SegmentsIds.Length] ; Segments - sides of polygon
    sub ecx, 1 ; The polygon itself

    mov ebx, Points
    .DeletePointsLoop:
        stdcall Main.DeleteLastPoint
        loop .DeletePointsLoop

    mov eax, [PolygonTool.pPolygon]
    mov ecx, [eax + PolygonObj.SegmentsIds.Length]
    add ecx, 1 ; The polygon itself
    mov ebx, Objects
    .DeleteSegementsAndPolygonLoop:
        push ecx
        stdcall HeterogenousVector.Pop
        pop ecx
        loop .DeleteSegementsAndPolygonLoop

    mov [PolygonTool.PolygonId], 0

    .Return:
    ret
endp

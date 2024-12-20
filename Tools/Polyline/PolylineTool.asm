
proc PolylineTool.SelectNextPoint uses ebx esi
    cmp [PolylineTool.pTempPolyline], 0
    jne @F

    mov eax, [NextObjectId]
    mov [PolylineTool.NextObjectIdBeforeTool], eax

    mov ebx, PolylineTool.pTempPolyline
    stdcall Main.AddPolyline
    mov [PolylineTool.pTempPolyline], eax

    @@:
    stdcall Main.FindPointOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jnz .PointSelected

    stdcall Main.AddPoint, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y], 0

    .PointSelected:
        mov esi, [eax + Point.Id]
        mov eax, [PolylineTool.pTempPolyline]
        cmp [eax + PolylineObj.PointsIds.Length], 2
        jb @F

        mov eax, [eax + PolylineObj.PointsIds.Ptr]
        mov eax, [eax]
        cmp eax, esi
        jne @F

        mov ebx, [PolylineTool.pTempPolyline]
        add ebx, PolylineObj.PointsIds
        stdcall Vector.Pop
        mov [PolylineTool.pTempPolyline], 0
        stdcall Main.ToolAddedObject
        jmp .Return

        @@:
        mov ebx, [PolylineTool.pTempPolyline]
        add ebx, PolylineObj.PointsIds
        stdcall Vector.Pop
        stdcall Vector.PushValue, esi
        stdcall Vector.PushValue, 0

    .Return:
    ret
endp


proc PolylineTool.Cancel uses ebx
    stdcall Main.UndoTempHistory
    mov [PolylineTool.pTempPolyline], 0

    .Return:
    ret
endp

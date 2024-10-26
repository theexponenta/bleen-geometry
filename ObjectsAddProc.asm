
proc Main.AddObject pObject, ObjectSize
    mov ebx, Objects
    stdcall HeterogenousVector.Push, [pObject], [ObjectSize]
    inc [NextObjectId]
    ret
endp


; Returns pointer to added Point object
proc Main.AddPoint uses ebx, X, Y, ParentObjectId
    local NewPoint Point ?

    stdcall Main.ToPlanePosition, [X], [Y]
    mov [X], edx
    mov [Y], eax


    mov eax, [ShowGrid]
    and eax, [SnapToGrid]
    jz @F

    stdcall DrawArea.GetNearestGridNode, [X], [Y]
    stdcall Math.Distance, [X], [Y], edx, eax
    fmul [Scale]
    fld [MaxGridSnapDistance]
    fcomip st0, st1
    fstp st0
    jbe @F

    mov [X], edx
    mov [Y], eax

    @@:
    lea ebx, [NewPoint]
    mov eax, [NextPointNum]
    stdcall Point.PointNumToName
    stdcall Point.Create, [NextObjectId], eax, 0, [X], [Y], Point.DefaultColor, Point.DefaultSize, [ParentObjectId]

    push ebx
    mov ebx, Points
    call Vector.Push

    inc [NextObjectId]
    inc [NextPointNum]

    ret
endp


proc Main.DeleteLastPoint uses ebx
    mov ebx, Points
    call Vector.Pop
    dec [NextPointNum]

    ret
endp


proc Main.AddSegment uses ebx, Point1Id, Point2Id
    local NewSegment Segment ?

    lea ebx, [NewSegment]
    stdcall Segment.Create, [NextObjectId], 0, 0, [Point1Id], [Point2Id], GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor
    stdcall Main.AddObject, ebx, sizeof.Segment

    ret
endp


proc Main.AddLine uses ebx, Point1Id, Point2Id
    local NewLine Segment ?

    lea ebx, [NewLine]
    stdcall Line.Create, [NextObjectId], 0, 0, [Point1Id], [Point2Id], GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor
    stdcall Main.AddObject, ebx, sizeof.Line

    ret
endp


proc Main.AddCircleWithCenter uses ebx, CenterPointId, SecondPointId
    local NewCircle CircleWithCenter ?

    lea ebx, [NewCircle]
    stdcall CircleWithCenter.Create, [NextObjectId], 0, 0, [CenterPointId], [SecondPointId], GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor
    stdcall Main.AddObject, ebx, sizeof.CircleWithCenter

    ret
endp


proc Main.AddEllipse uses ebx, Focus1PointId, Focus2PointId, CircumferencePointId
    local NewEllipse EllipseObj ?

    lea ebx, [NewEllipse]
    stdcall EllipseObj.Create, [NextObjectId], 0, 0, [Focus1PointId], [Focus2PointId], [CircumferencePointId], GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor
    stdcall Main.AddObject, ebx, sizeof.EllipseObj

    ret
endp


proc Main.AddPolyline uses ebx
    local NewPolyline PolylineObj ?

    lea ebx, [NewPolyline]
    stdcall PolylineObj.Create, [NextObjectId], 0, 0, GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor
    stdcall Main.AddObject, ebx, sizeof.PolylineObj

    ret
endp

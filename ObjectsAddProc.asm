
proc Main.AddObject pObject, ObjectSize
    mov ebx, Objects
    stdcall HeterogenousVector.Push, [pObject], [ObjectSize]
    inc [NextObjectId]
    ret
endp

; X, Y - SCREEN!!! coordinates
; Returns pointer to added Point object
proc Main.AddPoint, X, Y, pParentObject
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
    stdcall Main._AddPoint, [X], [Y], [pParentObject], Point.DefaultColor, Point.DefaultSize

    ret
endp


; X, Y - plane coordinates
; Returns pointer to added Point object
proc Main._AddPoint uses ebx, X, Y, pParentObject, Color, Width
    local NewPoint Point ?

    lea ebx, [NewPoint]
    mov eax, [NextPointNum]
    stdcall Point.PointNumToName
    stdcall Point.Create, [NextObjectId], eax, 0, [X], [Y], [Color],[Width], [pParentObject]

    push ebx
    mov ebx, Points
    stdcall Vector.Push

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


proc Main.AddSegment uses ebx, Point1Id, Point2Id, Width, Color
    local NewSegment Segment ?

    lea ebx, [NewSegment]
    stdcall Segment.Create, [NextObjectId], 0, 0, [Point1Id], [Point2Id], [Width], [Color]
    stdcall Main.AddObject, ebx, sizeof.Segment

    ret
endp


proc Main.AddLine uses ebx, Point1Id, Point2Id
    local NewLine Line ?

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


proc Main.AddPolygon uses ebx
    local NewPolygon PolygonObj ?

    lea ebx, [NewPolygon]
    stdcall PolygonObj.Create, [NextObjectId], 0, 0, GeometryObject.DefaultLineWidth, PolygonObj.DefaultColor
    stdcall Main.AddObject, ebx, sizeof.PolygonObj

    ret
endp


proc Main.AddParabola uses ebx, FocusPointId, LineObjectId
    local NewParabola Parabola ?

    lea ebx, [NewParabola]
    stdcall Parabola.Create, [NextObjectId], 0, 0, [FocusPointId], [LineObjectId], \
                             GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor

    stdcall Main.AddObject, ebx, sizeof.Parabola

    ret
endp


proc Main.AddIntersection uses ebx, Object1Id, Object2Id
    local NewIntersection Intersection ?

    lea ebx, [NewIntersection]
    stdcall Intersection.Create, [NextObjectId], [Object1Id], [Object2Id]

    stdcall Main.AddObject, ebx, sizeof.Intersection

    ret
endp


proc Main.SetIntersectionPoint uses esi edi, IntersectionId, PointIndex, X, Y
    mov ecx, [Points.Length]
    test ecx, ecx
    jz .Return

    mov esi, [Points.Ptr]
    mov edx, [IntersectionId]
    mov edi, [PointIndex]
    xor eax, eax
    .PointsLoop:
        cmp [esi + Point.IntersectionId], edx
        jne .NextIteration

        add eax, 1
        cmp eax, edi
        je .SetPoint

        .NextIteration:
        add esi, sizeof.Point
        loop .PointsLoop

    stdcall Main._AddPoint, [X], [Y], 0, Point.IntersectionDefaultColor, Point.DefaultSize
    mov edx, [IntersectionId]
    mov [eax + Point.IntersectionId], edx
    jmp .Return

    .SetPoint:
    mov eax, [X]
    mov [esi + Point.X], eax
    mov edx, [Y]
    mov [esi + Point.Y], edx
    mov [esi + Point.IsHidden], 0

    .Return:
    ret
endp


proc Main.HideIntersectionPoint uses esi edi, IntersectionId, PointIndex
    mov ecx, [Points.Length]
    test ecx, ecx
    jz .Return

    mov esi, [Points.Ptr]
    mov edx, [IntersectionId]
    mov edi, [PointIndex]
    xor eax, eax
    .PointsLoop:
        cmp [esi + Point.IntersectionId], edx
        jne .NextIteration

        add eax, 1
        cmp eax, edi
        jne .NextIteration

        mov [esi + Point.IsHidden], 1
        jmp .Return

        .NextIteration:
        add esi, sizeof.Point
        loop .PointsLoop

    .Return:
    ret
endp


proc Main.AddAngleBisector uses ebx, Point1Id, Point2Id, Point3Id
    local NewAngleBisector AngleBisector ?

    lea ebx, [NewAngleBisector]
    stdcall AngleBisector.Create, [NextObjectId], 0, 0, [Point1Id], [Point2Id], [Point3Id], GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor
    stdcall Main.AddObject, ebx, sizeof.AngleBisector

    ret
endp


proc Main.AddPerpendicular uses ebx, PointId, LineObjectId
    local NewPerpendicular Perpendicular ?

    lea ebx, [NewPerpendicular]
    stdcall Perpendicular.Create, [NextObjectId], 0, 0, [PointId], [LineObjectId], \
                                  GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor

    stdcall Main.AddObject, ebx, sizeof.Perpendicular

    ret
endp


proc Main.AddPerpendicularBisector uses ebx, Point1Id, Point2Id
    local NewPerpendicularBisector PerpendicularBisector ?

    lea ebx, [NewPerpendicularBisector]
    stdcall PerpendicularBisector.Create, [NextObjectId], 0, 0, [Point1Id], [Point2Id], \
                                  GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor

    stdcall Main.AddObject, ebx, sizeof.PerpendicularBisector

    ret
endp


proc Main.AddParallelLine uses ebx, PointId, LineObjectId
    local NewParallelLine ParallelLine ?

    lea ebx, [NewParallelLine]
    stdcall ParallelLine.Create, [NextObjectId], 0, 0, [PointId], [LineObjectId], \
                                  GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor

    stdcall Main.AddObject, ebx, sizeof.ParallelLine

    ret
endp


proc Main.AddPlot uses ebx, PlotType, pEquationStr
    locals
        NewPlot Plot ?
    endl

    lea ebx, [NewPlot]
    stdcall Plot.Create, [NextObjectId], 0, 0, [PlotType], [pEquationStr], \
                         GeometryObject.DefaultLineWidth, GeometryObject.DefaultLineColor

    lea eax, [NewPlot.RPN]
    stdcall MathParser.Parse, [pEquationStr], eax, 'x'
    test eax, eax
    jz .Error

    stdcall Main.AddObject, ebx, sizeof.Plot

    mov eax, 1
    jmp .Return

    .Error:
    lea ebx, [NewPlot]
    stdcall Plot.Destroy
    xor eax, eax

    .Return:
    ret
endp
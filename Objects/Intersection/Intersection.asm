
proc Intersection.Create Id, Object1Id, Object2Id
    stdcall GeometryObject.Create, [Id], OBJ_INTERSECTION, 0, 0
    
    mov eax, [Object1Id]
    mov [ebx + Intersection.Object1Id], eax

    mov eax, [Object2Id]
    mov [ebx + Intersection.Object2Id], eax

    ret
endp


proc Intersection.GetIntersectionProc uses esi edi, Obj1Type, Obj2Type
    mov eax, [Obj1Type]
    mov esi, [Obj2Type]

    cmp eax, OBJ_CIRCLE_WITH_CENTER
    jne @F

    stdcall GeometryObject.IsLineObjectType, esi
    test eax, eax
    jz .NotFound

    mov eax, Intersection._IntersectLineObjectWithCircle
    jmp .Return

    @@:
    stdcall GeometryObject.IsLineObjectType, eax
    mov edi, eax
    stdcall GeometryObject.IsLineObjectType, esi
    test edi, eax
    jz .NotFound

    mov eax, Intersection._IntersectLineLikeObjects
    jmp .Return

    .NotFound:
    xor eax, eax

    .Return:
    ret
endp


proc Intersection._IntersectLineLikeObjects uses ebx esi, pLineLikeObj1, pLineLikeObj2
    locals
        IntersectionPoint POINT ?
    endl

    mov esi, ebx
    mov eax, [pLineLikeObj1]
    mov edx, [pLineLikeObj2]

    stdcall Math.IntersectLines, [eax + Line.Point1.x], [eax + Line.Point1.y], [eax + Line.Point2.x], [eax + Line.Point2.y], \
                                 [edx + Line.Point1.x], [edx + Line.Point1.y], [edx + Line.Point2.x], [edx + Line.Point2.y]

    mov ebx, [pLineLikeObj1]
    cmp byte [ebx + GeometryObject.Type], OBJ_SEGMENT
    jne @F


    stdcall Segment.IsPointOnSegment

    test eax, eax
    jz .HidePoint

    @@:
    mov ebx, [pLineLikeObj2]
    cmp byte [ebx + GeometryObject.Type], OBJ_SEGMENT
    jne @F

    stdcall Segment.IsPointOnSegment

    test eax, eax
    jz .HidePoint

    @@:
    fst [IntersectionPoint.y]
    fxch
    fst [IntersectionPoint.x]

    stdcall Main.SetIntersectionPoint, [esi + Intersection.Id], 1, [IntersectionPoint.x], [IntersectionPoint.y]
    jmp .Return

    .HidePoint:
    stdcall Main.HideIntersectionPoint, [esi + Intersection.Id], 1

    .Return:
    fstp st0
    fstp st0
    ret
endp


proc Intersection._IntersectLineObjectWithCircle uses edi ebx, pCircle, pLineObject
    locals
       NearestPoint POINT ?
       IntersectionPoint1 POINT ?
       IntersectionPoint2 POINT ?

       ShowPoint1 dd ?
       ShowPoint2 dd ?
    endl

    mov eax, [pCircle]
    stdcall Main.GetObjectById, [eax + CircleWithCenter.CenterPointId]
    mov edi, eax

    mov eax, [pLineObject]
    stdcall Math.GetNearestPointOnLine, [edi + Point.X], [edi + Point.Y], [eax + Line.Point1.x], [eax + Line.Point1.y], \
                                        [eax + Line.Point2.x], [eax + Line.Point2.y]

    fstp [NearestPoint.y]
    fstp [NearestPoint.x]

    stdcall Math.Distance, [NearestPoint.x], [NearestPoint.y], [edi + Point.X], [edi + Point.Y]

    mov eax, [pCircle]
    stdcall Main.GetObjectById, [eax + CircleWithCenter.SecondPointId]
    stdcall Math.Distance, [edi + Point.X], [edi + Point.Y], [eax + Point.X], [eax + Point.Y]

    fcomi st0, st1
    jb .NoPoints

    fmul st0, st0
    fxch
    fmul st0, st0

    fsubp
    fsqrt

    mov eax, [pLineObject]
    stdcall Math.Distance, [eax + Line.Point1.x], [eax + Line.Point1.y], [eax + Line.Point2.x], [eax + Line.Point2.y]

    fdivp

    fld [eax + Line.Point2.x]
    fsub [eax + Line.Point1.x]
    fmul st0, st1
    fld [eax + Line.Point2.y]
    fsub [eax + Line.Point1.y]
    fmul st0, st2

    fld [NearestPoint.x]
    fadd st0, st2
    fst [IntersectionPoint1.x]
    fsub st0, st2
    fsub st0, st2
    fstp [IntersectionPoint2.x]

    fld [NearestPoint.y]
    fadd st0, st1
    fst [IntersectionPoint1.y]
    fsub st0, st1
    fsub st0, st1
    fstp [IntersectionPoint2.y]

    fstp st0
    fstp st0
    fstp st0

    mov edi, [ebx + Intersection.Id]

    mov [ShowPoint1], 1
    mov [ShowPoint2], 1

    mov ebx, eax
    cmp byte [eax + GeometryObject.Type], OBJ_SEGMENT
    jne .ShowOrHidePoints

    fld [IntersectionPoint1.x]
    fld [IntersectionPoint1.y]

    stdcall Segment.IsPointOnSegment
    fstp st0
    fstp st0
    mov [ShowPoint1], eax

    fld [IntersectionPoint2.x]
    fld [IntersectionPoint2.y]

    stdcall Segment.IsPointOnSegment
    fstp st0
    fstp st0
    mov [ShowPoint2], eax

    .ShowOrHidePoints:

    cmp [ShowPoint1], 0
    je @F

    stdcall Main.SetIntersectionPoint, edi, 1, [IntersectionPoint1.x], [IntersectionPoint1.y]
    jmp .ShowOrHidePoint2

    @@:
    stdcall Main.HideIntersectionPoint, edi, 1

    .ShowOrHidePoint2:
    cmp [ShowPoint2], 0
    je @F

    stdcall Main.SetIntersectionPoint, edi, 2, [IntersectionPoint2.x], [IntersectionPoint2.y]
    jmp .Return

    @@:
    stdcall Main.HideIntersectionPoint, edi, 2

    jmp .Return

    .NoPoints:
    mov edi, [ebx + Intersection.Id]
    stdcall Main.HideIntersectionPoint, edi, 1
    stdcall Main.HideIntersectionPoint, edi, 2
    fstp st0
    fstp st0

    .Return:
    ret
endp


proc Intersection.Draw, hDC
    locals
        pObject1 dd ?
        pObject2 dd ?
        IntersectionPoint POINT ?
    endl

    stdcall Main.GetObjectById, [ebx + Intersection.Object2Id]
    test eax, eax
    jz .Return

    mov [pObject2], eax
    movzx ecx, byte [eax + GeometryObject.Type]
    push ecx

    stdcall Main.GetObjectById, [ebx + Intersection.Object1Id]
    test eax, eax
    jz .Return

    mov [pObject1], eax
    movzx ecx, byte [eax + GeometryObject.Type]
    push ecx

    stdcall Intersection.GetIntersectionProc ; Arguments are pushed above
    stdcall eax, [pObject1], [pObject2]

    .Return:
    ret
endp


proc Intersection.IsOnPosition, X, Y
    xor eax, eax
    ret
endp


proc Intersection.Move
    ret
endp


proc Intersection.DependsOnObject, ObjectId
   mov eax, 1

   mov edx, [ObjectId]
   cmp [ebx + Intersection.Object1Id], edx
   je .Return
   cmp [ebx + Intersection.Object2Id], edx
   je .Return

   stdcall Main.GetObjectById, edx
   test eax, eax
   jz .Return

   mov edx, eax
   xor eax, eax

   cmp byte [edx + GeometryObject.Type], OBJ_POINT
   jne .Return

   mov ecx, [ebx + Intersection.Id]
   cmp [edx + Point.IntersectionId], ecx
   jne .Return

   mov eax, 1

   .Return:
   ret
endp


proc Intersection.ToString, pBuffer
    invoke lstrcpyW, [pBuffer], Intersection.StrFormat
    invoke lstrlenW, Intersection.StrFormat

    ret
endp

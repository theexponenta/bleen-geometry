
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

    stdcall GeometryObject.IsLineObjectType, eax
    mov edi, eax
    stdcall GeometryObject.IsLineObjectType, esi
    test edi, eax

    mov eax, Intersection._IntersectLineLikeObjects
    jmp .Return

    xor eax, eax

    .Return:
    ret
endp


; st0 - Y-coordinate of instersection point
; st1 - X-coordinate of instersection point
proc Intersection._CheckIntersectionPointOnSegment, pSegment
    mov eax, [pSegment]
    fld [eax + Segment.Point1.x]
    fld [eax + Segment.Point2.x]
    call Math.FPUSwapMax
    fld [eax + Segment.Point1.y]
    fld [eax + Segment.Point2.y]
    call Math.FPUSwapMax

    xor eax, eax

    fcomi st0, st4
    jb .Return

    fxch st1
    fcomi st0, st4
    ja .Return

    fxch st2
    fcomi st0, st5
    jb .Return

    fxch st3
    fcomi st0, st5
    ja .Return

    mov eax, 1

    .Return:
    fstp st0
    fstp st0
    fstp st0
    fstp st0
    ret
endp


proc Intersection._IntersectLineLikeObjects, pLineLikeObj1, pLineLikeObj2
    locals
        IntersectionPoint POINT ?
    endl

    mov eax, [pLineLikeObj1]
    mov edx, [pLineLikeObj2]

    stdcall Math.IntersectLines, [eax + Line.Point1.x], [eax + Line.Point1.y], [eax + Line.Point2.x], [eax + Line.Point2.y], \
                                 [edx + Line.Point1.x], [edx + Line.Point1.y], [edx + Line.Point2.x], [edx + Line.Point2.y]

    mov eax, [pLineLikeObj1]
    cmp byte [eax + GeometryObject.Type], OBJ_SEGMENT
    jne @F

    stdcall Intersection._CheckIntersectionPointOnSegment, eax

    test eax, eax
    jz .HidePoint

    @@:
    mov eax, [pLineLikeObj2]
    cmp byte [eax + GeometryObject.Type], OBJ_SEGMENT
    jne @F

    stdcall Intersection._CheckIntersectionPointOnSegment, eax

    test eax, eax
    jz .HidePoint

    @@:
    fst [IntersectionPoint.y]
    fxch
    fst [IntersectionPoint.x]

    stdcall Main.SetIntersectionPoint, [ebx + Intersection.Id], 1, [IntersectionPoint.x], [IntersectionPoint.y]
    jmp .Return

    .HidePoint:
    stdcall Main.HideIntersectionPoint, [ebx + Intersection.Id], 1

    .Return:
    fstp st0
    fstp st0
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


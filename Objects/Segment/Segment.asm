
proc Segment.Create Id, pName, pCaption, Point1Id, Point2Id, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_SEGMENT, [pName], [pCaption]

    mov eax, [Point1Id]
    mov [ebx + Segment.Point1Id], eax

    mov eax, [Point2Id]
    mov [ebx + Segment.Point2Id], eax

    mov eax, [Width]
    mov [ebx + Segment.Width], eax

    mov eax, [Color]
    mov [ebx + Segment.Color], eax

    ret
endp


proc Segment.Draw uses ebx edi, hdc
    locals
        X1 dd ?
        Y1 dd ?
        X2 dd ?
        Y2 dd ?

        SelectedWidth dd ?
    endl

    mov eax, [ebx + Segment.Point1Id]
    call Main.FindPointById
    stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
    mov [X1], edx
    mov [Y1], eax

    mov eax, [ebx + Segment.Point2Id]
    call Main.FindPointById
    stdcall Main.ToScreenPosition, [eax + Point.X], [eax + Point.Y]
    mov [X2], edx
    mov [Y2], eax

    cmp [ebx + Segment.IsSelected], 0
    jz @F

    mov eax, [ebx + Segment.Color]
    or eax, Segment.SelectedShadowOpacity shl 24

    fild dword [ebx + Segment.Width]
    fmul [Segment.SelectedShadowWidthCoefficient]
    fistp [SelectedWidth]
    stdcall Draw.Line, [hdc], [X1], [Y1], [X2], [Y2], [SelectedWidth], eax

    @@:
    stdcall Draw.Line, [hdc], [X1], [Y1], [X2], [Y2], [ebx + Segment.Width], [ebx + Segment.Color]

    .Return:
    ret
endp


proc Segment.IsOnPosition uses edi, X, Y
    locals
        X1 dd ?
        Y1 dd ?
        X2 dd ?
        Y2 dd ?
    endl

    ; Let d be a distance between point (X, Y) and segement line
    ; Let X1, X2 be x-coordinates of segment edge points
    ; Let w be width of segment line
    ;
    ; Segment is on given position if the following conditions are met:
    ;
    ; min(X1, X2) <= X <= max(X1, X2)
    ; d <= w

    ; To determine if the segment is on given position,
    ; we need to calculate distance between point and the line of the segment,
    ; then compare it with width of the segment, and finally determine if
    ; x-coordinate of the given point lies between x1 and x2

    ;mov edi, [ebx + Segment.AttachedPointsIds.Ptr]

    ;mov eax, [edi]
    mov eax, [ebx + Segment.Point1Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov [X1], edx
    mov edx, [eax + Point.Y]
    mov [Y1], edx

    ;mov eax, [edi + 4]
    mov eax, [ebx + Segment.Point2Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov [X2], edx
    mov edx, [eax + Point.Y]
    mov [Y2], edx

    ; Caclulate min(X1, X2) and max(X1, X2)
    fild [X1]
    fild [X2]
    fld st0
    fld st2
    stdcall Math.FPUMin
    fxch st2
    stdcall Math.FPUMax

    fild [X]

    mov eax, 1

    fcomi st0, st1
    jbe @F

    xor eax, eax
    jmp .EndXCheck

    @@:
    fcomi st0, st2
    jae .EndXCheck

    xor eax, eax

    .EndXCheck:
        fstp st0
        fstp st0
        fstp st0
        test eax, eax
        jz .Return

    ; Let (x1, y1) and (x2, y2) be points of segment edges
    ; Let (x_d, y_d) be a direction vector of the segment line (x_d = x2 - x1, y_d = y2 - y1)
    ; (X, Y) is the point to check
    ; Let (x_m, y_m) be a vector from (X, Y) to (x1, y1) (x_m = x1 - X, y_m = y1 - Y)
    ;
    ;
    ; To determine if the segment is on given position,
    ; we need to calculate distance between point and the line of the segment,
    ; then compare it with width of the segment, and finally determine if
    ; x-coordinate of the given point lies between x1 and x2
    ;
    ;
    ; So, distance between the line and the point is calculated as
    ; D = abs(x_d * y_m - y_d * x_m) / sqrt(x_d^2 + y_d^2)

    ; Calculate direction vector of line (x_d, y_d)
    ;fild [X2]
    ;fisub [X1]
    ;fild [Y2]
    ;fisub [Y1]

    ; Caclculate (x_m, y_m)
    ;fild [X1]
    ;fisub [X]
    ;fild [Y1]
    ;fisub [Y]

    ; Caclucalte x_d * y_m
    ;fld st0 ; y_m
    ;fmul st0, st4 ; * x_d

    ; Calculate y_d * x_m
    ;fld st2 ; x_m
    ;fmul st0, st4 ; * y_d

    ; Caclucalte abs(x_d * y_m - y_d * x_m)
    ;fsubp
    ;fabs

    ; Caclucalte sqrt(x_d^2 + y_d^2)
    ;fld st4
    ;fmul st0, st0
    ;fld st4
    ;fmul st0, st0
    ;faddp
    ;fsqrt

    ; Resutlting distance
    ;fdivp

    stdcall Math.DistanceLinePoint, [X1] ,[Y1], [X2], [Y2], [X], [Y]
    fild [ebx + Segment.Width]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


; edx - dX
; ecx - dY
proc Segment.Move ; uses esi
    ;call GeometryObject.Move
    mov esi, ebx

    mov eax, [esi + Segment.Point1Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    mov eax, [esi + Segment.Point2Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

   ret
endp

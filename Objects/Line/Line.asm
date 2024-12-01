
proc Line.Create Id, pName, pCaption, Point1Id, Point2Id, Width, Color
    stdcall GeometryObject.Create, [Id], OBJ_LINE, [pName], [pCaption]
    
    mov eax, [Point1Id]
    mov [ebx + Line.Point1Id], eax

    mov eax, [Point2Id]
    mov [ebx + Line.Point2Id], eax

    mov eax, [Width]
    mov [ebx + Line.Width], eax

    mov eax, [Color]
    mov [ebx + Line.Color], eax

    ret
endp


; Calculates y-corrdinte of intersection of given line with line x = a
; by formula y = (X2*Y1 - X1*Y2 - (Y1 - Y2)*x) / (X2 - X1)
;
; Parameters:
; st3 -- X2*Y1 - X1*Y2
; st2 -- X2 - X1
; st1 -- Y1 - Y2
; st0 -- X
;
; Where (X1, Y1) and (X2, Y2) - points that line given goes throught
;
; Returns y-coordinate to st0, returns 1 to eax if the coordinate
; is between 0 and height of draw area
proc Line._XIntersection
    fmul st0, st1
    fchs
    fadd st0, st3
    fdiv st0, st2

    xor eax, eax

    fldz
    fcomip st0, st1
    ja .ReturnFalse

    fild [DrawArea.Height]
    fcomip st0, st1
    jb .ReturnFalse

    .ReturnTrue:
        inc eax

    .ReturnFalse:
    ret
endp


; Calculates x-corrdinte of intersection of given line with line y = a
; by formula x = (X2*Y1 - X1*Y2 - (X2 - X1)*y) / (Y1 - Y2)
;
; Parameters:
; st3 -- X2*Y1 - X1*Y2
; st2 -- X2 - X1
; st1 -- Y1 - Y2
; st0 -- Y
;
; Where (X1, Y1) and (X2, Y2) - points that line given goes throught
;
; Returns x-coordinate to st0, returns 1 to eax if the coordinate
; is between 0 and width of draw area
proc Line._YIntersection
    fmul st0, st2
    fchs
    fadd st0, st3
    fdiv st0, st1

    xor eax, eax

    fldz
    fcomip st0, st1
    ja .ReturnFalse

    fild [DrawArea.Width]
    fcomip st0, st1
    jb .ReturnFalse

    .ReturnTrue:
        inc eax

    .ReturnFalse:
    ret
endp


proc Line.GetLineBorderPoints uses edi, P1.x, P1.y, P2.x, P2.y, pBorderPoint1, pBorderPoint2
    locals
        P1Border POINT ?
        P2Border POINT ?
    endl

    ; X2*Y1 - X1*Y2
    fld [P2.x]
    fmul [P1.y]
    fld [P1.x]
    fmul [P2.y]
    fsubp

    ; X2 - X1
    fld [P2.x]
    fsub [P1.x]

    ; Y1 - Y2
    fld [P1.y]
    fsub [P2.y]

    lea edi, [P1Border]

    fldz
    call Line._XIntersection
    test eax, eax
    jz @F

    mov [edi + POINT.x], 0f
    fst [edi + POINT.y]
    add edi, sizeof.POINT

    @@:
    fstp st0
    fild [DrawArea.Width]
    call Line._XIntersection
    test eax, eax
    jz @F

    mov eax, [DrawArea.Width]
    call Math.IntToFloat
    mov [edi + POINT.x], eax
    fst [edi + POINT.y]
    add edi, sizeof.POINT

    @@:
    fstp st0
    fldz
    call Line._YIntersection
    test eax, eax
    jz @F

    fst [edi + POINT.x]
    mov [edi + POINT.y], 0f
    add edi, sizeof.POINT

    @@:
    fstp st0
    fild [DrawArea.Height]
    call Line._YIntersection
    test eax, eax
    jz @F

    fst [edi + POINT.x]
    mov eax, [DrawArea.Height]
    call Math.IntToFloat
    mov [edi + POINT.y], eax

    @@:
    fstp st0
    fstp st0
    fstp st0
    fstp st0

    mov edi, [pBorderPoint1]
    mov eax, [P1Border.x]
    mov [edi + POINT.x], eax
    mov eax, [P1Border.y]
    mov [edi + POINT.y], eax

    mov edi, [pBorderPoint2]
    mov eax, [P2Border.x]
    mov [edi + POINT.x], eax
    mov eax, [P2Border.y]
    mov [edi + POINT.y], eax

    ret
endp


proc Line.Update
    mov eax, [ebx + Line.Point1Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov ecx, [eax + Point.Y]
    mov [ebx + Line.Point1.x], edx
    mov [ebx + Line.Point1.y], ecx

    mov eax, [ebx + Line.Point2Id]
    call Main.FindPointById
    mov edx, [eax + Point.X]
    mov ecx, [eax + Point.Y]
    mov [ebx + Line.Point2.x], edx
    mov [ebx + Line.Point2.y], ecx

    ret
endp


proc Line.Draw uses edi, hdc
    locals
        P1 POINT ?
        P2 POINT ?

        P1Border POINT ?
        P2Border POINT ?

        SelectedWidth dd ?
    endl

    stdcall Line.Update

    lea eax, [P1Border]
    lea edx, [P2Border]
    push edx eax

    stdcall Main.ToScreenPosition, [ebx + Line.Point1.x], [ebx + Line.Point1.y]
    push eax edx

    stdcall Main.ToScreenPosition, [ebx + Line.Point2.x], [ebx + Line.Point2.y]
    push eax edx

    stdcall Line.GetLineBorderPoints ; All arguments are pushed above

    cmp [ebx + Line.IsSelected], 0
    je @F

    fild [ebx + Line.Width]
    fmul [GeometryObject.SelectedLineShadowWidthCoefficient]
    fistp [SelectedWidth]
    stdcall Draw.Line, [hdc], [P1Border.x], [P1Border.y], [P2Border.x], [P2Border.y], [SelectedWidth], GeometryObject.SelectedLineColor

    @@:
    stdcall Draw.Line, [hdc], [P1Border.x], [P1Border.y], [P2Border.x], [P2Border.y], [ebx + Line.Width], [ebx + Line.Color]

    .Return:
    ret
endp


proc Line.IsOnPosition X, Y
    ; All the arguments are pushed above
    stdcall Math.DistanceLinePoint, [ebx + Line.Point1.x], [ebx + Line.Point1.y], [ebx + Line.Point2.x], [ebx + Line.Point2.y], [X], [Y]

    fild [ebx + Line.Width]
    fdiv [Scale]
    fcomip st0, st1
    fstp st0
    mov eax, 1
    jae .Return

    xor eax, eax

    .Return:
    ret
endp


proc Line.Move uses esi
    mov esi, ebx

    mov eax, [esi + Line.Point1Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    mov eax, [esi + Line.Point2Id]
    push edx ecx
    call Main.FindPointById
    pop ecx edx

    mov ebx, eax
    call Point.Move

    ret
endp


proc Line.ToString, pBuffer
    mov eax, [ebx + Line.Point2Id]
    stdcall Main.FindPointById
    push [eax + GeometryObject.pName]

    mov eax, [ebx + Line.Point1Id]
    stdcall Main.FindPointById
    push [eax + GeometryObject.pName]

    cinvoke sprintf, [pBuffer], Line.StrFormat ; Format arguments are pushed above
    add esp, 4*2

    ret
endp

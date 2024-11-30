
proc IntersectionTool.SelectObject uses esi
    stdcall Main.GetObjectOnPosition, [CurrentMouseScreenPoint.X], [CurrentMouseScreenPoint.Y]
    test eax, eax
    jz .Finish

    mov byte [eax + GeometryObject.IsSelected], 1

    xor ecx, ecx
    mov edx, IntersectionTool.Object1Id
    cmp dword [edx], 0
    je @F
    mov edx, IntersectionTool.Object2Id
    mov ecx, 1
    cmp dword [edx], 0
    jne .Finish

    @@:
    mov esi, [eax + GeometryObject.Id]
    mov [edx], esi
    test ecx, ecx
    jz .Return

    movzx edx, byte [eax + GeometryObject.Type]

    push edx
    stdcall Main.GetObjectById, [IntersectionTool.Object1Id]
    pop edx

    movzx ecx, byte [eax + GeometryObject.Type]
    cmp ecx, edx
    jbe @F

    mov eax, [IntersectionTool.Object1Id]
    xchg eax, [IntersectionTool.Object2Id]
    mov [IntersectionTool.Object2Id], eax
    xchg ecx, edx

    @@:
    push eax
    ; If object are not intersectable, just skip
    stdcall Intersection.GetIntersectionProc, ecx, edx
    test eax, eax
    pop eax
    jz .Finish

    stdcall Main.AddIntersection, [IntersectionTool.Object1Id], [IntersectionTool.Object2Id]
    stdcall Main.ToolAddedObject

    .Finish:
    call IntersectionTool.Cancel

    .Return:
    ret
endp


proc IntersectionTool.Cancel
    stdcall Main.GetObjectById, [IntersectionTool.Object1Id]
    test eax, eax
    jz .Finish
    mov byte [eax + GeometryObject.IsSelected], 0

    stdcall Main.GetObjectById, [IntersectionTool.Object2Id]
    test eax, eax
    jz .Finish
    mov byte [eax + GeometryObject.IsSelected], 0

    .Finish:
    mov [IntersectionTool.Object1Id], 0
    mov [IntersectionTool.Object2Id], 0
    ret
endp

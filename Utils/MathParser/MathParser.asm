
proc MathParser.Parse uses esi edi ebx, pSource, pOutBytearray, variableLetter
    locals
        CurrentTokenStart dd ?
        PrevTokenType dd ?
        Number dd ?
    endl

    push 0

    mov [PrevTokenType], 0

    mov esi, [pSource]
    cmp byte [esi], 0
    je .ReturnError

    .ReadLoop:
        movzx eax, byte [esi]

        cmp eax, 0
        je .ReturnSuccess

        ; Skip whitespace characters
        cmp al, ' '
        je ..NextIteration
        cmp al, 13
        je ..NextIteration
        cmp al, 10
        je ..NextIteration
        cmp al, 9
        je ..NextIteration

        ; If '(', just push to stack
        cmp al, '('
        jne .CheckCloseParen

        cmp [PrevTokenType], 0
        je @F
        cmp byte [PrevTokenType], OPERATION_TOKEN_TYPE
        je @F
        cmp byte [PrevTokenType], '('
        jne .ReturnError

        @@:
        push eax
        mov [PrevTokenType], '('
        jmp ..NextIteration

        .CheckCloseParen:
        ; If ')', pop from stack until '(' met
        cmp al, ')'
        jne .CheckMinus

        cmp [PrevTokenType], ')'
        je @F
        cmp byte [PrevTokenType], OPERATION_TOKEN_TYPE
        je @F
        cmp [PrevTokenType], VARIABLE_TOKEN_TYPE
        je @F
        cmp [PrevTokenType], NUMBER_TOKEN_TYPE
        jne .ReturnError

        @@:
        mov [PrevTokenType], ')'
        mov ebx, [pOutBytearray]
        ..PopUntilOpenParenLoop:
            pop eax
            cmp eax, '('
            je ..NextIteration
            cmp eax, 0
            je .ReturnError

            xchg ah, al
            stdcall ByteArray.PushWord
            jmp ..PopUntilOpenParenLoop

        .CheckMinus:
        cmp eax, '-'
        jne @F
        mov edx, [PrevTokenType]

        cmp edx, NUMBER_TOKEN_TYPE
        je @F
        cmp edx, VARIABLE_TOKEN_TYPE
        je @F
        cmp edx, ')'
        je @F

        mov [PrevTokenType], OPERATION_TOKEN_TYPE
        push OPERATION_TOKEN_TYPE * 256 + UNARY_MINUS_OPCODE
        jmp ..NextIteration

        @@:
        push eax
        stdcall MathParser.GetBinaryOperationOpcode, eax
        mov edx, eax
        pop eax
        test edx, edx
        jz @F

        mov eax, edx
        .BinaryOp:
            mov [PrevTokenType], OPERATION_TOKEN_TYPE
            mov edx, eax
            mov dh, OPERATION_TOKEN_TYPE

            stdcall MathParser.GetOpPriority, eax
            cmp eax, 0
            je .ReturnError
            mov ecx, eax
            ..PopStackLoop:
                pop eax
                mov ebx, eax
                cmp bh, OPERATION_TOKEN_TYPE
                jne ..PushToStack
                stdcall MathParser.GetOpPriority, ebx
                cmp eax, ecx
                jb ..PushToStack
                mov ax, bx
                xchg ah, al
                mov ebx, [pOutBytearray]
                stdcall ByteArray.PushWord
                jmp ..PopStackLoop

             ..PushToStack:
                 push ebx
                 push edx
                 jmp ..NextIteration

        @@:
        ; If character is digit, read number
        stdcall Strings.IsDigit, eax
        jnc .CheckLetter

        ; Check previous token to be only operation or open parenthesis
        cmp [PrevTokenType], 0
        je @F
        cmp [PrevTokenType], '('
        je @F
        cmp [PrevTokenType], OPERATION_TOKEN_TYPE
        je @F
        jmp .ReturnError

        @@:
        mov [CurrentTokenStart], esi
        xor eax, eax
        ..ReadNumberLoop:
            movzx eax, byte [esi]

            stdcall Strings.IsDigit, eax
            jc ...NextIteration
            cmp al, '.'
            jne ..WriteNumberToken
            cmp ah, 0
            jne ..WriteNumberToken
            inc ah

            ...NextIteration:
                inc esi
                jmp ..ReadNumberLoop

        ..WriteNumberToken:
            mov [PrevTokenType], NUMBER_TOKEN_TYPE

            mov al, NUMBER_TOKEN_TYPE
            mov ebx, [pOutBytearray]
            stdcall ByteArray.PushByte

            mov ecx, esi
            sub ecx, [CurrentTokenStart]
            lea edi, [Number]
            stdcall Strings.StringToFloat, [CurrentTokenStart], ecx, edi
            stdcall ByteArray.PushSequence, edi, 4
            dec esi
            jmp ..NextIteration

        .CheckLetter:
        stdcall Strings.IsLetter, eax
        jnc .ReturnError
        movzx edx, byte [esi + 1]
        push eax
        stdcall Strings.IsLetter, edx
        pop eax
        jc .CheckPI

        or eax, 32

        cmp al, byte [variableLetter]
        jne .CheckE

        cmp [PrevTokenType], NUMBER_TOKEN_TYPE
        jne @F
        mov eax, MUL_OPCODE
        dec esi
        jmp .BinaryOp

        @@:
        cmp [PrevTokenType], 0
        je @F
        cmp [PrevTokenType], OPERATION_TOKEN_TYPE
        je @F
        cmp [PrevTokenType], '('
        jne .ReturnError

        @@:
        mov [PrevTokenType], VARIABLE_TOKEN_TYPE
        mov ax,  VARIABLE_TOKEN_TYPE
        mov ebx, [pOutBytearray]
        stdcall ByteArray.PushByte
        jmp ..NextIteration

        .CheckE:
        cmp eax, 'e'
        jne .ReturnError
        mov [PrevTokenType], NUMBER_TOKEN_TYPE
        mov ax, NUMBER_TOKEN_TYPE
        mov ebx, [pOutBytearray]
        stdcall ByteArray.PushByte
        fld [e]
        fstp [Number]
        lea edi, [Number]
        stdcall ByteArray.PushSequence, edi, 4
        jmp ..NextIteration

        .CheckPI:
        movzx edx, byte [esi + 2]
        push eax
        stdcall Strings.IsLetter, edx
        pop eax
        jc ..ReadFunction
        cmp word [esi], 'i' shl 8 + 'p'
        jne ..ReadFunction
        mov [PrevTokenType], NUMBER_TOKEN_TYPE
        mov ax, NUMBER_TOKEN_TYPE
        mov ebx, [pOutBytearray]
        stdcall ByteArray.PushByte
        fldpi
        fstp [Number]
        lea edi, [Number]
        stdcall ByteArray.PushSequence, edi, 4
        inc esi
        jmp ..NextIteration

        ..ReadFunction:
        mov [CurrentTokenStart], esi
        inc esi
        ..ReadFunctionLoop:
            movzx eax, byte [esi]
            stdcall Strings.IsAlphanumeric, eax
            jnc ..WriteFunctionToken
            inc esi
            jmp ..ReadFunctionLoop

        ..WriteFunctionToken:
            mov ecx, esi
            sub ecx, [CurrentTokenStart]
            stdcall MathParser.GetFunctionOpcode, [CurrentTokenStart], ecx
            cmp eax, 0
            je .ReturnError
            mov ah, OPERATION_TOKEN_TYPE
            push eax
            mov [PrevTokenType], OPERATION_TOKEN_TYPE
            dec esi
            jmp ..NextIteration

        ..NextIteration:
            inc esi
            jmp .ReadLoop

    .ReturnSuccess:
        mov edi, 1
        jmp .PopRest

    .ReturnError:
       xor edi, edi

    .PopRest:
        mov ebx, [pOutBytearray]
        pop eax
        cmp eax, 0
        je .Return

        cmp ah, OPERATION_TOKEN_TYPE
        jne @F
        xchg ah, al

        @@:
        stdcall ByteArray.PushWord
        jmp .PopRest

    .Return:
        xor eax, eax
        stdcall ByteArray.PushByte

        mov eax, edi

        ret
endp


proc MathParser.GetOpPriority uses esi, op
    mov esi, OP_PRIORITIES
    mov eax, [op]
    .FindOpLoop:
        cmp [esi], byte 0
        je .NotFound
        cmp [esi], al
        jne .FindOpLoop.NextIteration

        movzx eax, byte [esi + 1]
        jmp .Return

        .FindOpLoop.NextIteration:
            add esi, 2
            jmp .FindOpLoop

    .NotFound:
        xor eax, eax

    .Return:
    ret
endp


proc MathParser.GetBinaryOperationOpcode uses edi, OpChar
    mov ecx, sizeof.BINARY_OPERATIONS
    mov eax, [OpChar]
    mov edi, BINARY_OPERATIONS
    cld

    repne scasb
    xor eax, eax
    test ecx, ecx
    jz .Return

    mov eax, edi
    sub eax, BINARY_OPERATIONS

    .Return:
    ret
endp


proc MathParser.GetFunctionOpcode funcStrBuf, strLen
    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], TAN_FUNCTION_ALIAS, 2
    jnc @F
    mov eax, TAN_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], LN_FUNCTION_NAME, 2
    jnc @F
    mov eax, LN_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], SIN_FUNCTION_NAME, 3
    jnc @F
    mov eax, SIN_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], COS_FUNCTION_NAME, 3
    jnc @F
    mov eax, COS_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], ABS_FUNCTION_NAME, 3
    jnc @F
    mov eax, ABS_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], TAN_FUNCTION_NAME, 3
    jnc @F
    mov eax, TAN_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], COT_FUNCTION_NAME, 3
    jnc @F
    mov eax, COT_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], COT_FUNCTION_ALIAS, 3
    jnc @F
    mov eax, COT_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], SQRT_FUNCTION_NAME, 4
    jnc @F
    mov eax, SQRT_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], ARCTAN_FUNCTION_ALIAS, 5
    jnc @F
    mov eax, ARCTAN_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], ARCSIN_FUNCTION_NAME, 6
    jnc @F
    mov eax, ARCSIN_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], ARCCOS_FUNCTION_NAME, 6
    jnc @F
    mov eax, ARCCOS_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], ARCTAN_FUNCTION_NAME, 6
    jnc @F
    mov eax, ARCTAN_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], ARCCOT_FUNCTION_NAME, 6
    jnc @F
    mov eax, ARCCOT_FUNCTION_OPCODE
    jmp .Return

    @@:
    stdcall Strings.StringsEqual, [funcStrBuf], [strLen], ARCCOT_FUNCTION_ALIAS, 6
    jnc @F
    mov eax, ARCCOT_FUNCTION_OPCODE
    jmp .Return

    @@:
    xor eax, eax

    .Return:
    ret
endp


proc MathParser.Calculate uses esi, pBytearray, VarValue
    local operand1 dd ?
    local operand2 dd ?
    local opResult dd ?

    mov eax, [pBytearray]
    mov esi, [eax + ByteArray.Ptr]

    .CalcLoop:
        movzx eax, byte [esi]
        test eax, eax
        jz .ReturnSuccess

        @@:
        cmp eax, NUMBER_TOKEN_TYPE
        jne @F

        add esi, 1
        push dword [esi]
        add esi, 3
        jmp .CalcLoop.NextIteration

        @@:
        cmp ax, VARIABLE_TOKEN_TYPE
        jne @F
        push [VarValue]
        jmp .CalcLoop.NextIteration

        @@:
        cmp ax, OPERATION_TOKEN_TYPE
        jne .ReturnError
        add esi, 1
        movzx eax, byte [esi]

        pop [operand2]
        fld [operand2]

        ; Unary operations come first and have lower opcodes
        ; Pow operations has the greatest opcode
        ; By comparing opcode with POW_OPCODE, we can find out whether we have binary
        ; or unary operation
        cmp eax, POW_OPCODE
        ja @F

        pop [operand1]
        fld [operand1]

        @@:
        mov edx, OPERATIONS_EXECUTORS
        sub eax, 1
        shl eax, 2
        add edx, eax
        jmp dword [edx]

        .UnaryMinus:
        fchs
        jmp .PushOpResult

        .Sin:
        fsin
        jmp .PushOpResult

        .Cos:
        fcos
        jmp .PushOpResult

        .Tan:
        fptan
        fstp st0
        jmp .PushOpResult

        .Cot:
        fptan
        fdivrp
        jmp .PushOpResult

        .Sqrt:
        fsqrt
        jmp .PushOpResult

        .Abs:
        fabs
        jmp .PushOpResult

        .Arccos:
        fld st0
        fmul st0, st0
        fld1
        fsubrp
        fsqrt
        fxch
        fpatan
        jmp .PushOpResult

        .Arcsin:
        fld st0
        fmul st0, st0
        fld1
        fsubrp
        fsqrt
        fpatan
        jmp .PushOpResult

        .Arctan:
        fld1
        fpatan
        jmp .PushOpResult

        .Arccot:
        fld1
        fpatan
        fldpi
        fidiv [TWO]
        fsubrp
        jmp .PushOpResult

        .Ln:
        fldln2
        fxch
        fyl2x
        jmp .PushOpResult

        .Add:
        faddp
        jmp .PushOpResult

        .Sub:
        fsubrp
        jmp .PushOpResult

        .Multiply:
        fmulp
        jmp .PushOpResult

        .Divide:
        fdivrp
        jmp .PushOpResult

        .Pow:
        fstp st0
        fstp st0
        stdcall Math.Pow, [operand1], [operand2]
        jmp .PushOpResult

        .PushOpResult:
            fstp [opResult]
            push [opResult]

        .CalcLoop.NextIteration:
            inc esi
            jmp .CalcLoop

    .ReturnError:
        clc
        jmp .Return

    .ReturnSuccess:
        pop [opResult]
        fld [opResult]
        stc

    .Return:
        ret
endp


; st0 - result
; edx - 0 if error, nonzero otherwise
proc MathParser.EvalConstantExpression uses ebx, pExpressionStr
    locals
        RPN ByteArray ?
        Result dd ?
    endl

    lea ebx, [RPN]
    stdcall ByteArray.Create, 0, 64

    stdcall MathParser.Parse, [pExpressionStr], ebx, 0
    test eax, eax
    jz .Return

    stdcall MathParser.Calculate, ebx, eax
    mov eax, 1

    .Return:
    push eax
    stdcall ByteArray.Destroy
    pop eax
    ret
endp
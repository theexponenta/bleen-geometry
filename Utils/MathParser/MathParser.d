
ADD_OPCODE = 1
SUB_OPCODE = 2
MUL_OPCODE = 3
DIV_OPCODE = 4
POW_OPCODE = 5

SIN_FUNCTION_OPCODE = 6
SIN_FUNCTION_NAME db "sin"

COS_FUNCTION_OPCODE = 7
COS_FUNCTION_NAME db "cos"

TAN_FUNCTION_OPCODE = 8
TAN_FUNCTION_NAME db "tan"
TAN_FUNCTION_ALIAS db "tg"

COT_FUNCTION_OPCODE = 9
COT_FUNCTION_NAME db "cot"
COT_FUNCTION_ALIAS db "ctg"

SQRT_FUNCTION_OPCODE = 10
SQRT_FUNCTION_NAME db "sqrt"

ABS_FUNCTION_OPCODE = 11
ABS_FUNCTION_NAME db "abs"

UNARY_MINUS_OPCODE = 12

ARCSIN_FUNCTION_OPCODE = 13
ARCSIN_FUNCTION_NAME db "arcsin"

ARCCOS_FUNCTION_OPCODE = 14
ARCCOS_FUNCTION_NAME db "arccos"

ARCTAN_FUNCTION_OPCODE = 15
ARCTAN_FUNCTION_NAME db "arctan"
ARCTAN_FUNCTION_ALIAS db "arctg"

ARCCOT_FUNCTION_OPCODE = 16
ARCCOT_FUNCTION_NAME db "arccot"
ARCCOT_FUNCTION_ALIAS db "arcctg"

LN_FUNCTION_OPCODE = 17
LN_FUNCTION_NAME db "ln"


BINARY_OPERATIONS db '+', '-', '*', '/', '^', 0
sizeof.BINARY_OPERATIONS = $ - BINARY_OPERATIONS


OP_PRIORITIES db ADD_OPCODE, 1, SUB_OPCODE, 1, UNARY_MINUS_OPCODE, 1, MUL_OPCODE, 2, DIV_OPCODE, 2, POW_OPCODE, 3, SIN_FUNCTION_OPCODE, 4, \
                 COS_FUNCTION_OPCODE, 4, TAN_FUNCTION_OPCODE, COT_FUNCTION_OPCODE, 4, 4, SQRT_FUNCTION_OPCODE, 4,\
                 ABS_FUNCTION_OPCODE, 4, ARCCOS_FUNCTION_OPCODE, 4, ARCSIN_FUNCTION_OPCODE, 4, ARCTAN_FUNCTION_OPCODE, 4, \
                 ARCCOT_FUNCTION_OPCODE, 4, LN_FUNCTION_OPCODE, 4, 0

OPERATIONS_EXECUTORS dd MathParser.Calculate.Add, MathParser.Calculate.Sub, MathParser.Calculate.Multiply, MathParser.Calculate.Divide, \
                        MathParser.Calculate.Pow, MathParser.Calculate.Sin, MathParser.Calculate.Cos, MathParser.Calculate.Tan, \
                        MathParser.Calculate.Cot, MathParser.Calculate.Sqrt, MathParser.Calculate.Abs, MathParser.Calculate.UnaryMinus, \
                        MathParser.Calculate.Arcsin, MathParser.Calculate.Arccos, MathParser.Calculate.Arctan, MathParser.Calculate.Arccot, \
                        MathParser.Calculate.Ln

e dq $4005BF0A8B145769
TWO dw 2

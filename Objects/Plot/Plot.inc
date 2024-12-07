
struct Plot GeometryObject
    Width dd ?
    Color dd ?
    PlotType db ?
    pEquationStr dd ?
    RPN ByteArray ?
ends


Plot.EditableProperties = PROP_SIZE or PROP_COLOR

Plot.Type.Regular = 1
Plot.Type.Parametric = 2

Plot.DrawStates.NoPointsDrawn = 0
Plot.DrawStates.PrevPointVisible = 1
Plot.DrawStates.PrevPointInvisible = 2

FIRST_POINT = 0
VALUE_UNDEFINED = 1
Y_OUT_OF_BOUNDS = 2
VALUE_OK = 3
X_OUT_OF_BOUNDS = 4

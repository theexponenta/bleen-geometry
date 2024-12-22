
struct Plot GeometryObject
    Width dd ?
    Color dd ?
    PlotType db ?
    pXEquationStr dd ?
    pYEquationStr dd ?
    tmin dd ?
    tmax dd ?
    RPNY ByteArray ?
    RPNX ByteArray ?
ends


Plot.EditableProperties = PROP_SIZE or PROP_COLOR

Plot.Type.Regular = 1
Plot.Type.Parametric = 2

Plot.DrawStates.NoPointsDrawn = 0
Plot.DrawStates.PrevPointVisible = 1
Plot.DrawStates.PrevPointInvisible = 2

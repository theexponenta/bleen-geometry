
PolylineTool.States.SelectPoints = 1

PolylineTool.States.SelectPoints.Transitions dd WM_LBUTTONDOWN, PolylineTool.SelectNextPoint, \
                                                VK_ESCAPE, PolylineTool.Cancel, \
                                                WM_MOUSEMOVE, 1, 0

PolylineTool.States.Transitions dd PolylineTool.States.SelectPoints.Transitions, 0

Polyline.NextObjectIdBeforeTool dd ?
PolylineTool.pTempPolyline dd 0


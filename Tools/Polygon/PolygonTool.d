
PolygonTool.States.SelectPoints = 1

PolygonTool.States.SelectPoints.Transitions dd WM_LBUTTONDOWN, PolygonTool.SelectNextPoint, \
                                                VK_ESCAPE, PolygonTool.Cancel, \
                                                WM_MOUSEMOVE, 1, 0

PolygonTool.States.Transitions dd PolygonTool.States.SelectPoints.Transitions, 0

PolygonTool.PolygonId dd 0
PolygonTool.pPolygon dd ?
PolygonTool.pPrevSegment dd ?
PolygonTool.FirstPointId dd ?
PolygonTool.PrevPointId dd ?
PolygonTool.NextObjectIdBeforeTool dd ?

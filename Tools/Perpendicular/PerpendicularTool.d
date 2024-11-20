
PerpendicularTool.States.SelectLine = 1
PerpendicularTool.States.SelectPoint = 2

PerpendicularTool.States.SelectLine.Transitions dd WM_LBUTTONDOWN, PerpendicularTool.SelectLine, \
                                                   VK_ESCAPE, PerpendicularTool.Cancel, 0

PerpendicularTool.States.SelectPoint.Transitions dd  WM_LBUTTONDOWN, PerpendicularTool.SelectPoint, \
                                                     VK_ESCAPE, PerpendicularTool.Cancel, 0

PerpendicularTool.States.Transitions dd PerpendicularTool.States.SelectLine.Transitions, PerpendicularTool.States.SelectPoint.Transitions, 0

PerpendicularTool.NextObjectIdBeforeTool dd 0
PerpendicularTool.pLineObject dd ?
PerpendicularTool.pPoint dd ?

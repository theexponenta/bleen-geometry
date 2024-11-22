
PerpendicularBisectorTool.States.SelectPointOrSegment = 1
PerpendicularBisectorTool.States.SelectSecondPoint = 2

PerpendicularBisectorTool.States.SelectPointOrSegment.Transitions dd WM_LBUTTONDOWN, PerpendicularBisectorTool.SelectPointOrSegment, \
                                                                     VK_ESCAPE, PerpendicularBisectorTool.Cancel, 0

PerpendicularBisectorTool.States.SelectSecondPoint.Transitions dd WM_MOUSEMOVE, 1, \
                                                                  WM_LBUTTONDOWN, PerpendicularBisectorTool.SelectSecondPoint, \
                                                                  VK_ESCAPE, PerpendicularBisectorTool.Cancel, 0

PerpendicularBisectorTool.States.Transitions dd PerpendicularBisectorTool.States.SelectPointOrSegment.Transitions,\
                                                PerpendicularBisectorTool.States.SelectSecondPoint.Transitions, 0

PerpendicularBisectorTool.pTempPerpendicularBisector dd ?

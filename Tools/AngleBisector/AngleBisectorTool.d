
AngleBisectorTool.States.SelectPoints = 1

AngleBisectorTool.States.SelectPoints.Transitions dd WM_LBUTTONDOWN, AngleBisectorTool.SelectNextPoint, \
                                               VK_ESCAPE, AngleBisectorTool.Cancel, \
                                               WM_MOUSEMOVE, 1, 0

AngleBisectorTool.States.Transitions dd AngleBisectorTool.States.SelectPoints.Transitions, 0


AngleBisectorTool.SelectedPointsCount dd 0
AngleBisectorTool.SelectedPointsIds dd 3 dup(?)
AngleBisectorTool.pTempAngleBisector dd ?


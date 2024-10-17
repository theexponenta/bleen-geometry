
EllipseTool.States.SelectPoints = 1

EllipseTool.States.SelectPoints.Transitions dd WM_LBUTTONDOWN, EllipseTool.SelectNextPoint, \
                                               VK_ESCAPE, EllipseTool.Cancel, \
                                               WM_MOUSEMOVE, 1, 0

EllipseTool.States.Transitions dd EllipseTool.States.SelectPoints.Transitions, 0


EllipseTool.SelectedPointsCount dd 0
EllipseTool.SelectedPointsIds dd 3 dup(?)
EllipseTool.pTempEllipse dd ?


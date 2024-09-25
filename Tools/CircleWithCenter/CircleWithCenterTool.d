
CircleWithCenterTool.States.SelectCenterPoint = 1
CircleWithCenterTool.States.SelectSecondPoint = 2

CircleWithCenterTool.pTempCircle dd ?


CircleWithCenterTool.States.SelectCenterPoint.Transitions dd WM_LBUTTONDOWN, CircleWithCenterTool.SelectCenterPoint, \
                                                             WM_LBUTTONUP, CircleWithCenterTool.SetSelectSecondPoint, 0

CircleWithCenterTool.States.SelectSecondPoint.Transitions dd WM_MOUSEMOVE, 1, \
                                                             WM_LBUTTONDOWN, CircleWithCenterTool.SelectSecondPoint, \
                                                             WM_LBUTTONUP, CircleWithCenterTool.SetSelectCenterPoint, \
                                                             VK_ESCAPE, CircleWithCenterTool.Cancel, 0


CircleWithCenterTool.States.Transitions dd CircleWithCenterTool.States.SelectCenterPoint.Transitions, CircleWithCenterTool.States.SelectSecondPoint.Transitions, 0


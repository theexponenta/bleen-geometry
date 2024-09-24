LineTool.States.SelectPoint1 = 1
LineTool.States.SelectPoint2 = 2

LineTool.pTempLine dd ?


LineTool.States.SelectPoint1.Transitions dd WM_LBUTTONDOWN, LineTool.SelectPoint1, \
                                            WM_LBUTTONUP, SegementTool.SetSelectPoint2, 0

LineTool.States.SelectPoint2.Transitions dd WM_MOUSEMOVE, 1, \
                                            WM_LBUTTONDOWN, LineTool.SelectPoint2, \
                                            WM_LBUTTONUP, SegementTool.SetSelectPoint1, 0


LineTool.States.Transitions dd LineTool.States.SelectPoint1.Transitions, LineTool.States.SelectPoint2.Transitions, 0
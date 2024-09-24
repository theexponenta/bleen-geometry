
MoveTool.States.SelectObject = 1
MoveTool.States.MoveObject = 2
MoveTool.States.TranslateCanvas = 3

MoveTool.pSelectedObject dd ?
MoveTool.PrevPoint POINT ?

MoveTool.States.SelectObject.Transitions dd WM_LBUTTONDOWN, MoveTool.SelectObject, 0

MoveTool.States.MoveObject.Transitions dd WM_MOUSEMOVE, MoveTool.MoveObject, \
                                          WM_LBUTTONUP, MoveTool.SetSelectObject, 0

MoveTool.States.TranslateCanvas.Transitions dd WM_MOUSEMOVE, MoveTool.TranslateCanvas, \
                                               WM_LBUTTONUP, MoveTool.SetSelectObject, 0



MoveTool.States.Transitions dd MoveTool.States.SelectObject.Transitions, \
                               MoveTool.States.MoveObject.Transitions, \
                               MoveTool.States.TranslateCanvas.Transitions, 0





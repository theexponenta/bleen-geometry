
MoveTool.States.SelectObjects = 1
MoveTool.States.MoveObjects = 2
MoveTool.States.TranslateCanvas = 3

MoveTool.PrevPoint POINT 0f, 0f
MoveTool.WasMoved dd 0

MoveTool.States.SelectObjects.Transitions dd WM_LBUTTONDOWN, MoveTool.SelectObjects, \
                                            VK_DELETE, MoveTool.DeleteSelectedObjects, 0

MoveTool.States.MoveObjects.Transitions dd WM_MOUSEMOVE, MoveTool.MoveObjects, \
                                          WM_LBUTTONUP, MoveTool.SetSelectObjects, 0

MoveTool.States.TranslateCanvas.Transitions dd WM_MOUSEMOVE, MoveTool.TranslateCanvas, \
                                               WM_LBUTTONUP, MoveTool.SetSelectObjects, 0



MoveTool.States.Transitions dd MoveTool.States.SelectObjects.Transitions, \
                               MoveTool.States.MoveObjects.Transitions, \
                               MoveTool.States.TranslateCanvas.Transitions, 0





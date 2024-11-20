
IntersectionTool.States.SelectObject = 1

IntersectionTool.States.SelectObject.Transitions dd WM_LBUTTONDOWN, IntersectionTool.SelectObject, \
                                                    VK_ESCAPE, IntersectionTool.Cancel, 0

IntersectionTool.States.Transitions dd IntersectionTool.States.SelectObject.Transitions, 0

IntersectionTool.Object1Id dd 0
IntersectionTool.Object2Id dd 0
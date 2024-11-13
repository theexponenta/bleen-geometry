
ParabolaTool.States.SelectDirectrix = 1
ParabolaTool.States.SelectFocus = 2

ParabolaTool.States.SelectDirectrix.Transitions dd WM_LBUTTONDOWN, ParabolaTool.SelectDirectrix, \
                                                   VK_ESCAPE, ParabolaTool.Cancel, 0

ParabolaTool.States.SelectFocus.Transitions dd  WM_LBUTTONDOWN, ParabolaTool.SelectFocus, \
                                                VK_ESCAPE, ParabolaTool.Cancel, 0

ParabolaTool.States.Transitions dd ParabolaTool.States.SelectDirectrix.Transitions, ParabolaTool.States.SelectFocus.Transitions, 0

ParabolaTool.NextObjectIdBeforeTool dd 0
ParabolaTool.pDirectrixLineObject dd ?
ParabolaTool.pFocusPoint dd ?

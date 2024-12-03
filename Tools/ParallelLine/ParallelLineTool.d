
ParallelLineTool.States.SelectLine = 1
ParallelLineTool.States.SelectPoint = 2

ParallelLineTool.States.SelectLine.Transitions dd WM_LBUTTONDOWN, ParallelLineTool.SelectLine, \
                                                   VK_ESCAPE, ParallelLineTool.Cancel, 0

ParallelLineTool.States.SelectPoint.Transitions dd  WM_LBUTTONDOWN, ParallelLineTool.SelectPoint, \
                                                     VK_ESCAPE, ParallelLineTool.Cancel, 0

ParallelLineTool.States.Transitions dd ParallelLineTool.States.SelectLine.Transitions, ParallelLineTool.States.SelectPoint.Transitions, 0

ParallelLineTool.NextObjectIdBeforeTool dd 0
ParallelLineTool.pLineObject dd ?
ParallelLineTool.pPoint dd ?

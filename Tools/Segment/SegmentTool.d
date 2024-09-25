
SegmentTool.States.SelectPoint1 = 1
SegmentTool.States.SelectPoint2 = 2

SegmentTool.pTempSegment dd ?


SegmentTool.States.SelectPoint1.Transitions dd WM_LBUTTONDOWN, SegmentTool.SelectPoint1, \
                                               WM_LBUTTONUP, SegementTool.SetSelectPoint2

SegmentTool.States.SelectPoint2.Transitions dd WM_MOUSEMOVE, 1, \
                                               WM_LBUTTONDOWN, SegmentTool.SelectPoint2, \
                                               WM_LBUTTONUP, SegementTool.SetSelectPoint1, \
                                               VK_ESCAPE, SegmentTool.Cancel, 0


SegmentTool.States.Transitions dd SegmentTool.States.SelectPoint1.Transitions, SegmentTool.States.SelectPoint2.Transitions, 0

include './Move/MoveTool.d'
include './Point/PointTool.d'
include './Segment/SegmentTool.d'
include './CircleWithCenter/CircleWithCenterTool.d'
include './Line/LineTool.d'
include './Ellipse/EllipseTool.d'


Tools.States.Transitions dd MoveTool.States.Transitions, PointTool.States.Transitions, SegmentTool.States.Transitions, \
                            CircleWithCenterTool.States.Transitions, LineTool.States.Transitions, EllipseTool.States.Transitions, 0

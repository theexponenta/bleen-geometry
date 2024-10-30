include './Move/MoveTool.d'
include './Point/PointTool.d'
include './Segment/SegmentTool.d'
include './CircleWithCenter/CircleWithCenterTool.d'
include './Line/LineTool.d'
include './Ellipse/EllipseTool.d'
include './Polyline/PolylineTool.d'
include './Polygon/PolygonTool.d'


Tools.States.Transitions dd MoveTool.States.Transitions, PointTool.States.Transitions, SegmentTool.States.Transitions, \
                            CircleWithCenterTool.States.Transitions, LineTool.States.Transitions, EllipseTool.States.Transitions, \
                            PolylineTool.States.Transitions, PolygonTool.States.Transitions, 0

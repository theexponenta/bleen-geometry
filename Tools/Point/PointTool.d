
PointTool.States.PlacePoint = 1


PointTool.States.PlacePoint.Transitions dd WM_LBUTTONDOWN, PointTool.PlacePoint, 0


PointTool.States.Transitions dd PointTool.States.PlacePoint.Transitions, 0



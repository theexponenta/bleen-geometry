

MidpointOrCenterTool.States.SelectObject = 1


MidpointOrCenterTool.States.SelectObject.Transitions dd WM_LBUTTONDOWN, MidpointOrCenterTool.SelectObject, 0


MidpointOrCenterTool.States.Transitions dd MidpointOrCenterTool.States.SelectObject.Transitions, 0


DrawArea.wcexClass.ClassName du 'DRAW_AREA_CLASS', 0
DrawArea.hwnd dd ?

DrawArea.hDC dd ?
DrawArea.MainBufferDC dd ?
DrawArea.AxesGridBufferDC dd ?

DrawArea.PaintStruct PAINTSTRUCT ?
DrawArea.Width dd ?
DrawArea.Height dd ?
DrawArea.Rect RECT ?

DrawArea.MainPopupMenu.Handle dd ?
DrawArea.MainPopupMenu.Commands.ShowAxes = 1
DrawArea.MainPopupMenu.Commands.ShowGrid = 2
DrawArea.MainPopupMenu.Commands.SnapToGrid = 3
DrawArea.MainPopupMenu.Strings.ShowAxes du 'Show axes', 0
DrawArea.MainPopupMenu.Strings.ShowGrid du 'Show grid', 0
DrawArea.MainPopupMenu.Strings.SnapToGrid du 'Snap to grid', 0

DrawArea.AxesTickFont dd ?
DrawArea.AxesTickFontFamily du 'Impact', 0

DrawArea.OffsetX = 0
DrawArea.OffsetY = 40
DrawArea.AxesWidth = 1
DrawArea.AxesColor = 0x252525
DrawArea.AxisTickLength = 5
DrawArea.AxisTickFontSize = 15
DrawArea.TickLabelDistanceFromAxis = 15
DrawArea.GridLinesWidth = 1
DrawArea.GridLinesColor = 0xC0C0C0

DrawArea.XAxis = 0
DrawArea.YAxis = 1



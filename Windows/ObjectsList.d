
ObjectsListWindow.wcexClass.ClassName du 'OBJECTS_LIST_CLASS', 0
ObjectsListWindow.hWnd dd ?
ObjectsListWindow.PaintStruct PAINTSTRUCT ?
ObjectsListWindow.NeedsRedraw db 0

ObjectsListWindow.Width dd 300
ObjectsListWindow.Height dd ?

ObjectsListWindow.VisibilityCircleColor = 0x00E6C1A1
ObjectsListWindow.VisibilityCircleBorderWidth = 2
ObjectsListWindow.SeparatorWidth = 2
ObjectsListWindow.SeparatorColor = 0x00DCDCDC
ObjectsListWindow.hSeparatorPen dd ?
ObjectsListWindow.hVisibilityCirclePen dd ?
ObjectsListWindow.hVisibilityCircleWhiteBrush dd ?
ObjectsListWindow.hVisibilityCircleFilledBrush dd ?
ObjectsListWindow.hBackgroundBrush dd ?

ObjectsListWindow.ListItemMarginLeft = 10
ObjectsListWindow.ListItemMarginBottom = 20
ObjectsListWindow.ListItemPadding = 10
ObjectsListWindow.ListItemHeight = ObjectsListWindow.ListItemPadding*2 + ObjectsListWindow.ListItemMarginBottom
ObjectsListWindow.VisibilityCircleRadius = 10
ObjectsListWindow.VisibilityCircleMarginRight = 10
ObjectsListWindow.VisibilityCircleSectionWidth = ObjectsListWindow.ListItemMarginLeft + ObjectsListWindow.VisibilityCircleRadius*2 + \
                                                 ObjectsListWindow.VisibilityCircleMarginRight
ObjectsListWindow.VisibilityCircleSeparatorXOffset = ObjectsListWindow.VisibilityCircleRadius * 2 + ObjectsListWindow.ListItemMarginLeft + \
                                                     ObjectsListWindow.VisibilityCircleMarginRight
ObjectsListWindow.TextMarginLeft = 10

ObjectsListWindow.ScrollStep = 15

ObjectsListWindow.CurrentListHeight dd 0
ObjectsListWindow.CurrentScroll dd 0


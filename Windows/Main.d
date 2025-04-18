
BTNS_AUTOSIZE = 0010h

MainWindow.wcexClass.ClassName du 'MAIN_WINDOW_CLASS', 0
MainWindow.hwnd dd ?
MainWindow.Title du 'BleenGeometry', 0

MainWindow.Toolbar.hwnd dd ?
MainWindow.ToolbarHeight = 40
MainWindow.Toolbar.BitmapSize = 24
MainWindow.Toolbar.Buttons TBBUTTON 0, TOOL_MOVE, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 1, TOOL_POINT, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 2, TOOL_SEGMENT, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 3, TOOL_CIRCLE_WITH_CENTER, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 4, TOOL_LINE, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 5, TOOL_ELLIPSE, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 6, TOOL_POLYLINE, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 7, TOOL_POLYGON, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 8, TOOL_PARABOLA, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 9, TOOL_INTERSECTION, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 10, TOOL_ANGLE_BISECTOR, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 11, TOOL_PERPENDICULAR, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 12, TOOL_PERPENDICULAR_BISECTOR, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 13, TOOL_PARALLEL_LINE, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 14, TOOL_MIDPOINT_OR_CENTER, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 0, 0, TBSTATE_ENABLED, TBSTYLE_SEP, 0, 0, NULL
                           TBBUTTON 15, TOOL_PLOT, TBSTATE_ENABLED, TBSTYLE_BUTTON, 0, 0, NULL


MainWindow.Toolbar.ButtonsCount = ($ - MainWindow.Toolbar.Buttons) / sizeof.TBBUTTON

MainWindow.SplitterBarWidth = 3
MainWindow.hSplitterCursor dd ?
MainWindow.IsResizing db 0

MainWindow.hMainMenu dd ?
MainWindow.MenuCommandProcedures dd MainWindow.OpenFile, MainWindow.Save, MainWindow.SaveAs, MainWindow.Exit

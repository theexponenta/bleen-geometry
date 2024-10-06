
BTNS_AUTOSIZE = 0010h

MainWindow.wcexClass.ClassName du 'MAIN_WINDOW_CLASS', 0
MainWindow.hwnd dd ?
MainWindow.Title du 'Suck Dick', 0

MainWindow.Toolbar.hwnd dd ?
MainWindow.Toolbar.BitmapSize = 24
MainWindow.Toolbar.Buttons TBBUTTON 0, TOOL_MOVE, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 1, TOOL_POINT, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 2, TOOL_SEGMENT, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 3, TOOL_CIRCLE_WITH_CENTER, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL
                           TBBUTTON 4, TOOL_LINE, TBSTATE_ENABLED, TBSTYLE_CHECKGROUP, 0, 0, NULL

MainWindow.Toolbar.ButtonsCount = ($ - MainWindow.Toolbar.Buttons) / sizeof.TBBUTTON

WorkArea RECT ?

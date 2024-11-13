
OBJ_POINT = 1
OBJ_SEGMENT = 2
OBJ_CIRCLE_WITH_CENTER = 3
OBJ_LINE = 4
OBJ_ELLIPSE = 5
OBJ_POLYLINE = 6
OBJ_POLYGON = 7
OBJ_PARABOLA = 8

struct GeometryObject
    Id dd ?
    Type db ?
    IsSelected db ?
    AttachedPointsIds Vector ?
    pName dd ? ; Delphi-string
    pCaption dd ? ; Delphi-string
ends


GeometryObject.DefaultLineWidth = 3
GeometryObject.DefaultLineColor = 0x00616161
GeometryObject.SelectedLineColor = 0x00DFDFDF
GeometryObject.AttachedPointsIds.DefaultCapacity = 2
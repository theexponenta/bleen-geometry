

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
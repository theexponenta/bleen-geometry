

struct GeometryObject
    Id dd ?
    Type db ?
    IsSelected db ?
    AttachedPointsIds Vector ?
    pName dd ? ; Delphi-string
    pCaption dd ? ; Delphi-string
ends


GeometryObject.AttachedPointsIds.DefaultCapacity = 2
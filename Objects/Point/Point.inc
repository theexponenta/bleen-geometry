
OBJ_POINT = 1


struct Point GeometryObject
    X dd ?
    Y dd ?
    Color dd ?
    Size dd ?
    ParentObjectId dd ?
ends


Point.DefaultColor = 0x00C06515
Point.DefaultSize = 7
Point.BorderSize = 1
Point.SelectedBorderSize = 3

; Position of name text is calculated as (x + Point.NameTextOffset; y - Point.NameTextOffset)
Point.NameTextOffset = 20


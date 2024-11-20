
struct Point GeometryObject
    Size dd ?
    Color dd ?
    X dd ?
    Y dd ?
    ParentObjectId dd ?
    IntersectionId dd ?
ends


Point.DefaultColor = 0x00C06515
Point.IntersectionDefaultColor = 0x616161
Point.DefaultSize = 7
Point.BorderSize = 1
Point.SelectedBorderSize = 3

; Position of name text is calculated as (x + Point.NameTextOffset; y - Point.NameTextOffset)
Point.NameTextOffset = 20

Point.EditableProperties = PROP_NAME or PROP_CAPTION or PROP_COLOR or PROP_SIZE


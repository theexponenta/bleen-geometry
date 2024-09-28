
OBJ_POINT = 1


struct Point GeometryObject
    X dd ?
    Y dd ?
    Color dd ?
    Size dd ?
    ParentObjectId dd ?
ends


Point.DefaultColor = 0xFF1565C0
Point.DefaultSize equ 7f
Point.BorderSize equ 1f
Point.SelectedBorderSize equ 3f

; Position of name text is calculated as (x + Point.NameTextOffset; y - Point.NameTextOffset)
Point.NameTextOffset = 20


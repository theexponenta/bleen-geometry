
PROP_NAME = 1
PROP_CAPTION = 2

; Size can be "Width" property for such object as Segment, Line, Circle etc.
; and "Size" property for Point object
PROP_SIZE = 4
PROP_SIZE.MinValue = 1
PROP_SIZE.MaxValue = 13

PROP_COLOR = 8

; Offset of editable property must be the same for all the objects that have this property
PROP_NAME.Offset = GeometryObject.pName
PROP_CAPTION.Offset = GeometryObject.pCaption
PROP_SIZE.Offset = Segment.Width
PROP_COLOR.Offset = Point.Color

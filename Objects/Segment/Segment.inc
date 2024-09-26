
OBJ_SEGMENT = 2


struct Segment GeometryObject
    Point1Id dd ?
    Point2Id dd ?
    Width dd ?
    Color dd ?
ends


Segment.DefaultColor = 0xFF616161
Segment.DefaultWidth equ 3.0
Segment.SelectedShadowOpacity = 60




struct PerpendicularBisector GeometryObject
    Width dd ?
    Color dd ?
    Vector.Point1 POINT ?
    Vector.Point2 POINT ?
    Point1Id dd ?
    Point2Id dd ?

    ; Perpendicular bisector can be applied to segment.
    ; In this case we will store segment's points ids.
    ; But if we try to delete a segment, point's won't be deleted
    ; and perpendicular bisector, therefore, also won't be deleted.
    ; So, we need to store segment id just for dependency
    SegmentId dd ?
ends


PerpendicularBisector.EditableProperties = PROP_NAME or PROP_SIZE or PROP_COLOR
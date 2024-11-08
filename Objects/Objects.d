include 'Point/Point.d'
include 'Segment/Segment.d'
include 'Line/Line.d'
include 'CircleWithCenter/CircleWithCenter.d'
include 'Ellipse/Ellipse.d'
include 'GeometryObject.d'


Objects.DrawProcedures dd Point.Draw, Segment.Draw, CircleWithCenter.Draw, Line.Draw, EllipseObj.Draw, PolylineObj.Draw, PolygonObj.Draw

Objects.IsOnPositionProcedures dd Point.IsOnPosition, Segment.IsOnPosition, CircleWithCenter.IsOnPosition, \
                                  Line.IsOnPosition, EllipseObj.IsOnPosition, PolylineObj.IsOnPosition, \
                                  PolygonObj.IsOnPosition

Objects.MoveProcedures dd Point.Move, Segment.Move, CircleWithCenter.Move, Line.Move, EllipseObj.Move, PolylineObj.Move, PolygonObj.Move

Objects.DependencyObjectsIdsOffsets dd 0, Segment.DependencyObjectsIdsOffsets, CircleWithCenter.DependencyObjectsIdsOffsets, \
                                          Line.DependencyObjectsIdsOffsets, EllipseObj.DependencyObjectsIdsOffsets, \
                                          0, \  ; Polyline dependency points are not fixed, they are stored in vector, so we defined a separate procedure PolylineObj.DependsOnObject
                                          0 ; The same story about polygon


Objects.EditableProperties dd Point.EditableProperties, Segment.EditableProperties, CircleWithCenter.EditableProperties, \
                              Line.EditableProperties, EllipseObj.EditableProperties, PolylineObj.EditableProperties, \
                              PolygonObj.EditableProperties


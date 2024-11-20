include 'Point/Point.d'
include 'Segment/Segment.d'
include 'Line/Line.d'
include 'CircleWithCenter/CircleWithCenter.d'
include 'Ellipse/Ellipse.d'
include 'Parabola/Parabola.d'
include 'AngleBisector/AngleBisector.d'
include 'GeometryObject.d'


Objects.DrawProcedures dd Point.Draw, Segment.Draw, CircleWithCenter.Draw, Line.Draw, EllipseObj.Draw, PolylineObj.Draw, PolygonObj.Draw, \
                          Parabola.Draw, Intersection.Draw, AngleBisector.Draw

Objects.IsOnPositionProcedures dd Point.IsOnPosition, Segment.IsOnPosition, CircleWithCenter.IsOnPosition, \
                                  Line.IsOnPosition, EllipseObj.IsOnPosition, PolylineObj.IsOnPosition, \
                                  PolygonObj.IsOnPosition, Parabola.IsOnPosition, Intersection.IsOnPosition, \
                                  AngleBisector.IsOnPosition

Objects.MoveProcedures dd Point.Move, Segment.Move, CircleWithCenter.Move, Line.Move, EllipseObj.Move, PolylineObj.Move, PolygonObj.Move, \
                          Parabola.Move, Intersection.Move, AngleBisector.Move

Objects.DependencyObjectsIdsOffsets dd    Point.DependencyObjectsIdsOffsets, Segment.DependencyObjectsIdsOffsets, CircleWithCenter.DependencyObjectsIdsOffsets, \
                                          Line.DependencyObjectsIdsOffsets, EllipseObj.DependencyObjectsIdsOffsets, \
                                          0, \  ; Polyline dependency points are not fixed, they are stored in vector, so we defined a separate procedure PolylineObj.DependsOnObject
                                          0, \ ; The same story about polygon
                                          Parabola.DependencyObjectsIdsOffsets, \
                                          0, \ ; Same for intersection
                                          AngleBisector.DependencyObjectsIdsOffsets


Objects.EditableProperties dd Point.EditableProperties, Segment.EditableProperties, CircleWithCenter.EditableProperties, \
                              Line.EditableProperties, EllipseObj.EditableProperties, PolylineObj.EditableProperties, \
                              PolygonObj.EditableProperties, Parabola.EditableProperties, 0, AngleBisector.EditableProperties


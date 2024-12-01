include 'Point/Point.d'
include 'Segment/Segment.d'
include 'Line/Line.d'
include 'CircleWithCenter/CircleWithCenter.d'
include 'Ellipse/Ellipse.d'
include 'Parabola/Parabola.d'
include 'AngleBisector/AngleBisector.d'
include 'Perpendicular/Perpendicular.d'
include 'Polyline/Polyline.d'
include 'Polygon/Polygon.d'
include 'Intersection/Intersection.d'
include 'PerpendicularBisector/PerpendicularBisector.d'
include 'GeometryObject.d'


Objects.DrawProcedures dd Point.Draw, Segment.Draw, CircleWithCenter.Draw, Line.Draw, EllipseObj.Draw, PolylineObj.Draw, PolygonObj.Draw, \
                          Parabola.Draw, Intersection.Draw, AngleBisector.Draw, Perpendicular.Draw, PerpendicularBisector.Draw

Objects.UpdateProcedures dd 0, Segment.Update, 0, Line.Update, 0, 0, 0, 0, 0, AngleBisector.Update, Perpendicular.Update, PerpendicularBisector.Update


Objects.IsOnPositionProcedures dd Point.IsOnPosition, Segment.IsOnPosition, CircleWithCenter.IsOnPosition, \
                                  Line.IsOnPosition, EllipseObj.IsOnPosition, PolylineObj.IsOnPosition, \
                                  PolygonObj.IsOnPosition, Parabola.IsOnPosition, Intersection.IsOnPosition, \
                                  AngleBisector.IsOnPosition, Perpendicular.IsOnPosition, PerpendicularBisector.IsOnPosition

Objects.MoveProcedures dd Point.Move, Segment.Move, CircleWithCenter.Move, Line.Move, EllipseObj.Move, PolylineObj.Move, PolygonObj.Move, \
                          Parabola.Move, Intersection.Move, AngleBisector.Move, Perpendicular.Move, PerpendicularBisector.Move

Objects.ToStringProcedures dd Point.ToString, Segment.ToString, CircleWithCenter.ToString, Line.ToString, EllipseObj.ToString, PolylineObj.ToString, \
                          PolygonObj.ToString, Parabola.ToString, Intersection.ToString, AngleBisector.ToString, \
                          Perpendicular.ToString, PerpendicularBisector.ToString

Objects.DependencyObjectsIdsOffsets dd    Point.DependencyObjectsIdsOffsets, Segment.DependencyObjectsIdsOffsets, CircleWithCenter.DependencyObjectsIdsOffsets, \
                                          Line.DependencyObjectsIdsOffsets, EllipseObj.DependencyObjectsIdsOffsets, \
                                          0, \  ; Polyline dependency points are not fixed, they are stored in vector, so we defined a separate procedure PolylineObj.DependsOnObject
                                          0, \ ; The same story about polygon
                                          Parabola.DependencyObjectsIdsOffsets, \
                                          0, \ ; Same for intersection
                                          AngleBisector.DependencyObjectsIdsOffsets, \
                                          Perpendicular.DependencyObjectsIdsOffsets, \
                                          PerpendicularBisector.DependencyObjectsIdsOffsets


Objects.EditableProperties dd Point.EditableProperties, Segment.EditableProperties, CircleWithCenter.EditableProperties, \
                              Line.EditableProperties, EllipseObj.EditableProperties, PolylineObj.EditableProperties, \
                              PolygonObj.EditableProperties, Parabola.EditableProperties, 0, AngleBisector.EditableProperties, \
                              Perpendicular.EditableProperties, PerpendicularBisector.EditableProperties


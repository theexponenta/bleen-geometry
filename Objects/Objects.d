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
include 'ParallelLine/ParallelLine.d'
include 'Plot/Plot.d'
include 'GeometryObject.d'


Objects.StructSizes dd sizeof.Point, sizeof.CircleWithCenter, sizeof.Segment, sizeof.Line, sizeof.EllipseObj, sizeof.PolylineObj, sizeof.PolygonObj, \
                      sizeof.Parabola, sizeof.Intersection, sizeof.AngleBisector, sizeof.Perpendicular, sizeof.PerpendicularBisector, \
                      sizeof.ParallelLine, sizeof.Plot


Objects.DrawProcedures dd Point.Draw, CircleWithCenter.Draw, Segment.Draw, Line.Draw, EllipseObj.Draw, PolylineObj.Draw, PolygonObj.Draw, \
                          Parabola.Draw, Intersection.Draw, AngleBisector.Draw, Perpendicular.Draw, PerpendicularBisector.Draw, \
                          ParallelLine.Draw, Plot.Draw

Objects.UpdateProcedures dd 0, 0, Segment.Update, Line.Update, 0, 0, 0, 0, 0, AngleBisector.Update, Perpendicular.Update,  \
                            PerpendicularBisector.Update, ParallelLine.Update, 0


Objects.IsOnPositionProcedures dd Point.IsOnPosition, CircleWithCenter.IsOnPosition, Segment.IsOnPosition, \
                                  Line.IsOnPosition, EllipseObj.IsOnPosition, PolylineObj.IsOnPosition, \
                                  PolygonObj.IsOnPosition, Parabola.IsOnPosition, Intersection.IsOnPosition, \
                                  AngleBisector.IsOnPosition, Perpendicular.IsOnPosition, PerpendicularBisector.IsOnPosition, \
                                  ParallelLine.IsOnPosition, Plot.IsOnPosition

Objects.MoveProcedures dd Point.Move,  CircleWithCenter.Move, Segment.Move, Line.Move, EllipseObj.Move, PolylineObj.Move, PolygonObj.Move, \
                          Parabola.Move, Intersection.Move, AngleBisector.Move, Perpendicular.Move, PerpendicularBisector.Move, \
                          ParallelLine.Move, Plot.Move

Objects.ToStringProcedures dd Point.ToString, CircleWithCenter.ToString, Segment.ToString, Line.ToString, EllipseObj.ToString, PolylineObj.ToString, \
                          PolygonObj.ToString, Parabola.ToString, Intersection.ToString, AngleBisector.ToString, \
                          Perpendicular.ToString, PerpendicularBisector.ToString, ParallelLine.ToString, Plot.ToString

Objects.DependencyObjectsIdsOffsets dd    Point.DependencyObjectsIdsOffsets, CircleWithCenter.DependencyObjectsIdsOffsets, Segment.DependencyObjectsIdsOffsets, \
                                          Line.DependencyObjectsIdsOffsets, EllipseObj.DependencyObjectsIdsOffsets, \
                                          0, \  ; Polyline dependency points are not fixed, they are stored in vector, so we defined a separate procedure PolylineObj.DependsOnObject
                                          0, \ ; The same story about polygon
                                          Parabola.DependencyObjectsIdsOffsets, \
                                          0, \ ; Same for intersection
                                          AngleBisector.DependencyObjectsIdsOffsets, \
                                          Perpendicular.DependencyObjectsIdsOffsets, \
                                          PerpendicularBisector.DependencyObjectsIdsOffsets, \
                                          ParallelLine.DependencyObjectsIdsOffsets, \
                                          0


Objects.EditableProperties dd Point.EditableProperties, CircleWithCenter.EditableProperties, Segment.EditableProperties, \
                              Line.EditableProperties, EllipseObj.EditableProperties, PolylineObj.EditableProperties, \
                              PolygonObj.EditableProperties, Parabola.EditableProperties, 0, AngleBisector.EditableProperties, \
                              Perpendicular.EditableProperties, PerpendicularBisector.EditableProperties, ParallelLine.EditableProperties, \
                              Plot.EditableProperties



struct ChangeHistoryRecord
    Type db ?
    GroupId dd ?
    Object ByteArray ?
ends


struct ChangeHistory
    CurrentGroupId dd ?
    TotalRecordsCount dd ? ; Including popped
    PoppedRecordsCount dd ?
    History Vector ?
ends


ChangeHistory.InitialCapacity = 50

ChangeHistoryRecord.Type.ADD_OBJECT = 1
ChangeHistoryRecord.Type.DELETE_OBJECT = 2



ESB_ENABLE_BOTH = 0
SW_INVALIDATE = 2

CCHILDREN_SCROLLBAR = 5
SBM_GETSCROLLBARINFO = 0x00EB
OBJID_VSCROLL = 0xFFFFFFFB

struct SCROLLBARINFO
    cbSize dd ?
    rcScrollBar RECT ?
    dxyLineButton dd ?
    xyThumbTop dd ?
    xyThumbBottom dd ?
    reserved dd ?
    rgstate dd (CCHILDREN_SCROLLBAR + 1) dup(?)
ends


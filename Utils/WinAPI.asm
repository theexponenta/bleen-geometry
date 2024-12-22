
proc WinAPIUtils.GetWindowHeight, hWnd
    locals
        WindowRect RECT ?
    endl

    lea eax, [WindowRect]
    invoke GetWindowRect, [hWnd], eax
    mov eax, [WindowRect.bottom]
    sub eax, [WindowRect.top]

    ret
endp


proc WinAPIUtils.GetTextSize, hWnd, pText, pSize
    locals
        hDC dd ?
    endl

    invoke GetDC, [hWnd]
    mov [hDC], eax

    invoke lstrlenW, [pText]
    invoke GetTextExtentPoint32W, [hDC], [pText], eax, [pSize]

    invoke ReleaseDC, [hDC]

    ret
endp
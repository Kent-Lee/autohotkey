﻿; Last Revision: 2019-02-23

; AUTO EXECUTE ====================================================================================
 
; details for script optimization: 
    ; https://autohotkey.com/docs/misc/Performance.htm
    ; https://www.autohotkey.com/boards/viewtopic.php?t=6413

; set current folder as starting directory
SetWorkingDir %A_ScriptDir%

; prevent empty variables from being looked up as environment variables
#NoEnv

; default script run speed == sleep 10 ms/line. Make it -1 to not sleep (run at maximum speed)
SetBatchLines -1

; set priority higher than normal Windows programs to improve performance
Process, Priority, , High

; ensure that there is only a single instance of this script running
#SingleInstance Force

; disable logging keys as they are only useful for debugging
#KeyHistory 0
ListLines Off

; set SendMode to SendInput to have no delay between keystrokes
SendMode Input

; if SendInput unavailable, SendEvent is used; set delays at -1 to improve SendEvent's speed
SetKeyDelay, -1, -1
SetMouseDelay, -1

; a short delay is done after every command (i.e. WinActivate) to give a window a chance to update and respond. A delay of -1 (no delay) is allowed but it is recommended to use at least 0 to increase confidence that the script will run correctly when CPU is under load
SetWinDelay, 0
SetControlDelay, 0
SetDefaultMouseSpeed, 0

; hide system tray icon
#NoTrayIcon

; prevent task bar icons from flashing when different windows are activated quickly one after the other
#WinActivateForce

; turn off CapsLock and ScrollLock
SetNumLockState, AlwaysOn
SetCapsLockState, AlwaysOff
SetScrollLockState, AlwaysOff

; set title matching to search for "containing" instead of "exact"
SetTitleMatchMode, 2

; add Explorer windows to group
GroupAdd, explorerGroup, ahk_class CabinetWClass

; custom scripts
#include %A_ScriptDir%
#include AutoCorrect.ahk

; end of auto execute section
return

; FUNCTIONS =======================================================================================

; activate program, if not exist open it, if active minimize it
; directory_path is the starting directory of the program
ActivateProgram(program, program_path, directory_path := "")
{
    if (!WinExist(program)) {
        Run, % program_path, % directory_path
        WinWaitActive, % program, , 2
        MoveWindow()
    }
    else if (!WinActive(program))
        WinActivate
    else
        WinMinimize
    return
}

; http://the-automator.com/?s=encode
; encode str to uri format
UriEncode(str)
{
    ; set new_str's capacity == buffer size of str + "\0"(null terminator)
    VarSetCapacity(new_str, StrPut(str, "UTF-8"), 0)
    ; write str to new_str with UTF-8 encoding
    StrPut(str, &new_str, "UTF-8")
    ; set code == binary number of each character in new_str
    while (code := NumGet(new_str, A_Index-1, "UChar"))
        ; concatenate chr, if Chr(code) matches regex, use chr, else use hex of code
        ; e.g. code == 15, %X == F (in hex), %02X == 0F (expect >2 characters, prepend with zeros if less)
        ; need to prepend zeros to single hex character to decode correctly later
        res .= (chr := Chr(code)) ~= "[0-9A-Za-z]" ? chr : Format("%{:02X}", code)
    return res
}

; decode uri str to original format
UriDecode(str)
{
    loop {
        if (RegExMatch(str, "i)(?<=%)[0-9a-f]{1,2}", hex))
            StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
        else break
    }
    return str
}

; search specified website by selected text, if it contains "http", open the url instead
SearchWebsite(website, keyword := "")
{
    Clipboard := ""
    Send, ^c
    ClipWait, 0
    keyword := (keyword) ? keyword : Clipboard
    if (InStr(keyword, "http"))
        action := % keyword
    else if (website == "youtube")
        action := "https://www.youtube.com/results?search_query=" . UriEncode(keyword)
    else if (website == "google")
        action := "http://www.google.com/search?q=" . UriEncode(keyword)
    Run, % action
    return
}

; search tab by input/keyword in current active program, if no match, do actions dependent on programs
; the search is based on window title (e.g. Chrome tab title)
; the user input is triggered after 5 seconds or pressing Enter
SearchTab(keyword := "")
{
    WinGet, program, ProcessName, A
    if (program == "chrome.exe" || program == "Code.exe") {
        switch_tab := "^{PgDn}"
        action := "http://www.google.com/search?q=" . UriEncode(keyword)
    }
    else if (program == "Explorer.EXE") {
        switch_tab := "{F4}"
        action := "find G:\"
    }
    else return

    if (!keyword)
        Input, keyword, B T5 E, {Enter}
    WinGetTitle, current_tab, A
    original_tab := current_tab
    loop {
        if (InStr(current_tab, keyword))
            return
        Send, % switch_tab
        Sleep, 30
        WinGetTitle, current_tab, A
        if (current_tab = original_tab) {
            Run, % action
            return
        }
    }
    return
}

; https://goo.gl/DtZL8P
; check if mouse is hovering an existing window (no need to be active)
MouseHover(window_class)
{
    MouseGetPos, , , A
    return WinExist(window_class . " ahk_id " . A)
}

; check if mouse is over an active window
MouseOver(window_class, y_boundary)
{
    MouseGetPos, x, y, A
    return WinActive(window_class . " ahk_id " . A) && (y < y_boundary)
}

; move active window to specified position
MoveWindow(position := "middle")
{
    WinRestore, A
    x := 0
    y := 0
    width := A_ScreenWidth
    height := A_ScreenHeight

    if (position == "middle") {
        width /= 1.4
        height /= 1.4
        x := A_ScreenWidth / 2 - width / 2
        y := A_ScreenHeight / 2 - height / 2
    }
    if (InStr(position, "left"))
        width /= 2
    if (InStr(position, "top"))
        height /= 2
    if (InStr(position, "right"))
        x := width /= 2
    if (InStr(position, "bottom"))
        y := height /= 2

    WinMove, A, , x, y, width, height
    return
}

; set active window always on top and transparent, 0 == invisible, 1 == opaque
FocusWindow(transparency)
{
    transparency := Floor(transparency * 255)
    WinSet, AlwaysOnTop, toggle, A
    WinGet, current_transparency, Transparent, A
    WinSet, Transparent, % (current_transparency == transparency) ? "Off" : transparency, A
    return
}


; SCRIPT ==========================================================================================

; AHK control
CapsLock & F5::Reload
CapsLock & F10::Run, C:\Program Files\AutoHotkey\WindowSpy.ahk
CapsLock & Pause::
    Suspend
    Pause, , 1
    return
CapsLock & ScrollLock::ExitApp

; program shortcut
; note that program names and paths are set to my PC's configuration
CapsLock & a::ActivateProgram("ahk_exe AcroRd32.exe", "AcroRd32.exe")
CapsLock & e::ActivateProgram("ahk_class CabinetWClass", "explorer.exe")
CapsLock & c::ActivateProgram("ahk_exe Code.exe" ,"C:\Program Files\Microsoft VS Code\Code.exe")
CapsLock & g::ActivateProgram("ahk_exe chrome.exe", "chrome.exe")
CapsLock & t::ActivateProgram("ahk_exe mintty.exe", "C:\Program Files\Git\git-bash.exe", "C:\Users\kent")
CapsLock & o::Run, C:\Program Files (x86)\Battle.net\Battle.net.exe
CapsLock & l::Run, D:\Games\League of Legends\LeagueClient.exe
CapsLock & s::SearchTab()
F2::SearchWebsite("google")
F3::SearchWebsite("youtube")
F4::GroupActivate, explorerGroup, R
CapsLock & q::SearchTab("youtube")

; windows navigation
CapsLock & Space::AltTab
CapsLock & Numpad1::MoveWindow("bottom left")
CapsLock & Numpad2::MoveWindow("bottom")
CapsLock & Numpad3::MoveWindow("bottom right")
CapsLock & Numpad4::MoveWindow("left")
CapsLock & Numpad5::MoveWindow()
CapsLock & Numpad6::MoveWindow("right")
CapsLock & Numpad7::MoveWindow("top left")
CapsLock & Numpad8::MoveWindow("top")
CapsLock & Numpad9::MoveWindow("top right")
CapsLock & f::FocusWindow(0.75)

; editing macros
+Left::Send, +{Home}
+Right::Send, +{End}
+BackSpace::Send, +{Home}{Del}
+Del::Send, +{End}{Del}
; remove formatting
CapsLock & v::
    Clipboard := Clipboard
    Send, ^v
    return

; media control
; mute microphone, 9 is my device number, which can be found by running SoundCard.ahk
Pause::SoundSet, +1, MASTER, MUTE, 9
CapsLock & Down::Send, {Media_Play_Pause}
CapsLock & Left::Send, {Media_Prev}
CapsLock & Right::Send, {Media_Next}

; system control
#Del::FileRecycleEmpty
#c::Run, Control
; lock system and turn off screen
#l::
    DllCall("LockWorkStation")
    SendMessage 0x112, 0xF170, 2, , Program Manager
    return

; mouse control
; scroll to mouse position instantly
CapsLock & Mbutton::
    MouseGetPos, mouse_x, mouse_y
    WinGetPos, win_x, win_y, win_w, win_h, A
    MouseMove, win_w-15, mouse_y, 0
    Send, +{LButton}
    MouseMove, mouse_x, mouse_y, 0
    return
; https://goo.gl/vRsUaN
; move mouse pixel by pixel for dragging/drawing graphics
CapsLock & Numpad0::Send, % (toggle := !toggle) ? "{LButton Down}" : "{LButton Up}"
#If toggle
    LButton::return
    CapsLock & Numpad1::MouseMove, -1, 1, 0, R
    CapsLock & Numpad2::MouseMove, 0, 1, 0, R
    CapsLock & Numpad3::MouseMove, 1, 1, 0, R
    CapsLock & Numpad4::MouseMove, -1, 0, 0, R
    CapsLock & Numpad5::return
    CapsLock & Numpad6::MouseMove, 1, 0, 0, R
    CapsLock & Numpad7::MouseMove, -1, -1, 0, R
    CapsLock & Numpad8::MouseMove, 0, -1, 0, R
    CapsLock & Numpad9::MouseMove, 1, -1, 0, R
#If MouseHover("ahk_class Shell_TrayWnd")
    WheelUp::Send, +!{Tab}
    WheelDown::Send, !{Tab}
#If MouseOver("ahk_class Chrome_WidgetWin_1", 100)
    WheelUp::Send, ^{PgUp}
    WheelDown::Send, ^{PgDn}
#If
return

; macros in programs
#IfWinActive ahk_exe Code.exe
    CapsLock & i::Send, {Up}
    CapsLock & l::Send, {Right}
    CapsLock & k::Send, {Down}
    CapsLock & j::Send, {Left}
    CapsLock & u::Send, ^{PgUp}
    CapsLock & o:: Send, ^{PgDn}
    CapsLock & Enter:: Send, {End}{Enter}
    CapsLock & r::Send, ^+t
#IfWinActive ahk_exe mintty.exe
    ^v::Send, {Raw}%Clipboard%
#IfWinActive ahk_exe chrome.exe
    CapsLock & r::Send, ^+t
    $^f::
        Clipboard := ""
        Send, ^c
        ClipWait, 0
        Send, ^f
        Send, % Clipboard
        return
#IfWinActive ahk_class OpusApp
    ^Left::Send, ^+{Left}
    ^Right::Send, ^+{Right}
    CapsLock & i::Send, {Up}
    CapsLock & l::Send, {Right}
    CapsLock & k::Send, {Down}
    CapsLock & j::Send, {Left}
    :*B0:(::){Left}
    :*B0:[::]{Left}
    :*B0:<::>{Left}
    :*B0:{::{}}{Left}
#IfWinActive ahk_class CabinetWClass
    Esc::Send, !{F4}
#IfWinActive
return

; NOT USE =========================================================================================
; snippet - here for reference only
; issues:
    ; inconsistent input in certain applications
    ; no longer needed as editors have this feature built in (except Word lol)
/*
:*B0:(::){Left}
:*B0:[::]{Left}
:*B0:<::>{Left}
:*B0:{::{}}{Left}

:*B0O:if`t::()`n{{}`n`n{}}{Up}`t{Up 2}{End}{Left}
:*B0O:else if`t::()`n{{}`n`n{}}{Up}`t{Up 2}{End}{Left}
:*B0O:else`t:: {Bs}`n{{}`n`n{}}{Up}`t
:*B0O:for`t::()`n{{}`n`n{}}{Up}`t{Up 2}{End}{Left}
:*B0O:while`t::()`n{{}`n`n{}}{Up}`t{Up 2}{End}{Left}
*/

; change MTU to 576 (for Mabinogi)/1500 (check MTU value with cmd --> netsh interface ipv4 show subinterfaces)
/*
CapsLock & 5::Run, %comspec% /c netsh interface ipv4 set subinterface "Ethernet" mtu=576 store=persistent
CapsLock & 1::Run, %comspec% /c netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent
*/
; =================================================================================================
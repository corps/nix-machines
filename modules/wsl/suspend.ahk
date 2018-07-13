DetectHiddenWindows, On
WinGet, IDList ,List, ahk_class AutoHotkey
Loop %IDList%
{
  ID:=IDList%A_Index%
  WinGetTitle, ATitle, ahk_id %ID%
  IfNotInString, ATitle, %A_ScriptFullPath%
  {
    WinClose, ahk_id %ID% ;kill
  }
}
ExitApp

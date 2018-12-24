#InstallKeybdHook
#SingleInstance force

<^+D:: 
if WinExist("ahk_exe Brave.exe")
    WinActivate, ahk_exe Brave.exe
else
    Run "C:\Users\recur\AppData\Local\Brave\Brave.exe"
return

<^+J::
SetTitleMatchMode, 2
if WinExist("OneNote")
    WinActivate ;
return

<^+E::
if WinExist("Cmder")
    WinActivate, Cmder
else
    Run "C:\tools\cmder\Cmder.exe"
return

<^+/::
if WinExist("ahk_exe idea64.exe")
    WinActivate, ahk_exe idea64.exe
else
    Run "C:\Program Files\JetBrains\IntelliJ IDEA 2018.1.6\bin\idea64.exe"
return

<^+'::
if WinExist("ahk_exe Signal.exe")
    WinActivate, ahk_exe Signal.exe
else
    Run "C:\Users\recur\AppData\Local\Programs\signal-desktop\Signal.exe"
return

#UseHook

IsTabbing := 0

*LAlt up::
if IsTabbing
  Send {LAlt up}
else
  Send {LCtrl up}
IsTabbing := 0
return

*LAlt::
Send {LCtrl down}
return

*Tab::
if IsTabbing {
  Send {LAlt down}{Tab}
  return
}
AltIsDown := GetKeyState("Alt", "P")
if AltIsDown {
        IsTabbing := 1
	Send {LCtrl up}{LAlt down}{Tab}
}
else
	Send {Tab}
return

#InstallKeybdHook
#SingleInstance force

<^+D:: 
if WinExist("ahk_exe Brave.exe")
    WinActivate, ahk_exe Brave.exe
else
    Run "C:\Users\recur\AppData\Local\Brave\Brave.exe"
return

<^+E::
if WinExist("ahk_exe ubuntu.exe")
    WinActivate, ahk_exe ubuntu.exe
else
    Run "C:\Users\recur\AppData\Local\Microsoft\WindowsApps\ubuntu.exe"
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

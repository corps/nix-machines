set ws=wscript.createobject("wscript.shell")
ws.run "C:\Windows\System32\bash.exe -c '/nix/current-system/sw/bin/wsl-run /nix/var/nix/profiles/system/activate-user'",0

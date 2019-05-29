{ writeScriptBin }:

writeScriptBin "activate-window" ''
#!/usr/bin/env bash

activateByPid()
{
  osascript -e "
    tell application \"System Events\"
      set frontmost of the first process whose unix id is $1 to true
    end tell
  "
}

pid=$(pgrep $1)
if [[ -z $pid ]]; then
  nohup $1 >/dev/null 2>&1 &
else
  activateByPid $pid
fi
''

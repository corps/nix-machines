#! @bash@/bin/bash

PATH=@wmctrl@/bin:$PATH
if [ `wmctrl -l | grep -c "@window@"` != 0 ]
then
  [[ -e /Applications/Utilities/XQuart.app ]] && open /Applications/Utilities/XQuartz.app/
  wmctrl -a "@window@"
fi

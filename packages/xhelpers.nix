{ stdenv, wmctrl, writeScript, bash, wget, setxkbmap }:

let

bringToFrontScript = { window, name ? window }: writeScript "bring-${name}-to-front" ''
#! ${bash}/bin/bash

PATH=${wmctrl}/bin:$PATH
if [ `wmctrl -l | grep -c "${window}" != 0 ]
then
  [[ -e /Applications/Utilities/XQuartz.app ]] && open /Applications/Utilities/XQuartz.app/
  wmctrl -a "${window}"
fi
'';

in

stdenv.mkDerivation rec {
  name = "xhelpers";
  phases = [ "installPhase" ];

  bringWebstorm = bringToFrontScript { window = "WebStorm"; };
  bringRubymine = bringToFrontScript { window = "RubyMine"; };
  bringChromium = bringToFrontScript { window = "Chromium"; };
  bringTerminal = bringToFrontScript { window = "Terminal"; };

  installPhase = ''
    mkdir -p $out/bin
    cp $bringWebstorm $out/bin/bring-webstorm-to-front
    cp $bringRubymine $out/bin/bring-rubymine-to-front
    cp $bringChromium $out/bin/bring-chromium-to-front
    cp $bringTerminal $out/bin/bring-terminal-to-front
  '';
}

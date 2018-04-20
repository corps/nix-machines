{ stdenv, wmctrl, substituteAll, bash, wget, setxkbmap }:

let

bringToFrontScript = { window, name ? window }: substituteAll {
  src = ./bring-to-front.sh;
  name = "bring-${name}-to-front";
  isExecutable = true;
  inherit wmctrl window bash;
};

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

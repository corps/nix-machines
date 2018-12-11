{ config, pkgs, lib, ... }:

with lib;

let
apps = config.nativeApps;
appPairs = map (shortName: { inherit shortName; install = apps."${shortName}".install; }) (attrNames apps);
importApp = { shortName, install }@args: args // (import "${./native-apps}/${shortName}.nix");
importedApps = map importApp appPairs;

activateApp = { shortName, install, name, zipped, url }: 
  if install then ''
    if ! [ -e "/Applications/${name}" ]; then
      set -x
      curl -sL "${url}" > /tmp/darwin-rebuild-app
      ${ if zipped then "unzip -q /tmp/darwin-rebuild-app -d /tmp/" 
         else "mv /tmp/darwin-rebuild-app \"/tmp/${name}\"" }
      mv "/tmp/${name}" "/Applications/${name}"
      set +x
    fi
  '' else ''
    if [ -e "/Applications/${name}" ]; then
      set -x
      sudo rm -rf "/Applications/${name}"
      set +x
    fi
  '';

in

{
  options = {
    nativeApps = {
      vscode.install = mkOption { 
        default = true;
        type = types.bool;
        description = "Install VsCode";
      };
    };
  };

  config = {
    system.activationScripts.extraActivation.text =
      concatStringsSep "\n" (map activateApp importedApps);
  };
}

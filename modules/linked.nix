{ config, lib, pkgs, ... }:

with lib;

let
mkLink = link: "ln -s ${src} $out/bin/${out}";
linkedPackageType = types.submodule {
  options = {
    source = mkOption {
      type = types.package;
    };
    links = mkOption {
      type = types.attrsOf types.string;
    };
  };
};

in

{
  options = {
    environment.linked = mkOption {
      type = types.listOf linkedPackageType;
      default = [];
      description = "Named paths to be linked indirectly from a package.";
    };
  };

  config = {
    environment.systemPackages = map (linkPackage: pkgs.stdenv.mkDerivation (rec {
        inherit (linkPackage) source;
        name = "linked";
        phases = [ "installPhase" ];
        buildInputs = [ source ];
        installPhase = ''
          mkdir -p $out
        '' + concatStringsSep "\n" (attrsets.mapAttrsToList (k: v: "mkdir -p $(dirname ${v})\nln -s $source/${k} $out/${v}") linkPackage.links);
    })) config.environment.linked;
  };
}

{ config, lib, pkgs, ... }:

with lib;

let
mkLinks = src: dst: if builtins.isList dst then concatStringsSep "\n" (map (mkLinks src) dst) else "ln -s ${src} $out/bin/${out}"
in

{
  options = {
    linked = mkOption {
      type = types.attrsOf (types.either types.str (types.listOf types.str));
      default = {};
      description = "Paths to be linked";
    }
  };

  config = {
    packages = [(
      pkgs.stdenv.mkDerivation {
        name = "linked";
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out/bin

        '' + (builtins.foldlAttrs mkLinks "" (acc: src: dst: acc + "\n" + (linked src dst)) config.linked)
      };
    )]
  };
}

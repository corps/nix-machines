{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenvNoCC;

  cfg = config.system;

  failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.assertions);

  throwAssertions = res: if (failedAssertions != []) then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}" else res;
  showWarnings = res: fold (w: x: builtins.trace "[1;31mwarning: ${w}[0m" x) res config.warnings;

in

{
  imports = [
    ./checks.nix
    ./version.nix
    ./etc.nix
    ./activation-scripts.nix
  ];

  options = {

    system.build = mkOption {
      internal = true;
      type = types.attrsOf types.package;
      default = {};
      description = ''
        Attribute set of derivation used to setup the system.
      '';
    };

    system.path = mkOption {
      internal = true;
      type = types.package;
      description = ''
        The packages you want in the system environment.
      '';
    };

    system.profile = mkOption {
      type = types.path;
      default = "/nix/var/nix/profiles/system";
      description = ''
        Profile to use for the system.
      '';
    };

    assertions = mkOption {
      type = types.listOf types.unspecified;
      internal = true;
      default = [];
      example = [ { assertion = false; message = "you can't enable this for that reason"; } ];
      description = ''
        This option allows modules to express conditions that must
        hold for the evaluation of the system configuration to
        succeed, along with associated error messages for the user.
      '';
    };

    warnings = mkOption {
      internal = true;
      default = [];
      type = types.listOf types.str;
      example = [ "The `foo' service is deprecated and will go away soon!" ];
      description = ''
        This option allows modules to show warnings to users during
        the evaluation of the system configuration.
      '';
    };

  };

  config = {

    system.build.toplevel = throwAssertions (showWarnings (stdenvNoCC.mkDerivation {
      name = "up-system-${cfg.upLabel}";
      preferLocalBuild = true;

      activationScript = cfg.activationScripts.script.text;
      activationUserScript = cfg.activationScripts.userScript.text;
      inherit (cfg) upLabel;

      buildCommand = ''
        mkdir $out

        systemConfig=$out

        mkdir -p $out/up

        ln -s ${cfg.build.etc}/etc $out/etc
        ln -s ${cfg.path} $out/sw

        echo "$activationScript" > $out/activate
        substituteInPlace $out/activate --subst-var out
        chmod u+x $out/activate
        unset activationScript

        echo "$activationUserScript" > $out/activate-user
        substituteInPlace $out/activate-user --subst-var out
        chmod u+x $out/activate-user
        unset activationUserScript

        echo -n "$systemConfig" > $out/systemConfig

        echo -n "$upLabel" > $out/up-version
        echo -n "$system" > $out/system
      '';
    }));

  };
}

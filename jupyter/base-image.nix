{
  pkgs ? import <nixpkgs> {
    overlays = [
      (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
    ];
  },
  dockerTools ? pkgs.dockerTools,
}:

dockerTools.buildImage {
  name = "jupyter";
  tag = "base-image.nix";
  created = "now";

  config = { };

  copyToRoot = pkgs.buildEnv {
    name = "jupyter-env";
    paths =
      with pkgs;
      let
        vine = pkgs.callPackage ../vine.nix { inherit pkgs; };
      in
      [
        vine
        bash
        coreutils
        cacert
        gzip
        gnutar
        curl
        iputils
        tini
        nodejs
        curl
        python311
        gitFull
        bintools
      ];
    pathsToLink = [ "/bin" ];
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    set -x
    ${dockerTools.shadowSetup}
    useradd -Ums ${pkgs.bash}/bin/bash -u 3753 ngrok
  '';
}

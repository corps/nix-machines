{
  pkgs ? import <nixpkgs> { },
  dockerTools ? pkgs.dockerTools,
}:

let
  name = "miniflux";
in

dockerTools.buildImage {
  inherit name;
  tag = "base-image.nix";
  created = "now";

  config = {
    WorkingDir = "/home/${name}";
    Entrypoint = "/bin/";
    Cmd = [ "miniflux" ];
    Env = [
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin"
    ];
    User = name;
  };

  copyToRoot = pkgs.buildEnv {
    name = "${name}-env";
    paths = with pkgs; [
      miniflux
      bash
      coreutils
      cacert
      gzip
      gnutar
      curl
      iputils
      bintools
    ];
    pathsToLink = [ "/bin" ];
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    set -x
    ${dockerTools.shadowSetup}
    useradd -Ums ${pkgs.bash}/bin/bash -u 3753 ${name}
  '';
}

{ pkgs ? import <nixpkgs> {}
, symlinkJoin ? pkgs.symlinkJoin
, dockerTools ? pkgs.dockerTools
}:

dockerTools.buildImage {
  name = "ngrok";
  tag = "base-image.nix";
  created = "now";

  config = {
    WorkingDir = "/home/ngrok";
    Cmd = [ "ngrok" ];
    Env = [
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin"
    ];
    User = "ngrok";
  };

  copyToRoot = pkgs.buildEnv {
    name = "ngrok-env";
    paths = with pkgs; let ngrok = pkgs.callPackage ./. {}; in [ ngrok bash coreutils cacert gzip gnutar curl iputils bintools ];
    pathsToLink = [ "/bin" ];
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    set -x
    ${dockerTools.shadowSetup}
    useradd -Ums ${pkgs.bash}/bin/bash -u 3753 ngrok
  '';
}

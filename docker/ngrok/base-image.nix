{ pkgs ? import <nixpkgs> {}
, ngrok ? pkgs.ngrok
, symlinkJoin ? pkgs.symlinkJoin
, dockerTools ? pkgs.dockerTools
, bash ? pkgs.bash
, coreutils ? pkgs.coreutils
, cacert ? pkgs.cacert
, gnutar ? pkgs.gnutar
, gzip ? pkgs.gzip
, curl ? pkgs.curl
}:

dockerTools.buildImage {
  name = "ngrok";
  tag = "base-image";
  created = "now";

  config = {
    WorkingDir = "/home/ngrok";
    Cmd = [ "ngrok" ];
    Env = [
      "GIT_SSL_CAINFO=${cacert}/etc/ssl/certs/ca-bundle.crt"
      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };

  contents = symlinkJoin {
    name = "ngrok-env";
    paths = [ ngrok bash coreutils cacert gzip gnutar curl ];
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    ${dockerTools.shadowSetup}
    useradd -Ums ${bash}/bin/bash -u 6753 ngrok
  '';
}


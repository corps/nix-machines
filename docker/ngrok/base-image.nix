{ pkgs ? import <nixpkgs> {}
, symlinkJoin ? pkgs.symlinkJoin
, dockerTools ? pkgs.dockerTools
}:

dockerTools.buildImage {
  name = "ngrok";
  tag = "base-image";
  created = "now";

  config = {
    WorkingDir = "/home/ngrok";
    Cmd = [ "ngrok" ];
    Env = [
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };

  contents = symlinkJoin {
    name = "ngrok-env";
    paths = with pkgs; [ ngrok bash coreutils cacert gzip gnutar curl iputils ];
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    ${dockerTools.shadowSetup}
    useradd -Ums ${pkgs.bash}/bin/bash -u 6753 ngrok
  '';
}


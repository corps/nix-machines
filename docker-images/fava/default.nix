{ pkgs ? import <nixpkgs> {}
, fava ? pkgs.fava
, buildImage? pkgs.dockerTools.buildImage
}:

buildImage {
  name = "fava"; 
  tag = "latest"; 

  # fromImage = someBaseImage; 
  # fromImageName = null; 
  # fromImageTag = "latest"; 
  contents = fava;

  runAsRoot = '' 
    #!${pkgs.runtimeShell}
    mkdir -p /data
  '';

  config = { 
    Env = [
      "BC_FILE=/data/master.bean"
    ];
    Cmd = [ "fava -H fava.comboslice.local /data/master.bean" ];
    WorkingDir = "/data";
    Volumes = {
      "/data" = {};
    };
  };
}

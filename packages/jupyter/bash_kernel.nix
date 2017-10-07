{ pkgs, fetchFromGitHub, writeScriptBin }:

with pkgs.python35Packages;

let

bash_kernel = buildPythonPackage rec {
  version = "0.7.1";
  pname = "bash_kernel";
  name = "${pname}-${version}";

  # format = "flit";
  format = "wheel";

  propagatedBuildInputs = [ pexpect ];

  src = fetchPypi {
    inherit pname version format;
    sha256 = "0gzj1835kdxhj8ipr5hkcni8b8r2hh8afl8rzi1f9zw5ql306i15";
  };

  # src = fetchFromGitHub {
  #  owner = "takluyver";
  #  repo = "bash_kernel";
  #  rev = "0966dc102d7549f5c909c93de633a95b2af9f707";
  #  sha256 = "1yv6br6fli3s5593i6q0hgj1fkwqfd5xdn9plaabayk42i5l5g3w";
  #};
};

env = pkgs.python.buildEnv.override {
  extraLibs = let p = pkgs.python35Packages; in [ bash_kernel notebook ];
  ignoreCollisions = true;
};

in

writeScriptBin "bash_kernel" ''
#! ${pkgs.bash}/bin/bash
PATH=${pkgs.bashInteractive}/bin:${env}/bin:$PATH
exec python -m bash_kernel $@
''

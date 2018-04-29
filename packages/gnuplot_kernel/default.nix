{ bash, bashInteractive, gnuplot, python, fetchFromGitHub, writeScriptBin }:

with python.pkgs;

let

metakernel-package = import ./metakernel-package.nix;
gnuplot-package = import ./gnuplot-package.nix { inherit fetchFromGitHub; } ;

metakernel = buildPythonPackage rec {
  inherit (metakernel-package) version pname format;
  name = "${pname}-${version}";

  propagatedBuildInputs = [ pexpect notebook ];

  src = fetchPypi {
    inherit (metakernel-package) pname version format sha256;
  };
};

gnuplot_kernel = buildPythonPackage rec {
  version = "0.2.3";
  pname = "gnuplot_kernel";
  name = "${pname}-${version}";

  doCheck = false;

  preBuild = ''
    export HOME=$(pwd)
  '';

  propagatedBuildInputs = [ metakernel ];

  src = gnuplot-package;
};

env = python.withPackages (ps: with ps; [ gnuplot_kernel notebook ]);

in

writeScriptBin "gnuplot_kernel" ''
#! ${bash}/bin/bash
PATH=${gnuplot}/bin:${env}/bin:$PATH
exec python -m gnuplot_kernel $@
''

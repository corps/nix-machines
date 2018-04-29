{ bash, bashInteractive, python, fetchFromGitHub, writeScriptBin }:

with python.pkgs;

let

package = import ./package.nix;

bash_kernel = buildPythonPackage rec {
  inherit (package) version pname format;
  name = "${pname}-${version}";
  propagatedBuildInputs = [ pexpect ];

  src = fetchPypi {
    inherit (package) pname version format sha256;
  };
};

env = python.withPackages (ps: with ps; [ bash_kernel notebook ]);

in

writeScriptBin "bash_kernel" ''
#! ${bash}/bin/bash
PATH=${bashInteractive}/bin:${env}/bin:$PATH
exec python -m bash_kernel $@
''

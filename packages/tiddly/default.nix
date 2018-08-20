{ callPackage, writeScriptBin, bash, nodeTools, nodejs }:

let
bin = ./bin;
in

writeScriptBin "tiddly" ''
#! /usr/bin/env ${bash}/bin/bash

export NODE_PATH=${nodeTools}/lib/node_modules:$NODE_PATH
export PATH=${nodeTools}/bin:$PATH
export PATH=${nodejs}/bin:$PATH

exec ${bin}/tiddly
''

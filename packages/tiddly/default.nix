{ callPackage, writeScriptBin, bash, npmPackages, nodejs }:

let
bin = ./bin;
in

writeScriptBin "tiddly" ''
#! /usr/bin/env ${bash}/bin/bash

export NODE_PATH=${npmPackages.tiddlywiki}/lib/node_modules:$NODE_PATH
export NODE_PATH=${npmPackages.http-proxy}/lib/node_modules:$NODE_PATH
export NODE_PATH=${npmPackages.wait-port}/lib/node_modules:$NODE_PATH
export PATH=${npmPackages.tiddlywiki}/bin:$PATH
export PATH=${nodejs}/bin:$PATH

exec ${bin}/tiddly
''

{ callPackage, writeScriptBin, bash }:

let
package = (callPackage ./npm-package.nix {}).package;
in

writeScriptBin "tiddly" ''
#! /usr/bin/env ${bash}/bin/bash

package=${package}/lib/node_modules/tiddly/
PATH=$package/node_modules/.bin:$PATH

exec $package/bin/tiddly
''

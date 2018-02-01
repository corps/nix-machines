{ stdenv, nodejs, lib, wget, bash, substituteAll, unzip }:

rec {
  embedInNativeApp = { name, url, version }:
    stdenv.mkDerivation {
      inherit name version;
      buildInputs = [ nodejs ];

      phases = [ "buildPhase" "installPhase" ];

      buildPhase = ''
        export NPM_CONFIG_PREFIX=$PWD
        export HOME=$PWD
        npm install nativefier
        ./node_modules/.bin/nativefier --name "${name}" "${url}"
      '';

      installPhase = ''
        mkdir -p $out/Applications
        cp -r ${name}-darwin-x64/${name}.app $out/Applications/
      '';
    };

  firstNonNull = lib.findFirst (v: !(builtins.isNull v)) null;
  getAttrOr = def: k: o: if builtins.isAttrs o
    then if builtins.hasAttr k o
      then builtins.getAttr k o
      else def
    else def;
  getAttrOrNull = getAttrOr null;
  union = l: lib.unique (lib.concatLists l);
  unionAttrNames = l: union (map builtins.attrNames l);

  listContains = l: v: lib.any (x: x == v) l;

  deepMerge = a: b:
    if !(builtins.isAttrs a && builtins.isAttrs b) then firstNonNull [b a] else
    builtins.listToAttrs (map (k: {
      name = k;
      value =
        let av = getAttrOrNull k a;
            bv = getAttrOrNull k b;
        in deepMerge av bv;
    }) (unionAttrNames [a b]));

  importWithDefault = path: default: if builtins.pathExists path then import path else default;

  jsonSafeOf = obj:
    if builtins.isAttrs obj
    then lib.filterAttrs (k: v:
      !(listContains [
        "jsonSafeOf"
        "jsonSafeSelf"
      ] k) && !(builtins.isFunction v)
      ) obj else
    if builtins.isList obj
    then builtins.filter (v: !(builtins.isFunction v)) obj else
    if builtins.isFunction obj then null else
    obj;
}

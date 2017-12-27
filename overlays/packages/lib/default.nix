{ stdenv, nodejs }:

{
  embedInNativeApp = { name, url, version }:
    stdenv.mkDerivation {
      inherit name version;
      buildInputs = [ nodejs ];

      src = ./.;
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
}

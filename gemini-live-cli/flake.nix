{
  description = "A development environment for the Gemini Live CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
          pythonEnv = pkgs.python3.withPackages (ps: [
            ps.google-genai
            ps.pyaudio
          ]);
        in
        {
          default = pkgs.stdenv.mkDerivation rec {
            pname = "gemini-live-cli";
            version = "0.1.0";

            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];
            buildInputs = [
              pkgs.portaudio
              pythonEnv
            ];

            installPhase = ''
              mkdir -p $out/bin
              makeWrapper ${pythonEnv}/bin/python $out/bin/${pname} \
                --add-flags $src/main.py
            '';
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
          pythonEnv = pkgs.python3.withPackages (ps: [
            ps.google-genai
            ps.pyaudio
          ]);
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              pythonEnv
              pkgs.portaudio
            ];
          };
        }
      );
    };
}

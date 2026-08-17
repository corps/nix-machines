{pkgs ? import <nixpkgs> {}}:
with pkgs;
  stdenv.mkDerivation {
    name = "pi-native-app";
    version = "1.0.0";

    src = ./.;

    installPhase = ''
      # Create the Applications directory
      mkdir -p $out/Applications

      # Copy the entire app bundle
      cp -r pi.app $out/Applications/

      # Make the executable script executable
      chmod +x $out/Applications/pi.app/Contents/MacOS/pi

      # Create a symlink for easier access
      mkdir -p $out/bin
      ln -s ../Applications/pi.app/Contents/MacOS/pi $out/bin/pi-native
    '';

    meta = with lib; {
      description = "Native macOS app wrapper for pi";
      homepage = "https://github.com/your-repo/pi-native";
      license = licenses.mit;
      platforms = platforms.darwin;
    };
  }

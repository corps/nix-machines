{ pkgs }: { 
  packageOverrides = super: 
    let self = super.pkgs; 
        pkg = pkgs.callPackage;
    in 
    with self; rec {

    ngrok = pkg packages/ngrok.nix {};
    xquartz-helpers = pkg packages/xquartz-helpers.nix {};
    corpscripts = pkg packages/scripts.nix {};
  };

  allowUnfree = true;
}

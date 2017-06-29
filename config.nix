{ pkgs }: { 
  packageOverrides = super: 
    let self = super.pkgs; 
        pkg = pkgs.callPackage;
    in 
  with self; rec {
    dropbox_uploader = pkg packages/dropbox_uploader.nix {};
    ngrok = pkg packages/ngrok.nix {};
    xhelpers = pkg packages/xhelpers.nix {};
    corpscripts = pkg packages/scripts.nix {};
  };

  allowUnfree = true;
}

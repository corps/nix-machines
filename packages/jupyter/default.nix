{ writeText, writeTextFile, fetchFromGitHub, python35, newScope,
  lib, symlinkJoin, writeScriptBin, bash, pkgs }:

let

python = import ./python-packages.nix python35;
jupyter = (python.withPackages (ps: [ ps.notebook ]));
scope = pkgs // {
  inherit python jupyter;
};
callPackage = newScope scope;

writeKernelFile = json@{ name, argv, ...}:
  writeTextFile {
    name = "kernel.json";
    destination = "/kernels/${name}/kernel.json";
    text = builtins.toJSON  (json // {
      argv = argv ++ ["{connection_file}"];
    });
  };

ihaskell = callPackage ./ihaskell.nix {};
bash_kernel = callPackage ./bash_kernel.nix {};
gnuplot_kernel = callPackage ./gnuplot_kernel.nix {};
nix-kernel = callPackage (fetchFromGitHub {
  owner = "corps";
  repo = "nix-kernel";
  rev = "ae99b3dacadead82efebe97d31439bd021acd980";
  sha256 = "1vc71ak2ag64ky2w6hxfxxivwvik1409iiqiihj6mdwrys9ryvdv";
}) {};

purescript-kernel = (callPackage (fetchFromGitHub {
  owner = "corps";
  repo = "purescript-webpack-kernel";
  rev = "97b78702df3565ea46554b21eebb5d4d40bad09e";
  sha256 = "006xzk8bn3p1mg3q911sy7q5pgvv0r6gacxgsmv4rmmzky90ybim";
}) {}) + "/lib/node_modules/purescript-webpack-kernel";

# nix-kernel = callPackage ../../../../nix-kernel {};

kernels = {
  python3 = null;

  purescript-webpacker = {
    language = "purescript";
    display_name = "Purescript / Webpack";
    argv = [
      "${purescript-kernel}/purescript-webpack/kernel"
    ];
  };
  nix = {
    language = "nix";
    display_name = "Nix";
    argv = [
      "${nix-kernel}/bin/nix-kernel"
      "-f"
    ];
  };
  haskell = {
    language = "haskell";
    display_name = "Haskell";
    argv = [
      "${ihaskell}/bin/ihaskell"
    ];
  };
  gnuplot = {
    language = "gnuplot";
    display_name = "gnuplot";
    argv = [
      "${gnuplot_kernel}/bin/gnuplot_kernel"
      "-f"
    ];
  };
  bash = {
    language = "bash";
    display_name = "Bash";
    env = { PS1 = "$"; };
    argv = [
      "${bash_kernel}/bin/bash_kernel"
      "-f"
    ];
  };
};

kernelFileAttrs = builtins.attrNames (lib.attrsets.filterAttrs (n: v: v != null) kernels);
kernelFiles = builtins.map
  (name: writeKernelFile (kernels.${name} // { inherit name; })) kernelFileAttrs;

whitelist = lib.strings.concatMapStringsSep ", " builtins.toJSON (builtins.attrNames kernels);

jupyterConfig = writeText "jupyter_config.py" ''
  from os.path import expanduser
  home = expanduser("~")
  c.KernelSpecManager.whitelist = { ${whitelist} }
  # c.NotebookApp.disable_check_xsrf = True
  # c.NotebookApp.token = ""
  # c.NotebookApp.allow_origin = ""
  c.NotebookApp.notebook_dir = home + "/Dropbox/Notebooks"
  c.TerminalInteractiveShell.confirm_exit = False
  c.JupyterConsoleApp.confirm_exit = False
  c.NotebookApp.open_browser = False
'';

kernelDir = symlinkJoin { name = "jupyter-kernels"; paths = kernelFiles; };

in

writeScriptBin "jupyter" ''
  #!${bash}/bin/bash -ie
  export PATH=${jupyter}/bin:$PATH
  export JUPYTER_PATH=${kernelDir}:$JUPYTER_PATH

  exec ipython notebook --config ${jupyterConfig} $@
''


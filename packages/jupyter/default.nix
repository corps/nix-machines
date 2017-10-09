{ python, python35Packages, writeText, writeTextFile, fetchFromGitHub,
  nodejs, lib, symlinkJoin, writeScriptBin, stdenv, bash, pkgs }:

let

writeKernelFile = json@{ name, argv, ...}:
  writeTextFile {
    name = "kernel.json";
    destination = "/kernels/${name}/kernel.json";
    text = builtins.toJSON  (json // {
      argv = argv ++ ["{connection_file}"];
    });
  };

jupyter = import ./python-env.nix { inherit pkgs fetchFromGitHub; };
ihaskell = import ./ihaskell.nix { inherit jupyter fetchFromGitHub; };
bash_kernel = import ./bash_kernel.nix { inherit pkgs fetchFromGitHub writeScriptBin; };
gnuplot_kernel = import ./gnuplot_kernel.nix { inherit pkgs fetchFromGitHub writeScriptBin; };
nix-kernel = import (fetchFromGitHub {
  owner = "corps";
  repo = "nix-kernel";
  rev = "aa02c68fff8052fd654b80a3a1be53891bab85f6";
  sha256 = "1bqavp678ggjqx53p5w55mbghynxn6j5n8g7pcdxpr01nc8v4wjh";
}) { inherit pkgs writeScriptBin; };

kernels = {
  python3 = null;
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
  c.NotebookApp.token = ""
  # c.NotebookApp.allow_origin = ""
  c.NotebookApp.notebook_dir = home + "/Dropbox/Notebooks"
  c.TerminalInteractiveShell.confirm_exit = False
  c.JupyterConsoleApp.confirm_exit = False
'';

kernelDir = symlinkJoin { name = "jupyter-kernels"; paths = kernelFiles; };

in

writeScriptBin "jupyter" ''
  #!${bash}/bin/bash -e
  export PATH=${jupyter}/bin:$PATH
  export JUPYTER_PATH=${kernelDir}:$JUPYTER_PATH

  exec yes | ipython notebook --config ${jupyterConfig} $@
''


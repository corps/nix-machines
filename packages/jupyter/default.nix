{ python, python35Packages, writeText, writeTextFile, fetchFromGitHub,
  nodejs, lib, symlinkJoin, writeScriptBin, stdenv, bash, pkgs }:

let

jupyter = import ./python-env.nix { inherit pkgs fetchFromGitHub; };
ihaskell = import ./ihaskell.nix { inherit jupyter fetchFromGitHub; };

writeKernelFile = { name, language, display_name, argv }:
  writeTextFile {
    name = "kernel.json";
    destination = "/kernels/${name}/kernel.json";
    text = builtins.toJSON  { 
      inherit language display_name; 
      argv = argv ++ ["{connection_file}"]; 
    };
  };

kernels = {
  python3 = null;
  haskell = {
    language = "haskell";
    display_name = "Haskell";
    argv = [
      "${ihaskell}/bin/ihaskell"
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


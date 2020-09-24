{ writeText, writeTextFile, fetchFromGitHub, python37, newScope,
  lib, symlinkJoin, writeScriptBin, bash, pkgs }:

let

python = import ./python-packages.nix python37;
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

ihaskell = callPackage ../ihaskell {};
bash_kernel = callPackage ../bash_kernel {};
gnuplot_kernel = callPackage ../gnuplot_kernel {};

purescript-kernel = callPackage ../purescript-kernel {
  npmPackages = [
    "moment"
    "bignumber.js"
  ];
  bowerPackages = [
    "purescript-lens"
    "purescript-profunctor-lenses"
    "purescript-foreign-generic"
  ];
};

kernels = {
  python3 = null;

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


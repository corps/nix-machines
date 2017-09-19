{ python35Packages, python, writeText, writeTextFile, 
  nodejs, lib, symlinkJoin, writeScriptBin, stdenv, bash }:

let
pynb = python.buildEnv.override {
  extraLibs = with python35Packages; [ jupyter notebook ];
  ignoreCollisions = true;
};

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
  purescript = {
    language = "purescript";
    display_name = "Purescript in NodeJs";
    argv = [ 
      "${nodejs}/bin/node" 
      "/Users/dame/Development/ipurescript/bin/run.js" 
      "/Users/dame/Development/ipurescript" 
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
'';

kernelDir = symlinkJoin { name = "jupyter-kernels"; paths = kernelFiles; };

in

writeScriptBin "jupyter" ''
  #!${bash}/bin/bash -e
  export PATH=${pynb}/bin:$PATH
  export JUPYTER_PATH=${kernelDir}:$JUPYTER_PATH

  exec ipython notebook --config ${jupyterConfig} $@
''


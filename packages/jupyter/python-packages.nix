python:

let
  packageOverrides = self: super: rec {
    nbconvert = super.nbconvert.overridePythonAttrs (old: {
      doCheck = false;
    });

    notebook = super.notebook.overridePythonAttrs (old: {
      doCheck = false;
    });

    send2trash = super.send2trash.overridePythonAttrs (old: {
      doCheck = false;
    });

    terminado = super.terminado.overridePythonAttrs (old: {
      doCheck = false;
    });
  };
in python.override { inherit packageOverrides; }

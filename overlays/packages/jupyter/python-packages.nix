python:

let
  packageOverrides = self: super: rec {
    nbconvert = super.nbconvert.overridePythonAttrs (old: {
      doCheck = false;
    });

    notebook = super.notebook.overridePythonAttrs (old: {
      doCheck = false;
    });
  };
in python.override { inherit packageOverrides; }
    

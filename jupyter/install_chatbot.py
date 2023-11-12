import json
import os
import sys
import argparse
import pathlib
import shutil

from jupyter_client.kernelspec import KernelSpecManager
from IPython.utils.tempdir import TemporaryDirectory

kernel_json = {"argv":[sys.executable,"-m","work.chat_kernel", "-f", "{connection_file}"],
 "display_name":"Chat",
 "language":"markdown",
 "codemirror_mode":"markdown",
 "env": dict(PYTHONPATH="/home/jovyan"),
}

def install(user=True, prefix=None):
    with TemporaryDirectory() as td:
        os.chmod(td, 0o755) # Starts off as 700, not user readable
        with open(os.path.join(td, 'kernel.json'), 'w') as f:
            json.dump(kernel_json, f, sort_keys=True)
        print('Installing Chat kernel spec')
        KernelSpecManager().install_kernel_spec(td, 'chat', user=user, prefix=prefix)
        print("Done")

install(user=True)

import json
import os

from setuptools import find_packages, setup

kernel_json = {
    "argv": ["ivine", "-f", "{connection_file}"],
    "display_name": "Vine",
    "language": "vine",
}

kernel_spec_dir = os.path.join(
    os.path.expanduser("~"), ".local/share/jupyter/kernels/vine"
)
os.makedirs(kernel_spec_dir, exist_ok=True)
with open(os.path.join(kernel_spec_dir, "kernel.json"), "w") as f:
    json.dump(kernel_json, f)

setup(
    name="ivine",
    version="0.1",
    packages=find_packages(),
    install_requires=[
        "jupyter_client",
        "ipykernel",
    ],
    data_files=[
        (kernel_spec_dir, ["kernel.json"]),
    ],
    entry_points={
        "console_scripts": [
            "ivine = ivine.kernel:main",
        ],
    },
)

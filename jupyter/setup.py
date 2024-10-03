from setuptools import find_packages, setup


def get_requirements():
    with open("requirements.frozen.txt") as fp:
        return [x.strip() for x in fp.read().split("\n") if not x.startswith("#")]


setup(
    name="kaihatsuio",
    version="0.1.0",
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    install_requires=get_requirements(),
)

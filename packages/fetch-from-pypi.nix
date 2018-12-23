{ pkgs ? import <nixpkgs> {}
, writeScriptBin ? pkgs.writeScriptBin
}:
writeScriptBin "fetch-from-pypi" ''
#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p "python3.withPackages (ps: with ps; [ requests toolz ])"

INDEX = "https://pypi.io/pypi"
import requests
import toolz
import json

format_extension = {
  "wheel": "whl",
  "setuptools": "tar.gz",
}

def _fetch_page(url):
  r = requests.get(url)
  if r.status_code == requests.codes.ok:
    return r.json()
  else:
    raise ValueError("request for {} failed".format(url))

def get_latest_version_pypi(package, extension):
  url = "{}/{}/json".format(INDEX, package)
  json = _fetch_page(url)
  version = json['info']['version']
  for release in json['releases'][version]:
    if release['filename'].endswith(extension):
      sha256 = release['digests']['sha256']

  return version, sha256

if __name__ == "__main__":
  import sys
  package = sys.argv[1]
  format = sys.argv[2]
  version, sha256 = get_latest_version_pypi(package, format_extension[format])

  if sha256 is None:
    raise Exception("Could not determine sha256")

  print("fetchPypi {")
  print("  pname = {};".format(json.dumps(package)))
  print("  version = {};".format(json.dumps(version)))
  print("  format = {};".format(json.dumps(format)))
  print("  sha256 = {};".format(json.dumps(sha256)))
  print("};")
''


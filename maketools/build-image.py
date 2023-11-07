#!/usr/bin/env python3
import os.path
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(SCRIPT_DIR))

from maketools.utils import run, root_dir, fail

docker_start = run.subcommand("docker", "start")
docker_create = run.subcommand("docker", "create")
docker_inspect = run.subcommand("docker", "inspect")
docker_exec = run.subcommand("docker", "exec")
nix_build = docker_exec.subcommand("nix-builder", "nix-build")
docker_build = run.subcommand("docker", "build")

def determine_tag(fullpath: str):
    file = os.path.basename(fullpath)
    if not fullpath.startswith(root_dir):
        fail(f"Could not determine image tag name for path {file}")
    parts = os.path.split(fullpath[len(root_dir) + 1:])
    if parts[-1] == 'Dockerfile':
        parts = parts[:-1]
    if len(parts) > 2:
        fail(f"Could not determine image tag name for path {file}")
    return ":".join(parts)

def build_nix(nixfile):
    tagname = determine_tag(nixfile)
    rel_nixfile = nixfile[len(root_dir) + 1:]

    nix_builder_exec = docker_exec.subcommand("nix-builder-cache")

    build_image(os.path.join(root_dir, 'nix-builder', 'Dockerfile'))
    if not docker_inspect("nix-builder-cache", required=False, silent=True):
        try:
            docker_create("nix-builder", name="nix-builder-cache", privileged=True,
                          i=True, t=True, w="/work", v=f"{root_dir}:/work", mount="type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly")
            docker_start("nix-builder-cache")
        except:
            run("docker", "stop", "nix-builder-cache", required=False)
            run("docker", "rm", "nix-builder-cache", required=False)
            raise

    nix_builder_exec.subcommand("nix-build")(rel_nixfile, o="/result")
    nix_builder_exec.subcommand("docker", "load")("--input", "/result")


def build_image(dockerfile, parents=None, seen=None):
    tagname = determine_tag(dockerfile)

    if parents is None:
        parents = []

    if dockerfile in parents:
        fail("Circular dependency: " + " -> ".join([*parents, dockerfile]))

    parents = [*parents, dockerfile]
    seen = seen or set()

    with open(dockerfile, 'r') as file:
        build_dockerfile_references(dockerfile, file, parents, seen)

    docker_build(os.path.dirname(dockerfile), f=dockerfile, tag=tagname)

def build_dockerfile_references(dockerfile, file, parents, seen):
    for i, line in enumerate(file.readlines()):
        if not line.startswith('FROM'):
            continue
        parts = line.split()
        if len(parts) < 2:
            fail(f"Found incomplete dependency line in {dockerfile}: {i}: {line}")
        source = parts[1]
        if "/" in source:
            print('skipped source')
            continue

        path = source.split(':')
        if len(path) == 1 and path[0].endswith('.nix'):
            path.insert(0, os.path.dirname(dockerfile))

        project_name = path[0]
        if not os.path.exists(os.path.join(root_dir, project_name)):
            continue

        if not path[-1].endswith('.nix'):
            path.append('Dockerfile')

        fullpath = os.path.join(root_dir, *path)

        if fullpath in seen:
            continue
        seen.add(fullpath)

        build(fullpath, parents, seen)


def build(fullpath, parents=None, seen=None):
    file = os.path.basename(fullpath)
    if file.endswith('.nix'):
        build_nix(fullpath)
    elif file == 'Dockerfile':
        build_image(fullpath, parents, seen)
    else:
        fail("Could not build " + fullpath)

if __name__ == "__main__":
    file = os.path.abspath(sys.argv[1])
    build(file)

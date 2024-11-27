#!/usr/bin/env python3
import os.path
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(SCRIPT_DIR))

from maketools.utils import edited_config_file, fail, parse_yaml_keys, run

docker_stack_deploy = run.subcommand("docker", "stack", "deploy")
docker_service_update = run.subcommand("docker", "service", "update")
docker_config_create = run.subcommand("docker", "config", "create")
docker_secret_create = run.subcommand("docker", "secret", "create")


def deploy(stack_yaml):
    project_name = os.path.basename(os.path.dirname(stack_yaml))
    with open(stack_yaml, "r") as yf:
        stack_keys, _ = parse_yaml_keys(list(yf.readlines()))

    for network_name, network_keys in stack_keys.get("networks", {}).items():
        if "external" in network_keys:
            if run(
                "docker",
                "network",
                "inspect",
                network_name,
                required=False,
                silent=True,
            ):
                continue
            run.subcommand("docker", "network", "create")(
                network_name, attachable=True, d="overlay", scope="swarm"
            )

    for config_name, config_keys in stack_keys.get("configs", {}).items():
        if "external" in config_keys:
            if run(
                "docker", "config", "inspect", config_name, required=False, silent=True
            ):
                continue

            with edited_config_file(
                f"<data for {config_name}>".encode("utf8")
            ) as cf_path:
                docker_config_create(config_name, cf_path)

    for secret_name, secret_keys in stack_keys.get("secrets", {}).items():
        if "external" in secret_keys:
            if run(
                "docker", "secret", "inspect", secret_name, required=False, silent=True
            ):
                continue

            docker_secret_create(secret_name, "-")

    docker_stack_deploy(project_name, compose_file=stack_yaml)
    for service_name in stack_keys.get("services", {}).keys():
        docker_service_update(f"{project_name}_{service_name}", force=True)


if __name__ == "__main__":
    stack_yml = os.path.abspath(sys.argv[1])
    deploy(stack_yml)

#!/usr/bin/env python3
import base64
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(SCRIPT_DIR))

from maketools.utils import run, parse_yaml_keys, edited_config_file

docker_config_inspect = run.subcommand("docker", "config", "inspect")
docker_config_create = run.subcommand("docker", "config", "create")
docker_config_rm = run.subcommand("docker", "config", "rm")
docker_service_update = run.subcommand("docker", "service", "update")

def count_leading_spaces(string):
    count = 0
    for char in string:
        if char.isspace():
            count += 1
        else:
            break
    return count

def configure(stack_yaml):
    # project_name = os.path.basename(os.path.dirname(stack_yaml))
    with open(stack_yaml, 'r') as yf:
        stack_keys, _ = parse_yaml_keys(list(yf.readlines()))

    for config_file in stack_keys.get('configs', {}).keys():
        config_json = json.loads(docker_config_inspect(config_file, capture_output=True, required=False))
        if not config_json:
            data = b''
        else:
            data = base64.b64decode(config_json[0]['Data'])

        with edited_config_file(data) as cf_path:
            sub_config_file = f"{config_file}.new"
            docker_config_create(sub_config_file, cf_path)
            run("make", "deploy", env={config_file.replace('.', ''): sub_config_file})
            docker_config_rm(config_file)
            docker_config_create(config_file, cf_path)
            run("make", "deploy")
            docker_config_rm(sub_config_file)

if __name__ == "__main__":
    stack_yml = os.path.abspath(sys.argv[1])
    configure(stack_yml)

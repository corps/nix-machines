#!/bin/env bash
set -e
set -x

cd src
exec python -m sheets.server

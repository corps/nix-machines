#!/bin/env bash
set -e
set -x

cd src
alembic upgrade heads
exec python -m wakimae.server

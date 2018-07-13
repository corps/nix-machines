#! @shell@
set -e
set -o pipefail

nc -kl 127.0.0.1 15150 | sh

# shellcheck shell=sh
PATH="$(git rev-parse --show-toplevel)/bin:${PATH}"
. bats.sh


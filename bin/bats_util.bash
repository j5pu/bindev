#!/bin/bash

#
# bats utils

load /usr/local/bin/bats-libs.bash

# <html><h2>Bats Test Description Array</h2>
# <p><strong><code>$BATS_TEST_DESCRIPTION_ARRAY</code></strong> test description to array.</p>
# </html>
declare -a BATS_TEST_DESCRIPTION_ARRAY

#######################################
# assert version
# Globals:
#   BATS_TEST_DESCRIPTION
# Arguments:
#   1:   image name (default: macOS).
#   2:   command executed.
#######################################
assert_version() {
  description_color "${1:-macOS}" "${2:-}"
  description_array
  run "${BATS_TEST_DESCRIPTION_ARRAY[@]}"
  assert_output "$(semver next)"
}

export -f assert_version

#######################################
# colorized test description with image name and command
# Globals:
#   BATS_TEST_DESCRIPTION
#   BATS_TEST_DESCRIPTION_ARRAY
#######################################
description_array() {
  read -r -a BATS_TEST_DESCRIPTION_ARRAY <<< "${BATS_TEST_DESCRIPTION}"
}

export -f description_array

#######################################
# colorized test description with image name and command
# Globals:
#   BATS_TEST_DESCRIPTION
# Arguments:
#   1:   image name (default: macOS).
#   2:   command executed.
#######################################
description_color() {
  echo "   [$(tput bold)$(tput magenta)$(echo "${BATS_TEST_DESCRIPTION}" | awk '{ $1=$1 };1')$(tput sgr0)] \
[$(tput bold)$(tput green)${1:-macOS}$(tput sgr0)] \
${2:+[$(tput bold)$(tput blue)${2}$(tput sgr0)]}" >&3
}

export -f description_color

####################################### Executed
#
if [ "$(basename "$0")" = 'bats_helper.sh' ]; then
  fromman "$0" "$@" || exit 0
fi

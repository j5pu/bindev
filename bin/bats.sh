#!/bin/bash

# add & updates bats libraries, sources libraries, set helper variables and run bats tests.
#

# <html><h2>Installation Directory for Bats and Bats Libraries</h2>
# <p><strong><code>$BATS_SHARE</code></strong> contains the installation directory.</p>
# </html>
BATS_SHARE="/usr/local/share/${BASH_SOURCE[0]##*/}"; export BATS_SHARE

# <html><h2>Bats Core Executable PATH</h2>
# <p><strong><code>$BATS_SHARE_EXE</code></strong> contains the bats core executable path.</p>
# </html>
BATS_EXE_PATH="${BATS_SHARE}/bats-core/bin"; export BATS_EXE_PATH

# <html><h2>Bats Test Filename Prefix</h2>
# <p><strong><code>$BATS_TEST_PREFIX</code></strong> prefix of BATS_TEST_DIRNAME basename.</p>
# </html>
# <html><h2>Bats Test Filename Prefix (when sourcing: bats.lib)</h2>
# <p><strong><code>$BATS_TEST_FILENAME_PREFIX</code></strong> prefix of BATS_TEST_FILENAME basename.</p>
# </html>
BATS_TEST_FILENAME_PREFIX="$(basename "${BATS_TEST_FILENAME:-}" .bats)"; export BATS_TEST_FILENAME_PREFIX

# <html><h2>Git Top Path</h2>
# <p><strong><code>$BATS_TOP</code></strong> contains the git top directory when sourced from a git dir.</p>
# </html>
BATS_TOP="$(git top)"; export BATS_TOP

# <html><h2>Git Top Basename</h2>
# <p><strong><code>$BATS_TOP_NAME</code></strong> basename of git top directory when sourced from a git dir.</p>
# </html>
BATS_TOP_BASENAME="${BATS_TOP##*/}"; export BATS_TOP_BASENAME

# <html><h2>Git Top Tests Path</h2>
# <p><strong><code>$BATS_TOP_TESTS</code></strong> contains the git top directory with 'tests' basename added.</p>
# </html>
BATS_TOP_TESTS="${BATS_TOP}/tests"; export BATS_TOP_TESTS

# <html><h2>Tests Jobs</h2>
# <p><strong><code>$TESTS_JOBS</code></strong> contains number of parallel test jobs.</p>
# <p>Global or sourced from '.envrc'.</p>
# </html>
export TESTS_JOBS

# <html><h2>Run Only Local Tests (not Docker)</h2>
# <p><strong><code>$TESTS_LOCAL</code></strong> if set to 0 will run container tests (default: 1).</p>
# <p>Global or sourced from '.envrc'.</p>
# </html>
TESTS_LOCAL="${TESTS_LOCAL:-1}"; export TESTS_LOCAL

# <html><h2>Run Only Local Tests Boolean (not Docker)</h2>
# <p><strong><code>$BATS_LOCAL</code></strong> will be true if $TESTS_LOCAL is set to 1 (not run container tests).</p>
# </html>
BATS_LOCAL=false; [ "${TESTS_LOCAL}" -eq 0 ] || BATS_LOCAL=true; export BATS_LOCAL


#######################################
# Colorized test description with image and command
# Globals:
#   BATS_TEST_DESCRIPTION
# Arguments:
#   1:   image name (default: macOS).
#   2:   command executed.
#######################################
bats::description() {
  . color.sh
  echo "   [$(magenta "$(echo "${BATS_TEST_DESCRIPTION}" | awk '{ $1=$1 };1')")] [$(green "${1:-macOS}")] \
${2:+[$(blue "${2}")]}" >&3
}

#######################################
# Source bats libraries; clone/pull bats core and libraries
# Globals:
#   BATS_SHARE
# Arguments:
#   0
#######################################
# shellcheck disable=SC1090
bats::libs() {
  local d i
  for i in bats-assert bats-core bats-file bats-support; do
    d="${BATS_SHARE}/${i}"
    if [ ! -d "${d}" ]; then
      git clone --quiet https://github.com/bats-core/"${i}".git "${d}"
    elif [ "${1}" = '--force' ]; then
     git -C "${d}" pull --quiet --force
   fi
    [ "${i}" = 'bats-core' ] || . "${d}"/load.bash
  done
  command -v assert_success >/dev/null || echo "${0##*/}": assert_success: command not found
}

#######################################
# Run bats tests and sets cwd to git top
# Globals:
#   BATS_SHARE_EXE
#   BATS_TOP
#   TESTS_JOBS
#   clean
#   verbose
# Arguments:
#   0
#   1:  tests root path
#######################################
# shellcheck disable=SC1090
bats::tests() {
  local args old_pwd="${PWD}" output tests_root="${1#--tests=}" tmp

  if [ -d "${tests_root-}" ]; then
    cd "${tests_root}"
    BATS_TOP="$(git top)"
  else
    tests_root="${BATS_TOP}/tests"
  fi

  [ -d "${tests_root}" ] || { echo "${0##*/}: ${tests_root}: No such directory"; exit 1; }
  [ "${BATS_TOP-}" ] || { echo "$0: ${BATS_TOP}: No git top directory"; exit 1; }
  tmp='/tmp/bats'
  output="${tests_root}/output"; [ ! -d "${output}" ] || { mkdir -p "${tmp}"; rm -rf "${tmp}";mv "${output}" "${tmp}"; }
  if ! $clean; then
    args=("${tests_root}" --print-output-on-failure --recursive )

    [ ! -f "${BATS_TOP}/.envrc" ] || . "${BATS_TOP}/.envrc"
    [ ! "${TESTS_JOBS-}" ] || args+=(--jobs "${TESTS_JOBS}")

    ! $verbose || args+=(--gather-test-outputs-in "${output}" --no-tempdir-cleanup --output "${output}" \
      --print-output-on-failure --recursive --show-output-of-passing-tests --timing --trace --verbose-run)

    cd "${old_pwd}"
    bats "${args[@]}"
  fi
}

#######################################
# Add & updates bats libraries, sources libraries, set helper variables and run bats tests
# Globals:
#   arg
#   clean
#   verbose
# Arguments:
#  1: [--clean[=<tests root path>]|--parsed|--tests[=<tests root path>]|--verbose[=<tests root path>]|
# Common Arguments:
#  1: [--desc|--help|-version]
#######################################
bats::main() {
  [ "${BATS_TOP-}" ] || { echo "${0##*/}: ${BATS_TOP}: No git top directory"; exit 1; }
  PATH="${BATS_TOP}/bin:${BATS_TOP}/sbin:${BATS_EXE_PATH}:${PATH}"
  if [ -d "${BATS_TOP_TESTS}/bin" ]; then
    PATH="${BATS_TOP_TESTS}/bin:${BATS_TOP}/bin:${BATS_TOP}/sbin:${BATS_EXE_PATH}:${PATH}"
  fi
  if [ "${0##*/}" = 'bats.sh' ]; then
    set -eu
    clean=false; verbose=false
    for arg do
      case "${arg}" in
        --clean*) clean=true; bats::tests "${arg}" ;;
        --force) bats::libs "${arg}" ;;
        --tests*) bats::tests "${arg}" ;;
        --verbose*) verbose=true; bats::tests "${arg}" ;;
        --desc|--help|--manrepo|--version) COMMAND="${0##*/}" parse-man "${arg}";;
      esac
      exit
    done
  else
    bats::libs
  fi
}

bats::main "$@"

#!/usr/bin/env bats

setup() { load helpers/test_helper; }

repo() {
  load helpers/test_helper
  test_repo_name=repo
  cp -r "${BATS_TOP_TESTS}/${test_repo_name}" "${BATS_TEST_TMPDIR}"
  export REPO_TEST_TMPDIR="${BATS_TEST_TMPDIR}/${test_repo_name}"
  git -C "${REPO_TEST_TMPDIR}" init --quiet
}

@test "genman: bindev " {
  assert genman
}

@test "genman: repo " {
  repo
  assert genman "${REPO_TEST_TMPDIR}/bin"
}

@test "genman: repo fail " {
  repo
  cp "${REPO_TEST_TMPDIR}/src/man/repo_test_main.adoc" "${REPO_TEST_TMPDIR}/src/man/repo_test_fail.adoc"
  run genman "${REPO_TEST_TMPDIR}/bin"
  assert_failure
  assert_output - <<STDIN
Invalid Function Comment Block for file: bin/repo_test_fail and function: main

@ BLOCK START @
#!/bin/sh

#
# repo test fail because no function comment in main

main() {
@ BLOCK END @
STDIN
}

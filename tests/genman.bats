#!/usr/bin/env bats

setup() { load helpers/test_helper; }

setup_file() {
  load helpers/test_helper
  test_repo_name=repo
  cp -r "${BATS_TOP_TESTS}/${test_repo_name}" "${BATS_FILE_TMPDIR}"
  export REPO_TEST_TMPDIR="${BATS_FILE_TMPDIR}/${test_repo_name}"
  git -C "${REPO_TEST_TMPDIR}" init --quiet
}

@test "genman: bindev " {
  assert genman
}

@test "genman: repo " {
  assert genman "${REPO_TEST_TMPDIR}/bin"
}

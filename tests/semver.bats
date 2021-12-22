#!/usr/bin/env bats

setup() { load helpers/test_helper; }

repo() {
  path="${BATS_FILE_TMPDIR}/${1:-${FUNCNAME[0]}}"
  if [ ! -d  "${path}" ]; then
    mkdir "${path}"
    cd "${path}" || exit 1
    git init --quiet >/dev/null
  else
    cd "${path}" || exit 1
  fi
  echo "${path}"
}

tag() {
  cd "$(repo '')" || return 1
  if ! git tag | grep -q '0.1.0'; then
    touch a
    git add a
    git commit --quiet -m "a"
    git tag '0.1.0'
  fi
  svu --strip-prefix next
}

commit() {
  cd "$(repo '')" || return 1
  touch "${1}"
  git add "${1}"
  git commit --quiet -a -m "${3}"
  run semver next
  assert_success
  assert_output "${2}"
}

@test "new: current " {
  cd "$(repo '')"
  run semver
  assert_success
  assert_output ''
}

@test "new: next " {
  cd "$(repo '')"
  run semver next
  assert_success
  assert_output '0.1.0'
}

@test "new: patch " {
  cd "$(repo '')"
  run semver patch
  assert_success
  assert_output '0.0.1'
}

@test "new: minor " {
  cd "$(repo '')"
  run semver minor
  assert_success
  assert_output '0.1.0'
}

@test "new: major " {
  cd "$(repo '')"
  run semver major
  assert_success
  assert_output '1.0.0'
}

@test "next " {
  cd "$(repo '')"
  run tag
  run svu --strip-prefix next
  assert_success
  assert_output '0.1.0'

  cd "$(repo '')"
  run semver next
  assert_success
  assert_output '0.1.1'

  cd "$(repo '')"
  path="$(pwd)"
  cd /tmp
  run semver next
  assert_failure

  cd "$(repo '')"
  path="$(pwd)"
  cd /tmp

  run semver next "${path}"
  assert_success
  assert_output '0.1.1'

  commit b '0.1.1' "fix: fix patch"
  commit c '0.2.0' "feat: feat minor"
  commit d '1.0.0' "fix!: fix major"
  commit e '1.0.0' "feat: feat minor (previous commit had fix! so takes the highest)"

  cd "$(repo '')"
  git tag '1.0.0'
  commit f '2.0.0' "fix: fix minor\nBREAKING CHANGE: "
}

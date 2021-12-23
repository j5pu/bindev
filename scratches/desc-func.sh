#!/bin/bash

a="
#######################################
# raises version to patch if svu next is not raising it and shows version if not git tags
# Arguments:
#  [current|major|minor|next|patch|--desc|--help|--version] [directory]
#######################################
otra() {
  local arg cmd='current' current path='.' next top
}

#######################################
# raises version to patch if svu next is not raising it and shows version if not git tags
# Arguments:
#  [current|major|minor|next|patch|--desc|--help|--version] [directory]
#######################################
main() {
  local arg cmd='current' current path='.' next top
}
"
line_comment="#######################################"
func=main
echo "${a}" | tail -r | awk "/^${func}\() {/{f=1; c=0} f; /${line_comment}/ && ++c==2{f=0}" | grep -v "${line_comment}" | sed 's/^# //'| tail -1

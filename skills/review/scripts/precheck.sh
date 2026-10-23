#!/bin/sh
# vue-power-up review precondition (SPEC D13).
# Takes no arguments and reads no user input. Always exits 0 and prints exactly one line:
#   PRECHECK=OK             git is installed and the working directory is inside a git work tree
#   PRECHECK=NO_GIT_BINARY  git is not on PATH
#   PRECHECK=NOT_A_REPO     the working directory is not inside a git work tree
if ! command -v git >/dev/null 2>&1; then
  echo "PRECHECK=NO_GIT_BINARY"
  exit 0
fi
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo "PRECHECK=NOT_A_REPO"
  exit 0
fi
echo "PRECHECK=OK"
exit 0

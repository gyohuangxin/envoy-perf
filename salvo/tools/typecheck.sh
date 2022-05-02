#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# pipefail indicates that the return value of a pipeline is the status
# of the last command to exit with a non-zero status.
set -exo pipefail

function die()
{
  MESSAGE="$1"

  echo ${MESSAGE}
  exit 1
}

PYTYPE=$(which pytype)
if [ -z "${PYTYPE}"  -a -f ${HOME}/.local/bin/pytype ]
then
  PYTYPE=${HOME}/.local/bin/pytype
fi

if [ -z "${PYTYPE}" ]
then
  die "Unable to find pytype in path"
fi

echo $PWD

${PYTYPE} src -P bazel-bin:.

#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_NAME="BlindMap"

USAGE="Usage: ./deploy.sh --host HOST --dir DIR\n\
\n\
Required arguments:\n\
  --host HOST              Remote server to deploy to.\n\
  --dir DIR                Remote directory.\n\
Optional arguments:\n\
  -h, --help               Print usage and exit.\n\
"

# Print given message and exit with code 1.
function fail() {
  echo -e "Error: $1" 1>&2
  exit 1
}

# Print given message and the usage and exit with code 1.
function fail_with_usage() {
  echo -e "Error: $1" >&2
  echo
  echo -e "${USAGE}" >&2
  exit 1
}

function print_usage() {
  echo -e "${USAGE}"
}

function parse_args() {
  # Set default values.
  export REMOTE_DIR=""
  export HOST=""

  # Parse arguments.
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      --dir)
        REMOTE_DIR="$2"
        shift
        ;;
      --host)
        HOST="$2"
        shift
        ;;
      -h|--help)
        echo
        print_usage
        exit 0;
        ;;
      -*)
        fail_with_usage "Unknown argument: '$1'"
        ;;
      *)
        fail_with_usage "Unexpected argument: '$1'"
        ;;
    esac
    shift # past argument key
  done

  # Check arguments.
  test -n "${HOST}" || fail_with_usage "Missing HOST argument."
  test -n "${REMOTE_DIR}" || fail_with_usage "Missing DIR argument."
}

parse_args "$@"

ssh "${HOST}" rm "${REMOTE_DIR}" -rf
scp -r "${SCRIPT_DIR}/../Export/Web/" "${HOST}":"${REMOTE_DIR}"
ssh "${HOST}" chmod -R +r "${REMOTE_DIR}" 

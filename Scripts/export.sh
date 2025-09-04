#!/bin/bash

set -euo pipefail

# Script for exporting Godot project.

GODOT="godot4.4"
PROJECT_NAME="Blind Map"
ITCH_IO_PROJECT_NAME="blind-map"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR="../BlindMap"

# paths relative to PROJECT_DIR
WEB_EXPORT_DIR="../Export/web" 
LINUX_EXPORT_DIR="../Export/linux"
WINDOWS_EXPORT_DIR="../Export/windows"
WEB_BUILD_DIR="${WEB_EXPORT_DIR}/build"
LINUX_BUILD_DIR="${LINUX_EXPORT_DIR}/build"
WINDOWS_BUILD_DIR="${WINDOWS_EXPORT_DIR}/build"


cd "${SCRIPT_DIR}"
GAME_VERSION="$(git describe --tags --abbrev=0 || echo "v0.0.0")"
GIT_HASH="$(git rev-parse --short HEAD)"


print_help() {
  echo "Usage: export.sh -v VERSION [-bhftu] [--web|--linux|--windows] [--ignore-uncommitted]"
  echo "  -h,--help: Print help message and exit."
  echo "  -v,--version VERSION: Version of the project."
  echo "  -f,--force: Overwrite existing tags and export files."
  echo "  -b,-build: Build export zip files."
  echo "  -t,--tag: Tag current commit with version specified in --version"
  echo "    Tag must not exist unless --force is specified."
  echo "  -u,-upload: Upload export zip files to itch.io."
  echo "  --linux: Export linux version."
  echo "  --windows: Export windows version."
  echo "  --web: Export html5 version."
  echo "  --ignore-uncommitted: Ignore uncommited changes."
}


fail_with_error() {
  echo "${1}" >&2
  exit 1
}


parse_args() {
  GIT_TAG=""
  FORCE="false"
  IGNORE_UNCOMMITTED="false"
  BUILD="false"
  UPLOAD="false"
  TAG="false"
  EXPORT_WEB="false"
  EXPORT_LINUX="false"
  EXPORT_WINDOWS="false"

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        print_help
        exit 0
        ;;
      -v|--version)
        GIT_TAG="$2"
        shift
        shift
        ;;
      -t|--tag)
        TAG="true"
        shift
        ;;
      -f|--force)
        FORCE="true"
        shift
        ;;
      --ignore-uncommitted)
        IGNORE_UNCOMMITTED="true"
        shift
        ;;
      --web)
        EXPORT_WEB="true"
        shift
        ;;
      --linux)
        EXPORT_LINUX="true"
        shift
        ;;
      --windows)
        EXPORT_WINDOWS="true"
        shift
        ;;
      -b|--build)
        BUILD="true"
        shift
        ;;
      -u|--upload)
        UPLOAD="true"
        shift
        ;;
      -*)
        fail_with_error "Unknown option: '$1'"
        ;;
      *)
        fail_with_error "Unexpected positional argument: '$1'"
        ;;
    esac
  done
}


check_no_uncommitted_changes() {
  test -z "$(git status -s)" || fail_with_error "There are uncommitted changes."
}


check_linux_export_does_not_exists() {
  test ! -f "${PROJECT_DIR}/${LINUX_EXPORT_DIR}/linux_${GAME_VERSION}.zip" || fail_with_error "Linux build for version ${GAME_VERSION} already exists."
}


check_windows_export_does_not_exists() {
  test ! -f "${PROJECT_DIR}/${WINDOWS_EXPORT_DIR}/windows_${GAME_VERSION}.zip" || fail_with_error "Windows build for version ${GAME_VERSION} already exists."
}


check_web_export_does_not_exists() {
  test ! -f "${PROJECT_DIR}/${WEB_EXPORT_DIR}/web_${GAME_VERSION}.zip" || fail_with_error "Web build for version ${GAME_VERSION} already exists."
}


save_git_hash() {
  echo -n "${GIT_HASH}" > "${PROJECT_DIR}/git_hash.txt"
}


apply_git_tag() {
  if test -z "${GIT_TAG}"; then
    return
  fi
  
  echo "Applying git tag: ${GIT_TAG}"
  if "${FORCE}" = "true"; then
    git tag --force "${GIT_TAG}" || fail_with_error "Failed to apply git tag."
  else
    git tag "${GIT_TAG}" || fail_with_error "Failed to apply git tag."
  fi
  GAME_VERSION="$GIT_TAG"
}


cleanup() {
  cd "${SCRIPT_DIR}"
  if test "${EXPORT_WEB}" == "true"; then
    rm -rf "${WEB_BUILD_DIR}"
    rm -f "${PROJECT_DIR}/${WEB_EXPORT_DIR}/web_${GAME_VERSION}.zip"
    rm -f "${PROJECT_DIR}/${WEB_EXPORT_DIR}/web_${GAME_VERSION}.log"
  fi
  if test "${EXPORT_LINUX}" == "true"; then
    rm -rf "${LINUX_BUILD_DIR}"
    rm -f "${PROJECT_DIR}/${LINUX_EXPORT_DIR}/linux_${GAME_VERSION}.zip"
    rm -f "${PROJECT_DIR}/${LINUX_EXPORT_DIR}/linux_${GAME_VERSION}.log"
  fi
  if test "${EXPORT_WINDOWS}" == "true"; then
    rm -rf "${WINDOWS_BUILD_DIR}"
    rm -f "${PROJECT_DIR}/${WINDOWS_EXPORT_DIR}/windows_${GAME_VERSION}.zip"
    rm -f "${PROJECT_DIR}/${WINDOWS_EXPORT_DIR}/windows_${GAME_VERSION}.log"
  fi
}


collect_license_files() {
  mkdir -p "${1}"
  find "${PROJECT_DIR}" -name "*_license.txt" -exec cp {} "${1}" \;
}


export_web() {
  echo "Exporting Web build to ${WEB_EXPORT_DIR}/web_${GAME_VERSION}.zip"
  cd "${SCRIPT_DIR}"
  mkdir -p "${WEB_BUILD_DIR}"
  WEB_BUILD_FILE="${WEB_BUILD_DIR}/index.html"
  WEB_LOG_FILE="$(realpath "${PROJECT_DIR}/${WEB_EXPORT_DIR}")""/web_${GAME_VERSION}.log"
  collect_license_files "${WEB_BUILD_DIR}/licenses"
  ${GODOT} --headless --path "${PROJECT_DIR}" --export-release "Web" "${WEB_BUILD_FILE}" &> "${WEB_LOG_FILE}" || fail_with_error "Failed to export Web build."
  cd "${PROJECT_DIR}/${WEB_BUILD_DIR}"
  zip "../web_${GAME_VERSION}.zip" * licenses/*  &>> "${WEB_LOG_FILE}"
}


export_linux() {
  echo "Exporting Linux build to ${LINUX_EXPORT_DIR}/linux_${GAME_VERSION}.zip"
  cd "${SCRIPT_DIR}"
  mkdir -p "${LINUX_BUILD_DIR}"
  LINUX_BUILD_FILE="${LINUX_BUILD_DIR}/${PROJECT_NAME}.x86_64"
  LINUX_LOG_FILE="$(realpath "${PROJECT_DIR}/${LINUX_EXPORT_DIR}/linux_${GAME_VERSION}.log")"
  collect_license_files "${LINUX_BUILD_DIR}/licenses"
  ${GODOT} --headless --path "${PROJECT_DIR}" --export-release "Linux" "${LINUX_BUILD_FILE}" &> "${LINUX_LOG_FILE}" || fail_with_error "Failed to export Linux build."
  cd "${PROJECT_DIR}/${LINUX_BUILD_DIR}"
  zip "../linux_${GAME_VERSION}.zip" "${PROJECT_NAME}.x86_64" "${PROJECT_NAME}.pck" licenses/*  &>> "${LINUX_LOG_FILE}"
}


export_windows() {
  echo "Exporting Windows build to ${WINDOWS_EXPORT_DIR}/windows_${GAME_VERSION}.zip"
  cd "${SCRIPT_DIR}"
  mkdir -p "${WINDOWS_BUILD_DIR}"
  WINDOWS_BUILD_FILE="${WINDOWS_BUILD_DIR}/${PROJECT_NAME}.exe"
  WINDOWS_LOG_FILE="$(realpath "${PROJECT_DIR}/${WINDOWS_EXPORT_DIR}/windows_${GAME_VERSION}.log")"
  collect_license_files "${WINDOWS_BUILD_DIR}/licenses"
  ${GODOT} --headless --path "${PROJECT_DIR}" --export-release "Windows" "${WINDOWS_BUILD_FILE}" &> "${WINDOWS_LOG_FILE}" || fail_with_error "Failed to export Windows build."
  cd "${PROJECT_DIR}/${WINDOWS_BUILD_DIR}/"
  zip "../windows_${GAME_VERSION}.zip" "${PROJECT_NAME}.exe" "${PROJECT_NAME}.pck" licenses/* &>> "${WINDOWS_LOG_FILE}"
}


upload_web_to_itch_io() {
  cd "${SCRIPT_DIR}"
  butler push "${PROJECT_DIR}/${WEB_EXPORT_DIR}/web_${GAME_VERSION}.zip" \
    "prvak/${ITCH_IO_PROJECT_NAME}:web" \
    --userversion "${GAME_VERSION}"
}


upload_linux_to_itch_io() {
  cd "${SCRIPT_DIR}"
  butler push "${PROJECT_DIR}/${LINUX_EXPORT_DIR}/linux_${GAME_VERSION}.zip" \
    "prvak/${ITCH_IO_PROJECT_NAME}:linux" \
    --userversion "${GAME_VERSION}"
}


upload_windows_to_itch_io() {
  cd "${SCRIPT_DIR}"
  butler push "${PROJECT_DIR}/${WINDOWS_EXPORT_DIR}/windows_${GAME_VERSION}.zip" \
    "prvak/${ITCH_IO_PROJECT_NAME}:windows" \
    --userversion "${GAME_VERSION}"
}


run() {
  parse_args "$@"

  if test "${IGNORE_UNCOMMITTED}" != "true"; then
    check_no_uncommitted_changes
  fi

  if test "${FORCE}" != "true"; then
    test "${EXPORT_WEB}" == "true" && check_web_export_does_not_exists
    test "${EXPORT_LINUX}" == "true" && check_linux_export_does_not_exists
    test "${EXPORT_WINDOWS}" == "true" && check_windows_export_does_not_exists
  fi

  cleanup

  if test "${TAG}" == "true"; then
    apply_git_tag
  fi

  save_git_hash

  if test "${BUILD}" == "true"; then
    test "${EXPORT_WEB}" == "true" && export_web
    test "${EXPORT_LINUX}" == "true" && export_linux
    test "${EXPORT_WINDOWS}" == "true" && export_windows
  fi

  if test "${UPLOAD}" == "true"; then
    test "${EXPORT_WEB}" == "true" && upload_web_to_itch_io
    test "${EXPORT_LINUX}" == "true" && upload_linux_to_itch_io
    test "${EXPORT_WINDOWS}" == "true" && upload_windows_to_itch_io
  fi
  echo "Export successful."
}

run "$@"


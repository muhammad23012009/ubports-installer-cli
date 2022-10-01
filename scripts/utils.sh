#!/usr/bin/env sh

[ -n "${UTILS_SH}" ] && return; UTILS_SH=0; # like #ifndef guard in C

URL="https://system-image.ubports.com"

cache_home="${XDG_CACHE_HOME}"
data_home="${XDG_DATA_HOME}"
if [ -z "${cache_home}" ]; then
  cache_home="${HOME}/.cache"
fi
if [ -z "${data_home}" ]; then
  data_home="${HOME}/.local"
fi
cache_dir="${cache_home}/ubports-installer-cli"
data_dir="${data_home}/ubports-installer-cli"

fetch() {
  url=${1}
  cached="${cache_dir}/$(basename "${url}")"

  if [ -z "${NO_CACHE}" ]; then
    if [ -e "${cached}" ]; then
      cat "${cached}"
      return 0
    fi
  fi

  if command -v wget > /dev/null 2>&1; then
    result=$(wget -qO- "${url}")
  elif command -v curl > /dev/null 2>&1; then
    result=$(curl -so- "${url}")
  else
    return 1
  fi

  # cache the result first
  if [ -z "${NO_CACHE}" ]; then
    mkdir -p "$(dirname "${cached}")"
    echo "${result}" > "${cached}"
  fi

  echo "${result}"
}

fetch_persistent_files() {
  url=${1}
  if [ -z ${2} ]; then
    cached="${data_dir}/${url}"
  else
    cached=${2}
  fi

  if command -v wget > /dev/null 2>&1; then
    output=$(wget "${url}" -O "${cached}")
  elif command -v curl > /dev/null 2>&1; then
    output=$(curl "${url}" -o "${cached}")
  fi

}

# https://stackoverflow.com/a/8811800
contains() {
  string="${1}"
  substring="${2}"

  if ! test "${string#*"${substring}"}" != "${string}"; then
    return 1 # $substring is not in $string
  fi
}

ct() {
  case "${1}" in
    red)
      color='\033[31m';;
    green)
      color='\033[32m';;
    orange)
      color='\033[33m';;
    blue)
      color='\033[34m';;
    magenta)
      color='\033[35m';;
    cyan)
      color='\033[36m';;
    white)
      color='\033[37m';;
    black)
      color='\033[30m';;
    *)
      color='\033[0m';;
  esac

  if [ "${2}" = true ]; then
    color="${color}\033[1m"
  fi

  # shellcheck disable=SC2059 # won't work with an escaped string
  printf "\033[0m${color}"
}

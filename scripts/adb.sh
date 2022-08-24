#!/usr/bin/env sh

. ./scripts/utils.sh

msg_unauthorized='Unauthorized - accept the prompt on device!'
msg_offline='Device offline'
msg_no_device='Device disconnected!'
msg_no_fstab='Unable to read recovery.fstab!'
msg_umount_failed='Unmounting /%s failed!'
msg_make_ext4fs_failed='make_ext4fs %s failed'
msg_mount_failed='Mounting /%s failed!'

_adb_handle_error() {
  output="${1}"

  if contains "${output}" 'error: device unauthorized' \
  || contains "${output}" 'error: device still authorizing' \
  ; then
    echo "${msg_unauthorized}" 1>&2
    return 0
  elif contains "${output}" 'error: device offline' \
    || contains "${output}" 'error: protocol fault' \
    || contains "${output}" 'connection reset' \
  ; then
    echo "${msg_offline}" 1>&2
    return 0
  elif contains "${output}" 'no devices/emulators found' \
    || contains "${output}" 'no device' \
    || contains "${output}" 'adb: error: failed to read copy response' \
    || contains "${output}" "couldn't read from device" \
    || contains "${output}" 'remote Bad file number' \
    || contains "${output}" 'remote Broken pipe' \
    || contains "${output}" 'adb: sideload connection failed: closed' \
    || contains "${output}" 'adb: pre-KitKat sideload connection failed: closed' \
  ; then
    echo "${msg_no_device}" 1>&2
    return 0
  fi

  return 1
}

_wrap_simple_adb() {
  cmd="${1}"
  result="$(adb "${cmd}" 2>&1)"
  exit_code=${?}

  if _adb_handle_error "${result}"; then
    return 1
  fi

  echo "${result}"
  return ${exit_code}
}

adb_shell() {
  _wrap_simple_adb "shell ${1}"
}

adb_has_access() {
  result="$(adb_shell 'echo .')"

  [ ${?} -eq 0 ] \
  && [ "${result}" = '.' ] \
  || return 1
}

adb_wait() {
  state="${1:-any}"
  transport="${2:-any}"

  _wrap_simple_adb "wait-for-${transport}-${state}" > /dev/null
}

adb_get_state() {
  _wrap_simple_adb "get-state"
}

_find_partition_in_fstab() {
  fstab="${1}"
  partition="${2}"

  while IFS= read -r line; do
    mnt_point="$(echo "${line}" | xargs | cut -d ' ' -f 2)"
    if [ "${mnt_point}" = "/${partition}" ]; then
      echo "${line}" | xargs | cut -d ' ' -f 1
      return 0
    fi
  done << EOI
${fstab}
EOI

  return 1
}

adb_format() {
  partition="${1}"
  fstab="$(adb_shell 'cat /etc/recovery.fstab')"
  block="$(_find_partition_in_fstab "${fstab}" "${partition}")"

  if [ -z "${block}" ]; then
    echo "${msg_no_fstab}" 1>&2
    return 1
  fi

  if ! adb_shell "umount '/${partition}'" > /dev/null 2>&1; then
    printf "${msg_umount_failed}" "${partition}" 1>&2
    return 2
  fi
  if ! adb_shell "make_ext4fs '${block}'" > /dev/null 2>&1; then
    printf "${msg_make_ext4fs_failed}" "${block}" 1>&2
    return 3
  fi
  if ! adb_shell "mount '/${partition}'" > /dev/null 2>&1; then
    printf "${msg_mount_failed}" "${partition}" 1>&2
    return 4
  fi
}

adb_sideload() {
  file="${1}"

  
}

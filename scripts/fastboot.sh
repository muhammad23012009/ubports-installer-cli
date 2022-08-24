#!/usr/bin/env sh

. ./scripts/utils.sh

msg_low_power='Low battery, charge the device first!'
msg_locked_bootloader='The bootloader is locked!'
msg_enable_unlocking='Enable OEM unlocking in Developer Options!'
msg_boot_failed='Boot failed!'
msg_no_device='Device disconnected!'

fastboot_has_access() {
  contains "$(fastboot devices)" 'fastboot'
}

fastboot_wait() {
  while ! fastboot_has_access; do
    sleep 2
  done
}

_fastboot_handle_error() {
  output=${1}

  if contains "${output}" 'FAILED (remote: low power, need battery charging.)'; then
    echo "${msg_low_power}" 1>&2
    return 0
  elif contains "${output}" 'not supported in locked device' \
    || contains "${output}" 'Bootloader is locked' \
    || contains "${output}" 'not allowed in locked state' \
    || contains "${output}" 'not allowed in Lock State' \
    || contains "${output}" 'Device not unlocked cannot flash or erase' \
    || contains "${output}" 'Partition flashing is not allowed' \
    || contains "${output}" 'Command not allowed' \
    || contains "${output}" 'not allowed when locked' \
    || contains "${output}" 'device is locked. Cannot flash images' \
    || (contains "${output}" 'for partition' \
     && contains "${output}" 'is not allowed') \
  ; then
    echo "${msg_locked_bootloader}" 1>&2
    return 0
  elif contains "${output}" "Check 'Allow OEM Unlock' in Developer Options" \
    || contains "${output}" 'Unlock operation is not allowed' \
    || contains "${output}" 'oem unlock is not allowed' \
  ; then
    echo "${msg_enable_unlocking}" 1>&2
    return 0
  elif contains "${output}" 'FAILED (remote failure)'; then
    echo "${msg_boot_failed}" 1>&2
    return 0
  elif contains "${output}" 'I/O error' \
    || contains "${output}" 'FAILED (command write failed (No such device))' \
    || contains "${output}" 'FAILED (command write failed (Success))' \
    || contains "${output}" 'FAILED (status read failed (No such device))' \
    || contains "${output}" 'FAILED (data transfer failure (Broken pipe))' \
    || contains "${output}" 'FAILED (data transfer failure (Protocol error))' \
  ; then
    echo "${msg_no_device}" 1>&2
    return 0
  fi

  return 1
}

_wrap_simple_fastboot() {
  cmd=${1}
  result="$(fastboot "${cmd}" 2>&1)"
  exit_code=${?}

  if _fastboot_handle_error "${result}"; then
    return 1
  fi

  echo "${result}"
  return "${exit_code}"
}

fastboot_oem_unlock() {
  code=${1}
  result="$(fastboot oem unlock "${code}" 2>&1)"
  exit_code=${?}

  if _fastboot_handle_error "${result}"; then
    return 1
  fi

  [ "${exit_code}" -eq 0 ] \
  || contains "${result}" 'Already Unlocked' \
  || contains "${result}" 'Not necessary' \
  || return 1
}

fastboot_flashing_unlock() {
  _wrap_simple_fastboot 'flashing unlock' > /dev/null
}

fastboot_reboot_bootloader() {
  _wrap_simple_fastboot 'reboot-bootloader' > /dev/null
}

fastboot_reboot_fastboot() {
  _wrap_simple_fastboot 'reboot-fastboot' > /dev/null
}

fastboot_reboot_recovery() {
  _wrap_simple_fastboot 'reboot-recovery' > /dev/null
}

fastboot_reboot() {
  _wrap_simple_fastboot 'reboot' > /dev/null
}

fastboot_continue() {
  _wrap_simple_fastboot 'continue' > /dev/null
}

fastboot_set_active() {
  slot=${1}
  result="$(fastboot --set-active="${slot}")"
  exit_code="${?}"

  if contains "${result}" 'error'; then
    echo "${result}"
    return 2
  fi

  [ ${exit_code} -eq 0 ] || return 1
}

fastboot_flash() {
  echo "${@}" | while IFS=';' read -r partition file raw; do
    flash_arg=$([ "${raw}" -eq 1 ] && echo 'flash:raw' || echo 'flash')
    result="$(fastboot ${flash_arg} ${partition} ${file} 2>&1)"
    
    if [ "${?}" -ne 0 ]; then
      if _fastboot_handle_error "${result}"; then
        return 1
      fi

      echo "${result}" 1>&2
      return 1
    fi
  done && fastboot_wait
}

fastboot_create_logical_partition() {
  partition=${1}
  size=${2}

  _wrap_simple_fastboot "create-logical-partition ${partition} ${size}" > /dev/null
}

fastboot_delete_logical_partition() {
  partition=${1}

  _wrap_simple_fastboot "delete-logical-partition ${partition}" > /dev/null
}

fastboot_resize_logical_partition() {
  partition=${1}
  size=${2}

  _wrap_simple_fastboot "resize-logical-partition ${partition} ${size}" > /dev/null
}

fastboot_wipe_super() {
  device=${1}
  group=${2}
  file=${3}

  _wrap_simple_fastboot "wipe-super \"${cache_dir}/${device}/${group}/${file}\"" > /dev/null
}

fastboot_erase() {
  partition="${1}"

  _wrap_simple_fastboot "erase ${partition}" > /dev/null
}

fastboot_format() {
  partition="${1}"
  type="${2}"
  size="${3}"

  type_arg="$([ -n "${type}" ] && echo ":${type}")"
  size_arg="$([ -n "${size}" -a -n "${type}" ] && echo ":${size}")"

  _wrap_simple_fastboot "format${type_arg}${size_arg} ${partition}" > /dev/null
}

fastboot_boot() {
  device=${1}
  group=${2}
  file=${3}

  _wrap_simple_fastboot "boot \"${cache_dir}/${device}/${group}/${file}\"" > /dev/null
}

fastboot_update() {
  device=${1}
  group=${2}
  file=${3}
  wipe=${4}

  wipe_arg="$([ "${wipe}" = true ] && echo "-w ")"

  _wrap_simple_fastboot "${wipe_arg}update \"${cache_dir}/${device}/${group}/${file}\"" > /dev/null
}

# TODO: no regexes
fastboot_assert_var() {
  var="${1}"
  value="${2}"

  if ! fastboot_has_access; then
    echo "${msg_no_device}" 1>&2
    return 1
  fi

  name=
  val=

  IFS=': ' read -r name val << EOI
$(fastboot getvar "${var}")
EOI

  if [ "${name}" != "${var}" ]; then
    # TODO: debug log?
    return 1
  fi

  [ "${val}" = "${value}" ] \
  || (echo "expected ${name} to equal '${value}' but got '${val}'" 1>&2; return 1)
}


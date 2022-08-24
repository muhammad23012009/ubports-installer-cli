#!/usr/bin/env sh

. ./scripts/utils.sh

fetch_channels() {
  channels_url="${UT_CHANNELS_URL}"
  if [ -z "${channels_url}" ]; then
    channels_url="https://system-image.ubports.com/channels.json"
  fi

  fetch "${channels_url}"
}

get_device_channels() {
  device="${1}"
  os="${2}"

  channel_config=$(fetch_channels)
  channels="$(echo "${channel_config}" | jq -r 'keys[]')"

  echo "${channels}" | while read -r channels_item; do
    if [ -n "${os}" ]; then
      if ! contains "${channels_item}" "${os}"; then
        continue
      fi
    fi

    ret=$(echo "${channel_config}" | jq -r ".[\"${channels_item}\"].devices.${device}.index")

    if [ "${ret}" != 'null' ]; then
      echo "- ${channels_item}"
    fi
  done
}

select_device() {
  device="${1}"
  channel="${2}"
  os="${3}"

  channel_config=$(fetch_channels)

  # no os specified - assume full channel
  if [ -z "$os" ]; then
    echo "${channel_config}" | jq -r ".[\"${channel}\"].devices.${device}.index"
  fi

  channels="$(echo "${channel_config}" | jq -r 'keys[]')"

  echo "${channels}" | while read -r channels_item; do
    if ! contains "${channels_item}" "${channel}"; then
      continue
    fi

    if ! contains "${channels_item}" "${os}"; then
      continue
    fi

    ret=$(echo "${channel_config}" | jq -r ".[\"${channels_item}\"].devices.${device}.index")

    if [ "${ret}" != 'null' ]; then
      echo "${ret}"
    fi
  done
}

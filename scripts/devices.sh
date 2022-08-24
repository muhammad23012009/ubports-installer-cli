#!/usr/bin/env sh

. ./scripts/utils.sh

fetch_devices_index() {
  fetch "https://ubports.github.io/installer-configs/v2/index.json"
}

fetch_device_aliases() {
  fetch "https://ubports.github.io/installer-configs/v2/aliases.json"
}

fetch_device_config() {
  device="${1}"
  fetch "https://ubports.github.io/installer-configs/v2/devices/${device}.json"
}
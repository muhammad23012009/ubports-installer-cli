#!/usr/bin/env sh

. ./scripts/utils.sh
. ./scripts/setup.sh
. ./scripts/bootstrap.sh
. ./scripts/channels.sh

helpp() {
  # display help
  echo "The UBCLI script allows for flashing devices from the terminal."
  echo
  echo "Syntax: ubcli.sh [-c|-h|-d|-w|-b]"
  echo "options:"
  echo "   --version <version>    Used to select the operating system version (eg. 16.04 for UT)"
  echo "   -c | --channel         Used to select a channel to install to the device."
  echo "   -d | --device          Used to specify a device. If no device is specificed the tool will try to automatically detect a device."
  echo "   -w | --wipe            Used to wipe the data partition of the device. Used when installing UT for the first time or wiping your user data"
  echo "   -s | --setup           Used to install the dependencies for the script."
  echo "   -b | --bootstrap       Used to install UT to a device for the first time. If you've installed UT already then don't enable this option"
  echo "   -lc | --list-channels  List available channels for device."
  echo "   -h | --help            Display this message."
}

parser_definition() {
  setup   REST plus:true help:usage abbr:true error alt:true -- \
		"Usage: ${prog##*/} [options...] [arguments...]" ''
  msg -- 'The UBCLI script allows for flashing devices from the terminal.' ''
  msg -- 'Options:'
  param os_version -ov --os-version     -- 'the operating system version (eg. 16.04 for UT) to install'
  param channel    -c --channel         -- 'channel to install'
  param device     -d --device          -- 'device name, if no device is specificed it will try to automatically detect it using adb'
  flag  wipe       -w --wipe            -- 'wipe userdata, usually required on first install from another OS'
  flag  bootstrap  -b --bootstrap       -- 'flash images using fastboot, required on first install from another OS'
  
}

printf "$(ct 'green')Welcome to UBCLI! A tool to install Ubuntu Touch on your device from the command-line!$(ct)\n"

while [ "${1}" != "" ]; do
  case "${1}" in
    -d | --device)
      shift
      device=$1
      shift
      ;;
    -c | --channel)
      shift
      channel=$1
      shift
      ;;
    -h | --help)
      help
      exit 0
      ;;
    -w | --wipe)
      shift
      wipe=true
      ;;
    -s | --setup)
      setup
      exit
      ;;
    -b | --bootstrap)
      shift
      bootstrap=true
      ;;
    --version)
      shift
      version=${1}
      shift
      ;;
    -lc | --list-channels)
      shift
      get_channels=true
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

if [ -z "${device}" ]; then
  device=$(adb shell getprop ro.product.vendor.name 2> /dev/null | tr -d '\r')
fi

# exit if no device found
if [ "${device}" = "" ]; then
  printf "$(ct 'red' true)ERROR:$(ct 'red') No device specified and no device connected!$(ct)"
  exit 1
fi

if [ -z "${version}" ]; then
  version="16.04" # default to xenial
fi

if [ "${get_channels}" = true ]; then
  channels=$(get_device_channels "${device}" "${version}")

  if [ -z "${channels}" ]; then
    printf "$(ct 'red' true)ERROR:$(ct 'red') no channels for"
    printf "$(ct 'orange') ${device}$(ct 'red') on"
    printf "$(ct 'orange') ${version}$(ct 'red')!\n"
    exit 1
  fi

  printf "$(ct 'green')Available channels for"
  printf "$(ct 'orange') ${device}$(ct 'green') on"
  printf "$(ct 'orange') ${version}$(ct 'green'):\n"
  
  printf "$(ct)${channels}\n"
  exit 0
fi

# exit if channel not specified
if [ "${channel}" = "" ]; then
  printf "$(ct 'red' true)ERROR:$(ct 'red') No channel specified!$(ct)"
  exit 2
fi

# clear version if full channel name specified
if contains "${channel}" "/"; then
  unset version
fi

image_index_url=$(select_device "${device}" "${channel}" "${version}")

if [ "${image_index_url}" = "null" ]; then
  unset image_index_url
fi

if [ -z "${image_index_url}" ]; then
  printf "$(ct 'red' true)ERROR:$(ct 'red') channel"
  printf "$(ct 'orange') ${channel}$(ct 'red') for"
  printf "$(ct 'orange') ${device}$(ct 'red')"
  if [ -n "${version}" ]; then
    printf "$(ct 'red') on$(ct 'orange') ${version}"
  fi
  printf "$(ct 'red') does not exist!$(ct)\n"
  
  echo 'Run with --list-channels to list available channels'
  exit 3
fi
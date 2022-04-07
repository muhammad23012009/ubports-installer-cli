#!/bin/bash
export TOPDIR=$(pwd)

. $TOPDIR/scripts/setup.sh
. $TOPDIR/scripts/bootstrap.sh
. $TOPDIR/scripts/channels.sh
#####################################
help()
{
   # Display help
   echo "The UBCLI script allows for flashing devices from the terminal."
   echo
   echo "Syntax: ubcli.sh [-c|-h|-d|-w|-b]"
   echo "options:"
   echo "   -c | --channel         Used to select a channel to install to the device."
   echo "   -d | --device          Used to specify a device. If no device is specificed the tool will try to automatically detect a device."
   echo "   -w | --wipe            Used to wipe the data partition of the device. Used when installing UT for the first time or wiping your user data"
   echo "   -s | --setup           Used to install the dependencies for the script."
   echo "   -b | --bootstrap       Used to install UT to a device for the first time. If you've installed UT already then don't enable this option"
   echo "   -h | --help            Display this message."
}
########################################################
# Colors
reset_color() {
        printf '\033[37m'
}
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')" ENDCOLOR="\e[0m" ENDBOLDCOLOR="$(printf '\033[1m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')" NC='\033[0m' # No Color
########################################################

# Welcome message
echo -e ${GREEN}${ENDBOLDCOLOR}"Welcome to UBCLI! A tool to install Ubuntu Touch on your device from the command-line!"${NC}

while [ "$1" != "" ]; do
    case $1 in
    -d | --device)
	shift
        DEVICE=$1
        ;;
    -c | --channel)
	shift
        CHANNEL_NAME=$1
        ;;
    -h | --help)
        help
        exit 0
        ;;
    -w | --wipe)
        WIPE=true
	shift
        ;;
    -s | --setup)
        setup
        exit
        ;;
    -b | --bootstrap)
        BOOTSTRAP=true
	shift
        ;;
    *)
        help
        exit 1
        ;;
    esac
    shift # remove the current value for `$1` and use the next
done

check_tools

# Device selector
if [ -z $DEVICE ]; then
    DEVICE=$(adb shell getprop ro.product.vendor.name | tr -d '\r')
fi
#########################
# Exit if no device found
if [ "$DEVICE" == "" ]; then
echo -e ${RED}${ENDBOLDCOLOR}"ERROR: No device found or defined!"${NC}
exit 1
fi

# Exit in case of no channel defined.
if [ ! $CHANNEL_NAME ]; then
echo -e ${RED}${ENDBOLDCOLOR}"ERROR: No channel defined!"${NC}
exit 1
fi

select_device

ADB_CHECK="$(adb get-state 1>/dev/null 2>&1)"
CONFIG="$(pwd)/installer-configs/v2/devices/${DEVICE}.yml"
CFG=$(yq eval -o json $CONFIG 2>/dev/null)
if [ $? -ne 0 ]; then
    CFG=$(yq . $CONFIG 2>/dev/null)
fi
DEVICEINFO=$(echo $CFG | jq -r .name)

echo Installing on $DEVICEINFO

for name in $(echo $CFG | jq .unlock[]); do
    ACTION=$(echo $CFG | jq -r .user_actions[$name])
    DESCRIPTION=$(echo $ACTION | jq -r .description)
    LINK=$(echo $ACTION | jq -r '.link // ""')
    echo ${BLUE}***********************************************
    echo ${RED}${ENDBOLDCOLOR}${DESCRIPTION}
    [ ! -z $LINK ] && echo $LINK
done
echo -e ${BLUE}***********************************************${NC}

reset_color

:

read -p "Do you wish to continue? [Y/n] " response
case $response in
	y | Y | yes | Yes) :;;
	n | N | no | No) echo "Exiting"; exit;;
	*) echo "Invalid option, please choose a correct option."; exit 1;;
esac

if [ "$BOOTSTRAP" == "true" ]; then
bootstrap
clean
fi

URL='https://system-image.ubports.com'

OUTPUT="${TOPDIR}/output"

mkdir -p "$OUTPUT" || true

download_file_and_asc() {
    wget "$1" -P "$2"
    wget "$1.asc" -P "$2"
}

# Gets the latest image from the system-image server
latest_image=$(wget -qO- "${URL}/${CHANNEL}/${DEVICE}/index.json" | jq '.images |  map(select(.type == "full")) | sort_by(.version) | .[-1]')

# Gets a list of files to download
files=$(echo "${latest_image}" | jq -r '.files[].path')

# Downloads master and signing keyrings
download_file_and_asc "${URL}/gpg/image-signing.tar.xz" "$OUTPUT"
download_file_and_asc "${URL}/gpg/image-master.tar.xz" "$OUTPUT"

# Start to generate ubuntu_command file
echo '# Generated by ubports rootfs-builder-debos' > "$OUTPUT/ubuntu_command"

if [ "$WIPE" == "true" ]; then
cat << EOF >> "$OUTPUT/ubuntu_command"
format system
format data
load_keyring image-master.tar.xz image-master.tar.xz.asc
load_keyring image-signing.tar.xz image-signing.tar.xz.asc
mount system
EOF
else
cat << EOF >> "$OUTPUT/ubuntu_command"
format system
load_keyring image-master.tar.xz image-master.tar.xz.asc
load_keyring image-signing.tar.xz image-signing.tar.xz.asc
mount system
EOF
fi

# Download and fill ubuntu_command
for file_path in ${files}; do
    file=$(basename ${file_path})
    download_file_and_asc "${URL}/${file_path}" "$OUTPUT"
    echo "update $file $file.asc" >> "$OUTPUT/ubuntu_command"
done

# End ubuntu_command
echo 'unmount system' >> "$OUTPUT/ubuntu_command"

# Check if device is connected.
if [ $ADB_CHECK ]; then
# Clean recovery-cache for installation.
adb shell rm -rf /cache/recovery
adb shell mkdir /cache/recovery

# Start installation on device end
adb push $OUTPUT/* /cache/recovery/*
adb reboot recovery

else

echo "Device not connected, please connect your device and try again!"
exit 1
fi

echo ${GREEN}"Installation complete! You can safely unplug your device now."

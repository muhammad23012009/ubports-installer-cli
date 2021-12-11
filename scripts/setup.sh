#!/bin/bash

# Architecture detection for YQ
if [ "$(uname -m)" == "x86_64" ]; then
export ARCH=amd64
elif [ "$(uname -m)" == "amd64" ]; then
export ARCH=amd64
elif [ "$(uname -m)" == "i686" ]; then
export ARCH=386
elif [ "$(uname -m)" == "aarch64" ]; then
export ARCH=arm64
fi
#########################################

# Check for available package managers
if [ -x /usr/bin/apt ]; then
export PMAN=apt && export INSTALL=install
elif [ -x /usr/bin/apk ]; then
export PMAN=apk && export INSTALL=add
elif [ -x /usr/bin/pacman ]; then
export PMAN=pacman && export INSTALL=-s
elif [ -x /usr/bin/dnf ]; then
export PMAN=dnf && export INSTALL=install
fi
#########################################

echo "The tool will now ask for your sudo password to install necessary dependencies."
echo
echo "Do you wish to continue?"
select yn in "Yes" "No"; do
     case $yn in
     Yes ) :; break;;
     No ) echo "Exiting!"; exit 1;;
     esac
done

if [ ! -x /usr/bin/yq ]; then
sudo wget https://github.com/mikefarah/yq/releases/download/v4.16.1/yq_linux_$ARCH -O /usr/bin/yq
else
echo "Dependency already satisfied, yq."
fi

if [ ! -x /usr/bin/jq ]; then
sudo $PMAN $INSTALL jq
else
echo "Dependency already satisfied, jq."
fi

if [ ! -x /usr/bin/fastboot ]; then
sudo $PMAN $INSTALL fastboot
else
echo "Dependency already satisfied, fastboot."
fi

if [ ! -x /usr/bin/adb ]; then
sudo $PMAN $INSTALL adb
else
echo "Dependency already satisfied, adb."
fi

echo "Setup complete! Run the script without the setup argument now."

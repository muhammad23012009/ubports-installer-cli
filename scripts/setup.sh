setup()
{
# Check if tools were already installed
if [ -e $TOPDIR/.tools_setup ]; then
echo "Tools already setup, re-run the script without the setup argument!"
exit 0
fi

# Architecture detection
if [ "$(uname -m)" == "x86_64" ]; then
export ARCH="amd64"
elif [ "$(uname -m)" == "amd64" ]; then
export ARCH="amd64"
elif [ "$(uname -m)" == "i686" ]; then
export ARCH="i386"
elif [ "$(uname -m)" == "aarch64" ]; then
export ARCH="arm64"
elif [ "$(uname -m)" == "armv7l" ]; then
export ARCH="armhf"
fi

# Check for an available package manager.
if [ -x /usr/bin/apt ]; then
export PMAN=apt && export INSTALL=install
elif [ -x /usr/bin/pacman ]; then
export PMAN=pacman && export INSTALL="-S"
elif [ -x /usr/bin/dnf ]; then
export PMAN=dnf && export INSTALL=install
elif [ -x /usr/bin/yum ]; then
export PMAN=yum && export INSTALl=install
fi

# Check what utilities we have on device.
if [ ! -x /usr/bin/adb ]; then
sudo $PMAN $INSTALL adb || exit 1
fi

if [ ! -x /usr/bin/fastboot ]; then
sudo $PMAN $INSTALL fastboot || exit 1
fi

# Check for a tool to download setup zip.
if [ -x /usr/bin/wget ]; then
export DL_TOOL=wget
elif [ -x /usr/bin/curl ]; then
export DL_TOOL=curl
fi

if [ "$DL_TOOL" == "wget" ]; then
wget https://github.com/muhammad23012009/ubports-installer-cli/releases/download/v1.0.0/ubcli_tools-$ARCH.tar.xz -O $TOPDIR/tools.tar.xz || exit 1
elif [ "$DL_TOOL" == "curl" ]; then
curl https://github.com/muhammad23012009/ubports-installer-cli/releases/download/v1.0.0/ubcli_tools-$ARCH.tar.xz >> $TOPDIR/tools.tar.xz || exit 1
fi

mkdir $TOPDIR/tools
tar -xvf $TOPDIR/tools.tar.xz -C $TOPDIR/tools || exit 1
touch $TOPDIR/.tools_setup

echo PATH=$TOPDIR/tools:$PATH >> ~/.bashrc

echo "Setup complete! Run the script without the setup argument now."

exit 0
}

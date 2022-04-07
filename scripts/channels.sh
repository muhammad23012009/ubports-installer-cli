select_device()
{
# Check for the available channels for the device.

URL='https://system-image.ubports.com/channels.json'

if [ -x /usr/bin/wget ]; then
export DL_TOOL=wget
elif [ -x /usr/bin/curl ]; then
export DL_TOOL=curl
fi

[ -e $TOPDIR/channels.json ] && :|| $DL_TOOL $URL -O $TOPDIR/channels.json
CHANNEL_CONFIG=$(cat $TOPDIR/channels.json)

android9_devices_stable_arm64="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/arm64/android9/stable"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
android9_devices_devel_arm64="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/arm64/android9/devel"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
android9_devices_rc_arm64="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/arm64/android9/rc"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"

hybris_devices_devel_arm64="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/arm64/hybris/devel"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
hybris_devices_rc_arm64="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/arm64/hybris/rc"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
hybris_devices_stable_arm64="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/arm64/hybris/stable"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"

hybris_devices_devel_armhf="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/armhf/hybris/devel"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
hybris_devices_rc_armhf="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/armhf/hybris/rc"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
hybris_devices_stable_armhf="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/armhf/hybris/stable"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"

hybris_devices_hal_devel="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/armhf/hybris/halium-devel"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
legacy_devices_devel="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/devel"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"
legacy_devices_rc="$(echo $CHANNEL_CONFIG | jq -r '.["16.04/rc"] | .devices' | cut -d ':' -f1 | cut -d '{' -f1 | cut -d '}' -f1 | awk -F 'index' '{print $1}' | tr -d '"')"

if [ "$CHANNEL_NAME" == "stable" ]; then
    for devices in $android9_devices_stable_arm64; do
        if [ "$DEVICE" == "$devices" ]; then
            export CHANNEL=16.04/arm64/android9/$CHANNEL_NAME
        fi
    done

    for devices in $hybris_devices_stable_arm64; do
        if [ "$DEVICE" == "$devices" ]; then
            export CHANNEL=16.04/arm64/hybris/$CHANNEL_NAME
        fi
    done

    for devices in $hybris_devices_stable_armhf; do
        if [ "$DEVICE" == "$devices" ]; then
            export CHANNEL=16.04/armhf/hybris/$CHANNEL_NAME
        fi
    done
fi

if [ "$CHANNEL_NAME" == "devel" ]; then
	for devices in $android9_devices_devel_arm64; do
        	if [ "$DEVICE" == "$devices" ]; then
            		export CHANNEL=16.04/arm64/android9/$CHANNEL_NAME
        	fi
    	done

    	for devices in $hybris_devices_devel_arm64; do
        	if [ "$DEVICE" == "$devices" ]; then
            		export CHANNEL=16.04/arm64/hybris/$CHANNEL_NAME
        	fi
    	done

     	for devices in $hybris_devices_devel_armhf; do
        	if [ "$DEVICE" == "$devices" ]; then
            		export CHANNEL=16.04/armhf/hybris/$CHANNEL_NAME
        	fi
    	done

	for devices in $legacy_devices_devel; do
		if [ "$DEVICE" == "$devices" ]; then
			export CHANNEL=16.04/devel
		fi
	done
fi

if [ "$CHANNEL_NAME" == "rc" ]; then
	for devices in $android9_devices_rc_arm64; do
		if [ "$DEVICE" == "$devices" ]; then
			export CHANNEL=16.04/arm64/android9/$CHANNEL_NAME
		fi
	done

     	for devices in $hybris_devices_rc_arm64; do
        	if [ "$DEVICE" == "$devices" ]; then
            		export CHANNEL=16.04/arm64/hybris/$CHANNEL_NAME
        	fi
    	done

    	for devices in $hybris_devices_rc_armhf; do
        	if [ "$DEVICE" == "$devices" ]; then
            		export CHANNEL=16.04/armhf/hybris/$CHANNEL_NAME
        	fi
    	done

    	for devices in $legacy_devices_rc; do
		if [ "$DEVICE" == "$devices" ]; then
	    		export CHANNEL=16.04/rc
    		fi
    	done
fi

if [ "$CHANNEL_NAME" == "halium-devel" ]; then
	for devices in $hybris_devices_hal_devel; do
		if [ "$DEVICE" == "$devices" ]; then
			export CHANNEL=16.04/armhf/hybris/halium-devel
		fi
	done
fi
}

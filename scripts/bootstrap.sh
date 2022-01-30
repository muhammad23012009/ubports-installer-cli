# Extension for ubcli.sh.
# Provides the bootstrap function.
PARTITIONS=$(echo $CFG | jq -r '.operating_systems[] | select(.name == "Ubuntu Touch") | .steps[].actions[]["fastboot:flash"].partitions')

bootstrap() {
    rm -rf $TOPDIR/bootstrap
    mkdir $TOPDIR/bootstrap
    cd $TOPDIR/bootstrap
        for link in $(echo $CFG | jq -r '.operating_systems[] | select(.name == "Ubuntu Touch") | .steps[].actions[]["core:download"].files[] | .url'); do
            wget $link
        done
    
}

clean() {
    fastboot erase userdata
    echo ${GREEN}${ENDBOLDCOLOR}"Bootstrap phase done! Beginning install."${NC}
}
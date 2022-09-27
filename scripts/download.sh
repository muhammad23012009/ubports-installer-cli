#!/usr/bin/env sh

. ./scripts/utils.sh

install_dir="${data_dir}/installation_files"

fetch_and_download_latest_images() {
   index_url=${1}
   latest_images="$(fetch "${URL}""${index_url}" | jq '.images |  map(select(.type == "full")) | sort_by(.version) | .[-1]'))"
   downloadable_files="$(echo "${latest_images}" | jq -r '.files[].path')"

   echo "${downloadable_files}" | while read -r files; do
      file=$(basename "${files}")
      fetch_persistent_files "${URL}${files}" "${install_dir}/${file}"
      echo "update $file $file.asc" >> "${install_dir}/ubuntu_command"
   done

   echo "unmount system" >> "${install_dir}/ubuntu_command"
}

create_inital_ubuntu_command() {
echo "format system
$( [ -z ${wipe:+true} ] || echo "format data")
load_keyring image-master.tar.xz image-master.tar.xz.asc
load_keyring image-signing.tar.xz image-signing.tar.xz.asc
mount system" > "${install_dir}/ubuntu_command"
}

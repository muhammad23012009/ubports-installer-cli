#!/usr/bin/env sh

. ./scripts/utils.sh

install_dir="${data_dir}/installation_files"

fetch_latest_images() {
   index_url=${1}
   latest_images="$(fetch "${URL}""${index_url}" | jq '.images |  map(select(.type == "full")) | sort_by(.version) | .[-1]'))"
   downloadable_files="$(echo "${latest_images}" | jq -r '.files[].path')"

   ret=$(echo "${downloadable_files}")
   if [ "${ret}" != "" ]; then
     echo ${ret}
   fi
}

download_latest_images() {
   index_url=${1}
   images=$(fetch_latest_images "${index_url}")

   for files in "${images}"; do
      file=$(basename "${files}")
      wget "${URL}${files}"
   done
}

create_ubuntu_command() {
echo "format system
$( [ -z ${wipe:+true} ] || echo "format data")
load_keyring image-master.tar.xz image-master.tar.xz.asc
load_keyring image-signing.tar.xz image-signing.tar.xz.asc
mount system" > "${install_dir}/ubuntu_command"
}

fill_ubuntu_command() {
   index_url=${1}
   ubuntu_command_file="${install_dir}/ubuntu_command"
   images=$(fetch_latest_images "${index_url}")

   echo "${images}" | while read -r files; do
      file=$(basename "${files}")
      echo "update $file $file.asc" >> "${ubuntu_command_file}"
   done

   echo "unmount system" >> "${ubuntu_command_file}"
}

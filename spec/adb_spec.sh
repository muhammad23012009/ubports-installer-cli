Describe 'scripts/adb.sh'
  Include scripts/adb.sh

  export adb_args=

  reset_args() {
    adb_returns=
    adb_args=
  }

  adb() {
    adb_args="${adb_args}${@}"
    %preserve adb_args
    %= "${adb_returns}"
  }

  BeforeEach 'reset_args'

  Describe '_adb_handle_error()'
    It 'detects not authorized'
      When call _adb_handle_error 'error: device still authorizing'
      The stderr should not equal ''
      The stderr should equal "${msg_unauthorized}"
    End

    It 'detects offline'
      When call _adb_handle_error 'connection reset'
      The stderr should not equal ''
      The stderr should equal "${msg_offline}"
    End

    It 'detects no device'
      When call _adb_handle_error 'adb: pre-KitKat sideload connection failed: closed'
      The stderr should not equal ''
      The stderr should equal "${msg_no_device}"
    End

    It 'returns 1 when nothing matched'
      When call _adb_handle_error 'success'
      The stderr should equal ''
      The status should equal 1
    End
  End

  Describe '_wrap_simple_adb()'
    It 'returns 1 when the error is handled'
      adb_returns='no device'

      When call _wrap_simple_adb
      The status should equal 1
      The stderr should not equal ''
    End
  End

  Describe 'adb_shell'
    It 'calls adb shell with arguments'
      adb_returns='1 echo 2'

      When call adb_shell 'echo 1 "echo 2"'
      The variable adb_args should equal 'shell echo 1 "echo 2"'
      The stdout should equal "${adb_returns}"
    End
  End

  Describe 'adb_has_access'
    It 'checks if it has shell access'
      adb_returns='.'

      When call adb_has_access
      The variable adb_args should equal 'shell echo .'
      The stdout should equal ''
      The status should equal 0
    End

    It "returns 1 if echo doesn't work"
      When call adb_has_access
      The status should equal 1
    End
  End

  Describe 'adb_wait'
    It 'calls adb wait-for-state-transport'
      When call adb_wait bootloader usb
      The variable adb_args should equal 'wait-for-usb-bootloader'
    End

    It 'uses any transport by default'
      When call adb_wait bootloader
      The variable adb_args should equal 'wait-for-any-bootloader'
    End

    It 'uses any state by default'
      When call adb_wait '' usb
      The variable adb_args should equal 'wait-for-usb-any'
    End

    It 'waits for anything by default'
      When call adb_wait
      The variable adb_args should equal 'wait-for-any-any'
    End
  End

  Describe 'adb_get_state'
    It 'calls adb get-state'
      adb_returns='device'

      When call adb_get_state
      The variable adb_args should equal 'get-state'
      The stdout should equal "${adb_returns}"
    End
  End

  fstab_example="# Android fstab file.

#<src>                                                     <mnt_point>        <type>      <mnt_flags and options>                               <fs_mgr_flags>
/dev/block/bootdevice/by-name/boot                         /boot              emmc        defaults                                              slotselect
/dev/block/platform/soc/1da4000.ufshc/by-name/system       /system_root       ext4        ro,barrier=1                                          wait,slotselect,avb
/dev/block/platform/soc/1da4000.ufshc/by-name/userdata     /data              ext4        errors=panic,noatime,nosuid,nodev,barrier=1,noauto_da_alloc        latemount,wait,check,formattable,fileencryption=ice:aes-256-heh,eraseblk=16777216,logicalblk=4096,quota,reservedsize=128M
/dev/block/platform/soc/1da4000.ufshc/by-name/misc         /misc              emmc        defaults                                              defaults
/dev/block/platform/soc/1da4000.ufshc/by-name/modem        /firmware          vfat        ro,shortname=lower,uid=1000,gid=1000,dmask=227,fmask=337,context=u:object_r:firmware_file:s0   wait,slotselect
/devices/soc/a800000.ssusb/a800000.dwc3*                   auto               vfat        defaults                                              voldmanaged=usb:auto
/dev/block/zram0                                           none               swap        defaults                                              zramsize=536870912,max_comp_streams=8
"

  Describe '_find_partition_in_fstab()'
    It 'finds the partition by mount point'
      When call _find_partition_in_fstab "${fstab_example}" 'system_root'
      The stdout should equal '/dev/block/platform/soc/1da4000.ufshc/by-name/system'
      The status should equal 0
    End

    It "doesn't find the partition by partial name"
      When call _find_partition_in_fstab "${fstab_example}" 'mi'
      The stdout should equal ''
      The status should equal 1
    End
  End

  Describe 'adb_format()'
    It 'unmounts, formats and mounts the partition'
      adb_umount_args=
      adb_make_ext4fs_args=
      adb_mount_args=

      adb() {
        cmd="${1#shell }"
        if [ "${cmd}" = "cat /etc/recovery.fstab" ]; then
          %= "${fstab_example}"
          return
        fi
        
        if [ "${cmd#umount}" != "${cmd}" ]; then
          adb_umount_args=${cmd}
          %preserve adb_umount_args
        elif [ "${cmd#make_ext4fs}" != "${cmd}" ]; then
          adb_make_ext4fs_args=${cmd}
          %preserve adb_make_ext4fs_args
        elif [ "${cmd#mount}" != "${cmd}" ]; then
          adb_mount_args=${cmd}
          %preserve adb_mount_args
        fi
        %= "ok"
      }
      
      When call adb_format data
      The status should equal 0
      The variable adb_umount_args should equal "umount '/data'"
      The variable adb_make_ext4fs_args should equal "make_ext4fs '/dev/block/platform/soc/1da4000.ufshc/by-name/userdata'"
      The variable adb_mount_args should equal "mount '/data'"
    End

    It "shows an error when fstab can't be read"
      adb() {
        %= ''
      }

      When call adb_format data
      The status should equal 1
      The stderr should not equal ''
      The stderr should equal "${msg_no_fstab}"
    End

    It 'shows an error when umount fails'
      adb() {
        cmd="${1#shell }"
        if [ "${cmd}" = "cat /etc/recovery.fstab" ]; then
          %= "${fstab_example}"
          return
        fi

        return 1
      }

      When call adb_format data
      The status should equal 2
      The stderr should not equal ''
      The stderr should equal "$(printf "${msg_umount_failed}" data)"
    End

    It 'shows an error when make_ext4fs fails'
      adb() {
        cmd="${1#shell }"
        if [ "${cmd}" = "cat /etc/recovery.fstab" ]; then
          %= "${fstab_example}"
          return
        fi

        if [ "${cmd#make_ext4fs}" != "${cmd}" ]; then
          return 1
        fi
      }

      When call adb_format data
      The status should equal 3
      The stderr should not equal ''
      The stderr should equal "$(printf "${msg_make_ext4fs_failed}" /dev/block/platform/soc/1da4000.ufshc/by-name/userdata)"
    End

    It 'shows an error when mount fails'
      adb() {
        cmd="${1#shell }"
        if [ "${cmd}" = "cat /etc/recovery.fstab" ]; then
          %= "${fstab_example}"
          return
        fi

        if [ "${cmd#mount}" != "${cmd}" ]; then
          return 1
        fi
      }

      When call adb_format data
      The status should equal 4
      The stderr should not equal ''
      The stderr should equal "$(printf "${msg_mount_failed}" data)"
    End
  End
End
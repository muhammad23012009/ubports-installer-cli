Describe 'scripts/fastboot.sh'
  Include scripts/fastboot.sh

  reset_args() {
    fastboot_args=
  }

  fastboot() {
    fastboot_args="${fastboot_args}${@}"
    %preserve fastboot_args
    %= "ok"
  }

  BeforeEach 'reset_args'

  Describe '_fastboot_handle_error()'
    It 'detects low battery'
      When call _fastboot_handle_error 'FAILED (remote: low power, need battery charging.)'
      The stderr should not equal ''
      The stderr should equal "${msg_low_power}"
    End

    It 'detects locked bootloader'
      When call _fastboot_handle_error 'download for partition boot is not allowed'
      The stderr should not equal ''
      The stderr should equal "${msg_locked_bootloader}"
    End

    It 'detects oem unlock not allowed'
      When call _fastboot_handle_error 'oem unlock is not allowed'
      The stderr should not equal ''
      The stderr should equal "${msg_enable_unlocking}"
    End

    It 'detects boot failed'
      When call _fastboot_handle_error 'FAILED (remote failure)'
      The stderr should not equal ''
      The stderr should equal "${msg_boot_failed}"
    End

    It 'detects device disconnected'
      When call _fastboot_handle_error 'FAILED (data transfer failure (Protocol error))'
      The stderr should not equal ''
      The stderr should equal "${msg_no_device}"
    End

    It 'returns 1 when nothing matched'
      When call _fastboot_handle_error 'success'
      The stderr should equal ''
      The status should equal 1
    End
  End

  Describe '_wrap_simple_fastboot()'
    It 'returns 1 when the error is handled'
      fastboot() {
        %= 'FAILED (remote failure)' 1>&2
      }
      When call _wrap_simple_fastboot
      The status should equal 1
      The stderr should not equal ''
    End
  End

  Describe 'fastboot_has_access()'
    It 'returns 0 when a device is found'
      fastboot() {
        %= 'deadbeef	fastboot'
      }

      When call fastboot_has_access
      The status should equal 0
    End

    It 'returns 1 when no devices are found'
      fastboot() {
        %= ''
      }

      When call fastboot_has_access
      The status should equal 1
    End
  End

  Describe 'fastboot_wait()'
    It 'returns 0 when device is found'
      fastboot_has_access() {
        return 0
      }

      When call fastboot_wait
      The status should equal 0
    End

    It 'sleeps when device is not found'
      has_slept=1
      sleep() {
        has_slept=0
        %preserve has_slept
      }
      
      fastboot_has_access() {
        return ${has_slept}
      }

      When call fastboot_wait
      The variable has_slept should equal 0
    End
  End

  Describe 'fastboot_oem_unlock()'
    It 'calls fastboot oem unlock ${code}'
      When call fastboot_oem_unlock asdf-code
      The variable fastboot_args should equal "oem unlock asdf-code"
    End

    It 'returns 0 on success'
      fastboot() {
        %= 'ok'
        return 0
      }

      When call fastboot_oem_unlock
      The status should equal 0
    End

    It 'returns 0 when already unlocked'
      fastboot() {
        %= 'Not necessary'
        return 1
      }

      When call fastboot_oem_unlock
      The status should equal 0
    End

    It 'instructs to enable OEM unlocking'
      fastboot() {
        %= 'oem unlock is not allowed!' 1>&2
        return 1
      }

      When call fastboot_oem_unlock
      The stderr should equal "${msg_enable_unlocking}"
      The status should equal 1
    End
  End

  Describe 'fastboot_flashing_unlock()'
    It 'calls fastboot flashing unlock'
      When call fastboot_flashing_unlock
      The variable fastboot_args should equal "flashing unlock"
    End
  End

  Describe 'fastboot_reboot_bootloader()'
    It 'calls fastboot reboot-bootloader'
      When call fastboot_reboot_bootloader
      The variable fastboot_args should equal "reboot-bootloader"
    End
  End

  Describe 'fastboot_reboot_fastboot()'
    It 'calls fastboot reboot-fastboot'
      When call fastboot_reboot_fastboot
      The variable fastboot_args should equal "reboot-fastboot"
    End
  End

  Describe 'fastboot_reboot_recovery()'
    It 'calls fastboot reboot-recovery'
      When call fastboot_reboot_recovery
      The variable fastboot_args should equal "reboot-recovery"
    End
  End

  Describe 'fastboot_reboot()'
    It 'calls fastboot reboot'
      When call fastboot_reboot
      The variable fastboot_args should equal "reboot"
    End
  End

  Describe 'fastboot_continue()'
    It 'calls fastboot continue'
      When call fastboot_continue
      The variable fastboot_args should equal "continue"
    End
  End

  Describe 'fastboot_set_active()'
    It 'calls fastboot --set-active'
      When call fastboot_set_active a
      The variable fastboot_args should equal "--set-active=a"
    End

    It 'returns 2 on fastboot error in stdout'
      fastboot() {
        %= 'some error happened'
        return 0
      }

      When call fastboot_set_active a
      The stdout should equal 'some error happened'
      The status should equal 2
    End
  End

  Describe 'fastboot_flash()'
    fastboot_has_access() {
      return 0
    }

    It 'flashes all partitions'
params="boot;boot.img;0
recovery;recovery.img;1"
      When call fastboot_flash "${params}"
      # only testing the last one because the args variable
      # is not preserved properly in a subshell
      The variable fastboot_args should include "flash:raw recovery recovery.img"
    End

    It 'returns 1 on known errors'
      fastboot() {
        %= 'Bootloader is locked' 1>&2
        return 1
      }

      When call fastboot_flash "boot;boot.img;0"
      The status should equal 1
      The stderr should equal "${msg_locked_bootloader}"
    End

    It 'dumps stdout + stderr on unknown error'
      fastboot() {
        %= 'stderr' 1>&2
        %= 'stdout'
        return 1
      }

      When call fastboot_flash "boot;boot.img;0"
      The status should equal 1
      The stderr should include 'stderr'
      The stderr should include 'stdout'
    End

    It 'calls fastboot_wait at the end'
      wait_called=

      fastboot_wait() {
        wait_called=1
        %preserve wait_called
      }

      When call fastboot_flash "boot;boot.img;0"
      The status should equal 0
      The variable wait_called should equal 1
    End
  End

  Describe 'fastboot_create_logical_partition()'
    It 'calls fastboot create-logical-partition with parameters'
      When call fastboot_create_logical_partition somepart 123
      The variable fastboot_args should equal "create-logical-partition somepart 123"
    End
  End

  Describe 'fastboot_delete_logical_partition()'
    It 'calls fastboot delete-logical-partition with parameters'
      When call fastboot_delete_logical_partition somepart
      The variable fastboot_args should equal "delete-logical-partition somepart"
    End
  End

  Describe 'fastboot_resize_logical_partition()'
    It 'calls fastboot resize-logical-partition with parameters'
      When call fastboot_resize_logical_partition somepart 1234
      The variable fastboot_args should equal "resize-logical-partition somepart 1234"
    End
  End

  Describe 'fastboot_wipe_super()'
    It 'calls fastboot wipe-super with image path'
      When call fastboot_wipe_super device group file.img
      The variable fastboot_args should equal "wipe-super \"${cache_dir}/device/group/file.img\""
    End
  End

  Describe 'fastboot_erase()'
    It 'calls fastboot erase with partition name'
      When call fastboot_erase bootp
      The variable fastboot_args should equal "erase bootp"
    End
  End

  Describe 'fastboot_format()'
    It 'calls fastboot format'
      When call fastboot_format bootp
      The variable fastboot_args should equal "format bootp"
    End

    It 'calls fastboot format with type'
      When call fastboot_format bootp ext4
      The variable fastboot_args should equal "format:ext4 bootp"
    End

    It 'calls fastboot format with type and size'
      When call fastboot_format bootp ext4 789
      The variable fastboot_args should equal "format:ext4:789 bootp"
    End

    It 'calls fastboot format without size if no type given'
      When call fastboot_format bootp '' 789
      The variable fastboot_args should equal "format bootp"
    End
  End

  Describe 'fastboot_boot()'
    It 'calls fastboot boot with image path'
      When call fastboot_boot device group file.img
      The variable fastboot_args should equal "boot \"${cache_dir}/device/group/file.img\""
    End
  End

  Describe 'fastboot_update()'
    It 'calls fastboot update'
      When call fastboot_update device group file.zip
      The variable fastboot_args should equal "update \"${cache_dir}/device/group/file.zip\""
    End

    It 'calls fastboot update with -w'
      When call fastboot_update device group file.zip true
      The variable fastboot_args should equal "-w update \"${cache_dir}/device/group/file.zip\""
    End
  End

  Describe 'fastboot_assert_var()'
    fastboot_has_access() {
      return 0
    }

    It 'checks fastboot variable'
      fastboot() {
        %= 'somevar: somevalue'
      }

      When call fastboot_assert_var somevar somevalue
      The status should equal 0
      The stderr should equal ""
    End

    It "returns 1 with error when variable doesn't match"
      fastboot() {
        %= 'somevar: somevaluee'
      }

      When call fastboot_assert_var somevar somevalue
      The status should equal 1
      The stderr should equal "expected somevar to equal 'somevalue' but got 'somevaluee'"
    End

    It "returns 1 with when variable name doesn't match"
      fastboot() {
        %= 'somevarr: somevalue'
      }

      When call fastboot_assert_var somevar somevalue
      The status should equal 1
    End

    It 'errors out if device is not connected'
      fastboot_has_access() {
        return 1
      }

      When call fastboot_assert_var somevar somevalue
      The status should equal 1
      The stderr should equal "${msg_no_device}"
    End
  End
End
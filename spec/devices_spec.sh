Describe 'scripts/devices.sh'
  Include scripts/devices.sh

  set_no_cache() {
    NO_CACHE=1
  }
  unset_cache() {
    unset -v NO_CACHE
  }

  BeforeAll 'set_no_cache'
  AfterAll 'unset_cache'

  wget() {
    %= "mock-${2}"
  }

  Describe 'fetch_devices_index()'
    It 'fetches devices index'
      When call fetch_devices_index
      The output should equal 'mock-https://ubports.github.io/installer-configs/v2/index.json'
    End
  End

  Describe 'fetch_device_aliases()'
    It 'fetches device aliases'
      When call fetch_device_aliases
      The output should equal 'mock-https://ubports.github.io/installer-configs/v2/aliases.json'
    End
  End

  Describe 'fetch_device_config()'
    It 'fetches device config'
      When call fetch_device_config 'yggdrasil'
      The output should equal 'mock-https://ubports.github.io/installer-configs/v2/devices/yggdrasil.json'
    End
  End
End
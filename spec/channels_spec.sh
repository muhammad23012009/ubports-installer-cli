Describe 'scripts/channels.sh'
  Include scripts/channels.sh

  set_no_cache() {
    NO_CACHE=1
  }
  unset_cache() {
    unset -v NO_CACHE
  }

  BeforeAll 'set_no_cache'
  AfterAll 'unset_cache'

  wget() {
    %= "$(cat ./spec/mocks/channels.json)"
  }

  Describe 'fetch_channels()'
    channels_test() {
      [ "${channels_test}" = "$(wget)" ]
    }

    It 'fetches channels'
      When call fetch_channels
      The output should satisfy channels_test
    End
  End

  Describe 'get_device_channels()'
    It 'returns a list of channels for specified device only'
      When call get_device_channels 'mock_device' '16.04'
      The output should include '- 16.04/arm64/android9/devel'
      The output should include '- 16.04/arm64/android9/stable'
      The output should include '- 16.04/arm64/android9/rc'
      The output should not include '- 15.04/arm64/android9/devel'
    End
  End

  Describe 'select_device()'
    It 'returns index.json when full channel is specified'
      When call select_device 'mock_device' '16.04/arm64/android9/devel'
      The output should equal '/16.04/arch/this_is_a_mock/devel/mock_device/index.json'
    End
  End

  Describe 'select_device() [parametric]'
    Parameters:matrix
      devel rc stable
      16.04 20.04
    End

    It "returns index.json for (channel: $1, os: $2)"
      When call select_device 'mock_device' $1 $2
      The output should equal "/$2/arch/this_is_a_mock/$1/mock_device/index.json"
    End
  End
End

Describe 'scripts/utils.sh'
  Include scripts/utils.sh

  NO_CACHE=1

  Describe 'fetch()'
    It 'returns 1 without fetch or curl'
      When call fetch 'some_url'
      The status should equal 1
    End

    It 'fetches stuff using curl'
      curl() {
        %= "curl-${2}"
      }
      When call fetch 'some_curl_url'
      The output should equal 'curl-some_curl_url'
    End

    It 'fetches stuff using wget'
      wget() {
        %= "mock-${2}"
      }

      When call fetch 'some_wget_url'
      The output should equal 'mock-some_wget_url'
    End


    url="cached_url-$(date +%s)"
    # these cases depend on each other - the first one creates the file
    It 'saves to cache'
      unset -v NO_CACHE
      File cached="${cache_dir}/${url}"

      wget() {
        %= "wget-${2}"
      }

      When call fetch "${url}"
      The output should equal "wget-${url}"
      The file cached should be file
    End

    It 'reads from cache'
      unset -v NO_CACHE

      wget() {
        %= 'should not be called'
      }

      When call fetch "${url}"
      The output should not equal 'should not be called'
    End
  End

  Describe 'contains()'
    It 'returns 1 when string is not found'
      When call contains 'asdf' 'ghjk'
      The status should equal 1
    End

    It 'returns 0 when string is found'
      When call contains 'asdf' 'sd'
      The status should equal 0
    End
  End

  Describe 'ct()'
    It 'colors bold text'
      When call ct 'red' true
      The output should equal "$(printf '\033[0m\033[31m\033[1m')"
    End

    It 'clears the color when not passed arguments'
      When call ct
      The output should equal "$(printf '\033[0m\033[0m')"
    End
  End

  Describe 'ct() [parametric]'
    Parameters
      red '\033[31m'
      green '\033[32m'
      orange '\033[33m'
      blue '\033[34m'
      magenta '\033[35m'
      cyan '\033[36m'
      white '\033[37m'
      black '\033[30m'
    End

    It "colors text ${1}"
      When call ct "${1}"
      The output should equal "$(printf "\033[0m${2}")"
    End
  End
End
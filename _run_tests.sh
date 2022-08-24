#!/usr/bin/env sh

e=$( [ -n "${1}" ] && echo "-E ${1}")

shellcheck -x ./scripts/*.sh
shellspec --sandbox --shell=/usr/bin/dash ${e}
shellspec --sandbox --shell=/usr/bin/zsh ${e}
shellspec --sandbox --shell=/usr/bin/bash ${e}
shellspec -f d --sandbox --kcov ${e}

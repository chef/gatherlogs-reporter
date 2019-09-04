_gatherlog_profiles() {
  local args
  read -cA args

  completions="$(gatherlog profiles)"

  reply=("${(ps:\n:)completions}")
}

_gatherlog_commands() {
  local args
  read -cA args

  completions="$(gatherlog --complete)"

  reply=("${(ps:\n:)completions}")
}

compctl -K _gatherlog_commands -x 'c[-1,--path],c[-1,-p]' -f - 's[--]' -k '(path debug all profiles verbose version)' \
                          - 'c[-1,report]' -K _gatherlog_profiles -- gatherlog

_gatherlog_profiles() {
  local args
  read -cA args

  completions="$(check_logs --profiles)"

  reply=("${(ps:\n:)completions}")
}

compctl -K _gatherlog_profiles -x 's[--]' -k '(path debug all profiles verbose version)' -- check_logs

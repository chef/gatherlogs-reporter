_gatherlog_profiles() {
  local args
  read -cA args

  completions="$(check_logs -p)"

  reply=("${(ps:\n:)completions}")
}

compctl -K _gatherlog_profiles -x 's[-]' -k '(a v h)' -- check_logs

function run_supercronic() {
  local crontab="$1"
  local timeout="${2:-2s}"
  timeout --preserve-status --kill-after "30s" "$timeout" \
    "${BATS_TEST_DIRNAME}/../supercronic" ${SUPERCRONIC_ARGS:-} "$crontab" 2>&1
}

@test "it starts" {
  run_supercronic "${BATS_TEST_DIRNAME}/noop.crontab" 2s
}

@test "it runs a cron job" {
  n="$(run_supercronic "${BATS_TEST_DIRNAME}/hello.crontab" 5s | grep -iE "hello from crontab" | wc -l)"
  [[ "$n" -gt 3 ]]
}

@test "it passes the environment through" {
  VAR="hello from foo" run_supercronic "${BATS_TEST_DIRNAME}/env.crontab" | grep -iE "hello from foo"
}

@test "it overrides the environment with the crontab" {
  VAR="hello from foo" run_supercronic "${BATS_TEST_DIRNAME}/override.crontab" | grep -iE "hello from bar"
}

@test "it warns when USER is set" {
  run_supercronic "${BATS_TEST_DIRNAME}/user.crontab" 5s | grep -iE "processes will not.*USER="
}

@test "it warns when a job is falling behind" {
  run_supercronic "${BATS_TEST_DIRNAME}/timeout.crontab" 5s | grep -iE "job took too long to run"
}

@test "it runs overlapped jobs" {
  n="$(SUPERCRONIC_ARGS="-overlapping" run_supercronic "${BATS_TEST_DIRNAME}/timeout.crontab" 5s | grep -iE "starting" | wc -l)"
  [[ "$n" -eq 5 ]]
}

@test "it supports debug logging " {
  SUPERCRONIC_ARGS="-debug" run_supercronic "${BATS_TEST_DIRNAME}/hello.crontab" | grep -iE "debug"
}

@test "it supports JSON logging " {
  SUPERCRONIC_ARGS="-json" run_supercronic "${BATS_TEST_DIRNAME}/noop.crontab" | grep -iE "^{"
}

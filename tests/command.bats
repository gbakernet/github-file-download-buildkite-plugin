#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# Uncomment to enable stub debugging
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "Example test" {
  run echo "test"

  assert_success
  assert_output "test"
}

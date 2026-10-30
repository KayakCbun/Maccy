#!/bin/bash
# Usage: test.sh <log file> <xcodebuild test arguments...>
#
# Runs `xcodebuild test`, printing the lines matching $PROGRESS as they come.
# If the output stops for 90 seconds, as when a test or the test host hangs,
# prints stack samples of every running Maccy process and stops the tests.
set -uo pipefail

log=$1
shift
idle_limit=${IDLE_LIMIT:-90}

(xcodebuild test "$@" > "$log" 2>&1; echo $? > "$log.status") &
runner=$!

shown=0
idle=0
show_new_lines() {
  local lines
  lines=$(wc -l < "$log")
  if [ "$lines" -gt "$shown" ]; then
    sed -n "$((shown + 1)),${lines}p" "$log" | grep -E "$PROGRESS" || true
    shown=$lines
    idle=0
  fi
}

while kill -0 "$runner" 2> /dev/null; do
  sleep 5
  idle=$((idle + 5))
  show_new_lines
  if [ "$idle" -ge "$idle_limit" ]; then
    echo "::error::No test output for $idle_limit seconds. Stacks of the running Maccy processes follow."
    for pid in $(pgrep -x Maccy); do
      sample "$pid" 3 -file "sample-$pid.txt" > /dev/null 2>&1
      echo "===== Maccy $pid"
      sed -n '/^Call graph:/,/^Total number in stack/p' "sample-$pid.txt" | head -400
    done
    pkill -x xcodebuild
    sleep 5
    tail -30 "$log"
    exit 1
  fi
done
show_new_lines

status=$(cat "$log.status")
if [ "$status" != 0 ]; then
  grep -E "error:|failed|Fatal" "$log" | sort -u | head -80
  tail -40 "$log"
fi
exit "$status"

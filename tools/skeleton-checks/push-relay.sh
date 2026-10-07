#!/bin/bash
# Sends the simulated notifications that the app-lock UI tests ask for
# (HarnessUITests/AutomatedChecks+AppLock.swift). A UI test runs inside the
# simulator and cannot run simctl itself, so it writes a payload file
# <name>.apns into the folder that this script watches. This script sends
# the file with `xcrun simctl push` and renames it to <name>.sent (or
# <name>.failed). automated-checks.sh starts this script before the checks
# and stops it after them.
#
# Usage: push-relay.sh <simulator udid> <folder>
UDID=$1
DIR=$2
mkdir -p "$DIR"
while true; do
  for payload in "$DIR"/*.apns; do
    [ -e "$payload" ] || continue
    if xcrun simctl push "$UDID" uk.midmorning.app "$payload" >"${payload%.apns}.out" 2>&1; then
      mv "$payload" "${payload%.apns}.sent"
    else
      mv "$payload" "${payload%.apns}.failed"
    fi
  done
  sleep 0.3
done

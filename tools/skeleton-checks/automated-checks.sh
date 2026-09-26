#!/bin/bash
# Runs the automated device checks (ruling r13-19, mm-t43.30) on a simulator:
# HarnessUITests/AutomatedChecks.swift. Each test names the device-check bead
# and the check that it replaces. Ash runs this by hand; it is not part of
# ./verify (see README.md in this folder for the reason).
#
# Usage: tools/skeleton-checks/automated-checks.sh [test name ...]
#   With no test name, the script runs every test in AutomatedChecks.
#   DEVICE_NAME sets the simulator (default: mm-automated-checks). The script
#   makes that simulator when it does not exist, so that the run does not
#   disturb a simulator that another session uses.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
DEVICE_NAME=${DEVICE_NAME:-mm-automated-checks}
OUT=${OUT:-$HERE/out/automated}
started=$(date +%s)
step() { printf '%4ss  %s\n' "$(( $(date +%s) - started ))" "$1"; }

# 1. The simulator.
UDID=$(xcrun simctl list devices | grep " $DEVICE_NAME (" | grep -oE '[0-9A-F]{8}-[0-9A-F-]{27}' | head -1)
if [ -z "$UDID" ]; then
  RUNTIME=$(xcrun simctl list runtimes | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | tail -1)
  step "make the simulator $DEVICE_NAME ($RUNTIME)"
  UDID=$(xcrun simctl create "$DEVICE_NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-17 "$RUNTIME") || exit 1
fi
step "boot the simulator $UDID"
xcrun simctl boot "$UDID" 2>/dev/null
xcrun simctl bootstatus "$UDID" -b >/dev/null || exit 1

# 2. Build and install the app; build the UI-test bundle.
step "build the app"
xcodebuild -project "$ROOT/App/Midmorning.xcodeproj" -scheme Midmorning \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd-app" -quiet build || exit 1
step "install the app"
xcrun simctl install "$UDID" "$HERE/.dd-app/Build/Products/Debug-iphonesimulator/Midmorning.app" || exit 1
step "build the UI tests"
xcodebuild build-for-testing -project "$HERE/Harness.xcodeproj" -scheme HarnessUITests \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd" -quiet || exit 1

# 3. Seed the stores.
step "seed the stores"
(cd "$HERE/seeder" && swift build -q) || exit 1
for scenario in week1 review corrupt; do
  "$HERE/seeder/.build/debug/Seeder" "$HERE/stores/$scenario/Record.store" "$scenario" >/dev/null || exit 1
done

# 4. Run the checks. The tests copy a seeded store into the app's data
# container before each launch.
DATA=$(xcrun simctl get_app_container "$UDID" uk.midmorning.app data) || exit 1
only=()
for name in "$@"; do only+=("-only-testing:HarnessUITests/AutomatedChecks/$name"); done
[ ${#only[@]} -eq 0 ] && only=("-only-testing:HarnessUITests/AutomatedChecks")
rm -rf "$OUT"; mkdir -p "$OUT"
step "run the checks"
# A failed test keeps its screen and hierarchy in $OUT. Xcode's own
# diagnostics collection after a failure can wait ten minutes, so it is off.
TEST_RUNNER_APP_DATA="$DATA" TEST_RUNNER_STORES="$HERE/stores" TEST_RUNNER_OUT_DIR="$OUT" \
  xcodebuild test-without-building -project "$HERE/Harness.xcodeproj" -scheme HarnessUITests \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd" \
  -collect-test-diagnostics never \
  -resultBundlePath "$OUT/AutomatedChecks.xcresult" "${only[@]}" >"$OUT/xcodebuild.log" 2>&1
status=$?
grep -E "Test Case .* (passed|failed)|error: " "$OUT/xcodebuild.log" | sed -E 's/^.*Test Case .-\[HarnessUITests\.AutomatedChecks (test[^]]*)\]. (passed|failed).*\(([0-9.]+) seconds\).*/\2  \1 (\3 s)/'
step "done (the log and the result bundle are in $OUT)"
exit "$status"

#!/bin/bash
# Runs the automated device checks (ruling r13-19, mm-t43.30) on a simulator:
# HarnessUITests/AutomatedChecks.swift. Each test names the device-check bead
# and the check that it replaces. Ash runs this by hand; it is not part of
# ./verify (see README.md in this folder for the reason). A device check
# marked "Automated by" can be skipped only after a dated run in which every
# check passes on a committed build. A tester build or a release build that
# skips such a check needs a new run on its own commit (gate mm-t43.31;
# README.md, "When Ash can skip a device check"). Run between 09:00 and
# 03:30: the seeder stops before 09:00.
#
# At the end the script writes the line for the README table: the date, the
# commit, the simulator runtime and the result. A run on a working tree with
# changes that are not committed does not count; the script says so loudly
# at the start and in that line.
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

# 0. The commit. Only a run on a committed build, with no change in the
# working tree, counts for the README table.
COMMIT=$(git -C "$ROOT" rev-parse --short=7 HEAD) || exit 1
BRANCH=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)
CHANGES=$(git -C "$ROOT" status --porcelain)
warn_changes() {
  echo "********************************************************************"
  echo "WARNING: the working tree has changes that are not committed."
  echo "This run builds those changes, so it does not count for the table in"
  echo "tools/skeleton-checks/README.md. Commit, then run the checks again."
  echo "********************************************************************"
}
[ -n "$CHANGES" ] && warn_changes

# The draft state that testDraftShowsAboveTheCardTitle expects: the bundle
# is a draft when Packages/Content/Resources holds no sign-off file for its
# content version (Packages/Content/SignOff.swift).
RESOURCES="$ROOT/Packages/Content/Resources"
CONTENT_VERSION=$(plutil -extract contentVersion raw "$RESOURCES/manifest.json") || exit 1
if [ -f "$RESOURCES/content-signoff-v$CONTENT_VERSION.json" ]; then CONTENT_DRAFT=0; else CONTENT_DRAFT=1; fi

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
# The runtime of that simulator, for example "iOS 27.0 (24A434)".
RUNTIME_NAME=$(xcrun simctl list -j devices runtimes | python3 -c '
import json, sys
data = json.load(sys.stdin)
udid = sys.argv[1]
key = next((k for k, devices in data["devices"].items() for d in devices if d["udid"] == udid), None)
runtime = next((r for r in data["runtimes"] if r["identifier"] == key), None)
print("%s (%s)" % (runtime["name"], runtime["buildversion"]) if runtime else (key or "unknown"))
' "$UDID")

# 2. Build and install the app; build the UI-test bundle.
step "build the app"
xcodebuild -project "$ROOT/App/Midmorning.xcodeproj" -scheme Midmorning \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd-app" -quiet build || exit 1
step "install the app"
# A new install each run: only a new install gives back the notification
# permission "not determined" that testZFreshInstallAsksForNotificationsOnToday
# needs (mm-t24.25). The tests copy their own store before each launch.
xcrun simctl uninstall "$UDID" uk.midmorning.app >/dev/null 2>&1
xcrun simctl install "$UDID" "$HERE/.dd-app/Build/Products/Debug-iphonesimulator/Midmorning.app" || exit 1
step "build the UI tests"
xcodebuild build-for-testing -project "$HERE/Harness.xcodeproj" -scheme HarnessUITests \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd" -quiet || exit 1

# 3. Seed the stores.
step "seed the stores"
(cd "$HERE/seeder" && swift build -q) || exit 1
for scenario in week1 review corrupt stage1Morning stage1Evening stage2Evening reminderSettings unfinishedOnboarding; do
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
  TEST_RUNNER_CONTENT_DRAFT="$CONTENT_DRAFT" \
  xcodebuild test-without-building -project "$HERE/Harness.xcodeproj" -scheme HarnessUITests \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd" \
  -collect-test-diagnostics never \
  -resultBundlePath "$OUT/AutomatedChecks.xcresult" "${only[@]}" >"$OUT/xcodebuild.log" 2>&1
status=$?
grep -E "Test Case .* (passed|failed)|error: " "$OUT/xcodebuild.log" | sed -E 's/^.*Test Case .-\[HarnessUITests\.AutomatedChecks (test[^]]*)\]. (passed|failed).*\(([0-9.]+) seconds\).*/\2  \1 (\3 s)/'
step "done (the log and the result bundle are in $OUT)"

# 5. The line for the README table.
passed=$(grep -cE "Test Case .* passed" "$OUT/xcodebuild.log")
failed=$(grep -cE "Test Case .* failed" "$OUT/xcodebuild.log")
seconds=$(( $(date +%s) - started ))
result="$passed of $(( passed + failed )) passed in $seconds s"
[ "$status" -ne 0 ] && [ "$failed" -eq 0 ] && result="$result; xcodebuild failed with status $status (see $OUT/xcodebuild.log)"
[ $# -gt 0 ] && result="$result; only the named checks ran, so this run does not count"
[ -n "$CHANGES" ] && result="$result; the working tree had changes that are not committed, so this run does not count"
[ -n "$CHANGES" ] && warn_changes
echo
echo "The line for the table in tools/skeleton-checks/README.md:"
echo "| $(LC_ALL=C date '+%-d %B %Y') | $COMMIT ($BRANCH) | $RUNTIME_NAME | $result. |"
exit "$status"

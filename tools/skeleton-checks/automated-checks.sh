#!/bin/bash
# Runs the automated device checks (ruling r13-19, mm-t43.30) on a simulator:
# class AutomatedChecks, in HarnessUITests/AutomatedChecks.swift and
# HarnessUITests/AutomatedChecks+*.swift. Each test names the device-check bead
# and the check that it replaces. Ash runs this by hand; it is not part of
# ./verify (see README.md in this folder for the reason). A device check
# marked "Automated by" can be skipped only after a dated run in which every
# check passes on a committed build. A tester build or a release build that
# skips such a check needs a new run on its own commit (gate mm-t43.31;
# README.md, "When Ash can skip a device check"). Run between 09:00 and
# 03:30: the seeder stops before 09:00.
#
# The app is installed new for each run. The tests in FRESH_PERMISSION_TESTS
# (step 4) need the notification permission "not determined", so they run
# first, in a pass of their own, before any other test can answer the
# system request. testZFreshInstallAsksForNotificationsOnToday answers
# "Allow" in that pass, so the script then installs the app new again: the
# other tests start with the permission "not determined", as before.
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
APP_BUNDLE="$HERE/.dd-app/Build/Products/Debug-iphonesimulator/Midmorning.app"
# The permission goes with the app's section in the simulator's BulletinBoard.
# Just after a boot, an uninstall left that section, and the new install kept
# the old answer (7 October 2026). A second install and uninstall removed it.
# So the script uninstalls until the section is gone, three times at most.
# A new install also gives a new data container; DATA is its path.
SECTIONS="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/BulletinBoard/VersionedSectionInfo.plist"
install_new() {
  for attempt in 1 2 3; do
    xcrun simctl uninstall "$UDID" uk.midmorning.app >/dev/null 2>&1
    for _ in $(seq 1 20); do
      grep -q "uk.midmorning.app" "$SECTIONS" 2>/dev/null || break 2
      sleep 0.5
    done
    xcrun simctl install "$UDID" "$APP_BUNDLE" >/dev/null 2>&1
    sleep 2
  done
  grep -q "uk.midmorning.app" "$SECTIONS" 2>/dev/null && echo "WARNING: the notification permission of the old install can stay; a test that needs the permission \"not determined\" can fail."
  xcrun simctl install "$UDID" "$APP_BUNDLE" || return 1
  DATA=$(xcrun simctl get_app_container "$UDID" uk.midmorning.app data) || return 1
}
install_new || exit 1
step "build the UI tests"
xcodebuild build-for-testing -project "$HERE/Harness.xcodeproj" -scheme HarnessUITests \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd" -quiet || exit 1

# 3. Seed the stores.
step "seed the stores"
(cd "$HERE/seeder" && swift build -q) || exit 1
# The record and plan scenarios: seeder/Sources/Seeder/RecordPlanScenarios.swift.
# The onboarding and review scenarios (or-*): seeder/Sources/Seeder/OnboardingReviewScenarios.swift.
# The export page scenario (exportPages): seeder/Sources/Seeder/ExportPagesScenarios.swift.
# The reminders and export scenarios: seeder/Sources/Seeder/RemindersExportScenarios.swift.
# The app-lock scenarios (lock-*): seeder/Sources/Seeder/AppLockScenarios.swift.
# The reminder tap scenario (tap-night): seeder/Sources/Seeder/ReminderTapScenarios.swift.
for scenario in week1 review corrupt \
  fifteen fifteenPlan bands planMatched planBand planStar planMissed planEarly planStrings dayStart6 \
  or-tomorrow or-secondday or-plancard or-plan or-pinned or-tworuns or-deterioration or-weighin \
  exportPages \
  stage1Morning stage1Evening stage1Paused stage2Evening stage2Morning reminderSettings unfinishedOnboarding \
  lock-week1 lock-week1-30s lock-review lock-face-only lock-gym \
  tap-night; do
  "$HERE/seeder/.build/debug/Seeder" "$HERE/stores/$scenario/Record.store" "$scenario" >/dev/null || exit 1
done

# 4. Run the checks. The tests copy a seeded store into the app's data
# container (DATA) before each launch.
only=()
for name in "$@"; do only+=("-only-testing:HarnessUITests/AutomatedChecks/$name"); done
[ ${#only[@]} -eq 0 ] && only=("-only-testing:HarnessUITests/AutomatedChecks")
rm -rf "$OUT"; mkdir -p "$OUT"
# The app-lock checks ask for simulated notifications through $OUT/push.
"$HERE/push-relay.sh" "$UDID" "$OUT/push" & relay=$!; trap 'kill "$relay" 2>/dev/null' EXIT
step "run the checks"
# A failed test keeps its screen and hierarchy in $OUT. Xcode's own
# diagnostics collection after a failure can wait ten minutes, so it is off.
#
# The tests that need the notification permission "not determined". Only a
# new install (step 2) gives that state. An answer to the system request
# stays until the next install, and tests in several files answer it. So
# these tests run first, in a pass of their own (FreshPermission.xcresult),
# and every other test runs after them. A name that no test file holds is
# left out. testZFreshInstallAsksForNotificationsOnToday answers "Allow" in
# the first pass. With the permission "allowed", the app schedules real
# reminders for each seeded store, and a reminder can show a banner over the
# navigation bar during a later test. So the script installs the app new
# between the two passes, and the second pass starts with the permission
# "not determined". A test in the second pass that answers the request
# itself (the testZ reminder count tests, which run last; the reminder
# tests of the app lock) leaves the permission "allowed" for the tests that
# run after it.
FRESH_PERMISSION_TESTS=(testZFreshInstallAsksForNotificationsOnToday testFifteenEntriesKeepThePinnedHeader)
first=(); rest=()
for id in "${only[@]}"; do
  case " ${FRESH_PERMISSION_TESTS[*]} " in
    *" ${id##*/} "*) first+=("$id") ;;
    *) rest+=("$id") ;;
  esac
done
if [ $# -eq 0 ]; then
  for name in "${FRESH_PERMISSION_TESTS[@]}"; do
    grep -q "func $name()" "$HERE"/HarnessUITests/*.swift || continue
    first+=("-only-testing:HarnessUITests/AutomatedChecks/$name")
    rest+=("-skip-testing:HarnessUITests/AutomatedChecks/$name")
  done
fi
run_pass() {
  local bundle=$1; shift
  TEST_RUNNER_APP_DATA="$DATA" TEST_RUNNER_STORES="$HERE/stores" TEST_RUNNER_OUT_DIR="$OUT" \
    TEST_RUNNER_CONTENT_DRAFT="$CONTENT_DRAFT" \
    xcodebuild test-without-building -project "$HERE/Harness.xcodeproj" -scheme HarnessUITests \
    -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd" \
    -collect-test-diagnostics never \
    -resultBundlePath "$OUT/$bundle.xcresult" "$@" >>"$OUT/xcodebuild.log" 2>&1
}
status=0
if [ ${#first[@]} -gt 0 ]; then run_pass FreshPermission "${first[@]}" || status=$?; fi
if [ ${#first[@]} -gt 0 ] && [ ${#rest[@]} -gt 0 ]; then
  step "install the app new again (the permission \"not determined\")"
  install_new || exit 1
fi
if [ ${#rest[@]} -gt 0 ]; then run_pass AutomatedChecks "${rest[@]}" || status=$?; fi
grep -E "Test Case .* (passed|failed)|error: " "$OUT/xcodebuild.log" | sed -E 's/^.*Test Case .-\[HarnessUITests\.AutomatedChecks (test[^]]*)\]. (passed|failed).*\(([0-9.]+) seconds\).*/\2  \1 (\3 s)/'
step "done (the log and the result bundles are in $OUT)"

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

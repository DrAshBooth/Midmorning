#!/bin/bash
# Runs one skeleton check on a booted simulator with a seeded store.
# Usage: tools/skeleton-checks/run.sh <test> <store: today|long|none> [VAR=value ...]
# Build first: see README.md in this folder.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
UDID=${UDID:-$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)}
TEST=$1; STORE=$2; shift 2
OUT=${OUT:-$HERE/out}; mkdir -p "$OUT"
xcrun simctl terminate "$UDID" uk.midmorning.app 2>/dev/null
DATA=$(xcrun simctl get_app_container "$UDID" uk.midmorning.app data)
REC="$DATA/Library/Application Support/Record"
rm -rf "$REC"; mkdir -p "$REC"
if [ "$STORE" != none ]; then cp "$HERE"/stores/$STORE/Record.store* "$REC/"; fi
env TEST_RUNNER_OUT_DIR="$OUT" "$@" xcodebuild test-without-building -project "$HERE/Harness.xcodeproj" -scheme HarnessUITests \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/.dd" \
  -only-testing:HarnessUITests/SkeletonChecks/$TEST 2>&1 | grep -E 'EVIDENCE|error:|Test Case .* (passed|failed)' | sed 's/^.*EVIDENCE: /EVIDENCE: /'

#!/usr/bin/env bash
#
# Build, install, and launch MyWorkout on a connected physical iPhone.
#
# Usage:
#   Scripts/deploy-to-device.sh                 # auto-detect the connected device
#   Scripts/deploy-to-device.sh <device-udid>    # target a specific device
#
# Requires: Xcode command line tools, a device connected via USB or on the
# same network with Developer Mode enabled, and the app's development team
# already configured in the Xcode project (Automatic signing).
#
# First run on a fresh device pairing will fail to launch with a
# "profile has not been explicitly trusted" error. That's expected — trust
# the certificate once on the device (Settings > General > VPN & Device
# Management > select the developer profile > Trust), then re-run this
# script.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

PROJECT="MyWorkout.xcodeproj"
SCHEME="MyWorkout"
CONFIGURATION="Debug"
BUNDLE_ID="com.nicolaenastas.myworkout"

log() { echo "==> $*"; }
fail() { echo "ERROR: $*" >&2; exit 1; }

# --- 1. Resolve the target device -------------------------------------

UDID="${1:-}"

if [ -z "$UDID" ]; then
    log "No device UDID given — auto-detecting a connected iPhone/iPad..."
    # xctrace lists "Name (OS version) (UDID)" under "== Devices ==" for
    # anything currently reachable (USB or network), one per line.
    DEVICE_CANDIDATES=$(xcrun xctrace list devices 2>&1 \
        | sed -n '/== Devices ==/,/== Devices Offline ==/p' \
        | grep -Ev "== Devices|Offline|Mac$|Mac \(" \
        | grep -E "iPhone|iPad" || true)

    [ -n "$DEVICE_CANDIDATES" ] || fail "No connected iPhone/iPad found. Plug in or connect over Wi-Fi, unlock it, and trust this Mac."

    DEVICE_CANDIDATE_COUNT=$(echo "$DEVICE_CANDIDATES" | grep -c .)
    if [ "$DEVICE_CANDIDATE_COUNT" -gt 1 ]; then
        fail "Multiple connected iPhone/iPad devices found — re-run with a specific UDID (second arg) to pick one:
$DEVICE_CANDIDATES"
    fi

    UDID=$(echo "$DEVICE_CANDIDATES" | grep -oE '\(([0-9A-Fa-f-]{25,})\)' | tail -1 | tr -d '()')
    DEVICE_NAME=$(echo "$DEVICE_CANDIDATES" | sed -E 's/ \([^)]*\)( \([^)]*\))?$//')

    [ -n "$UDID" ] || fail "Found a device line but couldn't parse its UDID: $DEVICE_CANDIDATES"
    log "Found: $DEVICE_NAME ($UDID)"
fi

# devicectl uses a separate "CoreDevice identifier", not the classic UDID
# xctrace/xcodebuild use, and there's no reliable field to join the two
# listings on (name/hostname formatting differs and isn't UDID-based for
# an iPhone). Assume a single reachable iPhone/iPad: its State column
# reads "connected", a launchd-transport-qualified variant of that, or
# "available (paired)" depending on how it's reached, so match anything
# except an explicit "unavailable" rather than the literal word
# "connected" (which several genuinely-reachable states don't contain).
# Pull the Identifier out by UUID shape rather than column position — the
# Name/Model columns are variable-width and shift awk's field numbering
# around. Fail rather than silently pick one if more than one reachable
# device is present, since there's no reliable way to confirm devicectl's
# pick is the same physical device xctrace selected above.
DEVICECTL_CANDIDATES=$(xcrun devicectl list devices 2>&1 \
    | grep -E "iPhone|iPad" \
    | grep -vi "unavailable" || true)

[ -n "$DEVICECTL_CANDIDATES" ] || fail "No reachable device found via devicectl. Is it unlocked and connected?"

DEVICECTL_CANDIDATE_COUNT=$(echo "$DEVICECTL_CANDIDATES" | grep -c .)
if [ "$DEVICECTL_CANDIDATE_COUNT" -gt 1 ]; then
    fail "Multiple reachable iPhone/iPad devices found via devicectl — disconnect all but one and re-run, since devicectl and xctrace listings can't be reliably matched to the same physical device:
$DEVICECTL_CANDIDATES"
fi

DEVICECTL_ID=$(echo "$DEVICECTL_CANDIDATES" | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}' | head -1)

[ -n "$DEVICECTL_ID" ] || fail "Found a device via devicectl but couldn't parse its identifier: $DEVICECTL_CANDIDATES"

# --- 2. Build for the device --------------------------------------------

log "Building $SCHEME for device $UDID (this can take a minute)..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
    -destination "id=$UDID" -configuration "$CONFIGURATION" build \
    | tail -20

# --- 3. Locate the built .app -------------------------------------------

BUILD_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
    -destination "id=$UDID" -configuration "$CONFIGURATION" \
    -showBuildSettings 2>/dev/null \
    | awk -F'= ' '/ TARGET_BUILD_DIR =/{print $2; exit}')
APP_PATH="$BUILD_DIR/$SCHEME.app"

[ -d "$APP_PATH" ] || fail "Expected app bundle not found at $APP_PATH"

# --- 4. Install -----------------------------------------------------------

log "Installing to device..."
xcrun devicectl device install app --device "$DEVICECTL_ID" "$APP_PATH"

# --- 5. Launch --------------------------------------------------------

log "Launching $BUNDLE_ID..."
if ! LAUNCH_OUTPUT=$(xcrun devicectl device process launch --device "$DEVICECTL_ID" "$BUNDLE_ID" 2>&1); then
    if echo "$LAUNCH_OUTPUT" | grep -q "not been explicitly trusted"; then
        echo "$LAUNCH_OUTPUT" >&2
        fail "App installed but not trusted yet. On the device: Settings > General > VPN & Device Management > select the developer profile > Trust. Then re-run this script."
    fi
    echo "$LAUNCH_OUTPUT" >&2
    fail "Launch failed."
fi
echo "$LAUNCH_OUTPUT"

# --- 6. Verify it's actually running, not crashed on launch ------------

sleep 1
if xcrun devicectl device info processes --device "$DEVICECTL_ID" 2>/dev/null | grep -qi "$SCHEME"; then
    log "Running on device."
else
    fail "Launch reported success but no matching process was found — it may have crashed immediately."
fi

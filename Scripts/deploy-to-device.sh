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
    DEVICE_LINE=$(xcrun xctrace list devices 2>&1 \
        | sed -n '/== Devices ==/,/== Devices Offline ==/p' \
        | grep -Ev "== Devices|Offline|Mac$|Mac \(" \
        | grep -E "iPhone|iPad" \
        | head -1)

    [ -n "$DEVICE_LINE" ] || fail "No connected iPhone/iPad found. Plug in or connect over Wi-Fi, unlock it, and trust this Mac."

    UDID=$(echo "$DEVICE_LINE" | grep -oE '\(([0-9A-Fa-f-]{25,})\)' | tail -1 | tr -d '()')
    DEVICE_NAME=$(echo "$DEVICE_LINE" | sed -E 's/ \([^)]*\)( \([^)]*\))?$//')

    [ -n "$UDID" ] || fail "Found a device line but couldn't parse its UDID: $DEVICE_LINE"
    log "Found: $DEVICE_NAME ($UDID)"
fi

# devicectl uses a separate "CoreDevice identifier", not the classic UDID
# xctrace/xcodebuild use, and there's no reliable field to join the two
# listings on (name/hostname formatting differs and isn't UDID-based for
# an iPhone). Assume a single actively-connected iPhone/iPad, find its row
# by connection state, and pull the Identifier out by UUID shape rather
# than column position — the Name/Model columns are variable-width and
# shift awk's field numbering around.
DEVICECTL_ID=$(xcrun devicectl list devices 2>&1 \
    | grep -E "iPhone|iPad" \
    | grep "connected" \
    | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}' \
    | head -1)

[ -n "$DEVICECTL_ID" ] || fail "No device in 'connected' state found via devicectl. Is it unlocked and connected?"

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

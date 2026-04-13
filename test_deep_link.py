#!/usr/bin/env python3
"""
test_deep_link.py
-----------------
Simulates a Firebase verifyEmail deep link on a connected Android device or
emulator.  Run this while the app is open on the EmailVerificationScreen to
test the full deep-link -> reload -> AuthGate -> MainShell flow WITHOUT
needing to send a real email.

Usage:
    python test_deep_link.py              # warm-start (app already running)
    python test_deep_link.py --cold       # cold-start (kills app first)
"""

import os
import subprocess
import sys
import time

# ── Config ────────────────────────────────────────────────────────────────────

PACKAGE = "com.example.mobile"

DEEP_LINK_URL = (
    "https://founder-notes-6b8cb.firebaseapp.com/__/auth/action"
    "?mode=verifyEmail"
    "&oobCode=TEST_FAKE_CODE"
    "&apiKey=AIzaSyAfNpouu_rv0ISVgF7bocqNBLB3_DOkITs"
    "&lang=en"
)

# ── Locate adb ────────────────────────────────────────────────────────────────

def find_adb() -> str:
    """Return the full path to adb.exe, searching common Windows locations."""
    candidates = [
        # Standard Android Studio install location
        os.path.join(os.environ.get("LOCALAPPDATA", ""), "Android", "Sdk", "platform-tools", "adb.exe"),
        os.path.join(os.environ.get("USERPROFILE", ""), "AppData", "Local", "Android", "Sdk", "platform-tools", "adb.exe"),
        # Flutter SDK bundled adb (rare)
        os.path.join(os.environ.get("FLUTTER_ROOT", ""), "bin", "cache", "artifacts", "adb", "adb.exe"),
        # Common manual installs
        r"C:\Android\platform-tools\adb.exe",
        r"C:\platform-tools\adb.exe",
    ]

    for path in candidates:
        if path and os.path.isfile(path):
            return path

    # Last resort: check PATH
    for directory in os.environ.get("PATH", "").split(os.pathsep):
        full = os.path.join(directory, "adb.exe")
        if os.path.isfile(full):
            return full

    print("\n[ERROR] Could not find adb.exe.")
    print("  Install Android Studio, or add platform-tools to your PATH:")
    print("  https://developer.android.com/tools/releases/platform-tools")
    print("\n  Or run the adb command manually in PowerShell:")
    print(f'\n  & "C:\\Users\\DEll\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe" shell am start \\')
    print(f'    -a android.intent.action.VIEW \\')
    print(f'    -c android.intent.category.BROWSABLE \\')
    print(f'    -d "{DEEP_LINK_URL}" \\')
    print(f'    {PACKAGE}')
    sys.exit(1)

# ── Helpers ───────────────────────────────────────────────────────────────────

def run(adb: str, args: list[str]) -> str:
    cmd = [adb] + args
    print(f"  $ {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0 and result.stderr.strip():
        print(f"[WARN] {result.stderr.strip()}")
    return result.stdout.strip()

# ── Main ──────────────────────────────────────────────────────────────────────

cold_start = "--cold" in sys.argv
adb = find_adb()

print(f"\n{'Cold' if cold_start else 'Warm'}-start deep-link test")
print(f"  adb     : {adb}")
print(f"  Package : {PACKAGE}")
print(f"  URL     : {DEEP_LINK_URL}\n")

# Verify a device is connected
devices = run(adb, ["devices"])
print(f"  Devices :\n    {devices}\n")
if "device" not in devices.replace("List of devices attached", ""):
    print("[ERROR] No device connected. Connect a device or start an emulator.")
    sys.exit(1)

if cold_start:
    print("Stopping app...")
    run(adb, ["shell", "am", "force-stop", PACKAGE])
    time.sleep(1)

print("Firing App Link intent...")
run(adb, [
    "shell", "am", "start",
    "-a", "android.intent.action.VIEW",
    "-c", "android.intent.category.BROWSABLE",
    "-d", DEEP_LINK_URL,
    PACKAGE,
])

print("\n✅  Intent sent! Watch the flutter logs for:")
print("    [DeepLink] Warm-start URI: ...")
print("    [DeepLink] Calling reload() for uid=...")
print("    [DeepLink] After reload -> emailVerified=true")
print("\n  Logcat in a second terminal:")
print(f'  & "{adb}" logcat | findstr DeepLink')

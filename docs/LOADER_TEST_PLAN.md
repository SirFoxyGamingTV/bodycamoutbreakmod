# Loader test deployment proposal

Status: prepared; NOT deployed or executed. User approval required.

Test mode changed by the user on 2026-10-09 to online. Use a private hosted lobby
with the user and consenting testers. No protection bypasses or public matchmaking tests.

Source: https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/v3.0.1
Archive: artifacts/downloads/zDEV-UE4SS_v3.0.1.zip
SHA256: AF777D2AF33FCE4D520DE35A8665E417376BCC530FEC647778012CE6CDF51B2B
The hash records the retrieved archive, not a publisher-signed integrity guarantee.

Staged files: artifacts/loader-review/v3.0.1
Exact hashes/destinations: artifacts/reports/loader-deployment-plan.json
Target: C:\Program Files (x86)\Steam\steamapps\common\Bodycam\Bodycam\Binaries\Win64

Add only these five files:
- dwmapi.dll
- UE4SS.dll
- UE4SS-settings.ini
- Mods/mods.txt
- Mods/BodycamOutbreak/Scripts/main.lua

No destination conflicts found at preparation time. Recheck before deployment;
abort if any destination exists or game fingerprint changes. Existing ReShade
and game executables are outside the write set. Archive example mods are excluded.
Hot reload, GUI console and experimental GUI function caller are disabled.
Our bootstrap is enabled only to print its version and unverified status; it has
no hooks, spawning, timers or property writes. No downloaded binaries executed.

After approval:
1. Ensure Bodycam is closed. Recheck executable fingerprint and staged hashes.
2. Save destination inventory and deployment receipt in the workspace. Abort on
   conflicts; never overwrite existing files under this proposal.
3. Copy exactly the manifest files. Launch through the normal Steam flow; inspect
   a fresh UE4SS.log for loader success and the bootstrap marker. Stop on errors.
4. Only enter the agreed controlled lobby. Collect log evidence and exit normally.
5. Roll back by removing only receipt-listed additions after verifying unchanged
   hashes and resolved paths under the exact target. Archive generated logs first.
   Do not recursively remove an existing Mods directory or touch ReShade.
6. Confirm original executable/ReShade fingerprints and successful normal launch.

This does not approve or implement zombie gameplay. Loader failure is investigated
from logs; protections are never disabled or bypassed to make it work.

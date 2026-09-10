"""Run the exported Mac executable; a headless check does not test Metal graphics."""
import subprocess
import sys

result = subprocess.run(
    [sys.argv[1], "--headless", "--", "--smoke-test"],
    capture_output=True, text=True, timeout=90,
)
output = result.stdout + result.stderr
print(output)
if result.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output:
    raise SystemExit("Exported Mac app failed its launch check")
if "MIAMI_SMOKE_TEST_OK" not in output:
    raise SystemExit("Exported Mac app did not finish its smoke test")
print("Exported Mac app launched and passed its headless scene checks")

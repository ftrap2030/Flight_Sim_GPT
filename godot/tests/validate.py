"""Run Godot checks and fail on script errors even if the engine exits zero."""
import argparse
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    commands = [
        [args.godot, "--headless", "--editor", "--path", str(project), "--import"],
        [args.godot, "--headless", "--path", str(project), "--", "--smoke-test"],
    ]
    for index, command in enumerate(commands):
        result = subprocess.run(command, capture_output=True, text=True, timeout=90)
        output = result.stdout + result.stderr
        print(output)
        if result.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output:
            raise SystemExit("Godot validation failed")
        if index == 1 and "MIAMI_SMOKE_TEST_OK" not in output:
            raise SystemExit("Godot smoke test did not finish")
    print("Graphics prototype validation passed")


if __name__ == "__main__":
    main()

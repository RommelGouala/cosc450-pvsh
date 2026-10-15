"""Entry point: python main.py [--data-dir DIR]"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from registration.cli import run
from registration.exceptions import DataFormatError
from registration.storage import load_system


def main() -> int:
    parser = argparse.ArgumentParser(description="Course Registration System (Python)")
    parser.add_argument("--data-dir", default="data", type=Path,
                        help="folder containing courses.csv, students.csv, enrollments.csv")
    args = parser.parse_args()

    try:
        system, warnings = load_system(args.data_dir)
    except FileNotFoundError as err:
        print(f"Could not open data file: {err.filename}", file=sys.stderr)
        return 1
    except DataFormatError as err:
        print(f"Bad data file: {err}", file=sys.stderr)
        return 1

    print(f"Loaded {len(system.courses)} courses and {len(system.students)} students.")
    for warning in warnings:
        print(f"Warning: {warning}")

    try:
        run(system, args.data_dir / "enrollments.csv")
    except KeyboardInterrupt:  # Ctrl+C exits cleanly instead of a traceback
        print("\nInterrupted. Unsaved changes were discarded.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

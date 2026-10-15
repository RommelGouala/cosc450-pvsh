"""Feature 1 (data ingestion) and saving: CSV file I/O.

File formats. Each file starts with a header row and columns are read by
name. (The Haskell version uses the same columns in the same order, but
without the header row.)
  courses.csv      course_id,title,capacity,prerequisites
  students.csv     student_id,name,completed_courses
  enrollments.csv  student_id,course_id
List fields (prerequisites, completed_courses) are separated by ';'
and may be empty.
"""
from __future__ import annotations

import csv
import os
from pathlib import Path

from .exceptions import DataFormatError, RegistrationError
from .models import Course, Student
from .system import RegistrationSystem, normalize_id

COURSE_COLUMNS = ["course_id", "title", "capacity", "prerequisites"]
STUDENT_COLUMNS = ["student_id", "name", "completed_courses"]
ENROLLMENT_COLUMNS = ["student_id", "course_id"]


def _split_ids(raw: str | None) -> frozenset[str]:
    """'cosc240; COSC241' -> frozenset({'COSC240', 'COSC241'}) (set comprehension)."""
    if not raw:
        return frozenset()
    return frozenset(normalize_id(part) for part in raw.split(";") if part.strip())


def _read_rows(file, required: list[str], path: Path):
    """Generator: checks the header, then yields (line_number, row_dict) for
    each non-blank row. Each row is a dict keyed by column name."""
    reader = csv.DictReader(file)
    missing = [name for name in required if name not in (reader.fieldnames or [])]
    if missing:
        raise DataFormatError(f"{path.name}: missing column(s): {', '.join(missing)}")
    for line_no, row in enumerate(reader, start=2):  # line 1 is the header
        if all(not (value or "").strip() for value in row.values()):
            continue  # skip blank lines
        if None in row.values() or None in row:
            raise DataFormatError(
                f"{path.name}, line {line_no}: expected {len(required)} columns")
        yield line_no, row


def load_courses(path: Path, system: RegistrationSystem) -> None:
    # `with` (a context manager) guarantees the file is closed, even on errors.
    # utf-8-sig quietly drops a byte-order mark if Excel added one.
    with open(path, newline="", encoding="utf-8-sig") as file:
        for line_no, row in _read_rows(file, COURSE_COLUMNS, path):
            try:
                course = Course(
                    course_id=normalize_id(row["course_id"]),
                    title=row["title"].strip(),
                    capacity=int(row["capacity"]),
                    prerequisites=_split_ids(row["prerequisites"]),
                )
                system.add_course(course)
            # ValueError: bad number or failed validation in Course.__post_init__
            except (ValueError, RegistrationError) as err:
                raise DataFormatError(f"{path.name}, line {line_no}: {err}") from err


def load_students(path: Path, system: RegistrationSystem) -> None:
    with open(path, newline="", encoding="utf-8-sig") as file:
        for line_no, row in _read_rows(file, STUDENT_COLUMNS, path):
            try:
                student = Student(
                    student_id=normalize_id(row["student_id"]),
                    name=row["name"].strip(),
                    completed=_split_ids(row["completed_courses"]),
                )
                system.add_student(student)
            except (ValueError, RegistrationError) as err:
                raise DataFormatError(f"{path.name}, line {line_no}: {err}") from err


def load_enrollments(path: Path, system: RegistrationSystem) -> list[str]:
    """Replay saved enrollments through register(), so every rule is re-checked.

    A bad row does not stop the program; it is skipped and reported as a warning.
    """
    warnings: list[str] = []
    if not path.exists():
        return warnings  # first run: nothing saved yet
    with open(path, newline="", encoding="utf-8-sig") as file:
        for line_no, row in _read_rows(file, ENROLLMENT_COLUMNS, path):
            try:
                system.register(row["student_id"], row["course_id"])
            except RegistrationError as err:
                warnings.append(f"{path.name}, line {line_no} skipped: {err}")
    return warnings


def save_enrollments(path: Path, system: RegistrationSystem) -> int:
    """Write current enrollments. Writes to a temp file first, then swaps it in,
    so a crash mid-save cannot corrupt the existing file."""
    pairs = system.enrollment_pairs()
    temp_path = path.with_suffix(".tmp")
    with open(temp_path, "w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file, lineterminator="\n")  # Unix line endings
        writer.writerow(ENROLLMENT_COLUMNS)
        writer.writerows(pairs)
    os.replace(temp_path, path)
    return len(pairs)


def load_system(data_dir: Path) -> tuple[RegistrationSystem, list[str]]:
    """Build a RegistrationSystem from the three CSV files in data_dir."""
    system = RegistrationSystem()
    load_courses(data_dir / "courses.csv", system)
    load_students(data_dir / "students.csv", system)
    warnings = load_enrollments(data_dir / "enrollments.csv", system)
    return system, warnings

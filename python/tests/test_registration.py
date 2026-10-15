"""Test cases for the report's Testing section. Run: python -m unittest -v

Uses only the standard-library unittest module (no installs needed).
"""
import shutil
import tempfile
import unittest
from pathlib import Path

from registration.exceptions import (
    AlreadyCompletedError, AlreadyEnrolledError, CourseFullError,
    CourseNotFoundError, DataFormatError, NotEnrolledError,
    PrerequisiteError, StudentNotFoundError,
)
from registration.formatting import format_catalog
from registration.models import Course, Student
from registration.storage import load_system, save_enrollments
from registration.system import RegistrationSystem

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
DEMO_DATA = DATA_DIR / "demo"


def small_system() -> RegistrationSystem:
    """A tiny in-memory system so every test starts from the same known state."""
    system = RegistrationSystem()
    system.add_course(Course("CS101", "Intro to CS", 2))
    system.add_course(Course("CS201", "Data Structures", 10, frozenset({"CS101"})))
    system.add_course(Course("CS999", "Closed Seminar", 0))
    system.add_student(Student("S1", "Ana Ruiz"))
    system.add_student(Student("S2", "Ben Ode"))
    system.add_student(Student("S3", "Cy Tran", frozenset({"CS101"})))
    return system


class T1NormalInput(unittest.TestCase):
    def test_register_valid_student(self):
        system = small_system()
        system.register("S1", "CS101")
        self.assertEqual([c.course_id for c in system.schedule("S1")], ["CS101"])
        self.assertEqual([s.student_id for s in system.roster("CS101")], ["S1"])
        self.assertEqual(system.get_course("CS101").open_seats, 1)


class T2BoundaryCase(unittest.TestCase):
    def test_last_seat_then_full(self):
        system = small_system()
        system.register("S1", "CS101")
        system.register("S2", "CS101")          # takes the last seat
        self.assertEqual(system.get_course("CS101").open_seats, 0)
        with self.assertRaises(CourseFullError):
            system.register("S3", "CS999")      # capacity 0 course
        system.drop("S1", "CS101")              # frees one seat...
        system.add_student(Student("S4", "Dee Park"))
        system.register("S4", "CS101")          # ...which can now be taken
        self.assertEqual(system.get_course("CS101").open_seats, 0)

    def test_full_course_rejects_next_student(self):
        system = small_system()
        system.register("S1", "CS101")
        system.register("S2", "CS101")
        system.add_student(Student("S4", "Dee Park"))
        with self.assertRaises(CourseFullError):
            system.register("S4", "CS101")


class T3InvalidInput(unittest.TestCase):
    def test_unknown_ids(self):
        system = small_system()
        with self.assertRaises(StudentNotFoundError):
            system.register("S404", "CS101")
        with self.assertRaises(CourseNotFoundError):
            system.register("S1", "XYZ123")

    def test_duplicate_and_bad_drop(self):
        system = small_system()
        system.register("S1", "CS101")
        with self.assertRaises(AlreadyEnrolledError):
            system.register("S1", "CS101")
        with self.assertRaises(NotEnrolledError):
            system.drop("S2", "CS101")
        with self.assertRaises(AlreadyCompletedError):
            system.register("S3", "CS101")      # S3 already passed CS101

    def test_ids_are_case_insensitive(self):
        system = small_system()
        system.register("  s1 ", "cs101")
        self.assertIn("S1", system.get_course("CS101").enrolled)

    def test_malformed_csv_reports_line_number(self):
        temp_dir = Path(tempfile.mkdtemp())
        try:
            shutil.copy(DEMO_DATA / "students.csv", temp_dir / "students.csv")
            (temp_dir / "courses.csv").write_text(
                "course_id,title,capacity,prerequisites\n"
                "10240,Intro,30,\n"
                "10241,Next,thirty,\n", encoding="utf-8")    # capacity is not a number
            with self.assertRaises(DataFormatError) as ctx:
                load_system(temp_dir)
            self.assertIn("line 3", str(ctx.exception))
        finally:
            shutil.rmtree(temp_dir)

    def test_wrong_column_count(self):
        temp_dir = Path(tempfile.mkdtemp())
        try:
            shutil.copy(DEMO_DATA / "students.csv", temp_dir / "students.csv")
            (temp_dir / "courses.csv").write_text(
                "course_id,title,capacity,prerequisites\n"
                "10240,Intro,30\n", encoding="utf-8")       # row is missing a column
            with self.assertRaises(DataFormatError) as ctx:
                load_system(temp_dir)
            self.assertIn("expected 4 columns", str(ctx.exception))
        finally:
            shutil.rmtree(temp_dir)

    def test_missing_header_column(self):
        temp_dir = Path(tempfile.mkdtemp())
        try:
            shutil.copy(DEMO_DATA / "students.csv", temp_dir / "students.csv")
            (temp_dir / "courses.csv").write_text(
                "course_id,title,prerequisites\n"           # no capacity column
                "10240,Intro,\n", encoding="utf-8")
            with self.assertRaises(DataFormatError) as ctx:
                load_system(temp_dir)
            self.assertIn("capacity", str(ctx.exception))
        finally:
            shutil.rmtree(temp_dir)


class T4ComplexCase(unittest.TestCase):
    def test_multi_student_workflow_with_save_and_reload(self):
        """Load sample data, make several changes, save, reload, compare."""
        temp_dir = Path(tempfile.mkdtemp())
        try:
            for name in ("courses.csv", "students.csv", "enrollments.csv"):
                shutil.copy(DEMO_DATA / name, temp_dir / name)
            system, warnings = load_system(temp_dir)
            self.assertEqual(warnings, [])

            system.register("1006", "10430")       # fills 10430 (3/3)
            with self.assertRaises(CourseFullError):
                system.register("1007", "10430")
            system.drop("1005", "10430")           # frees a seat
            system.register("1007", "10430")       # now succeeds
            system.register("1007", "10460")
            before = system.enrollment_pairs()

            save_enrollments(temp_dir / "enrollments.csv", system)
            reloaded, warnings = load_system(temp_dir)
            self.assertEqual(warnings, [])
            self.assertEqual(reloaded.enrollment_pairs(), before)
            self.assertEqual(len(reloaded.schedule("1007")), 2)
            self.assertEqual(reloaded.get_course("10430").open_seats, 0)
        finally:
            shutil.rmtree(temp_dir)


class T5FeatureSpecific(unittest.TestCase):
    def test_prerequisite_enforcement(self):
        system = small_system()
        with self.assertRaises(PrerequisiteError) as ctx:
            system.register("S1", "CS201")          # S1 has not taken CS101
        self.assertIn("CS101", str(ctx.exception))
        system.register("S3", "CS201")              # S3 has completed CS101
        self.assertIn("CS201", system.get_student("S3").enrolled)

    def test_failed_register_changes_nothing(self):
        system = small_system()
        with self.assertRaises(PrerequisiteError):
            system.register("S1", "CS201")
        self.assertEqual(system.get_student("S1").enrolled, set())
        self.assertEqual(system.get_course("CS201").enrolled, set())

    def test_search_and_catalog_display(self):
        system = small_system()
        self.assertEqual([c.course_id for c in system.search_courses("data")], ["CS201"])
        self.assertIn("FULL", format_catalog(system.catalog()))   # CS999 has 0 seats


class SharedDatasetLoads(unittest.TestCase):
    def test_full_shared_dataset(self):
        """The 500-course / 500-student files shared with the Haskell version load cleanly."""
        system, warnings = load_system(DATA_DIR)
        self.assertEqual(len(system.courses), 500)
        self.assertEqual(len(system.students), 500)
        self.assertEqual(warnings, [])


if __name__ == "__main__":
    unittest.main()

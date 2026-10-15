"""RegistrationSystem: owns all courses and students and enforces the rules."""
from __future__ import annotations

from typing import Callable, Iterator

from .exceptions import (
    AlreadyCompletedError,
    AlreadyEnrolledError,
    CourseFullError,
    CourseNotFoundError,
    NotEnrolledError,
    PrerequisiteError,
    RegistrationError,
    StudentNotFoundError,
)
from .models import Course, Student


def normalize_id(raw_id: str) -> str:
    """IDs are case-insensitive and ignore surrounding spaces: ' cosc350 ' -> 'COSC350'."""
    return raw_id.strip().upper()


class RegistrationSystem:
    """Central object that stores the catalog and student records.

    Courses and students are kept in dictionaries keyed by ID, giving
    O(1) lookups instead of scanning a list.
    """

    def __init__(self) -> None:
        self.courses: dict[str, Course] = {}
        self.students: dict[str, Student] = {}

    # ---------- building the system ----------

    def add_course(self, course: Course) -> None:
        if course.course_id in self.courses:
            raise RegistrationError(f"Duplicate course ID '{course.course_id}'.")
        self.courses[course.course_id] = course

    def add_student(self, student: Student) -> None:
        if student.student_id in self.students:
            raise RegistrationError(f"Duplicate student ID '{student.student_id}'.")
        self.students[student.student_id] = student

    # ---------- lookups ----------

    def get_course(self, course_id: str) -> Course:
        key = normalize_id(course_id)
        try:
            return self.courses[key]
        except KeyError:
            # Translate the low-level KeyError into a domain error.
            raise CourseNotFoundError(key) from None

    def get_student(self, student_id: str) -> Student:
        key = normalize_id(student_id)
        try:
            return self.students[key]
        except KeyError:
            raise StudentNotFoundError(key) from None

    # ---------- Feature 3: add / drop ----------

    def register(self, student_id: str, course_id: str) -> None:
        """Enroll a student, checking every rule before changing anything.

        Rule order: student exists -> course exists -> not already enrolled
        -> not already completed -> prerequisites met -> seat available.
        """
        student = self.get_student(student_id)
        course = self.get_course(course_id)

        if course.course_id in student.enrolled:
            raise AlreadyEnrolledError(student.student_id, course.course_id)
        if course.course_id in student.completed:
            raise AlreadyCompletedError(student.student_id, course.course_id)
        missing = student.missing_prerequisites(course)
        if missing:
            raise PrerequisiteError(student.student_id, course.course_id, missing)
        if course.is_full:
            raise CourseFullError(course.course_id, course.capacity)

        # All checks passed: mutate BOTH objects so they stay consistent.
        course.enrolled.add(student.student_id)
        student.enrolled.add(course.course_id)

    def drop(self, student_id: str, course_id: str) -> None:
        student = self.get_student(student_id)
        course = self.get_course(course_id)
        if course.course_id not in student.enrolled:
            raise NotEnrolledError(student.student_id, course.course_id)
        course.enrolled.discard(student.student_id)
        student.enrolled.discard(course.course_id)

    # ---------- Feature 2: catalog ----------

    def catalog(self, key: Callable[[Course], object] = lambda c: c.course_id) -> list[Course]:
        """Return all courses sorted by a caller-supplied key function (higher-order)."""
        return sorted(self.courses.values(), key=key)

    def search_courses(self, keyword: str) -> Iterator[Course]:
        """Generator: lazily yields courses whose ID or title contains the keyword."""
        needle = keyword.strip().lower()
        for course in self.catalog():
            if needle in course.course_id.lower() or needle in course.title.lower():
                yield course

    # ---------- Feature 4: student schedule ----------

    def schedule(self, student_id: str) -> list[Course]:
        student = self.get_student(student_id)
        return sorted((self.courses[cid] for cid in student.enrolled), key=lambda c: c.course_id)

    # ---------- Feature 5: course roster ----------

    def roster(self, course_id: str) -> list[Student]:
        course = self.get_course(course_id)
        return sorted((self.students[sid] for sid in course.enrolled), key=lambda s: s.name)

    # ---------- used by save ----------

    def enrollment_pairs(self) -> list[tuple[str, str]]:
        """Every (student_id, course_id) pair, sorted, via a nested comprehension."""
        return sorted(
            (student.student_id, cid)
            for student in self.students.values()
            for cid in student.enrolled
        )

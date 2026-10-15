"""Pure formatting helpers: they build strings and never print.

Keeping output-building separate from input/output makes these functions
easy to unit test.
"""
from __future__ import annotations

from .models import Course, Student

CATALOG_HEADER = f"{'ID':<8}{'Title':<36}{'Cap':>5}{'Open':>6}  Prerequisites"


def format_course_row(course: Course) -> str:
    prereqs = ", ".join(sorted(course.prerequisites)) or "-"
    status = "FULL" if course.is_full else str(course.open_seats)
    return (f"{course.course_id:<8}{course.title[:35]:<36}"
            f"{course.capacity:>5}{status:>6}  {prereqs}")


def format_catalog(courses: list[Course]) -> str:
    if not courses:
        return "No courses found."
    lines = [CATALOG_HEADER, "-" * len(CATALOG_HEADER)]
    lines += [format_course_row(course) for course in courses]  # list comprehension
    return "\n".join(lines)


def format_schedule(student: Student, courses: list[Course]) -> str:
    title = f"Schedule for {student.name} ({student.student_id})"
    if not courses:
        return f"{title}\n  (not enrolled in any courses)"
    lines = [title] + [f"  {c.course_id:<8}{c.title}" for c in courses]
    lines.append(f"  Courses enrolled: {len(courses)}")
    return "\n".join(lines)


def format_roster(course: Course, students: list[Student]) -> str:
    title = (f"Roster for {course.course_id} - {course.title} "
             f"({len(students)}/{course.capacity} seats filled)")
    if not students:
        return f"{title}\n  (no students enrolled)"
    lines = [title] + [f"  {s.student_id:<8}{s.name}" for s in students]
    return "\n".join(lines)

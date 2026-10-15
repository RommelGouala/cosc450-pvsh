"""Domain classes: Course and Student.

Both are *mutable* objects. Registering or dropping a course changes the
`enrolled` sets inside these objects in place, which is the core
object-oriented design choice we are comparing against Haskell's immutable
records.
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Course:
    """A course offering with a fixed seat capacity."""

    course_id: str
    title: str
    capacity: int
    prerequisites: frozenset[str] = field(default_factory=frozenset)
    # IDs of students currently enrolled (mutated by RegistrationSystem)
    enrolled: set[str] = field(default_factory=set)

    def __post_init__(self) -> None:
        # Dataclasses generate __init__ for us; this hook adds validation.
        if not self.course_id:
            raise ValueError("course_id cannot be empty")
        if self.capacity < 0:
            raise ValueError(f"capacity cannot be negative (got {self.capacity})")

    @property
    def open_seats(self) -> int:
        """Computed on every access, so it can never get out of sync."""
        return self.capacity - len(self.enrolled)

    @property
    def is_full(self) -> bool:
        return self.open_seats <= 0


@dataclass
class Student:
    """A student with a record of completed courses."""

    student_id: str
    name: str
    completed: frozenset[str] = field(default_factory=frozenset)
    # IDs of courses currently enrolled in (mutated by RegistrationSystem)
    enrolled: set[str] = field(default_factory=set)

    def __post_init__(self) -> None:
        if not self.student_id:
            raise ValueError("student_id cannot be empty")
        if not self.name:
            raise ValueError("name cannot be empty")

    def missing_prerequisites(self, course: Course) -> set[str]:
        """Set difference: prerequisites this student has not completed."""
        return set(course.prerequisites - self.completed)

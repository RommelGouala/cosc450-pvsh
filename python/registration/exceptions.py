"""Custom exception hierarchy for the registration system.

Every rule violation raises a subclass of RegistrationError. The menu loop
catches the base class once, so a new rule only needs a new subclass; the
caller code does not change. (Compare with Haskell, where each failure is a
value of an error type returned inside Either.)
"""


class RegistrationError(Exception):
    """Base class for every expected registration failure."""


class StudentNotFoundError(RegistrationError):
    def __init__(self, student_id: str):
        super().__init__(f"No student with ID '{student_id}'.")


class CourseNotFoundError(RegistrationError):
    def __init__(self, course_id: str):
        super().__init__(f"No course with ID '{course_id}'.")


class CourseFullError(RegistrationError):
    def __init__(self, course_id: str, capacity: int):
        super().__init__(f"{course_id} is full ({capacity}/{capacity} seats taken).")


class AlreadyEnrolledError(RegistrationError):
    def __init__(self, student_id: str, course_id: str):
        super().__init__(f"Student {student_id} is already enrolled in {course_id}.")


class NotEnrolledError(RegistrationError):
    def __init__(self, student_id: str, course_id: str):
        super().__init__(f"Student {student_id} is not enrolled in {course_id}.")


class AlreadyCompletedError(RegistrationError):
    def __init__(self, student_id: str, course_id: str):
        super().__init__(f"Student {student_id} has already completed {course_id}.")


class PrerequisiteError(RegistrationError):
    def __init__(self, student_id: str, course_id: str, missing: set[str]):
        needed = ", ".join(sorted(missing))
        super().__init__(f"Student {student_id} cannot take {course_id}; missing prerequisite(s): {needed}.")


class DataFormatError(RegistrationError):
    """Raised when an input data file is malformed."""

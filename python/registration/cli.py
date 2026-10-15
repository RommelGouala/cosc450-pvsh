"""Interactive console menu (the only module that talks to the user)."""
from __future__ import annotations

from pathlib import Path

from .exceptions import RegistrationError
from .formatting import format_catalog, format_roster, format_schedule
from .storage import save_enrollments
from .system import RegistrationSystem, normalize_id

MENU = """
===== Course Registration System =====
 1) View course catalog
 2) Search courses
 3) Register a student for a course
 4) Drop a course
 5) View a student's schedule
 6) View a course roster
 7) Save enrollments
 8) Exit
"""


def ask(prompt: str) -> str:
    """Read one line of input; reject blank answers."""
    answer = input(prompt).strip()
    if not answer:
        raise RegistrationError("Input cannot be blank.")
    return answer


def run(system: RegistrationSystem, enrollments_path: Path) -> None:
    unsaved_changes = False

    while True:
        print(MENU)
        try:
            choice = input("Choose an option (1-8): ").strip()
        except EOFError:  # input stream closed (e.g. piped input ran out)
            choice = "8"

        try:
            # Structural pattern matching (Python 3.10+) dispatches the menu.
            match choice:
                case "1":
                    print(format_catalog(system.catalog()))
                case "2":
                    keyword = ask("Keyword (ID or title): ")
                    print(format_catalog(list(system.search_courses(keyword))))
                case "3":
                    student_id = ask("Student ID: ")
                    course_id = ask("Course ID: ")
                    system.register(student_id, course_id)
                    unsaved_changes = True
                    print(f"Registered {normalize_id(student_id)} in {normalize_id(course_id)}.")
                case "4":
                    student_id = ask("Student ID: ")
                    course_id = ask("Course ID: ")
                    system.drop(student_id, course_id)
                    unsaved_changes = True
                    print(f"Dropped {normalize_id(course_id)} for {normalize_id(student_id)}.")
                case "5":
                    student = system.get_student(ask("Student ID: "))
                    print(format_schedule(student, system.schedule(student.student_id)))
                case "6":
                    course = system.get_course(ask("Course ID: "))
                    print(format_roster(course, system.roster(course.course_id)))
                case "7":
                    count = save_enrollments(enrollments_path, system)
                    unsaved_changes = False
                    print(f"Saved {count} enrollment(s) to {enrollments_path}.")
                case "8" | "q" | "quit":
                    if unsaved_changes:
                        print("Note: you have unsaved changes (option 7 saves them).")
                        if input("Exit anyway? (y/n): ").strip().lower() != "y":
                            continue
                    print("Goodbye.")
                    return
                case _:
                    print(f"'{choice}' is not a valid option. Enter a number from 1 to 8.")
        except RegistrationError as err:
            # One handler covers every rule violation (full, prerequisites, not found...).
            print(f"Error: {err}")
        except EOFError:
            print("\nInput ended.")
            return
        except OSError as err:
            print(f"File error: {err}")

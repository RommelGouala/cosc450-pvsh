# Course Registration System — Python Implementation

**Project:** Functional vs. Object-Oriented Design in a Course Registration System
**Group 6:** Devesh Parekh and Rommel Gouala
**Stage:** First-language implementation (Python)
**Language:** Python 3 (object-oriented / imperative style)

## Requirements

- **Interpreter:** CPython **3.10 or newer** (uses `match`/`case`). Developed and tested on Python 3.12.3.
- **Dependencies:** none. Only the standard library is used: `csv`, `dataclasses`, `argparse`, `pathlib`, `os`, `typing`, `tempfile`, `shutil`, `unittest`.

Check your version with `python3 --version` (on Windows: `python --version` or `py --version`).

## How to run

From the repository root:

```bash
python3 main.py                      # full shared dataset (500 courses, 500 students)
python3 main.py --data-dir data/demo # small demo set with tight seats and prerequisites
```

Run the tests:

```bash
python3 -m unittest -v
```

## Project structure

```
main.py                    entry point: loads data, starts the menu
registration/
  models.py                Course and Student classes (mutable dataclasses)
  system.py                RegistrationSystem: lookups and registration rules
  exceptions.py            custom exception hierarchy
  storage.py               CSV loading and saving
  formatting.py            builds catalog / schedule / roster text
  cli.py                   interactive menu
data/
  courses.csv              shared course catalog (500 sections)
  students.csv             shared student records (500 students)
  enrollments.csv          current enrollments (starts empty; overwritten by Save)
  demo/                    small dataset in the same format for demos and tests
tests/
  test_registration.py     test cases T1–T5
```

## Data file formats

Each file starts with a **header row**, and the Python program reads columns by name. The Haskell implementation uses the same data with the same columns in the same order, but without the header row, so the only difference between the two sets of files is that first line.

| File | Columns |
|---|---|
| `courses.csv` | `course_id,title,capacity,prerequisites` |
| `students.csv` | `student_id,name,completed_courses` |
| `enrollments.csv` | `student_id,course_id` |

List fields (`prerequisites`, `completed_courses`) separate IDs with `;`, for example `10345;10350`, and may be empty. Files use UTF-8 with Unix (LF) line endings. Example rows:

```
course_id,title,capacity,prerequisites
10460,Operating Systems,15,10345;10350
```

## Implemented features

1. **Data ingestion** – loads courses, students, and saved enrollments from CSV. A missing header column, a row with the wrong number of columns, or a non-numeric capacity stop loading with the file name and line number; saved enrollments that break a rule are skipped with a warning.
2. **Course catalog display** – formatted table of every course with capacity, open seats (or `FULL`), and prerequisites. Includes keyword search by ID or title.
3. **Add/drop** – registers a student only if the student and course exist, the student is not already enrolled, has not already completed the course, has every prerequisite, and a seat is open. Dropping frees the seat.
4. **Student schedule** – lists a student's enrolled courses and the course count.
5. **Course roster** – lists enrolled students (sorted by name) and seats filled.
6. **Save** – writes enrollments back to `enrollments.csv`; warns on exit if there are unsaved changes.

## Sample input and output

Using the demo dataset (`python3 main.py --data-dir data/demo`):

```
Choose an option (1-8): 3
Student ID: 1006
Course ID: 10430
Registered 1006 in 10430.

Choose an option (1-8): 3
Student ID: 1007
Course ID: 10430
Error: 10430 is full (3/3 seats taken).

Choose an option (1-8): 3
Student ID: 1002
Course ID: 10350
Error: Student 1002 cannot take 10350; missing prerequisite(s): 10241.

Choose an option (1-8): 6
Course ID: 10430
Roster for 10430 - Programming Languages (3/3 seats filled)
  1003    Carmen Diaz
  1005    Emily Chen
  1006    Farah Ahmed

Choose an option (1-8): 5
Student ID: 1003
Schedule for Carmen Diaz (1003)
  10430   Programming Languages
  10460   Operating Systems
  Courses enrolled: 2
```

## Python language features demonstrated

| Feature | Where |
|---|---|
| Classes with mutable state (`@dataclass`) | `models.py` |
| Computed attributes (`@property`) | `Course.open_seats`, `Course.is_full` |
| Custom exception hierarchy, `try`/`except`, `raise ... from` | `exceptions.py`, `system.py`, `storage.py` |
| Dictionaries for O(1) lookup, sets / frozensets with set difference | `system.py`, `models.py` |
| Generators (`yield`) | `RegistrationSystem.search_courses`, `storage._read_rows` |
| List / set / generator comprehensions | `storage.py`, `formatting.py`, `system.py` |
| Higher-order functions and lambdas | `catalog(key=...)`, `sorted(..., key=lambda ...)` |
| Context managers (`with open(...)`) | `storage.py` |
| Structural pattern matching (`match`/`case`) | `cli.py` |
| Optional type hints (not enforced at runtime) | throughout |

## Known limitations

- No waitlist: a full course simply rejects new registrations.
- The shared dataset has no credit hours, so there is no credit-hour limit; there is also no time-conflict checking.
- In the shared 500-course dataset every section has 30 seats and no prerequisites, so the full-course and prerequisite rules are demonstrated with the `data/demo` set.
- Students and courses can only be added by editing the CSV files, not from the menu.
- Only enrollments are saved; course and student files are read-only.
- Single user; no concurrent access to the data files.

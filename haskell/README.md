# Course Registration System — Haskell Implementation

**Project:** Functional vs. Object-Oriented Design in a Course Registration System  
**Group 6:** Devesh Parekh and Rommel Gouala  
**Stage:** Second-language implementation (Haskell)  
**Language:** Haskell

## Requirements

- **Compiler:** Glasgow Haskell Compiler (GHC). Developed and tested using **GHC 9.10.3**.
- **Build system:** Cabal, used for dependency management, compilation, and testing.
- **Dependencies:**
  - `cassava` — CSV parsing.
  - `bytestring` — reading CSV files.
  - `vector` — processing decoded CSV records.
  - `HUnit` — automated unit testing.
  - `base` — standard Haskell functionality, including list operations and console I/O.

Check your compiler and build tools with:

```bash
ghc --version
cabal --version
```

## How to run

From the Haskell project directory containing the Cabal configuration file:

```bash
cabal build
cabal run
```

The application loads the student and course records from the `data/` directory and displays an interactive menu.

The available menu options are:

```text
1. View Course Catalog
2. Search Courses
3. Register for a Course
4. Drop a Course
5. View Student Schedule
6. View Course Roster
7. Save and Exit
```

To run the automated tests:

```bash
cabal test --test-show-details=direct
```

The implementation was tested using GHC 9.10.3. All six automated tests passed with zero errors and zero failures.

## Project structure

```text
src/
  Type.hs             Student, Course, SystemState, and RegError types
  CoreLogic.hs        registration rules, lookups, and course search
  FileIO.hs           CSV loading, parsing, and saving
  Main.hs             entry point and interactive menu
  unitTest.hs         HUnit automated tests (T1–T6)

data/
  courses.csv         course records and prerequisite information
  students.csv        student records and enrollment information

*.cabal               Cabal package and dependency configuration
```

The program separates pure registration logic from input/output operations. `CoreLogic.hs` handles registration calculations without performing file or terminal I/O, while `FileIO.hs` and `Main.hs` handle external interactions.

## Data file formats

The shared dataset contains 500 students and 500 course sections. All courses initially have a capacity of 30 seats, and the supplied dataset does not include prerequisite or completed-course information. Existing student enrollments are recorded in both student and course records to maintain consistency. The prerequisite and course-capacity validation rules are demonstrated using the in-memory records defined in the HUnit test suite.

| File | Columns |
|---|---|
| `courses.csv` | `course_id,course_name,capacity,enrolled_students,prerequisites` |
| `students.csv` | `student_id,student_name,enrolled_courses,completed_courses` |

Fields containing multiple IDs use semicolons (`;`) as separators. Empty lists are represented by empty fields.

Example course records:

```text
41758,Intro Asian American Studies,30
60147,Commodifying Difference,30
```

Example student records:

```text
1001,Lori Gray,,
1002,Patrick Morgan,,
```

The CSV parser uses `cassava` to read records. Enrollment and prerequisite fields are converted into Haskell lists of integers using custom parsing functions.

When saving, the program writes the current enrollment information back to `students.csv` and `courses.csv`.

## Implemented features

1. **Data ingestion** — Loads course and student records from CSV files using `cassava`. Parses course IDs, student IDs, enrollment lists, prerequisite lists, and completed courses. Individual records that fail parsing are skipped.

2. **Course catalog display** — Displays available courses with their names, maximum capacities, and remaining open seats. Available seats are calculated from course capacity and the number of enrolled students.

3. **Add/drop** — Registers a student only if both IDs exist, the course has available seats, the student is not already enrolled, the student has not previously completed the course, and all prerequisites have been satisfied. Dropping a course removes the enrollment from both the student and course records.

4. **Student schedule** — Retrieves a student's enrolled courses using their student ID and displays the course names.

5. **Course roster** — Retrieves a course's enrolled students using the course ID and displays their names.

6. **Course search** — Searches the course catalog by course name or ID. Keyword matching is case-insensitive.

7. **Save** — Saves the current student and course records to their corresponding CSV files when selecting Save and Exit.

## Sample input and output

The following example illustrates the menu behavior using the sample student and course records shown above.

```text
Welcome to the Course Registration System!

--- Main Menu ---
1. View Course Catalog
2. Search Courses
3. Register for a Course
4. Drop a Course
5. View Student Schedule
6. View Course Roster
7. Save and Exit
Enter your choice: 3

Enter Student ID: 1001
Enter Course ID: 41758

[*] Successfully registered!
```

Attempting to register another student when the course is full:

```text
Enter your choice: 3
Enter Student ID: 1002
Enter Course ID: 41758

[!] Error registering: CourseFull
```

Attempting to register without completing a prerequisite:

```text
Enter your choice: 3
Enter Student ID: 1002
Enter Course ID: 50000

[!] Error registering: MissingPrereq
```

Viewing an enrolled student's schedule:

```text
Enter your choice: 5
Enter Student ID: 1001

--- Schedule ---
Intro Asian American Studies
```

Saving and exiting:

```text
Enter your choice: 7

Saving state to CSV...
Saved successfully. Goodbye!
```

Actual student names, course names, and available seats depend on the CSV dataset being used.

## Haskell language features demonstrated

| Feature | Where |
|---|---|
| Algebraic data types and record syntax | `Type.hs` |
| Immutable data and record updates | `CoreLogic.hs` |
| Pure functions | `CoreLogic.hs` |
| Higher-order functions (`map`, `filter`, `find`, `all`) | `CoreLogic.hs` |
| Pattern matching (`case`, `Just`, `Nothing`, `Left`, `Right`) | `CoreLogic.hs`, `FileIO.hs`, `Main.hs` |
| `Maybe` and `Either` for error handling | `CoreLogic.hs`, `FileIO.hs` |
| Recursion for menu execution | `Main.hs` |
| List comprehensions | `CoreLogic.hs` |
| Lambda expressions | `CoreLogic.hs`, `FileIO.hs` |
| Static typing and type signatures | Throughout |
| `IO` for terminal and file operations | `Main.hs`, `FileIO.hs` |
| Automated testing using HUnit | `unitTest.hs` |

Haskell's functional programming paradigm requires application state to be updated through new values rather than modifying existing records in place.

For example, registration returns a new system state:

```haskell
registerStudent :: Int -> Int -> SystemState -> Either RegError SystemState
```

The `Either` type distinguishes registration errors (`Left`) from successful registration operations (`Right`).

## Testing

Six automated unit tests were implemented using HUnit.

| Test | Description | Result |
|---|---|---|
| T1 | Normal student registration | Pass |
| T2 | Registration when course capacity is zero | Pass |
| T3 | Registration with an invalid student ID | Pass |
| T4 | Registering and then dropping a course restores the original state | Pass |
| T5 | Retrieving a course roster | Pass |
| T6 | Rejecting registration when prerequisites are missing | Pass |

Run the test suite with:

```bash
cabal test --test-show-details=direct
```

**Verified test results:**

```text
Running Course Registration Test Suite...
Cases: 6  Tried: 6  Errors: 0  Failures: 0
Test suite cosc450-tests: PASS
1 of 1 test suites (1 of 1 test cases) passed.
```

These tests verify the main registration operations and selected validation rules. They use in-memory test records rather than testing the entire CSV loading and saving workflow.

## Known limitations

- **No waitlist:** Registrations are rejected when a course reaches maximum capacity.
- **No schedule conflicts:** The system does not check whether courses overlap in meeting times.
- **No credit-hour limits:** Course credit hours are not tracked, so maximum semester credit limits are not enforced.
- **Limited input validation:** Entering nonnumeric student or course IDs in the menu can cause an exception because input conversion uses `read`.
- **CSV validation:** Invalid individual records may be skipped during loading rather than generating detailed error messages.
- **CSV saving:** The program constructs CSV output using comma-separated strings and does not fully handle quoted fields containing commas.
- **Manual record creation:** New students and courses must be added by editing the CSV files rather than through the menu.
- **Single-user application:** The system does not support concurrent users or simultaneous modifications to the CSV files.
- **Saving behavior:** Enrollment changes remain in memory until Save and Exit is selected, which overwrites the existing student and course CSV files.

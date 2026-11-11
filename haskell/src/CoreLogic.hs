module CoreLogic where
import Type
import Data.List (find, isInfixOf)
import Data.Char (toLower)

-- | finds a course by ID
-- uses the find function to search the course list for a matching ID
findCourse :: Int -> [Course] -> Maybe Course
findCourse cid crsList = find (\c -> courseID c == cid) crsList

-- | finds a student by ID
-- uses the find function to search the student list for a matching ID
findStudent :: Int -> [Student] -> Maybe Student
findStudent sid stdList = find (\s -> studentID s == sid) stdList

-- | gets a list of all courses and open seats
-- maps over the course list to extract the name, capacity, and remaining seats
getAvailableCourses :: SystemState -> [(String, Int, Int)]
getAvailableCourses state = 
  map (\c -> (courseName c, capacity c, capacity c - length (studentEnrollment c))) (courses state)

-- | search courses by keyword (case-insensitive)
-- converts keyword to lowercase and checks if it exists in the course name or ID string
searchCourses :: String -> SystemState -> [Course]
searchCourses keyword state =
  let lowerKey = map toLower keyword
      matches c = lowerKey `isInfixOf` map toLower (courseName c) || lowerKey `isInfixOf` show (courseID c)
  in filter matches (courses state)

-- | register a student for a course (now checks prereqs and completed courses)
-- evaluates registration rules sequentially and short-circuits if a rule fails
registerStudent :: Int -> Int -> SystemState -> Either RegError SystemState
registerStudent sid cid state = do
  
  -- attempts to locate student and course, returning an error if not found
  student <- maybeToEither StudentNotFound (findStudent sid (students state))
  course <- maybeToEither CourseNotFound (findCourse cid (courses state))
  
  -- verifies the course has not reached its maximum capacity
  if length (studentEnrollment course) >= capacity course
    then Left CourseFull
  
  -- verifies the student is not already enrolled in this course
  else if cid `elem` enrollment student
    then Left AlreadyEnrolled
  
  -- verifies the student has not already completed this course
  else if cid `elem` completedCourses student
    then Left AlreadyCompleted
  
  -- verifies all prerequisite course IDs exist in the student's completed courses list
  else if not (all (`elem` completedCourses student) (prerequisites course))
    then Left MissingPrereq
  
  -- proceeds to update the system state if all validation checks pass
  else Right $ updateStateAfterRegistration student course state

-- | updates the system state after registration
-- constructs new student and course records and maps them into a new SystemState
updateStateAfterRegistration :: Student -> Course -> SystemState -> SystemState
updateStateAfterRegistration student course state =
  
  -- creates updated records by prepending the new IDs to the enrollment lists
  let newStudent = student { enrollment = courseID course : enrollment student }
      newCourse = course { studentEnrollment = studentID student : studentEnrollment course }
      
      -- replaces the old records with the newly constructed ones
      newStudents = map (\s -> if studentID s == studentID student then newStudent else s) (students state)
      newCourses = map (\c -> if courseID c == courseID course then newCourse else c) (courses state)
  
  -- returns the final immutable state
  in SystemState newStudents newCourses

-- | drops a course
-- evaluates drop rules and short-circuits if the student is not enrolled
dropCourse :: Int -> Int -> SystemState -> Either RegError SystemState
dropCourse sid cid state = do
  
  -- attempts to locate student and course
  student <- maybeToEither StudentNotFound (findStudent sid (students state))
  course <- maybeToEither CourseNotFound (findCourse cid (courses state))
  
  -- verifies the student is currently enrolled in the course
  if cid `notElem` enrollment student
    then Left NotEnrolled
  
  -- proceeds to update the system state if validation passes
  else Right $ updateStateAfterDrop student course state

-- | updates the system state after dropping
-- constructs new records by filtering the dropped IDs out of the enrollment lists
updateStateAfterDrop :: Student -> Course -> SystemState -> SystemState
updateStateAfterDrop student course state =
  
  -- creates updated records using filter to remove the target IDs
  let newStudent = student { enrollment = filter (/= courseID course) (enrollment student) }
      newCourse = course { studentEnrollment = filter (/= studentID student) (studentEnrollment course) }
      
      -- replaces the old records with the newly constructed ones
      newStudents = map (\s -> if studentID s == studentID student then newStudent else s) (students state)
      newCourses = map (\c -> if courseID c == courseID course then newCourse else c) (courses state)
  
  -- returns the final immutable state
  in SystemState newStudents newCourses

-- | view a student's schedule
-- retrieves the names of all courses the student is currently enrolled in
viewStudentSchedule :: Int -> SystemState -> Either RegError [String]
viewStudentSchedule sid state = do
   
   -- attempts to locate student
   student <- maybeToEither StudentNotFound (findStudent sid (students state))
   
   -- uses list comprehension to extract course names matching the student's enrollment IDs
   let courseNames = [courseName c | c <- courses state, courseID c `elem` enrollment student]
   
   return courseNames

-- | view a course roster
-- retrieves the names of all students currently enrolled in the course
viewCourseRoster :: Int -> SystemState -> Either RegError [String]
viewCourseRoster cid state = do
   
   -- attempts to locate course
   course <- maybeToEither CourseNotFound (findCourse cid (courses state))
   
   -- uses list comprehension to extract student names matching the course's enrollment IDs
   let studentNames = [studentName s | s <- students state, studentID s `elem` studentEnrollment course]
   
   return studentNames

-- | helper to convert Maybe to Either
-- routes Nothing to a Left error and Just to a Right success
maybeToEither :: e -> Maybe a -> Either e a
maybeToEither err Nothing = Left err
maybeToEither _ (Just val) = Right val
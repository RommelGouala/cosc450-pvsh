module CoreLogic where
import Type
import Data.List (find, isInfixOf)
import Data.Char (toLower)

-- | finds a course by ID
findCourse :: Int -> [Course] -> Maybe Course
findCourse cid crsList = find (\c -> courseID c == cid) crsList

-- | finds a student by ID
findStudent :: Int -> [Student] -> Maybe Student
findStudent sid stdList = find (\s -> studentID s == sid) stdList

-- | gets a list of all courses and open seats
getAvailableCourses :: SystemState -> [(String, Int, Int)]
getAvailableCourses state = 
  map (\c -> (courseName c, capacity c, capacity c - length (studentEnrollment c))) (courses state)

-- | search courses by keyword (case-insensitive)
searchCourses :: String -> SystemState -> [Course]
searchCourses keyword state =
  let lowerKey = map toLower keyword
      matches c = lowerKey `isInfixOf` map toLower (courseName c) || lowerKey `isInfixOf` show (courseID c)
  in filter matches (courses state)

-- | register a student for a course (now checks prereqs and completed courses)
registerStudent :: Int -> Int -> SystemState -> Either RegError SystemState
registerStudent sid cid state = do
  student <- maybeToEither StudentNotFound (findStudent sid (students state))
  course <- maybeToEither CourseNotFound (findCourse cid (courses state))
  
  if length (studentEnrollment course) >= capacity course
    then Left CourseFull
  else if cid `elem` enrollment student
    then Left AlreadyEnrolled
  else if cid `elem` completedCourses student
    then Left AlreadyCompleted
  else if not (all (`elem` completedCourses student) (prerequisites course))
    then Left MissingPrereq
  else Right $ updateStateAfterRegistration student course state

-- | updates the system state after registration
updateStateAfterRegistration :: Student -> Course -> SystemState -> SystemState
updateStateAfterRegistration student course state =
  let newStudent = student { enrollment = courseID course : enrollment student }
      newCourse = course { studentEnrollment = studentID student : studentEnrollment course }
      newStudents = map (\s -> if studentID s == studentID student then newStudent else s) (students state)
      newCourses = map (\c -> if courseID c == courseID course then newCourse else c) (courses state)
  in SystemState newStudents newCourses

-- | drops a course
dropCourse :: Int -> Int -> SystemState -> Either RegError SystemState
dropCourse sid cid state = do
  student <- maybeToEither StudentNotFound (findStudent sid (students state))
  course <- maybeToEither CourseNotFound (findCourse cid (courses state))
  
  if cid `notElem` enrollment student
    then Left NotEnrolled
  else Right $ updateStateAfterDrop student course state

-- | updates the system state after dropping
updateStateAfterDrop :: Student -> Course -> SystemState -> SystemState
updateStateAfterDrop student course state =
  let newStudent = student { enrollment = filter (/= courseID course) (enrollment student) }
      newCourse = course { studentEnrollment = filter (/= studentID student) (studentEnrollment course) }
      newStudents = map (\s -> if studentID s == studentID student then newStudent else s) (students state)
      newCourses = map (\c -> if courseID c == courseID course then newCourse else c) (courses state)
  in SystemState newStudents newCourses

-- | view a student's schedule
viewStudentSchedule :: Int -> SystemState -> Either RegError [String]
viewStudentSchedule sid state = do
   student <- maybeToEither StudentNotFound (findStudent sid (students state))
   let courseNames = [courseName c | c <- courses state, courseID c `elem` enrollment student]
   return courseNames

-- | view a course roster
viewCourseRoster :: Int -> SystemState -> Either RegError [String]
viewCourseRoster cid state = do
   course <- maybeToEither CourseNotFound (findCourse cid (courses state))
   let studentNames = [studentName s | s <- students state, studentID s `elem` studentEnrollment course]
   return studentNames

-- | helper to convert Maybe to Either
maybeToEither :: e -> Maybe a -> Either e a
maybeToEither err Nothing = Left err
maybeToEither _ (Just val) = Right val
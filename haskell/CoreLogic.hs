module CoreLogic where
import Type
import Data.List(find) -- imports find function to search a list that matches a condition from standard library

-- | this blokc finds a course by ID
findCourse :: Int -> [Course] -> Maybe Course
findCourse cid crsList = 
    find (\c -> courseID c == cid) crsList

-- | this block finds a student by ID
findStudent :: Int -> [Student] -> Maybe Student
findStudent sid stdList = 
    find (\s -> studentID s == sid) stdList

-- | gets a list of all courses and open seats
getAvailableCourses :: SystemState -> [(String, Int, Int)] -- (Name, Capacity, Open Seats)
getAvailableCourses state = 
  map (\c -> (courseName c, capacity c, capacity c - length (studentEnrollment c))) (courses state)

-- | register a student for a course
registerStudent :: Int -> Int -> SystemState -> Either RegError SystemState
registerStudent sid cid state = do
  student <- maybeToEither StudentNotFound (findStudent sid (students state))
  course <- maybeToEither CourseNotFound (findCourse cid (courses state))
  
  if length (studentEnrollment course) >= capacity course
    then Left CourseFull
  else if cid `elem` enrollment student
    then Left AlreadyEnrolled
  else Right $ updateStateAfterRegistration student course state

-- | this block updates the system state after registration
updateStateAfterRegistration :: Student -> Course -> SystemState -> SystemState
updateStateAfterRegistration student course state =
  let 
      newStudent = student { enrollment = courseID course : enrollment student }
      newCourse = course { studentEnrollment = studentID student : studentEnrollment course }
      
      newStudents = map (\s -> if studentID s == studentID student then newStudent else s) (students state)
      newCourses = map (\c -> if courseID c == courseID course then newCourse else c) (courses state)
  in SystemState newStudents newCourses

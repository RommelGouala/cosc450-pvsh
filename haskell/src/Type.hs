-- the purpose of Type.hs is to define the data types needed for this course registration project

module Type where
    data Course = Course {
        courseID :: Int, -- note: field names start with lowercase letter in haskell
        courseName :: String,
        capacity :: Int,
        studentEnrollment :: [Int] -- use brackets for list, Course IDs the student are enrolled in
    } deriving (Show, Eq)
    data Student = Student{
        studentID :: Int,
        studentName :: String,
        enrollment :: [Int] --List of Student IDs enrolled in the course
    } deriving (Show, Eq) -- deriving prints records
    
    data SystemState = SystemState { -- this retrieves the current state of the registration system i.e capacity for a course and num enrolled, student name
        students :: [Student],
        courses  :: [Course]
  } deriving (Show, Eq)

-- custom error messages
    data RegError 
        = CourseFull 
        | CourseNotFound 
        | StudentNotFound 
        | AlreadyEnrolled 
        | NotEnrolled
        deriving (Show, Eq)

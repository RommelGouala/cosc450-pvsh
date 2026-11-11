-- the purpose of Type.hs is to define the data types needed for this course registration project

module Type where

-- |  model representing a course
data Course = Course {
    courseID :: Int,
    courseName :: String,
    capacity :: Int,
    studentEnrollment :: [Int],
    prerequisites :: [Int] 
} deriving (Show, Eq)

-- | model representing a student
data Student = Student{
    studentID :: Int,
    studentName :: String,
    enrollment :: [Int],
    completedCourses :: [Int] 
} deriving (Show, Eq)

-- | central state record holding all current student and course data
data SystemState = SystemState {
    students :: [Student],
    courses  :: [Course]
} deriving (Show, Eq)

-- | custom algebraic data type representing specific registration and lookup failures
data RegError 
    = CourseFull 
    | CourseNotFound 
    | StudentNotFound 
    | AlreadyEnrolled 
    | NotEnrolled
    | MissingPrereq 
    | AlreadyCompleted 
    deriving (Show, Eq)
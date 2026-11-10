-- the purpose of Type.hs is to define the data types needed for this course registration project

module Type where

data Course = Course {
    courseID :: Int,
    courseName :: String,
    capacity :: Int,
    studentEnrollment :: [Int],
    prerequisites :: [Int] 
} deriving (Show, Eq)

data Student = Student{
    studentID :: Int,
    studentName :: String,
    enrollment :: [Int],
    completedCourses :: [Int] 
} deriving (Show, Eq)

data SystemState = SystemState {
    students :: [Student],
    courses  :: [Course]
} deriving (Show, Eq)

data RegError 
    = CourseFull 
    | CourseNotFound 
    | StudentNotFound 
    | AlreadyEnrolled 
    | NotEnrolled
    | MissingPrereq 
    | AlreadyCompleted 
    deriving (Show, Eq)
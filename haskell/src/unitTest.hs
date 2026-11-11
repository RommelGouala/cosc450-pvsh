module Main where

import Test.HUnit
import Type
import CoreLogic

-- | constructs dummy course records
c1 :: Course
c1 = Course 41758 "Intro to Haskell" 1 [] []

c2 :: Course
c2 = Course 99999 "Full Course" 0 [] []

-- c3 requires c1 (course 41758) as a prerequisite
c3 :: Course
c3 = Course 50000 "Advanced Haskell" 10 [] [41758] 

-- | constructs dummy student records
s1 :: Student
s1 = Student 1001 "Lori Gray" [] []

-- s2 is pre-enrolled in c1 (course 41758)
s2 :: Student
s2 = Student 1002 "Patrick Morgan" [41758] []

-- | creates the baseline system state used at the start of each test
initialState :: SystemState
initialState = SystemState [s1, s2] [c1, c2, c3]

-- | test case 1: normal registration
-- verifies that a valid student and course result in a successfully updated state
test1 :: Test
test1 = TestCase $ 
    let expectedState = SystemState [s1 { enrollment = [41758] }, s2] [c1 { studentEnrollment = [1001] }, c2, c3]
    in assertEqual "T1: Normal Register - Successfully enrolls student" 
       (Right expectedState) 
       (registerStudent 1001 41758 initialState)

-- | test case 2: capacity boundary
-- verifies that registering for a full course returns a Left CourseFull error
test2 :: Test
test2 = TestCase $ 
    assertEqual "T2: Boundary - Capacity Limit (CourseFull error)"
    (Left CourseFull)
    (registerStudent 1001 99999 initialState)

-- | test case 3: invalid student ID
-- verifies that a non-existent student ID returns a Left StudentNotFound error
test3 :: Test
test3 = TestCase $ 
    assertEqual "T3: Invalid Input - Missing ID (StudentNotFound error)"
    (Left StudentNotFound)
    (registerStudent 9999 41758 initialState)

-- | test case 4: add and drop logic sequence
-- verifies that dropping a recently added course correctly returns the state to its original configuration
test4 :: Test
test4 = TestCase $ 
    let Right registeredState = registerStudent 1001 41758 initialState
        droppedResult = dropCourse 1001 41758 registeredState
    in assertEqual "T4: Complex - Add then Drop returns to original state" 
       (Right initialState) 
       droppedResult

-- | test case 5: view course roster
-- verifies that roster lookup accurately maps enrolled IDs back to student string names
test5 :: Test
test5 = TestCase $ 
    let stateEnrolled = SystemState [s1, s2] [c1 { studentEnrollment = [1002] }, c2, c3]
    in assertEqual "T5: Feature - Course Roster returns correct string name"
       (Right ["Patrick Morgan"])
       (viewCourseRoster 41758 stateEnrolled)

-- | test case 6: prerequisite validation
-- verifies that registering for an advanced course without the completed prerequisite returns a Left MissingPrereq error
test6 :: Test
test6 = TestCase $ 
    assertEqual "T6: Feature - Student lacks prerequisites (MissingPrereq error)"
    (Left MissingPrereq)
    (registerStudent 1001 50000 initialState)

-- | groups all individual tests into a single suite for execution
tests :: Test
tests = TestList [TestLabel "T1" test1, TestLabel "T2" test2, TestLabel "T3" test3, TestLabel "T4" test4, TestLabel "T5" test5, TestLabel "T6" test6]

-- | test suite entry point
main :: IO ()
main = do
    putStrLn "Running Course Registration Test Suite..."
    _ <- runTestTT tests
    return ()
module Main where

import Test.HUnit
import Type
import CoreLogic

--  dummy initial state to run tests against
c1 :: Course
c1 = Course 41758 "Intro to Haskell" 1 [] []

c2 :: Course
c2 = Course 99999 "Full Course" 0 [] []

c3 :: Course
c3 = Course 50000 "Advanced Haskell" 10 [] [41758] -- Requires 41758

s1 :: Student
s1 = Student 1001 "Lori Gray" [] []

s2 :: Student
s2 = Student 1002 "Patrick Morgan" [41758] []

initialState :: SystemState
initialState = SystemState [s1, s2] [c1, c2, c3]

-- defines the test cases
test1 :: Test
test1 = TestCase $ 
    let expectedState = SystemState [s1 { enrollment = [41758] }, s2] [c1 { studentEnrollment = [1001] }, c2, c3]
    in assertEqual "T1: Normal Register - Successfully enrolls student" 
       (Right expectedState) 
       (registerStudent 1001 41758 initialState)

test2 :: Test
test2 = TestCase $ 
    assertEqual "T2: Boundary - Capacity Limit (CourseFull error)"
    (Left CourseFull)
    (registerStudent 1001 99999 initialState)

test3 :: Test
test3 = TestCase $ 
    assertEqual "T3: Invalid Input - Missing ID (StudentNotFound error)"
    (Left StudentNotFound)
    (registerStudent 9999 41758 initialState)

test4 :: Test
test4 = TestCase $ 
    let Right registeredState = registerStudent 1001 41758 initialState
        droppedResult = dropCourse 1001 41758 registeredState
    in assertEqual "T4: Complex - Add then Drop returns to original state" 
       (Right initialState) 
       droppedResult

test5 :: Test
test5 = TestCase $ 
    let stateEnrolled = SystemState [s1, s2] [c1 { studentEnrollment = [1002] }, c2, c3]
    in assertEqual "T5: Feature - Course Roster returns correct string name"
       (Right ["Patrick Morgan"])
       (viewCourseRoster 41758 stateEnrolled)

test6 :: Test
test6 = TestCase $ 
    assertEqual "T6: Feature - Student lacks prerequisites (MissingPrereq error)"
    (Left MissingPrereq)
    (registerStudent 1001 50000 initialState)

-- group and run tests
tests :: Test
tests = TestList [TestLabel "T1" test1, TestLabel "T2" test2, TestLabel "T3" test3, TestLabel "T4" test4, TestLabel "T5" test5, TestLabel "T6" test6]

main :: IO ()
main = do
    putStrLn "Running Course Registration Test Suite..."
    _ <- runTestTT tests
    return ()
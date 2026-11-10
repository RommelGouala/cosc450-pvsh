module Main where

import Type
import CoreLogic
import FileIO
import System.IO

main :: IO ()
main = do
  state <- loadState "data/students.csv" "data/courses.csv"
  putStrLn $ "Successfully loaded " ++ show (length (students state)) ++ " students and " ++ show (length (courses state)) ++ " courses."
  putStrLn "Welcome to the Course Registration System!"
  runMenu state

runMenu :: SystemState -> IO ()
runMenu state = do
  putStrLn "\n--- Main Menu ---"
  putStrLn "1. View Course Catalog"
  putStrLn "2. Search Courses"
  putStrLn "3. Register for a Course"
  putStrLn "4. Drop a Course"
  putStrLn "5. View Student Schedule"
  putStrLn "6. View Course Roster"
  putStrLn "7. Save and Exit"
  putStr "Enter your choice: "
  hFlush stdout
  
  choice <- getLine
  case choice of
    "1" -> do
      putStrLn "\n--- Course Catalog ---"
      let catalog = getAvailableCourses state
      mapM_ print catalog
      runMenu state

    "2" -> do
      putStr "Enter keyword to search: "
      hFlush stdout
      keyword <- getLine
      let results = searchCourses keyword state
      putStrLn "\n--- Search Results ---"
      if null results
        then putStrLn "No courses found."
        else mapM_ (\c -> putStrLn $ show (courseID c) ++ " - " ++ courseName c) results
      runMenu state
      
    "3" -> do
      putStr "Enter Student ID: "
      hFlush stdout
      sInput <- getLine
      putStr "Enter Course ID: "
      hFlush stdout
      cInput <- getLine
      
      let sid = read sInput :: Int
      let cid = read cInput :: Int
      
      case registerStudent sid cid state of
        Left err -> do
          putStrLn $ "\n[!] Error registering: " ++ show err
          runMenu state
        Right newState -> do
          putStrLn "\n[*] Successfully registered!"
          runMenu newState
          
    "4" -> do
      putStr "Enter Student ID to drop: "
      hFlush stdout
      sInput <- getLine
      putStr "Enter Course ID to drop: "
      hFlush stdout
      cInput <- getLine
      
      let sid = read sInput :: Int
      let cid = read cInput :: Int
      
      case dropCourse sid cid state of
        Left err -> do
          putStrLn $ "\n[!] Error dropping course: " ++ show err
          runMenu state
        Right newState -> do
          putStrLn "\n[*] Successfully dropped course!"
          runMenu newState

    "5" -> do
        putStr "Enter Student ID: "
        hFlush stdout
        sInput <- getLine
        let sid = read sInput :: Int
        case viewStudentSchedule sid state of
            Left err -> putStrLn $ "\n[!] Error: " ++ show err
            Right schedule -> do
                putStrLn "\n--- Schedule ---"
                if null schedule
                  then putStrLn "Student is not enrolled in any courses."
                  else mapM_ putStrLn schedule
        runMenu state

    "6" -> do
        putStr "Enter Course ID to view roster: "
        hFlush stdout
        cInput <- getLine
        let cid = read cInput :: Int
        case viewCourseRoster cid state of
            Left err -> putStrLn $ "\n[!] Error: " ++ show err
            Right roster -> do
                putStrLn "\n--- Course Roster ---"
                if null roster 
                  then putStrLn "No students currently enrolled."
                  else mapM_ putStrLn roster
        runMenu state

    "7" -> do
        putStrLn "Saving state to CSV..."
        saveState "data/students.csv" "data/courses.csv" state
        putStrLn "Saved successfully. Goodbye!"
        
    _   -> do
      putStrLn "\n[!] Invalid choice. Please try again."
      runMenu state
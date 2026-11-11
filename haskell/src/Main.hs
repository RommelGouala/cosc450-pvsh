module Main where

import Type
import CoreLogic
import FileIO
import System.IO

-- | program entry point
-- handles initial data loading and starts the menu loop
main :: IO ()
main = do
  
  -- executes IO operation to load CSV files into initial SystemState
  state <- loadState "data/students.csv" "data/courses.csv"
  
  -- prints loading confirmation to the terminal
  putStrLn $ "Successfully loaded " ++ show (length (students state)) ++ " students and " ++ show (length (courses state)) ++ " courses."
  putStrLn "Welcome to the Course Registration System!"
  
  -- passes the loaded state into the recursive menu loop
  runMenu state

-- | interactive terminal menu loop
-- prompts the user, executes the selected action, and recursively calls itself with the updated state
runMenu :: SystemState -> IO ()
runMenu state = do
  
  -- displays menu options
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
  
  -- captures user input
  choice <- getLine
  
  -- routes execution based on the selected menu option
  case choice of
    
    -- Option 1: Course Catalog
    "1" -> do
      putStrLn "\n--- Course Catalog ---"
      let catalog = getAvailableCourses state
      mapM_ print catalog
      runMenu state

    -- Option 2: Search Courses
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
      
    -- Option 3: Register
    "3" -> do
      putStr "Enter Student ID: "
      hFlush stdout
      sInput <- getLine
      putStr "Enter Course ID: "
      hFlush stdout
      cInput <- getLine
      
      -- parses terminal input strings into integers
      let sid = read sInput :: Int
      let cid = read cInput :: Int
      
      -- executes pure registration logic and pattern matches the Either result
      case registerStudent sid cid state of
        
        -- handles validation failures by printing the RegError and maintaining the current state
        Left err -> do
          putStrLn $ "\n[!] Error registering: " ++ show err
          runMenu state
        
        -- handles successful registration by recursing with the newly generated state
        Right newState -> do
          putStrLn "\n[*] Successfully registered!"
          runMenu newState
          
    -- Option 4: Drop
    "4" -> do
      putStr "Enter Student ID to drop: "
      hFlush stdout
      sInput <- getLine
      putStr "Enter Course ID to drop: "
      hFlush stdout
      cInput <- getLine
      
      -- parses terminal input strings into integers
      let sid = read sInput :: Int
      let cid = read cInput :: Int
      
      -- executes pure drop logic and pattern matches the Either result
      case dropCourse sid cid state of
        
        -- handles validation failures by printing the RegError and maintaining the current state
        Left err -> do
          putStrLn $ "\n[!] Error dropping course: " ++ show err
          runMenu state
        
        -- handles successful drop by recursing with the newly generated state
        Right newState -> do
          putStrLn "\n[*] Successfully dropped course!"
          runMenu newState

    -- Option 5: View Schedule
    "5" -> do
        putStr "Enter Student ID: "
        hFlush stdout
        sInput <- getLine
        let sid = read sInput :: Int
        
        -- pattern matches the Either result for the schedule lookup
        case viewStudentSchedule sid state of
            Left err -> putStrLn $ "\n[!] Error: " ++ show err
            Right schedule -> do
                putStrLn "\n--- Schedule ---"
                if null schedule
                  then putStrLn "Student is not enrolled in any courses."
                  else mapM_ putStrLn schedule
        runMenu state

    -- Option 6: View Roster
    "6" -> do
        putStr "Enter Course ID to view roster: "
        hFlush stdout
        cInput <- getLine
        let cid = read cInput :: Int
        
        -- pattern matches the Either result for the roster lookup
        case viewCourseRoster cid state of
            Left err -> putStrLn $ "\n[!] Error: " ++ show err
            Right roster -> do
                putStrLn "\n--- Course Roster ---"
                if null roster 
                  then putStrLn "No students currently enrolled."
                  else mapM_ putStrLn roster
        runMenu state

    -- Option 7: Save and Exit
    "7" -> do
        putStrLn "Saving state to CSV..."
        
        -- executes IO operation to write the current in-memory state back to disk
        saveState "data/students.csv" "data/courses.csv" state
        
        -- exits the application gracefully without recursing runMenu
        putStrLn "Saved successfully. Goodbye!"
        
    -- Default fallback for invalid menu selections
    _   -> do
      putStrLn "\n[!] Invalid choice. Please try again."
      runMenu state
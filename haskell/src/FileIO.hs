module FileIO where

import Type
import Data.Csv (decode, HasHeader(NoHeader))
import qualified Data.ByteString.Lazy as BL
import qualified Data.Vector as V
import Data.Maybe (mapMaybe)
import Data.List (intercalate)

-- | parse a semicolon-separated list of IDs
-- returns an empty list for empty strings, otherwise splits by semicolon and parses to Int
parseIDList :: String -> Maybe [Int]
parseIDList "" = Just []
parseIDList s = traverse readInt (splitOn ';' s)
  where
    
    -- safely reads a string into an Int, returning Nothing if parsing fails
    readInt x = case reads x of
                    [(n, "")] -> Just n
                    _         -> Nothing

-- | Split a string using a delimiter
-- recursively breaks a string into a list of strings based on the target character
splitOn :: Char -> String -> [String]
splitOn _ "" = [""]
splitOn c s =
    let (word, rest) = break (== c) s
    in word : case rest of
                []     -> []
                (_:xs) -> splitOn c xs

-- | Parse an integer safely
-- attempts to read a string into an Int, returning Nothing if parsing fails
parseInt :: String -> Maybe Int
parseInt s = case reads s of
    [(n, "")] -> Just n
    _         -> Nothing

-- | search a student CSV row 
-- uses pattern matching to support different CSV column formats
parseStudent :: [String] -> Maybe Student

-- matches the expanded 4-column format containing active enrollments and completed courses
parseStudent [sidStr, name, enrolledStr, completedStr] = do
    sid       <- parseInt sidStr
    enrolled  <- parseIDList enrolledStr
    completed <- parseIDList completedStr
    return (Student sid name enrolled completed)

-- matches the 3-column format, defaulting active enrollments to an empty list
parseStudent [sidStr, name, completedStr] = do
    sid       <- parseInt sidStr
    completed <- parseIDList completedStr
    return (Student sid name [] completed)  -- Default empty enrollment list

-- matches a 2-column fallback format if trailing commas are missing
parseStudent [sidStr, name] = do
    sid       <- parseInt sidStr
    return (Student sid name [] [])         -- Fallback if trailing comma is missing

-- returns Nothing for any other malformed row format
parseStudent _ = Nothing


-- | parse a course CSV row
-- uses pattern matching to support different CSV column formats
parseCourse :: [String] -> Maybe Course

-- matches the expanded 5-column format containing capacity, active enrollments, and prerequisites
parseCourse [cidStr, name, capStr, enrolledStr, prereqStr] = do
    cid      <- parseInt cidStr
    cap      <- parseInt capStr
    enrolled <- parseIDList enrolledStr
    prereqs  <- parseIDList prereqStr
    return (Course cid name cap enrolled prereqs)

-- matches the 4-column format, defaulting active enrollments to an empty list
parseCourse [cidStr, name, capStr, prereqStr] = do
    cid      <- parseInt cidStr
    cap      <- parseInt capStr
    prereqs  <- parseIDList prereqStr
    return (Course cid name cap [] prereqs) -- Default empty enrollment list

-- matches a 3-column fallback format if trailing commas are missing
parseCourse [cidStr, name, capStr] = do
    cid      <- parseInt cidStr
    cap      <- parseInt capStr
    return (Course cid name cap [] [])      -- Fallback if trailing comma is missing

-- returns Nothing for any other malformed row format
parseCourse _ = Nothing

-- | load and parse CSV records
-- reads the file into a ByteString and decodes it using the cassava library
loadCsv :: FilePath -> IO [[String]]
loadCsv file = do
    contents <- BL.readFile file
    case decode NoHeader contents of
        Left err -> ioError (userError err)
        Right rows -> return (map V.toList (V.toList rows))

-- | load files and build the initial SystemState
-- triggers CSV loading and maps the parsing functions over the resulting rows
loadState :: FilePath -> FilePath -> IO SystemState
loadState studentFile courseFile = do
    studentRows <- loadCsv studentFile
    courseRows  <- loadCsv courseFile

    -- uses mapMaybe to extract valid records and automatically drop rows that failed parsing
    let loadedStudents = mapMaybe parseStudent studentRows
        loadedCourses  = mapMaybe parseCourse courseRows

    return (SystemState loadedStudents loadedCourses)

-- | helper to format an integer list back to a string for CSV
-- converts a list of integers into a semicolon-separated string
formatIDList :: [Int] -> String
formatIDList = intercalate ";" . map show

-- | save the current state back to the CSV files
-- formats the current SystemState back into comma-separated strings and writes to disk
saveState :: FilePath -> FilePath -> SystemState -> IO ()
saveState studentFile courseFile state = do
    
    -- formats each student record into the expanded 4-column CSV format
    let studentLines = map (\s -> intercalate "," [show (studentID s), studentName s, formatIDList (enrollment s), formatIDList (completedCourses s)]) (students state)
        
    -- formats each course record into the expanded 5-column CSV format
        courseLines  = map (\c -> intercalate "," [show (courseID c), courseName c, show (capacity c), formatIDList (studentEnrollment c), formatIDList (prerequisites c)]) (courses state)
    
    -- executes the IO operations to overwrite the files
    writeFile studentFile (unlines studentLines)
    writeFile courseFile (unlines courseLines)
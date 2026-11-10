module FileIO where

import Type
import Data.Csv (decode, HasHeader(NoHeader))
import qualified Data.ByteString.Lazy as BL
import qualified Data.Vector as V
import Data.Maybe (mapMaybe)
import Data.List (intercalate)
import System.IO (writeFile)

-- | parse a semicolon-separated list of IDs
parseIDList :: String -> Maybe [Int]
parseIDList "" = Just []
parseIDList s = traverse readInt (splitOn ';' s)
  where
    readInt x = case reads x of
                    [(n, "")] -> Just n
                    _         -> Nothing

-- | Split a string using a delimiter
splitOn :: Char -> String -> [String]
splitOn _ "" = [""]
splitOn c s =
    let (word, rest) = break (== c) s
    in word : case rest of
                []     -> []
                (_:xs) -> splitOn c xs

-- | Parse an integer safely
parseInt :: String -> Maybe Int
parseInt s = case reads s of
    [(n, "")] -> Just n
    _         -> Nothing

-- | search a student CSV row 
parseStudent :: [String] -> Maybe Student
parseStudent [sidStr, name, enrolledStr, completedStr] = do
    sid       <- parseInt sidStr
    enrolled  <- parseIDList enrolledStr
    completed <- parseIDList completedStr
    return (Student sid name enrolled completed)
parseStudent [sidStr, name, completedStr] = do
    sid       <- parseInt sidStr
    completed <- parseIDList completedStr
    return (Student sid name [] completed)  -- Default empty enrollment list
parseStudent [sidStr, name] = do
    sid       <- parseInt sidStr
    return (Student sid name [] [])         -- Fallback if trailing comma is missing
parseStudent _ = Nothing

parseCourse :: [String] -> Maybe Course
parseCourse [cidStr, name, capStr, enrolledStr, prereqStr] = do
    cid      <- parseInt cidStr
    cap      <- parseInt capStr
    enrolled <- parseIDList enrolledStr
    prereqs  <- parseIDList prereqStr
    return (Course cid name cap enrolled prereqs)
parseCourse [cidStr, name, capStr, prereqStr] = do
    cid      <- parseInt cidStr
    cap      <- parseInt capStr
    prereqs  <- parseIDList prereqStr
    return (Course cid name cap [] prereqs) -- Default empty enrollment list
parseCourse [cidStr, name, capStr] = do
    cid      <- parseInt cidStr
    cap      <- parseInt capStr
    return (Course cid name cap [] [])      -- Fallback if trailing comma is missing
parseCourse _ = Nothing

-- | load and parse CSV records
loadCsv :: FilePath -> IO [[String]]
loadCsv file = do
    contents <- BL.readFile file
    case decode NoHeader contents of
        Left err -> ioError (userError err)
        Right rows -> return (map V.toList (V.toList rows))

-- | load files and build the initial SystemState
loadState :: FilePath -> FilePath -> IO SystemState
loadState studentFile courseFile = do
    studentRows <- loadCsv studentFile
    courseRows  <- loadCsv courseFile

    let loadedStudents = mapMaybe parseStudent studentRows
        loadedCourses  = mapMaybe parseCourse courseRows

    return (SystemState loadedStudents loadedCourses)

formatIDList :: [Int] -> String
formatIDList = intercalate ";" . map show

-- | save the current state back to the CSV files
saveState :: FilePath -> FilePath -> SystemState -> IO ()
saveState studentFile courseFile state = do
    let studentLines = map (\s -> intercalate "," [show (studentID s), studentName s, formatIDList (enrollment s), formatIDList (completedCourses s)]) (students state)
        courseLines  = map (\c -> intercalate "," [show (courseID c), courseName c, show (capacity c), formatIDList (studentEnrollment c), formatIDList (prerequisites c)]) (courses state)
    
    writeFile studentFile (unlines studentLines)
    writeFile courseFile (unlines courseLines)
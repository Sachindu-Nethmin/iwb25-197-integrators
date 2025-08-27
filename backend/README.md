# Material Quiz Backend

This Ballerina project provides functionality to create MCQ (Multiple Choice Questions) from PDF documents and store them in a MySQL database.

## Features

- Extract text from PDF documents
- Generate MCQs using Google's Gemini AI
- Store questions and quizzes in MySQL database
- Manage quiz-question relationships

## Database Schema

The application creates three main tables:

### 1. `quizzes` table
- `id` (INT, AUTO_INCREMENT, PRIMARY KEY)
- `title` (VARCHAR(255), NOT NULL)
- `description` (TEXT)
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

### 2. `questions` table
- `id` (INT, AUTO_INCREMENT, PRIMARY KEY)
- `question` (TEXT, NOT NULL)
- `option_a` (VARCHAR(500), NOT NULL)
- `option_b` (VARCHAR(500), NOT NULL)
- `option_c` (VARCHAR(500), NOT NULL)
- `option_d` (VARCHAR(500), NOT NULL)
- `correct_answer` (CHAR(1), NOT NULL)
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

### 3. `quiz_questions` table (Junction table)
- `quiz_id` (INT, NOT NULL, FOREIGN KEY)
- `question_id` (INT, NOT NULL, FOREIGN KEY)
- PRIMARY KEY (`quiz_id`, `question_id`)

## Prerequisites

1. **MySQL Database**: Make sure you have MySQL installed and running
2. **Database Setup**: Create a database named `material_quiz` (or update the configuration)
3. **Configuration**: Update the `Config.toml` file with your database credentials

## Configuration

Update the `Config.toml` file with your database settings:

```toml
# Database Configuration
DB_HOST="localhost"
DB_PORT=3306
DB_NAME="material_quiz"
DB_USERNAME="root"
DB_PASSWORD="your_password_here"

# API Configuration
GEMINI_API_KEY="your_gemini_api_key_here"
```

## Database Functions

### Core Functions

1. **`initDatabase()`** - Initialize database connection
2. **`createTables()`** - Create all required database tables
3. **`closeDatabase()`** - Close database connection

### Quiz Management

1. **`createQuiz(title, description?)`** - Create a new quiz
2. **`getAllQuizzes()`** - Retrieve all quizzes
3. **`addQuestionsToQuiz(quizId, questionIds[])`** - Associate questions with a quiz

### Question Management

1. **`insertQuestion(Question)`** - Insert a single question
2. **`insertQuestionsFromJson(json)`** - Insert multiple questions from JSON format
3. **`getQuizQuestions(quizId)`** - Get all questions for a specific quiz

## Usage Example

```ballerina
import ballerina/io;

public function main() returns error? {
    // Sample JSON data
    json sampleQuizData = {
        "questions": [
            {
                "question": "What is the main topic?",
                "options": [
                    "a) Option A",
                    "b) Option B", 
                    "c) Option C",
                    "d) Option D"
                ],
                "answer": "b"
            }
        ],
        "answers": ["b"]
    };

    // Initialize database
    check initDatabase();
    check createTables();
    
    // Create quiz and insert questions
    int quizId = check createQuiz("Sample Quiz", "A sample quiz");
    int[] questionIds = check insertQuestionsFromJson(sampleQuizData);
    check addQuestionsToQuiz(quizId, questionIds);
    
    // Retrieve data
    Question[] questions = check getQuizQuestions(quizId);
    
    // Clean up
    check closeDatabase();
}
```

## JSON Format for Questions

The `insertQuestionsFromJson()` function expects JSON in the following format:

```json
{
  "questions": [
    {
      "question": "What is the main topic of the assignment?",
      "options": [
        "a) The history of mobile phones",
        "b) The impact of mobile phones on student productivity", 
        "c) The benefits of online learning",
        "d) The disadvantages of social media"
      ],
      "answer": "b"
    }
  ],
  "answers": [
    "b"
  ]
}
```

## Building and Running

1. **Build the project**:
   ```bash
   bal build
   ```

2. **Run the main application** (PDF to MCQ generation):
   ```bash
   bal run
   ```

3. **Test database functionality**:
   ```ballerina
   // Call testDatabase() function from test_database.bal
   check testDatabase();
   ```

## Dependencies

- `ballerinax/mysql` - MySQL database connector
- `anjanasupun/pdf` - PDF reading functionality
- `ballerina/http` - HTTP client for API calls
- `ballerina/io` - Input/Output operations

## Notes

- Make sure your MySQL server is running before executing database operations
- The application will automatically create the required tables if they don't exist
- All foreign key constraints are properly set up for data integrity
- The database connection is pooled and managed automatically by the MySQL connector

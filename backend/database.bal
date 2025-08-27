import ballerina/sql;
import ballerinax/mysql;
import ballerina/io;
import ballerina/file;
import ballerina/crypto;

// Database configuration
configurable string DB_HOST = ?;
configurable int DB_PORT = ?;
configurable string DB_NAME = ?;
configurable string DB_USERNAME = ?;
configurable string DB_PASSWORD = ?;

// Database client
mysql:Client? dbClient = ();

// Question record type
public type Question record {
    int id?;
    string question;
    string option_a;
    string option_b;
    string option_c;
    string option_d;
    string correct_answer;
    string created_at?;
};

// Quiz record type
public type Quiz record {
    int id?;
    string title;
    string description?;
    string category?;
    string created_at?;
};

// QuizQuestion relation record type
public type QuizQuestion record {
    int quiz_id;
    int question_id;
};

// User record type
public type User record {
    int id?;
    string username;
    string email;
    string password_hash;
    string created_at?;
};

// Quiz Result record type
public type QuizResult record {
    int id?;
    int user_id;
    int quiz_id;
    string quiz_title?;
    string category?;
    int score;
    int total_questions;
    decimal percentage;
    string username?;
    string completed_at?;
};

// Leaderboard Entry record type
public type LeaderboardEntry record {
    string username;
    string category;
    decimal average_score;
    int total_quizzes;
    decimal best_score;
    string latest_quiz_date?;
};

// Initialize database connection
public function initDatabase() returns error? {
    mysql:Client|sql:Error dbResult = new (
        host = DB_HOST,
        port = DB_PORT,
        database = DB_NAME,
        user = DB_USERNAME,
        password = DB_PASSWORD
    );
    
    if dbResult is sql:Error {
        io:println("Error connecting to database: " + dbResult.message());
        return dbResult;
    }
    
    dbClient = dbResult;
    io:println("Database connection established successfully");
}

// Get database client
public function getDbClient() returns mysql:Client|error {
    mysql:Client? dbConnection = dbClient;
    if dbConnection is mysql:Client {
        return dbConnection;
    }
    return error("Database not initialized. Call initDatabase() first.");
}

// Create database tables
public function createTables() returns error? {
    mysql:Client db = check getDbClient();
    
    // Create quizzes table
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS quizzes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT,
            category VARCHAR(100) DEFAULT 'General',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `);
    io:println("Quizzes table created/verified");
    
    // Add category column if it doesn't exist (for existing databases)
    sql:ExecutionResult|sql:Error alterResult = db->execute(`
        ALTER TABLE quizzes ADD COLUMN category VARCHAR(100) DEFAULT 'General'
    `);
    if alterResult is sql:ExecutionResult {
        io:println("Category column added to quizzes table");
    } else {
        // Column might already exist, which is fine
        io:println("Category column already exists or error adding it");
    }
    
    // Create questions table
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS questions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            question TEXT NOT NULL,
            option_a VARCHAR(500) NOT NULL,
            option_b VARCHAR(500) NOT NULL,
            option_c VARCHAR(500) NOT NULL,
            option_d VARCHAR(500) NOT NULL,
            correct_answer CHAR(1) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `);
    io:println("Questions table created/verified");
    
    // Create quiz_questions junction table
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS quiz_questions (
            quiz_id INT NOT NULL,
            question_id INT NOT NULL,
            PRIMARY KEY (quiz_id, question_id),
            FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE,
            FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
        )
    `);
    io:println("Quiz_questions table created/verified");
    
    // Create users table
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) NOT NULL UNIQUE,
            email VARCHAR(100) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `);
    io:println("Users table created/verified");
    
    // Create quiz_results table
    _ = check db->execute(`
        CREATE TABLE IF NOT EXISTS quiz_results (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            quiz_id INT NOT NULL,
            score INT NOT NULL,
            total_questions INT NOT NULL,
            percentage DECIMAL(5,2) NOT NULL,
            completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
        )
    `);
    io:println("Quiz_results table created/verified");
}

// Insert a single question
public function insertQuestion(Question question) returns int|error {
    mysql:Client db = check getDbClient();
    
    sql:ExecutionResult result = check db->execute(`
        INSERT INTO questions (question, option_a, option_b, option_c, option_d, correct_answer)
        VALUES (${question.question}, ${question.option_a}, ${question.option_b}, 
                ${question.option_c}, ${question.option_d}, ${question.correct_answer})
    `);
    
    if result.lastInsertId is int {
        return <int>result.lastInsertId;
    }
    return error("Failed to get last insert ID");
}

// Insert multiple questions from JSON format
public function insertQuestionsFromJson(json questionsJson) returns int[]|error {
    json questions = check questionsJson.questions;
    json answers = check questionsJson.answers;
    
    if questions !is json[] {
        return error("Invalid questions format");
    }
    
    if answers !is json[] {
        return error("Invalid answers format");
    }
    
    int[] questionIds = [];
    
    foreach int i in 0 ..< questions.length() {
        json questionData = questions[i];
        string answer = (answers[i]).toString();
        
        string questionText = (check questionData.question).toString();
        json[] options = <json[]>check questionData.options;
        
        if options.length() < 4 {
            return error("Each question must have 4 options");
        }
        
        // Extract options (assuming they are in format "a) option text")
        string optionA = options[0].toString();
        string optionB = options[1].toString();
        string optionC = options[2].toString();
        string optionD = options[3].toString();
        
        Question question = {
            question: questionText,
            option_a: optionA,
            option_b: optionB,
            option_c: optionC,
            option_d: optionD,
            correct_answer: answer
        };
        
        int questionId = check insertQuestion(question);
        questionIds.push(questionId);
        io:println(string `Inserted question ${i + 1} with ID: ${questionId}`);
    }
    
    return questionIds;
}

// Create a new quiz
public function createQuiz(string title, string? description = (), string category = "General") returns int|error {
    mysql:Client db = check getDbClient();
    
    sql:ExecutionResult result = check db->execute(`
        INSERT INTO quizzes (title, description, category)
        VALUES (${title}, ${description}, ${category})
    `);
    
    if result.lastInsertId is int {
        return <int>result.lastInsertId;
    }
    return error("Failed to get last insert ID");
}

// Associate questions with a quiz
public function addQuestionsToQuiz(int quizId, int[] questionIds) returns error? {
    mysql:Client db = check getDbClient();
    
    foreach int questionId in questionIds {
        _ = check db->execute(`
            INSERT INTO quiz_questions (quiz_id, question_id)
            VALUES (${quizId}, ${questionId})
        `);
    }
    
    io:println(string `Added ${questionIds.length()} questions to quiz ${quizId}`);
}

// Get all questions for a quiz
public function getQuizQuestions(int quizId) returns Question[]|error {
    mysql:Client db = check getDbClient();
    
    stream<Question, sql:Error?> resultStream = db->query(`
        SELECT q.id, q.question, q.option_a, q.option_b, q.option_c, q.option_d, 
               q.correct_answer, q.created_at
        FROM questions q
        INNER JOIN quiz_questions qq ON q.id = qq.question_id
        WHERE qq.quiz_id = ${quizId}
        ORDER BY q.id
    `);
    
    Question[] questions = [];
    check from Question question in resultStream
        do {
            questions.push(question);
        };
    
    check resultStream.close();
    return questions;
}

// Get all quizzes
public function getAllQuizzes() returns Quiz[]|error {
    mysql:Client db = check getDbClient();
    
    stream<Quiz, sql:Error?> resultStream = db->query(`
        SELECT id, title, description, created_at
        FROM quizzes
        ORDER BY created_at DESC
    `);
    
    Quiz[] quizzes = [];
    check from Quiz quiz in resultStream
        do {
            quizzes.push(quiz);
        };
    
    check resultStream.close();
    return quizzes;
}

// Get quiz by ID
public function getQuizById(int quizId) returns Quiz|error {
    mysql:Client db = check getDbClient();
    
    stream<Quiz, sql:Error?> resultStream = db->query(`
        SELECT id, title, description, created_at
        FROM quizzes
        WHERE id = ${quizId}
    `);
    
    Quiz? quiz = ();
    check from Quiz q in resultStream
        do {
            quiz = q;
        };
    
    check resultStream.close();
    
    if quiz is Quiz {
        return quiz;
    }
    return error("Quiz not found");
}

// Close database connection
public function closeDatabase() returns error? {
    mysql:Client? dbConnection = dbClient;
    if dbConnection is mysql:Client {
        check dbConnection.close();
        dbClient = ();
        io:println("Database connection closed");
    }
}

// File helper functions for PDF upload

// Create directory if it doesn't exist
public function createDirectoryIfNotExists(string dirPath) returns error? {
    boolean|error dirExists = file:test(dirPath, file:EXISTS);
    if dirExists is boolean && !dirExists {
        check file:createDir(dirPath);
        io:println(string `Created directory: ${dirPath}`);
    }
}

// Save uploaded file bytes to a file
public function saveUploadedFile(string filePath, byte[] fileBytes) returns error? {
    check io:fileWriteBytes(filePath, fileBytes);
    io:println(string `Saved uploaded file: ${filePath}`);
}

// Delete a file
public function deleteFile(string filePath) returns error? {
    boolean|error fileExists = file:test(filePath, file:EXISTS);
    if fileExists is boolean && fileExists {
        check file:remove(filePath);
        io:println(string `Deleted file: ${filePath}`);
    }
}

// Authentication functions

// Hash password using crypto
function hashPassword(string password) returns string {
    byte[] hashedBytes = crypto:hashSha256(password.toBytes());
    return hashedBytes.toBase64();
}

// Verify password against hash
function verifyPassword(string password, string hash) returns boolean {
    string passwordHash = hashPassword(password);
    return passwordHash == hash;
}

// Create a new user (sign up)
public function createUser(string username, string email, string password) returns int|error {
    mysql:Client db = check getDbClient();
    
    // Check if username or email already exists
    stream<record {|int count;|}, sql:Error?> userCheckStream = db->query(`
        SELECT COUNT(*) as count FROM users 
        WHERE username = ${username} OR email = ${email}
    `);
    
    record {|int count;|}? userCheck = ();
    check from record {|int count;|} row in userCheckStream
        do {
            userCheck = row;
        };
    
    check userCheckStream.close();
    
    if userCheck is record {|int count;|} && userCheck.count > 0 {
        return error("Username or email already exists");
    }
    
    // Hash the password
    string passwordHash = hashPassword(password);
    
    // Insert new user
    sql:ExecutionResult result = check db->execute(`
        INSERT INTO users (username, email, password_hash) 
        VALUES (${username}, ${email}, ${passwordHash})
    `);
    
    int|string? userId = result.lastInsertId;
    if userId is int {
        io:println(string `User created successfully with ID: ${userId}`);
        return userId;
    }
    
    return error("Failed to create user");
}

// Authenticate user (sign in)
public function authenticateUser(string usernameOrEmail, string password) returns User|error {
    mysql:Client db = check getDbClient();
    
    // Get user by username or email
    stream<User, sql:Error?> userStream = db->query(`
        SELECT id, username, email, password_hash, created_at 
        FROM users 
        WHERE username = ${usernameOrEmail} OR email = ${usernameOrEmail}
    `);
    
    User? user = ();
    check from User u in userStream
        do {
            user = u;
        };
    
    check userStream.close();
    
    if user is () {
        return error("User not found");
    }
    
    // Verify password
    boolean isValid = verifyPassword(password, user.password_hash);
    if !isValid {
        return error("Invalid password");
    }
    
    // Return user without password hash
    User authenticatedUser = {
        id: user.id,
        username: user.username,
        email: user.email,
        password_hash: "", // Don't return the hash
        created_at: user.created_at
    };
    
    io:println(string `User ${user.username} authenticated successfully`);
    return authenticatedUser;
}

// Get user by ID
public function getUserById(int userId) returns User|error {
    mysql:Client db = check getDbClient();
    
    stream<User, sql:Error?> userStream = db->query(`
        SELECT id, username, email, password_hash, created_at 
        FROM users 
        WHERE id = ${userId}
    `);
    
    User? user = ();
    check from User u in userStream
        do {
            user = u;
        };
    
    check userStream.close();
    
    if user is User {
        // Return user without password hash
        return {
            id: user.id,
            username: user.username,
            email: user.email,
            password_hash: "", // Don't return the hash
            created_at: user.created_at
        };
    }
    
    return error("User not found");
}

// Quiz Results Functions

// Save quiz result
public function saveQuizResult(int userId, int quizId, int score, int totalQuestions, decimal percentage) returns error? {
    mysql:Client db = check getDbClient();
    
    _ = check db->execute(`
        INSERT INTO quiz_results (user_id, quiz_id, score, total_questions, percentage)
        VALUES (${userId}, ${quizId}, ${score}, ${totalQuestions}, ${percentage})
    `);
    
    io:println(string `Quiz result saved for user ${userId}, quiz ${quizId}, score ${score}/${totalQuestions}`);
}

// Get user's quiz history
public function getUserQuizHistory(int userId) returns QuizResult[]|error {
    mysql:Client db = check getDbClient();
    
    stream<QuizResult, sql:Error?> resultStream = db->query(`
        SELECT qr.id, qr.user_id, qr.quiz_id, q.title as quiz_title, q.category,
               qr.score, qr.total_questions, qr.percentage, qr.completed_at
        FROM quiz_results qr
        JOIN quizzes q ON qr.quiz_id = q.id
        WHERE qr.user_id = ${userId}
        ORDER BY qr.completed_at DESC
    `);
    
    QuizResult[] results = [];
    check from QuizResult result in resultStream
        do {
            results.push(result);
        };
    
    check resultStream.close();
    return results;
}

// Get leaderboard by category
public function getLeaderboardByCategory(string? category = ()) returns LeaderboardEntry[]|error {
    mysql:Client db = check getDbClient();
    
    sql:ParameterizedQuery query;
    if category is string {
        query = `
            SELECT u.username, q.category,
                   AVG(qr.percentage) as average_score,
                   COUNT(qr.id) as total_quizzes,
                   MAX(qr.percentage) as best_score,
                   MAX(qr.completed_at) as latest_quiz_date
            FROM quiz_results qr
            JOIN users u ON qr.user_id = u.id
            JOIN quizzes q ON qr.quiz_id = q.id
            WHERE q.category = ${category}
            GROUP BY u.username, q.category
            ORDER BY average_score DESC, best_score DESC
            LIMIT 50
        `;
    } else {
        query = `
            SELECT u.username, q.category,
                   AVG(qr.percentage) as average_score,
                   COUNT(qr.id) as total_quizzes,
                   MAX(qr.percentage) as best_score,
                   MAX(qr.completed_at) as latest_quiz_date
            FROM quiz_results qr
            JOIN users u ON qr.user_id = u.id
            JOIN quizzes q ON qr.quiz_id = q.id
            GROUP BY u.username, q.category
            ORDER BY average_score DESC, best_score DESC
            LIMIT 50
        `;
    }
    
    stream<LeaderboardEntry, sql:Error?> resultStream = db->query(query);
    
    LeaderboardEntry[] entries = [];
    check from LeaderboardEntry entry in resultStream
        do {
            entries.push(entry);
        };
    
    check resultStream.close();
    return entries;
}

// Get all categories
public function getAllCategories() returns string[]|error {
    mysql:Client db = check getDbClient();
    
    stream<record {string category;}, sql:Error?> resultStream = db->query(`
        SELECT DISTINCT category
        FROM quizzes
        WHERE category IS NOT NULL
        ORDER BY category
    `);
    
    string[] categories = [];
    check from record {string category;} cat in resultStream
        do {
            categories.push(cat.category);
        };
    
    check resultStream.close();
    return categories;
}

// Get overall leaderboard (top performers across all categories)
public function getOverallLeaderboard() returns LeaderboardEntry[]|error {
    mysql:Client db = check getDbClient();
    
    stream<LeaderboardEntry, sql:Error?> resultStream = db->query(`
        SELECT u.username, 'Overall' as category,
               AVG(qr.percentage) as average_score,
               COUNT(qr.id) as total_quizzes,
               MAX(qr.percentage) as best_score,
               MAX(qr.completed_at) as latest_quiz_date
        FROM quiz_results qr
        JOIN users u ON qr.user_id = u.id
        GROUP BY u.username
        ORDER BY average_score DESC, best_score DESC
        LIMIT 20
    `);
    
    LeaderboardEntry[] entries = [];
    check from LeaderboardEntry entry in resultStream
        do {
            entries.push(entry);
        };
    
    check resultStream.close();
    return entries;
}

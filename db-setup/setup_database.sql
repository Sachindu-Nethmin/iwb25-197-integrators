-- MaterialQuiz Database Setup Script
-- This script creates the complete database schema for the MaterialQuiz application
-- Run this script in your MySQL database to set up all required tables and relationships

-- ====================================================================
-- DATABASE CREATION
-- ====================================================================

-- Create database (if it doesn't exist)
CREATE DATABASE IF NOT EXISTS material_quiz 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE material_quiz;

-- ====================================================================
-- TABLE CREATION
-- ====================================================================

-- Users table for authentication and user management
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_email (email)
);

-- Quizzes table to store quiz metadata
CREATE TABLE IF NOT EXISTS quizzes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) DEFAULT 'General',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_created_at (created_at)
);

-- Questions table to store individual quiz questions
CREATE TABLE IF NOT EXISTS questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question TEXT NOT NULL,
    option_a VARCHAR(500) NOT NULL,
    option_b VARCHAR(500) NOT NULL,
    option_c VARCHAR(500) NOT NULL,
    option_d VARCHAR(500) NOT NULL,
    correct_answer CHAR(1) NOT NULL CHECK (correct_answer IN ('a', 'b', 'c', 'd')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Junction table to link quizzes with questions (many-to-many relationship)
CREATE TABLE IF NOT EXISTS quiz_questions (
    quiz_id INT NOT NULL,
    question_id INT NOT NULL,
    PRIMARY KEY (quiz_id, question_id),
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

-- Quiz results table to store user quiz attempts and scores
CREATE TABLE IF NOT EXISTS quiz_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    quiz_id INT NOT NULL,
    score INT NOT NULL,
    total_questions INT NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_quiz_id (quiz_id),
    INDEX idx_completed_at (completed_at),
    INDEX idx_percentage (percentage)
);

-- ====================================================================
-- SAMPLE DATA INSERTION (OPTIONAL)
-- ====================================================================

-- Insert sample categories of quizzes
INSERT IGNORE INTO quizzes (title, description, category) VALUES 
('Introduction to Mathematics', 'Basic mathematical concepts and operations', 'Mathematics'),
('World History Basics', 'Fundamental concepts in world history', 'History'),
('Elementary Science', 'Basic scientific principles and concepts', 'Science'),
('English Grammar Fundamentals', 'Core grammar rules and usage', 'English'),
('Computer Science Basics', 'Introduction to programming and algorithms', 'Computer Science');

-- Insert sample questions for Mathematics quiz
INSERT IGNORE INTO questions (question, option_a, option_b, option_c, option_d, correct_answer) VALUES 
('What is 2 + 2?', '3', '4', '5', '6', 'b'),
('What is the square root of 16?', '2', '3', '4', '5', 'c'),
('What is 10 × 5?', '45', '50', '55', '60', 'b');

-- Insert sample questions for Science quiz
INSERT IGNORE INTO questions (question, option_a, option_b, option_c, option_d, correct_answer) VALUES 
('What is the chemical symbol for water?', 'H2O', 'CO2', 'O2', 'H2SO4', 'a'),
('How many planets are in our solar system?', '7', '8', '9', '10', 'b'),
('What gas do plants absorb from the atmosphere?', 'Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen', 'c');

-- Link questions to quizzes (Mathematics quiz - assuming quiz_id 1)
INSERT IGNORE INTO quiz_questions (quiz_id, question_id) VALUES 
(1, 1), (1, 2), (1, 3);

-- Link questions to quizzes (Science quiz - assuming quiz_id 3)
INSERT IGNORE INTO quiz_questions (quiz_id, question_id) VALUES 
(3, 4), (3, 5), (3, 6);

-- ====================================================================
-- SAMPLE USER (OPTIONAL - FOR TESTING)
-- ====================================================================

-- Insert a test user (password is 'password123' hashed with bcrypt)
-- Note: In production, passwords should be properly hashed by the application
INSERT IGNORE INTO users (username, email, password_hash) VALUES 
('testuser', 'test@example.com', '$2b$10$examplehashedpasswordhere123456789');

-- ====================================================================
-- VERIFICATION QUERIES
-- ====================================================================

-- Show all created tables
SHOW TABLES;

-- Display table structures
DESCRIBE users;
DESCRIBE quizzes;
DESCRIBE questions;
DESCRIBE quiz_questions;
DESCRIBE quiz_results;

-- Show sample data counts
SELECT 'Users' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'Quizzes' as table_name, COUNT(*) as record_count FROM quizzes
UNION ALL
SELECT 'Questions' as table_name, COUNT(*) as record_count FROM questions
UNION ALL
SELECT 'Quiz Questions' as table_name, COUNT(*) as record_count FROM quiz_questions
UNION ALL
SELECT 'Quiz Results' as table_name, COUNT(*) as record_count FROM quiz_results;

-- ====================================================================
-- USEFUL QUERIES FOR DEVELOPMENT
-- ====================================================================

-- View all quizzes with their question counts
SELECT 
    q.id,
    q.title,
    q.category,
    COUNT(qq.question_id) as question_count,
    q.created_at
FROM quizzes q
LEFT JOIN quiz_questions qq ON q.id = qq.quiz_id
GROUP BY q.id, q.title, q.category, q.created_at
ORDER BY q.created_at DESC;

-- View quiz results with user and quiz information
SELECT 
    qr.id,
    u.username,
    q.title as quiz_title,
    q.category,
    qr.score,
    qr.total_questions,
    qr.percentage,
    qr.completed_at
FROM quiz_results qr
JOIN users u ON qr.user_id = u.id
JOIN quizzes q ON qr.quiz_id = q.id
ORDER BY qr.completed_at DESC;

-- ====================================================================
-- DATABASE SETUP COMPLETE
-- ====================================================================

SELECT 'MaterialQuiz database setup completed successfully!' as status;

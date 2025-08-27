import ballerina/io;

public function createSampleQuizzes() returns error? {
    // Create sample quiz 1 - Machine Learning
    int quiz1Id = check createQuiz("Machine Learning Fundamentals", "Test your knowledge of ML basics and concepts", "Machine Learning");
    
    // Insert sample questions for quiz 1
    Question[] quiz1Questions = [
        {
            question: "What is the primary focus of Machine Learning (ML)?",
            option_a: "Programming computers with explicit instructions",
            option_b: "Building systems that learn from data and improve performance over time",
            option_c: "Developing hardware components for computer systems",
            option_d: "Creating static models for data storage",
            correct_answer: "b"
        },
        {
            question: "Which of the following is NOT an application powered by Machine Learning?",
            option_a: "Spam detection in emails",
            option_b: "Product recommendations on e-commerce platforms",
            option_c: "Manually writing code for a specific task",
            option_d: "Fraud detection in banking",
            correct_answer: "c"
        },
        {
            question: "What type of Machine Learning involves training models on labeled data?",
            option_a: "Unsupervised learning",
            option_b: "Reinforcement learning",
            option_c: "Supervised learning",
            option_d: "Deep learning",
            correct_answer: "c"
        }
    ];
    
    int[] quiz1QuestionIds = [];
    foreach Question q in quiz1Questions {
        int questionId = check insertQuestion(q);
        quiz1QuestionIds.push(questionId);
    }
    
    check addQuestionsToQuiz(quiz1Id, quiz1QuestionIds);
    
    // Create sample quiz 2 - Data Science
    int quiz2Id = check createQuiz("Data Science Basics", "Fundamental concepts in data science and analytics", "Data Science");
    
    Question[] quiz2Questions = [
        {
            question: "What is the first step in the data science process?",
            option_a: "Data modeling",
            option_b: "Data collection and problem definition",
            option_c: "Data visualization",
            option_d: "Model deployment",
            correct_answer: "b"
        },
        {
            question: "Which of the following is a measure of central tendency?",
            option_a: "Standard deviation",
            option_b: "Variance",
            option_c: "Mean",
            option_d: "Range",
            correct_answer: "c"
        }
    ];
    
    int[] quiz2QuestionIds = [];
    foreach Question q in quiz2Questions {
        int questionId = check insertQuestion(q);
        quiz2QuestionIds.push(questionId);
    }
    
    check addQuestionsToQuiz(quiz2Id, quiz2QuestionIds);
    
    // Create sample quiz 3 - Programming
    int quiz3Id = check createQuiz("Programming Basics", "Test your programming fundamentals", "Programming");
    
    Question[] quiz3Questions = [
        {
            question: "What is a variable in programming?",
            option_a: "A fixed value that cannot be changed",
            option_b: "A container for storing data values",
            option_c: "A type of loop structure",
            option_d: "A debugging tool",
            correct_answer: "b"
        },
        {
            question: "Which of the following is NOT a programming paradigm?",
            option_a: "Object-Oriented Programming",
            option_b: "Functional Programming",
            option_c: "Procedural Programming",
            option_d: "Database Programming",
            correct_answer: "d"
        }
    ];
    
    int[] quiz3QuestionIds = [];
    foreach Question q in quiz3Questions {
        int questionId = check insertQuestion(q);
        quiz3QuestionIds.push(questionId);
    }
    
    check addQuestionsToQuiz(quiz3Id, quiz3QuestionIds);
    
    // Create sample quiz 4 - Mathematics
    int quiz4Id = check createQuiz("Mathematics Fundamentals", "Basic mathematical concepts", "Mathematics");
    
    Question[] quiz4Questions = [
        {
            question: "What is the derivative of x²?",
            option_a: "x",
            option_b: "2x",
            option_c: "x²/2",
            option_d: "2x²",
            correct_answer: "b"
        },
        {
            question: "What is the value of π (pi) approximately?",
            option_a: "3.14159",
            option_b: "2.71828",
            option_c: "1.41421",
            option_d: "1.61803",
            correct_answer: "a"
        }
    ];
    
    int[] quiz4QuestionIds = [];
    foreach Question q in quiz4Questions {
        int questionId = check insertQuestion(q);
        quiz4QuestionIds.push(questionId);
    }
    
    check addQuestionsToQuiz(quiz4Id, quiz4QuestionIds);
    
    io:println("Sample quizzes created successfully!");
    io:println(string `Quiz 1 ID: ${quiz1Id} with ${quiz1QuestionIds.length()} questions (Machine Learning)`);
    io:println(string `Quiz 2 ID: ${quiz2Id} with ${quiz2QuestionIds.length()} questions (Data Science)`);
    io:println(string `Quiz 3 ID: ${quiz3Id} with ${quiz3QuestionIds.length()} questions (Programming)`);
    io:println(string `Quiz 4 ID: ${quiz4Id} with ${quiz4QuestionIds.length()} questions (Mathematics)`);
}

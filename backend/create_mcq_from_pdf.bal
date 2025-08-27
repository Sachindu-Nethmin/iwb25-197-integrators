import ballerina/http;
import ballerina/io;
import anjanasupun/pdf;

string path = "ML.pdf";
configurable string GEMINI_API_KEY = ?;

// Generate MCQ from PDF and save to database
public function generateAndSaveQuizFromPdf(string pdfPath, string quizTitle, string? quizDescription = ()) returns int|error {
    // Initialize database
    check initDatabase();
    check createTables();
    
    // Read PDF content
    int|float|decimal|string|boolean readFileResult = check pdf:readFile(pdfPath);
    
    // Generate MCQ using Gemini API
    string mcqResponse = check generateMCQFromContent(readFileResult.toString());
    
    // Clean the response by removing markdown code blocks if present
    string cleanedResponse = mcqResponse;
    if (cleanedResponse.includes("```json")) {
        int? startIdx = cleanedResponse.indexOf("```json");
        int? endIdx = cleanedResponse.lastIndexOf("```");
        if (startIdx is int && endIdx is int && endIdx > startIdx) {
            int startIndex = startIdx + 7;
            cleanedResponse = cleanedResponse.substring(startIndex, endIdx).trim();
        }
    }
    
    // Parse the JSON response
    json parsedMcq = check cleanedResponse.fromJsonString();
    
    // Insert questions into database
    int[] questionIds = check insertQuestionsFromJson(parsedMcq);
    
    // Create quiz
    int quizId = check createQuiz(quizTitle, quizDescription);
    
    // Associate questions with quiz
    check addQuestionsToQuiz(quizId, questionIds);
    
    io:println(string `Quiz "${quizTitle}" created successfully with ID: ${quizId}`);
    io:println(string `Added ${questionIds.length()} questions to the quiz`);
    
    return quizId;
}

// Generate MCQ using Gemini API
function generateMCQFromContent(string content) returns string|error {
    string apiKey = GEMINI_API_KEY;
    final string GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

    // Create the HTTP client
    http:Client geminiClient = check new (GEMINI_URL);

    // Create request payload
    json payload = 
    {
        "contents": [
            {
                "parts": [
                { "text": string `Create 5 MCQs based on the following content:\n${content}\n\nRespond ONLY in JSON format as: {"questions": [
{
    "question": "What is the main topic of the assignment?",
    "options": [
        "a) The history of mobile phones",
        "b) The impact of mobile phones on student productivity", 
        "c) The benefits of online learning",
        "d) The disadvantages of social media"
    ]
}], 
"answers": ["b"]}. Do not include any introductions or explanations.` }
                ]
            }
        ]
    };

    // Create a request object
    http:Request req = new;
    req.setJsonPayload(payload);
    req.setHeader("Content-Type", "application/json");
    req.setHeader("x-goog-api-key", apiKey);

    // Send the POST request
    http:Response resp = check geminiClient->post("", req);
    json response = check resp.getJsonPayload();
    json candidates = check response.candidates;
    json candidate = (<json[]>candidates)[0];
    json content_ = check candidate.content;
    json parts = check content_.parts;
    json part = (<json[]>parts)[0];
    json text = check part.text;
    string textContent = text.toString();
    
    return textContent;
}

public function main() returns error? {
    io:println("MaterialQuiz Backend is starting...");
    io:println("API will be available at: http://localhost:9090/api");
    io:println("Frontend is running at: http://localhost:3000");
    io:println("Use Ctrl+C to stop the service");
    
    // Initialize database
    check initDatabase();
    check createTables();
    
    // Create sample quizzes if they don't exist
    Quiz[]|error existingQuizzes = getAllQuizzes();
    if existingQuizzes is Quiz[] && existingQuizzes.length() == 0 {
        io:println("Creating sample quizzes...");
        error? result = createSampleQuizzes();
        if result is error {
            io:println("Warning: Failed to create sample quizzes: " + result.message());
        }
    } else {
        io:println("Existing quizzes found in database");
        // Let's check if they have questions and recreate if needed
        if existingQuizzes is Quiz[] {
            foreach Quiz quiz in existingQuizzes {
                int quizId = quiz.id ?: 0;
                if quizId > 0 {
                    Question[]|error questions = getQuizQuestions(quizId);
                    if questions is Question[] && questions.length() == 0 {
                        io:println(string `Quiz "${quiz.title}" has no questions, recreating sample quizzes...`);
                        error? result = createSampleQuizzes();
                        if result is error {
                            io:println("Warning: Failed to create sample quizzes: " + result.message());
                        }
                        break;
                    }
                }
            }
        }
    }
    
    io:println("Database initialized successfully");
    io:println("Backend is ready to serve requests");
}

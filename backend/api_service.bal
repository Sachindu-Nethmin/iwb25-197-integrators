import ballerina/http;
import ballerina/mime;

// CORS configuration for frontend
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID", "Content-Type"],
        allowMethods: ["GET", "POST", "OPTIONS"]
    }
}
service /api on new http:Listener(9090) {

    # Get all quizzes
    # + return - List of all quizzes or error
    resource function get quizzes() returns json|error {
        // Initialize database connection if not already done
        error? initResult = initDatabase();
        if initResult is error {
            return initResult;
        }

        // Get all quizzes from database
        Quiz[]|error quizzes = getAllQuizzes();
        if quizzes is error {
            return error("Failed to fetch quizzes: " + quizzes.message());
        }

        return quizzes.toJson();
    }

    # Get quiz by ID with questions
    # + id - Quiz ID
    # + return - Quiz data with questions or error
    resource function get quiz/[int id]() returns json|error {
        // Initialize database connection if not already done
        error? initResult = initDatabase();
        if initResult is error {
            return initResult;
        }

        // Get quiz questions
        Question[]|error questions = getQuizQuestions(id);
        if questions is error {
            return error("Failed to fetch quiz questions: " + questions.message());
        }

        // Get quiz info (we'll need to create this function)
        Quiz|error quizInfo = getQuizById(id);
        if quizInfo is error {
            return error("Quiz not found: " + quizInfo.message());
        }

        json quizData = {
            "id": quizInfo.id,
            "title": quizInfo.title,
            "description": quizInfo.description,
            "questions": questions.toJson()
        };

        return quizData;
    }

    # Generate new quiz from PDF
    # + caller - HTTP caller
    # + req - HTTP request with PDF path and quiz details
    # + return - Error if any
    resource function post generateQuiz(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is error {
            json errorResponse = {"error": "Invalid request payload"};
            check caller->respond(errorResponse);
            return;
        }

        json|error pdfPathJson = payload.pdfPath;
        json|error titleJson = payload.title;
        json|error descriptionJson = payload.description;
        
        if pdfPathJson is error || titleJson is error {
            json errorResponse = {"error": "Missing required fields: pdfPath and title"};
            check caller->respond(errorResponse);
            return;
        }
        
        string pdfPath = pdfPathJson.toString();
        string title = titleJson.toString();
        string? description = descriptionJson is error ? () : descriptionJson.toString();

        int|error quizId = generateAndSaveQuizFromPdf(pdfPath, title, description);
        if quizId is error {
            json errorResponse = {"error": "Failed to generate quiz: " + quizId.message()};
            check caller->respond(errorResponse);
            return;
        }

        json response = {
            "success": true,
            "quizId": quizId,
            "message": "Quiz generated successfully"
        };
        check caller->respond(response);
    }

    # Upload PDF file and generate quiz
    # + caller - HTTP caller
    # + req - HTTP request with multipart form data
    # + return - Error if any
    resource function post uploadPdf(http:Caller caller, http:Request req) returns error? {
        mime:Entity[]|error bodyParts = req.getBodyParts();
        if bodyParts is error {
            json errorResponse = {"error": "Failed to parse multipart data"};
            check caller->respond(errorResponse);
            return;
        }

        string title = "";
        string description = "";
        byte[]? pdfBytes = ();
        string fileName = "";

        // Parse multipart form data
        foreach mime:Entity part in bodyParts {
            mime:ContentDisposition? contentDisposition = part.getContentDisposition();
            if contentDisposition is mime:ContentDisposition {
                string fieldName = contentDisposition.name;
                
                if fieldName == "title" {
                    string|error titleValue = part.getText();
                    if titleValue is string {
                        title = titleValue;
                    }
                } else if fieldName == "description" {
                    string|error descValue = part.getText();
                    if descValue is string {
                        description = descValue;
                    }
                } else if fieldName == "pdf" {
                    string? fileNameFromHeader = contentDisposition.fileName;
                    fileName = fileNameFromHeader is string ? fileNameFromHeader : "uploaded.pdf";
                    byte[]|error fileBytes = part.getByteArray();
                    if fileBytes is byte[] {
                        pdfBytes = fileBytes;
                    }
                }
            }
        }

        if title.trim() == "" {
            json errorResponse = {"error": "Title is required"};
            check caller->respond(errorResponse);
            return;
        }

        if pdfBytes is () {
            json errorResponse = {"error": "PDF file is required"};
            check caller->respond(errorResponse);
            return;
        }

        // Save uploaded file temporarily
        string uploadDir = "uploads";
        check createDirectoryIfNotExists(uploadDir);
        
        string filePath = uploadDir + "/" + fileName;
        check saveUploadedFile(filePath, pdfBytes);

        // Generate quiz from uploaded PDF
        int|error quizId = generateAndSaveQuizFromPdf(filePath, title, description);
        
        // Clean up uploaded file
        check deleteFile(filePath);

        if quizId is error {
            json errorResponse = {"error": "Failed to generate quiz: " + quizId.message()};
            check caller->respond(errorResponse);
            return;
        }

        json response = {
            "success": true,
            "quizId": quizId,
            "message": "Quiz generated successfully from uploaded PDF",
            "fileName": fileName
        };
        check caller->respond(response);
    }

    # Handle preflight OPTIONS requests for CORS
    # + caller - HTTP caller
    # + return - Error if any
    resource function options uploadPdf(http:Caller caller) returns error? {
        http:Response response = new;
        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        check caller->respond(response);
    }

    # User registration (sign up)
    # + caller - HTTP caller
    # + req - HTTP request with user registration data
    # + return - Error if any
    resource function post register(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is error {
            json errorResponse = {"error": "Invalid request payload", "success": false};
            check caller->respond(errorResponse);
            return;
        }

        json|error usernameJson = payload.username;
        json|error emailJson = payload.email;
        json|error passwordJson = payload.password;
        
        if usernameJson is error || emailJson is error || passwordJson is error {
            json errorResponse = {"error": "Missing required fields: username, email, password", "success": false};
            check caller->respond(errorResponse);
            return;
        }
        
        string username = usernameJson.toString();
        string email = emailJson.toString();
        string password = passwordJson.toString();

        // Validate input
        if username.trim() == "" || email.trim() == "" || password.trim() == "" {
            json errorResponse = {"error": "All fields are required", "success": false};
            check caller->respond(errorResponse);
            return;
        }

        if password.length() < 6 {
            json errorResponse = {"error": "Password must be at least 6 characters long", "success": false};
            check caller->respond(errorResponse);
            return;
        }

        // Initialize database
        error? initResult = initDatabase();
        if initResult is error {
            json errorResponse = {"error": "Database connection failed", "success": false};
            check caller->respond(errorResponse);
            return;
        }

        int|error userId = createUser(username, email, password);
        if userId is error {
            json errorResponse = {"error": userId.message(), "success": false};
            check caller->respond(errorResponse);
            return;
        }

        json response = {
            "success": true,
            "message": "User registered successfully",
            "userId": userId
        };
        check caller->respond(response);
    }

    # User authentication (sign in)
    # + caller - HTTP caller
    # + req - HTTP request with login credentials
    # + return - Error if any
    resource function post login(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is error {
            json errorResponse = {"error": "Invalid request payload", "success": false};
            check caller->respond(errorResponse);
            return;
        }

        json|error usernameOrEmailJson = payload.usernameOrEmail;
        json|error passwordJson = payload.password;
        
        if usernameOrEmailJson is error || passwordJson is error {
            json errorResponse = {"error": "Missing required fields: usernameOrEmail, password", "success": false};
            check caller->respond(errorResponse);
            return;
        }
        
        string usernameOrEmail = usernameOrEmailJson.toString();
        string password = passwordJson.toString();

        // Validate input
        if usernameOrEmail.trim() == "" || password.trim() == "" {
            json errorResponse = {"error": "All fields are required", "success": false};
            check caller->respond(errorResponse);
            return;
        }

        // Initialize database
        error? initResult = initDatabase();
        if initResult is error {
            json errorResponse = {"error": "Database connection failed", "success": false};
            check caller->respond(errorResponse);
            return;
        }

        User|error user = authenticateUser(usernameOrEmail, password);
        if user is error {
            json errorResponse = {"error": user.message(), "success": false};
            check caller->respond(errorResponse);
            return;
        }

        json response = {
            "success": true,
            "message": "Login successful",
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "created_at": user.created_at
            }
        };
        check caller->respond(response);
    }

    # Handle preflight OPTIONS requests for authentication endpoints
    # + caller - HTTP caller
    # + return - Error if any
    resource function options register(http:Caller caller) returns error? {
        http:Response response = new;
        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        check caller->respond(response);
    }

    # Handle preflight OPTIONS requests for authentication endpoints
    # + caller - HTTP caller
    # + return - Error if any
    resource function options login(http:Caller caller) returns error? {
        http:Response response = new;
        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        check caller->respond(response);
    }

    # Save quiz result
    # + caller - HTTP caller
    # + req - HTTP request with quiz result data
    # + return - Error if any
    resource function post saveResult(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        if payload is error {
            json errorResponse = {"error": "Invalid request payload"};
            check caller->respond(errorResponse);
            return;
        }

        json|error userIdJson = payload.userId;
        json|error quizIdJson = payload.quizId;
        json|error scoreJson = payload.score;
        json|error totalQuestionsJson = payload.totalQuestions;
        json|error percentageJson = payload.percentage;

        if userIdJson is error || quizIdJson is error || scoreJson is error || 
           totalQuestionsJson is error || percentageJson is error {
            json errorResponse = {"error": "Missing required fields"};
            check caller->respond(errorResponse);
            return;
        }

        int userId = check int:fromString(userIdJson.toString());
        int quizId = check int:fromString(quizIdJson.toString());
        int score = check int:fromString(scoreJson.toString());
        int totalQuestions = check int:fromString(totalQuestionsJson.toString());
        decimal percentage = check decimal:fromString(percentageJson.toString());

        error? result = saveQuizResult(userId, quizId, score, totalQuestions, percentage);
        if result is error {
            json errorResponse = {"error": "Failed to save quiz result: " + result.message()};
            check caller->respond(errorResponse);
            return;
        }

        json response = {"success": true, "message": "Quiz result saved successfully"};
        check caller->respond(response);
    }

    # Get leaderboard by category
    # + category - Category name (optional)
    # + return - Leaderboard data or error
    resource function get leaderboard(string? category = ()) returns json|error {
        error? initResult = initDatabase();
        if initResult is error {
            return initResult;
        }

        LeaderboardEntry[]|error leaderboard = getLeaderboardByCategory(category);
        if leaderboard is error {
            return error("Failed to fetch leaderboard: " + leaderboard.message());
        }

        return leaderboard.toJson();
    }

    # Get overall leaderboard
    # + return - Overall leaderboard data or error
    resource function get leaderboard/overall() returns json|error {
        error? initResult = initDatabase();
        if initResult is error {
            return initResult;
        }

        LeaderboardEntry[]|error leaderboard = getOverallLeaderboard();
        if leaderboard is error {
            return error("Failed to fetch overall leaderboard: " + leaderboard.message());
        }

        return leaderboard.toJson();
    }

    # Get all categories
    # + return - List of categories or error
    resource function get categories() returns json|error {
        error? initResult = initDatabase();
        if initResult is error {
            return initResult;
        }

        string[]|error categories = getAllCategories();
        if categories is error {
            return error("Failed to fetch categories: " + categories.message());
        }

        return categories.toJson();
    }

    # Get user's quiz history
    # + userId - User ID
    # + return - User's quiz history or error
    resource function get user/[int userId]/history() returns json|error {
        error? initResult = initDatabase();
        if initResult is error {
            return initResult;
        }

        QuizResult[]|error history = getUserQuizHistory(userId);
        if history is error {
            return error("Failed to fetch user history: " + history.message());
        }

        return history.toJson();
    }
}

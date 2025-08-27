import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // Connect to Ballerina backend
    const response = await fetch('http://localhost:9090/api/quizzes');
    
    if (!response.ok) {
      throw new Error(`Backend responded with ${response.status}`);
    }
    
    const quizzes = await response.json();
    return NextResponse.json(quizzes);
  } catch (error) {
    console.error('Error fetching quizzes:', error);
    
    // Fallback to mock data if backend is not available
    const mockQuizzes = [
      {
        id: 1,
        title: "Machine Learning Fundamentals",
        description: "Test your knowledge of ML basics and concepts",
        created_at: "2024-01-15T10:00:00Z"
      },
      {
        id: 2,
        title: "Data Science Basics",
        description: "Fundamental concepts in data science and analytics",
        created_at: "2024-01-10T14:30:00Z"
      }
    ];

    return NextResponse.json(mockQuizzes);
  }
}

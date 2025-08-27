import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const quizId = params.id;
    
    // Connect to Ballerina backend
    const response = await fetch(`http://localhost:9090/api/quiz/${quizId}`);
    
    if (!response.ok) {
      throw new Error('Failed to fetch from backend');
    }
    
    const quizData = await response.json();
    return NextResponse.json(quizData);
  } catch (error) {
    console.error('Error fetching quiz:', error);
    
    // Fallback to mock data if backend is not available
    const quizId = params.id;
    const mockQuizData = {
      id: parseInt(quizId),
      title: quizId === '1' ? "Machine Learning Fundamentals" : "Data Science Quiz",
      description: "Test your knowledge with this comprehensive quiz",
      questions: [
        {
          id: 1,
          question: "What is the primary focus of Machine Learning (ML)?",
          option_a: "Programming computers with explicit instructions",
          option_b: "Building systems that learn from data and improve performance over time",
          option_c: "Developing hardware components for computer systems",
          option_d: "Creating static models for data storage",
          correct_answer: "b"
        },
        {
          id: 2,
          question: "Which of the following is NOT an application powered by Machine Learning?",
          option_a: "Spam detection in emails",
          option_b: "Product recommendations on e-commerce platforms",
          option_c: "Manually writing code for a specific task",
          option_d: "Fraud detection in banking",
          correct_answer: "c"
        },
        {
          id: 3,
          question: "What type of Machine Learning involves training models on labeled data?",
          option_a: "Unsupervised learning",
          option_b: "Reinforcement learning",
          option_c: "Supervised learning",
          option_d: "Deep learning",
          correct_answer: "c"
        },
        {
          id: 4,
          question: "What is a key challenge associated with Machine Learning?",
          option_a: "The lack of available programming languages",
          option_b: "The need for high-quality data and computational resources",
          option_c: "The simplicity of the algorithms involved",
          option_d: "The lack of potential applications",
          correct_answer: "b"
        },
        {
          id: 5,
          question: "What allows systems to learn through trial and error by receiving rewards or penalties for their actions?",
          option_a: "Supervised Learning",
          option_b: "Unsupervised Learning",
          option_c: "Reinforcement Learning",
          option_d: "Deep Learning",
          correct_answer: "c"
        }
      ]
    };

    return NextResponse.json(mockQuizData);
  }
}

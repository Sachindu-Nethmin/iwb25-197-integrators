'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import axios from 'axios';
import Navigation from '@/components/Navigation';

interface Question {
  id: number;
  question: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  correct_answer: string;
}

interface QuizData {
  id: number;
  title: string;
  description?: string;
  questions: Question[];
}

export default function QuizPage() {
  const params = useParams();
  const router = useRouter();
  const quizId = params.id;

  const [quizData, setQuizData] = useState<QuizData | null>(null);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<{ [key: number]: string }>({});
  const [showResults, setShowResults] = useState(false);
  const [score, setScore] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (quizId) {
      fetchQuizData();
    }
  }, [quizId]);

  const fetchQuizData = async () => {
    try {
      // Use Next.js API route which handles backend connection
      const response = await axios.get(`/api/quiz/${quizId}`);
      setQuizData(response.data);
    } catch (err) {
      setError('Failed to fetch quiz data. Make sure the backend is running.');
      console.error('Error fetching quiz:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAnswerSelect = (questionId: number, answer: string) => {
    setAnswers(prev => ({
      ...prev,
      [questionId]: answer
    }));
  };

  const handleNext = () => {
    if (quizData && currentQuestion < quizData.questions.length - 1) {
      setCurrentQuestion(prev => prev + 1);
    }
  };

  const handlePrevious = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(prev => prev - 1);
    }
  };

  const handleSubmit = async () => {
    if (!quizData) return;

    let correctAnswers = 0;
    quizData.questions.forEach(question => {
      if (answers[question.id] === question.correct_answer) {
        correctAnswers++;
      }
    });

    const finalScore = (correctAnswers / quizData.questions.length) * 100;
    setScore(finalScore);
    setShowResults(true);

    // Save results to localStorage
    const result = {
      quizId: quizData.id,
      quizTitle: quizData.title,
      score: finalScore,
      correctAnswers,
      totalQuestions: quizData.questions.length,
      answers,
      completedAt: new Date().toISOString()
    };

    const savedResults = JSON.parse(localStorage.getItem('quizResults') || '[]');
    savedResults.push(result);
    localStorage.setItem('quizResults', JSON.stringify(savedResults));

    // Save to backend leaderboard (if user is logged in)
    try {
      const userId = localStorage.getItem('userId'); // Assuming we store user ID on login
      if (userId) {
        const leaderboardData = {
          userId: parseInt(userId),
          quizId: quizData.id,
          score: correctAnswers,
          totalQuestions: quizData.questions.length,
          percentage: finalScore
        };

        await axios.post('/api/leaderboard', leaderboardData);
        console.log('Result saved to leaderboard');
      }
    } catch (error) {
      console.error('Failed to save result to leaderboard:', error);
      // Don't show error to user as the quiz is still completed successfully
    }
    savedResults.push(result);
    localStorage.setItem('quizResults', JSON.stringify(savedResults));
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <Navigation />
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading quiz...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error || !quizData) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <Navigation />
        <div className="flex items-center justify-center h-96">
          <div className="bg-white rounded-lg shadow-lg p-8 max-w-md w-full mx-4">
            <h2 className="text-xl font-semibold text-red-600 mb-4">Error</h2>
            <p className="text-gray-600 mb-6">{error || 'Quiz not found'}</p>
            <button
              onClick={() => router.push('/quizzes')}
              className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Back to Quizzes
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (showResults) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <Navigation />
        <div className="flex items-center justify-center py-8">
          <div className="bg-white rounded-lg shadow-lg p-8 max-w-2xl w-full mx-4">
            <div className="text-center">
            <h2 className="text-3xl font-bold text-gray-800 mb-4">Quiz Complete!</h2>
            <div className="mb-6">
              <div className={`text-6xl font-bold mb-2 ${score >= 70 ? 'text-green-600' : score >= 50 ? 'text-yellow-600' : 'text-red-600'}`}>
                {Math.round(score)}%
              </div>
              <p className="text-gray-600">
                You got {Object.values(answers).filter((answer, index) => answer === quizData.questions[index]?.correct_answer).length} out of {quizData.questions.length} questions correct
              </p>
            </div>
            
            <div className="flex gap-4 justify-center">
              <button
                onClick={() => router.push('/quizzes')}
                className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Take Another Quiz
              </button>
              <button
                onClick={() => router.push('/results')}
                className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors"
              >
                View All Results
              </button>
            </div>
          </div>
        </div>
        </div>
      </div>
    );
  }

  const currentQ = quizData.questions[currentQuestion];
  const progress = ((currentQuestion + 1) / quizData.questions.length) * 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <Navigation />
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
            <h1 className="text-2xl font-bold text-gray-800 mb-2">{quizData.title}</h1>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">
                Question {currentQuestion + 1} of {quizData.questions.length}
              </span>
              <span className="text-gray-600">{Math.round(progress)}% Complete</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
              <div 
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${progress}%` }}
              ></div>
            </div>
          </div>

          {/* Question */}
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-xl font-bold text-gray-900 mb-6 leading-relaxed">
              {currentQ.question}
            </h2>

            <div className="space-y-3">
              {[
                { key: 'a', text: currentQ.option_a },
                { key: 'b', text: currentQ.option_b },
                { key: 'c', text: currentQ.option_c },
                { key: 'd', text: currentQ.option_d }
              ].map((option) => (
                <label
                  key={option.key}
                  className={`block p-4 rounded-lg border-2 cursor-pointer transition-colors ${
                    answers[currentQ.id] === option.key
                      ? 'border-blue-600 bg-blue-50'
                      : 'border-gray-300 hover:border-gray-400 hover:bg-gray-50'
                  }`}
                >
                  <input
                    type="radio"
                    name={`question-${currentQ.id}`}
                    value={option.key}
                    checked={answers[currentQ.id] === option.key}
                    onChange={() => handleAnswerSelect(currentQ.id, option.key)}
                    className="sr-only"
                  />
                  <div className="flex items-center">
                    <div className={`w-5 h-5 rounded-full border-2 mr-4 flex-shrink-0 ${
                      answers[currentQ.id] === option.key
                        ? 'border-blue-600 bg-blue-600'
                        : 'border-gray-400'
                    }`}>
                      {answers[currentQ.id] === option.key && (
                        <div className="w-2 h-2 bg-white rounded-full mx-auto mt-1.5"></div>
                      )}
                    </div>
                    <span className="text-gray-900 font-medium text-base leading-relaxed">{option.text}</span>
                  </div>
                </label>
              ))}
            </div>

            {/* Navigation */}
            <div className="flex justify-between mt-8">
              <button
                onClick={handlePrevious}
                disabled={currentQuestion === 0}
                className="px-6 py-3 rounded-lg border-2 border-gray-400 text-gray-900 font-semibold hover:bg-gray-50 hover:border-gray-500 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>

              {currentQuestion === quizData.questions.length - 1 ? (
                <button
                  onClick={handleSubmit}
                  disabled={!answers[currentQ.id]}
                  className="px-6 py-3 rounded-lg bg-green-600 text-white font-semibold hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Submit Quiz
                </button>
              ) : (
                <button
                  onClick={handleNext}
                  disabled={!answers[currentQ.id]}
                  className="px-6 py-3 rounded-lg bg-blue-600 text-white font-semibold hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Next
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import axios from 'axios';
import Navigation from '@/components/Navigation';


interface Quiz {
  id: number;
  title: string;
  description?: string;
  created_at: string;
}

interface QuizWithFormattedDate extends Quiz {
  created_at_formatted: string;
}

export default function QuizzesPage() {
  const [quizzes, setQuizzes] = useState<QuizWithFormattedDate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchQuizzes();
  }, []);

  const fetchQuizzes = async () => {
    try {
      // Fetch from local Next.js API route
      const response = await axios.get('/api/quizzes');
      // Format date on client only
      const quizzesWithDate = response.data.map((quiz: Quiz) => ({
        ...quiz,
        created_at_formatted: new Date(quiz.created_at).toLocaleDateString(),
      }));
      setQuizzes(quizzesWithDate);
    } catch (err) {
      setError('Failed to fetch quizzes. Make sure the backend is running.');
      console.error('Error fetching quizzes:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <Navigation />
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading quizzes...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <Navigation />
      <div className="container mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-3xl font-bold text-gray-800">Available Quizzes</h1>
          <Link 
            href="/"
            className="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors"
          >
            Back to Home
          </Link>
        </div>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}

        {quizzes.length === 0 && !error ? (
          <div className="bg-white rounded-lg shadow-lg p-8 text-center">
            <h2 className="text-xl font-semibold text-gray-800 mb-4">No Quizzes Available</h2>
            <p className="text-gray-600">There are currently no quizzes available. Check back later!</p>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {quizzes.map((quiz) => (
              <div key={quiz.id} className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
                <h3 className="text-xl font-semibold text-gray-800 mb-3">{quiz.title}</h3>
                {quiz.description && (
                  <p className="text-gray-600 mb-4">{quiz.description}</p>
                )}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">
                    Created: {quiz.created_at_formatted}
                  </span>
                  <Link
                    href={`/quiz/${quiz.id}`}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    Take Quiz
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Navigation from '@/components/Navigation';

interface QuizResult {
  quizId: number;
  quizTitle: string;
  score: number;
  correctAnswers: number;
  totalQuestions: number;
  answers: { [key: number]: string };
  completedAt: string;
}

export default function ResultsPage() {
  const [results, setResults] = useState<QuizResult[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load results from localStorage
    const savedResults = JSON.parse(localStorage.getItem('quizResults') || '[]');
    setResults(savedResults.sort((a: QuizResult, b: QuizResult) => 
      new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime()
    ));
    setLoading(false);
  }, []);

  const clearResults = () => {
    if (confirm('Are you sure you want to clear all results?')) {
      localStorage.removeItem('quizResults');
      setResults([]);
    }
  };

  const getScoreColor = (score: number) => {
    if (score >= 80) return 'text-green-600';
    if (score >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getScoreBadge = (score: number) => {
    if (score >= 90) return { text: 'Excellent', color: 'bg-green-100 text-green-800' };
    if (score >= 80) return { text: 'Good', color: 'bg-blue-100 text-blue-800' };
    if (score >= 60) return { text: 'Fair', color: 'bg-yellow-100 text-yellow-800' };
    return { text: 'Needs Improvement', color: 'bg-red-100 text-red-800' };
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <Navigation />
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading results...</p>
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
          <h1 className="text-3xl font-bold text-gray-800">Quiz Results</h1>
          <div className="flex gap-4">
            {results.length > 0 && (
              <button
                onClick={clearResults}
                className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
              >
                Clear All Results
              </button>
            )}
            <Link 
              href="/"
              className="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors"
            >
              Back to Home
            </Link>
          </div>
        </div>

        {results.length === 0 ? (
          <div className="bg-white rounded-lg shadow-lg p-8 text-center">
            <h2 className="text-xl font-semibold text-gray-800 mb-4">No Results Yet</h2>
            <p className="text-gray-600 mb-6">You haven't completed any quizzes yet.</p>
            <Link
              href="/quizzes"
              className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Take Your First Quiz
            </Link>
          </div>
        ) : (
          <>
            {/* Summary Stats */}
            <div className="grid md:grid-cols-3 gap-6 mb-8">
              <div className="bg-white rounded-lg shadow-lg p-6 text-center">
                <h3 className="text-lg font-semibold text-gray-800 mb-2">Total Quizzes</h3>
                <p className="text-3xl font-bold text-blue-600">{results.length}</p>
              </div>
              <div className="bg-white rounded-lg shadow-lg p-6 text-center">
                <h3 className="text-lg font-semibold text-gray-800 mb-2">Average Score</h3>
                <p className={`text-3xl font-bold ${getScoreColor(results.reduce((sum, r) => sum + r.score, 0) / results.length)}`}>
                  {Math.round(results.reduce((sum, r) => sum + r.score, 0) / results.length)}%
                </p>
              </div>
              <div className="bg-white rounded-lg shadow-lg p-6 text-center">
                <h3 className="text-lg font-semibold text-gray-800 mb-2">Best Score</h3>
                <p className={`text-3xl font-bold ${getScoreColor(Math.max(...results.map(r => r.score)))}`}>
                  {Math.round(Math.max(...results.map(r => r.score)))}%
                </p>
              </div>
            </div>

            {/* Results List */}
            <div className="space-y-4">
              {results.map((result, index) => {
                const badge = getScoreBadge(result.score);
                return (
                  <div key={index} className="bg-white rounded-lg shadow-lg p-6">
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="text-xl font-semibold text-gray-800">{result.quizTitle}</h3>
                      <span className={`px-3 py-1 rounded-full text-sm font-medium ${badge.color}`}>
                        {badge.text}
                      </span>
                    </div>
                    
                    <div className="grid md:grid-cols-4 gap-4 mb-4">
                      <div>
                        <p className="text-sm text-gray-600">Score</p>
                        <p className={`text-2xl font-bold ${getScoreColor(result.score)}`}>
                          {Math.round(result.score)}%
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Correct Answers</p>
                        <p className="text-2xl font-bold text-gray-800">
                          {result.correctAnswers}/{result.totalQuestions}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Completion Date</p>
                        <p className="text-lg text-gray-800">
                          {new Date(result.completedAt).toLocaleDateString()}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Time</p>
                        <p className="text-lg text-gray-800">
                          {new Date(result.completedAt).toLocaleTimeString()}
                        </p>
                      </div>
                    </div>

                    <div className="flex justify-end">
                      <Link
                        href={`/quiz/${result.quizId}`}
                        className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        Retake Quiz
                      </Link>
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

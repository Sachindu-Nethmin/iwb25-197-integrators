'use client';

import { useState, useEffect } from 'react';
import axios from 'axios';
import Link from 'next/link';
import Navigation from '@/components/Navigation';

interface LeaderboardEntry {
  username: string;
  category: string;
  average_score: number;
  total_quizzes: number;
  best_score: number;
  latest_quiz_date?: string;
}

export default function LeaderboardPage() {
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('overall');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchCategories();
    fetchLeaderboard('overall');
  }, []);

  const fetchCategories = async () => {
    try {
      const response = await axios.get('/api/categories');
      setCategories(['overall', ...response.data]);
    } catch (err) {
      console.error('Error fetching categories:', err);
    }
  };

  const fetchLeaderboard = async (category: string) => {
    setLoading(true);
    setError('');
    try {
      let url = '/api/leaderboard';
      if (category === 'overall') {
        url = '/api/leaderboard/overall';
      } else if (category !== 'all') {
        url = `/api/leaderboard?category=${encodeURIComponent(category)}`;
      }
      
      const response = await axios.get(url);
      setLeaderboard(response.data);
    } catch (err: any) {
      setError('Failed to fetch leaderboard data');
      console.error('Error fetching leaderboard:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCategoryChange = (category: string) => {
    setSelectedCategory(category);
    fetchLeaderboard(category);
  };

  const getRankIcon = (index: number) => {
    switch (index) {
      case 0: return '🥇';
      case 1: return '🥈';
      case 2: return '🥉';
      default: return `#${index + 1}`;
    }
  };

  const getRankColor = (index: number) => {
    switch (index) {
      case 0: return 'text-yellow-700 bg-yellow-100 font-bold';
      case 1: return 'text-gray-700 bg-gray-100 font-semibold';
      case 2: return 'text-orange-700 bg-orange-100 font-semibold';
      default: return 'text-gray-800 bg-gray-100 font-medium';
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <Navigation />
      <div className="py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-6xl mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 mb-4">🏆 Leaderboard</h1>
            <p className="text-xl text-gray-600">Top performers across different quiz categories</p>
          </div>

          {/* Navigation */}
          <div className="mb-6 text-center">
            <Link href="/" className="text-indigo-600 hover:text-indigo-500 mr-4">
              ← Back to Home
            </Link>
          <Link href="/quizzes" className="text-indigo-600 hover:text-indigo-500">
            Take a Quiz
          </Link>
        </div>

        {/* Category Filter */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Filter by Category</h2>
          <div className="flex flex-wrap gap-2">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => handleCategoryChange(category)}
                className={`px-4 py-2 rounded-lg font-semibold transition-colors ${
                  selectedCategory === category
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-200 text-gray-900 hover:bg-gray-300'
                }`}
              >
                {category === 'overall' ? 'Overall Rankings' : category}
              </button>
            ))}
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <p className="text-red-800">{error}</p>
          </div>
        )}

        {/* Loading State */}
        {loading ? (
          <div className="bg-white rounded-lg shadow-lg p-8 text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Loading leaderboard...</p>
          </div>
        ) : (
          /* Leaderboard Table */
          <div className="bg-white rounded-lg shadow-lg overflow-hidden">
            <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-800">
                {selectedCategory === 'overall' 
                  ? 'Overall Rankings' 
                  : `${selectedCategory} Category Rankings`}
              </h3>
              <p className="text-sm text-gray-600 mt-1">
                {leaderboard.length} {leaderboard.length === 1 ? 'participant' : 'participants'}
              </p>
            </div>

            {leaderboard.length === 0 ? (
              <div className="p-8 text-center">
                <p className="text-gray-500">No results found for this category.</p>
                <p className="text-sm text-gray-400 mt-2">
                  Complete some quizzes to appear on the leaderboard!
                </p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Rank
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Player
                      </th>
                      {selectedCategory !== 'overall' && (
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Category
                        </th>
                      )}
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Avg Score
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Best Score
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Quizzes Taken
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Last Activity
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {leaderboard.map((entry, index) => (
                      <tr key={`${entry.username}-${entry.category}`} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className={`flex items-center justify-center w-10 h-10 rounded-full font-bold ${getRankColor(index)}`}>
                            {getRankIcon(index)}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="font-medium text-gray-900">{entry.username}</div>
                        </td>
                        {selectedCategory !== 'overall' && (
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                              {entry.category}
                            </span>
                          </td>
                        )}
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900">
                            {entry.average_score.toFixed(1)}%
                          </div>
                          <div className="w-full bg-gray-200 rounded-full h-2 mt-1">
                            <div 
                              className="bg-green-600 h-2 rounded-full" 
                              style={{ width: `${Math.min(entry.average_score, 100)}%` }}
                            ></div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          <span className="font-semibold text-green-600">
                            {entry.best_score.toFixed(1)}%
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                            {entry.total_quizzes} quiz{entry.total_quizzes !== 1 ? 'es' : ''}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {entry.latest_quiz_date 
                            ? new Date(entry.latest_quiz_date).toLocaleDateString()
                            : 'N/A'
                          }
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* Statistics Cards */}
        {leaderboard.length > 0 && (
          <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white rounded-lg shadow-lg p-6 text-center">
              <h4 className="text-lg font-semibold text-gray-800 mb-2">Top Performer</h4>
              <p className="text-2xl font-bold text-indigo-600">{leaderboard[0].username}</p>
              <p className="text-sm text-gray-600">{leaderboard[0].average_score.toFixed(1)}% avg</p>
            </div>
            <div className="bg-white rounded-lg shadow-lg p-6 text-center">
              <h4 className="text-lg font-semibold text-gray-800 mb-2">Highest Score</h4>
              <p className="text-2xl font-bold text-green-600">
                {Math.max(...leaderboard.map(e => e.best_score)).toFixed(1)}%
              </p>
              <p className="text-sm text-gray-600">Best single quiz result</p>
            </div>
            <div className="bg-white rounded-lg shadow-lg p-6 text-center">
              <h4 className="text-lg font-semibold text-gray-800 mb-2">Total Participants</h4>
              <p className="text-2xl font-bold text-purple-600">{leaderboard.length}</p>
              <p className="text-sm text-gray-600">Active players</p>
            </div>
          </div>
        )}
        </div>
      </div>
    </div>
  );
}

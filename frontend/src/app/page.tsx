import Link from 'next/link';
import Navigation from '@/components/Navigation';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <Navigation />

      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-800 mb-4">
            Welcome to MaterialQuiz
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Test your knowledge with AI-generated quizzes from educational materials
          </p>
        </header>

        <div className="max-w-6xl mx-auto grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          <div className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
            <h2 className="text-2xl font-semibold text-gray-800 mb-4">
              Available Quizzes
            </h2>
            <p className="text-gray-600 mb-6">
              Browse and take quizzes generated from various educational materials
            </p>
            <Link 
              href="/quizzes"
              className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
            >
              View Quizzes
            </Link>
          </div>

          <div className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
            <h2 className="text-2xl font-semibold text-gray-800 mb-4">
              Create New Quiz
            </h2>
            <p className="text-gray-600 mb-6">
              Upload a PDF document and let AI generate a quiz for you
            </p>
            <Link 
              href="/upload"
              className="inline-block bg-purple-600 text-white px-6 py-3 rounded-lg hover:bg-purple-700 transition-colors"
            >
              Upload PDF
            </Link>
          </div>

          <div className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
            <h2 className="text-2xl font-semibold text-gray-800 mb-4">
              🏆 Leaderboard
            </h2>
            <p className="text-gray-600 mb-6">
              See top performers and compete with other quiz takers
            </p>
            <Link 
              href="/leaderboard"
              className="inline-block bg-orange-600 text-white px-6 py-3 rounded-lg hover:bg-orange-700 transition-colors"
            >
              View Rankings
            </Link>
          </div>

          <div className="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
            <h2 className="text-2xl font-semibold text-gray-800 mb-4">
              Your Results
            </h2>
            <p className="text-gray-600 mb-6">
              Track your performance and see detailed results from completed quizzes
            </p>
            <Link 
              href="/results"
              className="inline-block bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors"
            >
              View Results
            </Link>
          </div>
        </div>

        <div className="mt-12 text-center">
          <div className="bg-white rounded-lg shadow-lg p-8 max-w-2xl mx-auto">
            <h3 className="text-xl font-semibold text-gray-800 mb-4">
              How it works
            </h3>
            <div className="grid md:grid-cols-4 gap-6 text-sm text-gray-600">
              <div>
                <div className="bg-blue-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                  <span className="font-bold text-blue-600">1</span>
                </div>
                <p>Upload your PDF document or browse existing quizzes</p>
              </div>
              <div>
                <div className="bg-purple-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                  <span className="font-bold text-purple-600">2</span>
                </div>
                <p>AI automatically generates quiz questions from your content</p>
              </div>
              <div>
                <div className="bg-green-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                  <span className="font-bold text-green-600">3</span>
                </div>
                <p>Answer multiple-choice questions at your own pace</p>
              </div>
              <div>
                <div className="bg-orange-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                  <span className="font-bold text-orange-600">4</span>
                </div>
                <p>Get instant results and track your progress</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const response = await fetch('http://localhost:9090/api/leaderboard/overall');
    
    if (!response.ok) {
      throw new Error('Failed to fetch from backend');
    }
    
    const leaderboard = await response.json();
    return NextResponse.json(leaderboard);
  } catch (error) {
    console.error('Error fetching overall leaderboard:', error);
    
    // Return empty leaderboard as fallback
    return NextResponse.json([]);
  }
}

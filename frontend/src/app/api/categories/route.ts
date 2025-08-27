import { NextRequest, NextResponse } from 'next/server';

export async function GET() {
  try {
    const response = await fetch('http://localhost:9090/api/categories');
    
    if (!response.ok) {
      throw new Error('Failed to fetch from backend');
    }
    
    const categories = await response.json();
    return NextResponse.json(categories);
  } catch (error) {
    console.error('Error fetching categories:', error);
    
    // Fallback to default categories if backend is not available
    const fallbackCategories = ['General', 'Machine Learning', 'Data Science', 'Programming'];
    return NextResponse.json(fallbackCategories);
  }
}

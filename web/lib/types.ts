export interface User {
  id: string;
  email: string;
  full_name: string;
  role: 'parent' | 'therapist' | 'admin';
  is_active: boolean;
  is_verified: boolean;
  phone: string | null;
  avatar_url: string | null;
  timezone: string;
  locale: string;
  created_at: string;
  last_login_at: string | null;
}

export interface Child {
  id: string;
  parent_id: string;
  first_name: string;
  last_name: string | null;
  date_of_birth: string;
  diagnosis: 'asd' | 'adhd' | 'asd_adhd' | 'other' | 'undiagnosed';
  diagnosis_details: string | null;
  avatar_url: string | null;
  grade_level: number | null;
  preferences: Record<string, unknown> | null;
  accessibility: Record<string, unknown> | null;
  age_years: number;
  created_at: string;
}

export interface Game {
  id: string;
  slug: string;
  title: string;
  description: string;
  category: string;
  min_age: number;
  max_age: number;
  version: string;
  thumbnail_url: string | null;
  html5_url: string | null;
  therapy_goals: Record<string, unknown> | null;
  is_active: boolean;
  is_premium: boolean;
}

export interface Session {
  id: string;
  child_id: string;
  game_id: string;
  status: 'started' | 'in_progress' | 'paused' | 'completed' | 'abandoned';
  started_at: string;
  ended_at: string | null;
  duration_seconds: number | null;
  pause_count: number;
  score: number | null;
  accuracy: number | null;
  avg_response_time_ms: number | null;
  difficulty_level: number;
  metrics: Record<string, unknown> | null;
  notes: string | null;
}

export interface ChildProgress {
  child_id: string;
  total_sessions: number;
  completed_sessions: number;
  total_play_time_minutes: number;
  avg_accuracy: number | null;
  avg_score: number | null;
  sessions_this_week: number;
  improvement_trend: number | null;
}

export interface DailyActivity {
  date: string;
  sessions: number;
  total_minutes: number;
  avg_accuracy: number | null;
}

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page?: number;
  per_page?: number;
}

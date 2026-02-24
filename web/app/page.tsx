'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth';

export default function Home() {
  const router = useRouter();
  const token = useAuth((s) => s.token);

  useEffect(() => {
    if (token) {
      router.replace('/dashboard');
    }
  }, [token, router]);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-br from-primary-50 to-accent-50">
      <div className="text-center px-4">
        <div className="mb-6 inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-primary-600 shadow-lg">
          <svg
            className="h-9 w-9 text-white"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
            />
          </svg>
        </div>
        <h1 className="text-5xl font-bold text-primary-700">KidNeuro</h1>
        <p className="mt-4 text-xl text-gray-600">
          ASD/ADHD Therapy Edu-Games Platform
        </p>
        <p className="mt-2 max-w-md mx-auto text-gray-500">
          Evidence-based therapy games with adaptive difficulty and comprehensive
          progress tracking for children with ASD and ADHD.
        </p>
        <div className="mt-8 flex gap-4 justify-center">
          <a
            href="/auth/login"
            className="btn-primary px-6 py-3 text-base"
          >
            Sign In
          </a>
          <a
            href="/auth/register"
            className="btn-secondary px-6 py-3 text-base"
          >
            Create Account
          </a>
        </div>
      </div>
    </main>
  );
}

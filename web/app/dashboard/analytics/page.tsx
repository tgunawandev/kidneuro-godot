'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { apiFetch } from '@/lib/api';
import { StatCard } from '@/components/ui/stat-card';
import { PageSpinner } from '@/components/ui/spinner';
import { EmptyState } from '@/components/ui/empty-state';
import { ProgressChart } from '@/components/charts/progress-chart';
import { SessionsChart } from '@/components/charts/sessions-chart';
import { DurationChart } from '@/components/charts/duration-chart';
import type {
  Child,
  ChildProgress,
  DailyActivity,
  PaginatedResponse,
} from '@/lib/types';

export default function AnalyticsPage() {
  const [selectedChildId, setSelectedChildId] = useState<string>('');
  const [days, setDays] = useState(30);

  const childrenQuery = useQuery({
    queryKey: ['children'],
    queryFn: () => apiFetch<PaginatedResponse<Child>>('/api/v1/children'),
  });

  const children = childrenQuery.data?.items || [];
  const activeChildId = selectedChildId || children[0]?.id || '';

  const progressQuery = useQuery({
    queryKey: ['progress', activeChildId],
    queryFn: () =>
      apiFetch<ChildProgress>(
        `/api/v1/analytics/children/${activeChildId}/progress`
      ),
    enabled: !!activeChildId,
  });

  const dailyQuery = useQuery({
    queryKey: ['daily', activeChildId, days],
    queryFn: () =>
      apiFetch<DailyActivity[]>(
        `/api/v1/analytics/children/${activeChildId}/daily?days=${days}`
      ),
    enabled: !!activeChildId,
  });

  if (childrenQuery.isLoading) {
    return <PageSpinner />;
  }

  if (children.length === 0) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
          <p className="mt-1 text-sm text-gray-500">
            Track progress and performance over time
          </p>
        </div>
        <EmptyState
          title="No children to analyze"
          description="Add a child profile first to view their analytics and progress reports."
        />
      </div>
    );
  }

  const progress = progressQuery.data;
  const daily = dailyQuery.data || [];

  const selectedChild = children.find((c) => c.id === activeChildId);

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
          <p className="mt-1 text-sm text-gray-500">
            Track progress and performance over time
          </p>
        </div>
        <div className="flex gap-3">
          <select
            className="input-field sm:w-56"
            value={activeChildId}
            onChange={(e) => setSelectedChildId(e.target.value)}
          >
            {children.map((child) => (
              <option key={child.id} value={child.id}>
                {child.first_name}
                {child.last_name ? ` ${child.last_name}` : ''} ({child.age_years}y)
              </option>
            ))}
          </select>
          <select
            className="input-field sm:w-36"
            value={days}
            onChange={(e) => setDays(Number(e.target.value))}
          >
            <option value={7}>Last 7 days</option>
            <option value={14}>Last 14 days</option>
            <option value={30}>Last 30 days</option>
            <option value={60}>Last 60 days</option>
            <option value={90}>Last 90 days</option>
          </select>
        </div>
      </div>

      {/* Child summary */}
      {selectedChild && (
        <div className="flex items-center gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary-100 text-sm font-semibold text-primary-700">
            {selectedChild.first_name[0]}
            {selectedChild.last_name ? selectedChild.last_name[0] : ''}
          </div>
          <div>
            <p className="font-medium text-gray-900">
              {selectedChild.first_name}
              {selectedChild.last_name ? ` ${selectedChild.last_name}` : ''}
            </p>
            <p className="text-sm text-gray-500">
              {selectedChild.age_years} years old &middot;{' '}
              {selectedChild.diagnosis.toUpperCase().replace('_', ' + ')}
            </p>
          </div>
        </div>
      )}

      {/* Progress summary cards */}
      {progressQuery.isLoading ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className="h-28 animate-pulse rounded-xl border border-gray-200 bg-gray-100"
            />
          ))}
        </div>
      ) : progress ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            label="Total Sessions"
            value={progress.total_sessions}
            subtitle={`${progress.completed_sessions} completed`}
            icon={
              <svg
                className="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            }
          />
          <StatCard
            label="Total Play Time"
            value={`${progress.total_play_time_minutes}m`}
            subtitle={`${Math.round(progress.total_play_time_minutes / 60)}h total`}
            icon={
              <svg
                className="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z"
                />
              </svg>
            }
          />
          <StatCard
            label="Average Accuracy"
            value={
              progress.avg_accuracy !== null
                ? `${(progress.avg_accuracy * 100).toFixed(1)}%`
                : '--'
            }
            trend={progress.improvement_trend}
            icon={
              <svg
                className="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            }
          />
          <StatCard
            label="This Week"
            value={progress.sessions_this_week}
            subtitle={
              progress.avg_score !== null
                ? `Avg score: ${progress.avg_score.toFixed(0)}`
                : undefined
            }
            icon={
              <svg
                className="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                />
              </svg>
            }
          />
        </div>
      ) : null}

      {/* Charts */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <ProgressChart
          data={daily}
          title={`Accuracy Over Time (Last ${days} Days)`}
        />
        <SessionsChart
          data={daily}
          title={`Daily Activity (Last ${days} Days)`}
        />
      </div>

      <div className="grid grid-cols-1 gap-6">
        <DurationChart
          data={daily}
          title={`Session Duration Trend (Last ${days} Days)`}
        />
      </div>

      {dailyQuery.isLoading && (
        <div className="flex justify-center py-8">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary-200 border-t-primary-600" />
        </div>
      )}
    </div>
  );
}

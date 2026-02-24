'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { apiFetch } from '@/lib/api';
import { PageSpinner } from '@/components/ui/spinner';
import { EmptyState } from '@/components/ui/empty-state';
import type {
  Child,
  Game,
  Session,
  PaginatedResponse,
} from '@/lib/types';
import { format, parseISO } from 'date-fns';

function formatDuration(seconds: number | null): string {
  if (!seconds) return '--';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
}

const statusOptions = [
  { value: '', label: 'All Statuses' },
  { value: 'started', label: 'Started' },
  { value: 'in_progress', label: 'In Progress' },
  { value: 'paused', label: 'Paused' },
  { value: 'completed', label: 'Completed' },
  { value: 'abandoned', label: 'Abandoned' },
];

const statusBadgeClass: Record<string, string> = {
  started: 'bg-blue-100 text-blue-700',
  in_progress: 'bg-yellow-100 text-yellow-700',
  paused: 'bg-gray-100 text-gray-700',
  completed: 'bg-green-100 text-green-700',
  abandoned: 'bg-red-100 text-red-700',
};

export default function SessionsPage() {
  const [page, setPage] = useState(1);
  const [childFilter, setChildFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const perPage = 15;

  const childrenQuery = useQuery({
    queryKey: ['children'],
    queryFn: () => apiFetch<PaginatedResponse<Child>>('/api/v1/children'),
  });

  const gamesQuery = useQuery({
    queryKey: ['games'],
    queryFn: () => apiFetch<PaginatedResponse<Game>>('/api/v1/games'),
  });

  const sessionsQuery = useQuery({
    queryKey: ['sessions', page, childFilter, statusFilter],
    queryFn: () => {
      const params = new URLSearchParams({
        page: String(page),
        per_page: String(perPage),
      });
      if (childFilter) params.set('child_id', childFilter);
      if (statusFilter) params.set('status', statusFilter);
      return apiFetch<PaginatedResponse<Session>>(
        `/api/v1/sessions?${params.toString()}`
      );
    },
  });

  const children = childrenQuery.data?.items || [];
  const games = gamesQuery.data?.items || [];
  const sessions = sessionsQuery.data?.items || [];
  const total = sessionsQuery.data?.total || 0;
  const totalPages = Math.ceil(total / perPage);

  const gameMap = new Map(games.map((g) => [g.id, g.title]));
  const childMap = new Map(
    children.map((c) => [
      c.id,
      `${c.first_name}${c.last_name ? ` ${c.last_name}` : ''}`,
    ])
  );

  const isLoading =
    childrenQuery.isLoading || gamesQuery.isLoading || sessionsQuery.isLoading;

  if (isLoading && page === 1) {
    return <PageSpinner />;
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Sessions</h1>
        <p className="mt-1 text-sm text-gray-500">
          View and filter therapy session history
        </p>
      </div>

      {/* Filters */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="flex-1 sm:max-w-xs">
          <select
            className="input-field"
            value={childFilter}
            onChange={(e) => {
              setChildFilter(e.target.value);
              setPage(1);
            }}
          >
            <option value="">All Children</option>
            {children.map((child) => (
              <option key={child.id} value={child.id}>
                {child.first_name}
                {child.last_name ? ` ${child.last_name}` : ''}
              </option>
            ))}
          </select>
        </div>
        <div className="flex-1 sm:max-w-xs">
          <select
            className="input-field"
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setPage(1);
            }}
          >
            {statusOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
        <div className="text-sm text-gray-500">
          {total} session{total !== 1 ? 's' : ''} found
        </div>
      </div>

      {sessionsQuery.isError && (
        <div className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
          Failed to load sessions. Please try again.
        </div>
      )}

      {sessions.length === 0 && !sessionsQuery.isLoading ? (
        <EmptyState
          title="No sessions found"
          description={
            childFilter || statusFilter
              ? 'Try adjusting your filters to find sessions.'
              : 'No therapy sessions have been recorded yet.'
          }
        />
      ) : (
        <>
          {/* Sessions table */}
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50/50">
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Child
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Game
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Score
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Accuracy
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Duration
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Difficulty
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Response Time
                    </th>
                    <th className="px-6 py-3 text-left font-medium text-gray-500">
                      Started
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {sessions.map((session) => (
                    <tr
                      key={session.id}
                      className="hover:bg-gray-50 transition-colors"
                    >
                      <td className="px-6 py-3 font-medium text-gray-900">
                        {childMap.get(session.child_id) || 'Unknown'}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {gameMap.get(session.game_id) || 'Unknown Game'}
                      </td>
                      <td className="px-6 py-3">
                        <span
                          className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${statusBadgeClass[session.status] || 'bg-gray-100 text-gray-600'}`}
                        >
                          {session.status.replace('_', ' ')}
                        </span>
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {session.score ?? '--'}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {session.accuracy !== null
                          ? `${(session.accuracy * 100).toFixed(1)}%`
                          : '--'}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {formatDuration(session.duration_seconds)}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        Lv.{session.difficulty_level}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {session.avg_response_time_ms !== null
                          ? `${session.avg_response_time_ms}ms`
                          : '--'}
                      </td>
                      <td className="px-6 py-3 text-gray-500 whitespace-nowrap">
                        {(() => {
                          try {
                            return format(
                              parseISO(session.started_at),
                              'MMM d, yyyy h:mm a'
                            );
                          } catch {
                            return '--';
                          }
                        })()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-gray-200 px-6 py-3">
                <p className="text-sm text-gray-500">
                  Page {page} of {totalPages}
                </p>
                <div className="flex gap-2">
                  <button
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    disabled={page <= 1}
                    className="btn-secondary px-3 py-1.5 text-xs disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() =>
                      setPage((p) => Math.min(totalPages, p + 1))
                    }
                    disabled={page >= totalPages}
                    className="btn-secondary px-3 py-1.5 text-xs disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}

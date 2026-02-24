'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { apiFetch } from '@/lib/api';
import { StatCard } from '@/components/ui/stat-card';
import { PageSpinner } from '@/components/ui/spinner';
import { ProgressChart } from '@/components/charts/progress-chart';
import { SessionsChart } from '@/components/charts/sessions-chart';
import type {
  Child,
  Game,
  Session,
  DailyActivity,
  PaginatedResponse,
} from '@/lib/types';
import { format, parseISO } from 'date-fns';

function formatDuration(seconds: number | null): string {
  if (!seconds) return '--';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
}

function statusBadge(status: Session['status']) {
  const map: Record<Session['status'], string> = {
    started: 'bg-blue-100 text-blue-700',
    in_progress: 'bg-yellow-100 text-yellow-700',
    paused: 'bg-gray-100 text-gray-700',
    completed: 'bg-green-100 text-green-700',
    abandoned: 'bg-red-100 text-red-700',
  };
  return map[status] || 'bg-gray-100 text-gray-700';
}

export default function DashboardPage() {
  const childrenQuery = useQuery({
    queryKey: ['children'],
    queryFn: () => apiFetch<PaginatedResponse<Child>>('/api/v1/children'),
  });

  const gamesQuery = useQuery({
    queryKey: ['games'],
    queryFn: () => apiFetch<PaginatedResponse<Game>>('/api/v1/games'),
  });

  const sessionsQuery = useQuery({
    queryKey: ['sessions', 'recent'],
    queryFn: () =>
      apiFetch<PaginatedResponse<Session>>(
        '/api/v1/sessions?per_page=10&page=1'
      ),
  });

  // Fetch daily activity for the first child, or skip if no children
  const firstChildId = childrenQuery.data?.items?.[0]?.id;

  const dailyQuery = useQuery({
    queryKey: ['daily', firstChildId],
    queryFn: () =>
      apiFetch<DailyActivity[]>(
        `/api/v1/analytics/children/${firstChildId}/daily?days=14`
      ),
    enabled: !!firstChildId,
  });

  const isLoading =
    childrenQuery.isLoading || gamesQuery.isLoading || sessionsQuery.isLoading;

  if (isLoading) {
    return <PageSpinner />;
  }

  const children = childrenQuery.data?.items || [];
  const games = gamesQuery.data?.items || [];
  const sessions = sessionsQuery.data?.items || [];
  const daily = dailyQuery.data || [];

  const totalChildren = childrenQuery.data?.total || 0;
  const activeGames = games.filter((g) => g.is_active).length;

  const todaySessions = sessions.filter((s) => {
    try {
      return (
        format(parseISO(s.started_at), 'yyyy-MM-dd') ===
        format(new Date(), 'yyyy-MM-dd')
      );
    } catch {
      return false;
    }
  }).length;

  const completedSessions = sessions.filter((s) => s.status === 'completed');
  const avgAccuracy =
    completedSessions.length > 0
      ? completedSessions.reduce((sum, s) => sum + (s.accuracy || 0), 0) /
        completedSessions.length
      : null;

  // Build a lookup for game names by ID
  const gameMap = new Map(games.map((g) => [g.id, g.title]));
  // Build a lookup for child names by ID
  const childMap = new Map(
    children.map((c) => [
      c.id,
      `${c.first_name}${c.last_name ? ` ${c.last_name}` : ''}`,
    ])
  );

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="mt-1 text-sm text-gray-500">
            Overview of therapy activity and progress
          </p>
        </div>
        <div className="flex gap-3">
          <Link href="/dashboard/children" className="btn-primary">
            Add Child
          </Link>
          <Link href="/dashboard/sessions" className="btn-secondary">
            View Sessions
          </Link>
        </div>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Total Children"
          value={totalChildren}
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
                d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
              />
            </svg>
          }
        />
        <StatCard
          label="Sessions Today"
          value={todaySessions}
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
          label="Avg. Accuracy"
          value={avgAccuracy !== null ? `${(avgAccuracy * 100).toFixed(1)}%` : '--'}
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
                d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z"
              />
            </svg>
          }
        />
        <StatCard
          label="Active Games"
          value={activeGames}
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
                d="M14.25 6.087c0-.355.186-.676.401-.959.221-.29.349-.634.349-1.003 0-1.036-1.007-1.875-2.25-1.875s-2.25.84-2.25 1.875c0 .369.128.713.349 1.003.215.283.401.604.401.959v0a.64.64 0 01-.657.643 48.39 48.39 0 01-4.163-.3c.186 1.613.293 3.25.315 4.907a.656.656 0 01-.658.663v0c-.355 0-.676-.186-.959-.401a1.647 1.647 0 00-1.003-.349c-1.036 0-1.875 1.007-1.875 2.25s.84 2.25 1.875 2.25c.369 0 .713-.128 1.003-.349.283-.215.604-.401.959-.401v0c.31 0 .555.26.532.57a48.039 48.039 0 01-.642 5.056c1.518.19 3.058.309 4.616.354a.64.64 0 00.657-.643v0c0-.355-.186-.676-.401-.959a1.647 1.647 0 01-.349-1.003c0-1.035 1.008-1.875 2.25-1.875 1.243 0 2.25.84 2.25 1.875 0 .369-.128.713-.349 1.003-.215.283-.4.604-.4.959v0c0 .333.277.599.61.58a48.1 48.1 0 005.427-.63 48.05 48.05 0 00.582-4.717.532.532 0 00-.533-.57v0c-.355 0-.676.186-.959.401-.29.221-.634.349-1.003.349-1.035 0-1.875-1.007-1.875-2.25s.84-2.25 1.875-2.25c.37 0 .713.128 1.003.349.283.215.604.401.96.401v0a.656.656 0 00.658-.663 48.422 48.422 0 00-.37-5.36c-1.886.342-3.81.574-5.766.689a.578.578 0 01-.61-.58v0z"
              />
            </svg>
          }
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <ProgressChart data={daily} title="Accuracy Trend (Last 14 Days)" />
        <SessionsChart data={daily} title="Daily Activity (Last 14 Days)" />
      </div>

      {/* Recent sessions table */}
      <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
          <h3 className="text-base font-semibold text-gray-900">
            Recent Sessions
          </h3>
          <Link
            href="/dashboard/sessions"
            className="text-sm font-medium text-primary-600 hover:text-primary-700"
          >
            View all
          </Link>
        </div>

        {sessions.length === 0 ? (
          <div className="px-6 py-12 text-center text-sm text-gray-400">
            No sessions recorded yet. Start a game to see data here.
          </div>
        ) : (
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
                    Date
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {sessions.slice(0, 8).map((session) => (
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
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${statusBadge(session.status)}`}
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
                    <td className="px-6 py-3 text-gray-500">
                      {(() => {
                        try {
                          return format(
                            parseISO(session.started_at),
                            'MMM d, h:mm a'
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
        )}
      </div>
    </div>
  );
}

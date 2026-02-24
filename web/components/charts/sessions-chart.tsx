'use client';

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import type { DailyActivity } from '@/lib/types';
import { format, parseISO } from 'date-fns';

interface SessionsChartProps {
  data: DailyActivity[];
  title?: string;
}

export function SessionsChart({ data, title }: SessionsChartProps) {
  const chartData = data.map((d) => ({
    ...d,
    dateLabel: format(parseISO(d.date), 'MMM d'),
    minutes: Math.round(d.total_minutes),
  }));

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
      {title && (
        <h3 className="mb-4 text-base font-semibold text-gray-900">{title}</h3>
      )}
      {chartData.length === 0 ? (
        <div className="flex h-64 items-center justify-center text-sm text-gray-400">
          No data available
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis
              dataKey="dateLabel"
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={false}
              axisLine={{ stroke: '#e5e7eb' }}
            />
            <YAxis
              yAxisId="left"
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={false}
              axisLine={{ stroke: '#e5e7eb' }}
            />
            <YAxis
              yAxisId="right"
              orientation="right"
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={false}
              axisLine={{ stroke: '#e5e7eb' }}
              unit=" min"
            />
            <Tooltip
              contentStyle={{
                borderRadius: '8px',
                border: '1px solid #e5e7eb',
                boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
              }}
            />
            <Legend />
            <Bar
              yAxisId="left"
              dataKey="sessions"
              fill="#2563eb"
              radius={[4, 4, 0, 0]}
              name="Sessions"
            />
            <Bar
              yAxisId="right"
              dataKey="minutes"
              fill="#22c55e"
              radius={[4, 4, 0, 0]}
              name="Minutes"
            />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

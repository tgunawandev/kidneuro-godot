'use client';

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import type { DailyActivity } from '@/lib/types';
import { format, parseISO } from 'date-fns';

interface DurationChartProps {
  data: DailyActivity[];
  title?: string;
}

export function DurationChart({ data, title }: DurationChartProps) {
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
          <AreaChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis
              dataKey="dateLabel"
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={false}
              axisLine={{ stroke: '#e5e7eb' }}
            />
            <YAxis
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
              formatter={(value) => [`${value} min`, 'Duration']}
            />
            <defs>
              <linearGradient id="durationFill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#22c55e" stopOpacity={0.2} />
                <stop offset="95%" stopColor="#22c55e" stopOpacity={0} />
              </linearGradient>
            </defs>
            <Area
              type="monotone"
              dataKey="minutes"
              stroke="#22c55e"
              strokeWidth={2}
              fill="url(#durationFill)"
              name="Duration (min)"
            />
          </AreaChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

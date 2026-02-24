'use client';

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import type { DailyActivity } from '@/lib/types';
import { format, parseISO } from 'date-fns';

interface ProgressChartProps {
  data: DailyActivity[];
  title?: string;
}

export function ProgressChart({ data, title }: ProgressChartProps) {
  const chartData = data.map((d) => ({
    ...d,
    dateLabel: format(parseISO(d.date), 'MMM d'),
    accuracy: d.avg_accuracy !== null ? Math.round(d.avg_accuracy * 1000) / 10 : null,
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
          <LineChart data={chartData}>
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
              domain={[0, 100]}
              unit="%"
            />
            <Tooltip
              contentStyle={{
                borderRadius: '8px',
                border: '1px solid #e5e7eb',
                boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
              }}
              formatter={(value) =>
                value !== null && value !== undefined
                  ? [`${value}%`, 'Accuracy']
                  : ['N/A', 'Accuracy']
              }
            />
            <Legend />
            <Line
              type="monotone"
              dataKey="accuracy"
              stroke="#2563eb"
              strokeWidth={2}
              dot={{ r: 3, fill: '#2563eb' }}
              activeDot={{ r: 5, fill: '#2563eb' }}
              name="Accuracy (%)"
              connectNulls
            />
          </LineChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

'use client';

import { useState } from 'react';
import { cn } from '@/lib/cn';

export interface ChildFormData {
  first_name: string;
  last_name: string;
  date_of_birth: string;
  diagnosis: string;
  diagnosis_details: string;
  grade_level: string;
}

interface ChildFormProps {
  initialData?: Partial<ChildFormData>;
  onSubmit: (data: ChildFormData) => Promise<void>;
  onCancel: () => void;
  submitLabel?: string;
}

const diagnosisOptions = [
  { value: 'asd', label: 'Autism Spectrum Disorder (ASD)' },
  { value: 'adhd', label: 'ADHD' },
  { value: 'asd_adhd', label: 'ASD + ADHD' },
  { value: 'other', label: 'Other' },
  { value: 'undiagnosed', label: 'Undiagnosed' },
];

export function ChildForm({
  initialData,
  onSubmit,
  onCancel,
  submitLabel = 'Save',
}: ChildFormProps) {
  const [formData, setFormData] = useState<ChildFormData>({
    first_name: initialData?.first_name || '',
    last_name: initialData?.last_name || '',
    date_of_birth: initialData?.date_of_birth || '',
    diagnosis: initialData?.diagnosis || 'undiagnosed',
    diagnosis_details: initialData?.diagnosis_details || '',
    grade_level: initialData?.grade_level || '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await onSubmit(formData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const inputClass =
    'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500';

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">
            First Name *
          </label>
          <input
            type="text"
            required
            className={inputClass}
            value={formData.first_name}
            onChange={(e) =>
              setFormData({ ...formData, first_name: e.target.value })
            }
            placeholder="First name"
          />
        </div>
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">
            Last Name
          </label>
          <input
            type="text"
            className={inputClass}
            value={formData.last_name}
            onChange={(e) =>
              setFormData({ ...formData, last_name: e.target.value })
            }
            placeholder="Last name"
          />
        </div>
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">
          Date of Birth *
        </label>
        <input
          type="date"
          required
          className={inputClass}
          value={formData.date_of_birth}
          onChange={(e) =>
            setFormData({ ...formData, date_of_birth: e.target.value })
          }
        />
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">
          Diagnosis *
        </label>
        <select
          required
          className={inputClass}
          value={formData.diagnosis}
          onChange={(e) =>
            setFormData({ ...formData, diagnosis: e.target.value })
          }
        >
          {diagnosisOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">
          Diagnosis Details
        </label>
        <textarea
          className={cn(inputClass, 'resize-none')}
          rows={2}
          value={formData.diagnosis_details}
          onChange={(e) =>
            setFormData({ ...formData, diagnosis_details: e.target.value })
          }
          placeholder="Additional details about diagnosis (optional)"
        />
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">
          Grade Level
        </label>
        <input
          type="number"
          min={0}
          max={12}
          className={inputClass}
          value={formData.grade_level}
          onChange={(e) =>
            setFormData({ ...formData, grade_level: e.target.value })
          }
          placeholder="e.g. 3"
        />
      </div>

      <div className="flex justify-end gap-3 pt-2">
        <button
          type="button"
          onClick={onCancel}
          className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={loading}
          className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
        >
          {loading ? 'Saving...' : submitLabel}
        </button>
      </div>
    </form>
  );
}

'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiFetch } from '@/lib/api';
import { Modal } from '@/components/ui/modal';
import { ChildForm, type ChildFormData } from '@/components/forms/child-form';
import { StatCard } from '@/components/ui/stat-card';
import { PageSpinner } from '@/components/ui/spinner';
import { EmptyState } from '@/components/ui/empty-state';
import type { Child, ChildProgress, PaginatedResponse } from '@/lib/types';
import { format, parseISO } from 'date-fns';

const diagnosisLabels: Record<string, string> = {
  asd: 'ASD',
  adhd: 'ADHD',
  asd_adhd: 'ASD + ADHD',
  other: 'Other',
  undiagnosed: 'Undiagnosed',
};

const diagnosisBadge: Record<string, string> = {
  asd: 'bg-blue-100 text-blue-700',
  adhd: 'bg-orange-100 text-orange-700',
  asd_adhd: 'bg-purple-100 text-purple-700',
  other: 'bg-gray-100 text-gray-700',
  undiagnosed: 'bg-gray-100 text-gray-500',
};

export default function ChildrenPage() {
  const queryClient = useQueryClient();
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingChild, setEditingChild] = useState<Child | null>(null);
  const [selectedChild, setSelectedChild] = useState<Child | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const childrenQuery = useQuery({
    queryKey: ['children'],
    queryFn: () => apiFetch<PaginatedResponse<Child>>('/api/v1/children'),
  });

  const progressQuery = useQuery({
    queryKey: ['progress', selectedChild?.id],
    queryFn: () =>
      apiFetch<ChildProgress>(
        `/api/v1/analytics/children/${selectedChild!.id}/progress`
      ),
    enabled: !!selectedChild,
  });

  const createMutation = useMutation({
    mutationFn: (data: ChildFormData) =>
      apiFetch<Child>('/api/v1/children', {
        method: 'POST',
        body: JSON.stringify({
          first_name: data.first_name,
          last_name: data.last_name || null,
          date_of_birth: data.date_of_birth,
          diagnosis: data.diagnosis,
          diagnosis_details: data.diagnosis_details || null,
          grade_level: data.grade_level ? Number(data.grade_level) : null,
        }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['children'] });
      setShowAddModal(false);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: string;
      data: ChildFormData;
    }) =>
      apiFetch<Child>(`/api/v1/children/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          first_name: data.first_name,
          last_name: data.last_name || null,
          date_of_birth: data.date_of_birth,
          diagnosis: data.diagnosis,
          diagnosis_details: data.diagnosis_details || null,
          grade_level: data.grade_level ? Number(data.grade_level) : null,
        }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['children'] });
      setEditingChild(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) =>
      apiFetch(`/api/v1/children/${id}`, { method: 'DELETE' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['children'] });
      setDeleteConfirm(null);
      if (selectedChild && selectedChild.id === deleteConfirm) {
        setSelectedChild(null);
      }
    },
  });

  if (childrenQuery.isLoading) {
    return <PageSpinner />;
  }

  const children = childrenQuery.data?.items || [];
  const progress = progressQuery.data;

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Children</h1>
          <p className="mt-1 text-sm text-gray-500">
            Manage child profiles and view their progress
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="btn-primary"
        >
          <span className="flex items-center gap-2">
            <svg
              className="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 4.5v15m7.5-7.5h-15"
              />
            </svg>
            Add Child
          </span>
        </button>
      </div>

      {childrenQuery.isError && (
        <div className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
          Failed to load children. Please try again.
        </div>
      )}

      {children.length === 0 ? (
        <EmptyState
          title="No children yet"
          description="Add a child profile to start tracking their therapy progress."
          action={
            <button
              onClick={() => setShowAddModal(true)}
              className="btn-primary"
            >
              Add First Child
            </button>
          }
        />
      ) : (
        <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
          {/* Children list */}
          <div className="xl:col-span-2">
            <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-100 bg-gray-50/50">
                      <th className="px-6 py-3 text-left font-medium text-gray-500">
                        Name
                      </th>
                      <th className="px-6 py-3 text-left font-medium text-gray-500">
                        Age
                      </th>
                      <th className="px-6 py-3 text-left font-medium text-gray-500">
                        Diagnosis
                      </th>
                      <th className="px-6 py-3 text-left font-medium text-gray-500">
                        Grade
                      </th>
                      <th className="px-6 py-3 text-left font-medium text-gray-500">
                        Added
                      </th>
                      <th className="px-6 py-3 text-right font-medium text-gray-500">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {children.map((child) => (
                      <tr
                        key={child.id}
                        className={`cursor-pointer transition-colors ${
                          selectedChild?.id === child.id
                            ? 'bg-primary-50'
                            : 'hover:bg-gray-50'
                        }`}
                        onClick={() => setSelectedChild(child)}
                      >
                        <td className="px-6 py-3">
                          <div className="flex items-center gap-3">
                            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary-100 text-xs font-semibold text-primary-700">
                              {child.first_name[0]}
                              {child.last_name ? child.last_name[0] : ''}
                            </div>
                            <span className="font-medium text-gray-900">
                              {child.first_name}
                              {child.last_name ? ` ${child.last_name}` : ''}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-3 text-gray-600">
                          {child.age_years}y
                        </td>
                        <td className="px-6 py-3">
                          <span
                            className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${diagnosisBadge[child.diagnosis] || 'bg-gray-100 text-gray-600'}`}
                          >
                            {diagnosisLabels[child.diagnosis] || child.diagnosis}
                          </span>
                        </td>
                        <td className="px-6 py-3 text-gray-600">
                          {child.grade_level !== null
                            ? `Grade ${child.grade_level}`
                            : '--'}
                        </td>
                        <td className="px-6 py-3 text-gray-500">
                          {(() => {
                            try {
                              return format(
                                parseISO(child.created_at),
                                'MMM d, yyyy'
                              );
                            } catch {
                              return '--';
                            }
                          })()}
                        </td>
                        <td className="px-6 py-3 text-right">
                          <div className="flex items-center justify-end gap-1">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setEditingChild(child);
                              }}
                              className="rounded p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
                              title="Edit"
                            >
                              <svg
                                className="h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                strokeWidth={1.5}
                                stroke="currentColor"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
                                />
                              </svg>
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setDeleteConfirm(child.id);
                              }}
                              className="rounded p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600"
                              title="Delete"
                            >
                              <svg
                                className="h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                strokeWidth={1.5}
                                stroke="currentColor"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
                                />
                              </svg>
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Detail panel */}
          <div className="xl:col-span-1">
            {selectedChild ? (
              <div className="space-y-4">
                <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
                  <div className="flex items-center gap-3 mb-4">
                    <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary-100 text-lg font-semibold text-primary-700">
                      {selectedChild.first_name[0]}
                      {selectedChild.last_name
                        ? selectedChild.last_name[0]
                        : ''}
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">
                        {selectedChild.first_name}
                        {selectedChild.last_name
                          ? ` ${selectedChild.last_name}`
                          : ''}
                      </h3>
                      <p className="text-sm text-gray-500">
                        {selectedChild.age_years} years old
                      </p>
                    </div>
                  </div>

                  <dl className="space-y-3 text-sm">
                    <div className="flex justify-between">
                      <dt className="text-gray-500">Diagnosis</dt>
                      <dd>
                        <span
                          className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${diagnosisBadge[selectedChild.diagnosis] || 'bg-gray-100 text-gray-600'}`}
                        >
                          {diagnosisLabels[selectedChild.diagnosis] ||
                            selectedChild.diagnosis}
                        </span>
                      </dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-500">Date of Birth</dt>
                      <dd className="text-gray-900">
                        {(() => {
                          try {
                            return format(
                              parseISO(selectedChild.date_of_birth),
                              'MMM d, yyyy'
                            );
                          } catch {
                            return selectedChild.date_of_birth;
                          }
                        })()}
                      </dd>
                    </div>
                    {selectedChild.grade_level !== null && (
                      <div className="flex justify-between">
                        <dt className="text-gray-500">Grade Level</dt>
                        <dd className="text-gray-900">
                          {selectedChild.grade_level}
                        </dd>
                      </div>
                    )}
                    {selectedChild.diagnosis_details && (
                      <div>
                        <dt className="text-gray-500 mb-1">Details</dt>
                        <dd className="text-gray-700 text-xs bg-gray-50 rounded-lg p-2">
                          {selectedChild.diagnosis_details}
                        </dd>
                      </div>
                    )}
                  </dl>
                </div>

                {/* Progress */}
                {progress && (
                  <div className="grid grid-cols-2 gap-3">
                    <StatCard
                      label="Total Sessions"
                      value={progress.total_sessions}
                      className="p-4"
                    />
                    <StatCard
                      label="Completed"
                      value={progress.completed_sessions}
                      className="p-4"
                    />
                    <StatCard
                      label="Play Time"
                      value={`${progress.total_play_time_minutes}m`}
                      className="p-4"
                    />
                    <StatCard
                      label="Avg Accuracy"
                      value={
                        progress.avg_accuracy !== null
                          ? `${(progress.avg_accuracy * 100).toFixed(1)}%`
                          : '--'
                      }
                      className="p-4"
                    />
                    <StatCard
                      label="This Week"
                      value={progress.sessions_this_week}
                      className="p-4"
                    />
                    <StatCard
                      label="Avg Score"
                      value={
                        progress.avg_score !== null
                          ? progress.avg_score.toFixed(0)
                          : '--'
                      }
                      className="p-4"
                    />
                  </div>
                )}

                {progressQuery.isLoading && (
                  <div className="flex justify-center py-8">
                    <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary-200 border-t-primary-600" />
                  </div>
                )}
              </div>
            ) : (
              <div className="rounded-xl border border-dashed border-gray-300 bg-gray-50/50 p-8 text-center">
                <p className="text-sm text-gray-400">
                  Select a child to view details and progress
                </p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Add Child Modal */}
      <Modal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        title="Add Child"
      >
        <ChildForm
          onSubmit={async (data) => {
            await createMutation.mutateAsync(data);
          }}
          onCancel={() => setShowAddModal(false)}
          submitLabel="Add Child"
        />
      </Modal>

      {/* Edit Child Modal */}
      <Modal
        isOpen={!!editingChild}
        onClose={() => setEditingChild(null)}
        title="Edit Child"
      >
        {editingChild && (
          <ChildForm
            initialData={{
              first_name: editingChild.first_name,
              last_name: editingChild.last_name || '',
              date_of_birth: editingChild.date_of_birth,
              diagnosis: editingChild.diagnosis,
              diagnosis_details: editingChild.diagnosis_details || '',
              grade_level:
                editingChild.grade_level !== null
                  ? String(editingChild.grade_level)
                  : '',
            }}
            onSubmit={async (data) => {
              await updateMutation.mutateAsync({
                id: editingChild.id,
                data,
              });
            }}
            onCancel={() => setEditingChild(null)}
            submitLabel="Save Changes"
          />
        )}
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={!!deleteConfirm}
        onClose={() => setDeleteConfirm(null)}
        title="Delete Child"
      >
        <p className="text-sm text-gray-600">
          Are you sure you want to delete this child profile? This will also
          remove all associated sessions and progress data. This action cannot be
          undone.
        </p>
        <div className="mt-6 flex justify-end gap-3">
          <button
            onClick={() => setDeleteConfirm(null)}
            className="btn-secondary"
          >
            Cancel
          </button>
          <button
            onClick={() => deleteConfirm && deleteMutation.mutate(deleteConfirm)}
            disabled={deleteMutation.isPending}
            className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
          >
            {deleteMutation.isPending ? 'Deleting...' : 'Delete'}
          </button>
        </div>
      </Modal>
    </div>
  );
}

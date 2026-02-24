'use client';

export default function Dashboard() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <h1 className="text-2xl font-bold text-primary-700">KidNeuro Dashboard</h1>
        </div>
      </header>
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[
            { label: 'Active Children', value: '—', color: 'primary' },
            { label: 'Sessions Today', value: '—', color: 'accent' },
            { label: 'Avg. Accuracy', value: '—', color: 'primary' },
            { label: 'Games Available', value: '6', color: 'accent' },
          ].map((stat) => (
            <div key={stat.label} className="bg-white rounded-xl shadow-sm p-6 border">
              <p className="text-sm text-gray-500">{stat.label}</p>
              <p className="text-3xl font-bold text-gray-900 mt-1">{stat.value}</p>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}

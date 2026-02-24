export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-br from-primary-50 to-accent-50">
      <div className="text-center">
        <h1 className="text-5xl font-bold text-primary-700">KidNeuro</h1>
        <p className="mt-4 text-xl text-gray-600">ASD/ADHD Therapy Edu-Games Platform</p>
        <div className="mt-8 flex gap-4 justify-center">
          <a
            href="/dashboard"
            className="rounded-lg bg-primary-600 px-6 py-3 text-white font-medium hover:bg-primary-700 transition-colors"
          >
            Dashboard
          </a>
          <a
            href={process.env.NEXT_PUBLIC_API_URL + '/docs'}
            className="rounded-lg border border-primary-300 px-6 py-3 text-primary-700 font-medium hover:bg-primary-50 transition-colors"
          >
            API Docs
          </a>
        </div>
      </div>
    </main>
  );
}

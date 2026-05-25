import Link from 'next/link'

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-green-50 to-emerald-100 dark:from-gray-950 dark:to-gray-900 p-4">
      <Link href="/dashboard" className="mb-8 flex items-center gap-2">
        <div className="h-9 w-9 rounded-xl bg-green-600 flex items-center justify-center">
          <span className="text-white font-bold text-lg">C</span>
        </div>
        <span className="text-2xl font-bold text-green-700 dark:text-green-400">Chal.AI</span>
      </Link>
      {children}
    </div>
  )
}

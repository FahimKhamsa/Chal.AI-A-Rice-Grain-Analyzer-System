import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { AppSidebar } from '@/components/layout/app-sidebar'
import { TopBar } from '@/components/layout/top-bar'
import type { UserProfile } from '@/types/auth'

export default async function VerifiedLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  if (!profile || (profile.role !== 'verified' && profile.role !== 'admin')) {
    redirect('/dashboard')
  }

  const VERIFIED_NAV = [
    { href: '/verified', label: 'Verified Dashboard', icon: null },
    { href: '/dashboard', label: 'Analyze', icon: null },
    { href: '/history', label: 'History', icon: null },
    { href: '/profile', label: 'Profile', icon: null },
    { href: '/settings', label: 'Settings', icon: null },
  ]

  return (
    <div className="flex h-screen overflow-hidden">
      <AppSidebar profile={profile as UserProfile} />
      <div className="flex-1 flex flex-col overflow-hidden">
        <TopBar profile={profile as UserProfile} />
        <main className="flex-1 overflow-y-auto p-4 md:p-6">
          {children}
        </main>
      </div>
    </div>
  )
}

'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { LayoutDashboard, History, User, Settings, BookOpen, LogOut } from 'lucide-react'
import { cn } from '@/lib/utils'
import { createClient } from '@/lib/supabase/client'
import type { UserProfile } from '@/types/auth'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'

const NAV_LINKS = [
  { href: '/dashboard', label: 'Analyze', icon: LayoutDashboard },
  { href: '/history', label: 'History', icon: History },
  { href: '/profile', label: 'Profile', icon: User },
  { href: '/settings', label: 'Settings', icon: Settings },
  { href: '/guidelines', label: 'Guidelines', icon: BookOpen },
]

export function AppSidebar({ profile }: { profile: UserProfile | null }) {
  const pathname = usePathname()
  const router = useRouter()

  async function handleLogout() {
    const supabase = createClient()
    await supabase.auth.signOut()
    document.cookie = 'chalai-role=; max-age=0; path=/'
    router.push('/login')
    router.refresh()
  }

  const initials = profile
    ? `${profile.first_name[0]}${profile.last_name[0]}`.toUpperCase()
    : '?'

  return (
    <aside className="hidden md:flex flex-col w-60 border-r bg-card h-screen sticky top-0">
      <div className="p-4 flex items-center gap-2 border-b">
        <div className="h-8 w-8 rounded-lg bg-green-600 flex items-center justify-center">
          <span className="text-white font-bold">C</span>
        </div>
        <span className="font-bold text-lg text-green-700 dark:text-green-400">Chal.AI</span>
      </div>

      <nav className="flex-1 p-3 space-y-1">
        {NAV_LINKS.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className={cn(
              'flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
              pathname === href
                ? 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400'
                : 'text-muted-foreground hover:bg-muted hover:text-foreground'
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </Link>
        ))}
      </nav>

      <Separator />
      <div className="p-3">
        <div className="flex items-center gap-3 px-3 py-2 mb-1">
          <Avatar className="h-8 w-8">
            <AvatarFallback className="bg-green-100 text-green-700 text-xs">{initials}</AvatarFallback>
          </Avatar>
          <div className="flex-1 min-w-0">
            {profile && (
              <p className="text-sm font-medium truncate">{profile.first_name} {profile.last_name}</p>
            )}
            <p className="text-xs text-muted-foreground truncate">{profile?.email}</p>
          </div>
        </div>
        <Button
          variant="ghost"
          className="w-full justify-start gap-3 text-red-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/30"
          onClick={handleLogout}
        >
          <LogOut className="h-4 w-4" />
          Sign Out
        </Button>
      </div>
    </aside>
  )
}

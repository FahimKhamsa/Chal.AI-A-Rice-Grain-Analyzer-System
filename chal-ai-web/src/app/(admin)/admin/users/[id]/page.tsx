import { notFound } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Separator } from '@/components/ui/separator'
import { ArrowLeft } from 'lucide-react'
import { formatDate, scoreHex, scoreLabel } from '@/lib/utils'
import type { UserProfile } from '@/types/auth'
import type { AnalysisRecord } from '@/types/analysis'

export default async function AdminUserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()

  const [profileRes, analysesRes] = await Promise.all([
    supabase.from('profiles').select('*').eq('id', id).single(),
    supabase
      .from('rice_analysis_records')
      .select('*')
      .eq('user_id', id)
      .order('created_at', { ascending: false })
      .limit(20),
  ])

  if (!profileRes.data) notFound()

  const profile = profileRes.data as UserProfile
  const analyses = (analysesRes.data ?? []) as AnalysisRecord[]
  const initials = `${profile.first_name[0]}${profile.last_name[0]}`.toUpperCase()

  const ROLE_COLORS: Record<string, string> = {
    user: 'bg-gray-100 text-gray-700',
    verified: 'bg-blue-100 text-blue-700',
    admin: 'bg-purple-100 text-purple-700',
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div className="flex items-center gap-3">
        <Link href="/admin/users">
          <Button variant="ghost" size="icon"><ArrowLeft className="h-4 w-4" /></Button>
        </Link>
        <div>
          <h1 className="text-xl font-bold">{profile.first_name} {profile.last_name}</h1>
          <p className="text-sm text-muted-foreground">User detail view</p>
        </div>
      </div>

      <Card>
        <CardContent className="p-6 flex items-center gap-4">
          <Avatar className="h-16 w-16">
            <AvatarFallback className="bg-green-100 text-green-700 text-xl">{initials}</AvatarFallback>
          </Avatar>
          <div className="space-y-1">
            <p className="font-bold text-lg">{profile.first_name} {profile.last_name}</p>
            <p className="text-muted-foreground">{profile.email}</p>
            <div className="flex flex-wrap gap-2">
              <Badge className={`capitalize ${ROLE_COLORS[profile.role]}`} variant="secondary">{profile.role}</Badge>
              {profile.designation && <Badge variant="outline">{profile.designation}</Badge>}
              {profile.location && <Badge variant="outline">{profile.location}</Badge>}
            </div>
            <p className="text-xs text-muted-foreground">Member since {formatDate(profile.created_at)}</p>
          </div>
        </CardContent>
      </Card>

      <Separator />
      <div>
        <h2 className="font-semibold mb-3">Recent Analyses ({analyses.length})</h2>
        {analyses.length === 0 ? (
          <p className="text-muted-foreground text-sm">No analyses yet.</p>
        ) : (
          <div className="space-y-2">
            {analyses.map(r => {
              const color = scoreHex(r.integrity_score)
              return (
                <Link key={r.id} href={`/analysis/${r.id}`}>
                  <Card className="hover:shadow-md transition-shadow">
                    <CardContent className="p-4 flex items-center gap-3">
                      <div className="h-10 w-10 rounded-lg flex items-center justify-center text-white text-sm font-bold flex-shrink-0" style={{ backgroundColor: color }}>
                        {Math.round(r.integrity_score)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">{r.batch_name}</p>
                        <p className="text-xs text-muted-foreground">{r.color_report?.detectedVariety ?? '—'} · {formatDate(r.analyzed_at)}</p>
                      </div>
                      <Badge style={{ color, borderColor: color }} variant="outline" className="text-xs flex-shrink-0">
                        {scoreLabel(r.integrity_score)}
                      </Badge>
                    </CardContent>
                  </Card>
                </Link>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}

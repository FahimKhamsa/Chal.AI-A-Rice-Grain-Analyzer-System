import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { ProfileEditForm } from '@/components/profile/profile-edit-form'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import type { UserProfile } from '@/types/auth'

export default async function ProfilePage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: profile } = await supabase.from('profiles').select('*').eq('id', user.id).single()
  if (!profile) redirect('/profile-setup')

  const p = profile as UserProfile
  const initials = `${p.first_name[0]}${p.last_name[0]}`.toUpperCase()

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Profile</h1>
        <p className="text-muted-foreground">Manage your personal information</p>
      </div>

      <Card>
        <CardContent className="p-6 flex items-center gap-4">
          <Avatar className="h-16 w-16">
            <AvatarFallback className="bg-green-100 text-green-700 text-xl">{initials}</AvatarFallback>
          </Avatar>
          <div>
            <p className="text-xl font-bold">{p.first_name} {p.last_name}</p>
            <p className="text-muted-foreground">{p.email}</p>
            <Badge variant="secondary" className="mt-1 capitalize">{p.role}</Badge>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Edit Profile</CardTitle>
          <CardDescription>Update your personal details</CardDescription>
        </CardHeader>
        <CardContent>
          <ProfileEditForm profile={p} />
        </CardContent>
      </Card>
    </div>
  )
}

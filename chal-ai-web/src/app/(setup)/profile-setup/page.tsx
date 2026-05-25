import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { ProfileSetupForm } from '@/components/profile/profile-setup-form'

export default async function ProfileSetupPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  return <ProfileSetupForm userId={user.id} email={user.email!} />
}

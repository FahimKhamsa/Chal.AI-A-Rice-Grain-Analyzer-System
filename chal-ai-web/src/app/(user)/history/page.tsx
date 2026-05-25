import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { HistoryList } from '@/components/history/history-list'

export default async function HistoryPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')
  return <HistoryList userId={user.id} />
}

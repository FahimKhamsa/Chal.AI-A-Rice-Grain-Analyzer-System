'use client'

import useSWR from 'swr'
import { createClient } from '@/lib/supabase/client'
import type { UserProfile } from '@/types/auth'

export function useAdminUsers() {
  return useSWR(
    ['admin', 'users'],
    async () => {
      const supabase = createClient()
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      return data as UserProfile[]
    }
  )
}

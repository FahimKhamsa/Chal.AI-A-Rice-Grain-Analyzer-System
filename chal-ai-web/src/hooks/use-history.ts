'use client'

import useSWR from 'swr'
import { createClient } from '@/lib/supabase/client'
import type { AnalysisRecord } from '@/types/analysis'

export function useHistory(userId: string) {
  return useSWR(
    ['history', userId],
    async () => {
      const supabase = createClient()
      const { data, error } = await supabase
        .from('rice_analysis_records')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(50)

      if (error) throw error
      return data as AnalysisRecord[]
    }
  )
}

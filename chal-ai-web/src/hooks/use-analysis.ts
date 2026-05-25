'use client'

import useSWR from 'swr'
import { createClient } from '@/lib/supabase/client'
import type { AnalysisRecord } from '@/types/analysis'

export function useAnalysis(id: string) {
  return useSWR(
    ['analysis', id],
    async () => {
      const supabase = createClient()
      const { data, error } = await supabase
        .from('rice_analysis_records')
        .select('*')
        .eq('id', id)
        .single()

      if (error) throw error
      return data as AnalysisRecord
    }
  )
}

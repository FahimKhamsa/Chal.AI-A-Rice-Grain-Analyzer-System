'use client'

import useSWR from 'swr'
import { createClient } from '@/lib/supabase/client'
import type { AnalysisRecord } from '@/types/analysis'

interface AdminAnalysisRecord extends AnalysisRecord {
  profiles?: { first_name: string; last_name: string; email: string }
}

export function useAdminAnalyses(search = '', filter = '') {
  return useSWR(
    ['admin', 'analyses', search, filter],
    async () => {
      const supabase = createClient()
      let query = supabase
        .from('rice_analysis_records')
        .select('*, profiles(first_name, last_name, email)')
        .order('created_at', { ascending: false })
        .limit(100)

      if (search) {
        query = query.ilike('batch_name', `%${search}%`)
      }

      if (filter === 'excellent') query = query.gte('integrity_score', 80)
      else if (filter === 'good') query = query.gte('integrity_score', 60).lt('integrity_score', 80)
      else if (filter === 'fair') query = query.gte('integrity_score', 40).lt('integrity_score', 60)
      else if (filter === 'poor') query = query.lt('integrity_score', 40)

      const { data, error } = await query
      if (error) throw error
      return data as AdminAnalysisRecord[]
    }
  )
}

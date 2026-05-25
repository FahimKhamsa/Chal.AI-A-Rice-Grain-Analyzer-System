'use client'

import useSWR from 'swr'
import { createClient } from '@/lib/supabase/client'

export function useAdminStats() {
  return useSWR(
    ['admin', 'stats'],
    async () => {
      const supabase = createClient()

      const [usersRes, analysesRes, recentRes] = await Promise.all([
        supabase.from('profiles').select('id, role', { count: 'exact' }),
        supabase.from('rice_analysis_records').select('id, created_at, integrity_score', { count: 'exact' }),
        supabase
          .from('rice_analysis_records')
          .select('created_at')
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
          .order('created_at', { ascending: true }),
      ])

      const users = usersRes.data || []
      const analyses = analysesRes.data || []
      const recent = recentRes.data || []

      // Role breakdown
      const roleBreakdown = {
        user: users.filter(u => u.role === 'user').length,
        verified: users.filter(u => u.role === 'verified').length,
        admin: users.filter(u => u.role === 'admin').length,
      }

      // Analyses per day (last 7 days)
      const byDay: Record<string, number> = {}
      for (let i = 6; i >= 0; i--) {
        const d = new Date()
        d.setDate(d.getDate() - i)
        byDay[d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })] = 0
      }
      recent.forEach(r => {
        const day = new Date(r.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
        if (day in byDay) byDay[day]++
      })

      const avgScore = analyses.length
        ? Math.round(analyses.reduce((s, a) => s + (a.integrity_score || 0), 0) / analyses.length)
        : 0

      return {
        totalUsers: usersRes.count ?? users.length,
        totalAnalyses: analysesRes.count ?? analyses.length,
        todayAnalyses: recent.filter(r =>
          new Date(r.created_at).toDateString() === new Date().toDateString()
        ).length,
        avgIntegrityScore: avgScore,
        roleBreakdown,
        analysesByDay: Object.entries(byDay).map(([date, count]) => ({ date, count })),
      }
    }
  )
}

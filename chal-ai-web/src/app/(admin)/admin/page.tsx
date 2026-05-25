'use client'

import { useAdminStats } from '@/hooks/use-admin-stats'
import { StatsCard } from '@/components/admin/stats-card'
import { StatsCharts } from '@/components/admin/stats-charts'
import { Users, BarChart2, Activity, TrendingUp } from 'lucide-react'

export default function AdminDashboardPage() {
  const { data, isLoading } = useAdminStats()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Admin Dashboard</h1>
        <p className="text-muted-foreground">System overview and statistics</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="Total Users"
          value={data?.totalUsers ?? '—'}
          icon={Users}
          iconColor="text-green-600"
          loading={isLoading}
        />
        <StatsCard
          title="Total Analyses"
          value={data?.totalAnalyses ?? '—'}
          icon={BarChart2}
          iconColor="text-blue-600"
          loading={isLoading}
        />
        <StatsCard
          title="Today"
          value={data?.todayAnalyses ?? '—'}
          description="analyses today"
          icon={Activity}
          iconColor="text-amber-600"
          loading={isLoading}
        />
        <StatsCard
          title="Avg Score"
          value={data ? `${data.avgIntegrityScore}/100` : '—'}
          description="integrity score"
          icon={TrendingUp}
          iconColor="text-purple-600"
          loading={isLoading}
        />
      </div>

      <StatsCharts />
    </div>
  )
}

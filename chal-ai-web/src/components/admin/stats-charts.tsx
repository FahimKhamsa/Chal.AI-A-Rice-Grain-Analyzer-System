'use client'

import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts'
import { useAdminStats } from '@/hooks/use-admin-stats'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'

const ROLE_COLORS = { user: '#22C55E', verified: '#3B82F6', admin: '#8B5CF6' }

export function StatsCharts() {
  const { data, isLoading } = useAdminStats()

  if (isLoading) return <Skeleton className="h-64 w-full" />
  if (!data) return null

  const roleData = [
    { name: 'Users', value: data.roleBreakdown.user },
    { name: 'Verified', value: data.roleBreakdown.verified },
    { name: 'Admins', value: data.roleBreakdown.admin },
  ].filter(d => d.value > 0)

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      <Card>
        <CardHeader><CardTitle className="text-base">Analyses (Last 7 Days)</CardTitle></CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={data.analysesByDay}>
              <XAxis dataKey="date" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
              <Tooltip />
              <Line type="monotone" dataKey="count" stroke="#22C55E" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">Users by Role</CardTitle></CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={roleData} cx="50%" cy="50%" outerRadius={70} dataKey="value" label>
                {roleData.map((d, i) => (
                  <Cell key={i} fill={ROLE_COLORS[d.name.toLowerCase() as keyof typeof ROLE_COLORS] ?? '#6B7280'} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </div>
  )
}

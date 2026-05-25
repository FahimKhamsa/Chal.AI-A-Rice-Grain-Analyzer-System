'use client'

import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import type { GrainCounts } from '@/types/analysis'
import { grainTotal } from '@/types/analysis'
import { pct } from '@/lib/utils'

const COLORS = ['#22C55E', '#F59E0B', '#EF4444', '#8B5CF6', '#3B82F6']
const LABELS = ['Healthy', '¾ Broken', '½ Broken', 'Impurity', 'Discolored']

export function GrainBreakdownPie({ counts }: { counts: GrainCounts }) {
  const total = grainTotal(counts)
  const data = [
    { name: LABELS[0], value: counts.healthy },
    { name: LABELS[1], value: counts.threeQuarterBroken },
    { name: LABELS[2], value: counts.halfBroken },
    { name: LABELS[3], value: counts.impurity },
    { name: LABELS[4], value: counts.discolored },
  ].filter(d => d.value > 0)

  return (
    <ResponsiveContainer width="100%" height={260}>
      <PieChart>
        <Pie
          data={data}
          cx="50%"
          cy="45%"
          innerRadius={60}
          outerRadius={90}
          paddingAngle={2}
          dataKey="value"
        >
          {data.map((_, i) => (
            <Cell key={i} fill={COLORS[i % COLORS.length]} />
          ))}
        </Pie>
        <Tooltip
          formatter={(value, name) => [
            `${Number(value)} (${pct(Number(value), total).toFixed(1)}%)`,
            name,
          ]}
        />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  )
}

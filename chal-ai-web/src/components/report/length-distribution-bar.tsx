'use client'

import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import type { LengthDistribution } from '@/types/analysis'

export function LengthDistributionBar({ dist }: { dist: LengthDistribution }) {
  const data = [
    { name: 'Short\n(<5mm)', value: dist.shortPct, fill: '#F59E0B' },
    { name: 'Medium\n(5–6.5mm)', value: dist.mediumPct, fill: '#22C55E' },
    { name: 'Long\n(>6.5mm)', value: dist.longPct, fill: '#3B82F6' },
  ]

  return (
    <ResponsiveContainer width="100%" height={200}>
      <BarChart data={data} margin={{ top: 4, right: 8, left: -20, bottom: 4 }}>
        <XAxis dataKey="name" tick={{ fontSize: 11 }} />
        <YAxis tickFormatter={v => `${v}%`} />
        <Tooltip formatter={(v) => [`${Number(v).toFixed(1)}%`, 'Percentage']} />
        <Bar dataKey="value" radius={[4, 4, 0, 0]}>
          {data.map((d, i) => <Cell key={i} fill={d.fill} />)}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  )
}

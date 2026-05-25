'use client'

import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import type { DefectBreakdown } from '@/types/analysis'

export function DefectBreakdownBar({ breakdown }: { breakdown: DefectBreakdown }) {
  const data = [
    { name: 'Chalky', value: breakdown.chalkyPct, fill: '#F3F4F6' },
    { name: 'Red Streaked', value: breakdown.redStreakedPct, fill: '#EF4444' },
    { name: 'Immature', value: breakdown.immaturePct, fill: '#84CC16' },
    { name: 'Foreign', value: breakdown.foreignMatterPct, fill: '#8B5CF6' },
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

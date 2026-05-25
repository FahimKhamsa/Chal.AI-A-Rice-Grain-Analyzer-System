'use client'

import { RadialBarChart, RadialBar, ResponsiveContainer } from 'recharts'
import { scoreHex, scoreLabel } from '@/lib/utils'

export function IntegrityScoreGauge({ score }: { score: number }) {
  const color = scoreHex(score)
  const data = [{ value: score, fill: color }]

  return (
    <div className="flex flex-col items-center gap-2">
      <div className="relative h-40 w-40">
        <ResponsiveContainer width="100%" height="100%">
          <RadialBarChart
            cx="50%"
            cy="50%"
            innerRadius="65%"
            outerRadius="90%"
            barSize={12}
            data={data}
            startAngle={225}
            endAngle={-45}
          >
            <RadialBar
              dataKey="value"
              cornerRadius={6}
              background={{ fill: '#e5e7eb' }}
            />
          </RadialBarChart>
        </ResponsiveContainer>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-3xl font-bold" style={{ color }}>{Math.round(score)}</span>
          <span className="text-xs text-muted-foreground">/ 100</span>
        </div>
      </div>
      <div className="text-center">
        <span className="text-sm font-semibold" style={{ color }}>{scoreLabel(score)}</span>
        <p className="text-xs text-muted-foreground">Integrity Score</p>
      </div>
    </div>
  )
}

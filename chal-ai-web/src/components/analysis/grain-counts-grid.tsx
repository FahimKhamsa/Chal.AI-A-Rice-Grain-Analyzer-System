import type { GrainCounts } from '@/types/analysis'
import { grainTotal } from '@/types/analysis'
import { pct } from '@/lib/utils'
import { Progress } from '@/components/ui/progress'

const GRAIN_TYPES = [
  { key: 'healthy', label: 'Healthy', color: '#22C55E', bg: 'bg-green-100 dark:bg-green-900/30', text: 'text-green-700 dark:text-green-400' },
  { key: 'threeQuarterBroken', label: '¾ Broken', color: '#F59E0B', bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-400' },
  { key: 'halfBroken', label: '½ Broken', color: '#EF4444', bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-700 dark:text-red-400' },
  { key: 'impurity', label: 'Impurity', color: '#8B5CF6', bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-400' },
  { key: 'discolored', label: 'Discolored', color: '#3B82F6', bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-400' },
] as const

export function GrainCountsGrid({ counts }: { counts: GrainCounts }) {
  const total = grainTotal(counts)

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
      {GRAIN_TYPES.map(({ key, label, bg, text }) => {
        const count = counts[key as keyof GrainCounts]
        const percent = pct(count, total)
        return (
          <div key={key} className={`rounded-xl p-3 ${bg} space-y-2`}>
            <p className={`text-xs font-medium ${text}`}>{label}</p>
            <p className="text-2xl font-bold">{count}</p>
            <div className="space-y-0.5">
              <Progress value={percent} className="h-1.5" />
              <p className="text-xs text-muted-foreground">{percent.toFixed(1)}%</p>
            </div>
          </div>
        )
      })}
    </div>
  )
}

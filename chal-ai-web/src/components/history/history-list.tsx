'use client'

import { useHistory } from '@/hooks/use-history'
import { HistoryCard } from './history-card'
import { Skeleton } from '@/components/ui/skeleton'
import { History } from 'lucide-react'

export function HistoryList({ userId }: { userId: string }) {
  const { data, error, isLoading, mutate } = useHistory(userId)

  return (
    <div className="max-w-3xl mx-auto space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Analysis History</h1>
        <p className="text-muted-foreground">Your past rice grain analyses</p>
      </div>

      {isLoading && (
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => <Skeleton key={i} className="h-20 rounded-xl" />)}
        </div>
      )}

      {error && (
        <p className="text-red-500">Failed to load history. Please refresh.</p>
      )}

      {data && data.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 text-center gap-3">
          <History className="h-12 w-12 text-muted-foreground/50" />
          <p className="font-medium text-muted-foreground">No analyses yet</p>
          <p className="text-sm text-muted-foreground">Upload a rice grain image on the dashboard to get started.</p>
        </div>
      )}

      {data && data.length > 0 && (
        <div className="space-y-2">
          {data.map(record => (
            <HistoryCard
              key={record.id}
              record={record}
              onDeleted={() => mutate()}
            />
          ))}
        </div>
      )}
    </div>
  )
}

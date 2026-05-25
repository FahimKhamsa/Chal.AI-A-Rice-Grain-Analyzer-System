'use client'

import Link from 'next/link'
import { useState } from 'react'
import { toast } from 'sonner'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Trash2, ChevronRight } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import type { AnalysisRecord } from '@/types/analysis'
import { formatDate, scoreHex, scoreLabel } from '@/lib/utils'

interface Props {
  record: AnalysisRecord
  onDeleted: () => void
}

export function HistoryCard({ record, onDeleted }: Props) {
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [deleting, setDeleting] = useState(false)

  async function handleDelete() {
    setDeleting(true)
    const supabase = createClient()
    const { error } = await supabase.from('rice_analysis_records').delete().eq('id', record.id)
    if (error) {
      toast.error('Failed to delete')
      setDeleting(false)
      return
    }
    setConfirmOpen(false)
    onDeleted()
  }

  const color = scoreHex(record.integrity_score)
  const variety = record.color_report?.detectedVariety || 'Unknown'

  return (
    <>
      <Card className="hover:shadow-md transition-shadow">
        <CardContent className="p-4 flex items-center gap-3">
          <div
            className="h-12 w-12 rounded-xl flex items-center justify-center font-bold text-sm text-white flex-shrink-0"
            style={{ backgroundColor: color }}
          >
            {Math.round(record.integrity_score)}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <p className="font-semibold truncate">{record.batch_name}</p>
              <Badge variant="outline" className="text-xs flex-shrink-0" style={{ color, borderColor: color }}>
                {scoreLabel(record.integrity_score)}
              </Badge>
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span>{variety}</span>
              <span>·</span>
              <span>{formatDate(record.analyzed_at)}</span>
            </div>
          </div>
          <div className="flex items-center gap-1 flex-shrink-0">
            <Button
              variant="ghost"
              size="icon"
              className="text-red-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/30"
              onClick={() => setConfirmOpen(true)}
            >
              <Trash2 className="h-4 w-4" />
            </Button>
            <Link href={`/analysis/${record.id}`}>
              <Button variant="ghost" size="icon">
                <ChevronRight className="h-4 w-4" />
              </Button>
            </Link>
          </div>
        </CardContent>
      </Card>

      <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete analysis?</DialogTitle>
            <DialogDescription>
              This will permanently remove &quot;{record.batch_name}&quot; and its images. This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmOpen(false)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete} disabled={deleting}>
              {deleting ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}

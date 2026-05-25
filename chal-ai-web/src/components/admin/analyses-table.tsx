'use client'

import { useState } from 'react'
import Link from 'next/link'
import { toast } from 'sonner'
import { useAdminAnalyses } from '@/hooks/use-admin-analyses'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Skeleton } from '@/components/ui/skeleton'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { createClient } from '@/lib/supabase/client'
import { formatDate, scoreHex, scoreLabel } from '@/lib/utils'
import { Search, Trash2, ExternalLink } from 'lucide-react'

export function AnalysesTable() {
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState('')
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const { data, isLoading, error, mutate } = useAdminAnalyses(search, filter)

  async function handleDelete() {
    if (!deleteId) return
    setDeleting(true)
    const supabase = createClient()
    const { error } = await supabase.from('rice_analysis_records').delete().eq('id', deleteId)
    if (error) toast.error('Failed to delete')
    else { toast.success('Record deleted'); mutate() }
    setDeleteId(null)
    setDeleting(false)
  }

  return (
    <div className="space-y-3">
      <div className="flex gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search batch name..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="pl-8"
          />
        </div>
        <Select value={filter} onValueChange={(v) => setFilter(v ?? '')}>
          <SelectTrigger className="w-36">
            <SelectValue placeholder="All scores" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">All scores</SelectItem>
            <SelectItem value="excellent">Excellent (≥80)</SelectItem>
            <SelectItem value="good">Good (60–79)</SelectItem>
            <SelectItem value="fair">Fair (40–59)</SelectItem>
            <SelectItem value="poor">Poor (&lt;40)</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {isLoading && (
        <div className="space-y-2">
          {[...Array(5)].map((_, i) => <Skeleton key={i} className="h-12 rounded" />)}
        </div>
      )}

      {error && <p className="text-red-500">Failed to load analyses.</p>}

      {data && (
        <div className="rounded-lg border overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow className="bg-muted/50">
                <TableHead>Batch Name</TableHead>
                <TableHead>User</TableHead>
                <TableHead>Score</TableHead>
                <TableHead>Variety</TableHead>
                <TableHead>Date</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="text-center text-muted-foreground py-8">No analyses found</TableCell>
                </TableRow>
              )}
              {data.map(record => {
                const color = scoreHex(record.integrity_score)
                const profile = (record as any).profiles
                return (
                  <TableRow key={record.id}>
                    <TableCell className="font-medium">{record.batch_name}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {profile ? (
                        <Link href={`/admin/users/${record.user_id}`} className="hover:underline text-foreground">
                          {profile.first_name} {profile.last_name}
                        </Link>
                      ) : '—'}
                    </TableCell>
                    <TableCell>
                      <Badge className="text-xs" style={{ backgroundColor: color + '20', color, borderColor: color }} variant="outline">
                        {Math.round(record.integrity_score)} · {scoreLabel(record.integrity_score)}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-sm">{record.color_report?.detectedVariety || '—'}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">{formatDate(record.analyzed_at)}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Link href={`/analysis/${record.id}`}>
                          <Button variant="ghost" size="icon" className="h-7 w-7">
                            <ExternalLink className="h-3.5 w-3.5" />
                          </Button>
                        </Link>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7 text-red-400 hover:text-red-600"
                          onClick={() => setDeleteId(record.id)}
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </div>
      )}

      <Dialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete analysis record?</DialogTitle>
            <DialogDescription>This action cannot be undone.</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteId(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete} disabled={deleting}>
              {deleting ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

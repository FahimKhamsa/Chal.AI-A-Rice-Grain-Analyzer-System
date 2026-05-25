import { redirect, notFound } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import type { AnalysisRecord } from '@/types/analysis'
import { grainTotal } from '@/types/analysis'
import { formatDate, formatDuration, scoreColor, scoreLabel } from '@/lib/utils'
import { IntegrityScoreGauge } from '@/components/analysis/integrity-score-gauge'
import { GrainCountsGrid } from '@/components/analysis/grain-counts-grid'
import { VarietyCard } from '@/components/analysis/variety-card'
import { AnnotatedImages } from '@/components/analysis/annotated-images'
import { GrainBreakdownPie } from '@/components/report/grain-breakdown-pie'
import { LengthDistributionBar } from '@/components/report/length-distribution-bar'
import { DefectBreakdownBar } from '@/components/report/defect-breakdown-bar'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Button } from '@/components/ui/button'
import { ArrowLeft, Clock, Layers } from 'lucide-react'

export default async function AnalysisPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data, error } = await supabase
    .from('rice_analysis_records')
    .select('*')
    .eq('id', id)
    .single()

  if (error || !data) notFound()

  const record = data as AnalysisRecord

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/history">
            <Button variant="ghost" size="icon"><ArrowLeft className="h-4 w-4" /></Button>
          </Link>
          <div>
            <h1 className="text-xl font-bold">{record.batch_name}</h1>
            <p className="text-sm text-muted-foreground">{formatDate(record.analyzed_at)}</p>
          </div>
        </div>
        <Badge className={`${scoreColor(record.integrity_score)} bg-transparent border`} variant="outline">
          {scoreLabel(record.integrity_score)}
        </Badge>
      </div>

      {/* Score + Variety + Meta */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="flex items-center justify-center py-6">
          <IntegrityScoreGauge score={record.integrity_score} />
        </Card>
        <div className="md:col-span-2 space-y-3">
          <VarietyCard colorReport={record.color_report} />
          <div className="grid grid-cols-2 gap-3">
            <Card>
              <CardContent className="p-4 flex items-center gap-3">
                <Layers className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-xs text-muted-foreground">Total Grains</p>
                  <p className="font-bold text-lg">{grainTotal(record.counts).toLocaleString()}</p>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 flex items-center gap-3">
                <Clock className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-xs text-muted-foreground">Processing Time</p>
                  <p className="font-bold text-lg">{formatDuration(record.processing_time_ms)}</p>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Grain Counts */}
      <Card>
        <CardHeader><CardTitle className="text-base">Grain Classification</CardTitle></CardHeader>
        <CardContent>
          <GrainCountsGrid counts={record.counts} />
        </CardContent>
      </Card>

      {/* Annotated Images */}
      <Card>
        <CardHeader><CardTitle className="text-base">Annotated Images</CardTitle></CardHeader>
        <CardContent>
          <AnnotatedImages
            morphologyPath={record.morphology_image_url}
            colorPath={record.color_image_url}
          />
        </CardContent>
      </Card>

      <Separator />
      <h2 className="text-lg font-bold">Detailed Report</h2>

      {/* Charts */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader><CardTitle className="text-base">Grain Breakdown</CardTitle></CardHeader>
          <CardContent>
            <GrainBreakdownPie counts={record.counts} />
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle className="text-base">Length Distribution</CardTitle></CardHeader>
          <CardContent>
            <LengthDistributionBar dist={record.morphology_report.lengthDistribution} />
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader><CardTitle className="text-base">Defect Breakdown</CardTitle></CardHeader>
        <CardContent>
          <DefectBreakdownBar breakdown={record.morphology_report.defectBreakdown} />
        </CardContent>
      </Card>
    </div>
  )
}

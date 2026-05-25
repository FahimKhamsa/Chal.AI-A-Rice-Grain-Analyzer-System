'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { ImageDropZone } from '@/components/capture/image-drop-zone'
import { AnalyzingOverlay } from '@/components/capture/analyzing-overlay'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Microscope } from 'lucide-react'

export default function DashboardPage() {
  const router = useRouter()
  const [file, setFile] = useState<File | null>(null)
  const [batchName, setBatchName] = useState('Batch A')
  const [analyzing, setAnalyzing] = useState(false)

  async function handleAnalyze() {
    if (!file) {
      toast.error('Please select an image first')
      return
    }

    setAnalyzing(true)

    try {
      const formData = new FormData()
      formData.append('file', file)
      formData.append('batch_name', batchName || 'Batch A')

      const res = await fetch('/api/analyze', {
        method: 'POST',
        body: formData,
      })

      if (!res.ok) {
        const err = await res.json().catch(() => ({}))
        throw new Error(err.error || 'Analysis failed')
      }

      const { id } = await res.json()
      router.push(`/analysis/${id}`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Analysis failed')
      setAnalyzing(false)
    }
  }

  return (
    <>
      {analyzing && <AnalyzingOverlay />}
      <div className="max-w-2xl mx-auto space-y-6">
        <div>
          <h1 className="text-2xl font-bold">Rice Grain Analysis</h1>
          <p className="text-muted-foreground">Upload a rice grain image to get an instant quality report</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Upload Image</CardTitle>
            <CardDescription>Select or drag a rice grain image (JPEG/PNG, max 10MB)</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <ImageDropZone file={file} onFileChange={setFile} />
            <div className="space-y-1">
              <Label htmlFor="batchName">Batch Name</Label>
              <Input
                id="batchName"
                value={batchName}
                onChange={e => setBatchName(e.target.value)}
                placeholder="e.g. Field A - North, Supplier B..."
              />
            </div>
            <Button
              className="w-full bg-green-600 hover:bg-green-700"
              size="lg"
              onClick={handleAnalyze}
              disabled={!file || analyzing}
            >
              <Microscope className="mr-2 h-5 w-5" />
              Analyze Grains
            </Button>
          </CardContent>
        </Card>

        <Card className="border-dashed">
          <CardContent className="p-6">
            <h3 className="font-semibold mb-3">What you&apos;ll get</h3>
            <div className="grid grid-cols-2 gap-3 text-sm">
              {[
                ['Integrity Score', 'Overall quality rating 0–100'],
                ['Grain Counts', 'Healthy, broken, impurity, discolored'],
                ['Variety Detection', 'Rice variety & confidence %'],
                ['Annotated Images', 'Visual overlay of detected grains'],
                ['Length Distribution', 'Short / medium / long percentages'],
                ['Defect Breakdown', 'Chalky, red streaked, immature, foreign'],
              ].map(([title, desc]) => (
                <div key={title} className="space-y-0.5">
                  <p className="font-medium text-green-700 dark:text-green-400">{title}</p>
                  <p className="text-muted-foreground text-xs">{desc}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </>
  )
}

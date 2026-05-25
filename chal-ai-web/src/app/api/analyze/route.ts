import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import type { FastApiResponse } from '@/types/analysis'

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'
const BUCKET = process.env.NEXT_PUBLIC_SUPABASE_BUCKET ?? 'rice-images'

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  let formData: FormData
  try {
    formData = await request.formData()
  } catch {
    return NextResponse.json({ error: 'Invalid form data' }, { status: 400 })
  }

  const file = formData.get('file') as File | null
  const batchName = (formData.get('batch_name') as string) || 'Batch A'

  if (!file) {
    return NextResponse.json({ error: 'No image file provided' }, { status: 400 })
  }

  // Forward to FastAPI with 90s timeout
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 90_000)

  let apiResult: FastApiResponse
  try {
    const apiForm = new FormData()
    apiForm.append('file', file)
    apiForm.append('batch_name', batchName)

    const apiRes = await fetch(`${API_URL}/api/v1/rice`, {
      method: 'POST',
      body: apiForm,
      signal: controller.signal,
    })
    clearTimeout(timeout)

    if (!apiRes.ok) {
      const text = await apiRes.text()
      return NextResponse.json({ error: `AI service error: ${text}` }, { status: 502 })
    }

    apiResult = await apiRes.json()
  } catch (err) {
    clearTimeout(timeout)
    if (err instanceof Error && err.name === 'AbortError') {
      return NextResponse.json({ error: 'Analysis timed out. Please try again.' }, { status: 504 })
    }
    return NextResponse.json({ error: 'Could not reach AI service' }, { status: 502 })
  }

  const analysisId = apiResult.id
  const userId = user.id

  // Upload annotated images to Supabase Storage
  let morphologyUrl: string | null = null
  let colorUrl: string | null = null

  if (apiResult.morphology_image_b64) {
    try {
      const buf = Buffer.from(apiResult.morphology_image_b64, 'base64')
      const path = `${userId}/${analysisId}/morphology.jpg`
      const { error } = await supabase.storage
        .from(BUCKET)
        .upload(path, buf, { contentType: 'image/jpeg', upsert: true })
      if (!error) morphologyUrl = path
    } catch { /* non-fatal */ }
  }

  if (apiResult.color_image_b64) {
    try {
      const buf = Buffer.from(apiResult.color_image_b64, 'base64')
      const path = `${userId}/${analysisId}/color.jpg`
      const { error } = await supabase.storage
        .from(BUCKET)
        .upload(path, buf, { contentType: 'image/jpeg', upsert: true })
      if (!error) colorUrl = path
    } catch { /* non-fatal */ }
  }

  // Build morphology + color reports
  const morphologyReport = apiResult.morphology_report ?? {
    analysisId,
    imagePath: morphologyUrl ?? '',
    lengthDistribution: apiResult.lengthDistribution,
    defectBreakdown: apiResult.defectBreakdown,
  }

  const colorReport = apiResult.color_report ?? {
    detectedVariety: apiResult.detectedVariety,
    varietyConfidence: apiResult.varietyConfidence,
  }

  // Insert analysis record
  const { error: insertError } = await supabase.from('rice_analysis_records').insert({
    id: analysisId,
    user_id: userId,
    batch_name: batchName,
    analyzed_at: apiResult.analyzedAt,
    processing_time_ms: apiResult.processingTimeMs,
    integrity_score: apiResult.integrityScore,
    counts: apiResult.counts,
    morphology_report: morphologyReport,
    color_report: colorReport,
    morphology_image_url: morphologyUrl,
    color_image_url: colorUrl,
  })

  if (insertError) {
    console.error('DB insert error:', insertError)
    return NextResponse.json({ error: 'Failed to save analysis' }, { status: 500 })
  }

  return NextResponse.json({ id: analysisId })
}

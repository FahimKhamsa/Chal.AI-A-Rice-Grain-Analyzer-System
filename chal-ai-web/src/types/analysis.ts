export interface GrainCounts {
  healthy: number
  threeQuarterBroken: number
  halfBroken: number
  impurity: number
  discolored: number
}

export interface LengthDistribution {
  shortPct: number
  mediumPct: number
  longPct: number
}

export interface DefectBreakdown {
  chalkyPct: number
  redStreakedPct: number
  immaturePct: number
  foreignMatterPct: number
}

export interface MorphologyReport {
  analysisId: string
  imagePath: string
  lengthDistribution: LengthDistribution
  defectBreakdown: DefectBreakdown
}

export interface ColorReport {
  detectedVariety: string
  varietyConfidence: number
}

export interface AnalysisRecord {
  id: string
  user_id: string
  batch_name: string
  analyzed_at: string
  processing_time_ms: number
  integrity_score: number
  counts: GrainCounts
  morphology_report: MorphologyReport
  color_report: ColorReport
  morphology_image_url: string | null
  color_image_url: string | null
  created_at: string
}

export interface FastApiResponse {
  id: string
  batchName: string
  analyzedAt: string
  processingTimeMs: number
  counts: {
    healthy: number
    threeQuarterBroken: number
    halfBroken: number
    impurity: number
    discolored: number
  }
  integrityScore: number
  detectedVariety: string
  varietyConfidence: number
  lengthDistribution: LengthDistribution
  defectBreakdown: DefectBreakdown
  morphology_report?: MorphologyReport
  color_report?: ColorReport
  morphology_image_b64: string
  color_image_b64: string
}

export function grainTotal(counts: GrainCounts): number {
  return counts.healthy + counts.threeQuarterBroken + counts.halfBroken + counts.impurity + counts.discolored
}

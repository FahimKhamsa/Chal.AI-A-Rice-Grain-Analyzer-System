import type { ColorReport } from '@/types/analysis'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Wheat } from 'lucide-react'

export function VarietyCard({ colorReport }: { colorReport: ColorReport }) {
  const { detectedVariety, varietyConfidence } = colorReport
  return (
    <Card>
      <CardContent className="p-4 flex items-center gap-3">
        <div className="h-10 w-10 rounded-full bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
          <Wheat className="h-5 w-5 text-amber-600" />
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Detected Variety</p>
          <div className="flex items-center gap-2">
            <span className="font-semibold">{detectedVariety || 'Unknown'}</span>
            {varietyConfidence > 0 && (
              <Badge variant="secondary" className="text-xs">
                {varietyConfidence.toFixed(1)}% confidence
              </Badge>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

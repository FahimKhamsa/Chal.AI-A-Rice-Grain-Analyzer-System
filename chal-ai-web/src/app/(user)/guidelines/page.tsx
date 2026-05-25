import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { CheckCircle, AlertCircle, Camera, BarChart2, History, Settings } from 'lucide-react'

const SECTIONS = [
  {
    icon: Camera,
    title: 'Capturing Images',
    items: [
      'Use a clean, flat surface with good lighting',
      'Spread rice grains in a single layer without overlapping',
      'Capture from directly above at a consistent distance',
      'Ensure the image is sharp and in focus',
      'Supported formats: JPEG, PNG (max 10MB)',
    ],
    type: 'tips' as const,
  },
  {
    icon: BarChart2,
    title: 'Understanding Results',
    items: [
      'Integrity Score (0-100): Overall quality rating based on healthy grain percentage',
      'Healthy: Whole, undamaged grains in good condition',
      '¾ Broken: Grains with more than half their length intact',
      '½ Broken: Grains broken roughly in half',
      'Impurity: Non-rice matter, dust, or foreign objects',
      'Discolored: Grains with abnormal color (chalky, red-streaked, immature)',
    ],
    type: 'info' as const,
  },
  {
    icon: History,
    title: 'Managing History',
    items: [
      'All analyses are automatically saved to your account',
      'Access past results anytime from the History page',
      'Click any record to view full analysis details',
      'Delete records you no longer need',
      'History is limited to the last 50 analyses',
    ],
    type: 'tips' as const,
  },
  {
    icon: Settings,
    title: 'Best Practices',
    items: [
      'Name batches clearly (e.g., "Field A - May 2025") for easy tracking',
      'Analyze multiple samples from the same batch for accuracy',
      'Use consistent lighting conditions across analyses for comparison',
      'Download annotated images for reporting purposes',
    ],
    type: 'tips' as const,
  },
]

export default function GuidelinesPage() {
  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold">User Guidelines</h1>
        <p className="text-muted-foreground">How to get the best results from Chal.AI</p>
      </div>

      <Card className="bg-green-50 dark:bg-green-950/20 border-green-200 dark:border-green-800">
        <CardContent className="p-4 text-sm text-green-800 dark:text-green-200">
          Chal.AI uses AI-powered computer vision to detect and classify rice grains in your images.
          Follow these guidelines to get accurate and meaningful results.
        </CardContent>
      </Card>

      {SECTIONS.map(({ icon: Icon, title, items, type }) => (
        <Card key={title}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Icon className="h-5 w-5 text-green-600" />
              {title}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="space-y-2">
              {items.map(item => (
                <li key={item} className="flex items-start gap-2 text-sm">
                  {type === 'tips'
                    ? <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 flex-shrink-0" />
                    : <AlertCircle className="h-4 w-4 text-blue-500 mt-0.5 flex-shrink-0" />
                  }
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      ))}

      <Separator />
      <div className="text-center space-y-2">
        <p className="text-sm font-medium">Score Interpretation</p>
        <div className="flex justify-center gap-3 flex-wrap">
          {[
            ['Excellent', '≥ 80', 'bg-green-100 text-green-700'],
            ['Good', '60–79', 'bg-yellow-100 text-yellow-700'],
            ['Fair', '40–59', 'bg-orange-100 text-orange-700'],
            ['Poor', '< 40', 'bg-red-100 text-red-700'],
          ].map(([label, range, cls]) => (
            <div key={label} className={`rounded-lg px-3 py-2 text-xs font-medium ${cls}`}>
              <span className="font-bold">{label}</span> · {range}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

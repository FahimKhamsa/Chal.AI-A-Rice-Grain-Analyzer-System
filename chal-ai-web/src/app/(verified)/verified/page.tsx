import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { CheckCircle, Clock } from 'lucide-react'

export default function VerifiedDashboardPage() {
  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="flex items-center gap-3">
        <div>
          <h1 className="text-2xl font-bold">Verified Dashboard</h1>
          <div className="flex items-center gap-2 mt-1">
            <Badge className="bg-blue-100 text-blue-700 gap-1">
              <CheckCircle className="h-3 w-3" />
              Verified Account
            </Badge>
          </div>
        </div>
      </div>

      <Card className="border-blue-200 dark:border-blue-800 bg-blue-50/50 dark:bg-blue-950/20">
        <CardHeader>
          <div className="flex items-center gap-2">
            <Clock className="h-5 w-5 text-blue-600" />
            <CardTitle className="text-blue-800 dark:text-blue-200">Coming Soon</CardTitle>
          </div>
          <CardDescription className="text-blue-700 dark:text-blue-300">
            The Verified user portal is currently under development. As a verified user, you&apos;ll get access to exclusive features.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-blue-800 dark:text-blue-200 font-medium mb-3">Planned features for verified users:</p>
          <ul className="space-y-2 text-sm text-blue-700 dark:text-blue-300">
            {[
              'Advanced analytics and batch comparison',
              'Export reports as PDF',
              'Priority AI processing queue',
              'API access for programmatic analysis',
              'Historical trend analysis across batches',
            ].map(feature => (
              <li key={feature} className="flex items-center gap-2">
                <CheckCircle className="h-4 w-4 flex-shrink-0 opacity-50" />
                {feature}
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-4 text-sm text-muted-foreground text-center">
          Meanwhile, you have full access to all standard user features — use the sidebar to navigate to Analyze, History, and more.
        </CardContent>
      </Card>
    </div>
  )
}

import { AnalysesTable } from '@/components/admin/analyses-table'

export default function AdminAnalysesPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">All Analyses</h1>
        <p className="text-muted-foreground">Browse and manage all rice grain analyses across all users</p>
      </div>
      <AnalysesTable />
    </div>
  )
}

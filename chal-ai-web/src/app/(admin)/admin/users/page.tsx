import { UserTable } from '@/components/admin/user-table'

export default function AdminUsersPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Users</h1>
        <p className="text-muted-foreground">Manage all registered users and their roles</p>
      </div>
      <UserTable />
    </div>
  )
}

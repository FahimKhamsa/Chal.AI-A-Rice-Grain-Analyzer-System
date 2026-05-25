'use client'

import Link from 'next/link'
import { useAdminUsers } from '@/hooks/use-admin-users'
import { UserRoleSelect } from './user-role-select'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { formatDate } from '@/lib/utils'
import { ExternalLink } from 'lucide-react'
import type { UserRole } from '@/types/auth'

const ROLE_COLORS: Record<UserRole, string> = {
  user: 'bg-gray-100 text-gray-700',
  verified: 'bg-blue-100 text-blue-700',
  admin: 'bg-purple-100 text-purple-700',
}

export function UserTable() {
  const { data, isLoading, error, mutate } = useAdminUsers()

  if (isLoading) return (
    <div className="space-y-2">
      {[...Array(5)].map((_, i) => <Skeleton key={i} className="h-12 rounded" />)}
    </div>
  )

  if (error) return <p className="text-red-500">Failed to load users.</p>
  if (!data?.length) return <p className="text-muted-foreground">No users found.</p>

  return (
    <div className="rounded-lg border overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow className="bg-muted/50">
            <TableHead>Name</TableHead>
            <TableHead>Email</TableHead>
            <TableHead>Role</TableHead>
            <TableHead>Location</TableHead>
            <TableHead>Joined</TableHead>
            <TableHead />
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.map(user => (
            <TableRow key={user.id}>
              <TableCell className="font-medium">{user.first_name} {user.last_name}</TableCell>
              <TableCell className="text-muted-foreground text-sm">{user.email}</TableCell>
              <TableCell>
                <div className="flex items-center gap-2">
                  <Badge className={`text-xs capitalize ${ROLE_COLORS[user.role]}`} variant="secondary">
                    {user.role}
                  </Badge>
                  <UserRoleSelect
                    userId={user.id}
                    currentRole={user.role}
                    onChanged={() => mutate()}
                  />
                </div>
              </TableCell>
              <TableCell className="text-sm text-muted-foreground">{user.location}</TableCell>
              <TableCell className="text-sm text-muted-foreground">{formatDate(user.created_at)}</TableCell>
              <TableCell>
                <Link href={`/admin/users/${user.id}`}>
                  <Button variant="ghost" size="icon" className="h-7 w-7">
                    <ExternalLink className="h-3.5 w-3.5" />
                  </Button>
                </Link>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}

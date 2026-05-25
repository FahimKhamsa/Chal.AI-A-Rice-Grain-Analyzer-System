'use client'

import { useState } from 'react'
import { toast } from 'sonner'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createClient } from '@/lib/supabase/client'
import type { UserRole } from '@/types/auth'

interface Props {
  userId: string
  currentRole: UserRole
  onChanged: () => void
}

export function UserRoleSelect({ userId, currentRole, onChanged }: Props) {
  const [loading, setLoading] = useState(false)

  async function handleChange(newRole: string | null) {
    if (!newRole) return
    setLoading(true)
    const supabase = createClient()
    const { error } = await supabase
      .from('profiles')
      .update({ role: newRole })
      .eq('id', userId)

    if (error) {
      toast.error('Failed to update role')
    } else {
      toast.success(`Role updated to ${newRole}`)
      onChanged()
    }
    setLoading(false)
  }

  return (
    <Select defaultValue={currentRole} onValueChange={handleChange} disabled={loading}>
      <SelectTrigger className="w-28 h-7 text-xs">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="user">User</SelectItem>
        <SelectItem value="verified">Verified</SelectItem>
        <SelectItem value="admin">Admin</SelectItem>
      </SelectContent>
    </Select>
  )
}

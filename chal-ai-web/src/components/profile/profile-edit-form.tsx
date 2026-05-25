'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { createClient } from '@/lib/supabase/client'
import type { UserProfile } from '@/types/auth'
import { Loader2 } from 'lucide-react'

const schema = z.object({
  first_name: z.string().min(1, 'Required'),
  last_name: z.string().min(1, 'Required'),
  phone_number: z.string().min(1, 'Required'),
  location: z.string().min(1, 'Required'),
  designation: z.string().optional(),
})

type FormData = z.infer<typeof schema>

export function ProfileEditForm({ profile }: { profile: UserProfile }) {
  const [loading, setLoading] = useState(false)
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      first_name: profile.first_name,
      last_name: profile.last_name,
      phone_number: profile.phone_number,
      location: profile.location,
      designation: profile.designation ?? '',
    },
  })

  async function onSubmit(data: FormData) {
    setLoading(true)
    const supabase = createClient()
    const { error } = await supabase
      .from('profiles')
      .update({
        first_name: data.first_name,
        last_name: data.last_name,
        phone_number: data.phone_number,
        location: data.location,
        designation: data.designation || null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', profile.id)

    if (error) {
      toast.error(error.message)
    } else {
      toast.success('Profile updated')
    }
    setLoading(false)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-1">
          <Label htmlFor="first_name">First Name</Label>
          <Input id="first_name" {...register('first_name')} />
          {errors.first_name && <p className="text-sm text-red-500">{errors.first_name.message}</p>}
        </div>
        <div className="space-y-1">
          <Label htmlFor="last_name">Last Name</Label>
          <Input id="last_name" {...register('last_name')} />
          {errors.last_name && <p className="text-sm text-red-500">{errors.last_name.message}</p>}
        </div>
      </div>
      <div className="space-y-1">
        <Label>Email</Label>
        <Input value={profile.email} disabled className="bg-muted" />
      </div>
      <div className="space-y-1">
        <Label htmlFor="phone_number">Phone Number</Label>
        <Input id="phone_number" {...register('phone_number')} />
        {errors.phone_number && <p className="text-sm text-red-500">{errors.phone_number.message}</p>}
      </div>
      <div className="space-y-1">
        <Label htmlFor="location">Location</Label>
        <Input id="location" {...register('location')} />
        {errors.location && <p className="text-sm text-red-500">{errors.location.message}</p>}
      </div>
      <div className="space-y-1">
        <Label htmlFor="designation">Designation <span className="text-muted-foreground">(optional)</span></Label>
        <Input id="designation" {...register('designation')} />
      </div>
      <Button type="submit" className="bg-green-600 hover:bg-green-700" disabled={loading}>
        {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
        Save Changes
      </Button>
    </form>
  )
}

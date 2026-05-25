'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { createClient } from '@/lib/supabase/client'
import { Loader2 } from 'lucide-react'

const schema = z.object({
  first_name: z.string().min(1, 'First name is required'),
  last_name: z.string().min(1, 'Last name is required'),
  phone_number: z.string().min(1, 'Phone number is required'),
  location: z.string().min(1, 'Location is required'),
  designation: z.string().optional(),
})

type FormData = z.infer<typeof schema>

export function ProfileSetupForm({ userId, email }: { userId: string; email: string }) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  async function onSubmit(data: FormData) {
    setLoading(true)
    const supabase = createClient()
    const { error } = await supabase.from('profiles').insert({
      id: userId,
      email,
      first_name: data.first_name,
      last_name: data.last_name,
      phone_number: data.phone_number,
      location: data.location,
      designation: data.designation || null,
      role: 'user',
    })

    if (error) {
      toast.error(error.message)
      setLoading(false)
      return
    }

    // Clear cached role cookie
    document.cookie = 'chalai-role=; max-age=0; path=/'
    router.push('/dashboard')
    router.refresh()
  }

  return (
    <Card className="w-full max-w-lg">
      <CardHeader>
        <CardTitle>Complete your profile</CardTitle>
        <CardDescription>Tell us a bit about yourself to get started</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <Label htmlFor="first_name">First Name</Label>
              <Input id="first_name" placeholder="Fahim" {...register('first_name')} />
              {errors.first_name && <p className="text-sm text-red-500">{errors.first_name.message}</p>}
            </div>
            <div className="space-y-1">
              <Label htmlFor="last_name">Last Name</Label>
              <Input id="last_name" placeholder="Rahman" {...register('last_name')} />
              {errors.last_name && <p className="text-sm text-red-500">{errors.last_name.message}</p>}
            </div>
          </div>
          <div className="space-y-1">
            <Label htmlFor="phone_number">Phone Number</Label>
            <Input id="phone_number" placeholder="+880 1700 000000" {...register('phone_number')} />
            {errors.phone_number && <p className="text-sm text-red-500">{errors.phone_number.message}</p>}
          </div>
          <div className="space-y-1">
            <Label htmlFor="location">Location</Label>
            <Input id="location" placeholder="Dhaka, Bangladesh" {...register('location')} />
            {errors.location && <p className="text-sm text-red-500">{errors.location.message}</p>}
          </div>
          <div className="space-y-1">
            <Label htmlFor="designation">Designation <span className="text-muted-foreground">(optional)</span></Label>
            <Input id="designation" placeholder="Quality Analyst" {...register('designation')} />
          </div>
          <Button type="submit" className="w-full bg-green-600 hover:bg-green-700" disabled={loading}>
            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save & Continue
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}

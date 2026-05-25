export type UserRole = 'user' | 'verified' | 'admin'

export interface UserProfile {
  id: string
  first_name: string
  last_name: string
  phone_number: string
  location: string
  designation: string | null
  email: string
  role: UserRole
  created_at: string
  updated_at: string
}

export interface AppUser {
  id: string
  email: string
}

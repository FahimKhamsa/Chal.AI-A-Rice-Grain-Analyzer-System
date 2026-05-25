import type { UserRole } from './auth'
import type { GrainCounts, MorphologyReport, ColorReport } from './analysis'

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
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
        Insert: Omit<Database['public']['Tables']['profiles']['Row'], 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>
      }
      rice_analysis_records: {
        Row: {
          id: string
          user_id: string
          batch_name: string
          analyzed_at: string
          processing_time_ms: number
          integrity_score: number
          counts: GrainCounts
          morphology_report: MorphologyReport
          color_report: ColorReport
          morphology_image_url: string | null
          color_image_url: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['rice_analysis_records']['Row'], 'created_at'>
        Update: Partial<Database['public']['Tables']['rice_analysis_records']['Insert']>
      }
    }
  }
}

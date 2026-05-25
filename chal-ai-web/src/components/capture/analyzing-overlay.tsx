'use client'

import { Loader2, Microscope } from 'lucide-react'

export function AnalyzingOverlay() {
  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex flex-col items-center justify-center gap-6">
      <div className="h-20 w-20 rounded-full bg-green-600/20 flex items-center justify-center">
        <Microscope className="h-10 w-10 text-green-400" />
      </div>
      <div className="text-center text-white space-y-2">
        <div className="flex items-center gap-2 justify-center">
          <Loader2 className="h-5 w-5 animate-spin text-green-400" />
          <span className="text-lg font-semibold">Analyzing rice grains...</span>
        </div>
        <p className="text-sm text-gray-300">AI is detecting and classifying grains. This may take up to 60 seconds.</p>
      </div>
    </div>
  )
}

'use client'

import { useRef, useState, useCallback } from 'react'
import { Upload, X, ImageIcon } from 'lucide-react'
import { cn } from '@/lib/utils'
import Image from 'next/image'

interface Props {
  file: File | null
  onFileChange: (file: File | null) => void
}

export function ImageDropZone({ file, onFileChange }: Props) {
  const inputRef = useRef<HTMLInputElement>(null)
  const [dragging, setDragging] = useState(false)
  const previewUrl = file ? URL.createObjectURL(file) : null

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setDragging(false)
    const dropped = e.dataTransfer.files[0]
    if (dropped && dropped.type.startsWith('image/')) {
      onFileChange(dropped)
    }
  }, [onFileChange])

  if (file && previewUrl) {
    return (
      <div className="relative rounded-xl overflow-hidden border bg-muted aspect-video">
        <Image src={previewUrl} alt="Selected image" fill className="object-contain" unoptimized />
        <button
          onClick={() => onFileChange(null)}
          className="absolute top-2 right-2 bg-black/60 hover:bg-black/80 text-white rounded-full p-1 transition-colors"
        >
          <X className="h-4 w-4" />
        </button>
        <div className="absolute bottom-2 left-2 bg-black/60 text-white text-xs rounded px-2 py-1">
          {file.name}
        </div>
      </div>
    )
  }

  return (
    <div
      className={cn(
        'border-2 border-dashed rounded-xl p-10 flex flex-col items-center justify-center gap-3 cursor-pointer transition-colors aspect-video',
        dragging
          ? 'border-green-500 bg-green-50 dark:bg-green-950/20'
          : 'border-muted-foreground/25 hover:border-green-400 hover:bg-muted/50'
      )}
      onDrop={handleDrop}
      onDragOver={e => { e.preventDefault(); setDragging(true) }}
      onDragLeave={() => setDragging(false)}
      onClick={() => inputRef.current?.click()}
    >
      <div className="h-14 w-14 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
        <ImageIcon className="h-7 w-7 text-green-600" />
      </div>
      <div className="text-center">
        <p className="font-medium">Drop your rice grain image here</p>
        <p className="text-sm text-muted-foreground mt-1">or click to browse — JPEG, PNG up to 10MB</p>
      </div>
      <div className="flex items-center gap-2 text-muted-foreground text-sm">
        <Upload className="h-4 w-4" />
        <span>Upload Image</span>
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/jpg"
        className="hidden"
        onChange={e => onFileChange(e.target.files?.[0] ?? null)}
      />
    </div>
  )
}

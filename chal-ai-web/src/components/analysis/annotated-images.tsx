'use client'

import { useState, useEffect } from 'react'
import Image from 'next/image'
import { Dialog, DialogContent } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Expand, Download } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

const BUCKET = process.env.NEXT_PUBLIC_SUPABASE_BUCKET ?? 'rice-images'

function useSignedUrl(path: string | null) {
  const [url, setUrl] = useState<string | null>(null)

  useEffect(() => {
    if (!path) return
    const supabase = createClient()
    supabase.storage.from(BUCKET).createSignedUrl(path, 3600).then(({ data }) => {
      if (data?.signedUrl) setUrl(data.signedUrl)
    })
  }, [path])

  return url
}

function ImagePanel({ label, path }: { label: string; path: string | null }) {
  const url = useSignedUrl(path)
  const [open, setOpen] = useState(false)

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium text-muted-foreground">{label}</p>
      <div className="relative aspect-video rounded-xl overflow-hidden bg-muted border">
        {!url ? (
          <Skeleton className="w-full h-full" />
        ) : (
          <>
            <Image src={url} alt={label} fill className="object-contain" unoptimized />
            <div className="absolute top-2 right-2 flex gap-1">
              <Button size="icon" variant="secondary" className="h-7 w-7" onClick={() => setOpen(true)}>
                <Expand className="h-3.5 w-3.5" />
              </Button>
              <a href={url} download>
                <Button size="icon" variant="secondary" className="h-7 w-7">
                  <Download className="h-3.5 w-3.5" />
                </Button>
              </a>
            </div>
          </>
        )}
      </div>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-4xl p-2">
          {url && <Image src={url} alt={label} width={1200} height={900} className="w-full h-auto" unoptimized />}
        </DialogContent>
      </Dialog>
    </div>
  )
}

export function AnnotatedImages({
  morphologyPath,
  colorPath,
}: {
  morphologyPath: string | null
  colorPath: string | null
}) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <ImagePanel label="Morphology Analysis" path={morphologyPath} />
      <ImagePanel label="Color Analysis" path={colorPath} />
    </div>
  )
}

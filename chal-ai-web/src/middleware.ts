import { type NextRequest, NextResponse } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'
import type { UserRole } from '@/types/auth'

const AUTH_ROUTES = ['/login', '/signup', '/forgot-password', '/reset-password']
const SETUP_ROUTE = '/profile-setup'
const ADMIN_ROUTES = ['/admin']
const VERIFIED_ROUTES = ['/verified']

function roleHome(role: UserRole): string {
  if (role === 'admin') return '/admin'
  if (role === 'verified') return '/verified'
  return '/dashboard'
}

function isAuthRoute(pathname: string) {
  return AUTH_ROUTES.some(r => pathname.startsWith(r))
}

function isAdminRoute(pathname: string) {
  return ADMIN_ROUTES.some(r => pathname.startsWith(r))
}

function isVerifiedRoute(pathname: string) {
  return VERIFIED_ROUTES.some(r => pathname.startsWith(r))
}

function isProtectedRoute(pathname: string) {
  return !isAuthRoute(pathname) && pathname !== SETUP_ROUTE && !pathname.startsWith('/auth')
}

export async function middleware(request: NextRequest) {
  const { supabase, supabaseResponse } = await updateSession(request)
  const pathname = request.nextUrl.pathname

  // Get current user session
  const { data: { user } } = await supabase.auth.getUser()

  // Unauthenticated users can only access auth routes
  if (!user) {
    if (isProtectedRoute(pathname)) {
      const url = request.nextUrl.clone()
      url.pathname = '/login'
      return NextResponse.redirect(url)
    }
    return supabaseResponse
  }

  // Authenticated users should not see auth pages
  if (isAuthRoute(pathname)) {
    // Check role to redirect to correct home
    const cachedRole = request.cookies.get('chalai-role')?.value as UserRole | undefined
    const home = cachedRole ? roleHome(cachedRole) : '/dashboard'
    const url = request.nextUrl.clone()
    url.pathname = home
    return NextResponse.redirect(url)
  }

  // Fetch role — use cached cookie if present, else query DB
  let role: UserRole = 'user'
  const cachedRole = request.cookies.get('chalai-role')?.value as UserRole | undefined

  if (cachedRole) {
    role = cachedRole
  } else {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!profile) {
      // No profile yet — send to setup unless already there
      if (pathname !== SETUP_ROUTE) {
        const url = request.nextUrl.clone()
        url.pathname = SETUP_ROUTE
        return NextResponse.redirect(url)
      }
      return supabaseResponse
    }

    role = profile.role as UserRole
    // Cache role in cookie for 1 hour
    supabaseResponse.cookies.set('chalai-role', role, {
      maxAge: 3600,
      httpOnly: true,
      sameSite: 'lax',
    })
  }

  // Profile setup: if already has profile, redirect away from setup
  if (pathname === SETUP_ROUTE) {
    const url = request.nextUrl.clone()
    url.pathname = roleHome(role)
    return NextResponse.redirect(url)
  }

  // Role-based route protection
  if (isAdminRoute(pathname) && role !== 'admin') {
    const url = request.nextUrl.clone()
    url.pathname = roleHome(role)
    return NextResponse.redirect(url)
  }

  if (isVerifiedRoute(pathname) && role !== 'verified' && role !== 'admin') {
    const url = request.nextUrl.clone()
    url.pathname = roleHome(role)
    return NextResponse.redirect(url)
  }

  // Admin navigating to /dashboard → send to /admin
  if (pathname === '/dashboard' && role === 'admin') {
    const url = request.nextUrl.clone()
    url.pathname = '/admin'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}

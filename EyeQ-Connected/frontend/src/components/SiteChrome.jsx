import { Link } from 'react-router-dom'
import Logo from './Logo.jsx'

const navLinks = [
  { label: 'Home', href: '/' },
  { label: 'About', href: '/about' },
  { label: 'How It Works', href: '/how-it-works' },
  { label: 'Contact', href: '/contact' },
]

export function SiteHeader() {
  return (
    <header className="flex items-center justify-between px-6 md:px-12 py-5 border-b border-black/5">
      <Logo size="lg" />
      <nav className="hidden md:flex items-center gap-8 text-[15px] font-medium text-ink-800">
        {navLinks.map((l) => (
          <Link key={l.label} to={l.href} className="hover:text-brand-600 transition-colors">
            {l.label}
          </Link>
        ))}
      </nav>
      <Link
        to="/dashboard"
        className="rounded-full bg-brand-600 px-6 py-2.5 text-sm font-semibold text-white hover:bg-brand-700 transition-colors"
      >
        Get Started
      </Link>
    </header>
  )
}

export function SiteFooter() {
  return (
    <footer className="border-t border-black/5 px-6 md:px-12 py-8">
      <div className="mx-auto max-w-6xl flex flex-col md:flex-row items-center justify-between gap-4">
        <Logo />
        <p className="text-xs text-ink-800/50">© {new Date().getFullYear()} EyeQ. All rights reserved.</p>
      </div>
    </footer>
  )
}

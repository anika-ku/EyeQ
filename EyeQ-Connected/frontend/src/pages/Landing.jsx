import { Link } from 'react-router-dom'
import { Clock, ScanEye, BrainCircuit, Users, TrendingUp, ArrowUpRight } from 'lucide-react'
import Logo from '../components/Logo.jsx'

const navLinks = [
  { label: 'Home', href: '/' },
  { label: 'About', href: '/about' },
  { label: 'How It Works', href: '/how-it-works' },
  { label: 'Contact', href: '/contact' },
]

const features = [
  {
    icon: ScanEye,
    title: 'Early Detection',
    desc: 'Identify risks before vision loss begins',
  },
  {
    icon: BrainCircuit,
    title: 'AI-Powered',
    desc: 'accurate & explainable predictions',
  },
  {
    icon: Users,
    title: 'Rural Focus',
    desc: 'accessible healthcare for all',
  },
  {
    icon: TrendingUp,
    title: 'Better Tomorrow',
    desc: 'healthcare communities, stronger futures',
  },
]

export default function Landing() {
  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
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

      {/* Hero */}
      <section className="bg-surface-50 px-6 md:px-12 pt-14 pb-10">
        <div className="mx-auto max-w-6xl grid md:grid-cols-2 gap-10 items-center">
          <div>
            <span className="inline-flex items-center gap-2 rounded-full bg-brand-100 px-4 py-1.5 text-sm font-medium text-brand-700 mb-6">
              <Clock size={15} />
              AI-Powered Retinal Screening
            </span>
            <h1 className="text-4xl md:text-5xl font-extrabold leading-[1.1] text-ink-900">
              Bringing retinal screening closer to{' '}
              <span className="font-serif italic text-brand-600 font-semibold">everyone</span>
            </h1>
            <p className="mt-6 text-ink-800/70 text-base leading-relaxed max-w-md">
              EyeQ uses advanced AI to detect diabetic retinopathy early – helping people
              protect their vision, especially in underserved and rural communities.
            </p>
            <Link
              to="/dashboard"
              className="mt-8 inline-flex items-center gap-2 rounded-full bg-brand-600 px-7 py-3.5 text-sm font-semibold text-white hover:bg-brand-700 transition-colors"
            >
              Start Screening
              <ArrowUpRight size={16} />
            </Link>
          </div>

          <div className="relative flex items-center justify-center">
            <div className="absolute inset-0 rounded-full bg-brand-100/60 blur-2xl" />
            <div className="relative w-72 h-72 md:w-80 md:h-80 rounded-full border-[10px] border-ink-900 overflow-hidden shadow-xl bg-[radial-gradient(circle_at_60%_45%,#f4b183,#8a2f1c_70%)]">
              <div className="absolute left-1/2 top-1/2 h-10 w-10 -translate-x-1/2 -translate-y-1/2 rounded-full bg-orange-200/90 blur-[2px]" />
            </div>
          </div>
        </div>
      </section>

      {/* Feature strip */}
      <section className="px-6 md:px-12 pb-16 -mt-2">
        <div className="mx-auto max-w-6xl rounded-2xl bg-white border border-black/5 shadow-sm px-8 py-8 grid grid-cols-2 md:grid-cols-4 gap-8">
          {features.map(({ icon: Icon, title, desc }) => (
            <div key={title} className="flex items-start gap-3">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand-100 text-brand-700">
                <Icon size={20} />
              </span>
              <div>
                <p className="font-semibold text-ink-900 text-sm">{title}</p>
                <p className="text-xs text-ink-800/60 mt-0.5">{desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}

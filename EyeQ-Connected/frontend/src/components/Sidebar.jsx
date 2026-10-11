import { LayoutGrid, ScanLine, Settings, Files, Activity } from 'lucide-react'
import { NavLink } from 'react-router-dom'
import Logo from './Logo.jsx'

const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutGrid },
  { to: '/new-screening', label: 'New Screening', icon: ScanLine },
  { to: '/bulk-screening', label: 'Bulk Screening', icon: Files },
  { to: '/simulation', label: 'Simulation', icon: Activity },
  { to: '/settings', label: 'Settings', icon: Settings },
]

export default function Sidebar({ doctorName = 'Dr. Arun Sharma', doctorRole = 'Opthalmologist' }) {
  return (
    <aside className="hidden md:flex md:w-64 shrink-0 flex-col justify-between bg-white px-6 py-8 border-r border-black/5">
      <div>
        <div className="mb-10">
          <Logo />
        </div>
        <nav className="space-y-1">
          {navItems.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-brand-50 text-brand-700'
                    : 'text-ink-800/70 hover:bg-surface-100 hover:text-ink-900'
                }`
              }
            >
              <Icon size={18} strokeWidth={2} />
              {label}
            </NavLink>
          ))}
        </nav>
      </div>

      <div>
        <p className="text-sm font-semibold text-ink-900">{doctorName}</p>
        <p className="text-xs text-ink-800/50">{doctorRole}</p>
      </div>
    </aside>
  )
}

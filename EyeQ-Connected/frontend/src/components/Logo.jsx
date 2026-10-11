import { Eye } from 'lucide-react'
import { Link } from 'react-router-dom'

export default function Logo({ size = 'md' }) {
  const textSize = size === 'lg' ? 'text-2xl' : 'text-xl'
  const iconSize = size === 'lg' ? 22 : 18

  return (
    <Link to="/" className="flex items-center gap-2 shrink-0">
      <Eye size={iconSize} className="text-brand-600" strokeWidth={2.4} />
      <span className={`${textSize} font-extrabold tracking-tight text-ink-900`}>EyeQ</span>
    </Link>
  )
}

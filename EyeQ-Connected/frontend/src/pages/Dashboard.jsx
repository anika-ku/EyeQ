import { useEffect, useState } from 'react'
import { getDashboard } from '../api.js'
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import Sidebar from '../components/Sidebar.jsx'


const emptyStats = [
  { label: 'Total Screenings', value: 0, bg: 'bg-brand-100', text: 'text-brand-700' },
  { label: 'Referable Cases', value: 0, bg: 'bg-rose-100', text: 'text-rose-600' },
  { label: 'Positive Cases', value: 0, bg: 'bg-slate-200', text: 'text-slate-700' },
]
export default function Dashboard() {
  const [dashboard, setDashboard] = useState(null)
  useEffect(() => { getDashboard().then(setDashboard).catch(() => setDashboard({ totalScreenings: 0, referableCases: 0, positiveCases: 0, recentActivity: [] })) }, [])
  const trendData = dashboard?.trend || []
  const stats = [
    { ...emptyStats[0], value: dashboard?.totalScreenings ?? 0 },
    { ...emptyStats[1], value: dashboard?.referableCases ?? 0 },
    { ...emptyStats[2], value: dashboard?.positiveCases ?? 0 },
  ]
  const activity = dashboard?.recentActivity || []

  return (
    <div className="min-h-screen flex bg-surface-50">
      <Sidebar />

      <main className="flex-1 px-6 md:px-10 py-10 max-w-6xl">
        <h1 className="text-3xl font-extrabold text-ink-900">Good Morning, Dr. Sharma!</h1>
        <p className="mt-2 text-ink-800/60 text-sm">Here's a quick overview of your screenings.</p>

        {/* Stat cards */}
        <div className="mt-8 grid grid-cols-1 sm:grid-cols-3 gap-5">
          {stats.map((s) => (
            <div
              key={s.label}
              className="rounded-2xl bg-white border border-black/5 px-6 py-5 flex items-center justify-between"
            >
              <span className="text-sm font-medium text-ink-800/70">{s.label}</span>
              <span
                className={`flex h-11 w-11 items-center justify-center rounded-full font-bold ${s.bg} ${s.text}`}
              >
                {s.value}
              </span>
            </div>
          ))}
        </div>

        <div className="mt-6 grid md:grid-cols-3 gap-5">
          {/* Trends chart */}
          <div className="md:col-span-2 rounded-2xl bg-white border border-black/5 px-6 py-6">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-ink-900">Screening Trends</h2>
              <span className="rounded-full bg-surface-100 px-4 py-1.5 text-xs font-medium text-ink-800/60">Recorded screenings</span>
            </div>
            <div className="mt-4 h-64">
              {trendData.length ? (
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={trendData} margin={{ top: 8, right: 8, left: -20, bottom: 0 }}>
                    <CartesianGrid vertical={false} stroke="#eef2f1" />
                    <XAxis dataKey="month" tickLine={false} axisLine={false} tick={{ fontSize: 11, fill: '#94a3ac' }} />
                    <YAxis allowDecimals={false} tickLine={false} axisLine={false} tick={{ fontSize: 11, fill: '#94a3ac' }} />
                    <Tooltip />
                    <Line type="monotone" dataKey="screenings" stroke="#0c8a73" strokeWidth={2.5} dot={{ r: 3 }} />
                  </LineChart>
                </ResponsiveContainer>
              ) : (
                <div className="h-full rounded-xl bg-surface-100 flex items-center justify-center px-8 text-center text-sm text-ink-800/50">No historical screening data has been recorded yet. Run screenings to build this chart from real sessions.</div>
              )}
            </div>
          </div>

          {/* Recent activity */}
          <div className="rounded-2xl bg-white border border-black/5 px-6 py-6">
            <h2 className="text-lg font-bold text-ink-900">Recent Activity</h2>
            <ul className="mt-4 space-y-3">
              {activity.map((a) => (
                <li key={a.title} className="rounded-xl bg-surface-100 px-4 py-3">
                  <p className="text-sm font-medium text-ink-900">{a.title}</p>
                  <p className="text-xs text-ink-800/50 mt-0.5">{a.time}</p>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </main>
    </div>
  )
}

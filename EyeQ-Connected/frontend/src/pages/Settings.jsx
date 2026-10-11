import { useState } from 'react'
import { Check } from 'lucide-react'
import Sidebar from '../components/Sidebar.jsx'

const STORAGE_KEY = 'eyeq_settings'

const defaultSettings = {
  doctorName: 'Dr. Arun Sharma',
  role: 'Ophthalmologist',
  clinic: 'Community Eye Care Center',
  email: 'arun.sharma@example.com',
  referableAlerts: true,
  weeklySummary: false,
  soundOnComplete: true,
  riskSensitivity: 'Medium',
  autoQualityCheck: true,
  reportFormat: 'PDF',
  language: 'English',
  dateFormat: 'DD/MM/YYYY',
}

function loadSettings() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? { ...defaultSettings, ...JSON.parse(raw) } : defaultSettings
  } catch {
    return defaultSettings
  }
}

const inputClass =
  'mt-1.5 w-full rounded-xl bg-surface-100 px-4 py-2.5 text-sm text-ink-900 outline-none focus:ring-2 focus:ring-brand-400'

function Field({ label, children }) {
  return (
    <label className="block">
      <span className="text-xs font-medium text-ink-800/60">{label}</span>
      {children}
    </label>
  )
}

function Toggle({ checked, onChange }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${
        checked ? 'bg-brand-600' : 'bg-surface-100 border border-black/10'
      }`}
    >
      <span
        className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${
          checked ? 'translate-x-5' : 'translate-x-0.5'
        }`}
      />
    </button>
  )
}

function ToggleRow({ title, desc, checked, onChange }) {
  return (
    <div className="flex items-center justify-between gap-4">
      <div>
        <p className="text-sm font-medium text-ink-900">{title}</p>
        <p className="text-xs text-ink-800/50">{desc}</p>
      </div>
      <Toggle checked={checked} onChange={onChange} />
    </div>
  )
}

export default function Settings() {
  const [settings, setSettings] = useState(loadSettings)
  const [saved, setSaved] = useState(false)

  function update(key, value) {
    setSettings((s) => ({ ...s, [key]: value }))
    setSaved(false)
  }

  function handleSave(e) {
    e.preventDefault()
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings))
    setSaved(true)
    setTimeout(() => setSaved(false), 2500)
  }

  return (
    <div className="min-h-screen flex bg-surface-50">
      <Sidebar />

      <main className="flex-1 px-6 md:px-10 py-10 max-w-3xl">
        <h1 className="text-3xl font-extrabold text-ink-900">Settings</h1>
        <p className="mt-2 text-ink-800/60 text-sm">
          Manage your profile, notifications and screening preferences.
        </p>

        <form onSubmit={handleSave} className="mt-8 space-y-5">
          {/* Profile */}
          <section className="rounded-2xl bg-white border border-black/5 px-6 py-6">
            <h2 className="text-lg font-bold text-ink-900">Profile</h2>
            <div className="mt-4 grid sm:grid-cols-2 gap-4">
              <Field label="Full Name">
                <input
                  className={inputClass}
                  value={settings.doctorName}
                  onChange={(e) => update('doctorName', e.target.value)}
                />
              </Field>
              <Field label="Role / Title">
                <input
                  className={inputClass}
                  value={settings.role}
                  onChange={(e) => update('role', e.target.value)}
                />
              </Field>
              <Field label="Clinic / Hospital">
                <input
                  className={inputClass}
                  value={settings.clinic}
                  onChange={(e) => update('clinic', e.target.value)}
                />
              </Field>
              <Field label="Email Address">
                <input
                  type="email"
                  className={inputClass}
                  value={settings.email}
                  onChange={(e) => update('email', e.target.value)}
                />
              </Field>
            </div>
          </section>

          {/* Notifications */}
          <section className="rounded-2xl bg-white border border-black/5 px-6 py-6">
            <h2 className="text-lg font-bold text-ink-900">Notifications</h2>
            <div className="mt-4 space-y-4">
              <ToggleRow
                title="Referable case alerts"
                desc="Email me immediately when a screening is flagged as referable."
                checked={settings.referableAlerts}
                onChange={(v) => update('referableAlerts', v)}
              />
              <ToggleRow
                title="Weekly summary report"
                desc="A digest of screenings and trends every Monday."
                checked={settings.weeklySummary}
                onChange={(v) => update('weeklySummary', v)}
              />
              <ToggleRow
                title="Sound on analysis complete"
                desc="Play a short sound when a screening finishes processing."
                checked={settings.soundOnComplete}
                onChange={(v) => update('soundOnComplete', v)}
              />
            </div>
          </section>

          {/* Screening preferences */}
          <section className="rounded-2xl bg-white border border-black/5 px-6 py-6">
            <h2 className="text-lg font-bold text-ink-900">Screening Preferences</h2>
            <div className="mt-4 grid sm:grid-cols-2 gap-4">
              <Field label="Risk Sensitivity">
                <select
                  className={inputClass}
                  value={settings.riskSensitivity}
                  onChange={(e) => update('riskSensitivity', e.target.value)}
                >
                  <option>Low</option>
                  <option>Medium</option>
                  <option>High</option>
                </select>
              </Field>
              <Field label="Report Format">
                <select
                  className={inputClass}
                  value={settings.reportFormat}
                  onChange={(e) => update('reportFormat', e.target.value)}
                >
                  <option>PDF</option>
                  <option>HTML</option>
                </select>
              </Field>
            </div>
            <div className="mt-4">
              <ToggleRow
                title="Auto image quality check"
                desc="Flag blurry or poorly lit fundus images before analysis."
                checked={settings.autoQualityCheck}
                onChange={(v) => update('autoQualityCheck', v)}
              />
            </div>
          </section>

          {/* Regional */}
          <section className="rounded-2xl bg-white border border-black/5 px-6 py-6">
            <h2 className="text-lg font-bold text-ink-900">Regional</h2>
            <div className="mt-4 grid sm:grid-cols-2 gap-4">
              <Field label="Language">
                <select
                  className={inputClass}
                  value={settings.language}
                  onChange={(e) => update('language', e.target.value)}
                >
                  <option>English</option>
                  <option>Hindi</option>
                  <option>Tamil</option>
                  <option>Telugu</option>
                </select>
              </Field>
              <Field label="Date Format">
                <select
                  className={inputClass}
                  value={settings.dateFormat}
                  onChange={(e) => update('dateFormat', e.target.value)}
                >
                  <option>DD/MM/YYYY</option>
                  <option>MM/DD/YYYY</option>
                  <option>YYYY-MM-DD</option>
                </select>
              </Field>
            </div>
          </section>

          <div className="flex items-center gap-4 pt-1">
            <button
              type="submit"
              className="rounded-full bg-brand-600 px-7 py-3 text-sm font-semibold text-white hover:bg-brand-700 transition-colors"
            >
              Save Changes
            </button>
            {saved && (
              <span className="flex items-center gap-1.5 text-sm font-medium text-brand-700">
                <Check size={16} /> Saved
              </span>
            )}
          </div>
        </form>
      </main>
    </div>
  )
}

import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, Activity, Gauge, Network, Users, Camera, Cpu, Play, AlertTriangle } from 'lucide-react'
import Sidebar from '../components/Sidebar.jsx'
import { runSimulation, optimizeSimulation } from '../api.js'

const defaults = {
  patientsPerYear: 100000,
  workingDaysPerYear: 300,
  operatingHoursPerDay: 8,
  numCameras: 20,
  imagesPerCameraPerHour: 8,
  bandwidthMbps: 10,
  imageSizeMB: 2.5,
  aiWorkers: 4,
  aiImagesPerHour: 60,
  reviewers: 5,
  reviewsPerHour: 12,
}

function Field({ label, value, onChange, step = 1 }) {
  return <label className="block">
    <span className="text-xs font-medium text-ink-800/60">{label}</span>
    <input type="number" min="0" step={step} value={value} onChange={e => onChange(Number(e.target.value))}
      className="mt-1.5 w-full rounded-xl border border-black/10 bg-white px-3 py-2.5 text-sm outline-none focus:border-brand-400" />
  </label>
}

export default function Simulation() {
  const [params, setParams] = useState(defaults)
  const [result, setResult] = useState(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [optimized, setOptimized] = useState(null)
  const set = (key, value) => setParams(p => ({ ...p, [key]: value }))

  async function optimize() {
    setBusy(true); setError(''); setOptimized(null)
    try { setOptimized(await optimizeSimulation({ ...params, targetCoveragePercent: 90 })) }
    catch (e) { setError(e.message || 'Optimization failed.') }
    finally { setBusy(false) }
  }

  async function run() {
    setBusy(true); setError('')
    try { setResult(await runSimulation(params)) }
    catch (e) { setError(e.message || 'Simulation failed.') }
    finally { setBusy(false) }
  }

  const cards = result ? [
    ['Daily throughput', `${Math.round(result.capacityPerDay).toLocaleString()}`, Activity],
    ['Annual capacity', `${Math.round(result.annualCapacity).toLocaleString()}`, Gauge],
    ['Coverage', `${result.coveragePercent.toFixed(1)}%`, Network],
    ['Avg. wait', `${result.averageWaitHours.toFixed(1)} h`, Users],
  ] : []

  return <div className="min-h-screen flex bg-surface-50"><Sidebar /><main className="flex-1 px-6 md:px-10 py-10 max-w-7xl">
    <Link to="/dashboard" className="inline-flex items-center gap-2 text-sm text-ink-800/70"><ArrowLeft size={15}/> Back</Link>
    <div className="mt-3 flex flex-wrap items-end justify-between gap-4">
      <div><h1 className="text-3xl font-extrabold text-ink-900">Rural Telemedicine Simulation</h1><p className="mt-1 text-sm text-ink-800/60">Model acquisition, bandwidth, AI throughput and specialist review capacity for a district programme.</p></div>
      <div className="flex gap-2"><button onClick={optimize} disabled={busy} className="rounded-full border border-brand-200 bg-white px-5 py-3 text-sm font-semibold text-brand-700 disabled:opacity-50">Optimize Resources</button><button onClick={run} disabled={busy} className="inline-flex items-center gap-2 rounded-full bg-brand-600 px-6 py-3 text-sm font-semibold text-white disabled:opacity-50"><Play size={15}/>{busy ? 'Running…' : 'Run Simulation'}</button></div>
    </div>

    <div className="mt-7 grid lg:grid-cols-5 gap-5">
      <section className="lg:col-span-2 rounded-2xl bg-white border border-black/5 p-6">
        <h2 className="text-lg font-bold">Programme inputs</h2>
        <div className="mt-5 grid sm:grid-cols-2 gap-4">
          <Field label="Patients / year" value={params.patientsPerYear} onChange={v=>set('patientsPerYear',v)} />
          <Field label="Working days / year" value={params.workingDaysPerYear} onChange={v=>set('workingDaysPerYear',v)} />
          <Field label="Operating hours / day" value={params.operatingHoursPerDay} step={0.5} onChange={v=>set('operatingHoursPerDay',v)} />
          <Field label="Fundus cameras" value={params.numCameras} onChange={v=>set('numCameras',v)} />
          <Field label="Images / camera / hour" value={params.imagesPerCameraPerHour} step={0.5} onChange={v=>set('imagesPerCameraPerHour',v)} />
          <Field label="Bandwidth (Mbps)" value={params.bandwidthMbps} step={0.5} onChange={v=>set('bandwidthMbps',v)} />
          <Field label="Image size (MB)" value={params.imageSizeMB} step={0.1} onChange={v=>set('imageSizeMB',v)} />
          <Field label="AI workers" value={params.aiWorkers} onChange={v=>set('aiWorkers',v)} />
          <Field label="AI images / worker / hour" value={params.aiImagesPerHour} onChange={v=>set('aiImagesPerHour',v)} />
          <Field label="Specialist reviewers" value={params.reviewers} onChange={v=>set('reviewers',v)} />
          <Field label="Reviews / specialist / hour" value={params.reviewsPerHour} onChange={v=>set('reviewsPerHour',v)} />
        </div>
      </section>

      <section className="lg:col-span-3 rounded-2xl bg-white border border-black/5 p-6">
        <h2 className="text-lg font-bold">Pipeline capacity</h2>
        <div className="mt-5 grid sm:grid-cols-4 gap-3">
          {[[Camera,'Acquisition'],[Network,'Network'],[Cpu,'AI'],[Users,'Review']].map(([Icon,label]) => <div key={label} className="rounded-xl bg-surface-100 p-4"><Icon size={18} className="text-brand-600"/><p className="mt-3 text-sm font-semibold">{label}</p><p className="text-xs text-ink-800/50">Capacity is calculated from the inputs.</p></div>)}
        </div>
        {result ? <>
          <div className="mt-6 grid sm:grid-cols-2 xl:grid-cols-4 gap-3">{cards.map(([label,value,Icon])=><div key={label} className="rounded-xl bg-brand-50 p-4"><Icon size={17} className="text-brand-700"/><p className="mt-2 text-xs text-ink-800/50">{label}</p><p className="mt-1 text-xl font-extrabold text-brand-800">{value}</p></div>)}</div>
          <div className="mt-5 rounded-2xl border border-black/5 p-5">
            <p className="text-xs uppercase tracking-wide text-ink-800/40">Current bottleneck</p>
            <p className="mt-1 text-2xl font-extrabold text-ink-900">{result.bottleneck}</p>
            <div className="mt-4 grid sm:grid-cols-4 gap-3">{Object.entries(result.utilization || {}).map(([key,value])=><div key={key}><div className="flex justify-between text-xs mb-1"><span className="capitalize">{key}</span><span>{Number(value).toFixed(0)}%</span></div><div className="h-2 rounded-full bg-surface-100 overflow-hidden"><div className="h-full bg-brand-500 rounded-full" style={{width:`${Math.min(100,Number(value))}%`}} /></div></div>)}</div>
          </div>
          <div className="mt-4 rounded-xl bg-surface-100 px-4 py-3 text-xs text-ink-800/60"><strong>Simulink:</strong> {result.simulink?.message || 'Not run.'}</div>
        </> : <div className="mt-7 rounded-2xl bg-surface-100 p-8 text-center text-sm text-ink-800/50">Set the district resources and run the simulation to see the system bottleneck and sustainable capacity.</div>}
        {optimized?.found && <div className="mt-5 rounded-2xl bg-brand-50 border border-brand-100 p-5"><p className="text-xs uppercase tracking-wide text-brand-700/60">90% coverage configuration</p><div className="mt-3 grid sm:grid-cols-5 gap-3 text-sm"><div><span className="text-xs text-ink-800/50">Cameras</span><p className="font-bold">{optimized.recommendation.cameras}</p></div><div><span className="text-xs text-ink-800/50">AI workers</span><p className="font-bold">{optimized.recommendation.aiWorkers}</p></div><div><span className="text-xs text-ink-800/50">Reviewers</span><p className="font-bold">{optimized.recommendation.reviewers}</p></div><div><span className="text-xs text-ink-800/50">Bandwidth</span><p className="font-bold">{optimized.recommendation.bandwidthMbps} Mbps</p></div><div><span className="text-xs text-ink-800/50">Coverage</span><p className="font-bold">{optimized.recommendation.coveragePercent.toFixed(1)}%</p></div></div><p className="mt-3 text-[11px] text-ink-800/50">Engineering optimization based on the configured assumptions; not a clinical or procurement recommendation.</p></div>}
        {error && <div className="mt-4 flex gap-2 rounded-xl bg-rose-50 px-4 py-3 text-sm text-rose-700"><AlertTriangle size={17}/>{error}</div>}
      </section>
    </div>
  </main></div>
}

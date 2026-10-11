import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, UploadCloud } from 'lucide-react'
import Sidebar from '../components/Sidebar.jsx'
import { analyzeBulk } from '../api.js'

export default function BulkScreening() {
  const [files, setFiles] = useState([])
  const [rows, setRows] = useState([])
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  async function run() {
    if (!files.length) return
    setBusy(true); setError(''); setRows([])
    try { setRows((await analyzeBulk(files)).results || []) }
    catch (e) { setError(e.message || 'Bulk analysis failed.') }
    finally { setBusy(false) }
  }

  return <div className="min-h-screen flex bg-surface-50"><Sidebar /><main className="flex-1 px-6 md:px-10 py-10 max-w-6xl">
    <Link to="/dashboard" className="inline-flex items-center gap-2 text-sm text-ink-800/70"><ArrowLeft size={15}/> Back</Link>
    <h1 className="mt-3 text-3xl font-extrabold text-ink-900">Bulk Screening</h1>
    <p className="mt-1 text-sm text-ink-800/60">Run the same MATLAB screening pipeline across multiple retinal images.</p>
    <label className="mt-7 flex min-h-48 cursor-pointer flex-col items-center justify-center rounded-2xl border-2 border-dashed border-brand-300 bg-brand-50 px-6 text-center">
      <UploadCloud className="text-brand-600"/>
      <span className="mt-3 text-sm font-semibold">Choose multiple fundus images</span>
      <span className="mt-1 text-xs text-ink-800/50">JPG, PNG, TIFF</span>
      <input className="hidden" type="file" multiple accept="image/*" onChange={e => setFiles(Array.from(e.target.files || []))}/>
    </label>
    {files.length > 0 && <p className="mt-3 text-sm text-ink-800/60">{files.length} image(s) selected</p>}
    <button onClick={run} disabled={!files.length || busy} className="mt-5 rounded-full bg-brand-600 px-6 py-3 text-sm font-semibold text-white disabled:opacity-40">{busy ? 'Screening…' : 'Run Bulk Screening'}</button>
    {error && <p className="mt-4 rounded-xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>}
    {rows.length > 0 && <div className="mt-7 overflow-x-auto rounded-2xl bg-white border border-black/5"><table className="w-full text-sm"><thead><tr className="text-left border-b"><th className="p-4">Image</th><th className="p-4">Prediction</th><th className="p-4">Confidence</th><th className="p-4">Referable</th><th className="p-4">Quality</th></tr></thead><tbody>{rows.map((r,i)=><tr key={r.jobId || i} className="border-b last:border-0"><td className="p-4">{r.filename}</td><td className="p-4 font-semibold">{r.error ? 'Error' : r.label}</td><td className="p-4">{r.error ? '—' : `${Math.round((r.confidence || 0)*100)}%`}</td><td className="p-4">{r.error ? '—' : r.referable ? 'Yes' : 'No'}</td><td className="p-4">{r.error || `${r.qualityScore ?? '—'} — ${r.qualityMessage || ''}`}</td></tr>)}</tbody></table></div>}
  </main></div>
}

const API_BASE = import.meta.env.VITE_API_URL || 'http://127.0.0.1:5000'

async function parse(res) {
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(data.error || `Request failed (${res.status})`)
  return data
}

export async function analyzeImage(file) {
  const form = new FormData()
  form.append('image', file)
  return parse(await fetch(`${API_BASE}/api/analyze`, { method: 'POST', body: form }))
}

export async function analyzeBulk(files) {
  const form = new FormData()
  files.forEach(f => form.append('images', f))
  return parse(await fetch(`${API_BASE}/api/bulk-analyze`, { method: 'POST', body: form }))
}

export async function getTreatment(level) {
  return parse(await fetch(`${API_BASE}/api/treatment?level=${level}`))
}

export async function getDashboard() {
  return parse(await fetch(`${API_BASE}/api/dashboard`))
}

export function assetUrl(jobId, filename) {
  return `${API_BASE}/api/results/${jobId}/${filename}`
}

export async function runSimulation(params) {
  return parse(await fetch(`${API_BASE}/api/simulation`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(params) }))
}

export async function optimizeSimulation(params) {
  return parse(await fetch(`${API_BASE}/api/simulation/optimize`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(params) }))
}

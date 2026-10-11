import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Download } from 'lucide-react'
import Logo from '../components/Logo.jsx'
import { useScreening } from '../context/ScreeningContext.jsx'
import { assetUrl, getTreatment } from '../api.js'
import { useEffect, useState } from 'react'

// ---- PDF export helpers -----------------------------------------------

// Loads an <img> (same-origin blob: URL or CORS-enabled backend URL) and
// re-encodes it as a PNG data URL via canvas so jsPDF can embed it
// regardless of the source format (png/jpg/bmp/etc).
function loadImageAsDataUrl(url) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas')
        canvas.width = img.naturalWidth
        canvas.height = img.naturalHeight
        const ctx = canvas.getContext('2d')
        ctx.drawImage(img, 0, 0)
        resolve({ dataUrl: canvas.toDataURL('image/png'), width: img.naturalWidth, height: img.naturalHeight })
      } catch (err) {
        reject(err)
      }
    }
    img.onerror = () => reject(new Error(`Could not load image: ${url}`))
    img.src = url
  })
}

// Scales srcW x srcH to fit inside maxW x maxH, preserving aspect ratio.
function fitContain(srcW, srcH, maxW, maxH) {
  const ratio = Math.min(maxW / srcW, maxH / srcH)
  return { w: srcW * ratio, h: srcH * ratio }
}

// Adds a new page and resets y if the next block won't fit above the footer.
function ensureSpace(doc, y, needed, topMargin) {
  const pageHeight = doc.internal.pageSize.getHeight()
  if (y + needed > pageHeight - 50) {
    doc.addPage()
    return topMargin
  }
  return y
}

export default function Results() {
  const navigate = useNavigate()
  const { imageUrl, result } = useScreening()
  const [care, setCare] = useState(null)
  const [isExporting, setIsExporting] = useState(false)
  const [exportError, setExportError] = useState('')
  useEffect(() => { if (result?.drLevel !== undefined) getTreatment(result.drLevel).then(setCare).catch(() => setCare(null)) }, [result])

  async function handleDownloadPdf() {
    if (!result || isExporting) return
    setIsExporting(true)
    setExportError('')
    try {
      const { jsPDF } = await import('jspdf')
      const doc = new jsPDF({ unit: 'pt', format: 'a4' })
      const pageWidth = doc.internal.pageSize.getWidth()
      const margin = 40
      let y = 54

      // Header
      doc.setFont('helvetica', 'bold')
      doc.setFontSize(20)
      doc.setTextColor(12, 138, 115)
      doc.text('EyeQ Connected', margin, y)
      doc.setFontSize(11)
      doc.setTextColor(90, 90, 90)
      doc.setFont('helvetica', 'normal')
      doc.text('Diabetic Retinopathy Screening Report', margin, y + 17)
      y += 32
      doc.setDrawColor(225, 225, 225)
      doc.line(margin, y, pageWidth - margin, y)
      y += 20

      doc.setFontSize(9)
      doc.setTextColor(130, 130, 130)
      doc.text(`Generated: ${new Date().toLocaleString()}`, margin, y)
      if (result.jobId) doc.text(`Job ID: ${result.jobId}`, pageWidth - margin, y, { align: 'right' })
      y += 26

      // Prediction
      doc.setFont('helvetica', 'bold')
      doc.setFontSize(13)
      doc.setTextColor(15, 35, 51)
      doc.text('Prediction', margin, y)
      y += 18
      doc.setFont('helvetica', 'normal')
      doc.setFontSize(11)
      doc.setTextColor(20, 20, 20)
      doc.text(`${result.label}  —  Confidence: ${Math.round(result.confidence * 100)}%`, margin, y)
      y += 17
      doc.setFontSize(10)
      doc.setTextColor(90, 90, 90)
      const summaryLines = doc.splitTextToSize(result.summary || '', pageWidth - margin * 2)
      doc.text(summaryLines, margin, y)
      y += summaryLines.length * 13 + 6
      doc.text(`Image quality: ${result.qualityScore ?? '—'} — ${result.qualityMessage ?? 'Not reported'}`, margin, y)
      y += 16
      if (result.demoModel) {
        doc.setTextColor(180, 120, 20)
        doc.text('DEMO MODEL: trained model not loaded; this output is for pipeline demonstration only.', margin, y)
        y += 16
      }
      y += 12

      // Uploaded image + Grad-CAM heatmap, side by side
      const gcUrl = result.gradCamUrl || (result.jobId && result.gradCamFile ? assetUrl(result.jobId, result.gradCamFile) : null)
      if (imageUrl || gcUrl) {
        const boxW = (pageWidth - margin * 2 - 20) / 2
        const boxH = 170
        y = ensureSpace(doc, y, boxH + 24, margin)
        doc.setFont('helvetica', 'bold')
        doc.setFontSize(10)
        doc.setTextColor(15, 35, 51)
        if (imageUrl) doc.text('Uploaded Image', margin, y)
        if (gcUrl) doc.text('Grad-CAM Heatmap', margin + boxW + 20, y)
        y += 8
        doc.setDrawColor(230, 230, 230)
        if (imageUrl) doc.rect(margin, y, boxW, boxH)
        if (gcUrl) doc.rect(margin + boxW + 20, y, boxW, boxH)

        if (imageUrl) {
          try {
            const { dataUrl, width, height } = await loadImageAsDataUrl(imageUrl)
            const { w, h } = fitContain(width, height, boxW - 10, boxH - 10)
            doc.addImage(dataUrl, 'PNG', margin + (boxW - w) / 2, y + (boxH - h) / 2, w, h)
          } catch { /* skip image if it can't be loaded */ }
        }
        if (gcUrl) {
          try {
            const { dataUrl, width, height } = await loadImageAsDataUrl(gcUrl)
            const { w, h } = fitContain(width, height, boxW - 10, boxH - 10)
            doc.addImage(dataUrl, 'PNG', margin + boxW + 20 + (boxW - w) / 2, y + (boxH - h) / 2, w, h)
          } catch { /* skip image if it can't be loaded */ }
        }
        y += boxH + 26
      }

      // Care pathway
      if (care) {
        y = ensureSpace(doc, y, 90, margin)
        doc.setFont('helvetica', 'bold')
        doc.setFontSize(13)
        doc.setTextColor(15, 35, 51)
        doc.text('Care Pathway & Illustrative Cost', margin, y)
        y += 18
        doc.setFont('helvetica', 'normal')
        doc.setFontSize(10)
        doc.setTextColor(40, 40, 40)
        doc.text(`Follow-up: ${care.followUp}`, margin, y)
        y += 15
        doc.text(`Illustrative range: ${care.costINR}`, margin, y)
        y += 15
        const noteLines = doc.splitTextToSize(`Note: ${care.note}`, pageWidth - margin * 2)
        doc.text(noteLines, margin, y)
        y += noteLines.length * 13 + 14
      }

      // Detected lesions table
      const lesions = result.lesions || []
      if (lesions.length) {
        y = ensureSpace(doc, y, 50, margin)
        doc.setFont('helvetica', 'bold')
        doc.setFontSize(13)
        doc.setTextColor(15, 35, 51)
        doc.text('Detected Lesions', margin, y)
        y += 18

        const tableW = pageWidth - margin * 2
        const col1 = tableW * 0.34
        const col2 = tableW * 0.14
        const col3 = tableW * 0.52

        doc.setFontSize(9.5)
        doc.setTextColor(130, 130, 130)
        doc.text('Finding', margin, y)
        doc.text('Count', margin + col1, y)
        doc.text('Note', margin + col1 + col2, y)
        y += 6
        doc.setDrawColor(220, 220, 220)
        doc.line(margin, y, margin + tableW, y)
        y += 14

        doc.setFont('helvetica', 'normal')
        doc.setTextColor(40, 40, 40)
        doc.setFontSize(10)
        lesions.forEach((l) => {
          const noteLines = doc.splitTextToSize(l.note || '', col3 - 6)
          const rowH = Math.max(15, noteLines.length * 13)
          y = ensureSpace(doc, y, rowH + 6, margin)
          doc.text(String(l.name ?? ''), margin, y)
          doc.text(String(l.count ?? ''), margin + col1, y)
          doc.text(noteLines, margin + col1 + col2, y)
          y += rowH + 6
        })
      }

      // Disclaimer footer + page numbers on every page
      const pageCount = doc.internal.getNumberOfPages()
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i)
        const pageHeight = doc.internal.pageSize.getHeight()
        doc.setDrawColor(235, 235, 235)
        doc.line(margin, pageHeight - 38, pageWidth - margin, pageHeight - 38)
        doc.setFont('helvetica', 'normal')
        doc.setFontSize(8)
        doc.setTextColor(150, 150, 150)
        doc.text('AI screening aid — requires clinician review. Not a diagnosis.', margin, pageHeight - 24)
        doc.text(`Page ${i} of ${pageCount}`, pageWidth - margin, pageHeight - 24, { align: 'right' })
      }

      doc.save(`EyeQ-Screening-Report-${result.jobId || Date.now()}.pdf`)
    } catch (err) {
      setExportError(err?.message || 'Could not generate the PDF report. Please try again.')
    } finally {
      setIsExporting(false)
    }
  }

  // If someone lands here directly without running a screening yet.
  if (!result) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-white text-center px-6">
        <p className="text-ink-800/60 text-sm">No screening result yet.</p>
        <button
          onClick={() => navigate('/new-screening')}
          className="rounded-full bg-brand-600 px-6 py-3 text-sm font-semibold text-white hover:bg-brand-700"
        >
          Start a New Screening
        </button>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-surface-50">
      <header className="flex items-center gap-6 px-6 md:px-10 py-5 bg-white border-b border-black/5">
        <Logo size="lg" />
        <Link
          to="/dashboard"
          className="inline-flex items-center gap-2 text-sm font-medium text-ink-800/70 hover:text-ink-900"
        >
          <ArrowLeft size={15} />
          Back to Dashboard
        </Link>
        <button
          onClick={handleDownloadPdf}
          disabled={isExporting}
          className="ml-auto inline-flex items-center gap-2 rounded-full bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Download size={15} />
          {isExporting ? 'Preparing PDF…' : 'Download PDF Report'}
        </button>
      </header>

      <main className="px-6 md:px-10 py-10 max-w-5xl mx-auto">
        <h1 className="text-3xl font-extrabold text-ink-900">Screening Results</h1>
        {exportError && (
          <div className="mt-4 rounded-xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{exportError}</div>
        )}

        <div className="mt-6 grid md:grid-cols-2 gap-5">
          {/* Uploaded image */}
          <div className="h-56 rounded-2xl bg-surface-100 overflow-hidden">
            {imageUrl && (
              <img src={imageUrl} alt="Uploaded retinal scan" className="h-full w-full object-cover" />
            )}
          </div>

          {/* Prediction */}
          <div className="h-56 rounded-2xl bg-blush-50 px-6 py-6 overflow-auto">
            <h2 className="text-lg font-bold text-ink-900">Prediction</h2>
            <p className="mt-3 text-sm font-semibold text-ink-900">{result.label}</p>
            <p className="text-xs text-ink-800/60 mt-1">
              Confidence: {Math.round(result.confidence * 100)}%
            </p>
            <p className="mt-3 text-sm text-ink-800/70 leading-relaxed">{result.summary}</p>
            <p className="mt-2 text-xs text-ink-800/50">Image quality: {result.qualityScore ?? '—'} — {result.qualityMessage ?? 'Not reported'}</p>
            {result.demoModel && <p className="mt-2 text-xs font-semibold text-amber-700">DEMO MODEL: trained model not loaded; this output is for pipeline demonstration only.</p>}
          </div>

          {/* Grad-CAM explainability */}
          <div className="rounded-2xl bg-white border border-black/5 px-6 py-6">
            <h2 className="text-lg font-bold text-ink-900">Explainability (Grad-CAM)</h2>
            <div className="mt-4 h-56 rounded-xl bg-surface-100 overflow-hidden flex items-center justify-center">
              {result.gradCamUrl || result.jobId ? (
                <img
                  src={result.gradCamUrl || assetUrl(result.jobId, result.gradCamFile)}
                  alt="Grad-CAM heatmap overlay"
                  className="h-full w-full object-contain"
                />
              ) : (
                <p className="text-xs text-ink-800/40 px-4 text-center">
                  Grad-CAM heatmap will appear here
                </p>
              )}
            </div>
            <p className="mt-2 text-[11px] text-ink-800/40">
              Warmer colors show the regions that most influenced this prediction.
            </p>
          </div>

          {care && <div className="rounded-2xl bg-white border border-black/5 px-6 py-6 md:col-span-2">
            <h2 className="text-lg font-bold text-ink-900">Care pathway & illustrative cost</h2>
            <div className="mt-3 grid sm:grid-cols-3 gap-3">
              <div className="rounded-xl bg-surface-100 p-4"><p className="text-xs text-ink-800/50">Follow-up</p><p className="mt-1 text-sm font-semibold">{care.followUp}</p></div>
              <div className="rounded-xl bg-surface-100 p-4"><p className="text-xs text-ink-800/50">Illustrative range</p><p className="mt-1 text-sm font-semibold">{care.costINR}</p></div>
              <div className="rounded-xl bg-surface-100 p-4"><p className="text-xs text-ink-800/50">Important</p><p className="mt-1 text-xs">{care.note}</p></div>
            </div>
          </div>}

          {/* Detected lesions */}
          <div className="rounded-2xl bg-white border border-black/5 px-6 py-6">
            <h2 className="text-lg font-bold text-ink-900">Detected Lesions</h2>
            <ul className="mt-4 space-y-2.5">
              {(result.lesions || []).map((l) => (
                <li
                  key={l.name}
                  className="flex items-center justify-between rounded-xl bg-surface-100 px-4 py-2.5"
                >
                  <div>
                    <p className="text-sm font-medium text-ink-900">{l.name}</p>
                    <p className="text-xs text-ink-800/50">{l.note}</p>
                  </div>
                  <span className="rounded-full bg-brand-100 px-3 py-1 text-xs font-semibold text-brand-700">
                    {l.count}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </main>
    </div>
  )
}

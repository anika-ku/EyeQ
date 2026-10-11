import { useRef, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { ArrowLeft, ArrowRight, UploadCloud, Eye } from 'lucide-react'
import Logo from '../components/Logo.jsx'
import { useScreening } from '../context/ScreeningContext.jsx'

export default function NewScreening() {
  const navigate = useNavigate()
  const fileInputRef = useRef(null)
  const [isDragging, setIsDragging] = useState(false)
  const [isAnalysing, setIsAnalysing] = useState(false)
  const { imageUrl, setImageUrl, imageFile, setImageFile, runAnalysis } = useScreening()
  const [error, setError] = useState('')

  function handleFiles(files) {
    const file = files?.[0]
    if (!file || !file.type.startsWith('image/')) return
    setImageFile(file)
    setImageUrl(URL.createObjectURL(file))
  }

  async function handleAnalyse() {
    if (!imageFile) return
    setIsAnalysing(true)
    setError('')
    try {
      await runAnalysis(imageFile)
      navigate('/results')
    } catch (e) {
      setError(e.message || 'Analysis failed. Make sure the backend and MATLAB are running.')
    } finally {
      setIsAnalysing(false)
    }
  }

  return (
    <div className="min-h-screen bg-white">
      <header className="px-6 md:px-10 py-5 border-b border-black/5">
        <Logo size="lg" />
      </header>

      <main className="px-6 md:px-10 py-10 max-w-5xl mx-auto">
        <Link
          to="/dashboard"
          className="inline-flex items-center gap-2 text-sm font-medium text-ink-800/70 hover:text-ink-900"
        >
          <ArrowLeft size={15} />
          Back
        </Link>
        <h1 className="mt-3 text-3xl font-extrabold text-ink-900">New Screening</h1>
        <p className="mt-1 text-sm text-ink-800/60">Upload a retinal image to begin the analysis</p>

        <div className="mt-8 grid md:grid-cols-2 gap-6 items-start">
          {/* Dropzone */}
          <div
            onDragOver={(e) => {
              e.preventDefault()
              setIsDragging(true)
            }}
            onDragLeave={() => setIsDragging(false)}
            onDrop={(e) => {
              e.preventDefault()
              setIsDragging(false)
              handleFiles(e.dataTransfer.files)
            }}
            className={`flex h-72 flex-col items-center justify-center gap-4 rounded-2xl border-2 border-dashed px-6 text-center transition-colors ${
              isDragging ? 'border-brand-500 bg-brand-100/60' : 'border-brand-300 bg-brand-50'
            }`}
          >
            <UploadCloud size={28} className="text-brand-600" />
            <p className="text-sm font-semibold text-ink-900">Drag &amp; Drop your image here</p>
            <span className="text-xs text-ink-800/50">or</span>
            <button
              onClick={() => fileInputRef.current?.click()}
              className="rounded-full bg-brand-100 px-6 py-2.5 text-sm font-semibold text-brand-700 hover:bg-brand-200 transition-colors"
            >
              Browse Files
            </button>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => handleFiles(e.target.files)}
            />
          </div>

          {/* Preview */}
          <div className="h-72 rounded-2xl bg-surface-100 flex items-center justify-center overflow-hidden">
            {imageUrl ? (
              <img src={imageUrl} alt="Uploaded retinal scan" className="h-full w-full object-cover" />
            ) : (
              <p className="text-sm text-ink-800/40 px-6 text-center">
                Your uploaded image will appear here
              </p>
            )}
          </div>
        </div>

        {error && <div className="mt-5 rounded-xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</div>}

        <div className="mt-8 flex items-center justify-between">
          <button
            onClick={handleAnalyse}
            disabled={!imageUrl || isAnalysing}
            className="inline-flex items-center gap-2 rounded-full bg-brand-600 px-7 py-3.5 text-sm font-semibold text-white hover:bg-brand-700 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {isAnalysing ? 'Analysing with MATLAB…' : 'Analyse Image'}
            {!isAnalysing && <ArrowRight size={16} />}
          </button>

          <span className="hidden md:flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-50">
            <Eye size={22} className="text-brand-600" />
          </span>
        </div>
      </main>
    </div>
  )
}

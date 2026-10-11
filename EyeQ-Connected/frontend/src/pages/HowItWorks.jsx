import { Upload, ScanEye, BrainCircuit, FileCheck2, ArrowUpRight } from 'lucide-react'
import { Link } from 'react-router-dom'
import { SiteHeader, SiteFooter } from '../components/SiteChrome.jsx'

const steps = [
  {
    icon: Upload,
    title: '1. Capture or Upload',
    desc: 'A health worker captures a fundus (retinal) image using a compatible camera, or uploads an existing image or a batch of images for screening.',
  },
  {
    icon: ScanEye,
    title: '2. Image Quality Check',
    desc: 'EyeQ automatically checks that the image is a valid, well-focused fundus photo before analysis, flagging retakes when quality is too low to trust.',
  },
  {
    icon: BrainCircuit,
    title: '3. AI Analysis',
    desc: 'Our deep learning model analyzes the retina for lesions associated with diabetic retinopathy — microaneurysms, hemorrhages, and exudates — and produces a risk score with a visual heatmap of the regions it focused on.',
  },
  {
    icon: FileCheck2,
    title: '4. Report & Referral',
    desc: 'A clear, shareable screening report is generated in seconds, showing the risk grade and explainability heatmap, so patients who need specialist care can be referred immediately.',
  },
]

export default function HowItWorks() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <SiteHeader />

      <section className="bg-surface-50 px-6 md:px-12 py-16">
        <div className="mx-auto max-w-4xl text-center">
          <h1 className="text-4xl md:text-5xl font-extrabold leading-[1.1] text-ink-900">
            How It <span className="font-serif italic text-brand-600 font-semibold">Works</span>
          </h1>
          <p className="mt-6 text-ink-800/70 text-base md:text-lg leading-relaxed max-w-2xl mx-auto">
            From a single retinal photo to a referral-ready report in under a minute — here's
            what happens behind the scenes.
          </p>
        </div>
      </section>

      <section className="px-6 md:px-12 py-16">
        <div className="mx-auto max-w-4xl space-y-6">
          {steps.map(({ icon: Icon, title, desc }) => (
            <div key={title} className="flex gap-5 rounded-2xl bg-surface-50 border border-black/5 p-6">
              <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-brand-100 text-brand-700">
                <Icon size={22} />
              </span>
              <div>
                <h3 className="font-semibold text-ink-900 mb-1.5">{title}</h3>
                <p className="text-sm text-ink-800/60 leading-relaxed">{desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className="px-6 md:px-12 pb-20">
        <div className="mx-auto max-w-4xl rounded-2xl bg-brand-50 border border-black/5 p-8 text-center">
          <h2 className="text-xl font-bold text-ink-900 mb-2">Ready to try it yourself?</h2>
          <p className="text-sm text-ink-800/60 mb-6 max-w-md mx-auto">
            Run a single screening or upload a batch of retinal images to see EyeQ's analysis
            in action.
          </p>
          <Link
            to="/dashboard"
            className="inline-flex items-center gap-2 rounded-full bg-brand-600 px-7 py-3.5 text-sm font-semibold text-white hover:bg-brand-700 transition-colors"
          >
            Start Screening
            <ArrowUpRight size={16} />
          </Link>
        </div>
      </section>

      <SiteFooter />
    </div>
  )
}

import { Heart, Target, Globe2, ShieldCheck } from 'lucide-react'
import { SiteHeader, SiteFooter } from '../components/SiteChrome.jsx'

const values = [
  {
    icon: Target,
    title: 'Our Mission',
    desc: 'To make diabetic retinopathy screening accessible, affordable, and fast for every community — not just those near a specialist.',
  },
  {
    icon: Globe2,
    title: 'Rural-First',
    desc: 'We build for clinics and health camps with limited connectivity and no on-site ophthalmologist, so no patient is left waiting.',
  },
  {
    icon: ShieldCheck,
    title: 'Clinically Grounded',
    desc: 'Our models are trained and validated on real fundus imaging datasets, with explainable outputs clinicians can trust and verify.',
  },
  {
    icon: Heart,
    title: 'Patient-Centered',
    desc: 'Every feature is designed around one goal: catching vision-threatening disease early enough to actually prevent blindness.',
  },
]

export default function About() {
  return (
    <div className="min-h-screen bg-white flex flex-col">
      <SiteHeader />

      <section className="bg-surface-50 px-6 md:px-12 py-16">
        <div className="mx-auto max-w-4xl text-center">
          <h1 className="text-4xl md:text-5xl font-extrabold leading-[1.1] text-ink-900">
            About <span className="font-serif italic text-brand-600 font-semibold">EyeQ</span>
          </h1>
          <p className="mt-6 text-ink-800/70 text-base md:text-lg leading-relaxed max-w-2xl mx-auto">
            EyeQ is an AI-powered retinal screening platform built to catch diabetic retinopathy
            early, especially in underserved and rural communities where access to
            ophthalmologists is limited.
          </p>
        </div>
      </section>

      <section className="px-6 md:px-12 py-16">
        <div className="mx-auto max-w-4xl">
          <h2 className="text-2xl font-bold text-ink-900 mb-4">Why we exist</h2>
          <p className="text-ink-800/70 leading-relaxed mb-4">
            Diabetic retinopathy is one of the leading causes of preventable blindness worldwide,
            yet it is often symptomless until significant, irreversible damage has occurred.
            Regular retinal screening can catch it early — but for millions of people in rural
            and underserved regions, the nearest eye specialist may be hours or days away.
          </p>
          <p className="text-ink-800/70 leading-relaxed">
            EyeQ was built to close that gap. By pairing a simple fundus camera image with an
            AI model trained to detect the early lesions of diabetic retinopathy, we give
            frontline health workers a fast, reliable way to flag at-risk patients on the spot —
            no specialist required for the first pass.
          </p>
        </div>
      </section>

      <section className="px-6 md:px-12 pb-16">
        <div className="mx-auto max-w-6xl grid sm:grid-cols-2 gap-6">
          {values.map(({ icon: Icon, title, desc }) => (
            <div key={title} className="rounded-2xl bg-surface-50 border border-black/5 p-6">
              <span className="flex h-11 w-11 items-center justify-center rounded-full bg-brand-100 text-brand-700 mb-4">
                <Icon size={20} />
              </span>
              <h3 className="font-semibold text-ink-900 mb-1.5">{title}</h3>
              <p className="text-sm text-ink-800/60 leading-relaxed">{desc}</p>
            </div>
          ))}
        </div>
      </section>

      <SiteFooter />
    </div>
  )
}

import { useState } from 'react'
import { Mail, Phone, MapPin, Send, CheckCircle2 } from 'lucide-react'
import { SiteHeader, SiteFooter } from '../components/SiteChrome.jsx'

const contactDetails = [
  { icon: Mail, label: 'Email', value: 'support@eyeq-connected.com' },
  { icon: Phone, label: 'Phone', value: '+91 98765 43210' },
  { icon: MapPin, label: 'Location', value: 'Bengaluru, India' },
]

export default function Contact() {
  const [form, setForm] = useState({ name: '', email: '', message: '' })
  const [submitted, setSubmitted] = useState(false)

  function handleChange(e) {
    setForm((f) => ({ ...f, [e.target.name]: e.target.value }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    setSubmitted(true)
  }

  return (
    <div className="min-h-screen bg-white flex flex-col">
      <SiteHeader />

      <section className="bg-surface-50 px-6 md:px-12 py-16">
        <div className="mx-auto max-w-4xl text-center">
          <h1 className="text-4xl md:text-5xl font-extrabold leading-[1.1] text-ink-900">
            Get in <span className="font-serif italic text-brand-600 font-semibold">Touch</span>
          </h1>
          <p className="mt-6 text-ink-800/70 text-base md:text-lg leading-relaxed max-w-2xl mx-auto">
            Questions about deploying EyeQ at your clinic, hospital, or health camp? We'd love
            to hear from you.
          </p>
        </div>
      </section>

      <section className="px-6 md:px-12 py-16">
        <div className="mx-auto max-w-5xl grid md:grid-cols-5 gap-10">
          <div className="md:col-span-2 space-y-5">
            {contactDetails.map(({ icon: Icon, label, value }) => (
              <div key={label} className="flex items-start gap-4 rounded-2xl bg-surface-50 border border-black/5 p-5">
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand-100 text-brand-700">
                  <Icon size={20} />
                </span>
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wide text-ink-800/50">{label}</p>
                  <p className="text-sm font-medium text-ink-900 mt-0.5">{value}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="md:col-span-3">
            {submitted ? (
              <div className="h-full flex flex-col items-center justify-center text-center rounded-2xl bg-surface-50 border border-black/5 p-10">
                <CheckCircle2 size={40} className="text-brand-600 mb-4" />
                <h3 className="font-semibold text-ink-900 mb-1.5">Message sent</h3>
                <p className="text-sm text-ink-800/60 max-w-xs">
                  Thanks for reaching out — our team will get back to you shortly.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="rounded-2xl bg-surface-50 border border-black/5 p-6 space-y-4">
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wide text-ink-800/50 mb-1.5">
                    Name
                  </label>
                  <input
                    required
                    name="name"
                    value={form.name}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-black/10 bg-white px-4 py-2.5 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-brand-400"
                    placeholder="Your name"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wide text-ink-800/50 mb-1.5">
                    Email
                  </label>
                  <input
                    required
                    type="email"
                    name="email"
                    value={form.email}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-black/10 bg-white px-4 py-2.5 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-brand-400"
                    placeholder="you@example.com"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wide text-ink-800/50 mb-1.5">
                    Message
                  </label>
                  <textarea
                    required
                    name="message"
                    value={form.message}
                    onChange={handleChange}
                    rows={5}
                    className="w-full rounded-lg border border-black/10 bg-white px-4 py-2.5 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-brand-400 resize-none"
                    placeholder="How can we help?"
                  />
                </div>
                <button
                  type="submit"
                  className="inline-flex items-center gap-2 rounded-full bg-brand-600 px-6 py-2.5 text-sm font-semibold text-white hover:bg-brand-700 transition-colors"
                >
                  Send Message
                  <Send size={15} />
                </button>
              </form>
            )}
          </div>
        </div>
      </section>

      <SiteFooter />
    </div>
  )
}

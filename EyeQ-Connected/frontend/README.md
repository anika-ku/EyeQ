# EyeQ – React Frontend

Generated from Figma screens: Landing, Dashboard, New Screening, Results.

## Setup

```bash
npm install
npm run dev
```

Then open the printed localhost URL. Routes:
- `/` — Landing page
- `/dashboard` — Doctor dashboard
- `/new-screening` — Upload flow (drag & drop or browse, works with real files)
- `/results` — Shows the uploaded image + a mock AI prediction
- `/settings` — General settings (profile, notifications, screening preferences)

## Wiring up real data

Everything marked `// TODO` uses mock/placeholder data and is the spot to connect your backend:

- `src/context/ScreeningContext.jsx` → `runMockAnalysis()` — replace with a `fetch`/API call to your
  retinal-analysis model. It currently returns a mock `label`, `confidence`, `gradCamUrl`, and `lesions` list.
- `src/pages/Dashboard.jsx` → `stats`, `trendData`, `activity` — replace with data fetched for the current doctor.

## Stack

Vite + React 18 + React Router 6 + Tailwind CSS + Recharts (for the dashboard chart) + lucide-react (icons).

## Notes

- I could not run `npm install`/build in this sandbox (no network access), so double-check with
  `npm install && npm run dev` on your machine. The code was written and reviewed carefully, but let me
  know if anything doesn't compile and I'll fix it fast.
- Colors/type are approximated from your screenshots (teal `#0c8a73`, dark navy `#0f2333`) — tweak
  `tailwind.config.js` if you have exact hex values from Figma.

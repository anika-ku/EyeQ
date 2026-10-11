import { HashRouter, Routes, Route } from 'react-router-dom'
import { ScreeningProvider } from './context/ScreeningContext.jsx'
import Landing from './pages/Landing.jsx'
import Dashboard from './pages/Dashboard.jsx'
import NewScreening from './pages/NewScreening.jsx'
import Results from './pages/Results.jsx'
import BulkScreening from './pages/BulkScreening.jsx'
import Settings from './pages/Settings.jsx'
import About from './pages/About.jsx'
import HowItWorks from './pages/HowItWorks.jsx'
import Contact from './pages/Contact.jsx'
import Simulation from './pages/Simulation.jsx'

export default function App() {
  return (
    <ScreeningProvider>
      <HashRouter>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/new-screening" element={<NewScreening />} />
          <Route path="/results" element={<Results />} />
          <Route path="/bulk-screening" element={<BulkScreening />} />
          <Route path="/simulation" element={<Simulation />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/about" element={<About />} />
          <Route path="/how-it-works" element={<HowItWorks />} />
          <Route path="/contact" element={<Contact />} />
        </Routes>
      </HashRouter>
    </ScreeningProvider>
  )
}

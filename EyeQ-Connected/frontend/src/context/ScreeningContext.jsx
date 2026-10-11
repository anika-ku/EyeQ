import { createContext, useContext, useState } from 'react'
import { analyzeImage } from '../api.js'

const ScreeningContext = createContext(null)

export function ScreeningProvider({ children }) {
  const [imageUrl, setImageUrl] = useState(null)
  const [imageFile, setImageFile] = useState(null)
  const [result, setResult] = useState(null)

  async function runAnalysis(file = imageFile) {
    if (!file) throw new Error('Please choose an image first.')
    const response = await analyzeImage(file)
    setResult(response)
    return response
  }

  return (
    <ScreeningContext.Provider value={{ imageUrl, setImageUrl, imageFile, setImageFile, result, setResult, runAnalysis }}>
      {children}
    </ScreeningContext.Provider>
  )
}

export function useScreening() {
  const ctx = useContext(ScreeningContext)
  if (!ctx) throw new Error('useScreening must be used within ScreeningProvider')
  return ctx
}

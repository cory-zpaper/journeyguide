import { useState, useEffect, useRef } from 'react'
import { useLocation } from 'react-router-dom'
import './App.css'

const API_BASE_URL = 'https://sourdough.ui.dev.sprkzdoc.com'

function App() {
  const location = useLocation()
  const [journeyData, setJourneyData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const pdfViewerRef = useRef(null)

  useEffect(() => {
    const fetchJourneyData = async () => {
      // Extract the journey ID from the path (last segment)
      const pathSegments = location.pathname.split('/').filter(Boolean)
      const journeyId = pathSegments[pathSegments.length - 1] || 'default'

      setLoading(true)
      setError(null)

      try {
        const response = await fetch(`${API_BASE_URL}/${journeyId}`)

        if (!response.ok) {
          throw new Error(`Failed to fetch journey: ${response.statusText}`)
        }

        const data = await response.json()
        setJourneyData(data)
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    fetchJourneyData()
  }, [location.pathname])

  if (loading) {
    return (
      <div className="container">
        <div className="loading">Loading journey...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="container">
        <div className="error">Error: {error}</div>
      </div>
    )
  }

  return (
    <div className="container">
      <h1>Journey Guide</h1>

      {journeyData && (
        <div className="journey-content">
          <h2>{journeyData.title || 'Journey'}</h2>

          {journeyData.description && (
            <p className="description">{journeyData.description}</p>
          )}

          {journeyData.pdfUrl && (
            <div className="pdf-container">
              <pdf-viewer
                ref={pdfViewerRef}
                src={journeyData.pdfUrl}
              />
            </div>
          )}

          <div className="journey-data">
            <pre>{JSON.stringify(journeyData, null, 2)}</pre>
          </div>
        </div>
      )}
    </div>
  )
}

export default App

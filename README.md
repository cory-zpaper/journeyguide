# JourneyGuide

A React application that dynamically fetches and displays journey data from an API based on URL paths, with integrated PDF viewing capabilities.

## Features

- **Dynamic Routing**: Handles all URL paths and uses the last path segment to fetch journey data
- **API Integration**: Consumes the Sourdough API at `https://sourdough.ui.dev.sprkzdoc.com/`
- **PDF Viewer**: Embeds the custom `<pdf-viewer>` component from SparkzDoc
- **React + Vite**: Fast development experience with Hot Module Replacement (HMR)

## How It Works

The application extracts the journey ID from the URL path and fetches the corresponding journey data:

- `/journey1` → fetches from `https://sourdough.ui.dev.sprkzdoc.com/journey1`
- `/path/to/journey2` → fetches from `https://sourdough.ui.dev.sprkzdoc.com/journey2`
- All routes are handled the same way, making the app flexible for any journey ID

## Getting Started

### Installation

```bash
npm install
```

### Development

```bash
npm run dev
```

Visit `http://localhost:5173` to view the app.

### Build

```bash
npm run build
```

### Preview Production Build

```bash
npm run preview
```

## Project Structure

- `src/App.jsx` - Main application component with routing and API integration
- `src/main.jsx` - Entry point with React Router setup
- `index.html` - Includes the pdf-viewer library script
- `vite.config.js` - Vite configuration

## Technologies

- React 18
- React Router DOM
- Vite
- SparkzDoc PDF Viewer

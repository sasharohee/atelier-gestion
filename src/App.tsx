import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline, Box, Alert, Button, Typography } from '@mui/material';
import { Toaster } from 'react-hot-toast';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { fr } from 'date-fns/locale';

import { theme } from './theme';
import { useAuthenticatedData } from './hooks/useAuthenticatedData';
import { useAppStore } from './store';
import { WorkshopSettingsProvider } from './contexts/WorkshopSettingsContext';
import './styles/print.css';

// Composants de layout
import Layout from './components/Layout/Layout';
import Sidebar from './components/Layout/Sidebar';

// Composants de guide et d'authentification
import { OnboardingGuide } from './components/OnboardingGuide';
import { OnboardingNotification } from './components/OnboardingNotification';
import AuthGuard from './components/AuthGuard';

// Pages
import Landing from './pages/Landing/Landing';
import Auth from './pages/Auth/Auth';
import Dashboard from './pages/Dashboard/Dashboard';
import Kanban from './pages/Kanban/Kanban';
import Calendar from './pages/Calendar/Calendar';
import Messaging from './pages/Messaging/Messaging';
import Catalog from './pages/Catalog/Catalog';
import Sales from './pages/Sales/Sales';
import Statistics from './pages/Statistics/Statistics';
import Administration from './pages/Administration/Administration';
import Settings from './pages/Settings/Settings';

// Services
import { demoDataService } from './services/demoDataService';

// Composant de fallback en cas d'erreur
const ErrorFallback: React.FC<{ error: Error; resetError: () => void }> = ({ error, resetError }) => (
  <Box sx={{ p: 4, textAlign: 'center' }}>
    <Alert severity="error" sx={{ mb: 2 }}>
      <strong>Erreur de chargement :</strong> {error.message}
    </Alert>
    <Button variant="contained" onClick={resetError}>
      Réessayer
    </Button>
  </Box>
);

// Composant de chargement
const LoadingComponent: React.FC = () => (
  <Box sx={{ 
    display: 'flex', 
    justifyContent: 'center', 
    alignItems: 'center', 
    height: '100vh',
    flexDirection: 'column'
  }}>
    <Typography variant="h6" sx={{ mb: 2 }}>
      Chargement de l'application...
    </Typography>
    <Typography variant="body2" color="text.secondary">
      Initialisation en cours
    </Typography>
  </Box>
);

function App() {
  const [error, setError] = useState<Error | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [showOnboarding, setShowOnboarding] = useState(false);
  
  const { setCurrentUser, setAuthenticated } = useAppStore();
  const { isDataLoaded, isLoading: isDataLoading, error: dataError } = useAuthenticatedData();

  // Initialisation de l'application avec gestion d'erreur
  useEffect(() => {
    const initializeApp = async () => {
      try {
        // S'assurer que les données de démonstration sont chargées
        await demoDataService.ensureDemoData();
        
        setIsLoading(false);
        
        // Vérifier si le guide d'intégration doit être affiché
        if (!demoDataService.isOnboardingCompleted()) {
          setShowOnboarding(true);
        }
      } catch (err) {
        console.error('Erreur lors de l\'initialisation:', err);
        setError(err instanceof Error ? err : new Error('Erreur inconnue'));
        setIsLoading(false);
      }
    };

    initializeApp();
  }, []);

  // Gérer les erreurs de chargement des données
  useEffect(() => {
    if (dataError) {
      setError(dataError);
    }
  }, [dataError]);

  const resetError = () => {
    setError(null);
    setIsLoading(true);
    window.location.reload();
  };

  if (error) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <ErrorFallback error={error} resetError={resetError} />
      </ThemeProvider>
    );
  }

  if (isLoading) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <LoadingComponent />
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={fr}>
        <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          <WorkshopSettingsProvider>
            <Routes>
              <Route path="/" element={<Landing />} />
              <Route path="/auth" element={<Auth />} />
              <Route path="/app/*" element={
                <AuthGuard>
                  <Box sx={{ display: 'flex', minHeight: '100vh' }}>
                    <Sidebar />
                    <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
                      <Layout>
                        <Routes>
                          <Route path="/" element={<Navigate to="/dashboard" replace />} />
                          <Route path="/dashboard" element={<Dashboard />} />
                          <Route path="/kanban" element={<Kanban />} />
                          <Route path="/calendar" element={<Calendar />} />
                          <Route path="/messaging" element={<Messaging />} />
                          <Route path="/catalog/*" element={<Catalog />} />
                          <Route path="/sales" element={<Sales />} />
                          <Route path="/statistics" element={<Statistics />} />
                          <Route path="/administration" element={<Administration />} />
                          <Route path="/settings" element={<Settings />} />
                        </Routes>
                        
                        {/* Guide d'intégration */}
                        {showOnboarding && (
                          <OnboardingGuide 
                            onComplete={() => {
                              setShowOnboarding(false);
                              demoDataService.markOnboardingCompleted();
                            }}
                          />
                        )}
                        
                        {/* Notification d'intégration */}
                        <OnboardingNotification onShowGuide={() => setShowOnboarding(true)} />
                      </Layout>
                    </Box>
                  </Box>
                </AuthGuard>
              } />
            </Routes>
            
            {/* Toast notifications */}
            <Toaster position="top-right" />
          </WorkshopSettingsProvider>
        </Router>
      </LocalizationProvider>
    </ThemeProvider>
  );
}

export default App;

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
import { AuthErrorHandler } from './components/AuthErrorHandler';
import './styles/print.css';

// Composants de layout
import Layout from './components/Layout/Layout';
import Sidebar from './components/Layout/Sidebar';

// Composants de guide et d'authentification
// import { OnboardingGuide } from './components/OnboardingGuide'; // MASQUÉ
// import { OnboardingNotification } from './components/OnboardingNotification'; // MASQUÉ
import AuthGuard from './components/AuthGuard';
import AdminGuard from './components/AdminGuard';

// Pages
import Landing from './pages/Landing/Landing';
import Auth from './pages/Auth/Auth';
import Dashboard from './pages/Dashboard/Dashboard';
import Kanban from './pages/Kanban/Kanban';
import Archive from './pages/Archive/Archive';
import Calendar from './pages/Calendar/Calendar';

import Catalog from './pages/Catalog/Catalog';
import Transaction from './pages/Transaction/Transaction';
import Sales from './pages/Sales/Sales';
import Statistics from './pages/Statistics/Statistics';
import Administration from './pages/Administration/Administration';
import SubscriptionManagement from './pages/Administration/SubscriptionManagement';
import UserAccessManagement from './pages/Administration/UserAccessManagement';
import AdminAccess from './pages/AdminAccess/AdminAccess';
import Settings from './pages/Settings/Settings';
import PrivacyPolicy from './pages/Legal/PrivacyPolicy';
import TermsOfService from './pages/Legal/TermsOfService';
import CGV from './pages/Legal/CGV';
import RGPD from './pages/Legal/RGPD';
import Support from './pages/Support/Support';
import FAQ from './pages/Support/FAQ';

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
        
        // Vérifier si le guide d'intégration doit être affiché - MASQUÉ
        // if (!demoDataService.isOnboardingCompleted()) {
        //   setShowOnboarding(true);
        // }
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
      // Ne pas afficher les erreurs "Utilisateur non connecté" comme erreurs critiques
      if (dataError.message.includes('Utilisateur non connecté')) {
        console.log('ℹ️ Utilisateur non connecté - données non chargées');
        return;
      }
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
            <AuthErrorHandler>
              <Routes>
                <Route path="/" element={<Landing />} />
                <Route path="/auth" element={<Auth />} />
                <Route path="/admin" element={<AdminAccess />} />
                <Route path="/privacy-policy" element={<PrivacyPolicy />} />
                <Route path="/terms-of-service" element={<TermsOfService />} />
                <Route path="/cgv" element={<CGV />} />
                <Route path="/rgpd" element={<RGPD />} />
                <Route path="/support" element={<Support />} />
                <Route path="/faq" element={<FAQ />} />
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
                            <Route path="/archive" element={<Archive />} />
                            <Route path="/calendar" element={<Calendar />} />

                            <Route path="/catalog/*" element={<Catalog />} />
                            <Route path="/transaction/*" element={<Transaction />} />
                            <Route path="/sales" element={<Sales />} />
                            <Route path="/statistics" element={<Statistics />} />
                            <Route path="/administration" element={<Administration />} />
                            <Route path="/administration/subscriptions" element={<SubscriptionManagement />} />
                            <Route path="/administration/user-access" element={<UserAccessManagement />} />
                            <Route path="/settings" element={<Settings />} />
                          </Routes>
                          
                          {/* Guide d'intégration - MASQUÉ */}
                          {/* {showOnboarding && (
                            <OnboardingGuide 
                              onComplete={() => setShowOnboarding(false)}
                            />
                          )} */}
                        </Layout>
                      </Box>
                    </Box>
                  </AuthGuard>
                } />
              </Routes>
            </AuthErrorHandler>
          </WorkshopSettingsProvider>
        </Router>
      </LocalizationProvider>
      <Toaster position="top-right" />
    </ThemeProvider>
  );
}

export default App;

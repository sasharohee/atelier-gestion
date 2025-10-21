import React, { useEffect, useState, Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline, Box, Alert, Button, Typography, CircularProgress } from '@mui/material';
import { Toaster } from 'react-hot-toast';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { fr } from 'date-fns/locale';

import { theme } from './theme';
import { useAuthenticatedData } from './hooks/useAuthenticatedData';
import { useAppStore } from './store';
import { WorkshopSettingsProvider } from './contexts/WorkshopSettingsContext';
import { AuthErrorHandler } from './components/AuthErrorHandler';
import { repairService } from './services/supabaseService';
import './styles/print.css';

// Composants de layout
import Layout from './components/Layout/Layout';

// Composants de guide et d'authentification
// import { OnboardingGuide } from './components/OnboardingGuide'; // MASQUÉ
// import { OnboardingNotification } from './components/OnboardingNotification'; // MASQUÉ
import AuthGuard from './components/AuthGuard';
import AdminGuard from './components/AdminGuard';
import AdminPasswordGuard from './components/AdminPasswordGuard';
import AccountingPasswordGuard from './components/AccountingPasswordGuard';
import GuestGuard from './components/GuestGuard';
import { AuthProvider } from './contexts/AuthContext';

// Pages - Lazy loading pour les pages lourdes
import Landing from './pages/Landing/Landing';
import Auth from './pages/Auth/Auth';

// Lazy loading des pages lourdes
const Dashboard = lazy(() => import('./pages/Dashboard/Dashboard'));
const Kanban = lazy(() => import('./pages/Kanban/Kanban'));
const SAV = lazy(() => import('./pages/SAV/SAV'));
const Calendar = lazy(() => import('./pages/Calendar/Calendar'));
const Catalog = lazy(() => import('./pages/Catalog/Catalog'));
const Transaction = lazy(() => import('./pages/Transaction/Transaction'));
const Statistics = lazy(() => import('./pages/Statistics/Statistics'));
const Archive = lazy(() => import('./pages/Archive/Archive'));
const Loyalty = lazy(() => import('./pages/Loyalty/Loyalty'));
const Expenses = lazy(() => import('./pages/Expenses/Expenses'));
const QuoteRequests = lazy(() => import('./pages/QuoteRequests/QuoteRequestsManagement'));
const Administration = lazy(() => import('./pages/Administration/Administration'));
const Settings = lazy(() => import('./pages/Settings/Settings'));
import Buyback from './pages/Buyback/BuybackProgressive';
const Accounting = lazy(() => import('./pages/Accounting/Accounting'));
const SubscriptionBlocked = lazy(() => import('./pages/Auth/SubscriptionBlocked'));

// Pages légères - import direct
import Sales from './pages/Sales/Sales';
import UserAccessManagement from './pages/Administration/UserAccessManagement';
import AdminAccess from './pages/AdminAccess/AdminAccess';
import PrivacyPolicy from './pages/Legal/PrivacyPolicy';
import TermsOfService from './pages/Legal/TermsOfService';
import CGV from './pages/Legal/CGV';
import RGPD from './pages/Legal/RGPD';
import Support from './pages/Support/Support';
import FAQ from './pages/Support/FAQ';
import RepairTracking from './pages/RepairTracking/RepairTracking';
import RepairHistory from './pages/RepairTracking/RepairHistory';
import QuoteRequestPageFixed from './pages/QuoteRequest/QuoteRequestPageFixed';

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

// Composant de chargement pour l'application
const LoadingComponent: React.FC = () => (
  <Box sx={{ 
    display: 'flex', 
    justifyContent: 'center', 
    alignItems: 'center', 
    height: '100vh',
    flexDirection: 'column'
  }}>
    <CircularProgress size={40} sx={{ mb: 2 }} />
    <Typography variant="h6" sx={{ mb: 1 }}>
      Chargement de l'application...
    </Typography>
    <Typography variant="body2" color="text.secondary">
      Initialisation en cours
    </Typography>
  </Box>
);

// Composant de chargement pour les pages lazy-loaded
const PageLoadingComponent: React.FC = () => (
  <Box sx={{ 
    display: 'flex', 
    justifyContent: 'center', 
    alignItems: 'center', 
    height: '50vh',
    flexDirection: 'column'
  }}>
    <CircularProgress size={30} sx={{ mb: 1 }} />
    <Typography variant="body2" color="text.secondary">
      Chargement de la page...
    </Typography>
  </Box>
);

function App() {
  const [error, setError] = useState<Error | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [showOnboarding, setShowOnboarding] = useState(false);
  
  const { setCurrentUser, setAuthenticated } = useAppStore();
  const { isDataLoaded, isLoading: isDataLoading, error: dataError } = useAuthenticatedData();

  // Initialisation rapide de l'application
  useEffect(() => {
    const initializeApp = async () => {
      try {
        // Initialisation immédiate - pas d'attente
        setIsLoading(false);
        
        // Exposer les objets globaux pour le débogage (en arrière-plan)
        if (typeof window !== 'undefined') {
          window.useAppStore = useAppStore;
          window.repairService = repairService;
          console.log('🔧 Objets de débogage exposés globalement');
        }
        
        // Charger les données de démonstration en arrière-plan (non bloquant)
        demoDataService.ensureDemoData().then(() => {
          console.log('✅ Données de démonstration chargées en arrière-plan');
        }).catch(err => {
          console.warn('⚠️ Erreur lors du chargement des données de démonstration:', err);
        });
        
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
          <AuthProvider>
            <WorkshopSettingsProvider>
              <AuthErrorHandler>
              <Routes>
                <Route path="/" element={<Landing />} />
                <Route path="/auth" element={
                  <GuestGuard>
                    <Auth />
                  </GuestGuard>
                } />
                <Route path="/admin" element={
                  <AdminPasswordGuard>
                    <AdminAccess />
                  </AdminPasswordGuard>
                } />
                <Route path="/privacy-policy" element={<PrivacyPolicy />} />
                <Route path="/terms-of-service" element={<TermsOfService />} />
                <Route path="/cgv" element={<CGV />} />
                <Route path="/rgpd" element={<RGPD />} />
                <Route path="/support" element={<Support />} />
                <Route path="/faq" element={<FAQ />} />
                <Route path="/repair-tracking" element={<RepairTracking />} />
                <Route path="/repair-history" element={<RepairHistory />} />
                <Route path="/quote/:customUrl" element={<QuoteRequestPageFixed />} />
                <Route path="/app/*" element={
                  <AuthGuard>
                    <Layout>
                      <Suspense fallback={<PageLoadingComponent />}>
                        <Routes>
                          <Route path="/" element={<Navigate to="/dashboard" replace />} />
                          <Route path="/dashboard" element={<Dashboard />} />
                          <Route path="/kanban" element={<Kanban />} />
                          <Route path="/sav" element={<SAV />} />
                          <Route path="/archive" element={<Archive />} />
                          <Route path="/calendar" element={<Calendar />} />

                          <Route path="/catalog/*" element={<Catalog />} />
                          <Route path="/transaction/*" element={<Transaction />} />
                          <Route path="/sales" element={<Sales />} />
                          <Route path="/statistics" element={<Statistics />} />
                          <Route path="/administration" element={<Administration />} />
                          <Route path="/administration/subscriptions" element={<UserAccessManagement />} />
                          <Route path="/administration/user-access" element={<UserAccessManagement />} />
                          <Route path="/loyalty" element={<Loyalty />} />
                          <Route path="/expenses" element={<Expenses />} />
                          <Route path="/quote-requests" element={<QuoteRequests />} />
                          <Route path="/buyback" element={<Buyback />} />
                          <Route path="/accounting" element={
                            <AccountingPasswordGuard>
                              <Accounting />
                            </AccountingPasswordGuard>
                          } />
                          <Route path="/settings" element={<Settings />} />
                        </Routes>
                      </Suspense>
                      
                      {/* Guide d'intégration - MASQUÉ */}
                      {/* {showOnboarding && (
                        <OnboardingGuide 
                          onComplete={() => setShowOnboarding(false)}
                        />
                      )} */}
                    </Layout>
                  </AuthGuard>
                } />
              </Routes>
              </AuthErrorHandler>
            </WorkshopSettingsProvider>
          </AuthProvider>
        </Router>
      </LocalizationProvider>
      <Toaster position="top-right" />
    </ThemeProvider>
  );
}

export default App;

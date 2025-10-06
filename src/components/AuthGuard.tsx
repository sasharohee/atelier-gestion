import React, { Suspense, lazy, memo } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { Box, CircularProgress, Typography } from '@mui/material';
import { useUltraFastAccess } from '../hooks/useUltraFastAccess';

// Lazy loading de SubscriptionBlocked
const SubscriptionBlocked = lazy(() => import('../pages/Auth/SubscriptionBlocked'));

interface AuthGuardProps {
  children: React.ReactNode;
}

const AuthGuard: React.FC<AuthGuardProps> = memo(({ children }) => {
  const { 
    user, 
    isAuthenticated, 
    isAccessActive, 
    loading, 
    authLoading, 
    subscriptionLoading 
  } = useUltraFastAccess();
  const location = useLocation();

  // Éviter les re-rendus inutiles en mémorisant les valeurs
  const isLoading = loading || authLoading || subscriptionLoading;

  // Si l'authentification ou le statut d'abonnement est en cours de chargement
  if (isLoading) {
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          height: '100vh',
          gap: 2
        }}
      >
        <CircularProgress size={50} sx={{ mb: 2 }} />
        <Typography variant="h6" color="text.secondary" sx={{ mb: 1 }}>
          {authLoading ? 'Authentification...' : subscriptionLoading ? 'Vérification des permissions...' : 'Préparation...'}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {authLoading ? 'Vérification de votre identité' : 
           subscriptionLoading ? 'Chargement de vos droits d\'accès' : 
           'Finalisation de l\'interface'}
        </Typography>
      </Box>
    );
  }

  if (!isAuthenticated) {
    // Rediriger vers la page d'authentification en conservant l'URL de destination
    return <Navigate to="/auth" state={{ from: location }} replace />;
  }

  // Si l'utilisateur est connecté mais que l'abonnement n'est pas actif
  if (user && !isAccessActive) {
    return (
      <Suspense fallback={
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
      }>
        <SubscriptionBlocked />
      </Suspense>
    );
  }

  return <>{children}</>;
});

AuthGuard.displayName = 'AuthGuard';

export default AuthGuard;

import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { Box, CircularProgress, Typography } from '@mui/material';
import { useAuth } from '../hooks/useAuth';
import { useSubscription } from '../hooks/useSubscription';
import SubscriptionBlocked from '../pages/Auth/SubscriptionBlocked';

interface AuthGuardProps {
  children: React.ReactNode;
}

const AuthGuard: React.FC<AuthGuardProps> = ({ children }) => {
  const { isAuthenticated, loading: authLoading, user } = useAuth();
  const { subscriptionStatus, loading: subscriptionLoading } = useSubscription();
  const location = useLocation();

  // Vérifier si l'abonnement est actif
  const isSubscriptionActive = subscriptionStatus?.is_active || false;

  // Si l'authentification ou le statut d'abonnement est en cours de chargement
  if (authLoading || (isAuthenticated && subscriptionLoading)) {
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
        <CircularProgress size={60} />
        <Typography variant="h6" color="text.secondary">
          {authLoading ? 'Vérification de l\'authentification...' : 'Vérification de votre accès...'}
        </Typography>
      </Box>
    );
  }

  if (!isAuthenticated) {
    // Rediriger vers la page d'authentification en conservant l'URL de destination
    return <Navigate to="/auth" state={{ from: location }} replace />;
  }

  // Si l'utilisateur est connecté mais que l'abonnement n'est pas actif
  if (user && !isSubscriptionActive) {
    return <SubscriptionBlocked />;
  }

  return <>{children}</>;
};

export default AuthGuard;

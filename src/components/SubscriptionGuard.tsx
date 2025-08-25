import React from 'react';
import { useAuth } from '../hooks/useAuth';
import { useSubscription } from '../hooks/useSubscription';
import SubscriptionBlocked from '../pages/Auth/SubscriptionBlocked';

interface SubscriptionGuardProps {
  children: React.ReactNode;
}

const SubscriptionGuard: React.FC<SubscriptionGuardProps> = ({ children }) => {
  const { user, loading: authLoading } = useAuth();
  const { subscriptionStatus, loading: subscriptionLoading } = useSubscription();

  // Vérifier si l'abonnement est actif
  const isSubscriptionActive = subscriptionStatus?.is_active || false;

  // Si l'authentification ou le statut d'abonnement est en cours de chargement
  if (authLoading || subscriptionLoading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        flexDirection: 'column'
      }}>
        <div>Vérification de votre accès...</div>
      </div>
    );
  }

  // Si l'utilisateur n'est pas connecté, laisser AuthGuard gérer
  if (!user) {
    return <>{children}</>;
  }

  // Si l'abonnement n'est pas actif, afficher la page de blocage
  if (!isSubscriptionActive) {
    return <SubscriptionBlocked />;
  }

  // Si l'abonnement est actif, afficher le contenu normal
  return <>{children}</>;
};

export default SubscriptionGuard;

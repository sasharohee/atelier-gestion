import React, { memo, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

interface GuestGuardProps {
  children: React.ReactNode;
}

// Variable GLOBALE pour éviter les re-renders en boucle
let globalHasRedirected = false;

/**
 * GuestGuard - Protège les routes accessibles uniquement aux utilisateurs NON connectés
 * Redirige vers /app/dashboard si l'utilisateur est déjà authentifié
 */
const GuestGuard: React.FC<GuestGuardProps> = memo(({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const redirectToRef = useRef(location.state?.from?.pathname || '/app/dashboard');
  
  useEffect(() => {
    // Attendre la fin du loading
    if (loading) return;
    
    // Si l'utilisateur n'est pas connecté, réinitialiser le flag global
    if (!isAuthenticated) {
      globalHasRedirected = false;
      return;
    }
    
    // Si l'utilisateur est connecté ET qu'on n'a pas encore redirigé
    if (isAuthenticated && !globalHasRedirected) {
      globalHasRedirected = true;
      console.log('🔄 Utilisateur déjà connecté, redirection depuis GuestGuard vers:', redirectToRef.current);
      
      // Redirection forcée avec window.location pour éviter les problèmes de React Router
      setTimeout(() => {
        console.log('🚀 Redirection forcée vers:', redirectToRef.current);
        window.location.href = redirectToRef.current;
      }, 100);
    }
  }, [isAuthenticated, loading, navigate]);

  // Pendant le loading, ne rien afficher
  if (loading) {
    return null;
  }

  // Si on a déjà redirigé, ne rien afficher pendant la redirection
  if (globalHasRedirected) {
    return null;
  }

  // Si l'utilisateur n'est pas connecté, afficher la page (Auth)
  return <>{children}</>;
});

GuestGuard.displayName = 'GuestGuard';

export default GuestGuard;


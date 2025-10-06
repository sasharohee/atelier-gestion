import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { userService } from '../services/supabaseService';
import { User } from '@supabase/supabase-js';

export const useAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState<string | null>(null);
  const isMounted = useRef(true);
  const authStateRef = useRef<'stable' | 'changing'>('stable');
  const hasCheckedSession = useRef(false);
  const sessionCheckTimeout = useRef<NodeJS.Timeout | null>(null);

  const clearAuthState = () => {
    localStorage.removeItem('pendingUserData');
    localStorage.removeItem('pendingSignupEmail');
  };

  useEffect(() => {
    isMounted.current = true;
    hasCheckedSession.current = false;
    
    // Nettoyer le timeout précédent s'il existe
    if (sessionCheckTimeout.current) {
      clearTimeout(sessionCheckTimeout.current);
    }
    
    const getCurrentUser = async () => {
      // Éviter les vérifications multiples
      if (hasCheckedSession.current) {
        return;
      }
      
      hasCheckedSession.current = true;
      
      try {
        const { data: { user }, error } = await supabase.auth.getUser();
        
        if (!isMounted.current) return;
        
        if (error) {
          // Gérer spécifiquement l'erreur de session manquante sans la logger
          if (error.message.includes('Auth session missing')) {
            setUser(null);
            setAuthError(null);
            setLoading(false);
            return;
          }
          
          console.error('❌ Erreur lors de la récupération de l\'utilisateur:', error);
          
          // Gérer les erreurs de token spécifiques
          if (error.message.includes('Invalid Refresh Token') || 
              error.message.includes('Refresh Token Not Found')) {
            console.log('🔄 Token invalide, nettoyage de l\'état...');
            clearAuthState();
            setUser(null);
            setAuthError('Session expirée. Veuillez vous reconnecter.');
          } else {
            setAuthError(error.message);
          }
        } else {
          setUser(user);
          setAuthError(null);
          
          // Traiter les données utilisateur en attente si l'utilisateur est connecté
          if (user && localStorage.getItem('pendingUserData')) {
            await userService.processPendingUserData();
          }
        }
      } catch (error) {
        if (isMounted.current) {
          console.error('💥 Exception lors de la récupération de l\'utilisateur:', error);
          setUser(null);
          setAuthError('Erreur inattendue lors de l\'authentification');
        }
      } finally {
        if (isMounted.current) {
          setLoading(false);
        }
      }
    };

    // Délai pour éviter les vérifications trop fréquentes
    sessionCheckTimeout.current = setTimeout(() => {
      getCurrentUser();
    }, 100);

    // Écouter les changements d'authentification avec stabilisation
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (!isMounted.current) return;
        
        // Éviter les changements d'état trop fréquents
        if (authStateRef.current === 'changing') {
          return;
        }
        
        // Ignorer l'événement INITIAL_SESSION pour éviter la boucle infinie
        if (event === 'INITIAL_SESSION') {
          return;
        }
        
        authStateRef.current = 'changing';
        
        try {
          if (event === 'SIGNED_IN' && session?.user) {
            console.log('✅ Utilisateur connecté:', session.user.email);
            setUser(session.user);
            setAuthError(null);
            
            // Traiter les données utilisateur en attente lors de la connexion
            if (localStorage.getItem('pendingUserData')) {
              await userService.processPendingUserData();
            }
          } else if (event === 'TOKEN_REFRESHED') {
            console.log('✅ Token rafraîchi avec succès');
            setAuthError(null);
          } else if (event === 'SIGNED_OUT') {
            console.log('👋 Utilisateur déconnecté');
            setUser(null);
            setAuthError(null);
            // Nettoyer les données en attente
            clearAuthState();
          }
        } finally {
          // Remettre l'état à stable après un délai
          setTimeout(() => {
            authStateRef.current = 'stable';
          }, 1000);
        }
        
        setLoading(false);
      }
    );

    return () => {
      isMounted.current = false;
      if (sessionCheckTimeout.current) {
        clearTimeout(sessionCheckTimeout.current);
      }
      subscription.unsubscribe();
    };
  }, []); // Dépendances vides pour éviter les re-exécutions

  // Fonction pour forcer la réinitialisation de l'authentification
  const resetAuth = async () => {
    setLoading(true);
    try {
      await supabase.auth.signOut();
      clearAuthState();
      setUser(null);
      setAuthError(null);
      window.location.reload();
    } catch (error) {
      console.error('❌ Erreur lors de la réinitialisation:', error);
      setAuthError('Erreur lors de la réinitialisation');
    } finally {
      setLoading(false);
    }
  };

  return {
    user,
    loading,
    authError,
    isAuthenticated: !!user,
    resetAuth
  };
};

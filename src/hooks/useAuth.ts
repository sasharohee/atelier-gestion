import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { userService } from '../services/supabaseService';
import { User } from '@supabase/supabase-js';

// Variable GLOBALE pour tracker l'état d'authentification (partagée entre toutes les instances)
let globalPreviousAuthState = false;
let globalUserId: string | null = null;

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
    // Réinitialiser les variables globales
    globalPreviousAuthState = false;
    globalUserId = null;
  };

  // Fonction pour mettre à jour l'utilisateur seulement si l'état change vraiment
  const updateUser = (newUser: User | null) => {
    const newAuthState = !!newUser;
    const newUserId = newUser?.id || null;
    
    // Ne mettre à jour que si l'état d'authentification CHANGE ou si l'utilisateur change
    if (newAuthState !== globalPreviousAuthState) {
      console.log(`🔄 État d'authentification changé: ${globalPreviousAuthState ? 'connecté' : 'déconnecté'} → ${newAuthState ? 'connecté' : 'déconnecté'}`);
      globalPreviousAuthState = newAuthState;
      globalUserId = newUserId;
      setUser(newUser);
    } else if (newUserId && newUserId !== globalUserId) {
      // Utilisateur différent mais toujours authentifié
      console.log(`🔄 Utilisateur changé: ${globalUserId} → ${newUserId}`);
      globalUserId = newUserId;
      setUser(newUser);
    }
    // Sinon, ne rien faire (éviter les mises à jour inutiles)
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
            updateUser(null);
            setAuthError(null);
            setLoading(false);
            return;
          }
          
          // Gérer les erreurs CORS/réseau sans les afficher à l'utilisateur
          if (error.message.includes('Failed to fetch') || 
              error.message.includes('CORS') ||
              error.message.includes('502')) {
            console.warn('⚠️ Erreur réseau temporaire lors de la récupération de l\'utilisateur');
            // Ne pas afficher d'erreur à l'utilisateur, simplement considérer comme non connecté
            updateUser(null);
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
            updateUser(null);
            setAuthError('Session expirée. Veuillez vous reconnecter.');
          } else {
            setAuthError(error.message);
          }
        } else {
          updateUser(user);
          setAuthError(null);
          
          // Traiter les données utilisateur en attente si l'utilisateur est connecté
          if (user && localStorage.getItem('pendingUserData')) {
            await userService.processPendingUserData();
          }
        }
      } catch (error: any) {
        if (isMounted.current) {
          // Gérer les erreurs réseau sans les afficher à l'utilisateur
          if (error?.message?.includes('Failed to fetch') || 
              error?.message?.includes('CORS') ||
              error?.message?.includes('502')) {
            console.warn('⚠️ Erreur réseau temporaire lors de la récupération de l\'utilisateur');
            updateUser(null);
            setAuthError(null);
          } else {
            console.error('💥 Exception lors de la récupération de l\'utilisateur:', error);
            updateUser(null);
            setAuthError('Erreur inattendue lors de l\'authentification');
          }
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
            updateUser(session.user);
            setAuthError(null);
            
            // Traiter les données utilisateur en attente lors de la connexion
            if (localStorage.getItem('pendingUserData')) {
              await userService.processPendingUserData();
            }
          } else if (event === 'TOKEN_REFRESHED') {
            // Ne rien faire - pas besoin de mettre à jour l'utilisateur
            console.log('✅ Token rafraîchi avec succès (pas de mise à jour de l\'état)');
            setAuthError(null);
          } else if (event === 'SIGNED_OUT') {
            console.log('👋 Utilisateur déconnecté');
            updateUser(null);
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
      updateUser(null);
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

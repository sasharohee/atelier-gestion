import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { userService } from '../services/supabaseService';
import { User } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  loading: boolean;
  authError: string | null;
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  signOut: () => Promise<void>;
  resetAuth: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Variable GLOBALE pour tracker l'état d'authentification (partagée entre toutes les instances)
let globalPreviousAuthState = false;
let globalUserId: string | null = null;
let globalUser: User | null = null;
let globalLoading = true;
let globalAuthError: string | null = null;

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(globalUser);
  const [loading, setLoading] = useState<boolean>(globalLoading);
  const [authError, setAuthError] = useState<string | null>(globalAuthError);
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
    globalUser = null;
    globalAuthError = null;
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
      globalUser = newUser;
      setUser(newUser);
    } else if (newUserId && newUserId !== globalUserId) {
      // Utilisateur différent mais toujours authentifié
      console.log(`🔄 Utilisateur changé: ${globalUserId} → ${newUserId}`);
      globalUserId = newUserId;
      globalUser = newUser;
      setUser(newUser);
    }
    // Sinon, ne rien faire (éviter les mises à jour inutiles)
  };

  useEffect(() => {
    isMounted.current = true;
    hasCheckedSession.current = false;
    
    // Vérifier la session existante au démarrage
    const getCurrentUser = async () => {
      try {
        const { data: { user: currentUser }, error } = await supabase.auth.getUser();
        
        if (error) {
          console.error('❌ Erreur lors de la récupération de l\'utilisateur:', error);
          if (isMounted.current) {
            setAuthError(error.message);
          }
          return;
        }

        if (currentUser) {
          console.log('✅ Utilisateur connecté:', currentUser.email);
          updateUser(currentUser);
        } else {
          console.log('❌ Aucun utilisateur connecté');
          updateUser(null);
        }
      } catch (error) {
        console.error('❌ Erreur réseau lors de la récupération de l\'utilisateur:', error);
        if (isMounted.current) {
          setAuthError('Erreur de connexion réseau');
        }
      } finally {
        if (isMounted.current) {
          setLoading(false);
          globalLoading = false;
        }
      }
    };

    // Écouter les changements d'authentification
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log('🔔 Événement d\'authentification:', event);
      
      if (!isMounted.current) return;

      try {
        if (event === 'SIGNED_IN' && session?.user) {
          console.log('✅ Utilisateur connecté:', session.user.email);
          updateUser(session.user);
          
          // Traiter les données en attente
          await userService.processPendingUserData();
        } else if (event === 'SIGNED_OUT') {
          console.log('❌ Utilisateur déconnecté');
          updateUser(null);
          clearAuthState();
        } else if (event === 'TOKEN_REFRESHED' && session?.user) {
          console.log('✅ Token rafraîchi avec succès (pas de mise à jour de l\'état)');
          // Ne pas mettre à jour l'état pour éviter les re-renders inutiles
        }
      } catch (error) {
        console.error('❌ Erreur lors du traitement de l\'événement d\'authentification:', error);
        if (isMounted.current) {
          setAuthError('Erreur lors de l\'authentification');
        }
      }
    });

    // Vérifier la session actuelle
    getCurrentUser();

    return () => {
      isMounted.current = false;
      subscription.unsubscribe();
      if (sessionCheckTimeout.current) {
        clearTimeout(sessionCheckTimeout.current);
      }
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    try {
      setAuthError(null);
      const result = await userService.signIn(email, password);
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Erreur de connexion';
      setAuthError(errorMessage);
      return { success: false, error: errorMessage };
    }
  };

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
      updateUser(null);
      clearAuthState();
    } catch (error) {
      console.error('❌ Erreur lors de la déconnexion:', error);
    }
  };

  const resetAuth = () => {
    updateUser(null);
    setAuthError(null);
    clearAuthState();
  };

  const isAuthenticated = !!user;

  const value: AuthContextType = {
    user,
    isAuthenticated,
    loading,
    authError,
    signIn,
    signOut,
    resetAuth
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

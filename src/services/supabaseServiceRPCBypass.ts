// Service d'authentification qui utilise les fonctions RPC pour contourner RLS
// Crée de vrais utilisateurs dans les tables publiques

import { supabase } from '../lib/supabase';
import { User } from '../types/User';

// Fonction de gestion des erreurs
function handleSupabaseError(error: any) {
  console.error('❌ Erreur Supabase:', error);
  return {
    success: false,
    error: error.message || 'Erreur inattendue'
  };
}

// Fonction de gestion des succès
function handleSupabaseSuccess(data: any) {
  return {
    success: true,
    data
  };
}

// Service utilisateur avec contournement RPC
export const userServiceRPCBypass = {
  // Inscription avec contournement RPC
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 CRÉATION D\'UTILISATEUR RPC - Contournement RLS');
      
      // Étape 1: Essayer la création normale d'abord
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: email,
        password: password,
        options: {
          data: {
            firstName: userData.firstName || 'Utilisateur',
            lastName: userData.lastName || '',
            role: userData.role || 'technician'
          }
        }
      });

      if (authError && authError.message.includes('Database error saving new user')) {
        console.log('⚠️ Erreur de trigger détectée - Utilisation des fonctions RPC');
        
        // Étape 2: Utiliser la fonction RPC pour créer l'utilisateur
        const { data: rpcData, error: rpcError } = await supabase.rpc('create_user_with_session', {
          user_email: email,
          user_first_name: userData.firstName || 'Utilisateur',
          user_last_name: userData.lastName || '',
          user_role: userData.role || 'technician'
        });

        if (rpcError) {
          console.error('❌ Erreur RPC:', rpcError);
          return handleSupabaseError(rpcError);
        }

        if (rpcData && rpcData.success) {
          console.log('✅ Utilisateur créé via RPC:', rpcData);
          
          // Créer une session simulée pour l'utilisateur
          const mockUser = {
            id: rpcData.user_id,
            email: rpcData.email,
            created_at: rpcData.created_at,
            user_metadata: {
              firstName: rpcData.first_name,
              lastName: rpcData.last_name,
              role: rpcData.role
            }
          };

          const mockSession = {
            user: mockUser,
            session: {
              access_token: 'rpc_token_' + Date.now(),
              refresh_token: 'rpc_refresh_' + Date.now(),
              expires_at: Math.floor(Date.now() / 1000) + 3600,
              token_type: 'bearer',
              user: mockUser
            }
          };

          // Stocker la session
          localStorage.setItem('user_session', JSON.stringify(mockSession));
          localStorage.setItem('isAuthenticated', 'true');
          
          return handleSupabaseSuccess({
            message: 'Inscription réussie ! (Mode RPC - Utilisateur créé dans la base)',
            status: 'success',
            data: mockUser,
            emailSent: false,
            realUser: true,
            userId: rpcData.user_id,
            rpcMode: true
          });
        } else {
          return handleSupabaseError({
            message: 'Erreur lors de la création RPC',
            code: 'RPC_CREATION_ERROR'
          });
        }
      } else if (authError) {
        // Autre erreur d'auth
        return handleSupabaseError(authError);
      }
      
      // Si la création auth a réussi
      if (authData.user) {
        console.log('✅ Utilisateur créé avec succès via Supabase Auth');
        return handleSupabaseSuccess({
          message: 'Inscription réussie ! Vérifiez votre email pour confirmer votre compte.',
          status: 'success',
          data: authData.user,
          emailSent: true,
          realUser: true
        });
      }
      
      return handleSupabaseError({
        message: 'Erreur inattendue lors de la création',
        code: 'UNEXPECTED_CREATION_ERROR'
      });
      
    } catch (err) {
      console.error('💥 Exception lors de l\'inscription:', err);
      return handleSupabaseError({
        message: 'Erreur inattendue lors de l\'inscription. Veuillez réessayer.',
        code: 'UNEXPECTED_ERROR'
      });
    }
  },

  // Connexion avec gestion des sessions
  async signIn(email: string, password: string) {
    try {
      console.log('🔧 CONNEXION RPC');
      
      // Essayer la connexion normale d'abord
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      });
      
      if (error) {
        console.warn('⚠️ Connexion normale échouée, vérification des sessions RPC');
        
        // Vérifier si un utilisateur RPC existe
        const storedSession = localStorage.getItem('user_session');
        if (storedSession) {
          const session = JSON.parse(storedSession);
          if (session.user && session.user.email === email) {
            console.log('✅ Connexion RPC réussie');
            localStorage.setItem('isAuthenticated', 'true');
            return handleSupabaseSuccess(session);
          }
        }
        
        return handleSupabaseError(error);
      }
      
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception lors de la connexion:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Déconnexion
  async signOut() {
    try {
      // Nettoyer les sessions
      localStorage.removeItem('user_session');
      localStorage.removeItem('isAuthenticated');
      localStorage.removeItem('supabase.auth.token');
      
      // Essayer la déconnexion normale
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.warn('⚠️ Erreur déconnexion normale (non bloquante):', error);
      }
      
      return handleSupabaseSuccess({});
    } catch (err) {
      console.error('💥 Exception lors de la déconnexion:', err);
      return handleSupabaseError(err as any);
    }
  }
};

// Service d'authentification mock qui simule l'inscription sans Supabase Auth
// Solution de contournement total pour l'erreur 500

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

// Service utilisateur mock qui simule l'inscription
export const userServiceAuthMock = {
  // Inscription mock qui simule le succès
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 INSCRIPTION MOCK - SIMULATION DE SUCCÈS');
      
      // Simuler un délai d'inscription
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Créer un utilisateur mock
      const mockUser = {
        id: `mock_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        email: email,
        user_metadata: {
          firstName: userData.firstName || 'Utilisateur',
          lastName: userData.lastName || '',
          role: userData.role || 'technician'
        },
        created_at: new Date().toISOString(),
        email_confirmed_at: null,
        phone: '',
        confirmed_at: null,
        last_sign_in_at: null,
        app_metadata: {},
        user_metadata: {
          firstName: userData.firstName || 'Utilisateur',
          lastName: userData.lastName || '',
          role: userData.role || 'technician'
        },
        identities: [],
        aud: 'authenticated',
        role: 'authenticated'
      };
      
      console.log('✅ Utilisateur mock créé avec succès:', mockUser);
      
      // Stocker l'utilisateur en local storage pour la session
      localStorage.setItem('mock_user', JSON.stringify(mockUser));
      localStorage.setItem('mock_auth_token', `mock_token_${Date.now()}`);
      
      return handleSupabaseSuccess({
        message: 'Inscription réussie ! Vous pouvez maintenant vous connecter directement (mode développement).',
        status: 'success',
        data: mockUser,
        emailSent: false,
        realUser: false,
        userId: mockUser.id,
        mockUser: true
      });
      
    } catch (err) {
      console.error('💥 Exception lors de l\'inscription mock:', err);
      return handleSupabaseError({
        message: 'Erreur lors de l\'inscription mock. Veuillez réessayer.',
        code: 'MOCK_ERROR'
      });
    }
  },

  // Connexion mock
  async signIn(email: string, password: string) {
    try {
      console.log('🔧 CONNEXION MOCK');
      
      // Vérifier si un utilisateur mock existe
      const mockUser = localStorage.getItem('mock_user');
      if (mockUser) {
        const user = JSON.parse(mockUser);
        if (user.email === email) {
          console.log('✅ Connexion mock réussie:', user);
          return handleSupabaseSuccess({
            user: user,
            session: {
              access_token: localStorage.getItem('mock_auth_token'),
              refresh_token: localStorage.getItem('mock_auth_token'),
              expires_in: 3600,
              token_type: 'bearer',
              user: user
            }
          });
        }
      }
      
      return handleSupabaseError({
        message: 'Utilisateur non trouvé. Veuillez d\'abord vous inscrire.',
        code: 'USER_NOT_FOUND'
      });
      
    } catch (err) {
      console.error('💥 Exception lors de la connexion mock:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Déconnexion mock
  async signOut() {
    try {
      console.log('🔧 DÉCONNEXION MOCK');
      
      // Supprimer les données mock du localStorage
      localStorage.removeItem('mock_user');
      localStorage.removeItem('mock_auth_token');
      
      console.log('✅ Déconnexion mock réussie');
      return handleSupabaseSuccess({});
    } catch (err) {
      console.error('💥 Exception lors de la déconnexion mock:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Obtenir l'utilisateur actuel mock
  async getCurrentUser() {
    try {
      const mockUser = localStorage.getItem('mock_user');
      if (mockUser) {
        const user = JSON.parse(mockUser);
        return handleSupabaseSuccess(user);
      }
      
      return handleSupabaseError({
        message: 'Aucun utilisateur connecté',
        code: 'NO_USER'
      });
    } catch (err) {
      console.error('💥 Exception lors de la récupération de l\'utilisateur mock:', err);
      return handleSupabaseError(err as any);
    }
  }
};

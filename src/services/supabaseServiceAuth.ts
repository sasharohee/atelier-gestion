// Service d'authentification qui utilise vraiment Supabase Auth
// Utilise l'API Supabase Auth normale avec gestion des erreurs

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

// Service utilisateur avec Supabase Auth réel
export const userServiceAuth = {
  // Inscription avec Supabase Auth réel
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 INSCRIPTION SUPABASE AUTH RÉEL');
      
      // Utiliser l'API Supabase Auth normale
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

      if (authError) {
        console.error('❌ Erreur auth:', authError);
        return handleSupabaseError(authError);
      }
      
      if (authData.user) {
        console.log('✅ Utilisateur créé avec succès via Supabase Auth:', authData.user);
        
        return handleSupabaseSuccess({
          message: 'Inscription réussie ! Vérifiez votre email pour confirmer votre compte.',
          status: 'success',
          data: authData.user,
          emailSent: true,
          realUser: true,
          userId: authData.user.id
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

  // Connexion avec Supabase Auth réel
  async signIn(email: string, password: string) {
    try {
      console.log('🔧 CONNEXION SUPABASE AUTH RÉEL');
      
      // Utiliser l'API Supabase Auth normale
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      });
      
      if (error) {
        console.error('❌ Erreur connexion:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Connexion réussie via Supabase Auth:', data.user);
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception lors de la connexion:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Déconnexion avec Supabase Auth réel
  async signOut() {
    try {
      console.log('🔧 DÉCONNEXION SUPABASE AUTH RÉEL');
      
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error('❌ Erreur déconnexion:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Déconnexion réussie via Supabase Auth');
      return handleSupabaseSuccess({});
    } catch (err) {
      console.error('💥 Exception lors de la déconnexion:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Obtenir l'utilisateur actuel
  async getCurrentUser() {
    try {
      const { data: { user }, error } = await supabase.auth.getUser();
      if (error) {
        return handleSupabaseError(error);
      }
      
      return handleSupabaseSuccess(user);
    } catch (err) {
      console.error('💥 Exception lors de la récupération de l\'utilisateur:', err);
      return handleSupabaseError(err as any);
    }
  }
};

// Service d'authentification ultra-simple qui évite complètement le trigger
// Solution de contournement pour l'erreur 500

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

// Service utilisateur ultra-simple sans trigger
export const userServiceAuthSimple = {
  // Inscription ultra-simple sans metadata
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 INSCRIPTION ULTRA-SIMPLE SANS TRIGGER');
      
      // Inscription minimale sans metadata pour éviter le trigger
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: email,
        password: password
        // Pas de metadata pour éviter le trigger problématique
      });

      if (authError) {
        console.error('❌ Erreur auth simple:', authError);
        return handleSupabaseError(authError);
      }
      
      if (authData.user) {
        console.log('✅ Utilisateur créé avec méthode simple:', authData.user);
        
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
      console.error('💥 Exception lors de l\'inscription simple:', err);
      return handleSupabaseError({
        message: 'Erreur inattendue lors de l\'inscription. Veuillez réessayer.',
        code: 'UNEXPECTED_ERROR'
      });
    }
  },

  // Connexion
  async signIn(email: string, password: string) {
    try {
      console.log('🔧 CONNEXION SIMPLE');
      
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      });
      
      if (error) {
        console.error('❌ Erreur connexion:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Connexion réussie:', data.user);
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception lors de la connexion:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Déconnexion
  async signOut() {
    try {
      console.log('🔧 DÉCONNEXION SIMPLE');
      
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error('❌ Erreur déconnexion:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Déconnexion réussie');
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

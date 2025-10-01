// Service d'authentification direct qui évite complètement le trigger problématique
// Utilise une approche différente pour créer des utilisateurs réels

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

// Service utilisateur direct qui évite le trigger
export const userServiceAuthDirect = {
  // Inscription directe sans metadata pour éviter le trigger
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 INSCRIPTION DIRECTE SANS TRIGGER');
      
      // Inscription minimale sans metadata pour éviter le trigger
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: email,
        password: password
        // Pas de metadata pour éviter le trigger problématique
      });

      if (authError) {
        console.error('❌ Erreur auth direct:', authError);
        return handleSupabaseError(authError);
      }
      
      if (authData.user) {
        console.log('✅ Utilisateur créé avec méthode directe:', authData.user);
        
        // Créer manuellement l'enregistrement utilisateur après l'inscription
        try {
          await this.createUserRecord(authData.user.id, userData);
        } catch (recordError) {
          console.warn('⚠️ Impossible de créer l\'enregistrement utilisateur:', recordError);
          // Continuer même si la création de l'enregistrement échoue
        }
        
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
      console.error('💥 Exception lors de l\'inscription directe:', err);
      return handleSupabaseError({
        message: 'Erreur inattendue lors de l\'inscription. Veuillez réessayer.',
        code: 'UNEXPECTED_ERROR'
      });
    }
  },

  // Créer manuellement l'enregistrement utilisateur
  async createUserRecord(userId: string, userData: Partial<User>) {
    try {
      const { error } = await supabase
        .from('users')
        .insert({
          id: userId,
          first_name: userData.firstName || 'Utilisateur',
          last_name: userData.lastName || '',
          email: userData.email || '',
          role: userData.role || 'technician',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });

      if (error) {
        console.warn('⚠️ Erreur lors de la création de l\'enregistrement utilisateur:', error);
        // Ne pas faire échouer l'inscription pour cette erreur
      } else {
        console.log('✅ Enregistrement utilisateur créé manuellement');
      }
    } catch (err) {
      console.warn('⚠️ Exception lors de la création de l\'enregistrement utilisateur:', err);
    }
  },

  // Connexion
  async signIn(email: string, password: string) {
    try {
      console.log('🔧 CONNEXION DIRECTE');
      
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
      console.log('🔧 DÉCONNEXION DIRECTE');
      
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

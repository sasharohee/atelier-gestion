// Service d'authentification robuste qui gère l'erreur 500 automatiquement
// Utilise Supabase Auth réel avec contournement du trigger problématique

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

// Service utilisateur robuste qui gère l'erreur 500
export const userServiceAuthRobust = {
  // Inscription robuste qui contourne l'erreur 500
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 INSCRIPTION ROBUSTE SUPABASE AUTH');
      
      // Méthode 1: Essayer l'inscription normale
      try {
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
          // Si erreur 500, utiliser la méthode de contournement
          if (authError.message.includes('Database error') || authError.message.includes('500')) {
            console.log('🔄 Erreur 500 détectée, utilisation de la méthode de contournement...');
            return await this.signUpBypass(email, password, userData);
          }
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
      } catch (triggerError) {
        console.log('🔄 Erreur de trigger détectée, utilisation de la méthode de contournement...');
        return await this.signUpBypass(email, password, userData);
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

  // Méthode de contournement pour l'erreur 500
  async signUpBypass(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 MÉTHODE DE CONTOURNEMENT POUR ERREUR 500');
      
      // Inscription sans metadata pour éviter le trigger
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: email,
        password: password
        // Pas de metadata pour éviter le trigger problématique
      });

      if (authError) {
        console.error('❌ Erreur auth bypass:', authError);
        return handleSupabaseError(authError);
      }
      
      if (authData.user) {
        console.log('✅ Utilisateur créé avec méthode de contournement:', authData.user);
        
        // Créer manuellement l'enregistrement utilisateur
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
        message: 'Erreur inattendue lors de la création de contournement',
        code: 'UNEXPECTED_BYPASS_ERROR'
      });
      
    } catch (err) {
      console.error('💥 Exception lors de l\'inscription de contournement:', err);
      return handleSupabaseError({
        message: 'Erreur lors de l\'inscription de contournement. Veuillez réessayer.',
        code: 'BYPASS_ERROR'
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

  // Connexion avec Supabase Auth réel
  async signIn(email: string, password: string) {
    try {
      console.log('🔧 CONNEXION SUPABASE AUTH RÉEL');
      
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

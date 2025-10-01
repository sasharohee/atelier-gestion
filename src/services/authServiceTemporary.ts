// Service d'authentification temporaire pour contourner l'erreur de trigger
// Ce service crée les utilisateurs directement dans les tables sans passer par les triggers

import { supabase } from '../lib/supabase';
import { User } from '../types/User';

export const temporaryAuthService = {
  // Inscription temporaire qui contourne les triggers
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 Inscription temporaire - Contournement du trigger problématique');
      
      // Étape 1: Créer l'utilisateur dans auth.users via l'API Supabase
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: email,
        password: password
      });

      if (authError) {
        console.error('❌ Erreur auth Supabase:', authError);
        return {
          success: false,
          error: authError.message
        };
      }

      if (!authData.user) {
        return {
          success: false,
          error: 'Aucun utilisateur créé'
        };
      }

      console.log('✅ Utilisateur auth créé:', authData.user.id);

      // Étape 2: Créer manuellement les enregistrements dans les tables publiques
      try {
        // Créer l'utilisateur dans public.users
        const { error: userError } = await supabase
          .from('users')
          .insert({
            id: authData.user.id,
            first_name: userData.firstName || 'Utilisateur',
            last_name: userData.lastName || '',
            email: email,
            role: userData.role || 'technician',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });

        if (userError) {
          console.warn('⚠️ Erreur création users (non bloquante):', userError);
        } else {
          console.log('✅ Utilisateur créé dans public.users');
        }

        // Créer le profil utilisateur
        const { error: profileError } = await supabase
          .from('user_profiles')
          .insert({
            user_id: authData.user.id,
            first_name: userData.firstName || 'Utilisateur',
            last_name: userData.lastName || '',
            email: email,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });

        if (profileError) {
          console.warn('⚠️ Erreur création profile (non bloquante):', profileError);
        } else {
          console.log('✅ Profil créé dans public.user_profiles');
        }

        // Créer les préférences utilisateur
        const { error: prefsError } = await supabase
          .from('user_preferences')
          .insert({
            user_id: authData.user.id,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });

        if (prefsError) {
          console.warn('⚠️ Erreur création preferences (non bloquante):', prefsError);
        } else {
          console.log('✅ Préférences créées dans public.user_preferences');
        }

      } catch (manualError) {
        console.warn('⚠️ Erreur lors de la création manuelle (non bloquante):', manualError);
      }

      return {
        success: true,
        data: {
          user: authData.user,
          session: authData.session,
          message: 'Inscription réussie ! Vérifiez votre email pour confirmer votre compte.'
        }
      };

    } catch (error: any) {
      console.error('❌ Erreur inattendue lors de l\'inscription temporaire:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de l\'inscription'
      };
    }
  },

  // Connexion normale (inchangée)
  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    if (error) return { success: false, error: error.message };
    return { success: true, data };
  },

  // Déconnexion
  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) return { success: false, error: error.message };
    return { success: true };
  }
};

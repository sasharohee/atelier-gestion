// Service d'authentification qui contourne complètement Supabase Auth
// Crée des utilisateurs directement dans la base de données

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

// Service utilisateur qui contourne Supabase Auth
export const userServiceAuthBypass = {
  // Inscription directe dans la base de données
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 INSCRIPTION BYPASS - CRÉATION DIRECTE EN BASE');
      
      // Générer un ID utilisateur unique
      const userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // Créer l'utilisateur directement dans la table users
      const { data: insertedUser, error: insertError } = await supabase
        .from('users')
        .insert({
          id: userId,
          email: email,
          first_name: userData.firstName || 'Utilisateur',
          last_name: userData.lastName || '',
          role: userData.role || 'technician',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          email_confirmed_at: new Date().toISOString(), // Confirmer automatiquement
          is_active: true
        })
        .select()
        .single();

      if (insertError) {
        console.error('❌ Erreur création utilisateur direct:', insertError);
        return handleSupabaseError(insertError);
      }

      console.log('✅ Utilisateur créé directement en base:', insertedUser);
      
      // Simuler un objet utilisateur Supabase Auth
      const mockAuthUser = {
        id: userId,
        email: email,
        user_metadata: {
          firstName: userData.firstName || 'Utilisateur',
          lastName: userData.lastName || '',
          role: userData.role || 'technician'
        },
        created_at: new Date().toISOString(),
        email_confirmed_at: new Date().toISOString(),
        last_sign_in_at: null,
        app_metadata: {},
        aud: 'authenticated',
        confirmation_sent_at: new Date().toISOString()
      };

      return handleSupabaseSuccess({
        message: 'Inscription réussie ! Vous pouvez maintenant vous connecter.',
        status: 'success',
        data: mockAuthUser,
        emailSent: false, // Pas d'email car contournement
        realUser: true,
        userId: userId,
        bypassMode: true
      });
      
    } catch (err) {
      console.error('💥 Exception lors de l\'inscription bypass:', err);
      return handleSupabaseError({
        message: 'Erreur inattendue lors de l\'inscription. Veuillez réessayer.',
        code: 'UNEXPECTED_ERROR'
      });
    }
  },

  // Connexion en vérifiant directement la base de données
  async signIn(email: string, password: string) {
    try {
      console.log('🔧 CONNEXION BYPASS - VÉRIFICATION DIRECTE');
      
      // Rechercher l'utilisateur par email
      const { data: userData, error: selectError } = await supabase
        .from('users')
        .select('*')
        .eq('email', email)
        .eq('is_active', true)
        .single();

      if (selectError || !userData) {
        console.error('❌ Utilisateur non trouvé:', selectError);
        return handleSupabaseError({
          message: 'Email ou mot de passe incorrect',
          code: 'INVALID_CREDENTIALS'
        });
      }

      // Simuler un objet utilisateur Supabase Auth
      const mockAuthUser = {
        id: userData.id,
        email: userData.email,
        user_metadata: {
          firstName: userData.first_name,
          lastName: userData.last_name,
          role: userData.role
        },
        created_at: userData.created_at,
        email_confirmed_at: userData.email_confirmed_at,
        last_sign_in_at: new Date().toISOString(),
        app_metadata: {},
        aud: 'authenticated'
      };

      console.log('✅ Connexion bypass réussie:', mockAuthUser);
      return handleSupabaseSuccess({
        user: mockAuthUser,
        session: {
          access_token: `bypass_token_${Date.now()}`,
          refresh_token: `bypass_refresh_${Date.now()}`,
          user: mockAuthUser
        }
      });
      
    } catch (err) {
      console.error('💥 Exception lors de la connexion bypass:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Déconnexion
  async signOut() {
    try {
      console.log('🔧 DÉCONNEXION BYPASS');
      console.log('✅ Déconnexion bypass réussie');
      return handleSupabaseSuccess({});
    } catch (err) {
      console.error('💥 Exception lors de la déconnexion bypass:', err);
      return handleSupabaseError(err as any);
    }
  },

  // Obtenir l'utilisateur actuel (simulation)
  async getCurrentUser() {
    try {
      // Pour le bypass, on ne peut pas vraiment récupérer l'utilisateur actuel
      // car on n'utilise pas les sessions Supabase
      return handleSupabaseSuccess(null);
    } catch (err) {
      console.error('💥 Exception lors de la récupération de l\'utilisateur:', err);
      return handleSupabaseError(err as any);
    }
  }
};
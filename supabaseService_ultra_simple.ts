// Version ultra-simplifiée du service d'authentification
// Cette version évite complètement les appels à la base de données lors de l'inscription

import { supabase } from '../lib/supabase';
import { User } from '../types';

// Fonction de gestion d'erreur simplifiée
const handleError = (error: any) => {
  console.error('Erreur:', error);
  return {
    success: false,
    error: error?.message || 'Une erreur est survenue'
  };
};

// Fonction de succès simplifiée
const handleSuccess = <T>(data: T) => {
  return {
    success: true,
    data
  };
};

// Service d'authentification ultra-simplifié
export const userService = {
  // Inscription ultra-simple - SEULEMENT Supabase Auth, pas de base de données
  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 Inscription ultra-simple via Supabase Auth uniquement:', { email });
      
      // Appel direct à Supabase Auth SANS options de données pour éviter les triggers
      const { data, error } = await supabase.auth.signUp({
        email: email,
        password: password
        // PAS d'options.data pour éviter les triggers
        // PAS d'emailRedirectTo pour éviter les problèmes
      });
      
      if (error) {
        console.error('❌ Erreur lors de l\'inscription:', error);
        
        // Gestion des erreurs spécifiques
        if (error.message.includes('already registered')) {
          return handleError({
            message: 'Un compte avec cet email existe déjà. Veuillez vous connecter.',
            code: 'ACCOUNT_EXISTS'
          });
        }
        
        return handleError({
          message: 'Erreur lors de l\'inscription. Veuillez réessayer.',
          code: 'SIGNUP_ERROR'
        });
      }
      
      console.log('✅ Inscription réussie:', data);
      
      // Stocker les données utilisateur pour traitement différé
      if (data.user) {
        const pendingUserData = {
          userId: data.user.id,
          email: email,
          firstName: userData.firstName || 'Utilisateur',
          lastName: userData.lastName || 'Test',
          role: userData.role || 'technician',
          timestamp: new Date().toISOString()
        };
        
        localStorage.setItem('pendingUserData', JSON.stringify(pendingUserData));
        console.log('💾 Données utilisateur stockées pour traitement différé');
      }
      
      // Stocker l'email pour vérification
      localStorage.setItem('pendingSignupEmail', email);
      
      return handleSuccess({
        message: 'Inscription réussie ! Vérifiez votre email pour confirmer votre compte. Les données seront créées lors de votre première connexion.',
        status: 'pending',
        data: data.user,
        emailSent: true,
        needsDataCreation: true
      });
    } catch (err) {
      console.error('💥 Exception lors de l\'inscription:', err);
      return handleError({
        message: 'Erreur inattendue lors de l\'inscription. Veuillez réessayer.',
        code: 'UNEXPECTED_ERROR'
      });
    }
  },

  // Connexion simple
  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    if (error) return handleError(error);
    return handleSuccess(data);
  },

  // Déconnexion simple
  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) return handleError(error);
    
    // Nettoyer les données en attente
    localStorage.removeItem('pendingUserData');
    localStorage.removeItem('pendingSignupEmail');
    
    return handleSuccess(true);
  },

  // Traitement des données utilisateur en attente lors de la connexion
  async processPendingUserData() {
    try {
      const pendingData = localStorage.getItem('pendingUserData');
      if (!pendingData) return;

      const userData = JSON.parse(pendingData);
      console.log('🔄 Traitement des données utilisateur en attente:', userData);

      // Vérifier que l'utilisateur est connecté
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) {
        console.log('⚠️ Utilisateur non connecté, traitement différé');
        return;
      }

      // Créer l'utilisateur dans la table users
      const newUserData = {
        id: user.id,
        email: userData.email,
        first_name: userData.firstName,
        last_name: userData.lastName,
        role: userData.role,
        avatar: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data: insertData, error: insertError } = await supabase
        .from('users')
        .insert([newUserData])
        .select()
        .single();

      if (insertError) {
        console.error('❌ Erreur lors de la création de l\'utilisateur:', insertError);
        return;
      }

      console.log('✅ Utilisateur créé avec succès:', insertData);

      // Créer les données par défaut de manière asynchrone
      setTimeout(async () => {
        try {
          const { data: rpcData, error: rpcError } = await supabase.rpc('create_user_default_data', {
            p_user_id: user.id
          });

          if (rpcError) {
            console.warn('⚠️ Erreur lors de la création des données par défaut (non bloquant):', rpcError);
          } else {
            console.log('✅ Données par défaut créées pour l\'utilisateur:', user.id);
          }
        } catch (rpcError) {
          console.warn('⚠️ Exception lors de la création des données par défaut (non bloquant):', rpcError);
        }
      }, 2000);

      // Nettoyer les données en attente
      localStorage.removeItem('pendingUserData');
      console.log('✅ Données utilisateur traitées avec succès');

    } catch (err) {
      console.error('❌ Erreur lors du traitement des données utilisateur:', err);
    }
  }
};

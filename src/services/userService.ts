import { supabase } from '../lib/supabase';
import { User } from '@supabase/supabase-js';

// Types pour les réponses du service utilisateur
export interface UserResponse {
  success: boolean;
  data?: any;
  error?: string | null;
  message?: string;
}

export interface UserProfile {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: string;
  avatar?: string;
  createdAt: Date;
  updatedAt: Date;
  isEmailConfirmed: boolean;
}

// Service utilisateur simplifié et robuste
export const userService = {
  /**
   * Récupérer le profil de l'utilisateur actuel
   */
  async getCurrentUser(): Promise<UserResponse> {
    try {
      console.log('👤 Récupération du profil utilisateur...');

      // Récupérer l'utilisateur depuis Supabase Auth
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        console.log('⚠️ Aucun utilisateur authentifié');
        return {
          success: false,
          error: 'Utilisateur non authentifié',
          message: 'Veuillez vous connecter'
        };
      }

      // Récupérer les données complètes depuis la table users
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single();

      if (userError) {
        console.error('❌ Erreur lors de la récupération des données utilisateur:', userError);
        
        // Si l'utilisateur n'existe pas dans la table users, le créer
        if (userError.code === 'PGRST116') {
          console.log('🔄 Création automatique du profil utilisateur...');
          return await this.createUserProfile(user);
        }
        
        return {
          success: false,
          error: 'Erreur lors de la récupération du profil',
          message: 'Impossible de charger les données utilisateur'
        };
      }

      // Convertir les données vers le format attendu
      const profile: UserProfile = {
        id: userData.id,
        firstName: userData.first_name,
        lastName: userData.last_name,
        email: userData.email,
        role: userData.role,
        avatar: userData.avatar,
        createdAt: new Date(userData.created_at),
        updatedAt: new Date(userData.updated_at),
        isEmailConfirmed: !!user.email_confirmed_at
      };

      console.log('✅ Profil utilisateur récupéré:', profile.email);
      
      return {
        success: true,
        data: profile,
        message: 'Profil récupéré avec succès'
      };

    } catch (error) {
      console.error('💥 Exception lors de la récupération du profil:', error);
      return {
        success: false,
        error: 'Erreur inattendue',
        message: 'Erreur lors de la récupération du profil'
      };
    }
  },

  /**
   * Créer le profil utilisateur dans la table users
   */
  async createUserProfile(authUser: User): Promise<UserResponse> {
    try {
      console.log('🔄 Création du profil utilisateur pour:', authUser.email);

      const userData = {
        id: authUser.id,
        first_name: authUser.user_metadata?.firstName || 'Utilisateur',
        last_name: authUser.user_metadata?.lastName || '',
        email: authUser.email || '',
        role: authUser.user_metadata?.role || 'technician',
        avatar: authUser.user_metadata?.avatar || null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data, error } = await supabase
        .from('users')
        .insert([userData])
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur lors de la création du profil:', error);
        return {
          success: false,
          error: 'Erreur lors de la création du profil',
          message: 'Impossible de créer le profil utilisateur'
        };
      }

      // Convertir les données vers le format attendu
      const profile: UserProfile = {
        id: data.id,
        firstName: data.first_name,
        lastName: data.last_name,
        email: data.email,
        role: data.role,
        avatar: data.avatar,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at),
        isEmailConfirmed: !!authUser.email_confirmed_at
      };

      console.log('✅ Profil utilisateur créé:', profile.email);
      
      return {
        success: true,
        data: profile,
        message: 'Profil créé avec succès'
      };

    } catch (error) {
      console.error('💥 Exception lors de la création du profil:', error);
      return {
        success: false,
        error: 'Erreur inattendue',
        message: 'Erreur lors de la création du profil'
      };
    }
  },

  /**
   * Mettre à jour le profil utilisateur
   */
  async updateProfile(updates: Partial<UserProfile>): Promise<UserResponse> {
    try {
      console.log('🔄 Mise à jour du profil utilisateur...');

      // Récupérer l'utilisateur actuel
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        return {
          success: false,
          error: 'Utilisateur non authentifié',
          message: 'Veuillez vous connecter'
        };
      }

      // Préparer les données à mettre à jour
      const updateData: any = {
        updated_at: new Date().toISOString()
      };

      if (updates.firstName) updateData.first_name = updates.firstName;
      if (updates.lastName) updateData.last_name = updates.lastName;
      if (updates.avatar !== undefined) updateData.avatar = updates.avatar;
      if (updates.role) updateData.role = updates.role;

      // Mettre à jour dans la table users
      const { data, error } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', user.id)
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur lors de la mise à jour:', error);
        return {
          success: false,
          error: 'Erreur lors de la mise à jour',
          message: 'Impossible de mettre à jour le profil'
        };
      }

      // Mettre à jour les métadonnées dans auth.users si nécessaire
      if (updates.firstName || updates.lastName || updates.role) {
        const metadata: any = {};
        if (updates.firstName) metadata.firstName = updates.firstName;
        if (updates.lastName) metadata.lastName = updates.lastName;
        if (updates.role) metadata.role = updates.role;

        const { error: metadataError } = await supabase.auth.updateUser({
          data: metadata
        });

        if (metadataError) {
          console.warn('⚠️ Erreur lors de la mise à jour des métadonnées:', metadataError);
        }
      }

      // Convertir les données vers le format attendu
      const profile: UserProfile = {
        id: data.id,
        firstName: data.first_name,
        lastName: data.last_name,
        email: data.email,
        role: data.role,
        avatar: data.avatar,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at),
        isEmailConfirmed: !!user.email_confirmed_at
      };

      console.log('✅ Profil utilisateur mis à jour:', profile.email);
      
      return {
        success: true,
        data: profile,
        message: 'Profil mis à jour avec succès'
      };

    } catch (error) {
      console.error('💥 Exception lors de la mise à jour:', error);
      return {
        success: false,
        error: 'Erreur inattendue',
        message: 'Erreur lors de la mise à jour du profil'
      };
    }
  },

  /**
   * Récupérer tous les utilisateurs (pour les admins)
   */
  async getAllUsers(): Promise<UserResponse> {
    try {
      console.log('👥 Récupération de tous les utilisateurs...');

      // Vérifier que l'utilisateur actuel est admin ou technicien
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        return {
          success: false,
          error: 'Utilisateur non authentifié',
          message: 'Veuillez vous connecter'
        };
      }

      // Récupérer le rôle de l'utilisateur actuel
      const { data: currentUser, error: roleError } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

      if (roleError || !currentUser) {
        return {
          success: false,
          error: 'Impossible de vérifier les permissions',
          message: 'Erreur de permissions'
        };
      }

      if (!['admin', 'technician'].includes(currentUser.role)) {
        return {
          success: false,
          error: 'Permissions insuffisantes',
          message: 'Seuls les administrateurs et techniciens peuvent voir tous les utilisateurs'
        };
      }

      // Récupérer tous les utilisateurs
      const { data: usersData, error: usersError } = await supabase
        .from('users')
        .select(`
          *,
          auth_users:auth.users(email_confirmed_at)
        `)
        .order('created_at', { ascending: false });

      if (usersError) {
        console.error('❌ Erreur lors de la récupération des utilisateurs:', usersError);
        return {
          success: false,
          error: 'Erreur lors de la récupération',
          message: 'Impossible de récupérer la liste des utilisateurs'
        };
      }

      // Convertir les données vers le format attendu
      const profiles: UserProfile[] = usersData.map((userData: any) => ({
        id: userData.id,
        firstName: userData.first_name,
        lastName: userData.last_name,
        email: userData.email,
        role: userData.role,
        avatar: userData.avatar,
        createdAt: new Date(userData.created_at),
        updatedAt: new Date(userData.updated_at),
        isEmailConfirmed: !!userData.auth_users?.email_confirmed_at
      }));

      console.log('✅ Utilisateurs récupérés:', profiles.length);
      
      return {
        success: true,
        data: profiles,
        message: `${profiles.length} utilisateur(s) récupéré(s)`
      };

    } catch (error) {
      console.error('💥 Exception lors de la récupération des utilisateurs:', error);
      return {
        success: false,
        error: 'Erreur inattendue',
        message: 'Erreur lors de la récupération des utilisateurs'
      };
    }
  },

  /**
   * Supprimer un utilisateur (pour les admins)
   */
  async deleteUser(userId: string): Promise<UserResponse> {
    try {
      console.log('🗑️ Suppression de l\'utilisateur:', userId);

      // Vérifier que l'utilisateur actuel est admin
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        return {
          success: false,
          error: 'Utilisateur non authentifié',
          message: 'Veuillez vous connecter'
        };
      }

      // Récupérer le rôle de l'utilisateur actuel
      const { data: currentUser, error: roleError } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

      if (roleError || !currentUser || currentUser.role !== 'admin') {
        return {
          success: false,
          error: 'Permissions insuffisantes',
          message: 'Seuls les administrateurs peuvent supprimer des utilisateurs'
        };
      }

      // Empêcher l'auto-suppression
      if (userId === user.id) {
        return {
          success: false,
          error: 'Auto-suppression interdite',
          message: 'Vous ne pouvez pas supprimer votre propre compte'
        };
      }

      // Supprimer l'utilisateur de la table users
      const { error: deleteError } = await supabase
        .from('users')
        .delete()
        .eq('id', userId);

      if (deleteError) {
        console.error('❌ Erreur lors de la suppression:', deleteError);
        return {
          success: false,
          error: 'Erreur lors de la suppression',
          message: 'Impossible de supprimer l\'utilisateur'
        };
      }

      console.log('✅ Utilisateur supprimé:', userId);
      
      return {
        success: true,
        message: 'Utilisateur supprimé avec succès'
      };

    } catch (error) {
      console.error('💥 Exception lors de la suppression:', error);
      return {
        success: false,
        error: 'Erreur inattendue',
        message: 'Erreur lors de la suppression de l\'utilisateur'
      };
    }
  }
};

// Export par défaut
export default userService;

// Service pour synchroniser automatiquement les utilisateurs manquants
// À appeler périodiquement ou lors du chargement de l'application

import { supabase } from '../lib/supabase';

export const userSyncService = {
  // Synchroniser tous les utilisateurs manquants
  async syncMissingUsers() {
    try {
      console.log('🔄 Synchronisation des utilisateurs manquants...');
      
      const { data, error } = await supabase.rpc('sync_all_missing_users');
      
      if (error) {
        console.error('❌ Erreur lors de la synchronisation:', error);
        return { success: false, error: error.message };
      }
      
      console.log('✅ Synchronisation réussie:', data);
      return { success: true, data };
    } catch (err) {
      console.error('❌ Exception lors de la synchronisation:', err);
      return { success: false, error: 'Erreur lors de la synchronisation' };
    }
  },

  // Vérifier les utilisateurs manquants
  async checkMissingUsers() {
    try {
      const { data, error } = await supabase.rpc('check_missing_users_count');
      
      if (error) {
        console.error('❌ Erreur lors de la vérification:', error);
        return { success: false, error: error.message };
      }
      
      return { success: true, count: data };
    } catch (err) {
      console.error('❌ Exception lors de la vérification:', err);
      return { success: false, error: 'Erreur lors de la vérification' };
    }
  },

  // Synchroniser un utilisateur spécifique
  async syncSpecificUser(userId: string) {
    try {
      console.log(`🔄 Synchronisation de l'utilisateur ${userId}...`);
      
      // Récupérer les données de l'utilisateur depuis auth.users
      const { data: authUser, error: authError } = await supabase.auth.admin.getUserById(userId);
      
      if (authError || !authUser.user) {
        return { success: false, error: 'Utilisateur non trouvé' };
      }
      
      const user = authUser.user;
      const userMetadata = user.user_metadata || {};
      
      // Insérer dans subscription_status
      const { data, error } = await supabase
        .from('subscription_status')
        .upsert({
          user_id: user.id,
          first_name: userMetadata.first_name || userMetadata.full_name?.split(' ')[0] || user.email?.split('@')[0] || 'Utilisateur',
          last_name: userMetadata.last_name || (userMetadata.full_name ? userMetadata.full_name.split(' ').slice(1).join(' ') : ''),
          email: user.email || '',
          is_active: false,
          subscription_type: 'free',
          created_at: user.created_at,
          updated_at: new Date().toISOString(),
          activated_at: null,
          activated_by: null,
          notes: 'Utilisateur synchronisé manuellement - en attente d\'activation'
        }, {
          onConflict: 'user_id'
        })
        .select();
      
      if (error) {
        console.error('❌ Erreur lors de l\'insertion:', error);
        return { success: false, error: error.message };
      }
      
      console.log('✅ Utilisateur synchronisé:', data[0]);
      return { success: true, data: data[0] };
    } catch (err) {
      console.error('❌ Exception lors de la synchronisation:', err);
      return { success: false, error: 'Erreur lors de la synchronisation' };
    }
  },

  // Synchronisation automatique au démarrage de l'application
  async autoSyncOnStartup() {
    try {
      console.log('🚀 Synchronisation automatique au démarrage...');
      
      // Vérifier s'il y a des utilisateurs manquants
      const missingCheck = await this.checkMissingUsers();
      
      if (!missingCheck.success) {
        console.warn('⚠️ Impossible de vérifier les utilisateurs manquants');
        return;
      }
      
      if (missingCheck.count > 0) {
        console.log(`📊 ${missingCheck.count} utilisateurs manquants détectés, synchronisation...`);
        
        const syncResult = await this.syncMissingUsers();
        
        if (syncResult.success) {
          console.log('✅ Synchronisation automatique réussie');
        } else {
          console.error('❌ Échec de la synchronisation automatique:', syncResult.error);
        }
      } else {
        console.log('✅ Tous les utilisateurs sont synchronisés');
      }
    } catch (err) {
      console.error('❌ Erreur lors de la synchronisation automatique:', err);
    }
  }
};

// Fonction utilitaire pour synchroniser depuis n'importe où dans l'application
export const syncUsersOnDemand = async () => {
  try {
    const result = await userSyncService.syncMissingUsers();
    
    if (result.success) {
      console.log('✅ Utilisateurs synchronisés avec succès');
      return true;
    } else {
      console.error('❌ Échec de la synchronisation:', result.error);
      return false;
    }
  } catch (err) {
    console.error('❌ Erreur lors de la synchronisation:', err);
    return false;
  }
};














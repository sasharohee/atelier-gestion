import { supabase } from '../lib/supabase';
import { handleSupabaseError, handleSupabaseSuccess } from '../lib/supabase';
import bcrypt from 'bcryptjs';

/**
 * Helper function to get the current authenticated user ID
 * Note: We don't need to pass user_id explicitly as RLS policies will handle it automatically
 */
const getCurrentUserId = async (): Promise<string | null> => {
  try {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) {
      console.error('Erreur lors de la récupération de l\'utilisateur:', error);
      return null;
    }
    return user?.id || null;
  } catch (err) {
    console.error('Exception lors de la récupération de l\'utilisateur:', err);
    return null;
  }
};

export interface AccountingPasswordResult {
  success: boolean;
  data?: any;
  error?: string;
}

export const accountingPasswordServiceFallback = {
  /**
   * Vérifier si un mot de passe comptable existe
   * Version fallback qui gère les erreurs de table
   */
  async hasPassword(): Promise<AccountingPasswordResult> {
    try {
      const userId = await getCurrentUserId();
      if (!userId) {
        console.warn('Utilisateur non authentifié, utilisation du fallback localStorage');
        const storedHash = localStorage.getItem('accounting_password_hash');
        return handleSupabaseSuccess(!!storedHash);
      }

      // Essayer d'abord avec la fonction RPC
      const { data, error } = await supabase.rpc('get_system_setting', {
        setting_key: 'accounting_password_hash'
      });

      // Si la fonction RPC n'existe pas, utiliser l'approche directe
      if (error && error.code === 'PGRST301') {
        console.log('Fonction RPC non trouvée, utilisation de l\'approche directe');
        const { data: directData, error: directError } = await supabase
          .from('system_settings')
          .select('value')
          .eq('key', 'accounting_password_hash')
          .single();
        
        if (directError && directError.code !== 'PGRST116') {
          console.warn('Erreur avec system_settings, utilisation du fallback:', directError);
          // Fallback: utiliser localStorage
          const storedHash = localStorage.getItem('accounting_password_hash');
          return handleSupabaseSuccess(!!storedHash);
        }
        
        const hasPassword = directData?.value && directData.value !== '';
        return handleSupabaseSuccess(hasPassword);
      }

      if (error) {
        console.warn('Erreur avec la fonction RPC, utilisation du fallback:', error);
        // Fallback: utiliser localStorage
        const storedHash = localStorage.getItem('accounting_password_hash');
        return handleSupabaseSuccess(!!storedHash);
      }

      const hasPassword = data?.data?.value && data.data.value !== '';
      return handleSupabaseSuccess(hasPassword);
    } catch (err) {
      console.warn('Exception avec system_settings, utilisation du fallback:', err);
      // Fallback: utiliser localStorage
      const storedHash = localStorage.getItem('accounting_password_hash');
      return handleSupabaseSuccess(!!storedHash);
    }
  },

  /**
   * Définir le mot de passe comptable
   * Version fallback qui utilise localStorage en cas d'erreur
   */
  async setPassword(password: string): Promise<AccountingPasswordResult> {
    try {
      const userId = await getCurrentUserId();
      if (!userId) {
        console.warn('Utilisateur non authentifié, utilisation du fallback localStorage');
        const hashedPassword = await bcrypt.hash(password, 10);
        localStorage.setItem('accounting_password_hash', hashedPassword);
        return handleSupabaseSuccess({ fallback: true });
      }

      const hashedPassword = await bcrypt.hash(password, 10);

      // Essayer d'abord avec la fonction RPC
      const { data, error } = await supabase.rpc('upsert_system_setting', {
        setting_key: 'accounting_password_hash',
        setting_value: hashedPassword
      });

      // Si la fonction RPC n'existe pas, utiliser l'approche directe
      if (error && error.code === 'PGRST301') {
        console.log('Fonction RPC non trouvée, utilisation de l\'approche directe');
        const { data: directData, error: directError } = await supabase
          .from('system_settings')
          .upsert(
            {
              key: 'accounting_password_hash',
              value: hashedPassword,
              user_id: userId,
            },
            { onConflict: 'key,user_id' }
          )
          .select()
          .single();
        
        if (directError) {
          throw directError;
        }
        return handleSupabaseSuccess(directData);
      }

      if (error) {
        console.warn('Erreur avec system_settings, utilisation du fallback:', error);
        // Fallback: utiliser localStorage
        localStorage.setItem('accounting_password_hash', hashedPassword);
        return handleSupabaseSuccess({ fallback: true });
      }

      return handleSupabaseSuccess(data);
    } catch (err) {
      console.warn('Exception avec system_settings, utilisation du fallback:', err);
      // Fallback: utiliser localStorage
      const hashedPassword = await bcrypt.hash(password, 10);
      localStorage.setItem('accounting_password_hash', hashedPassword);
      return handleSupabaseSuccess({ fallback: true });
    }
  },

  /**
   * Vérifier le mot de passe comptable
   * Version fallback qui utilise localStorage en cas d'erreur
   */
  async verifyPassword(password: string): Promise<AccountingPasswordResult> {
    try {
      const userId = await getCurrentUserId();
      if (!userId) {
        console.warn('Utilisateur non authentifié, utilisation du fallback localStorage');
        const storedHash = localStorage.getItem('accounting_password_hash');
        if (!storedHash) {
          return handleSupabaseSuccess(false);
        }
        const isValid = await bcrypt.compare(password, storedHash);
        return handleSupabaseSuccess(isValid);
      }

      // Essayer d'abord avec la fonction RPC
      const { data, error } = await supabase.rpc('get_system_setting', {
        setting_key: 'accounting_password_hash'
      });

      // Si la fonction RPC n'existe pas, utiliser l'approche directe
      if (error && error.code === 'PGRST301') {
        console.log('Fonction RPC non trouvée, utilisation de l\'approche directe');
        const { data: directData, error: directError } = await supabase
          .from('system_settings')
          .select('value')
          .eq('key', 'accounting_password_hash')
          .single();
        
        if (directError && directError.code !== 'PGRST116') {
          console.warn('Erreur avec system_settings, utilisation du fallback:', directError);
          // Fallback: utiliser localStorage
          const storedHash = localStorage.getItem('accounting_password_hash');
          if (!storedHash) {
            return handleSupabaseSuccess(false);
          }
          const isValid = await bcrypt.compare(password, storedHash);
          return handleSupabaseSuccess(isValid);
        }

        if (!directData?.value) {
          return handleSupabaseSuccess(false);
        }

        const isValid = await bcrypt.compare(password, directData.value);
        return handleSupabaseSuccess(isValid);
      }

      if (error) {
        console.warn('Erreur avec la fonction RPC, utilisation du fallback:', error);
        // Fallback: utiliser localStorage
        const storedHash = localStorage.getItem('accounting_password_hash');
        if (!storedHash) {
          return handleSupabaseSuccess(false);
        }
        const isValid = await bcrypt.compare(password, storedHash);
        return handleSupabaseSuccess(isValid);
      }

      if (!data?.data?.value) {
        return handleSupabaseSuccess(false);
      }

      const isValid = await bcrypt.compare(password, data.data.value);
      return handleSupabaseSuccess(isValid);
    } catch (err) {
      console.warn('Exception avec system_settings, utilisation du fallback:', err);
      // Fallback: utiliser localStorage
      const storedHash = localStorage.getItem('accounting_password_hash');
      if (!storedHash) {
        return handleSupabaseSuccess(false);
      }
      const isValid = await bcrypt.compare(password, storedHash);
      return handleSupabaseSuccess(isValid);
    }
  },

  /**
   * Vérifier l'accès à la comptabilité
   */
  async checkAccess(): Promise<{ hasAccess: boolean; needsPassword: boolean; error?: string }> {
    try {
      const hasPasswordResult = await this.hasPassword();
      
      if (!hasPasswordResult.success) {
        return {
          hasAccess: false,
          needsPassword: false,
          error: hasPasswordResult.error
        };
      }

      // Si aucun mot de passe n'est défini, proposer d'en créer un
      if (!hasPasswordResult.data) {
        return {
          hasAccess: false,
          needsPassword: false
        };
      }

      // Un mot de passe existe, demander la saisie
      return {
        hasAccess: false,
        needsPassword: true
      };
    } catch (err) {
      console.error('Erreur lors de la vérification de l\'accès:', err);
      return {
        hasAccess: false,
        needsPassword: false,
        error: err instanceof Error ? err.message : 'Erreur inconnue'
      };
    }
  },

  /**
   * Marquer la session comme active (gestion côté client)
   */
  setSessionActive(): void {
    localStorage.setItem('accounting_session_active', 'true');
    localStorage.setItem('accounting_session_timestamp', Date.now().toString());
  },

  /**
   * Vérifier si la session est active
   */
  isSessionActive(): boolean {
    const isActive = localStorage.getItem('accounting_session_active') === 'true';
    const timestamp = localStorage.getItem('accounting_session_timestamp');
    
    if (!isActive || !timestamp) {
      return false;
    }

    // Vérifier si la session n'a pas expiré (30 minutes)
    const sessionTime = parseInt(timestamp);
    const now = Date.now();
    const thirtyMinutes = 30 * 60 * 1000; // 30 minutes en millisecondes

    if (now - sessionTime > thirtyMinutes) {
      // Session expirée, nettoyer
      this.clearSession();
      return false;
    }

    return true;
  },

  /**
   * Nettoyer la session
   */
  clearSession(): void {
    localStorage.removeItem('accounting_session_active');
    localStorage.removeItem('accounting_session_timestamp');
  },
};

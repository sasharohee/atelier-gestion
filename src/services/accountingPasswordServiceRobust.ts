import { supabase } from '../lib/supabase';
import { handleSupabaseError, handleSupabaseSuccess } from '../lib/supabase';
import bcrypt from 'bcryptjs';

export interface AccountingPasswordResult {
  success: boolean;
  data?: any;
  error?: string;
}

export const accountingPasswordServiceRobust = {
  /**
   * Vérifier si un mot de passe comptable existe
   */
  async hasPassword(): Promise<AccountingPasswordResult> {
    try {
      // Vérifier d'abord si la table existe
      const { data: tableCheck, error: tableError } = await supabase
        .from('system_settings')
        .select('id')
        .limit(1);

      if (tableError) {
        console.error('Erreur lors de la vérification de la table system_settings:', tableError);
        return handleSupabaseError(new Error('Table system_settings non accessible. Veuillez exécuter le script SQL de création.'));
      }

      const { data, error } = await supabase
        .from('system_settings')
        .select('value')
        .eq('key', 'accounting_password_hash')
        .single();

      if (error && error.code !== 'PGRST116') { // PGRST116 = no rows found
        console.error('Erreur lors de la vérification du mot de passe:', error);
        return handleSupabaseError(error);
      }

      const hasPassword = data?.value && data.value !== '';
      return handleSupabaseSuccess(hasPassword);
    } catch (err) {
      console.error('Exception lors de la vérification du mot de passe:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Définir le mot de passe comptable
   */
  async setPassword(password: string): Promise<AccountingPasswordResult> {
    try {
      const hashedPassword = await bcrypt.hash(password, 10);

      const { data, error } = await supabase
        .from('system_settings')
        .upsert(
          {
            key: 'accounting_password_hash',
            value: hashedPassword,
          },
          { onConflict: 'key,user_id' }
        )
        .select()
        .single();

      if (error) {
        console.error('Erreur lors de la définition du mot de passe:', error);
        return handleSupabaseError(error);
      }

      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('Exception lors de la définition du mot de passe:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Vérifier le mot de passe comptable
   */
  async verifyPassword(password: string): Promise<AccountingPasswordResult> {
    try {
      const { data, error } = await supabase
        .from('system_settings')
        .select('value')
        .eq('key', 'accounting_password_hash')
        .single();

      if (error && error.code !== 'PGRST116') {
        console.error('Erreur lors de la vérification du mot de passe:', error);
        return handleSupabaseError(error);
      }

      if (!data?.value) {
        return handleSupabaseSuccess(false);
      }

      const isValid = await bcrypt.compare(password, data.value);
      return handleSupabaseSuccess(isValid);
    } catch (err) {
      console.error('Exception lors de la vérification du mot de passe:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
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

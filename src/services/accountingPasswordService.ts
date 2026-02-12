import { supabase } from '../lib/supabase';
import { handleSupabaseError, handleSupabaseSuccess } from '../lib/supabase';

export interface AccountingPasswordResult {
  success: boolean;
  data?: any;
  error?: string;
}

export const accountingPasswordService = {
  /**
   * Vérifier si un mot de passe comptable existe
   */
  async hasPassword(): Promise<AccountingPasswordResult> {
    try {
      const { data, error } = await supabase.rpc('has_accounting_password');
      
      if (error) {
        console.error('Erreur lors de la vérification du mot de passe:', error);
        return handleSupabaseError(error);
      }
      
      return handleSupabaseSuccess(data);
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
      if (!password || password.length < 6) {
        return {
          success: false,
          error: 'Le mot de passe doit contenir au moins 6 caractères'
        };
      }

      const { data, error } = await supabase.rpc('set_accounting_password', {
        input_password: password
      });
      
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
      if (!password) {
        return {
          success: false,
          error: 'Veuillez saisir un mot de passe'
        };
      }

      const { data, error } = await supabase.rpc('verify_accounting_password', {
        input_password: password
      });
      
      if (error) {
        console.error('Erreur lors de la vérification du mot de passe:', error);
        return handleSupabaseError(error);
      }
      
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('Exception lors de la vérification du mot de passe:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Gérer la session de mot de passe (stockage temporaire)
   */
  setSessionActive(): void {
    sessionStorage.setItem('accounting_password_verified', 'true');
    sessionStorage.setItem('accounting_password_timestamp', Date.now().toString());
  },

  /**
   * Vérifier si la session est active
   */
  isSessionActive(): boolean {
    const verified = sessionStorage.getItem('accounting_password_verified');
    const timestamp = sessionStorage.getItem('accounting_password_timestamp');
    
    if (!verified || !timestamp) {
      return false;
    }
    
    // Session valide pendant 30 minutes
    const sessionAge = Date.now() - parseInt(timestamp);
    const maxAge = 30 * 60 * 1000; // 30 minutes en millisecondes
    
    if (sessionAge > maxAge) {
      this.clearSession();
      return false;
    }
    
    return true;
  },

  /**
   * Effacer la session
   */
  clearSession(): void {
    sessionStorage.removeItem('accounting_password_verified');
    sessionStorage.removeItem('accounting_password_timestamp');
  },

  /**
   * Vérifier l'accès complet (session + mot de passe)
   */
  async checkAccess(): Promise<{ hasAccess: boolean; needsPassword: boolean; error?: string }> {
    try {
      // Vérifier d'abord si la session est active
      if (this.isSessionActive()) {
        return { hasAccess: true, needsPassword: false };
      }

      // Vérifier si un mot de passe existe
      const hasPasswordResult = await this.hasPassword();
      if (!hasPasswordResult.success) {
        return { 
          hasAccess: false, 
          needsPassword: false, 
          error: 'Erreur lors de la vérification du mot de passe' 
        };
      }

      if (!hasPasswordResult.data) {
        return { hasAccess: false, needsPassword: true };
      }

      return { hasAccess: false, needsPassword: true };
    } catch (err) {
      console.error('Erreur lors de la vérification de l\'accès:', err);
      return { 
        hasAccess: false, 
        needsPassword: false, 
        error: 'Erreur lors de la vérification de l\'accès' 
      };
    }
  }
};

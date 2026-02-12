import { supabase } from '../lib/supabase';

export interface InterventionForm {
  id?: string;
  repair_id: string;
  intervention_date: string;
  technician_name: string;
  client_name: string;
  client_phone: string;
  client_email: string;
  device_brand: string;
  device_model: string;
  device_serial_number: string;
  device_type: string;
  device_condition: string;
  visible_damages: string;
  missing_parts: string;
  password_provided: boolean;
  data_backup: boolean;
  reported_issue: string;
  initial_diagnosis: string;
  proposed_solution: string;
  estimated_cost: number;
  estimated_duration: string;
  data_loss_risk: boolean;
  data_loss_risk_details: string;
  cosmetic_changes: boolean;
  cosmetic_changes_details: string;
  warranty_void: boolean;
  warranty_void_details: string;
  client_authorizes_repair: boolean;
  client_authorizes_data_access: boolean;
  client_authorizes_replacement: boolean;
  additional_notes: string;
  special_instructions: string;
  terms_accepted: boolean;
  liability_accepted: boolean;
  signature_token?: string;
  signature_status?: 'pending' | 'sent' | 'signed' | 'expired';
  signature_image?: string;
  signature_signed_at?: string;
  token_expires_at?: string;
  created_at?: string;
  updated_at?: string;
}

export const interventionService = {
  async create(intervention: Omit<InterventionForm, 'id' | 'created_at' | 'updated_at'>) {
    try {
      // Exclure les champs signature (ajoutés séparément via generateSignatureToken)
      const { signature_token, signature_status, signature_image, signature_signed_at, token_expires_at, ...baseFields } = intervention as any;

      const { data, error } = await supabase
        .from('intervention_forms')
        .insert([{
          ...baseFields,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }])
        .select()
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la création du bon d\'intervention:', error);
      return { success: false, error };
    }
  },

  async getByRepairId(repairId: string) {
    // Méthode 1 : Requête directe (fonctionne si RLS autorise SELECT)
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .select('*')
        .eq('repair_id', repairId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!error && data) {
        return { success: true, data };
      }
    } catch (_) {
      // Direct query failed, try RPC
    }

    // Méthode 2 : RPC (bypass RLS)
    try {
      const { data, error } = await supabase.rpc('get_intervention_by_repair_id', {
        p_repair_id: repairId,
      });

      if (error) throw error;
      if (!data) return { success: false, error: 'Aucune intervention trouvée' };
      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la récupération du bon d\'intervention:', error);
      return { success: false, error };
    }
  },

  async update(id: string, updates: Partial<InterventionForm>) {
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la mise à jour du bon d\'intervention:', error);
      return { success: false, error };
    }
  },

  async delete(id: string) {
    try {
      const { error } = await supabase
        .from('intervention_forms')
        .delete()
        .eq('id', id);

      if (error) throw error;
      return { success: true };
    } catch (error) {
      console.error('Erreur lors de la suppression du bon d\'intervention:', error);
      return { success: false, error };
    }
  },

  async getAll() {
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la récupération des bons d\'intervention:', error);
      return { success: false, error };
    }
  },

  async getById(id: string) {
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la récupération du bon d\'intervention:', error);
      return { success: false, error };
    }
  },

  async generateSignatureToken(id: string) {
    try {
      const token = crypto.randomUUID();
      const expiresAt = new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString();

      const { data, error } = await supabase
        .from('intervention_forms')
        .update({
          signature_token: token,
          signature_status: 'sent',
          token_expires_at: expiresAt,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return { success: true, data, token };
    } catch (error) {
      console.error('Erreur lors de la génération du token de signature:', error);
      return { success: false, error };
    }
  },

  /**
   * Crée l'intervention ET génère le token de signature en une seule opération via RPC.
   * Utilise SECURITY DEFINER pour contourner la RLS.
   */
  async createWithToken(interventionData: Record<string, any>): Promise<{ success: boolean; data?: { id: string; token: string; expires_at: string }; error?: any }> {
    try {
      const { data, error } = await supabase.rpc('create_intervention_with_token', {
        p_data: interventionData,
      });

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la création intervention + token:', error);
      return { success: false, error };
    }
  },

  /**
   * Met à jour une intervention (requête directe avec fallback RPC).
   */
  async updateViaRpc(id: string, updates: Record<string, any>) {
    // Méthode 1 : Requête directe (fonctionne si RLS autorise UPDATE)
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .update({
          ...updates,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id)
        .select()
        .single();

      if (!error && data) {
        return { success: true, data };
      }
    } catch (_) {
      // Direct update failed, try RPC
    }

    // Méthode 2 : RPC (bypass RLS)
    try {
      const { data, error } = await supabase.rpc('update_intervention', {
        p_intervention_id: id,
        p_updates: updates,
      });

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la mise à jour intervention via RPC:', error);
      return { success: false, error };
    }
  },

  /**
   * Récupère le statut de signature (requête directe avec fallback RPC).
   */
  async getSignatureStatus(id: string) {
    // Méthode 1 : Requête directe
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .select('id, signature_status, signature_image, signature_signed_at')
        .eq('id', id)
        .single();

      if (!error && data) {
        return { success: true, data };
      }
    } catch (_) {
      // Direct query failed, try RPC
    }

    // Méthode 2 : RPC
    try {
      const { data, error } = await supabase.rpc('get_signature_status', {
        p_intervention_id: id,
      });

      if (error) throw error;
      if (!data) return { success: false, error: 'Intervention introuvable' };
      return { success: true, data };
    } catch (error) {
      // Silently fail for polling - don't spam console
      return { success: false, error };
    }
  },
};

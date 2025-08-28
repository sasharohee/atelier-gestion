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
  created_at?: string;
  updated_at?: string;
}

export const interventionService = {
  async create(intervention: Omit<InterventionForm, 'id' | 'created_at' | 'updated_at'>) {
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .insert([{
          ...intervention,
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
    try {
      const { data, error } = await supabase
        .from('intervention_forms')
        .select('*')
        .eq('repair_id', repairId)
        .single();

      if (error) throw error;
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
  }
};

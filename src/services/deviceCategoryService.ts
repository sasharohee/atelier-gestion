import { supabase } from '../lib/supabase';
import { DeviceCategory } from '../types/deviceManagement';

class DeviceCategoryService {
  // Récupérer toutes les catégories d'appareils
  async getAll(): Promise<{ success: boolean; data?: DeviceCategory[]; error?: string }> {
    try {
      // Récupérer l'utilisateur actuel pour l'isolation
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { data, error } = await supabase
        .from('device_categories')
        .select('*')
        .eq('is_active', true)
        .eq('user_id', user.id)
        .order('name', { ascending: true });

      if (error) {
        console.error('Erreur lors de la récupération des catégories d\'appareils:', error);
        return { success: false, error: error.message };
      }

      // Transformer les données pour correspondre à l'interface DeviceCategory
      const transformedData = (data || []).map(category => ({
        id: category.id,
        name: category.name,
        description: category.description || '',
        icon: category.icon || 'category',
        isActive: category.is_active,
        createdAt: category.created_at,
        updatedAt: category.updated_at
      }));

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la récupération des catégories d\'appareils:', error);
      return { success: false, error: 'Erreur lors de la récupération des catégories d\'appareils' };
    }
  }

  // Récupérer une catégorie par ID
  async getById(id: string): Promise<{ success: boolean; data?: DeviceCategory; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { data, error } = await supabase
        .from('device_categories')
        .select('*')
        .eq('id', id)
        .eq('user_id', user.id)
        .single();

      if (error) {
        console.error('Erreur lors de la récupération de la catégorie:', error);
        return { success: false, error: error.message };
      }

      const transformedData = {
        id: data.id,
        name: data.name,
        description: data.description || '',
        icon: data.icon || 'category',
        isActive: data.is_active,
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la récupération de la catégorie:', error);
      return { success: false, error: 'Erreur lors de la récupération de la catégorie' };
    }
  }

  // Créer une nouvelle catégorie
  async create(categoryData: { name: string; description?: string; icon?: string }): Promise<{ success: boolean; data?: DeviceCategory; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { data, error } = await supabase
        .from('device_categories')
        .insert([{
          name: categoryData.name,
          description: categoryData.description || '',
          icon: categoryData.icon || 'category',
          is_active: true,
          user_id: user.id,
          created_by: user.id
        }])
        .select()
        .single();

      if (error) {
        console.error('Erreur lors de la création de la catégorie:', error);
        return { success: false, error: error.message };
      }

      const transformedData = {
        id: data.id,
        name: data.name,
        description: data.description || '',
        icon: data.icon || 'category',
        isActive: data.is_active,
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la création de la catégorie:', error);
      return { success: false, error: 'Erreur lors de la création de la catégorie' };
    }
  }

  // Mettre à jour une catégorie
  async update(id: string, updates: { name?: string; description?: string; icon?: string }): Promise<{ success: boolean; data?: DeviceCategory; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { data, error } = await supabase
        .from('device_categories')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();

      if (error) {
        console.error('Erreur lors de la mise à jour de la catégorie:', error);
        return { success: false, error: error.message };
      }

      const transformedData = {
        id: data.id,
        name: data.name,
        description: data.description || '',
        icon: data.icon || 'category',
        isActive: data.is_active,
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la mise à jour de la catégorie:', error);
      return { success: false, error: 'Erreur lors de la mise à jour de la catégorie' };
    }
  }

  // Supprimer une catégorie
  async delete(id: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { error } = await supabase
        .from('device_categories')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);

      if (error) {
        console.error('Erreur lors de la suppression de la catégorie:', error);
        return { success: false, error: error.message };
      }

      return { success: true };
    } catch (error) {
      console.error('Erreur lors de la suppression de la catégorie:', error);
      return { success: false, error: 'Erreur lors de la suppression de la catégorie' };
    }
  }
}

export const deviceCategoryService = new DeviceCategoryService();

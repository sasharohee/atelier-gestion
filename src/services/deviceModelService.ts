import { supabase } from '../lib/supabase';
import { DeviceModel } from '../types/deviceManagement';

export interface CreateModelData {
  name: string;
  brandId: string;
  categoryId: string;
  description?: string;
}

export interface UpdateModelData {
  name?: string;
  brandId?: string;
  categoryId?: string;
  description?: string;
}

class DeviceModelService {
  // Récupérer tous les modèles d'appareils
  async getAll(): Promise<{ success: boolean; data?: DeviceModel[]; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { data, error } = await supabase
        .from('device_models')
        .select(`
          *,
          device_brands!device_models_brand_id_fkey (
            id,
            name,
            description
          ),
          device_categories!device_models_category_id_fkey (
            id,
            name,
            description
          )
        `)
        .eq('user_id', user.id)
        .order('name');

      if (error) {
        console.error('Erreur lors de la récupération des modèles d\'appareils:', error);
        return { success: false, error: error.message };
      }

      // Transformer les données pour correspondre à l'interface DeviceModel
      const transformedData = (data || []).map(model => ({
        id: model.id,
        name: model.name,
        model: model.model || '',
        description: model.description || '',
        brandId: model.brand_id,
        categoryId: model.category_id,
        brandName: model.device_brands?.name || 'Marque inconnue',
        categoryName: model.device_categories?.name || 'Catégorie inconnue',
        isActive: model.is_active,
        createdAt: model.created_at,
        updatedAt: model.updated_at
      }));

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la récupération des modèles d\'appareils:', error);
      return { success: false, error: 'Erreur lors de la récupération des modèles d\'appareils' };
    }
  }

  // Récupérer un modèle par ID
  async getById(id: string): Promise<{ success: boolean; data?: DeviceModel; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { data, error } = await supabase
        .from('device_models')
        .select(`
          *,
          device_brands!device_models_brand_id_fkey (
            id,
            name,
            description
          ),
          device_categories!device_models_category_id_fkey (
            id,
            name,
            description
          )
        `)
        .eq('id', id)
        .eq('user_id', user.id)
        .single();

      if (error) {
        console.error('Erreur lors de la récupération du modèle:', error);
        return { success: false, error: error.message };
      }

      const transformedData = {
        id: data.id,
        name: data.name,
        model: data.model || '',
        description: data.description || '',
        brandId: data.brand_id,
        categoryId: data.category_id,
        brandName: data.device_brands?.name || 'Marque inconnue',
        categoryName: data.device_categories?.name || 'Catégorie inconnue',
        isActive: data.is_active,
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la récupération du modèle:', error);
      return { success: false, error: 'Erreur lors de la récupération du modèle' };
    }
  }

  // Créer un nouveau modèle
  async create(modelData: CreateModelData): Promise<{ success: boolean; data?: DeviceModel; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { data, error } = await supabase
        .from('device_models')
        .insert([{
          name: modelData.name,
          model: modelData.name, // Utiliser le nom comme modèle
          description: modelData.description || '',
          brand_id: modelData.brandId,
          category_id: modelData.categoryId,
          is_active: true,
          user_id: user.id,
          created_by: user.id
        }])
        .select()
        .single();

      if (error) {
        console.error('Erreur lors de la création du modèle:', error);
        return { success: false, error: error.message };
      }

      const transformedData = {
        id: data.id,
        name: data.name,
        description: data.description || '',
        brandId: data.brand_id,
        categoryId: data.category_id,
        brandName: 'Marque', // Sera mis à jour lors du prochain getAll
        categoryName: 'Catégorie', // Sera mis à jour lors du prochain getAll
        isActive: data.is_active,
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la création du modèle:', error);
      return { success: false, error: 'Erreur lors de la création du modèle' };
    }
  }

  // Mettre à jour un modèle
  async update(id: string, updates: UpdateModelData): Promise<{ success: boolean; data?: DeviceModel; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      // Mapper les données camelCase vers snake_case
      // Note: Seulement les colonnes qui existent réellement dans la table
      const dbUpdates: any = {
        updated_at: new Date().toISOString()
      };

      if (updates.name !== undefined) {
        dbUpdates.name = updates.name;
        dbUpdates.model = updates.name; // Mettre à jour aussi la colonne model
      }
      if (updates.description !== undefined) dbUpdates.description = updates.description;
      if (updates.brandId !== undefined) dbUpdates.brand_id = updates.brandId;
      if (updates.categoryId !== undefined) dbUpdates.category_id = updates.categoryId;

      const { data, error } = await supabase
        .from('device_models')
        .update(dbUpdates)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();

      if (error) {
        console.error('Erreur lors de la mise à jour du modèle:', error);
        return { success: false, error: error.message };
      }

      const transformedData = {
        id: data.id,
        name: data.name,
        description: data.description || '',
        brandId: data.brand_id,
        categoryId: data.category_id,
        brandName: 'Marque', // Sera mis à jour lors du prochain getAll
        categoryName: 'Catégorie', // Sera mis à jour lors du prochain getAll
        isActive: data.is_active,
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };

      return { success: true, data: transformedData };
    } catch (error) {
      console.error('Erreur lors de la mise à jour du modèle:', error);
      return { success: false, error: 'Erreur lors de la mise à jour du modèle' };
    }
  }

  // Supprimer un modèle
  async delete(id: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const { error } = await supabase
        .from('device_models')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);

      if (error) {
        console.error('Erreur lors de la suppression du modèle:', error);
        return { success: false, error: error.message };
      }

      return { success: true };
    } catch (error) {
      console.error('Erreur lors de la suppression du modèle:', error);
      return { success: false, error: 'Erreur lors de la suppression du modèle' };
    }
  }
}

export const deviceModelService = new DeviceModelService();

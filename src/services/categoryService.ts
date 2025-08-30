import { supabase } from '../lib/supabase';

export interface ProductCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
  color: string;
  is_active: boolean;
  sort_order: number;
  workshop_id: string;
  user_id?: string;
  created_at: string;
  updated_at: string;
}

export interface CreateCategoryData {
  name: string;
  description: string;
  icon: string;
  color?: string;
  is_active?: boolean;
  sort_order?: number;
}

export interface UpdateCategoryData {
  name?: string;
  description?: string;
  icon?: string;
  color?: string;
  is_active?: boolean;
  sort_order?: number;
}

class CategoryService {
  // Récupérer toutes les catégories de l'utilisateur connecté
  async getAll(): Promise<{ success: boolean; data?: ProductCategory[]; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('product_categories')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', { ascending: true });

      if (error) {
        console.error('Erreur lors de la récupération des catégories:', error);
        return { success: false, error: error.message };
      }

      return { success: true, data: data || [] };
    } catch (error) {
      console.error('Erreur lors de la récupération des catégories:', error);
      return { success: false, error: 'Erreur lors de la récupération des catégories' };
    }
  }

  // Récupérer une catégorie par ID
  async getById(id: string): Promise<{ success: boolean; data?: ProductCategory; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('product_categories')
        .select('*')
        .eq('id', id)
        .single();

      if (error) {
        console.error('Erreur lors de la récupération de la catégorie:', error);
        return { success: false, error: error.message };
      }

      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la récupération de la catégorie:', error);
      return { success: false, error: 'Erreur lors de la récupération de la catégorie' };
    }
  }

  // Créer une nouvelle catégorie
  async create(categoryData: CreateCategoryData): Promise<{ success: boolean; data?: ProductCategory; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('product_categories')
        .insert([{
          name: categoryData.name,
          description: categoryData.description,
          icon: categoryData.icon,
          color: categoryData.color || '#1976d2',
          is_active: categoryData.is_active !== undefined ? categoryData.is_active : true,
          sort_order: categoryData.sort_order || 0
          // user_id sera automatiquement assigné par le trigger
        }])
        .select()
        .single();

      if (error) {
        console.error('Erreur lors de la création de la catégorie:', error);
        
        // Gérer spécifiquement l'erreur de contrainte unique
        if (error.code === '23505') {
          if (error.message.includes('product_categories_name_key')) {
            return { success: false, error: 'Une catégorie avec ce nom existe déjà. Veuillez choisir un nom différent.' };
          } else if (error.message.includes('product_categories_name_user_unique')) {
            return { success: false, error: 'Vous avez déjà une catégorie avec ce nom. Veuillez choisir un nom différent.' };
          }
        }
        
        return { success: false, error: error.message };
      }

      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la création de la catégorie:', error);
      return { success: false, error: 'Erreur lors de la création de la catégorie' };
    }
  }

  // Mettre à jour une catégorie
  async update(id: string, updates: UpdateCategoryData): Promise<{ success: boolean; data?: ProductCategory; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('product_categories')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single();

      if (error) {
        console.error('Erreur lors de la mise à jour de la catégorie:', error);
        return { success: false, error: error.message };
      }

      return { success: true, data };
    } catch (error) {
      console.error('Erreur lors de la mise à jour de la catégorie:', error);
      return { success: false, error: 'Erreur lors de la mise à jour de la catégorie' };
    }
  }

  // Supprimer une catégorie
  async delete(id: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('product_categories')
        .delete()
        .eq('id', id);

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

  // Désactiver une catégorie (au lieu de la supprimer)
  async deactivate(id: string): Promise<{ success: boolean; data?: ProductCategory; error?: string }> {
    return this.update(id, { is_active: false });
  }

  // Réactiver une catégorie
  async activate(id: string): Promise<{ success: boolean; data?: ProductCategory; error?: string }> {
    return this.update(id, { is_active: true });
  }

  // Récupérer les catégories par nom (recherche)
  async searchByName(searchTerm: string): Promise<{ success: boolean; data?: ProductCategory[]; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('product_categories')
        .select('*')
        .ilike('name', `%${searchTerm}%`)
        .eq('is_active', true)
        .order('sort_order', { ascending: true });

      if (error) {
        console.error('Erreur lors de la recherche des catégories:', error);
        return { success: false, error: error.message };
      }

      return { success: true, data: data || [] };
    } catch (error) {
      console.error('Erreur lors de la recherche des catégories:', error);
      return { success: false, error: 'Erreur lors de la recherche des catégories' };
    }
  }
}

export const categoryService = new CategoryService();

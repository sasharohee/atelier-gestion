// Service simplifié pour la gestion des marques avec support des IDs hardcodés
import { supabase } from './supabase';

export interface DeviceBrand {
  id: string;
  name: string;
  categoryId: string; // Pour compatibilité avec l'ancien système
  categoryIds?: string[]; // Nouveaux IDs de catégories (many-to-many)
  categories?: DeviceCategory[]; // Données complètes des catégories
  description?: string;
  logo?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface DeviceCategory {
  id: string;
  name: string;
  description?: string;
  icon?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Fonctions utilitaires
function handleSupabaseError(error: any): { success: false; error: string } {
  console.error('Erreur Supabase:', error);
  return { success: false, error: error.message || 'Erreur inconnue' };
}

function handleSupabaseSuccess<T>(data: T): { success: true; data: T } {
  return { success: true, data };
}

// Service pour les marques
export const brandService = {
  async getAll(): Promise<{ success: boolean; data: DeviceBrand[] }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: [] };
    }

    // Utiliser la vue pour récupérer les marques avec leurs catégories
    const { data, error } = await supabase
      .from('brand_with_categories')
      .select('*')
      .eq('user_id', user.id)
      .order('name');
    
    if (error) return handleSupabaseError(error);
    
    const brands = data.map((brand: any) => ({
      id: brand.id,
      name: brand.name,
      categoryId: brand.categories[0]?.id || '', // Pour compatibilité
      categoryIds: brand.categories.map((cat: any) => cat.id), // Tableau d'IDs
      categories: brand.categories, // Données complètes des catégories
      description: brand.description,
      logo: brand.logo,
      isActive: brand.is_active,
      createdAt: new Date(brand.created_at),
      updatedAt: new Date(brand.updated_at),
    }));
    
    return handleSupabaseSuccess(brands);
  },

  async update(id: string, updates: Partial<DeviceBrand>): Promise<{ success: boolean; data: DeviceBrand | null }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: null };
    }

    // Vérifier si l'ID est un UUID valide
    const isValidUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    
    if (!isValidUUID) {
      console.log('⚠️ Modification d\'une marque hardcodée (ID non-UUID):', id);
      
      // Pour les marques hardcodées, on ne peut modifier que le champ category_id
      // Vérifier que seule la catégorie est modifiée
      const allowedUpdates = Object.keys(updates);
      const onlyCategoryUpdate = allowedUpdates.length === 1 && allowedUpdates.includes('categoryId');
      
      if (!onlyCategoryUpdate) {
        console.error('❌ Modification non autorisée pour les marques hardcodées:', allowedUpdates);
        return { 
          success: false, 
          data: null,
          error: `Seules les catégories peuvent être modifiées pour les marques prédéfinies.`
        };
      }
      
      console.log('✅ Modification de catégorie autorisée pour marque hardcodée');
    }

    const updateData: any = {};
    
    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.description !== undefined) updateData.description = updates.description;
    if (updates.logo !== undefined) updateData.logo = updates.logo;
    if (updates.isActive !== undefined) updateData.is_active = updates.isActive;

    // Mettre à jour la marque
    const { data: brandResult, error: brandError } = await supabase
      .from('device_brands')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (brandError) return handleSupabaseError(brandError);
    
    // Mettre à jour les catégories si elles sont spécifiées
    const categoryIds = (updates as any).categoryIds;
    const categoryId = updates.categoryId; // Pour les marques hardcodées
    
    if (categoryIds !== undefined && categoryIds.length > 0) {
      console.log('🔄 Mise à jour des catégories (many-to-many):', categoryIds);
      
      try {
        // Essayer d'abord avec la nouvelle fonction RPC
        const { error: categoryError } = await supabase
          .rpc('update_brand_categories', {
            p_brand_id: id,
            p_category_ids: categoryIds
          });
        
        if (categoryError) {
          console.warn('⚠️ Fonction RPC non disponible, utilisation du fallback:', categoryError);
          
          // Fallback : mettre à jour le champ category_id avec la première catégorie
          const { error: fallbackError } = await supabase
            .from('device_brands')
            .update({ category_id: categoryIds[0] })
            .eq('id', id)
            .eq('user_id', user.id);
          
          if (fallbackError) {
            console.error('❌ Erreur lors de la mise à jour des catégories (fallback):', fallbackError);
          } else {
            console.log('✅ Catégories mises à jour avec le fallback');
          }
        } else {
          console.log('✅ Catégories mises à jour avec la fonction RPC');
        }
      } catch (error) {
        console.error('❌ Erreur lors de la mise à jour des catégories:', error);
      }
    } else if (categoryId !== undefined) {
      console.log('🔄 Mise à jour de la catégorie (single):', categoryId);
      
      // Pour les marques hardcodées, utiliser une approche upsert
      // Essayer d'abord de mettre à jour, si ça échoue, créer
      const { data: updateResult, error: updateError } = await supabase
        .from('device_brands')
        .update({ category_id: categoryId })
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();
      
      if (updateError && updateError.code === 'PGRST116') {
        // La marque n'existe pas, la créer
        console.log('📝 Création de la marque hardcodée en base:', id);
        
        const { data: newBrand, error: createError } = await supabase
          .from('device_brands')
          .insert([{
            id: id, // Utiliser l'ID hardcodé
            name: updates.name || 'Marque inconnue',
            category_id: categoryId,
            description: updates.description || '',
            logo: updates.logo || '',
            is_active: true,
            user_id: user.id,
            created_by: user.id
          }])
          .select()
          .single();
        
        if (createError) {
          console.error('❌ Erreur lors de la création de la marque:', createError);
          throw createError;
        } else {
          console.log('✅ Marque hardcodée créée en base avec succès');
        }
      } else if (updateError) {
        console.error('❌ Erreur lors de la mise à jour de la catégorie:', updateError);
        throw updateError;
      } else {
        console.log('✅ Catégorie mise à jour avec succès');
      }
    }
    
    // Récupérer la marque avec ses catégories
    let fullBrandData: any;
    let fetchError: any;
    
    try {
      // Essayer d'abord avec la vue
      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .eq('id', id)
        .single();
      
      fullBrandData = data;
      fetchError = error;
      
      if (fetchError) {
        console.warn('⚠️ Vue brand_with_categories non disponible, utilisation du fallback:', fetchError);
        throw fetchError;
      }
    } catch (error) {
      console.log('🔄 Utilisation du fallback pour récupérer les données');
      
      // Fallback : récupérer la marque et ses catégories séparément
      const { data: brandData, error: brandFetchError } = await supabase
        .from('device_brands')
        .select('*')
        .eq('id', id)
        .eq('user_id', user.id)
        .single();
      
      if (brandFetchError) {
        console.log('⚠️ Marque non trouvée en base, utilisation des données hardcodées');
        
        // Si la marque n'existe pas en base, utiliser les données hardcodées
        // et créer une structure compatible
        fullBrandData = {
          id: id,
          name: 'Marque hardcodée',
          description: 'Description par défaut',
          logo: '',
          is_active: true,
          user_id: user.id,
          created_by: user.id,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          categories: []
        };
      } else {
        // Récupérer les catégories associées (si la table de liaison existe)
        let categories: any[] = [];
        try {
          const { data: categoryData, error: categoryFetchError } = await supabase
            .from('device_categories')
            .select('*')
            .eq('id', brandData.category_id)
            .eq('user_id', user.id)
            .single();
          
          if (!categoryFetchError && categoryData) {
            categories = [categoryData];
          }
        } catch (e) {
          console.log('ℹ️ Pas de catégories associées trouvées');
        }
        
        fullBrandData = {
          ...brandData,
          categories: categories
        };
      }
    }
    
    const updatedBrand: DeviceBrand = {
      id: fullBrandData.id,
      name: fullBrandData.name,
      categoryId: fullBrandData.categories[0]?.id || '', // Pour compatibilité
      categoryIds: fullBrandData.categories.map((cat: any) => cat.id),
      categories: fullBrandData.categories,
      description: fullBrandData.description,
      logo: fullBrandData.logo,
      isActive: fullBrandData.is_active,
      createdAt: new Date(fullBrandData.created_at),
      updatedAt: new Date(fullBrandData.updated_at),
    };
    
    return handleSupabaseSuccess(updatedBrand);
  },

  async delete(id: string): Promise<{ success: boolean }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false };
    }

    // Vérifier si l'ID est un UUID valide
    const isValidUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    if (!isValidUUID) {
      console.error('❌ ID invalide (non-UUID):', id);
      return { 
        success: false,
        error: `ID invalide: ${id}. Les marques prédéfinies ne peuvent pas être supprimées.`
      };
    }

    const { error } = await supabase
      .from('device_brands')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return { success: true };
  },

  async getByCategory(categoryId: string): Promise<{ success: boolean; data: DeviceBrand[] }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: [] };
    }

    const { data, error } = await supabase
      .from('device_brands')
      .select('*')
      .eq('category_id', categoryId)
      .eq('user_id', user.id)
      .order('name');
    
    if (error) return handleSupabaseError(error);
    
    const brands = data.map((brand: any) => ({
      id: brand.id,
      name: brand.name,
      categoryId: brand.category_id,
      description: brand.description,
      logo: brand.logo,
      isActive: brand.is_active,
      createdAt: new Date(brand.created_at),
      updatedAt: new Date(brand.updated_at),
    }));
    
    return handleSupabaseSuccess(brands);
  }
};

// Service pour les catégories
export const categoryService = {
  async getAll(): Promise<{ success: boolean; data: DeviceCategory[] }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: [] };
    }

    const { data, error } = await supabase
      .from('device_categories')
      .select('*')
      .eq('user_id', user.id)
      .order('name');
    
    if (error) return handleSupabaseError(error);
    
    const categories = data.map((category: any) => ({
      id: category.id,
      name: category.name,
      description: category.description,
      icon: category.icon,
      isActive: category.is_active,
      createdAt: new Date(category.created_at),
      updatedAt: new Date(category.updated_at),
    }));
    
    return handleSupabaseSuccess(categories);
  },

  async create(category: Omit<DeviceCategory, 'id' | 'createdAt' | 'updatedAt'>): Promise<{ success: boolean; data: DeviceCategory | null }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: null };
    }

    const categoryData = {
      name: category.name,
      description: category.description,
      icon: category.icon,
      is_active: category.isActive,
      user_id: user.id,
    };

    const { data, error } = await supabase
      .from('device_categories')
      .insert([categoryData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    const newCategory: DeviceCategory = {
      id: data.id,
      name: data.name,
      description: data.description,
      icon: data.icon,
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at),
    };
    
    return handleSupabaseSuccess(newCategory);
  },

  async update(id: string, updates: Partial<DeviceCategory>): Promise<{ success: boolean; data: DeviceCategory | null }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: null };
    }

    const updateData: any = {};
    
    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.description !== undefined) updateData.description = updates.description;
    if (updates.icon !== undefined) updateData.icon = updates.icon;
    if (updates.isActive !== undefined) updateData.is_active = updates.isActive;

    const { data, error } = await supabase
      .from('device_categories')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    const updatedCategory: DeviceCategory = {
      id: data.id,
      name: data.name,
      description: data.description,
      icon: data.icon,
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at),
    };
    
    return handleSupabaseSuccess(updatedCategory);
  },

  async delete(id: string): Promise<{ success: boolean }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false };
    }

    const { error } = await supabase
      .from('device_categories')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return { success: true };
  }
};

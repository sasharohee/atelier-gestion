import { supabase } from '../lib/supabase';

// Types pour les nouvelles entités
export interface DeviceCategory {
  id: string;
  name: string;
  description?: string;
  icon: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

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

export interface DeviceModel {
  id: string;
  brand: string;
  model: string;
  type: 'smartphone' | 'tablet' | 'laptop' | 'desktop' | 'other';
  year: number;
  specifications: {
    screen?: string;
    processor?: string;
    ram?: string;
    storage?: string;
    battery?: string;
    os?: string;
  };
  commonIssues: string[];
  repairDifficulty: 'easy' | 'medium' | 'hard';
  partsAvailability: 'high' | 'medium' | 'low';
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Fonctions utilitaires
const handleSupabaseError = (error: any) => {
  console.error('Erreur Supabase:', error);
  throw new Error(error.message || 'Une erreur est survenue');
};

const handleSupabaseSuccess = (data: any) => {
  return { success: true, data };
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
    
    const categories = data.map((cat: any) => ({
      id: cat.id,
      name: cat.name,
      description: cat.description,
      icon: cat.icon,
      isActive: cat.is_active,
      createdAt: new Date(cat.created_at),
      updatedAt: new Date(cat.updated_at),
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
  },
};

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

  async create(brand: Omit<DeviceBrand, 'id' | 'createdAt' | 'updatedAt'>): Promise<{ success: boolean; data: DeviceBrand | null }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: null };
    }

    const brandData = {
      name: brand.name,
      description: brand.description,
      logo: brand.logo,
      is_active: brand.isActive,
      user_id: user.id,
    };

    // Créer la marque
    const { data: brandResult, error: brandError } = await supabase
      .from('device_brands')
      .insert([brandData])
      .select()
      .single();
    
    if (brandError) return handleSupabaseError(brandError);
    
    // Ajouter les catégories si elles sont spécifiées
    const categoryIds = (brand as any).categoryIds || (brand.categoryId ? [brand.categoryId] : []);
    
    if (categoryIds.length > 0) {
      const { error: categoryError } = await supabase
        .rpc('update_brand_categories', {
          p_brand_id: brandResult.id,
          p_category_ids: categoryIds
        });
      
      if (categoryError) {
        console.error('Erreur lors de l\'ajout des catégories:', categoryError);
        // Ne pas faire échouer la création de la marque si les catégories échouent
      }
    }
    
    // Récupérer la marque avec ses catégories
    const { data: fullBrandData, error: fetchError } = await supabase
      .from('brand_with_categories')
      .select('*')
      .eq('id', brandResult.id)
      .single();
    
    if (fetchError) return handleSupabaseError(fetchError);
    
    const newBrand: DeviceBrand = {
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
    
    return handleSupabaseSuccess(newBrand);
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
  },
};

// Service pour les modèles
export const modelService = {
  async getAll(): Promise<{ success: boolean; data: DeviceModel[] }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: [] };
    }

    const { data, error } = await supabase
      .from('device_models')
      .select(`
        *,
        device_brands!inner(name),
        device_categories!inner(name)
      `)
      .eq('user_id', user.id)
      .order('name');
    
    if (error) return handleSupabaseError(error);
    
    const models = data.map((model: any) => ({
      id: model.id,
      brand: model.brand,
      model: model.model,
      type: model.type,
      year: model.year,
      specifications: model.specifications || {},
      commonIssues: model.common_issues || [],
      repairDifficulty: model.repair_difficulty,
      partsAvailability: model.parts_availability,
      isActive: model.is_active,
      createdAt: new Date(model.created_at),
      updatedAt: new Date(model.updated_at),
    }));
    
    return handleSupabaseSuccess(models);
  },

  async create(model: Omit<DeviceModel, 'id' | 'createdAt' | 'updatedAt'>): Promise<{ success: boolean; data: DeviceModel | null }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: null };
    }

    const modelData = {
      brand: model.brand,
      model: model.model,
      type: model.type,
      year: model.year,
      specifications: model.specifications,
      common_issues: model.commonIssues,
      repair_difficulty: model.repairDifficulty,
      parts_availability: model.partsAvailability,
      is_active: model.isActive,
      user_id: user.id,
    };

    const { data, error } = await supabase
      .from('device_models')
      .insert([modelData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    const newModel: DeviceModel = {
      id: data.id,
      brand: data.brand,
      model: data.model,
      type: data.type,
      year: data.year,
      specifications: data.specifications || {},
      commonIssues: data.common_issues || [],
      repairDifficulty: data.repair_difficulty,
      partsAvailability: data.parts_availability,
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at),
    };
    
    return handleSupabaseSuccess(newModel);
  },

  async update(id: string, updates: Partial<DeviceModel>): Promise<{ success: boolean; data: DeviceModel | null }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: null };
    }

    const updateData: any = {};
    
    if (updates.brand !== undefined) updateData.brand = updates.brand;
    if (updates.model !== undefined) updateData.model = updates.model;
    if (updates.type !== undefined) updateData.type = updates.type;
    if (updates.year !== undefined) updateData.year = updates.year;
    if (updates.specifications !== undefined) updateData.specifications = updates.specifications;
    if (updates.commonIssues !== undefined) updateData.common_issues = updates.commonIssues;
    if (updates.repairDifficulty !== undefined) updateData.repair_difficulty = updates.repairDifficulty;
    if (updates.partsAvailability !== undefined) updateData.parts_availability = updates.partsAvailability;
    if (updates.isActive !== undefined) updateData.is_active = updates.isActive;

    const { data, error } = await supabase
      .from('device_models')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    const updatedModel: DeviceModel = {
      id: data.id,
      brand: data.brand,
      model: data.model,
      type: data.type,
      year: data.year,
      specifications: data.specifications || {},
      commonIssues: data.common_issues || [],
      repairDifficulty: data.repair_difficulty,
      partsAvailability: data.parts_availability,
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at),
    };
    
    return handleSupabaseSuccess(updatedModel);
  },

  async delete(id: string): Promise<{ success: boolean }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false };
    }

    const { error } = await supabase
      .from('device_models')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return { success: true };
  },

  async getByBrand(brandId: string): Promise<{ success: boolean; data: DeviceModel[] }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: [] };
    }

    const { data, error } = await supabase
      .from('device_models')
      .select('*')
      .eq('brand_id', brandId)
      .eq('user_id', user.id)
      .order('name');
    
    if (error) return handleSupabaseError(error);
    
    const models = data.map((model: any) => ({
      id: model.id,
      name: model.name,
      brandId: model.brand_id,
      categoryId: model.category_id,
      year: model.year,
      commonIssues: model.common_issues || [],
      repairDifficulty: model.repair_difficulty,
      partsAvailability: model.parts_availability,
      isActive: model.is_active,
      createdAt: new Date(model.created_at),
      updatedAt: new Date(model.updated_at),
    }));
    
    return handleSupabaseSuccess(models);
  },

  async getByCategory(categoryId: string): Promise<{ success: boolean; data: DeviceModel[] }> {
    // Récupérer l'utilisateur actuel pour l'isolation
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return { success: false, data: [] };
    }

    const { data, error } = await supabase
      .from('device_models')
      .select('*')
      .eq('category_id', categoryId)
      .eq('user_id', user.id)
      .order('name');
    
    if (error) return handleSupabaseError(error);
    
    const models = data.map((model: any) => ({
      id: model.id,
      name: model.name,
      brandId: model.brand_id,
      categoryId: model.category_id,
      year: model.year,
      commonIssues: model.common_issues || [],
      repairDifficulty: model.repair_difficulty,
      partsAvailability: model.parts_availability,
      isActive: model.is_active,
      createdAt: new Date(model.created_at),
      updatedAt: new Date(model.updated_at),
    }));
    
    return handleSupabaseSuccess(models);
  },
};

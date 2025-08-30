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
  categoryId: string;
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
    const { data, error } = await supabase
      .from('device_categories')
      .select('*')
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

  async create(category: Omit<DeviceCategory, 'id' | 'createdAt' | 'updatedAt'>): Promise<{ success: boolean; data: DeviceCategory }> {
    const categoryData = {
      name: category.name,
      description: category.description,
      icon: category.icon,
      is_active: category.isActive,
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

  async update(id: string, updates: Partial<DeviceCategory>): Promise<{ success: boolean; data: DeviceCategory }> {
    const updateData: any = {};
    
    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.description !== undefined) updateData.description = updates.description;
    if (updates.icon !== undefined) updateData.icon = updates.icon;
    if (updates.isActive !== undefined) updateData.is_active = updates.isActive;

    const { data, error } = await supabase
      .from('device_categories')
      .update(updateData)
      .eq('id', id)
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
    const { error } = await supabase
      .from('device_categories')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return { success: true };
  },
};

// Service pour les marques
export const brandService = {
  async getAll(): Promise<{ success: boolean; data: DeviceBrand[] }> {
    const { data, error } = await supabase
      .from('device_brands')
      .select(`
        *,
        device_categories!inner(name)
      `)
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

  async create(brand: Omit<DeviceBrand, 'id' | 'createdAt' | 'updatedAt'>): Promise<{ success: boolean; data: DeviceBrand }> {
    const brandData = {
      name: brand.name,
      category_id: brand.categoryId,
      description: brand.description,
      logo: brand.logo,
      is_active: brand.isActive,
    };

    const { data, error } = await supabase
      .from('device_brands')
      .insert([brandData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    const newBrand: DeviceBrand = {
      id: data.id,
      name: data.name,
      categoryId: data.category_id,
      description: data.description,
      logo: data.logo,
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at),
    };
    
    return handleSupabaseSuccess(newBrand);
  },

  async update(id: string, updates: Partial<DeviceBrand>): Promise<{ success: boolean; data: DeviceBrand }> {
    const updateData: any = {};
    
    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.categoryId !== undefined) updateData.category_id = updates.categoryId;
    if (updates.description !== undefined) updateData.description = updates.description;
    if (updates.logo !== undefined) updateData.logo = updates.logo;
    if (updates.isActive !== undefined) updateData.is_active = updates.isActive;

    const { data, error } = await supabase
      .from('device_brands')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    const updatedBrand: DeviceBrand = {
      id: data.id,
      name: data.name,
      categoryId: data.category_id,
      description: data.description,
      logo: data.logo,
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at),
    };
    
    return handleSupabaseSuccess(updatedBrand);
  },

  async delete(id: string): Promise<{ success: boolean }> {
    const { error } = await supabase
      .from('device_brands')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return { success: true };
  },

  async getByCategory(categoryId: string): Promise<{ success: boolean; data: DeviceBrand[] }> {
    const { data, error } = await supabase
      .from('device_brands')
      .select('*')
      .eq('category_id', categoryId)
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
    const { data, error } = await supabase
      .from('device_models')
      .select(`
        *,
        device_brands!inner(name),
        device_categories!inner(name)
      `)
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

  async create(model: Omit<DeviceModel, 'id' | 'createdAt' | 'updatedAt'>): Promise<{ success: boolean; data: DeviceModel }> {
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

  async update(id: string, updates: Partial<DeviceModel>): Promise<{ success: boolean; data: DeviceModel }> {
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
    const { error } = await supabase
      .from('device_models')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return { success: true };
  },

  async getByBrand(brandId: string): Promise<{ success: boolean; data: DeviceModel[] }> {
    const { data, error } = await supabase
      .from('device_models')
      .select('*')
      .eq('brand_id', brandId)
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
    const { data, error } = await supabase
      .from('device_models')
      .select('*')
      .eq('category_id', categoryId)
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

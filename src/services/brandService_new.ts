import { supabase } from '../supabase';
import { DeviceBrand, DeviceCategory } from '../types';

export interface BrandWithCategories extends DeviceBrand {
  categories: DeviceCategory[];
}

export interface CreateBrandData {
  name: string;
  description?: string;
  logo?: string;
  categoryIds?: string[];
}

export interface UpdateBrandData {
  name?: string;
  description?: string;
  logo?: string;
  categoryIds?: string[];
}

class BrandService {
  // Récupérer toutes les marques avec leurs catégories
  async getAll(): Promise<BrandWithCategories[]> {
    try {
      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .order('name');

      if (error) throw error;

      return data.map(brand => ({
        id: brand.id,
        name: brand.name,
        description: brand.description || '',
        logo: brand.logo || '',
        isActive: brand.is_active,
        categories: brand.categories || [],
        createdAt: brand.created_at,
        updatedAt: brand.updated_at
      }));
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des marques:', error);
      throw error;
    }
  }

  // Récupérer une marque par son ID
  async getById(id: string): Promise<BrandWithCategories | null> {
    try {
      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .eq('id', id)
        .single();

      if (error) {
        if (error.code === 'PGRST116') return null;
        throw error;
      }

      return {
        id: data.id,
        name: data.name,
        description: data.description || '',
        logo: data.logo || '',
        isActive: data.is_active,
        categories: data.categories || [],
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };
    } catch (error) {
      console.error('❌ Erreur lors de la récupération de la marque:', error);
      throw error;
    }
  }

  // Créer une nouvelle marque
  async create(brandData: CreateBrandData): Promise<BrandWithCategories> {
    try {
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Utilisateur non authentifié');

      // Générer un ID unique pour la nouvelle marque
      const brandId = `brand_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      // Utiliser la fonction RPC upsert_brand
      const { data, error } = await supabase.rpc('upsert_brand', {
        p_id: brandId,
        p_name: brandData.name,
        p_description: brandData.description || '',
        p_logo: brandData.logo || '',
        p_category_ids: brandData.categoryIds || null
      });

      if (error) throw error;

      return {
        id: data.id,
        name: data.name,
        description: data.description || '',
        logo: data.logo || '',
        isActive: data.is_active,
        categories: data.categories || [],
        createdAt: new Date(),
        updatedAt: new Date()
      };
    } catch (error) {
      console.error('❌ Erreur lors de la création de la marque:', error);
      throw error;
    }
  }

  // Mettre à jour une marque existante
  async update(id: string, updates: UpdateBrandData): Promise<BrandWithCategories> {
    try {
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Utilisateur non authentifié');

      // Utiliser la fonction RPC upsert_brand pour la mise à jour
      const { data, error } = await supabase.rpc('upsert_brand', {
        p_id: id,
        p_name: updates.name,
        p_description: updates.description,
        p_logo: updates.logo,
        p_category_ids: updates.categoryIds || null
      });

      if (error) throw error;

      return {
        id: data.id,
        name: data.name,
        description: data.description || '',
        logo: data.logo || '',
        isActive: data.is_active,
        categories: data.categories || [],
        createdAt: new Date(),
        updatedAt: new Date()
      };
    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour de la marque:', error);
      throw error;
    }
  }

  // Mettre à jour uniquement les catégories d'une marque
  async updateCategories(id: string, categoryIds: string[]): Promise<BrandWithCategories> {
    try {
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Utilisateur non authentifié');

      // Utiliser la fonction RPC update_brand_categories
      const { data, error } = await supabase.rpc('update_brand_categories', {
        p_brand_id: id,
        p_category_ids: categoryIds
      });

      if (error) throw error;

      return {
        id: data.id,
        name: data.name,
        description: data.description || '',
        logo: data.logo || '',
        isActive: data.is_active,
        categories: data.categories || [],
        createdAt: new Date(),
        updatedAt: new Date()
      };
    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour des catégories:', error);
      throw error;
    }
  }

  // Supprimer une marque
  async delete(id: string): Promise<void> {
    try {
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Utilisateur non authentifié');

      const { error } = await supabase
        .from('device_brands')
        .delete()
        .eq('id', id);

      if (error) throw error;

      console.log('✅ Marque supprimée avec succès');
    } catch (error) {
      console.error('❌ Erreur lors de la suppression de la marque:', error);
      throw error;
    }
  }

  // Activer/Désactiver une marque
  async toggleActive(id: string): Promise<BrandWithCategories> {
    try {
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Utilisateur non authentifié');

      // Récupérer l'état actuel
      const currentBrand = await this.getById(id);
      if (!currentBrand) throw new Error('Marque non trouvée');

      const newActiveState = !currentBrand.isActive;

      const { error } = await supabase
        .from('device_brands')
        .update({ is_active: newActiveState })
        .eq('id', id);

      if (error) throw error;

      // Retourner la marque mise à jour
      return await this.getById(id);
    } catch (error) {
      console.error('❌ Erreur lors du changement d\'état de la marque:', error);
      throw error;
    }
  }

  // Rechercher des marques par nom
  async search(query: string): Promise<BrandWithCategories[]> {
    try {
      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .ilike('name', `%${query}%`)
        .order('name');

      if (error) throw error;

      return data.map(brand => ({
        id: brand.id,
        name: brand.name,
        description: brand.description || '',
        logo: brand.logo || '',
        isActive: brand.is_active,
        categories: brand.categories || [],
        createdAt: brand.created_at,
        updatedAt: brand.updated_at
      }));
    } catch (error) {
      console.error('❌ Erreur lors de la recherche de marques:', error);
      throw error;
    }
  }

  // Vérifier si une marque existe
  async exists(id: string): Promise<boolean> {
    try {
      const brand = await this.getById(id);
      return brand !== null;
    } catch (error) {
      console.error('❌ Erreur lors de la vérification de l\'existence de la marque:', error);
      return false;
    }
  }

  // Récupérer les marques par catégorie
  async getByCategory(categoryId: string): Promise<BrandWithCategories[]> {
    try {
      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .contains('categories', [{ id: categoryId }])
        .order('name');

      if (error) throw error;

      return data.map(brand => ({
        id: brand.id,
        name: brand.name,
        description: brand.description || '',
        logo: brand.logo || '',
        isActive: brand.is_active,
        categories: brand.categories || [],
        createdAt: brand.created_at,
        updatedAt: brand.updated_at
      }));
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des marques par catégorie:', error);
      throw error;
    }
  }
}

export const brandService = new BrandService();

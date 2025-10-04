import { supabase } from '../lib/supabase';
import { DeviceBrand, DeviceCategory } from '../types/deviceManagement';

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
      // Récupérer l'utilisateur connecté pour l'isolation des données
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) {
        console.error('❌ Utilisateur non authentifié');
        return [];
      }

      // Essayer d'abord la vue brand_with_categories avec filtrage par utilisateur
      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .eq('user_id', user.id)
        .order('name');

      if (error) {
        console.warn('⚠️ Vue brand_with_categories non disponible, utilisation du fallback:', error.message);
        // Fallback vers la table device_brands directement
        return this.getAllFallback();
      }

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
      // Fallback en cas d'erreur
      return this.getAllFallback();
    }
  }

  // Fallback pour récupérer les marques sans la vue
  private async getAllFallback(): Promise<BrandWithCategories[]> {
    try {
      // Récupérer l'utilisateur connecté pour l'isolation des données
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) {
        console.error('❌ Utilisateur non authentifié');
        return [];
      }

      const { data: brands, error: brandsError } = await supabase
        .from('device_brands')
        .select('*')
        .eq('user_id', user.id)
        .order('name');

      if (brandsError) throw brandsError;

      // Pour chaque marque, récupérer ses catégories
      const brandsWithCategories = await Promise.all(
        (brands || []).map(async (brand) => {
          const { data: brandCategories } = await supabase
            .from('brand_categories')
            .select(`
              device_categories (
                id,
                name,
                description,
                icon,
                is_active,
                created_at,
                updated_at
              )
            `)
            .eq('brand_id', brand.id);

          const categories = (brandCategories || []).map(bc => ({
            id: bc.device_categories.id,
            name: bc.device_categories.name,
            description: bc.device_categories.description || '',
            icon: bc.device_categories.icon || 'category',
            isActive: bc.device_categories.is_active,
            createdAt: bc.device_categories.created_at,
            updatedAt: bc.device_categories.updated_at
          }));

          return {
            id: brand.id,
            name: brand.name,
            description: brand.description || '',
            logo: brand.logo || '',
            isActive: brand.is_active,
            categories,
            createdAt: brand.created_at,
            updatedAt: brand.updated_at
          };
        })
      );

      return brandsWithCategories;
    } catch (error) {
      console.error('❌ Erreur lors du fallback des marques:', error);
      return [];
    }
  }

  // Récupérer une marque par son ID
  async getById(id: string): Promise<BrandWithCategories | null> {
    try {
      // Récupérer l'utilisateur connecté pour l'isolation des données
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) {
        console.error('❌ Utilisateur non authentifié');
        return null;
      }

      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .eq('id', id)
        .eq('user_id', user.id)
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
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) throw new Error('Utilisateur non authentifié');

      // Générer un ID unique pour la nouvelle marque
      const brandId = `brand_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      // Créer la marque directement avec une requête SQL
      const { data: brandData_result, error: brandError } = await supabase
        .from('device_brands')
        .insert([{
          id: brandId,
          name: brandData.name,
          description: brandData.description || '',
          logo: brandData.logo || '',
          is_active: true,
          user_id: user.id,
          created_by: user.id
        }])
        .select()
        .single();

      if (brandError) throw brandError;

      // Associer les catégories si fournies
      if (brandData.categoryIds && brandData.categoryIds.length > 0) {
        const categoryInserts = brandData.categoryIds.map(categoryId => ({
          brand_id: brandId,
          category_id: categoryId,
          user_id: user.id
        }));

        const { error: categoryError } = await supabase
          .from('brand_categories')
          .insert(categoryInserts);

        if (categoryError) {
          console.warn('⚠️ Erreur lors de l\'association des catégories:', categoryError);
          // Ne pas faire échouer la création de la marque pour une erreur de catégorie
        }
      }

      // Récupérer la marque avec ses catégories
      const { data: brandWithCategories, error: fetchError } = await supabase
        .from('device_brands')
        .select(`
          *,
          brand_categories (
            device_categories (
              id,
              name,
              description,
              icon,
              is_active,
              created_at,
              updated_at
            )
          )
        `)
        .eq('id', brandId)
        .eq('user_id', user.id)
        .single();

      if (fetchError) {
        console.warn('⚠️ Erreur lors de la récupération des catégories:', fetchError);
        // Retourner la marque sans catégories en cas d'erreur
        return {
          id: brandData_result.id,
          name: brandData_result.name,
          description: brandData_result.description || '',
          logo: brandData_result.logo || '',
          isActive: brandData_result.is_active,
          categories: [],
          createdAt: new Date(brandData_result.created_at),
          updatedAt: new Date(brandData_result.updated_at)
        };
      }

      // Transformer les catégories
      const categories = (brandWithCategories.brand_categories || []).map(bc => ({
        id: bc.device_categories.id,
        name: bc.device_categories.name,
        description: bc.device_categories.description || '',
        icon: bc.device_categories.icon || 'category',
        isActive: bc.device_categories.is_active,
        createdAt: bc.device_categories.created_at,
        updatedAt: bc.device_categories.updated_at
      }));

      return {
        id: brandWithCategories.id,
        name: brandWithCategories.name,
        description: brandWithCategories.description || '',
        logo: brandWithCategories.logo || '',
        isActive: brandWithCategories.is_active,
        categories,
        createdAt: new Date(brandWithCategories.created_at),
        updatedAt: new Date(brandWithCategories.updated_at)
      };
    } catch (error) {
      console.error('❌ Erreur lors de la création de la marque:', error);
      throw error;
    }
  }

  // Mettre à jour une marque existante
  async update(id: string, updates: UpdateBrandData): Promise<BrandWithCategories> {
    try {
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) throw new Error('Utilisateur non authentifié');

      // Mettre à jour la marque directement
      const updateData: any = {
        updated_at: new Date().toISOString()
      };

      if (updates.name !== undefined) updateData.name = updates.name;
      if (updates.description !== undefined) updateData.description = updates.description;
      if (updates.logo !== undefined) updateData.logo = updates.logo;

      const { data: brandData_result, error: brandError } = await supabase
        .from('device_brands')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();

      if (brandError) throw brandError;

      // Mettre à jour les catégories si fournies
      if (updates.categoryIds !== undefined) {
        // Supprimer les anciennes associations
        const { error: deleteError } = await supabase
          .from('brand_categories')
          .delete()
          .eq('brand_id', id)
          .eq('user_id', user.id);

        if (deleteError) {
          console.warn('⚠️ Erreur lors de la suppression des anciennes catégories:', deleteError);
        }

        // Ajouter les nouvelles associations
        if (updates.categoryIds.length > 0) {
          const categoryInserts = updates.categoryIds.map(categoryId => ({
            brand_id: id,
            category_id: categoryId,
            user_id: user.id
          }));

          const { error: categoryError } = await supabase
            .from('brand_categories')
            .insert(categoryInserts);

          if (categoryError) {
            console.warn('⚠️ Erreur lors de l\'association des catégories:', categoryError);
          }
        }
      }

      // Récupérer la marque avec ses catégories
      const { data: brandWithCategories, error: fetchError } = await supabase
        .from('device_brands')
        .select(`
          *,
          brand_categories (
            device_categories (
              id,
              name,
              description,
              icon,
              is_active,
              created_at,
              updated_at
            )
          )
        `)
        .eq('id', id)
        .eq('user_id', user.id)
        .single();

      if (fetchError) {
        console.warn('⚠️ Erreur lors de la récupération des catégories:', fetchError);
        // Retourner la marque sans catégories en cas d'erreur
        return {
          id: brandData_result.id,
          name: brandData_result.name,
          description: brandData_result.description || '',
          logo: brandData_result.logo || '',
          isActive: brandData_result.is_active,
          categories: [],
          createdAt: new Date(brandData_result.created_at),
          updatedAt: new Date(brandData_result.updated_at)
        };
      }

      // Transformer les catégories
      const categories = (brandWithCategories.brand_categories || []).map(bc => ({
        id: bc.device_categories.id,
        name: bc.device_categories.name,
        description: bc.device_categories.description || '',
        icon: bc.device_categories.icon || 'category',
        isActive: bc.device_categories.is_active,
        createdAt: bc.device_categories.created_at,
        updatedAt: bc.device_categories.updated_at
      }));

      return {
        id: brandWithCategories.id,
        name: brandWithCategories.name,
        description: brandWithCategories.description || '',
        logo: brandWithCategories.logo || '',
        isActive: brandWithCategories.is_active,
        categories,
        createdAt: new Date(brandWithCategories.created_at),
        updatedAt: new Date(brandWithCategories.updated_at)
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
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) throw new Error('Utilisateur non authentifié');

      const { error } = await supabase
        .from('device_brands')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);

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
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) throw new Error('Utilisateur non authentifié');

      // Récupérer l'état actuel
      const currentBrand = await this.getById(id);
      if (!currentBrand) throw new Error('Marque non trouvée');

      const newActiveState = !currentBrand.isActive;

      const { error } = await supabase
        .from('device_brands')
        .update({ is_active: newActiveState })
        .eq('id', id)
        .eq('user_id', user.id);

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
      // Récupérer l'utilisateur connecté pour l'isolation des données
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) {
        console.error('❌ Utilisateur non authentifié');
        return [];
      }

      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .eq('user_id', user.id)
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
      // Récupérer l'utilisateur connecté pour l'isolation des données
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError || !user) {
        console.error('❌ Utilisateur non authentifié');
        return [];
      }

      const { data, error } = await supabase
        .from('brand_with_categories')
        .select('*')
        .eq('user_id', user.id)
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

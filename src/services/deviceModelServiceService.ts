// Service pour gérer les associations entre modèles d'appareils et services
// Permet de définir des services spécifiques avec prix et durée personnalisés

import { supabase } from '../lib/supabase';
import { 
  DeviceModelService, 
  DeviceModelServiceDetailed,
  CreateDeviceModelServiceData, 
  UpdateDeviceModelServiceData,
  DeviceModelServiceFilters,
  ModelServicesResult,
  BrandCategoryServicesResult,
  DeviceModelServiceDisplay,
  DeviceModelServiceStats,
  DeviceModelServiceImportData,
  DeviceModelServiceImportResult
} from '../types/deviceModelService';

export interface ServiceResult<T> {
  success: boolean;
  data?: T;
  error?: string;
}

class DeviceModelServiceService {
  private tableName = 'device_model_services';
  private detailedViewName = 'device_model_services_detailed';

  /**
   * Créer une nouvelle association modèle-service
   */
  async create(data: CreateDeviceModelServiceData): Promise<ServiceResult<DeviceModelService>> {
    try {
      console.log('🔄 Création d\'une association modèle-service:', data);

      // Récupérer les informations du modèle pour obtenir brand_id et category_id
      const { data: modelData, error: modelError } = await supabase
        .from('device_models')
        .select('brand_id, category_id')
        .eq('id', data.deviceModelId)
        .single();

      if (modelError || !modelData) {
        throw new Error(`Modèle non trouvé: ${modelError?.message || 'Modèle introuvable'}`);
      }

      // Vérifier que l'association n'existe pas déjà
      const { data: existingData, error: checkError } = await supabase
        .from(this.tableName)
        .select('id')
        .eq('device_model_id', data.deviceModelId)
        .eq('service_id', data.serviceId);

      if (checkError) {
        console.warn('⚠️ Erreur lors de la vérification d\'existence:', checkError.message);
      }

      if (existingData && existingData.length > 0) {
        throw new Error('Cette association existe déjà');
      }

      // Récupérer l'utilisateur authentifié
      const { data: authData, error: authError } = await supabase.auth.getUser();
      if (authError || !authData?.user) {
        throw new Error('Utilisateur non authentifié');
      }

      // Pour l'instant, on va utiliser l'ID de l'utilisateur comme workshop_id
      // Cela permet de contourner le problème de configuration
      const workshopId = authData.user.id;
      console.log('🔧 Utilisation de l\'ID utilisateur comme workshop_id:', workshopId);

      // Créer l'association
      const { data: result, error } = await supabase
        .from(this.tableName)
        .insert({
          device_model_id: data.deviceModelId,
          service_id: data.serviceId,
          brand_id: modelData.brand_id,
          category_id: modelData.category_id,
          custom_price: data.customPrice,
          custom_duration: data.customDuration,
          user_id: authData.user.id,
        })
        .select()
        .single();

      if (error) {
        throw new Error(`Erreur lors de la création: ${error.message}`);
      }

      console.log('✅ Association créée avec succès:', result);
      return { success: true, data: result };
    } catch (error: any) {
      console.error('❌ Erreur lors de la création de l\'association:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Obtenir toutes les associations avec détails
   */
  async getAll(): Promise<ServiceResult<DeviceModelServiceDetailed[]>> {
    try {
      console.log('🔄 Récupération de toutes les associations modèle-service');

      // Récupérer l'utilisateur authentifié pour l'isolation
      const { data: authData, error: authError } = await supabase.auth.getUser();
      if (authError || !authData?.user) {
        throw new Error('Utilisateur non authentifié');
      }

      const { data, error } = await supabase
        .from(this.detailedViewName)
        .select('*')
        .order('model_name, service_name');

      if (error) {
        throw new Error(`Erreur lors de la récupération: ${error.message}`);
      }

      console.log(`✅ ${data?.length || 0} associations récupérées`);
      console.log('🔍 Données brutes de la vue:', data);
      if (data && data.length > 0) {
        console.log('🔍 Premier élément brut:', data[0]);
        console.log('🔍 Colonnes disponibles:', Object.keys(data[0]));
      }
      return { success: true, data: data || [] };
    } catch (error: any) {
      console.error('❌ Erreur lors de la récupération des associations:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Obtenir les services pour un modèle spécifique
   */
  async getByModelId(modelId: string): Promise<ServiceResult<ModelServicesResult[]>> {
    try {
      console.log('🔄 Récupération des services pour le modèle:', modelId);

      const { data, error } = await supabase
        .rpc('get_services_for_model', { p_model_id: modelId });

      if (error) {
        throw new Error(`Erreur lors de la récupération: ${error.message}`);
      }

      console.log(`✅ ${data?.length || 0} services trouvés pour le modèle`);
      return { success: true, data: data || [] };
    } catch (error: any) {
      console.error('❌ Erreur lors de la récupération des services du modèle:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Obtenir les services par marque et catégorie
   */
  async getByBrandAndCategory(brandId: string, categoryId: string): Promise<ServiceResult<BrandCategoryServicesResult[]>> {
    try {
      console.log('🔄 Récupération des services par marque et catégorie:', { brandId, categoryId });

      const { data, error } = await supabase
        .rpc('get_services_for_brand_category', { 
          p_brand_id: brandId, 
          p_category_id: categoryId 
        });

      if (error) {
        throw new Error(`Erreur lors de la récupération: ${error.message}`);
      }

      console.log(`✅ ${data?.length || 0} services trouvés pour cette marque/catégorie`);
      return { success: true, data: data || [] };
    } catch (error: any) {
      console.error('❌ Erreur lors de la récupération des services par marque/catégorie:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Obtenir une association par ID
   */
  async getById(id: string): Promise<ServiceResult<DeviceModelServiceDetailed>> {
    try {
      console.log('🔄 Récupération de l\'association:', id);

      const { data, error } = await supabase
        .from(this.detailedViewName)
        .select('*')
        .eq('id', id)
        .single();

      if (error) {
        throw new Error(`Erreur lors de la récupération: ${error.message}`);
      }

      if (!data) {
        throw new Error('Association non trouvée');
      }

      console.log('✅ Association récupérée:', data);
      return { success: true, data };
    } catch (error: any) {
      console.error('❌ Erreur lors de la récupération de l\'association:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Mettre à jour une association
   */
  async update(id: string, data: UpdateDeviceModelServiceData): Promise<ServiceResult<DeviceModelService>> {
    try {
      console.log('🔄 Mise à jour de l\'association:', id, data);

      const { data: result, error } = await supabase
        .from(this.tableName)
        .update({
          custom_price: data.customPrice,
          custom_duration: data.customDuration,
          is_active: data.isActive,
        })
        .eq('id', id)
        .select()
        .single();

      if (error) {
        throw new Error(`Erreur lors de la mise à jour: ${error.message}`);
      }

      console.log('✅ Association mise à jour:', result);
      return { success: true, data: result };
    } catch (error: any) {
      console.error('❌ Erreur lors de la mise à jour de l\'association:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Supprimer une association
   */
  async delete(id: string): Promise<ServiceResult<void>> {
    try {
      console.log('🔄 Suppression de l\'association:', id);

      const { error } = await supabase
        .from(this.tableName)
        .delete()
        .eq('id', id);

      if (error) {
        throw new Error(`Erreur lors de la suppression: ${error.message}`);
      }

      console.log('✅ Association supprimée');
      return { success: true };
    } catch (error: any) {
      console.error('❌ Erreur lors de la suppression de l\'association:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Filtrer les associations selon des critères
   */
  async getFiltered(filters: DeviceModelServiceFilters): Promise<ServiceResult<DeviceModelServiceDetailed[]>> {
    try {
      console.log('🔄 Filtrage des associations:', filters);

      // Récupérer l'utilisateur authentifié pour l'isolation
      const { data: authData, error: authError } = await supabase.auth.getUser();
      if (authError || !authData?.user) {
        throw new Error('Utilisateur non authentifié');
      }

      let query = supabase
        .from(this.detailedViewName)
        .select('*');

      if (filters.deviceModelId) {
        query = query.eq('device_model_id', filters.deviceModelId);
      }
      if (filters.serviceId) {
        query = query.eq('service_id', filters.serviceId);
      }
      if (filters.brandId) {
        query = query.eq('brand_id', filters.brandId);
      }
      if (filters.categoryId) {
        query = query.eq('category_id', filters.categoryId);
      }
      if (filters.isActive !== undefined) {
        query = query.eq('is_active', filters.isActive);
      }
      if (filters.hasCustomPrice) {
        query = query.not('custom_price', 'is', null);
      }
      if (filters.hasCustomDuration) {
        query = query.not('custom_duration', 'is', null);
      }

      const { data, error } = await query.order('model_name, service_name');

      if (error) {
        throw new Error(`Erreur lors du filtrage: ${error.message}`);
      }

      console.log(`✅ ${data?.length || 0} associations filtrées`);
      return { success: true, data: data || [] };
    } catch (error: any) {
      console.error('❌ Erreur lors du filtrage des associations:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Obtenir les statistiques des associations
   */
  async getStats(): Promise<ServiceResult<DeviceModelServiceStats>> {
    try {
      console.log('🔄 Récupération des statistiques des associations');

      // Récupérer l'utilisateur authentifié pour l'isolation
      const { data: authData, error: authError } = await supabase.auth.getUser();
      if (authError || !authData?.user) {
        throw new Error('Utilisateur non authentifié');
      }

      const { data, error } = await supabase
        .from(this.detailedViewName)
        .select('*');

      if (error) {
        throw new Error(`Erreur lors de la récupération: ${error.message}`);
      }

      const associations = data || [];
      const activeAssociations = associations.filter(a => a.is_active);
      const modelsWithServices = new Set(associations.map(a => a.device_model_id)).size;
      const servicesWithCustomPricing = associations.filter(a => a.custom_price !== null).length;
      
      const customPrices = associations
        .filter(a => a.custom_price !== null)
        .map(a => a.custom_price);
      const averageCustomPrice = customPrices.length > 0 
        ? customPrices.reduce((sum, price) => sum + price, 0) / customPrices.length 
        : 0;

      const customDurations = associations
        .filter(a => a.custom_duration !== null)
        .map(a => a.custom_duration);
      const averageCustomDuration = customDurations.length > 0 
        ? customDurations.reduce((sum, duration) => sum + duration, 0) / customDurations.length 
        : 0;

      const stats: DeviceModelServiceStats = {
        totalAssociations: associations.length,
        activeAssociations: activeAssociations.length,
        modelsWithServices,
        servicesWithCustomPricing,
        averageCustomPrice,
        averageCustomDuration,
      };

      console.log('✅ Statistiques récupérées:', stats);
      return { success: true, data: stats };
    } catch (error: any) {
      console.error('❌ Erreur lors de la récupération des statistiques:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Importer des associations en lot
   */
  async importAssociations(importData: DeviceModelServiceImportData[]): Promise<ServiceResult<DeviceModelServiceImportResult>> {
    try {
      console.log('🔄 Import de', importData.length, 'associations');

      const results = {
        success: 0,
        errors: 0,
        details: {
          imported: [] as DeviceModelServiceImportData[],
          errors: [] as Array<{ data: DeviceModelServiceImportData; error: string }>
        }
      };

      for (const item of importData) {
        try {
          // Trouver le modèle par nom, marque et catégorie
          const { data: modelData, error: modelError } = await supabase
            .from('device_models')
            .select('id, brand_id, category_id')
            .eq('name', item.modelName)
            .single();

          if (modelError || !modelData) {
            throw new Error(`Modèle non trouvé: ${item.modelName}`);
          }

          // Trouver le service par nom
          const { data: serviceData, error: serviceError } = await supabase
            .from('services')
            .select('id')
            .eq('name', item.serviceName)
            .single();

          if (serviceError || !serviceData) {
            throw new Error(`Service non trouvé: ${item.serviceName}`);
          }

          // Créer l'association
          const createResult = await this.create({
            deviceModelId: modelData.id,
            serviceId: serviceData.id,
            customPrice: item.customPrice,
            customDuration: item.customDuration,
          });

          if (createResult.success) {
            results.success++;
            results.details.imported.push(item);
          } else {
            throw new Error(createResult.error || 'Erreur inconnue');
          }
        } catch (error: any) {
          results.errors++;
          results.details.errors.push({
            data: item,
            error: error.message
          });
        }
      }

      console.log(`✅ Import terminé: ${results.success} succès, ${results.errors} erreurs`);
      return { success: true, data: results };
    } catch (error: any) {
      console.error('❌ Erreur lors de l\'import des associations:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Exporter les associations vers un format CSV
   */
  async exportToCSV(): Promise<ServiceResult<string>> {
    try {
      console.log('🔄 Export des associations vers CSV');

      const result = await this.getAll();
      if (!result.success || !result.data) {
        throw new Error(result.error || 'Erreur lors de la récupération des données');
      }

      const csvHeaders = [
        'Modèle',
        'Marque', 
        'Catégorie',
        'Service',
        'Prix par défaut',
        'Durée par défaut (h)',
        'Prix personnalisé',
        'Durée personnalisée (h)',
        'Prix effectif',
        'Durée effective (h)',
        'Actif'
      ].join(',');

      const csvRows = result.data.map(association => [
        association.modelName,
        association.brandName,
        association.categoryName,
        association.serviceName,
        association.serviceDefaultPrice,
        association.serviceDefaultDuration,
        association.customPrice || '',
        association.customDuration || '',
        association.effectivePrice,
        association.effectiveDuration,
        association.isActive ? 'Oui' : 'Non'
      ].join(','));

      const csvContent = [csvHeaders, ...csvRows].join('\n');

      console.log('✅ Export CSV généré');
      return { success: true, data: csvContent };
    } catch (error: any) {
      console.error('❌ Erreur lors de l\'export CSV:', error);
      return { success: false, error: error.message };
    }
  }
}

// Instance singleton du service
export const deviceModelServiceService = new DeviceModelServiceService();

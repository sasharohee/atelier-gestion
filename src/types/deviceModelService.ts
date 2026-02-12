// Types pour le système de services par modèle
// Permet d'associer des services spécifiques à des modèles d'appareils

import { Service } from './index';
import { DeviceModel } from './deviceManagement';
import { DeviceBrand } from './deviceManagement';
import { DeviceCategory } from './deviceManagement';

/**
 * Association entre un modèle d'appareil et un service
 * Permet de définir des services spécifiques avec prix et durée personnalisés
 */
export interface DeviceModelService {
  id: string;
  deviceModelId: string;
  serviceId: string;
  brandId: string;
  categoryId: string;
  customPrice?: number;
  customDuration?: number; // en heures
  isActive: boolean;
  userId: string;
  workshopId?: string;
  createdAt: Date;
  updatedAt: Date;
  
  // Relations peuplées (pour affichage)
  service?: Service;
  deviceModel?: DeviceModel;
  brand?: DeviceBrand;
  category?: DeviceCategory;
}

/**
 * Données pour créer une nouvelle association modèle-service
 */
export interface CreateDeviceModelServiceData {
  deviceModelId: string;
  serviceId: string;
  customPrice?: number;
  customDuration?: number;
}

/**
 * Données pour mettre à jour une association modèle-service
 */
export interface UpdateDeviceModelServiceData {
  customPrice?: number;
  customDuration?: number;
  isActive?: boolean;
}

/**
 * Vue enrichie avec toutes les informations pour l'affichage
 * Utilise la vue SQL device_model_services_detailed
 */
export interface DeviceModelServiceDetailed {
  id: string;
  deviceModelId: string;
  serviceId: string;
  brandId: string;
  categoryId: string;
  customPrice?: number;
  customDuration?: number;
  isActive: boolean;
  userId: string;
  workshopId?: string;
  createdAt: Date;
  updatedAt: Date;
  
  // Informations du service
  serviceName: string;
  serviceDescription?: string;
  serviceDefaultPrice: number;
  serviceDefaultDuration: number;
  serviceCategory: string;
  
  // Informations du modèle
  modelName: string;
  modelDescription?: string;
  
  // Informations de la marque
  brandName: string;
  brandDescription?: string;
  
  // Informations de la catégorie
  categoryName: string;
  categoryDescription?: string;
  categoryIcon?: string;
  
  // Prix et durée effectifs (personnalisés ou par défaut)
  effectivePrice: number;
  effectiveDuration: number;
}

/**
 * Filtres pour rechercher des associations modèle-service
 */
export interface DeviceModelServiceFilters {
  deviceModelId?: string;
  serviceId?: string;
  brandId?: string;
  categoryId?: string;
  isActive?: boolean;
  hasCustomPrice?: boolean;
  hasCustomDuration?: boolean;
}

/**
 * Résultat d'une requête avec services pour un modèle
 */
export interface ModelServicesResult {
  serviceId: string;
  serviceName: string;
  serviceDescription?: string;
  effectivePrice: number;
  effectiveDuration: number;
  isCustomPrice: boolean;
  isCustomDuration: boolean;
}

/**
 * Résultat d'une requête avec services par marque et catégorie
 */
export interface BrandCategoryServicesResult {
  modelId: string;
  modelName: string;
  serviceId: string;
  serviceName: string;
  effectivePrice: number;
  effectiveDuration: number;
}

/**
 * Données pour l'affichage dans l'interface de gestion
 */
export interface DeviceModelServiceDisplay {
  id: string;
  modelName: string;
  brandName: string;
  categoryName: string;
  serviceName: string;
  effectivePrice: number;
  effectiveDuration: number;
  isCustomPrice: boolean;
  isCustomDuration: boolean;
  isActive: boolean;
}

/**
 * Statistiques pour le tableau de bord
 */
export interface DeviceModelServiceStats {
  totalAssociations: number;
  activeAssociations: number;
  modelsWithServices: number;
  servicesWithCustomPricing: number;
  averageCustomPrice: number;
  averageCustomDuration: number;
}

/**
 * Configuration pour l'import/export des associations
 */
export interface DeviceModelServiceImportData {
  modelName: string;
  brandName: string;
  categoryName: string;
  serviceName: string;
  customPrice?: number;
  customDuration?: number;
  isActive?: boolean;
}

/**
 * Résultat d'un import en lot
 */
export interface DeviceModelServiceImportResult {
  success: number;
  errors: number;
  details: {
    imported: DeviceModelServiceImportData[];
    errors: Array<{
      data: DeviceModelServiceImportData;
      error: string;
    }>;
  };
}

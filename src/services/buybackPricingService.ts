import { supabase } from '../lib/supabase';
import { DeviceMarketPrice, BuybackPricing, BuybackPricingInput } from '../types';

interface PricingResult {
  success: boolean;
  data?: BuybackPricing;
  error?: Error;
}

/**
 * Service de calcul intelligent des prix de rachat
 * Utilise les prix de référence stockés en base et applique tous les ajustements
 */
export class BuybackPricingService {
  
  /**
   * Calcule le prix estimé d'un appareil en rachat
   * @param input - Données de l'appareil et de son état
   * @returns Prix estimé avec détail du calcul
   */
  async calculateEstimatedPrice(input: BuybackPricingInput): Promise<PricingResult> {
    try {
      console.log('🔍 Calcul du prix estimé pour:', input.deviceBrand, input.deviceModel);
      
      // 1. Récupérer les prix de référence pour ce modèle
      const priceData = await this.getDeviceBasePrice(
        input.deviceBrand, 
        input.deviceModel, 
        input.deviceType
      );
      
      if (!priceData.success || !priceData.data) {
        console.log('⚠️ Aucune donnée de prix trouvée, utilisation du prix par défaut');
        return this.calculateDefaultPrice(input);
      }
      
      const marketPrice = priceData.data;
      
      // 2. Calculer le prix de base selon la capacité
      const basePrice = this.getBasePriceForCapacity(marketPrice, input.storageCapacity);
      
      if (basePrice === 0) {
        console.log('⚠️ Prix de base non trouvé pour cette capacité');
        return this.calculateDefaultPrice(input);
      }
      
      // 3. Appliquer tous les ajustements
      const breakdown = {
        basePrice,
        conditionMultiplier: 1,
        screenMultiplier: 1,
        batteryPenalty: 0,
        buttonPenalty: 0,
        functionalPenalty: 0,
        accessoriesBonus: 0,
        warrantyBonus: 0,
        lockPenalty: 0,
        finalPrice: basePrice
      };
      
      let estimatedPrice = basePrice;
      
      // Ajustement état physique
      const conditionMultiplier = marketPrice.conditionMultipliers[input.physicalCondition] || 0.8;
      estimatedPrice *= conditionMultiplier;
      breakdown.conditionMultiplier = conditionMultiplier;
      
      // Ajustement état écran
      if (input.screenCondition) {
        const screenMultiplier = marketPrice.screenConditionMultipliers[input.screenCondition] || 1;
        estimatedPrice *= screenMultiplier;
        breakdown.screenMultiplier = screenMultiplier;
      }
      
      // Déduction batterie
      if (input.batteryHealth !== undefined) {
        const batteryPenalty = (100 - input.batteryHealth) * marketPrice.batteryHealthPenalty;
        estimatedPrice -= batteryPenalty;
        breakdown.batteryPenalty = batteryPenalty;
      }
      
      // Déduction boutons
      if (input.buttonCondition && input.buttonCondition !== 'perfect') {
        const buttonPenalty = marketPrice.buttonConditionPenalty[input.buttonCondition] || 0;
        estimatedPrice -= buttonPenalty;
        breakdown.buttonPenalty = buttonPenalty;
      }
      
      // Déduction fonctionnalités défectueuses
      let functionalPenalty = 0;
      Object.entries(input.functionalCondition).forEach(([key, isWorking]) => {
        if (!isWorking) {
          const penalty = marketPrice.functionalPenalties[key] || 0;
          functionalPenalty += penalty;
        }
      });
      estimatedPrice -= functionalPenalty;
      breakdown.functionalPenalty = functionalPenalty;
      
      // Bonus accessoires
      let accessoriesBonus = 0;
      Object.entries(input.accessories).forEach(([key, included]) => {
        if (included) {
          const bonus = marketPrice.accessoriesBonus[key] || 0;
          accessoriesBonus += bonus;
        }
      });
      estimatedPrice += accessoriesBonus;
      breakdown.accessoriesBonus = accessoriesBonus;
      
      // Bonus garantie
      if (input.hasWarranty && input.warrantyExpiresAt) {
        const warrantyMonthsLeft = this.getWarrantyMonthsLeft(input.warrantyExpiresAt);
        if (warrantyMonthsLeft > 6) {
          const warrantyBonus = estimatedPrice * (marketPrice.warrantyBonusPercentage / 100);
          estimatedPrice += warrantyBonus;
          breakdown.warrantyBonus = warrantyBonus;
        }
      }
      
      // Pénalités blocages
      let lockPenalty = 0;
      if (input.icloudLocked) {
        lockPenalty += estimatedPrice * (marketPrice.lockPenalties.icloud / 100);
      }
      if (input.googleLocked) {
        lockPenalty += estimatedPrice * (marketPrice.lockPenalties.google / 100);
      }
      if (input.carrierLocked) {
        lockPenalty += estimatedPrice * (marketPrice.lockPenalties.carrier / 100);
      }
      estimatedPrice -= lockPenalty;
      breakdown.lockPenalty = lockPenalty;
      
      // S'assurer que le prix ne soit pas négatif
      estimatedPrice = Math.max(0, estimatedPrice);
      breakdown.finalPrice = estimatedPrice;
      
      const result: BuybackPricing = {
        estimatedPrice: Math.round(estimatedPrice),
        basePrice: Math.round(basePrice),
        breakdown
      };
      
      console.log('✅ Prix calculé:', result);
      return { success: true, data: result };
      
    } catch (error) {
      console.error('❌ Erreur lors du calcul du prix:', error);
      return { success: false, error: error as Error };
    }
  }
  
  /**
   * Récupère les prix de référence pour un modèle d'appareil
   */
  private async getDeviceBasePrice(
    brand: string, 
    model: string, 
    deviceType: string
  ): Promise<{ success: boolean; data?: DeviceMarketPrice; error?: Error }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return { success: false, error: new Error('Utilisateur non connecté') };
      }

      const { data, error } = await supabase
        .from('device_market_prices')
        .select('*')
        .eq('device_brand', brand)
        .eq('device_model', model)
        .eq('device_type', deviceType)
        .eq('user_id', user.id)
        .eq('is_active', true)
        .single();
      
      if (error) {
        console.log('⚠️ Prix non trouvé en base:', error.message);
        return { success: false, error };
      }
      
      // Conversion snake_case vers camelCase
      const convertedData: DeviceMarketPrice = {
        id: data.id,
        deviceModelId: data.device_model_id,
        deviceBrand: data.device_brand,
        deviceModel: data.device_model,
        deviceType: data.device_type,
        pricesByCapacity: data.prices_by_capacity,
        releaseYear: data.release_year,
        marketSegment: data.market_segment,
        baseMarketPrice: data.base_market_price,
        currentMarketPrice: data.current_market_price,
        depreciationRate: data.depreciation_rate,
        conditionMultipliers: data.condition_multipliers,
        screenConditionMultipliers: data.screen_condition_multipliers,
        batteryHealthPenalty: data.battery_health_penalty,
        buttonConditionPenalty: data.button_condition_penalty,
        functionalPenalties: data.functional_penalties,
        accessoriesBonus: data.accessories_bonus,
        warrantyBonusPercentage: data.warranty_bonus_percentage,
        lockPenalties: data.lock_penalties,
        isActive: data.is_active,
        lastPriceUpdate: new Date(data.last_price_update),
        priceSource: data.price_source,
        externalApiId: data.external_api_id,
        userId: data.user_id,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return { success: true, data: convertedData };
      
    } catch (error) {
      return { success: false, error: error as Error };
    }
  }
  
  /**
   * Extrait le prix de base pour une capacité donnée
   */
  private getBasePriceForCapacity(marketPrice: DeviceMarketPrice, capacity?: string): number {
    if (!capacity || !marketPrice.pricesByCapacity) {
      // Utiliser le prix moyen si pas de capacité spécifiée
      const prices = Object.values(marketPrice.pricesByCapacity);
      return prices.length > 0 ? prices.reduce((a, b) => a + b, 0) / prices.length : 0;
    }
    
    return marketPrice.pricesByCapacity[capacity] || 0;
  }
  
  /**
   * Calcule le nombre de mois de garantie restants
   */
  private getWarrantyMonthsLeft(expiryDate: Date): number {
    const now = new Date();
    const diffTime = expiryDate.getTime() - now.getTime();
    const diffMonths = Math.ceil(diffTime / (1000 * 60 * 60 * 24 * 30));
    return Math.max(0, diffMonths);
  }
  
  // Table de référence intégrée : prix de rachat de base par modèle
  private static readonly REFERENCE_PRICES: Record<string, Record<string, number>> = {
    'apple': {
      'iphone 15 pro max': 550, 'iphone 15 pro': 480, 'iphone 15': 380, 'iphone 15 plus': 400,
      'iphone 14 pro max': 450, 'iphone 14 pro': 400, 'iphone 14': 300, 'iphone 14 plus': 320,
      'iphone 13 pro max': 380, 'iphone 13 pro': 340, 'iphone 13': 250, 'iphone 13 mini': 220,
      'iphone 12 pro max': 300, 'iphone 12 pro': 270, 'iphone 12': 200, 'iphone 12 mini': 170,
      'iphone 11 pro max': 230, 'iphone 11 pro': 210, 'iphone 11': 160,
      'iphone se (2022)': 150, 'iphone se (2020)': 100, 'iphone se 2022': 150, 'iphone se 2020': 100,
      'iphone xs max': 170, 'iphone xs': 150, 'iphone xr': 130, 'iphone x': 120,
      'ipad pro 12.9': 450, 'ipad pro 11': 380, 'ipad air': 280, 'ipad': 180, 'ipad mini': 220,
      'macbook pro 16': 900, 'macbook pro 14': 750, 'macbook pro 13': 550, 'macbook air': 450,
    },
    'samsung': {
      'galaxy s24 ultra': 480, 'galaxy s24+': 380, 'galaxy s24': 320,
      'galaxy s23 ultra': 400, 'galaxy s23+': 320, 'galaxy s23': 260,
      'galaxy s22 ultra': 320, 'galaxy s22+': 250, 'galaxy s22': 200,
      'galaxy s21 ultra': 250, 'galaxy s21+': 200, 'galaxy s21': 170,
      'galaxy z fold5': 550, 'galaxy z flip5': 350,
      'galaxy z fold4': 450, 'galaxy z flip4': 280,
      'galaxy a54': 150, 'galaxy a34': 100, 'galaxy a14': 60,
      'galaxy tab s9': 350, 'galaxy tab s8': 280, 'galaxy tab a': 120,
    },
    'google': {
      'pixel 8 pro': 350, 'pixel 8': 280, 'pixel 7 pro': 280, 'pixel 7': 220,
    },
    'xiaomi': {
      '14 ultra': 350, '14 pro': 280, '13t pro': 220, '13t': 180,
      'redmi note 13 pro': 120, 'redmi note 12 pro': 100,
    },
    'huawei': {
      'p60 pro': 300, 'p50 pro': 220, 'mate 50 pro': 280,
    },
  };

  // Multiplicateurs de condition physique
  private static readonly CONDITION_MULTIPLIERS: Record<string, number> = {
    'excellent': 1.0, 'good': 0.85, 'fair': 0.65, 'poor': 0.40, 'broken': 0.15,
  };

  // Multiplicateurs d'état écran
  private static readonly SCREEN_MULTIPLIERS: Record<string, number> = {
    'perfect': 1.0, 'minor_scratches': 0.95, 'major_scratches': 0.85, 'cracked': 0.60, 'broken': 0.30,
  };

  // Pénalités boutons
  private static readonly BUTTON_PENALTIES: Record<string, number> = {
    'perfect': 0, 'sticky': 10, 'broken': 25, 'missing': 40,
  };

  // Bonus accessoires
  private static readonly ACCESSORY_BONUSES: Record<string, number> = {
    'charger': 5, 'cable': 3, 'originalBox': 10, 'headphones': 5,
  };

  // Pénalités fonctionnelles
  private static readonly FUNCTIONAL_PENALTIES: Record<string, number> = {
    'powersOn': 50, 'touchWorks': 15, 'soundWorks': 15, 'camerasWork': 15, 'buttonsWork': 15,
  };

  /**
   * Recherche fuzzy du prix de base dans la table de référence
   */
  private findReferencePrice(brand: string, model: string): number | null {
    const normalizedBrand = brand.toLowerCase().trim();
    const normalizedModel = model.toLowerCase().trim();

    const brandPrices = BuybackPricingService.REFERENCE_PRICES[normalizedBrand];
    if (!brandPrices) return null;

    // 1. Match exact
    if (brandPrices[normalizedModel] !== undefined) {
      return brandPrices[normalizedModel];
    }

    // 2. Match partiel : le modèle saisi est contenu dans une clé de référence ou inversement
    let bestMatch: { key: string; price: number; score: number } | null = null;
    for (const [refModel, price] of Object.entries(brandPrices)) {
      let score = 0;
      if (refModel.includes(normalizedModel)) {
        // Le modèle saisi est un sous-ensemble d'une référence (ex: "iphone 15" -> "iphone 15 pro max")
        score = normalizedModel.length / refModel.length;
      } else if (normalizedModel.includes(refModel)) {
        // La référence est un sous-ensemble du modèle saisi (ex: "iphone 15 pro max 256gb" -> "iphone 15 pro max")
        score = refModel.length / normalizedModel.length;
      }
      if (score > 0 && (!bestMatch || score > bestMatch.score)) {
        bestMatch = { key: refModel, price, score };
      }
    }

    if (bestMatch) {
      console.log(`🔍 Match fuzzy: "${normalizedModel}" -> "${bestMatch.key}" (score: ${bestMatch.score.toFixed(2)})`);
      return bestMatch.price;
    }

    return null;
  }

  /**
   * Calcul de prix intelligent avec table de référence intégrée
   */
  private calculateDefaultPrice(input: BuybackPricingInput): PricingResult {
    console.log('🔄 Calcul intelligent par modèle');

    // 1. Chercher le prix de base dans la table de référence
    let basePrice = this.findReferencePrice(input.deviceBrand, input.deviceModel);

    // Fallback par type d'appareil si aucun match
    if (basePrice === null) {
      console.log('⚠️ Modèle non trouvé dans la table de référence, fallback par type');
      switch (input.deviceType) {
        case 'smartphone': basePrice = 150; break;
        case 'tablet': basePrice = 120; break;
        case 'laptop': basePrice = 350; break;
        case 'desktop': basePrice = 250; break;
        default: basePrice = 80;
      }
    }

    const breakdown = {
      basePrice,
      conditionMultiplier: 1,
      screenMultiplier: 1,
      batteryPenalty: 0,
      buttonPenalty: 0,
      functionalPenalty: 0,
      accessoriesBonus: 0,
      warrantyBonus: 0,
      lockPenalty: 0,
      finalPrice: basePrice,
    };

    let estimatedPrice = basePrice;

    // 2. Ajustement condition physique
    const conditionMultiplier = BuybackPricingService.CONDITION_MULTIPLIERS[input.physicalCondition] || 0.85;
    estimatedPrice *= conditionMultiplier;
    breakdown.conditionMultiplier = conditionMultiplier;

    // 3. Ajustement état écran
    if (input.screenCondition) {
      const screenMultiplier = BuybackPricingService.SCREEN_MULTIPLIERS[input.screenCondition] || 1;
      estimatedPrice *= screenMultiplier;
      breakdown.screenMultiplier = screenMultiplier;
    }

    // 4. Pénalité batterie : -1€ par % en dessous de 80%
    if (input.batteryHealth !== undefined && input.batteryHealth < 80) {
      const batteryPenalty = (80 - input.batteryHealth) * 1;
      estimatedPrice -= batteryPenalty;
      breakdown.batteryPenalty = batteryPenalty;
    }

    // 5. Pénalité boutons
    if (input.buttonCondition && input.buttonCondition !== 'perfect') {
      const buttonPenalty = BuybackPricingService.BUTTON_PENALTIES[input.buttonCondition] || 0;
      estimatedPrice -= buttonPenalty;
      breakdown.buttonPenalty = buttonPenalty;
    }

    // 6. Pénalités fonctionnelles
    let functionalPenalty = 0;
    if (input.functionalCondition) {
      Object.entries(input.functionalCondition).forEach(([key, isWorking]) => {
        if (!isWorking) {
          functionalPenalty += BuybackPricingService.FUNCTIONAL_PENALTIES[key] || 15;
        }
      });
    }
    estimatedPrice -= functionalPenalty;
    breakdown.functionalPenalty = functionalPenalty;

    // 7. Bonus accessoires
    let accessoriesBonus = 0;
    if (input.accessories) {
      Object.entries(input.accessories).forEach(([key, included]) => {
        if (included) {
          accessoriesBonus += BuybackPricingService.ACCESSORY_BONUSES[key] || 0;
        }
      });
    }
    estimatedPrice += accessoriesBonus;
    breakdown.accessoriesBonus = accessoriesBonus;

    // 8. Bonus garantie (> 6 mois restants -> +5%)
    let warrantyBonus = 0;
    if (input.hasWarranty && input.warrantyExpiresAt) {
      const warrantyMonthsLeft = this.getWarrantyMonthsLeft(input.warrantyExpiresAt);
      if (warrantyMonthsLeft > 6) {
        warrantyBonus = estimatedPrice * 0.05;
        estimatedPrice += warrantyBonus;
      }
    }
    breakdown.warrantyBonus = warrantyBonus;

    // 9. Pénalités blocages
    let lockPenalty = 0;
    if (input.icloudLocked) {
      lockPenalty += estimatedPrice * 0.70;
    }
    if (input.googleLocked) {
      lockPenalty += estimatedPrice * 0.50;
    }
    if (input.carrierLocked) {
      lockPenalty += estimatedPrice * 0.15;
    }
    estimatedPrice -= lockPenalty;
    breakdown.lockPenalty = lockPenalty;

    // Prix minimum 0
    estimatedPrice = Math.max(0, estimatedPrice);
    breakdown.finalPrice = estimatedPrice;

    const result: BuybackPricing = {
      estimatedPrice: Math.round(estimatedPrice),
      basePrice: Math.round(basePrice),
      breakdown,
    };

    console.log('✅ Prix calculé (référence intégrée):', result);
    return { success: true, data: result };
  }
  
  /**
   * Met à jour les prix de référence depuis une API externe
   */
  async updatePricesFromAPI(): Promise<{ success: boolean; updated: number; error?: Error }> {
    try {
      // TODO: Implémenter l'appel à l'API externe
      console.log('🔄 Mise à jour des prix depuis API externe (à implémenter)');
      return { success: true, updated: 0 };
    } catch (error) {
      return { success: false, updated: 0, error: error as Error };
    }
  }
  
  /**
   * Obtient les statistiques de pricing
   */
  async getPricingStats(): Promise<{ success: boolean; data?: any; error?: Error }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return { success: false, error: new Error('Utilisateur non connecté') };
      }

      const { data, error } = await supabase
        .from('device_market_prices')
        .select('device_brand, device_model, last_price_update, price_source')
        .eq('user_id', user.id)
        .eq('is_active', true);
      
      if (error) {
        return { success: false, error };
      }
      
      const stats = {
        totalModels: data.length,
        brands: [...new Set(data.map((item: any) => item.device_brand))],
        lastUpdate: data.length > 0 ? Math.max(...data.map((item: any) => new Date(item.last_price_update).getTime())) : null,
        sources: [...new Set(data.map((item: any) => item.price_source))]
      };
      
      return { success: true, data: stats };
      
    } catch (error) {
      return { success: false, error: error as Error };
    }
  }
}

// Instance singleton du service
export const buybackPricingService = new BuybackPricingService();

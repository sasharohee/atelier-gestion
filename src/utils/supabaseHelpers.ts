// Fonctions utilitaires pour la gestion des réponses Supabase

export interface SupabaseResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string | null;
  message?: string;
}

/**
 * Gère les erreurs Supabase et retourne une réponse standardisée
 */
export const handleSupabaseError = (error: any): SupabaseResponse => {
  console.error('❌ Erreur Supabase:', error);
  
  let errorMessage = 'Une erreur est survenue';
  
  if (error?.message) {
    errorMessage = error.message;
  } else if (typeof error === 'string') {
    errorMessage = error;
  }
  
  return {
    success: false,
    error: errorMessage,
    message: 'Opération échouée'
  };
};

/**
 * Gère les succès Supabase et retourne une réponse standardisée
 */
export const handleSupabaseSuccess = <T = any>(data: T, message?: string): SupabaseResponse<T> => {
  console.log('✅ Succès Supabase:', data);
  
  return {
    success: true,
    data,
    message: message || 'Opération réussie'
  };
};

/**
 * Gère les réponses Supabase (succès ou erreur) et retourne une réponse standardisée
 */
export const handleSupabaseResponse = <T = any>(
  data: T | null, 
  error: any, 
  successMessage?: string
): SupabaseResponse<T> => {
  if (error) {
    return handleSupabaseError(error);
  }
  
  return handleSupabaseSuccess(data, successMessage);
};

/**
 * Convertit les données de snake_case vers camelCase
 */
export const convertToCamelCase = (obj: any): any => {
  if (obj === null || obj === undefined) {
    return obj;
  }
  
  if (Array.isArray(obj)) {
    return obj.map(convertToCamelCase);
  }
  
  if (typeof obj === 'object') {
    const converted: any = {};
    
    for (const [key, value] of Object.entries(obj)) {
      // Convertir snake_case vers camelCase
      const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
      converted[camelKey] = convertToCamelCase(value);
    }
    
    return converted;
  }
  
  return obj;
};

/**
 * Convertit les données de camelCase vers snake_case
 */
export const convertToSnakeCase = (obj: any): any => {
  if (obj === null || obj === undefined) {
    return obj;
  }
  
  if (Array.isArray(obj)) {
    return obj.map(convertToSnakeCase);
  }
  
  if (typeof obj === 'object') {
    const converted: any = {};
    
    for (const [key, value] of Object.entries(obj)) {
      // Convertir camelCase vers snake_case
      const snakeKey = key.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);
      converted[snakeKey] = convertToSnakeCase(value);
    }
    
    return converted;
  }
  
  return obj;
};

/**
 * Valide qu'un objet contient les propriétés requises
 */
export const validateRequired = (obj: any, requiredFields: string[]): string[] => {
  const missingFields: string[] = [];
  
  for (const field of requiredFields) {
    if (obj[field] === undefined || obj[field] === null || obj[field] === '') {
      missingFields.push(field);
    }
  }
  
  return missingFields;
};

/**
 * Formate une date pour l'affichage
 */
export const formatDate = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return dateObj.toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

/**
 * Formate une date et heure pour l'affichage
 */
export const formatDateTime = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return dateObj.toLocaleString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

/**
 * Génère un ID unique
 */
export const generateId = (): string => {
  return Math.random().toString(36).substr(2, 9);
};

/**
 * Débounce une fonction
 */
export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: NodeJS.Timeout;
  
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};

/**
 * Throttle une fonction
 */
export const throttle = <T extends (...args: any[]) => any>(
  func: T,
  limit: number
): ((...args: Parameters<T>) => void) => {
  let inThrottle: boolean;
  
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
};

/**
 * Teste la connexion à Supabase
 */
export const testConnection = async (supabaseClient: any): Promise<boolean> => {
  try {
    console.log('🔍 Test de connexion à Supabase...');
    
    // Test simple : récupérer la session actuelle
    const { error } = await supabaseClient.auth.getSession();
    
    if (error && !error.message.includes('Auth session missing')) {
      console.error('❌ Erreur de connexion:', error);
      return false;
    }
    
    console.log('✅ Connexion à Supabase réussie');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors du test de connexion:', error);
    return false;
  }
};

/**
 * Vérifie la santé de la connexion Supabase
 */
export const checkConnectionHealth = async (supabaseClient: any) => {
  const startTime = Date.now();
  
  try {
    console.log('🏥 Vérification de la santé de la connexion...');
    
    // Test de performance avec une requête simple
    const { error } = await supabaseClient.auth.getSession();
    
    const responseTime = Date.now() - startTime;
    
    if (error && !error.message.includes('Auth session missing')) {
      console.error('❌ Problème de santé de connexion:', error);
      return {
        healthy: false,
        responseTime,
        message: error.message
      };
    }
    
    console.log(`✅ Connexion saine (${responseTime}ms)`);
    
    return {
      healthy: true,
      responseTime,
      message: `Connexion stable (${responseTime}ms)`
    };
  } catch (error) {
    const responseTime = Date.now() - startTime;
    console.error('❌ Erreur lors de la vérification de santé:', error);
    
    return {
      healthy: false,
      responseTime,
      message: error instanceof Error ? error.message : 'Erreur inconnue'
    };
  }
};

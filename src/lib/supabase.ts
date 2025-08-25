import { createClient } from '@supabase/supabase-js';

// Configuration Supabase
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8';

// Création du client Supabase
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    storageKey: 'atelier-auth-token'
  },
  db: {
    schema: 'public'
  },
  global: {
    headers: {
      'X-Client-Info': 'atelier-gestion-app'
    }
  }
});

// Configuration pour la connexion directe PostgreSQL (optionnel)
export const postgresConfig = {
  host: 'db.wlqyrmntfxwdvkzzsujv.supabase.co',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'wi?8sN$wn&#BVr7'
};

// Types pour les réponses Supabase
export interface SupabaseResponse<T> {
  data: T | null;
  error: any;
  count?: number;
}

// Fonctions utilitaires pour la gestion des erreurs
export const handleSupabaseError = (error: any) => {
  console.error('Supabase error:', error);
  return {
    success: false,
    error: error?.message || 'Une erreur est survenue'
  };
};

export const handleSupabaseSuccess = <T>(data: T) => {
  return {
    success: true,
    data
  };
};

// Fonction pour nettoyer l'état d'authentification
export const clearAuthState = () => {
  try {
    // Nettoyer le localStorage
    localStorage.removeItem('atelier-auth-token');
    localStorage.removeItem('supabase.auth.token');
    localStorage.removeItem('pendingSignupEmail');
    localStorage.removeItem('confirmationToken');
    localStorage.removeItem('pendingUserData');
    
    // Nettoyer sessionStorage
    sessionStorage.removeItem('atelier-auth-token');
    sessionStorage.removeItem('supabase.auth.token');
    
    console.log('🧹 État d\'authentification nettoyé');
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
  }
};

// Fonction pour réinitialiser l'authentification
export const resetAuth = async () => {
  try {
    console.log('🔄 Réinitialisation de l\'authentification...');
    
    // Déconnexion forcée
    await supabase.auth.signOut();
    
    // Nettoyer l'état
    clearAuthState();
    
    // Recharger la page pour forcer une réinitialisation complète
    window.location.reload();
    
    return true;
  } catch (error) {
    console.error('❌ Erreur lors de la réinitialisation:', error);
    return false;
  }
};

// Fonction pour vérifier et corriger l'état d'authentification
export const checkAndFixAuthState = async () => {
  try {
    const { data: { user }, error } = await supabase.auth.getUser();
    
    if (error) {
      console.log('⚠️ Erreur d\'authentification détectée:', error.message);
      
      // Si c'est une erreur de token invalide, nettoyer et réinitialiser
      if (error.message.includes('Invalid Refresh Token') || 
          error.message.includes('Refresh Token Not Found')) {
        console.log('🔄 Token invalide détecté, nettoyage en cours...');
        clearAuthState();
        return false;
      }
    }
    
    return !!user;
  } catch (error) {
    console.error('❌ Erreur lors de la vérification de l\'authentification:', error);
    clearAuthState();
    return false;
  }
};

// Fonction pour vérifier la connexion
export const testConnection = async () => {
  try {
    const { data, error } = await supabase.from('clients').select('count').limit(1);
    if (error) {
      console.error('Erreur de connexion Supabase:', error);
      return false;
    }
    console.log('✅ Connexion Supabase réussie');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors du test de connexion:', error);
    return false;
  }
};

// Fonction pour vérifier la santé de la connexion
export const checkConnectionHealth = async () => {
  try {
    const startTime = Date.now();
    const { data, error } = await supabase.from('clients').select('count').limit(1);
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    
    if (error) {
      return { healthy: false, error: error.message, responseTime };
    }
    
    return { 
      healthy: true, 
      responseTime,
      message: `Connexion stable (${responseTime}ms)`
    };
  } catch (error) {
    return { 
      healthy: false, 
      error: error instanceof Error ? error.message : 'Erreur inconnue',
      responseTime: undefined
    };
  }
};

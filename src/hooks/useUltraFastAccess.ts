import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { User } from '@supabase/supabase-js';

// Cache global pour la vérification d'accès ultra-rapide
const accessCache = new Map<string, { 
  user: User | null; 
  isActive: boolean; 
  timestamp: number 
}>();
const ACCESS_CACHE_DURATION = 15000; // 15 secondes

// Protection contre les appels multiples
let globalCheckInProgress = false;
let globalHasChecked = false;

// États globaux partagés entre toutes les instances du hook
let globalUser: User | null = null;
let globalIsAccessActive: boolean | null = null;
let globalLoading = true;
let globalAuthLoading = true;
let globalSubscriptionLoading = true;

export const useUltraFastAccess = () => {
  // Initialiser avec les données du cache si disponibles
  const getInitialState = () => {
    const cached = accessCache.get('ultra_fast_access');
    const now = Date.now();
    
    if (cached && (now - cached.timestamp) < ACCESS_CACHE_DURATION) {
      return {
        user: cached.user,
        isAccessActive: cached.isActive,
        loading: false,
        authLoading: false,
        subscriptionLoading: false
      };
    }
    
    return {
      user: null,
      isAccessActive: null,
      loading: true,
      authLoading: true,
      subscriptionLoading: true
    };
  };

  const initialState = getInitialState();
  const [user, setUser] = useState<User | null>(initialState.user || globalUser);
  const [isAccessActive, setIsAccessActive] = useState<boolean | null>(initialState.isAccessActive || globalIsAccessActive);
  const [loading, setLoading] = useState(initialState.loading && globalLoading);
  const [authLoading, setAuthLoading] = useState(initialState.authLoading && globalAuthLoading);
  const [subscriptionLoading, setSubscriptionLoading] = useState(initialState.subscriptionLoading && globalSubscriptionLoading);
  const hasChecked = useRef(false);
  const isChecking = useRef(false);

  const checkAccess = async () => {
    // Éviter les vérifications multiples simultanées
    if (isChecking.current || globalCheckInProgress) {
      return;
    }

    try {
      isChecking.current = true;
      globalCheckInProgress = true;
      setLoading(true);
      setAuthLoading(true);
      setSubscriptionLoading(true);

      // Vérifier le cache d'abord
      const cached = accessCache.get('ultra_fast_access');
      const now = Date.now();
      
      if (cached && (now - cached.timestamp) < ACCESS_CACHE_DURATION) {
        console.log('⚡ Accès vérifié depuis le cache ultra-rapide');
        setUser(cached.user);
        setIsAccessActive(cached.isActive);
        setLoading(false);
        setAuthLoading(false);
        setSubscriptionLoading(false);
        isChecking.current = false;
        globalCheckInProgress = false;
        return;
      }

      // Vérification ultra-rapide en une seule requête
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      let isActive = false;
      
      if (user && !authError) {
        // Vérification d'accès rapide (seulement is_active)
        const { data, error } = await supabase
          .from('subscription_status')
          .select('is_active')
          .eq('user_id', user.id)
          .single();
        
        if (error) {
          // Logique rapide pour les admins
          const userEmail = user.email?.toLowerCase();
          const isAdmin = userEmail === 'srohee32@gmail.com' || userEmail === 'repphonereparation@gmail.com';
          const userRole = user.user_metadata?.role || 'technician';
          isActive = isAdmin || userRole === 'admin';
        } else {
          isActive = data?.is_active || false;
        }
      }

      // Traiter les résultats
      setUser(user);
      setIsAccessActive(isActive);
      setAuthLoading(false);
      setSubscriptionLoading(false);

      // Mettre à jour les états globaux
      globalUser = user;
      globalIsAccessActive = isActive;
      globalLoading = false;
      globalAuthLoading = false;
      globalSubscriptionLoading = false;

      // Mettre en cache le résultat
      accessCache.set('ultra_fast_access', { 
        user, 
        isActive, 
        timestamp: now 
      });

      console.log(`✅ Vérification ultra-rapide terminée: ${user?.email} - ${isActive ? 'ACTIF' : 'RESTREINT'}`);

    } catch (err) {
      console.error('Erreur lors de la vérification ultra-rapide:', err);
      setUser(null);
      setIsAccessActive(false);
      
      // Mettre à jour les états globaux en cas d'erreur
      globalUser = null;
      globalIsAccessActive = false;
      globalLoading = false;
      globalAuthLoading = false;
      globalSubscriptionLoading = false;
    } finally {
      setLoading(false);
      isChecking.current = false;
      globalCheckInProgress = false;
    }
  };

  const refreshAccess = async () => {
    // Invalider le cache et réinitialiser les flags
    accessCache.delete('ultra_fast_access');
    globalHasChecked = false;
    hasChecked.current = false;
    
    // Réinitialiser les états globaux
    globalUser = null;
    globalIsAccessActive = null;
    globalLoading = true;
    globalAuthLoading = true;
    globalSubscriptionLoading = true;
    
    await checkAccess();
  };

  useEffect(() => {
    // Si les données sont déjà en cache et valides, ne pas appeler checkAccess
    const cached = accessCache.get('ultra_fast_access');
    const now = Date.now();
    
    if (cached && (now - cached.timestamp) < ACCESS_CACHE_DURATION) {
      hasChecked.current = true;
      globalHasChecked = true;
      return;
    }
    
    if (!hasChecked.current && !isChecking.current && !globalCheckInProgress && !globalHasChecked) {
      hasChecked.current = true;
      globalHasChecked = true;
      checkAccess();
    }
  }, []);

  return {
    user,
    isAuthenticated: !!user,
    isAccessActive,
    loading,
    authLoading,
    subscriptionLoading,
    refreshAccess
  };
};

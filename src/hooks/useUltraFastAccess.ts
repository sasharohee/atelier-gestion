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
  const [refreshTrigger, setRefreshTrigger] = useState(0);
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

      // Vérifier le cache d'abord (sauf si on force le refresh)
      const cached = accessCache.get('ultra_fast_access');
      const now = Date.now();
      
      // Ne pas utiliser le cache si l'utilisateur vient juste de se connecter
      if (cached && (now - cached.timestamp) < ACCESS_CACHE_DURATION) {
        console.log('⚡ Accès vérifié depuis le cache ultra-rapide');
        setUser(cached.user);
        setIsAccessActive(cached.isActive);
        setLoading(false);
        setAuthLoading(false);
        setSubscriptionLoading(false);
        globalUser = cached.user;
        globalIsAccessActive = cached.isActive;
        globalLoading = false;
        globalAuthLoading = false;
        globalSubscriptionLoading = false;
        isChecking.current = false;
        globalCheckInProgress = false;
        return;
      }

      // Vérification ultra-rapide en une seule requête
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      // Gérer les erreurs CORS/réseau
      if (authError && (
        authError.message.includes('Failed to fetch') || 
        authError.message.includes('CORS') ||
        authError.message.includes('502')
      )) {
        console.warn('⚠️ Erreur réseau temporaire lors de la vérification d\'accès');
        setUser(null);
        setIsAccessActive(false);
        setLoading(false);
        setAuthLoading(false);
        setSubscriptionLoading(false);
        isChecking.current = false;
        globalCheckInProgress = false;
        return;
      }
      
      let isActive = false;
      
      if (user && !authError) {
        // Vérification d'accès rapide (is_active + stripe_current_period_end pour vérifier l'expiration)
        const { data, error } = await supabase
          .from('subscription_status')
          .select('is_active, stripe_current_period_end')
          .eq('user_id', user.id)
          .single();
        
        if (error) {
          // Logique rapide pour les admins
          const userEmail = user.email?.toLowerCase();
          const isAdmin = userEmail === 'srohee32@gmail.com' || userEmail === 'repphonereparation@gmail.com';
          const userRole = user.user_metadata?.role || 'technician';
          isActive = isAdmin || userRole === 'admin';
        } else {
          // Vérifier si l'abonnement est actif ET non expiré
          let subscriptionActive = data?.is_active || false;
          
          // Si l'abonnement est marqué actif mais la période est expirée, le désactiver
          if (subscriptionActive && data?.stripe_current_period_end) {
            const periodEnd = new Date(data.stripe_current_period_end);
            const now = new Date();
            
            if (periodEnd < now) {
              // Abonnement expiré - désactiver
              subscriptionActive = false;
              console.log(`⚠️ Abonnement expiré pour ${user.email} - Blocage automatique`);
              
              // Mettre à jour la base de données en arrière-plan
              supabase
                .from('subscription_status')
                .update({
                  is_active: false,
                  updated_at: new Date().toISOString(),
                })
                .eq('user_id', user.id)
                .then(({ error }) => {
                  if (error) {
                    console.error('Erreur lors de la mise à jour du statut expiré:', error);
                  }
                });
            }
          }
          
          isActive = subscriptionActive;
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

    } catch (err: any) {
      // Gérer les erreurs réseau sans les afficher à l'utilisateur
      if (err?.message?.includes('Failed to fetch') || 
          err?.message?.includes('CORS') ||
          err?.message?.includes('502')) {
        console.warn('⚠️ Erreur réseau temporaire lors de la vérification ultra-rapide');
      } else {
        console.error('Erreur lors de la vérification ultra-rapide:', err);
      }
      
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

  // Invalider le cache après connexion/déconnexion
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || event === 'TOKEN_REFRESHED') {
        console.log('🔄 Invalidation du cache suite à:', event);
        accessCache.delete('ultra_fast_access');
        globalHasChecked = false;
        hasChecked.current = false;
        
        // Déclencher une nouvelle vérification
        setRefreshTrigger(prev => prev + 1);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    // Réinitialiser les flags quand refreshTrigger change (sauf au montage initial)
    if (refreshTrigger > 0) {
      hasChecked.current = false;
      globalHasChecked = false;
    }
    
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
  }, [refreshTrigger]); // Se déclenche au montage ET quand refreshTrigger change

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

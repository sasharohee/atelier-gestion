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

export const useUltraFastAccess = () => {
  const [user, setUser] = useState<User | null>(null);
  const [isAccessActive, setIsAccessActive] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const [authLoading, setAuthLoading] = useState(true);
  const [subscriptionLoading, setSubscriptionLoading] = useState(true);
  const hasChecked = useRef(false);

  const checkAccess = async () => {
    try {
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
    } finally {
      setLoading(false);
    }
  };

  const refreshAccess = async () => {
    // Invalider le cache
    accessCache.delete('ultra_fast_access');
    await checkAccess();
  };

  useEffect(() => {
    if (!hasChecked.current) {
      hasChecked.current = true;
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

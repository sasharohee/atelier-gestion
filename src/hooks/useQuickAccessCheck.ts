import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';

// Cache global pour la vérification rapide
const accessCache = new Map<string, { isActive: boolean; timestamp: number }>();
const CACHE_DURATION = 60000; // 1 minute

export const useQuickAccessCheck = () => {
  const [isAccessActive, setIsAccessActive] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const lastUserId = useRef<string | null>(null);

  const checkAccess = async () => {
    try {
      setLoading(true);

      // Récupérer l'utilisateur actuel
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        setIsAccessActive(false);
        setLoading(false);
        return;
      }

      // Vérifier le cache d'abord
      const cacheKey = user.id;
      const cached = accessCache.get(cacheKey);
      const now = Date.now();
      
      if (cached && (now - cached.timestamp) < CACHE_DURATION) {
        console.log(`⚡ Accès vérifié depuis le cache pour ${user.email}`);
        setIsAccessActive(cached.isActive);
        setLoading(false);
        return;
      }

      // Vérification rapide - seulement le champ is_active
      const { data, error } = await supabase
        .from('subscription_status')
        .select('is_active')
        .eq('user_id', user.id)
        .single();

      let isActive = false;

      if (error) {
        // Logique rapide pour les admins
        const userEmail = user.email?.toLowerCase();
        const isAdmin = userEmail === 'srohee32@gmail.com' || userEmail === 'repphonereparation@gmail.com';
        const userRole = user.user_metadata?.role || 'technician';
        isActive = isAdmin || userRole === 'admin';
      } else {
        isActive = data?.is_active || false;
      }

      // Mettre en cache le résultat
      accessCache.set(cacheKey, { isActive, timestamp: now });
      setIsAccessActive(isActive);
      
      console.log(`✅ Accès vérifié pour ${user.email}: ${isActive ? 'ACTIF' : 'RESTREINT'}`);
    } catch (err) {
      console.error('Erreur lors de la vérification rapide:', err);
      setIsAccessActive(false);
    } finally {
      setLoading(false);
    }
  };

  const refreshAccess = async () => {
    // Invalider le cache
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      accessCache.delete(user.id);
    }
    checkAccess();
  };

  useEffect(() => {
    checkAccess();
  }, []);

  return {
    isAccessActive,
    loading,
    refreshAccess
  };
};


import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { User } from '@supabase/supabase-js';

// Cache global pour l'authentification
const authCache = new Map<string, { user: User | null; timestamp: number }>();
const AUTH_CACHE_DURATION = 10000; // 10 secondes

export const useQuickAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const hasChecked = useRef(false);

  const checkAuth = async () => {
    try {
      setLoading(true);

      // Vérifier le cache d'abord
      const cached = authCache.get('current_user');
      const now = Date.now();
      
      if (cached && (now - cached.timestamp) < AUTH_CACHE_DURATION) {
        console.log('⚡ Utilisateur récupéré depuis le cache');
        setUser(cached.user);
        setIsAuthenticated(!!cached.user);
        setLoading(false);
        return;
      }

      // Vérification rapide de l'authentification
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error) {
        console.log('❌ Erreur d\'authentification:', error.message);
        setUser(null);
        setIsAuthenticated(false);
      } else {
        console.log('✅ Utilisateur authentifié:', user?.email);
        setUser(user);
        setIsAuthenticated(!!user);
      }

      // Mettre en cache le résultat
      authCache.set('current_user', { user, timestamp: now });

    } catch (err) {
      console.error('Erreur lors de la vérification d\'authentification:', err);
      setUser(null);
      setIsAuthenticated(false);
    } finally {
      setLoading(false);
    }
  };

  const refreshAuth = async () => {
    // Invalider le cache
    authCache.delete('current_user');
    await checkAuth();
  };

  useEffect(() => {
    if (!hasChecked.current) {
      hasChecked.current = true;
      checkAuth();
    }
  }, []);

  return {
    user,
    loading,
    isAuthenticated,
    refreshAuth
  };
};


import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { SubscriptionStatus } from '../types';

// Cache global pour éviter les requêtes répétées
const subscriptionCache = new Map<string, { data: SubscriptionStatus; timestamp: number }>();
const CACHE_DURATION = 30000; // 30 secondes

export const useSubscription = () => {
  const [subscriptionStatus, setSubscriptionStatus] = useState<SubscriptionStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);
  const lastUserId = useRef<string | null>(null);

  const checkSubscriptionStatus = async () => {
    try {
      setLoading(true);
      setError(null);

      // Récupérer l'utilisateur actuel
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        setError('Utilisateur non connecté');
        setLoading(false);
        return;
      }

      // Vérifier le cache d'abord
      const cacheKey = user.id;
      const cached = subscriptionCache.get(cacheKey);
      const now = Date.now();
      
      if (cached && (now - cached.timestamp) < CACHE_DURATION) {
        console.log(`⚡ Statut récupéré depuis le cache pour ${user.email}`);
        setSubscriptionStatus(cached.data);
        setLoading(false);
        return;
      }

      console.log(`🔍 Vérification du statut pour ${user.email}`);

      // Requête optimisée - seulement les champs nécessaires
      const { data, error: subscriptionError } = await supabase
        .from('subscription_status')
        .select('id, user_id, first_name, last_name, email, is_active, subscription_type, created_at, updated_at, notes')
        .eq('user_id', user.id)
        .maybeSingle(); // Utiliser maybeSingle() au lieu de single() pour éviter l'erreur PGRST116

      let finalStatus: SubscriptionStatus;

      if (subscriptionError) {
        console.log('❌ Erreur subscription_status:', subscriptionError);
        
        // Logique simplifiée pour les admins
        const userEmail = user.email?.toLowerCase();
        const isAdmin = userEmail === 'srohee32@gmail.com' || userEmail === 'repphonereparation@gmail.com';
        const userRole = user.user_metadata?.role || 'technician';
        
        // Créer un statut par défaut rapidement
        finalStatus = {
          id: `temp_${user.id}`,
          user_id: user.id,
          first_name: user.user_metadata?.firstName || user.user_metadata?.first_name || (isAdmin ? 'Admin' : 'Utilisateur'),
          last_name: user.user_metadata?.lastName || user.user_metadata?.lastName || '',
          email: user.email || '',
          is_active: isAdmin || userRole === 'admin',
          subscription_type: isAdmin || userRole === 'admin' ? 'premium' : 'free',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          notes: isAdmin 
            ? 'Administrateur - accès complet' 
            : 'Compte créé - en attente d\'activation par l\'administrateur'
        };

        console.log(`✅ Statut par défaut créé pour ${userEmail}: ${isAdmin ? 'ADMIN' : 'UTILISATEUR'}`);
      } else if (data) {
        // ✅ ENREGISTREMENT TROUVÉ DANS LA TABLE
        finalStatus = data;
        console.log(`✅ Statut récupéré depuis la table subscription_status: ${data.is_active ? 'ACTIF' : 'RESTREINT'}`);
      } else {
        // Aucune donnée trouvée, créer un statut par défaut
        const userEmail = user.email?.toLowerCase();
        const isAdmin = userEmail === 'srohee32@gmail.com' || userEmail === 'repphonereparation@gmail.com';
        const userRole = user.user_metadata?.role || 'technician';
        
        finalStatus = {
          id: `temp_${user.id}`,
          user_id: user.id,
          first_name: user.user_metadata?.firstName || user.user_metadata?.first_name || (isAdmin ? 'Admin' : 'Utilisateur'),
          last_name: user.user_metadata?.lastName || user.user_metadata?.lastName || '',
          email: user.email || '',
          is_active: isAdmin || userRole === 'admin',
          subscription_type: isAdmin || userRole === 'admin' ? 'premium' : 'free',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          notes: isAdmin 
            ? 'Administrateur - accès complet' 
            : 'Compte créé - en attente d\'activation par l\'administrateur'
        };
        console.log(`✅ Statut par défaut créé pour ${userEmail}: ${isAdmin ? 'ADMIN' : 'UTILISATEUR'}`);
      }

      // Mettre en cache le résultat
      subscriptionCache.set(cacheKey, { data: finalStatus, timestamp: now });
      setSubscriptionStatus(finalStatus);
    } catch (err) {
      setError('Erreur inattendue lors de la vérification du statut');
      console.error('💥 Exception useSubscription:', err);
    } finally {
      setLoading(false);
    }
  };

  // Fonction pour rafraîchir le statut
  const refreshStatus = async () => {
    console.log('🔄 Rafraîchissement du statut d\'abonnement...');
    
    // Invalider le cache pour forcer une nouvelle requête
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      subscriptionCache.delete(user.id);
    }
    
    setRefreshKey(prev => prev + 1); // Force le re-render
    checkSubscriptionStatus();
  };

  useEffect(() => {
    checkSubscriptionStatus();
  }, [refreshKey]);

  return {
    subscriptionStatus,
    loading,
    error,
    refreshStatus
  };
};

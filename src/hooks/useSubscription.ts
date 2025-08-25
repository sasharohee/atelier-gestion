import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { SubscriptionStatus } from '../types';

export const useSubscription = () => {
  const [subscriptionStatus, setSubscriptionStatus] = useState<SubscriptionStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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

      console.log(`🔍 Vérification du statut pour ${user.email}`);

      // ESSAYER D'ACCÉDER À LA VRAIE TABLE SUBSCRIPTION_STATUS
      const { data, error: subscriptionError } = await supabase
        .from('subscription_status')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (subscriptionError) {
        console.log('❌ Erreur subscription_status:', subscriptionError);
        
        // Si c'est une erreur 406 (permissions) ou PGRST116 (pas d'enregistrement)
        if (subscriptionError.code === '406' || subscriptionError.code === 'PGRST116') {
          console.log('⚠️ Utilisateur non trouvé dans subscription_status - Création d\'un statut par défaut');
          
          // Tenter de créer l'enregistrement dans subscription_status
          try {
            const userEmail = user.email?.toLowerCase();
            const isAdmin = userEmail === 'srohee32@gmail.com' || userEmail === 'repphonereparation@gmail.com';
            const userRole = user.user_metadata?.role || 'technician';
            
            const { data: insertData, error: insertError } = await supabase
              .from('subscription_status')
              .insert({
                user_id: user.id,
                first_name: user.user_metadata?.firstName || user.user_metadata?.first_name || (isAdmin ? 'Admin' : 'Utilisateur'),
                last_name: user.user_metadata?.lastName || user.user_metadata?.lastName || 'Test',
                email: user.email || '',
                is_active: isAdmin || userRole === 'admin',
                subscription_type: isAdmin || userRole === 'admin' ? 'premium' : 'free',
                notes: 'Compte créé automatiquement',
                status: isAdmin || userRole === 'admin' ? 'ACTIF' : 'INACTIF'
              })
              .select()
              .single();

            if (insertError) {
              console.log('⚠️ Erreur lors de la création du statut:', insertError);
              // Utiliser le système de fallback
              const defaultStatus: SubscriptionStatus = {
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

              setSubscriptionStatus(defaultStatus);
              console.log(`✅ Statut de fallback créé pour ${userEmail}: ${isAdmin ? 'ADMIN' : 'UTILISATEUR'}`);
            } else {
              // ✅ ENREGISTREMENT CRÉÉ AVEC SUCCÈS
              setSubscriptionStatus(insertData);
              console.log('✅ Statut créé avec succès dans subscription_status:', insertData);
              console.log(`📊 Statut actuel: ${insertData.is_active ? 'ACTIF' : 'RESTREINT'} - Type: ${insertData.subscription_type}`);
            }
          } catch (insertErr) {
            console.error('💥 Exception lors de la création du statut:', insertErr);
            // Utiliser le système de fallback en cas d'erreur
            const userEmail = user.email?.toLowerCase();
            const isAdmin = userEmail === 'srohee32@gmail.com' || userEmail === 'repphonereparation@gmail.com';
            const userRole = user.user_metadata?.role || 'technician';
            
            const defaultStatus: SubscriptionStatus = {
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

            setSubscriptionStatus(defaultStatus);
            console.log(`✅ Statut de fallback créé pour ${userEmail}: ${isAdmin ? 'ADMIN' : 'UTILISATEUR'}`);
          }
        } else {
          setError('Erreur lors de la récupération du statut d\'accès');
          console.error('❌ Erreur subscription_status:', subscriptionError);
        }
      } else {
        // ✅ ENREGISTREMENT TROUVÉ DANS LA TABLE - UTILISER LES DONNÉES RÉELLES
        setSubscriptionStatus(data);
        console.log('✅ Statut récupéré depuis la table subscription_status:', data);
        console.log(`📊 Statut actuel: ${data.is_active ? 'ACTIF' : 'RESTREINT'} - Type: ${data.subscription_type}`);
      }
    } catch (err) {
      setError('Erreur inattendue lors de la vérification du statut');
      console.error('💥 Exception useSubscription:', err);
    } finally {
      setLoading(false);
    }
  };

  // Fonction pour rafraîchir le statut
  const refreshStatus = () => {
    console.log('🔄 Rafraîchissement du statut d\'abonnement...');
    checkSubscriptionStatus();
  };

  useEffect(() => {
    checkSubscriptionStatus();
  }, []);

  return {
    subscriptionStatus,
    loading,
    error,
    refreshStatus
  };
};

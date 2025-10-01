import { useEffect, useState, useCallback } from 'react';
import { useAuth } from './useAuth';
import { useAppStore } from '../store';

export const useAuthenticatedData = () => {
  const { user, isAuthenticated } = useAuth();
  const [isDataLoaded, setIsDataLoaded] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const {
    loadUsers,
    loadClients,
    loadDevices,
    loadDeviceModels,
    loadServices,
    loadParts,
    loadProducts,
    loadRepairs,
    loadSales,
    loadAppointments,
  } = useAppStore();

  const loadData = useCallback(async () => {
    // Vérifier que l'utilisateur est authentifié
    if (!isAuthenticated || !user) {
      setIsDataLoaded(false);
      return;
    }

    console.log('✅ Chargement des données pour utilisateur:', user.email);
    setIsLoading(true);
    setError(null);

    try {
      // Chargement progressif par priorité
      // 1. Données essentielles (priorité haute)
      console.log('📊 Chargement des données essentielles...');
      await Promise.all([
        loadUsers(),
        loadClients(),
        loadDevices(),
      ]);

      // 2. Données secondaires (priorité moyenne)
      console.log('📋 Chargement des données secondaires...');
      await Promise.all([
        loadDeviceModels(),
        loadServices(),
        loadParts(),
      ]);

      // 3. Données volumineuses (priorité basse) - en arrière-plan
      console.log('📈 Chargement des données volumineuses...');
      Promise.all([
        loadProducts(),
        loadRepairs(),
        loadSales(),
        loadAppointments(),
      ]).then(() => {
        console.log('✅ Données volumineuses chargées en arrière-plan');
      }).catch(err => {
        console.warn('⚠️ Erreur lors du chargement des données volumineuses:', err);
      });

      setIsDataLoaded(true);
      console.log('✅ Données essentielles chargées avec succès');
    } catch (err) {
      console.error('❌ Erreur lors du chargement des données:', err);
      setError(err instanceof Error ? err : new Error('Erreur inconnue'));
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated, user, loadUsers, loadClients, loadDevices, loadDeviceModels, loadServices, loadParts, loadProducts, loadRepairs, loadSales, loadAppointments]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const reload = useCallback(() => {
    setIsDataLoaded(false);
    setError(null);
    loadData();
  }, [loadData]);

  return {
    isDataLoaded,
    isLoading,
    error,
    reload
  };
};

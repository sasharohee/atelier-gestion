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
      // Charger toutes les données en parallèle
      await Promise.all([
        loadUsers(),
        loadClients(),
        loadDevices(),
        loadDeviceModels(),
        loadServices(),
        loadParts(),
        loadProducts(),
        loadRepairs(),
        loadSales(),
        loadAppointments(),
      ]);

      setIsDataLoaded(true);
      console.log('✅ Données chargées avec succès');
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

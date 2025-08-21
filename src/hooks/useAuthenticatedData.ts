import { useEffect, useState } from 'react';
import { useAuth } from './useAuth';
import { useAppStore } from '../store';

export const useAuthenticatedData = () => {
  const { user, isAuthenticated } = useAuth();
  const [isDataLoaded, setIsDataLoaded] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const {
    loadClients,
    loadDevices,
    loadServices,
    loadParts,
    loadProducts,
    loadRepairs,
    loadSales,
    loadAppointments,
  } = useAppStore();

  useEffect(() => {
    const loadData = async () => {
      if (!isAuthenticated || !user) {
        setIsDataLoaded(false);
        return;
      }

      setIsLoading(true);
      setError(null);

      try {
        // Charger toutes les données en parallèle
        await Promise.all([
          loadClients(),
          loadDevices(),
          loadServices(),
          loadParts(),
          loadProducts(),
          loadRepairs(),
          loadSales(),
          loadAppointments(),
        ]);

        setIsDataLoaded(true);
      } catch (err) {
        console.error('Erreur lors du chargement des données:', err);
        setError(err instanceof Error ? err : new Error('Erreur inconnue'));
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [isAuthenticated, user, loadClients, loadDevices, loadServices, loadParts, loadProducts, loadRepairs, loadSales, loadAppointments]);

  return {
    isDataLoaded,
    isLoading,
    error,
    reload: () => {
      setIsDataLoaded(false);
      setError(null);
    }
  };
};

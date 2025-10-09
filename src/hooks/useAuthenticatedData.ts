import { useEffect, useState, useRef } from 'react';
import { useAuth } from './useAuth';
import { useAppStore } from '../store';

export const useAuthenticatedData = () => {
  const { user, isAuthenticated } = useAuth();
  const [isDataLoaded, setIsDataLoaded] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const hasLoadedOnce = useRef(false);
  const userIdRef = useRef<string | null>(null);

  useEffect(() => {
    // Vérifier que l'utilisateur est authentifié
    if (!isAuthenticated || !user) {
      setIsDataLoaded(false);
      hasLoadedOnce.current = false;
      userIdRef.current = null;
      return;
    }

    // Éviter de charger plusieurs fois pour le même utilisateur
    if (hasLoadedOnce.current && userIdRef.current === user.id) {
      return;
    }

    userIdRef.current = user.id;
    hasLoadedOnce.current = true;

    const loadData = async () => {
      console.log('✅ Chargement des données pour utilisateur:', user.email);
      setIsLoading(true);
      setError(null);

      // Obtenir les fonctions directement du store pour éviter les problèmes de dépendances
      const store = useAppStore.getState();

      try {
        // Chargement progressif par priorité
        // 1. Données essentielles (priorité haute)
        console.log('📊 Chargement des données essentielles...');
        await Promise.all([
          store.loadUsers(),
          store.loadClients(),
          store.loadDevices(),
        ]);

        // 2. Données secondaires (priorité moyenne)
        console.log('📋 Chargement des données secondaires...');
        await Promise.all([
          store.loadDeviceModels(),
          store.loadServices(),
          store.loadParts(),
        ]);

        // 3. Données volumineuses (priorité basse) - en arrière-plan
        console.log('📈 Chargement des données volumineuses...');
        Promise.all([
          store.loadProducts(),
          store.loadRepairs(),
          store.loadSales(),
          store.loadAppointments(),
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
        hasLoadedOnce.current = false; // Permettre de réessayer en cas d'erreur
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [isAuthenticated, user]);

  const reload = () => {
    hasLoadedOnce.current = false;
    setIsDataLoaded(false);
    setError(null);
    
    // Obtenir les fonctions directement du store
    const store = useAppStore.getState();
    
    const loadData = async () => {
      console.log('✅ Rechargement des données...');
      setIsLoading(true);
      setError(null);

      try {
        await Promise.all([
          store.loadUsers(),
          store.loadClients(),
          store.loadDevices(),
        ]);

        await Promise.all([
          store.loadDeviceModels(),
          store.loadServices(),
          store.loadParts(),
        ]);

        Promise.all([
          store.loadProducts(),
          store.loadRepairs(),
          store.loadSales(),
          store.loadAppointments(),
        ]).then(() => {
          console.log('✅ Données volumineuses rechargées');
        }).catch(err => {
          console.warn('⚠️ Erreur lors du rechargement des données volumineuses:', err);
        });

        setIsDataLoaded(true);
        hasLoadedOnce.current = true;
        console.log('✅ Rechargement terminé avec succès');
      } catch (err) {
        console.error('❌ Erreur lors du rechargement des données:', err);
        setError(err instanceof Error ? err : new Error('Erreur inconnue'));
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  };

  return {
    isDataLoaded,
    isLoading,
    error,
    reload
  };
};

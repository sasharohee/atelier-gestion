import { useState, useEffect, useCallback } from 'react';
import { supabase, testConnection, checkConnectionHealth } from '../lib/supabase';

export interface ConnectionStatus {
  isConnected: boolean;
  isLoading: boolean;
  error: string | null;
  health: {
    healthy: boolean;
    responseTime?: number;
    message?: string;
  } | null;
  lastChecked: Date | null;
}

export const useSupabaseConnection = () => {
  const [status, setStatus] = useState<ConnectionStatus>({
    isConnected: false,
    isLoading: true,
    error: null,
    health: null,
    lastChecked: null
  });

  const checkConnection = useCallback(async () => {
    try {
      setStatus(prev => ({ ...prev, isLoading: true, error: null }));
      
      const isConnected = await testConnection();
      
      if (isConnected) {
        const health = await checkConnectionHealth();
        setStatus({
          isConnected: true,
          isLoading: false,
          error: null,
          health,
          lastChecked: new Date()
        });
      } else {
        setStatus({
          isConnected: false,
          isLoading: false,
          error: 'Connexion échouée',
          health: null,
          lastChecked: new Date()
        });
      }
    } catch (error) {
      setStatus({
        isConnected: false,
        isLoading: false,
        error: error instanceof Error ? error.message : 'Erreur inconnue',
        health: null,
        lastChecked: new Date()
      });
    }
  }, []);

  // Vérification initiale
  useEffect(() => {
    checkConnection();
  }, [checkConnection]);

  // Vérification périodique (toutes les 30 secondes)
  useEffect(() => {
    const interval = setInterval(() => {
      if (!status.isLoading) {
        checkConnection();
      }
    }, 30000);

    return () => clearInterval(interval);
  }, [checkConnection, status.isLoading]);

  // Écouter les changements de connexion réseau
  useEffect(() => {
    const handleOnline = () => {
      console.log('🟢 Connexion réseau rétablie');
      checkConnection();
    };

    const handleOffline = () => {
      console.log('🔴 Connexion réseau perdue');
      setStatus(prev => ({
        ...prev,
        isConnected: false,
        error: 'Connexion réseau perdue'
      }));
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [checkConnection]);

  return {
    ...status,
    checkConnection,
    retry: checkConnection
  };
};

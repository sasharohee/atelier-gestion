import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';

export interface WorkshopSettings {
  name: string;
  address: string;
  phone: string;
  email: string;
  vatRate: string;
  currency: string;
}

const defaultSettings: WorkshopSettings = {
  name: 'Atelier de réparation',
  address: '123 Rue de la Paix, 75001 Paris',
  phone: '01 23 45 67 89',
  email: 'contact@atelier.fr',
  vatRate: '20',
  currency: 'EUR'
};

interface WorkshopSettingsContextType {
  workshopSettings: WorkshopSettings;
  isLoading: boolean;
  saveSettings: (newSettings: Partial<WorkshopSettings>) => boolean;
  loadSettings: () => void;
}

const WorkshopSettingsContext = createContext<WorkshopSettingsContextType | undefined>(undefined);

export const useWorkshopSettings = () => {
  const context = useContext(WorkshopSettingsContext);
  if (context === undefined) {
    throw new Error('useWorkshopSettings must be used within a WorkshopSettingsProvider');
  }
  return context;
};

interface WorkshopSettingsProviderProps {
  children: ReactNode;
}

export const WorkshopSettingsProvider: React.FC<WorkshopSettingsProviderProps> = ({ children }) => {
  const [workshopSettings, setWorkshopSettings] = useState<WorkshopSettings>(defaultSettings);
  const [isLoading, setIsLoading] = useState(true);

  // Charger les paramètres depuis localStorage
  const loadSettings = useCallback(() => {
    try {
      const savedSettings = localStorage.getItem('atelier-settings');
      if (savedSettings) {
        const parsed = JSON.parse(savedSettings);
        if (parsed.workshop) {
          setWorkshopSettings(parsed.workshop);
        }
      }
    } catch (error) {
      console.error('Erreur lors du chargement des paramètres de l\'atelier:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Sauvegarder les paramètres dans localStorage
  const saveSettings = useCallback((newSettings: Partial<WorkshopSettings>) => {
    try {
      const currentSettings = localStorage.getItem('atelier-settings');
      let parsedSettings = currentSettings ? JSON.parse(currentSettings) : {};
      
      // Mettre à jour les paramètres de l'atelier
      parsedSettings.workshop = {
        ...parsedSettings.workshop,
        ...newSettings
      };
      
      localStorage.setItem('atelier-settings', JSON.stringify(parsedSettings));
      
      // Mettre à jour l'état local
      setWorkshopSettings(prev => ({
        ...prev,
        ...newSettings
      }));

      // Déclencher un événement personnalisé pour notifier les autres composants
      window.dispatchEvent(new CustomEvent('workshopSettingsUpdated', {
        detail: { workshop: parsedSettings.workshop }
      }));

      return true;
    } catch (error) {
      console.error('Erreur lors de la sauvegarde des paramètres:', error);
      return false;
    }
  }, []);

  // Écouter les changements de paramètres
  useEffect(() => {
    loadSettings();

    // Écouter les événements de mise à jour
    const handleSettingsUpdate = (event: CustomEvent) => {
      if (event.detail?.workshop) {
        setWorkshopSettings(event.detail.workshop);
      }
    };

    // Écouter les changements de localStorage
    const handleStorageChange = (event: StorageEvent) => {
      if (event.key === 'atelier-settings') {
        loadSettings();
      }
    };

    window.addEventListener('workshopSettingsUpdated', handleSettingsUpdate as EventListener);
    window.addEventListener('storage', handleStorageChange);

    return () => {
      window.removeEventListener('workshopSettingsUpdated', handleSettingsUpdate as EventListener);
      window.removeEventListener('storage', handleStorageChange);
    };
  }, [loadSettings]);

  const value = {
    workshopSettings,
    isLoading,
    saveSettings,
    loadSettings
  };

  return (
    <WorkshopSettingsContext.Provider value={value}>
      {children}
    </WorkshopSettingsContext.Provider>
  );
};

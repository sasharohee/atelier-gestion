import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import { systemSettingsService } from '../services/supabaseService';

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
  phone: '07 59 23 91 70',
  email: 'contact.ateliergestion@gmail.com',
  vatRate: '20',
  currency: 'EUR'
};

interface WorkshopSettingsContextType {
  workshopSettings: WorkshopSettings;
  isLoading: boolean;
  saveSettings: (newSettings: Partial<WorkshopSettings>) => Promise<boolean>;
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

  // Charger les paramètres depuis la base de données
  const loadSettings = useCallback(async () => {
    try {
      setIsLoading(true);
      const result = await systemSettingsService.getAll();
      
      if (result.success && 'data' in result && result.data) {
        const newSettings = { ...defaultSettings };
        
        // Mettre à jour les paramètres de l'atelier depuis la base de données
        result.data.forEach(setting => {
          switch (setting.key) {
            case 'workshop_name':
              newSettings.name = setting.value;
              break;
            case 'workshop_address':
              newSettings.address = setting.value;
              break;
            case 'workshop_phone':
              newSettings.phone = setting.value;
              break;
            case 'workshop_email':
              newSettings.email = setting.value;
              break;
            case 'vat_rate':
              newSettings.vatRate = setting.value;
              break;
            case 'currency':
              newSettings.currency = setting.value;
              break;
          }
        });
        
        setWorkshopSettings(newSettings);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des paramètres de l\'atelier:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Sauvegarder les paramètres dans la base de données
  const saveSettings = useCallback(async (newSettings: Partial<WorkshopSettings>) => {
    try {
      setIsLoading(true);
      
      // Préparer les paramètres à sauvegarder
      const settingsToUpdate = [];
      
      if (newSettings.name !== undefined) {
        settingsToUpdate.push({ key: 'workshop_name', value: newSettings.name });
      }
      if (newSettings.address !== undefined) {
        settingsToUpdate.push({ key: 'workshop_address', value: newSettings.address });
      }
      if (newSettings.phone !== undefined) {
        settingsToUpdate.push({ key: 'workshop_phone', value: newSettings.phone });
      }
      if (newSettings.email !== undefined) {
        settingsToUpdate.push({ key: 'workshop_email', value: newSettings.email });
      }
      if (newSettings.vatRate !== undefined) {
        settingsToUpdate.push({ key: 'vat_rate', value: newSettings.vatRate });
      }
      if (newSettings.currency !== undefined) {
        settingsToUpdate.push({ key: 'currency', value: newSettings.currency });
      }

      // Sauvegarder dans la base de données
      if (settingsToUpdate.length > 0) {
        const result = await systemSettingsService.updateMultiple(settingsToUpdate);
        if (!result.success) {
          throw new Error('Erreur lors de la sauvegarde');
        }
      }
      
      // Mettre à jour l'état local
      setWorkshopSettings(prev => ({
        ...prev,
        ...newSettings
      }));

      // Déclencher un événement personnalisé pour notifier les autres composants
      window.dispatchEvent(new CustomEvent('workshopSettingsUpdated', {
        detail: { workshop: { ...workshopSettings, ...newSettings } }
      }));

      return true;
    } catch (error) {
      console.error('Erreur lors de la sauvegarde des paramètres:', error);
      return false;
    } finally {
      setIsLoading(false);
    }
  }, [workshopSettings]);

  // Charger les paramètres au montage
  useEffect(() => {
    loadSettings();
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

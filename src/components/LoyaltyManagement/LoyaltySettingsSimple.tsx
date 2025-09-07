import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  Button,
  Card,
  CardContent,
  Grid,
  Alert,
  CircularProgress,
  Divider,
  Switch,
  FormControlLabel,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  IconButton,
  Tooltip
} from '@mui/material';
import {
  Save as SaveIcon,
  Refresh as RefreshIcon,
  Settings as SettingsIcon,
  Star as StarIcon,
  TrendingUp as TrendingUpIcon,
  ExpandMore as ExpandMoreIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon
} from '@mui/icons-material';
import { supabase } from '../../lib/supabase';

interface LoyaltyConfig {
  key: string;
  value: string;
  description: string;
}

interface LoyaltyTier {
  id: string;
  name: string;
  description: string;
  points_required: number;
  discount_percentage: number;
  color: string;
  benefits: string[];
  is_active: boolean;
}

interface LoyaltySettingsProps {
  onDataChanged?: () => void; // Callback pour notifier les changements
}

const LoyaltySettingsSimple: React.FC<LoyaltySettingsProps> = ({ onDataChanged }) => {
  // États pour les données
  const [config, setConfig] = useState<LoyaltyConfig[]>([]);
  const [tiers, setTiers] = useState<LoyaltyTier[]>([]);
  
  // États pour l'interface
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  
  // États pour l'édition
  const [editingConfig, setEditingConfig] = useState<Record<string, string>>({});
  const [editingTiers, setEditingTiers] = useState<Record<string, Partial<LoyaltyTier>>>({});

  // Charger les données au montage du composant
  useEffect(() => {
    loadData();
  }, []);

  // Fonction pour sauvegarder les données localement
  const saveToLocalStorage = (tiersData: LoyaltyTier[]) => {
    try {
      localStorage.setItem('loyalty_tiers_backup', JSON.stringify(tiersData));
      console.log('💾 Données sauvegardées localement');
    } catch (error) {
      console.error('❌ Erreur sauvegarde locale:', error);
    }
  };

  // Fonction pour charger les données depuis le localStorage
  const loadFromLocalStorage = (): LoyaltyTier[] => {
    try {
      const saved = localStorage.getItem('loyalty_tiers_backup');
      if (saved) {
        const parsed = JSON.parse(saved);
        console.log('📂 Données chargées depuis le localStorage:', parsed);
        return parsed;
      }
    } catch (error) {
      console.error('❌ Erreur chargement local:', error);
    }
    return [];
  };

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('🔄 Chargement des données de fidélité...');

      // Récupérer l'utilisateur actuel
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }

      // Charger la configuration avec isolation par atelier
      let configData = null;
      try {
        console.log('🔍 Chargement de la configuration avec isolation par atelier...');
        
        // Utiliser la fonction isolée par atelier
        const { data, error: configError } = await supabase.rpc('get_workshop_loyalty_config');

        if (configError) {
          console.warn('⚠️ Erreur lors du chargement de la config isolée:', configError.message);
          console.log('🔄 Tentative de chargement direct depuis la table...');
          
          // Fallback: charger directement depuis la table (avec isolation RLS)
          const { data: fallbackData, error: fallbackError } = await supabase
            .from('loyalty_config')
            .select('*')
            .order('key');

          if (fallbackError) {
            console.warn('⚠️ Erreur lors du chargement direct:', fallbackError.message);
            // Utiliser des valeurs par défaut si la table est vide ou erreur
            configData = [
              { key: 'points_per_euro', value: '1', description: 'Points gagnés par euro dépensé' },
              { key: 'minimum_purchase', value: '10', description: 'Montant minimum pour gagner des points' },
              { key: 'bonus_threshold', value: '100', description: 'Seuil pour bonus de points' },
              { key: 'bonus_multiplier', value: '1.5', description: 'Multiplicateur de bonus' },
              { key: 'points_expiry_days', value: '365', description: 'Durée de validité des points en jours' },
              { key: 'auto_tier_upgrade', value: 'true', description: 'Mise à jour automatique des niveaux de fidélité' }
            ];
          } else {
            configData = fallbackData;
          }
        } else if (!data || data.length === 0) {
          console.log('📝 Aucune configuration trouvée pour cet atelier, utilisation des valeurs par défaut');
          configData = [
            { key: 'points_per_euro', value: '1', description: 'Points gagnés par euro dépensé' },
            { key: 'minimum_purchase', value: '10', description: 'Montant minimum pour gagner des points' },
            { key: 'bonus_threshold', value: '100', description: 'Seuil pour bonus de points' },
            { key: 'bonus_multiplier', value: '1.5', description: 'Multiplicateur de bonus' },
            { key: 'points_expiry_days', value: '365', description: 'Durée de validité des points en jours' },
            { key: 'auto_tier_upgrade', value: 'true', description: 'Mise à jour automatique des niveaux de fidélité' }
          ];
        } else {
          configData = data;
          console.log('✅ Configuration chargée avec isolation par atelier:', data.length);
        }
      } catch (error) {
        console.warn('⚠️ Erreur lors du chargement de la config, utilisation des valeurs par défaut:', error);
        // Valeurs par défaut en cas d'erreur
        configData = [
          { key: 'points_per_euro', value: '1', description: 'Points gagnés par euro dépensé' },
          { key: 'minimum_purchase', value: '10', description: 'Montant minimum pour gagner des points' },
          { key: 'bonus_threshold', value: '100', description: 'Seuil pour bonus de points' },
          { key: 'bonus_multiplier', value: '1.5', description: 'Multiplicateur de bonus' },
          { key: 'points_expiry_days', value: '365', description: 'Durée de validité des points en jours' },
          { key: 'auto_tier_upgrade', value: 'true', description: 'Mise à jour automatique des niveaux de fidélité' }
        ];
      }

      // Nettoyer les doublons et trier par clé
      const cleanConfigData = configData ? configData
        .filter((item, index, self) => 
          index === self.findIndex(t => t.key === item.key)
        )
        .sort((a, b) => a.key.localeCompare(b.key)) : [];

      console.log('✅ Configuration chargée:', cleanConfigData);
      setConfig(cleanConfigData);

      // Charger les niveaux de fidélité avec isolation par atelier
      let tiersData = null;
      try {
        console.log('🔍 Chargement des niveaux avec isolation par atelier...');
        
        // Utiliser la fonction isolée par atelier
        const { data, error: tiersError } = await supabase.rpc('get_workshop_loyalty_tiers');

        if (tiersError) {
          console.warn('⚠️ Erreur lors du chargement des tiers isolés:', tiersError.message);
          console.log('🔄 Tentative de chargement direct depuis la table...');
          
          // Fallback: charger directement depuis la table (avec isolation RLS)
          const { data: fallbackData, error: fallbackError } = await supabase
            .from('loyalty_tiers_advanced')
            .select('*')
            .order('points_required');

          if (fallbackError) {
            console.warn('⚠️ Erreur lors du chargement direct:', fallbackError.message);
            // Utiliser des valeurs par défaut si la table est vide ou erreur
            tiersData = [];
          } else {
            tiersData = fallbackData;
          }
        } else if (!data || data.length === 0) {
          console.log('📝 Aucun niveau trouvé pour cet atelier, création des niveaux par défaut...');
          // Créer les niveaux par défaut directement en base
          try {
            await createDefaultTiers();
            // Recharger les données après création
            const { data: newData, error: newError } = await supabase.rpc('get_workshop_loyalty_tiers');
            if (newError) {
              console.warn('⚠️ Erreur lors du rechargement après création:', newError.message);
              tiersData = [];
            } else {
              tiersData = newData || [];
              console.log('✅ Niveaux créés et rechargés:', tiersData.length);
            }
          } catch (createError) {
            console.warn('⚠️ Erreur lors de la création des niveaux:', createError);
            tiersData = [];
          }
        } else {
          tiersData = data;
          console.log('✅ Niveaux chargés avec isolation par atelier:', data.length);
          // Sauvegarder en local pour backup
          saveToLocalStorage(data);
        }
      } catch (error) {
        console.warn('⚠️ Erreur lors du chargement des tiers:', error);
        // Pas de valeurs par défaut en cas d'erreur
        tiersData = [];
      }
      
      // Filtrer les doublons côté client si nécessaire
      const uniqueTiers = tiersData ? tiersData.filter((tier: any, index: number, self: any[]) => 
        index === self.findIndex((t: any) => t.name === tier.name)
      ) : [];

      console.log('✅ Niveaux chargés:', uniqueTiers);
      setTiers(uniqueTiers);

    } catch (err: any) {
      console.error('❌ Erreur lors du chargement:', err);
      setError(`Erreur de chargement: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleConfigChange = (key: string, value: string) => {
    console.log('📝 Modification config:', key, value);
    setEditingConfig(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const handleTierChange = (tierId: string, field: keyof LoyaltyTier, value: any) => {
    console.log('📝 Modification tier:', tierId, field, value);
    console.log('📊 Type de valeur:', typeof value, 'Valeur:', value);
    
    // Trouver le tier original pour comparer
    const originalTier = tiers.find(tier => tier.id === tierId);
    if (!originalTier) {
      console.warn(`⚠️ Tier ${tierId} non trouvé`);
      return;
    }
    
    // Vérifier si la valeur a vraiment changé
    const originalValue = originalTier[field];
    if (originalValue === value) {
      console.log(`📝 Valeur identique pour ${field}, suppression de la modification`);
      setEditingTiers(prev => {
        const newState = { ...prev };
        if (newState[tierId]) {
          delete newState[tierId][field];
          // Si plus aucune modification pour ce tier, supprimer l'entrée
          if (Object.keys(newState[tierId]).length === 0) {
            delete newState[tierId];
          }
        }
        console.log('🔄 État editingTiers après suppression:', newState);
        return newState;
      });
      return;
    }
    
    setEditingTiers(prev => {
      const newState = {
        ...prev,
        [tierId]: {
          ...prev[tierId],
          [field]: value
        }
      };
      console.log('🔄 Nouvel état editingTiers:', newState);
      return newState;
    });
  };

  const saveConfig = async () => {
    try {
      setSaving(true);
      setError(null);
      console.log('💾 Sauvegarde de la configuration...');

      const updates = Object.entries(editingConfig).map(([key, value]) => ({
        key,
        value,
        updated_at: new Date().toISOString()
      }));

      for (const update of updates) {
        // Essayer d'abord de mettre à jour
        const { error: updateError } = await supabase
          .from('loyalty_config')
          .update(update)
          .eq('key', update.key);

        // Si la mise à jour échoue (probablement parce que la ligne n'existe pas), essayer d'insérer
        if (updateError) {
          console.log(`📝 Création de la configuration ${update.key} car elle n'existe pas`);
          
          // Trouver la description correspondante
          const configItem = config.find(item => item.key === update.key);
          const description = configItem ? configItem.description : `Configuration pour ${update.key}`;
          
          const { error: insertError } = await supabase
            .from('loyalty_config')
            .insert({
              key: update.key,
              value: update.value,
              description: description,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString()
            });

          if (insertError) {
            console.error('❌ Erreur insertion:', insertError);
            throw insertError;
          }
        }
      }

      // Mettre à jour l'état local
      setConfig(prev => prev.map(item => 
        editingConfig[item.key] 
          ? { ...item, value: editingConfig[item.key] }
          : item
      ));

      setEditingConfig({});
      setSuccess('✅ Configuration sauvegardée avec succès !');
      console.log('✅ Configuration sauvegardée');
      
      setTimeout(() => setSuccess(null), 3000);

    } catch (err: any) {
      console.error('❌ Erreur sauvegarde config:', err);
      setError(`Erreur de sauvegarde: ${err.message}`);
    } finally {
      setSaving(false);
    }
  };

  const saveTiers = async () => {
    try {
      setSaving(true);
      setError(null);
      console.log('💾 Sauvegarde des niveaux...');
      console.log('📝 Modifications à sauvegarder:', editingTiers);

      // Si aucun niveau n'existe, les créer d'abord
      if (tiers.length === 0) {
        console.log('🆕 Aucun niveau, création des niveaux par défaut...');
        await createDefaultTiers();
        return;
      }

      // Mettre à jour l'état local avec les modifications
      const updatedTiers = tiers.map(tier => 
        editingTiers[tier.id] 
          ? { ...tier, ...editingTiers[tier.id] }
          : tier
      );
      
      console.log('📊 Niveaux mis à jour:', updatedTiers);
      
      // Sauvegarder en localStorage d'abord
      saveToLocalStorage(updatedTiers);
      
      // Mettre à jour l'état local
      setTiers(updatedTiers);
      
      // Essayer de sauvegarder en base de données avec une approche plus robuste
      let dbSuccessCount = 0;
      let dbErrorCount = 0;
      
      // Sauvegarder une copie des modifications avant de les vider
      const modificationsToSave = { ...editingTiers };
      
      for (const [id, updates] of Object.entries(modificationsToSave)) {
        try {
          const tierData = tiers.find(tier => tier.id === id);
          if (!tierData) {
            console.warn(`⚠️ Tier ${id} non trouvé dans les données locales`);
            continue;
          }

          // Préparer les données de mise à jour
          const updateData = {
            name: tierData.name,
            description: updates.description !== undefined ? updates.description : tierData.description,
            points_required: updates.points_required !== undefined ? Number(updates.points_required) : tierData.points_required,
            discount_percentage: updates.discount_percentage !== undefined ? Number(updates.discount_percentage) : tierData.discount_percentage,
            color: tierData.color,
            is_active: updates.is_active !== undefined ? updates.is_active : tierData.is_active,
            updated_at: new Date().toISOString()
          };
          
          console.log(`🔄 Sauvegarde tier ${tierData.name}:`, updateData);
          
          // Essayer d'abord une mise à jour
          const { data: updateResult, error: updateError } = await supabase
            .from('loyalty_tiers_advanced')
            .update(updateData)
            .eq('id', id)
            .select();

          if (updateError) {
            console.warn(`⚠️ Erreur mise à jour ${id}:`, updateError);
            
            // Si la mise à jour échoue, essayer un insert
            const { data: insertResult, error: insertError } = await supabase
              .from('loyalty_tiers_advanced')
              .insert({
                id: id,
                ...updateData,
                created_at: new Date().toISOString()
              })
              .select();

            if (insertError) {
              console.error(`❌ Erreur insertion ${id}:`, insertError);
              dbErrorCount++;
            } else {
              console.log(`✅ Tier ${id} inséré avec succès`);
              dbSuccessCount++;
            }
          } else {
            console.log(`✅ Tier ${id} mis à jour avec succès`);
            dbSuccessCount++;
          }
        } catch (err) {
          console.error(`❌ Exception sauvegarde ${id}:`, err);
          dbErrorCount++;
        }
      }

      // Vider les modifications après la sauvegarde
      setEditingTiers({});
      
      // Afficher le résultat
      if (dbSuccessCount > 0 && dbErrorCount === 0) {
        setSuccess(`✅ Tous les niveaux sauvegardés avec succès ! (${dbSuccessCount} en base + local)`);
      } else if (dbSuccessCount > 0 && dbErrorCount > 0) {
        setSuccess(`✅ Niveaux partiellement sauvegardés ! (${dbSuccessCount} en base, ${dbErrorCount} erreurs + local)`);
      } else if (dbErrorCount > 0) {
        setError(`⚠️ Erreurs de sauvegarde en base (${dbErrorCount} erreurs), mais sauvegardé localement`);
      } else {
        setSuccess('✅ Niveaux sauvegardés localement !');
      }
      
      console.log('✅ Sauvegarde terminée');
      
      // Notifier la page parent des changements
      if (onDataChanged) {
        console.log('🔄 Notification de changement envoyée à la page parent');
        onDataChanged();
      }

    } catch (err: any) {
      console.error('❌ Erreur sauvegarde tiers:', err);
      setError(`Erreur de sauvegarde: ${err.message}`);
    } finally {
      setSaving(false);
    }
  };

  const cleanupDuplicates = async () => {
    try {
      setSaving(true);
      setError(null);
      console.log('🧹 Nettoyage des doublons...');

      // Récupérer toutes les configurations
      const { data: allConfigs, error: fetchError } = await supabase
        .from('loyalty_config')
        .select('*')
        .order('key');

      if (fetchError) {
        throw fetchError;
      }

      if (!allConfigs || allConfigs.length === 0) {
        setSuccess('✅ Aucune configuration à nettoyer');
        return;
      }

      // Identifier les doublons
      const duplicates = allConfigs.reduce((acc, config) => {
        if (!acc[config.key]) {
          acc[config.key] = [];
        }
        acc[config.key].push(config);
        return acc;
      }, {} as Record<string, any[]>);

      const keysToClean = Object.keys(duplicates).filter(key => duplicates[key].length > 1);
      
      if (keysToClean.length === 0) {
        setSuccess('✅ Aucun doublon trouvé');
        return;
      }

      console.log(`🧹 ${keysToClean.length} clés avec doublons trouvées:`, keysToClean);

      // Supprimer les doublons en gardant seulement le plus récent
      for (const key of keysToClean) {
        const configs = duplicates[key];
        const sortedConfigs = configs.sort((a, b) => 
          new Date(b.updated_at || b.created_at).getTime() - new Date(a.updated_at || a.created_at).getTime()
        );
        
        // Garder le premier (le plus récent) et supprimer les autres
        const toKeep = sortedConfigs[0];
        const toDelete = sortedConfigs.slice(1);

        for (const configToDelete of toDelete) {
          const { error: deleteError } = await supabase
            .from('loyalty_config')
            .delete()
            .eq('id', configToDelete.id);

          if (deleteError) {
            console.warn(`⚠️ Erreur suppression doublon ${configToDelete.id}:`, deleteError);
          }
        }
      }

      setSuccess(`✅ ${keysToClean.length} doublons supprimés avec succès !`);
      console.log('✅ Nettoyage terminé');
      
      // Recharger les données
      setTimeout(() => {
        loadData();
        setSuccess(null);
      }, 2000);

    } catch (err: any) {
      console.error('❌ Erreur nettoyage:', err);
      setError(`Erreur de nettoyage: ${err.message}`);
    } finally {
      setSaving(false);
    }
  };

  const createDefaultTiers = async () => {
    try {
      setSaving(true);
      setError(null);
      console.log('🌟 Création des niveaux par défaut pour cet atelier...');

      // Récupérer l'utilisateur actuel
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }

      // Utiliser la fonction de création par défaut pour l'atelier
      const { data: createResult, error: createError } = await supabase.rpc(
        'create_default_loyalty_tiers_for_workshop',
        { p_workshop_id: user.id }
      );

      if (createError) {
        console.warn('⚠️ Erreur lors de la création avec la fonction:', createError.message);
        console.log('🔄 Tentative de création manuelle...');
        
        // Fallback: création manuelle
        const defaultTiers = [
          { name: 'Bronze', points_required: 0, discount_percentage: 0.00, color: '#CD7F32', description: 'Niveau de base', is_active: true },
          { name: 'Argent', points_required: 100, discount_percentage: 5.00, color: '#C0C0C0', description: '5% de réduction', is_active: true },
          { name: 'Or', points_required: 500, discount_percentage: 10.00, color: '#FFD700', description: '10% de réduction', is_active: true },
          { name: 'Platine', points_required: 1000, discount_percentage: 15.00, color: '#E5E4E2', description: '15% de réduction', is_active: true },
          { name: 'Diamant', points_required: 2000, discount_percentage: 20.00, color: '#B9F2FF', description: '20% de réduction', is_active: true }
        ];

        let successCount = 0;
        let errorCount = 0;
        
        for (const tier of defaultTiers) {
          try {
            console.log(`🔄 Création tier ${tier.name}...`);
            
            const { error: insertError } = await supabase
              .from('loyalty_tiers_advanced')
              .insert({
                name: tier.name,
                description: tier.description,
                points_required: tier.points_required,
                discount_percentage: tier.discount_percentage,
                color: tier.color,
                is_active: tier.is_active,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              })
              .select();

            if (insertError) {
              console.error(`❌ Erreur insertion ${tier.name}:`, insertError);
              errorCount++;
            } else {
              console.log(`✅ ${tier.name} inséré avec succès`);
              successCount++;
            }
          } catch (err) {
            console.error(`❌ Exception création ${tier.name}:`, err);
            errorCount++;
          }
        }

        // Afficher le résultat
        if (successCount > 0 && errorCount === 0) {
          setSuccess(`✅ Tous les niveaux créés avec succès ! (${successCount} en base)`);
        } else if (successCount > 0 && errorCount > 0) {
          setSuccess(`✅ Niveaux partiellement créés ! (${successCount} en base, ${errorCount} erreurs)`);
        } else if (errorCount > 0) {
          setError(`⚠️ Erreurs de création en base (${errorCount} erreurs)`);
        }
      } else if (createResult?.success) {
        console.log('✅ Niveaux créés avec la fonction:', createResult);
        setSuccess(`✅ ${createResult.message} (${createResult.tiers_created} niveaux créés)`);
      } else {
        console.error('❌ Erreur dans la réponse de création:', createResult?.error);
        setError(`Erreur de création: ${createResult?.error || 'Erreur inconnue'}`);
      }
      
      console.log('✅ Niveaux créés et sauvegardés');
      
      // Recharger les données pour afficher les nouveaux niveaux
      setTimeout(() => {
        loadData();
      }, 1000);
      
      // Notifier la page parent des changements
      if (onDataChanged) {
        console.log('🔄 Notification de changement envoyée à la page parent');
        onDataChanged();
      }

    } catch (err: any) {
      console.error('❌ Erreur création niveaux:', err);
      setError(`Erreur de création: ${err.message}`);
    } finally {
      setSaving(false);
    }
  };

  const initializeDefaultData = async () => {
    try {
      setSaving(true);
      setError(null);
      console.log('🚀 Initialisation des données par défaut...');

      // Récupérer l'utilisateur actuel
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }

      // Créer les configurations par défaut
      const defaultConfigs = [
        { key: 'points_per_euro', value: '1', description: 'Points gagnés par euro dépensé' },
        { key: 'minimum_purchase', value: '10', description: 'Montant minimum pour gagner des points' },
        { key: 'bonus_threshold', value: '100', description: 'Seuil pour bonus de points' },
        { key: 'bonus_multiplier', value: '1.5', description: 'Multiplicateur de bonus' },
        { key: 'points_expiry_days', value: '365', description: 'Durée de validité des points en jours' },
        { key: 'auto_tier_upgrade', value: 'true', description: 'Mise à jour automatique des niveaux de fidélité' }
      ];

      for (const configItem of defaultConfigs) {
        const { error } = await supabase
          .from('loyalty_config')
          .upsert({
            key: configItem.key,
            value: configItem.value,
            description: configItem.description,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });

        if (error) {
          console.warn(`⚠️ Erreur lors de la création de la config ${configItem.key}:`, error);
        }
      }

      // Créer les niveaux par défaut
      const defaultTiers = [
        { name: 'Bronze', points_required: 0, discount_percentage: 0.00, color: '#CD7F32', description: 'Niveau de base', is_active: true },
        { name: 'Argent', points_required: 100, discount_percentage: 5.00, color: '#C0C0C0', description: '5% de réduction', is_active: true },
        { name: 'Or', points_required: 500, discount_percentage: 10.00, color: '#FFD700', description: '10% de réduction', is_active: true },
        { name: 'Platine', points_required: 1000, discount_percentage: 15.00, color: '#E5E4E2', description: '15% de réduction', is_active: true },
        { name: 'Diamant', points_required: 2000, discount_percentage: 20.00, color: '#B9F2FF', description: '20% de réduction', is_active: true }
      ];

      for (const tier of defaultTiers) {
        const { error } = await supabase
          .from('loyalty_tiers_advanced')
          .insert({
            name: tier.name,
            description: tier.description,
            points_required: tier.points_required,
            discount_percentage: tier.discount_percentage,
            color: tier.color,
            is_active: tier.is_active,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });

        if (error) {
          console.warn(`⚠️ Erreur lors de la création du niveau ${tier.name}:`, error);
        } else {
          console.log(`✅ Niveau ${tier.name} créé avec succès`);
        }
      }

      setSuccess('✅ Données par défaut initialisées avec succès !');
      console.log('✅ Données par défaut initialisées');
      
      // Recharger les données
      setTimeout(() => {
        loadData();
        setSuccess(null);
        // Notifier la page parent des changements
        if (onDataChanged) {
          console.log('🔄 Notification de changement envoyée à la page parent');
          onDataChanged();
        }
      }, 2000);

    } catch (err: any) {
      console.error('❌ Erreur initialisation:', err);
      setError(`Erreur d'initialisation: ${err.message}`);
    } finally {
      setSaving(false);
    }
  };

  const hasConfigChanges = Object.keys(editingConfig).length > 0;
  const hasTierChanges = Object.keys(editingTiers).length > 0;

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 200 }}>
        <CircularProgress />
        <Typography sx={{ ml: 2 }}>Chargement des paramètres...</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" gutterBottom>
          ⚙️ Paramètres du Système de Fidélité
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Personnalisez le système de fidélité selon vos préférences et votre stratégie commerciale
        </Typography>
      </Box>

      {/* Messages d'erreur et de succès */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 3 }}>
          {success}
        </Alert>
      )}

      {/* Boutons d'action */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={saveConfig}
          disabled={saving || !hasConfigChanges}
          color="primary"
        >
          {saving ? 'Sauvegarde...' : 'Sauvegarder Configuration'}
        </Button>

        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={saveTiers}
          disabled={saving || !hasTierChanges}
          color="secondary"
        >
          {saving ? 'Sauvegarde...' : `Sauvegarder Niveaux${hasTierChanges ? ` (${Object.keys(editingTiers).length} modifié${Object.keys(editingTiers).length > 1 ? 's' : ''})` : ''}`}
        </Button>

        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadData}
          disabled={saving}
        >
          Actualiser
        </Button>

        {(config.length === 0 || tiers.length === 0) && (
          <Button
            variant="outlined"
            startIcon={<CheckCircleIcon />}
            onClick={initializeDefaultData}
            disabled={saving}
            color="success"
          >
            Initialiser les Données
          </Button>
        )}

        {config.length > 6 && (
          <Button
            variant="outlined"
            startIcon={<WarningIcon />}
            onClick={cleanupDuplicates}
            disabled={saving}
            color="warning"
          >
            Nettoyer les Doublons
          </Button>
        )}

        {tiers.length === 0 && (
          <Button
            variant="contained"
            startIcon={<StarIcon />}
            onClick={createDefaultTiers}
            disabled={saving}
            color="primary"
          >
            Créer les Niveaux
          </Button>
        )}

        {tiers.length > 0 && (
          <Button
            variant="outlined"
            startIcon={<StarIcon />}
            onClick={createDefaultTiers}
            disabled={saving}
            color="secondary"
          >
            Recréer les Niveaux
          </Button>
        )}
      </Box>

      {/* Configuration Générale */}
      <Accordion defaultExpanded>
        <AccordionSummary expandIcon={<ExpandMoreIcon />}>
          <SettingsIcon sx={{ mr: 1 }} />
          <Typography variant="h6">Configuration Générale</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Alert severity="info" sx={{ mb: 2 }}>
            <Typography variant="body2">
              <strong>Configuration du système de fidélité :</strong><br/>
              • <strong>Points par euro :</strong> Nombre de points gagnés pour chaque euro dépensé<br/>
              • <strong>Montant minimum :</strong> Montant minimum d'achat pour gagner des points<br/>
              • <strong>Seuil bonus :</strong> Montant à partir duquel le multiplicateur s'applique<br/>
              • <strong>Multiplicateur :</strong> Facteur de bonus pour les gros achats<br/>
              • <strong>Durée de validité :</strong> Nombre de jours avant expiration des points<br/>
              • <strong>Mise à jour automatique :</strong> Active la progression automatique des niveaux
            </Typography>
          </Alert>
          <Grid container spacing={3}>
            {config.map((item) => (
              <Grid item xs={12} sm={6} key={item.key}>
                <TextField
                  fullWidth
                  label={item.description}
                  value={editingConfig[item.key] !== undefined ? editingConfig[item.key] : item.value}
                  onChange={(e) => handleConfigChange(item.key, e.target.value)}
                  variant="outlined"
                  type={item.key.includes('multiplier') || item.key.includes('threshold') || item.key.includes('days') ? 'number' : 'text'}
                  inputProps={{
                    min: item.key.includes('multiplier') ? 0.1 : item.key.includes('days') ? 1 : 0,
                    max: item.key.includes('multiplier') ? 10 : item.key.includes('days') ? 3650 : undefined,
                    step: item.key.includes('multiplier') ? 0.1 : 1
                  }}
                />
              </Grid>
            ))}
          </Grid>
        </AccordionDetails>
      </Accordion>

      {/* Niveaux de Fidélité */}
      <Accordion defaultExpanded sx={{ mt: 2 }}>
        <AccordionSummary expandIcon={<ExpandMoreIcon />}>
          <StarIcon sx={{ mr: 1 }} />
          <Typography variant="h6">Niveaux de Fidélité</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Alert severity="info" sx={{ mb: 2 }}>
            <Typography variant="body2">
              <strong>Niveaux de fidélité :</strong><br/>
              • <strong>Points requis :</strong> Nombre de points nécessaires pour atteindre ce niveau<br/>
              • <strong>Réduction :</strong> Pourcentage de réduction accordé aux clients de ce niveau<br/>
              • <strong>Description :</strong> Explication du niveau pour vos clients<br/>
              • <strong>Niveau actif :</strong> Active ou désactive ce niveau de fidélité<br/><br/>
              <strong>🏪 Isolation par atelier :</strong> Chaque atelier a ses propres niveaux personnalisables. Vos modifications n'affectent que votre atelier.<br/>
              <strong>💡 Conseil :</strong> Modifiez les valeurs puis cliquez sur "Sauvegarder Niveaux" pour enregistrer vos changements.<br/>
              <strong>🔧 Mode de fonctionnement :</strong> Les données sont sauvegardées localement et tentent de se synchroniser avec la base de données.
            </Typography>
          </Alert>
          <Grid container spacing={3}>
            {tiers.map((tier) => (
              <Grid item xs={12} key={tier.id}>
                <Card variant="outlined">
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <Box
                        sx={{
                          width: 20,
                          height: 20,
                          borderRadius: '50%',
                          backgroundColor: tier.color,
                          mr: 2
                        }}
                      />
                      <Typography variant="h6">{tier.name}</Typography>
                      <Chip
                        label={tier.is_active ? 'Actif' : 'Inactif'}
                        color={tier.is_active ? 'success' : 'default'}
                        size="small"
                        sx={{ ml: 'auto' }}
                      />
                    </Box>

                    <Grid container spacing={2}>
                      <Grid item xs={12} sm={6}>
                        <TextField
                          fullWidth
                          label="Points requis"
                          type="number"
                          value={editingTiers[tier.id]?.points_required !== undefined 
                            ? editingTiers[tier.id].points_required 
                            : tier.points_required}
                          onChange={(e) => {
                            const value = parseInt(e.target.value) || 0;
                            console.log(`📝 Modification points_required pour ${tier.name}: ${value}`);
                            handleTierChange(tier.id, 'points_required', value);
                          }}
                          variant="outlined"
                          inputProps={{ min: 0, step: 1 }}
                        />
                      </Grid>
                      <Grid item xs={12} sm={6}>
                        <TextField
                          fullWidth
                          label="Réduction (%)"
                          type="number"
                          value={editingTiers[tier.id]?.discount_percentage !== undefined 
                            ? editingTiers[tier.id].discount_percentage 
                            : tier.discount_percentage}
                          onChange={(e) => {
                            const value = parseFloat(e.target.value) || 0;
                            console.log(`📝 Modification discount_percentage pour ${tier.name}: ${value}`);
                            handleTierChange(tier.id, 'discount_percentage', value);
                          }}
                          variant="outlined"
                          inputProps={{ min: 0, max: 100, step: 0.1 }}
                        />
                      </Grid>
                      <Grid item xs={12}>
                        <TextField
                          fullWidth
                          label="Description"
                          value={editingTiers[tier.id]?.description !== undefined 
                            ? editingTiers[tier.id].description 
                            : tier.description}
                          onChange={(e) => handleTierChange(tier.id, 'description', e.target.value)}
                          variant="outlined"
                          multiline
                          rows={2}
                        />
                      </Grid>
                      <Grid item xs={12}>
                        <FormControlLabel
                          control={
                            <Switch
                              checked={editingTiers[tier.id]?.is_active !== undefined 
                                ? editingTiers[tier.id].is_active 
                                : tier.is_active}
                              onChange={(e) => handleTierChange(tier.id, 'is_active', e.target.checked)}
                            />
                          }
                          label="Niveau actif"
                        />
                      </Grid>
                    </Grid>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </AccordionDetails>
      </Accordion>

      {/* Informations de débogage */}
      <Box sx={{ mt: 3, p: 2, backgroundColor: '#f5f5f5', borderRadius: 1 }}>
        <Typography variant="caption" color="text.secondary">
          📊 Debug: {config.length} configurations, {tiers.length} niveaux chargés
          {hasConfigChanges && ` | ${Object.keys(editingConfig).length} modifications config`}
          {hasTierChanges && ` | ${Object.keys(editingTiers).length} modifications niveaux`}
        </Typography>
      </Box>
    </Box>
  );
};

export default LoyaltySettingsSimple;

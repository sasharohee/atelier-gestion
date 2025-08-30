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

      // Charger la configuration pour cet atelier
      let configData = null;
      try {
        const { data, error: configError } = await supabase.rpc('get_loyalty_config', {
          p_workshop_id: user.id
        });

        if (configError) {
          console.warn('⚠️ Fonction get_loyalty_config non disponible, utilisation des valeurs par défaut:', configError.message);
          // Utiliser des valeurs par défaut si la fonction n'existe pas
          configData = [
            { key: 'points_per_euro', value: '1', description: 'Points gagnés par euro dépensé' },
            { key: 'minimum_purchase', value: '10', description: 'Montant minimum pour gagner des points' },
            { key: 'bonus_threshold', value: '100', description: 'Seuil pour bonus de points' },
            { key: 'bonus_multiplier', value: '1.5', description: 'Multiplicateur de bonus' },
            { key: 'points_expiry_days', value: '365', description: 'Durée de validité des points en jours' }
          ];
        } else {
          configData = data;
        }
      } catch (error) {
        console.warn('⚠️ Erreur lors du chargement de la config, utilisation des valeurs par défaut:', error);
        // Valeurs par défaut en cas d'erreur
        configData = [
          { key: 'points_per_euro', value: '1', description: 'Points gagnés par euro dépensé' },
          { key: 'minimum_purchase', value: '10', description: 'Montant minimum pour gagner des points' },
          { key: 'bonus_threshold', value: '100', description: 'Seuil pour bonus de points' },
          { key: 'bonus_multiplier', value: '1.5', description: 'Multiplicateur de bonus' },
          { key: 'points_expiry_days', value: '365', description: 'Durée de validité des points en jours' }
        ];
      }

      console.log('✅ Configuration chargée:', configData);
      setConfig(configData || []);

      // Charger les niveaux de fidélité pour cet atelier
      let tiersData = null;
      try {
        const { data, error: tiersError } = await supabase.rpc('get_loyalty_tiers', {
          p_workshop_id: user.id
        });

        if (tiersError) {
          console.warn('⚠️ Fonction get_loyalty_tiers non disponible, utilisation des valeurs par défaut:', tiersError.message);
          // Utiliser des valeurs par défaut si la fonction n'existe pas
          tiersData = [
            { id: '00000000-0000-0000-0000-000000000001', name: 'Bronze', points_required: 0, discount_percentage: 0.00, color: '#CD7F32', description: 'Niveau de base', is_active: true },
            { id: '00000000-0000-0000-0000-000000000002', name: 'Argent', points_required: 100, discount_percentage: 5.00, color: '#C0C0C0', description: '5% de réduction', is_active: true },
            { id: '00000000-0000-0000-0000-000000000003', name: 'Or', points_required: 500, discount_percentage: 10.00, color: '#FFD700', description: '10% de réduction', is_active: true },
            { id: '00000000-0000-0000-0000-000000000004', name: 'Platine', points_required: 1000, discount_percentage: 15.00, color: '#E5E4E2', description: '15% de réduction', is_active: true },
            { id: '00000000-0000-0000-0000-000000000005', name: 'Diamant', points_required: 2000, discount_percentage: 20.00, color: '#B9F2FF', description: '20% de réduction', is_active: true }
          ];
        } else {
          tiersData = data;
        }
      } catch (error) {
        console.warn('⚠️ Erreur lors du chargement des tiers, utilisation des valeurs par défaut:', error);
        // Valeurs par défaut en cas d'erreur
        tiersData = [
          { id: '00000000-0000-0000-0000-000000000001', name: 'Bronze', points_required: 0, discount_percentage: 0.00, color: '#CD7F32', description: 'Niveau de base', is_active: true },
          { id: '00000000-0000-0000-0000-000000000002', name: 'Argent', points_required: 100, discount_percentage: 5.00, color: '#C0C0C0', description: '5% de réduction', is_active: true },
          { id: '00000000-0000-0000-0000-000000000003', name: 'Or', points_required: 500, discount_percentage: 10.00, color: '#FFD700', description: '10% de réduction', is_active: true },
          { id: '00000000-0000-0000-0000-000000000004', name: 'Platine', points_required: 1000, discount_percentage: 15.00, color: '#E5E4E2', description: '15% de réduction', is_active: true },
          { id: '00000000-0000-0000-0000-000000000005', name: 'Diamant', points_required: 2000, discount_percentage: 20.00, color: '#B9F2FF', description: '20% de réduction', is_active: true }
        ];
      }
      
      // Filtrer les doublons côté client si nécessaire
      const uniqueTiers = tiersData ? tiersData.filter((tier, index, self) => 
        index === self.findIndex(t => t.name === tier.name)
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
        const { error } = await supabase
          .from('loyalty_config')
          .update(update)
          .eq('key', update.key);

        if (error) {
          console.error('❌ Erreur mise à jour:', error);
          throw error;
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

      // Récupérer l'utilisateur actuel
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }

      const updates = Object.entries(editingTiers).map(([id, updates]) => ({
        id,
        ...updates,
        updated_at: new Date().toISOString()
      }));

      console.log('🔄 Mises à jour préparées:', updates);

      for (const update of updates) {
        const { id, ...updateData } = update;
        console.log(`🔄 Mise à jour du tier ${id}:`, updateData);
        console.log(`📊 Données à envoyer:`, JSON.stringify(updateData, null, 2));
        
        // Vérifier si le tier existe (si c'est un UUID par défaut, il n'existe probablement pas)
        const isDefaultUUID = id.startsWith('00000000-0000-0000-0000-00000000000');
        
        if (isDefaultUUID) {
          // Créer le tier s'il n'existe pas
          console.log(`🆕 Création du tier ${id} car c'est un UUID par défaut`);
          const { data, error } = await supabase
            .from('loyalty_tiers_advanced')
            .insert({
              ...updateData,
              workshop_id: user.id,
              created_at: new Date().toISOString()
            })
            .select();

          console.log(`📊 Résultat création ${id}:`, { data, error });
          
          if (error) {
            console.error('❌ Erreur création tier:', error);
            throw error;
          }
        } else {
          // Mettre à jour le tier existant
          const { data, error } = await supabase
            .from('loyalty_tiers_advanced')
            .update(updateData)
            .eq('id', id)
            .select();

          console.log(`📊 Résultat mise à jour ${id}:`, { data, error });
          
          if (error) {
            console.error('❌ Erreur mise à jour tier:', error);
            throw error;
          }
        }
      }

      // Mettre à jour l'état local
      setTiers(prev => prev.map(tier => 
        editingTiers[tier.id] 
          ? { ...tier, ...editingTiers[tier.id] }
          : tier
      ));

      setEditingTiers({});
      setSuccess('✅ Niveaux de fidélité sauvegardés avec succès !');
      console.log('✅ Niveaux sauvegardés');
      
      // Recharger les données pour confirmer
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
      console.error('❌ Erreur sauvegarde tiers:', err);
      setError(`Erreur de sauvegarde: ${err.message}`);
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
          {saving ? 'Sauvegarde...' : 'Sauvegarder Niveaux'}
        </Button>

        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadData}
          disabled={saving}
        >
          Actualiser
        </Button>
      </Box>

      {/* Configuration Générale */}
      <Accordion defaultExpanded>
        <AccordionSummary expandIcon={<ExpandMoreIcon />}>
          <SettingsIcon sx={{ mr: 1 }} />
          <Typography variant="h6">Configuration Générale</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Grid container spacing={3}>
            {config.map((item) => (
              <Grid item xs={12} sm={6} key={item.key}>
                <TextField
                  fullWidth
                  label={item.description}
                  value={editingConfig[item.key] !== undefined ? editingConfig[item.key] : item.value}
                  onChange={(e) => handleConfigChange(item.key, e.target.value)}
                  helperText={`Clé: ${item.key}`}
                  variant="outlined"
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
                          onChange={(e) => handleTierChange(tier.id, 'points_required', parseInt(e.target.value) || 0)}
                          variant="outlined"
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
                          onChange={(e) => handleTierChange(tier.id, 'discount_percentage', parseFloat(e.target.value) || 0)}
                          variant="outlined"
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

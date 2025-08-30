import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Divider,
  Alert,
  CircularProgress,
  IconButton,
  Tooltip,
  Paper,
  Chip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Slider,
  InputAdornment,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions
} from '@mui/material';
import {
  Save as SaveIcon,
  Refresh as RefreshIcon,
  Tune as TuneIcon,
  Euro as EuroIcon,
  Star as StarIcon,
  TrendingUp as TrendingUpIcon,
  ExpandMore as ExpandMoreIcon,
  Info as InfoIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Settings as SettingsIcon
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

interface LoyaltySettingsProps {}

const LoyaltySettings: React.FC<LoyaltySettingsProps> = () => {
  const [config, setConfig] = useState<LoyaltyConfig[]>([]);
  const [tiers, setTiers] = useState<LoyaltyTier[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [editingConfig, setEditingConfig] = useState<Record<string, string>>({});
  const [editingTiers, setEditingTiers] = useState<Record<string, Partial<LoyaltyTier>>>({});
  const [previewDialogOpen, setPreviewDialogOpen] = useState(false);
  const [previewData, setPreviewData] = useState<any>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Charger la configuration
      const { data: configData, error: configError } = await supabase
        .from('loyalty_config')
        .select('*')
        .order('key');

      if (configError) throw configError;
      setConfig(configData || []);

      // Charger les niveaux de fidélité
      const { data: tiersData, error: tiersError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .order('points_required');

      if (tiersError) throw tiersError;
      setTiers(tiersData || []);

    } catch (err) {
      console.error('Erreur lors du chargement des données:', err);
      setError('Erreur lors du chargement des données');
    } finally {
      setLoading(false);
    }
  };

  const handleConfigChange = (key: string, value: string) => {
    setEditingConfig(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const handleTierChange = (tierId: string, field: keyof LoyaltyTier, value: any) => {
    setEditingTiers(prev => ({
      ...prev,
      [tierId]: {
        ...prev[tierId],
        [field]: value
      }
    }));
  };

  const saveConfig = async () => {
    try {
      setSaving(true);
      setError(null);

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

        if (error) throw error;
      }

      // Mettre à jour l'état local
      setConfig(prev => prev.map(item => 
        editingConfig[item.key] 
          ? { ...item, value: editingConfig[item.key] }
          : item
      ));

      setEditingConfig({});
      setSuccess('Configuration sauvegardée avec succès !');
      
      // Effacer le message de succès après 3 secondes
      setTimeout(() => setSuccess(null), 3000);

    } catch (err) {
      console.error('Erreur lors de la sauvegarde:', err);
      setError('Erreur lors de la sauvegarde de la configuration');
    } finally {
      setSaving(false);
    }
  };

  const saveTiers = async () => {
    try {
      setSaving(true);
      setError(null);

      const updates = Object.entries(editingTiers).map(([id, updates]) => ({
        id,
        ...updates,
        updated_at: new Date().toISOString()
      }));

      for (const update of updates) {
        const { id, ...updateData } = update;
        const { error } = await supabase
          .from('loyalty_tiers_advanced')
          .update(updateData)
          .eq('id', id);

        if (error) throw error;
      }

      // Mettre à jour l'état local
      setTiers(prev => prev.map(tier => 
        editingTiers[tier.id] 
          ? { ...tier, ...editingTiers[tier.id] }
          : tier
      ));

      setEditingTiers({});
      setSuccess('Niveaux de fidélité sauvegardés avec succès !');
      
      // Effacer le message de succès après 3 secondes
      setTimeout(() => setSuccess(null), 3000);

    } catch (err) {
      console.error('Erreur lors de la sauvegarde:', err);
      setError('Erreur lors de la sauvegarde des niveaux de fidélité');
    } finally {
      setSaving(false);
    }
  };

  const previewSystem = async () => {
    try {
      setLoading(true);
      
      // Simuler un calcul avec les paramètres actuels
      const testAmounts = [25, 75, 150, 300];
      const previewResults = [];

      for (const amount of testAmounts) {
        const { data, error } = await supabase.rpc('calculate_loyalty_points', {
          p_amount: amount,
          p_client_id: '00000000-0000-0000-0000-000000000000' // ID factice pour le test
        });

        if (!error && data !== null) {
          previewResults.push({
            amount,
            points: data,
            tier: getTierForPoints(data)
          });
        }
      }

      setPreviewData({
        config: config.reduce((acc, item) => ({ ...acc, [item.key]: item.value }), {}),
        previewResults,
        tiers: tiers.map(tier => ({
          name: tier.name,
          points_required: tier.points_required,
          discount_percentage: tier.discount_percentage,
          benefits: tier.benefits
        }))
      });

      setPreviewDialogOpen(true);

    } catch (err) {
      console.error('Erreur lors de la prévisualisation:', err);
      setError('Erreur lors de la prévisualisation du système');
    } finally {
      setLoading(false);
    }
  };

  const getTierForPoints = (points: number) => {
    const tier = tiers
      .filter(t => t.is_active)
      .sort((a, b) => b.points_required - a.points_required)
      .find(t => points >= t.points_required);
    
    return tier ? tier.name : 'Sans niveau';
  };

  const hasUnsavedChanges = () => {
    return Object.keys(editingConfig).length > 0 || Object.keys(editingTiers).length > 0;
  };

  const resetChanges = () => {
    setEditingConfig({});
    setEditingTiers({});
    setError(null);
    setSuccess(null);
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        ⚙️ Paramètres du Système de Fidélité
      </Typography>
      
      <Typography variant="body1" color="textSecondary" paragraph>
        Personnalisez le système de fidélité selon vos préférences et votre stratégie commerciale
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      {/* Actions principales */}
      <Box display="flex" gap={2} mb={3} flexWrap="wrap">
        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={saveConfig}
          disabled={!Object.keys(editingConfig).length || saving}
        >
          Sauvegarder Configuration
        </Button>
        
        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={saveTiers}
          disabled={!Object.keys(editingTiers).length || saving}
        >
          Sauvegarder Niveaux
        </Button>
        
        <Button
          variant="outlined"
          startIcon={<TuneIcon />}
          onClick={previewSystem}
          disabled={loading}
        >
          Prévisualiser le Système
        </Button>
        
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadData}
          disabled={loading}
        >
          Actualiser
        </Button>
        
        {hasUnsavedChanges() && (
          <Button
            variant="outlined"
            color="warning"
            onClick={resetChanges}
          >
            Annuler les Modifications
          </Button>
        )}
      </Box>

      {/* Configuration du système */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            <SettingsIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
            Configuration Générale
          </Typography>
          
          <Grid container spacing={3}>
            {config.map((item) => (
              <Grid item xs={12} sm={6} md={4} key={item.key}>
                <TextField
                  fullWidth
                  label={item.description}
                  value={editingConfig[item.key] !== undefined ? editingConfig[item.key] : item.value}
                  onChange={(e) => handleConfigChange(item.key, e.target.value)}
                  InputProps={{
                    startAdornment: item.key.includes('points') ? (
                      <InputAdornment position="start">
                        <StarIcon color="primary" />
                      </InputAdornment>
                    ) : item.key.includes('euro') || item.key.includes('threshold') ? (
                      <InputAdornment position="start">
                        <EuroIcon color="primary" />
                      </InputAdornment>
                    ) : null
                  }}
                  helperText={`Clé: ${item.key}`}
                  variant="outlined"
                  size="small"
                />
              </Grid>
            ))}
          </Grid>
        </CardContent>
      </Card>

      {/* Niveaux de fidélité */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            <StarIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
            Niveaux de Fidélité
          </Typography>
          
          <Typography variant="body2" color="textSecondary" paragraph>
            Modifiez les seuils, réductions et avantages de chaque niveau
          </Typography>

          {tiers.map((tier) => (
            <Accordion key={tier.id} sx={{ mb: 2 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Box display="flex" alignItems="center" width="100%">
                  <Box
                    width={20}
                    height={20}
                    borderRadius="50%"
                    bgcolor={tier.color}
                    mr={2}
                  />
                  <Typography variant="h6" sx={{ flexGrow: 1 }}>
                    {tier.name}
                  </Typography>
                  <Chip
                    label={`${tier.points_required} points`}
                    color="primary"
                    variant="outlined"
                    size="small"
                  />
                  {tier.discount_percentage > 0 && (
                    <Chip
                      label={`${tier.discount_percentage}% réduction`}
                      color="success"
                      variant="outlined"
                      size="small"
                      sx={{ ml: 1 }}
                    />
                  )}
                </Box>
              </AccordionSummary>
              
              <AccordionDetails>
                <Grid container spacing={3}>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Points requis"
                      type="number"
                      value={editingTiers[tier.id]?.points_required !== undefined 
                        ? editingTiers[tier.id].points_required 
                        : tier.points_required}
                      onChange={(e) => handleTierChange(tier.id, 'points_required', parseInt(e.target.value) || 0)}
                      InputProps={{
                        startAdornment: <InputAdornment position="start"><StarIcon /></InputAdornment>
                      }}
                    />
                  </Grid>
                  
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Pourcentage de réduction"
                      type="number"
                      value={editingTiers[tier.id]?.discount_percentage !== undefined 
                        ? editingTiers[tier.id].discount_percentage 
                        : tier.discount_percentage}
                      onChange={(e) => handleTierChange(tier.id, 'discount_percentage', parseFloat(e.target.value) || 0)}
                      InputProps={{
                        endAdornment: <InputAdornment position="end">%</InputAdornment>
                      }}
                    />
                  </Grid>
                  
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Description"
                      value={editingTiers[tier.id]?.description !== undefined 
                        ? editingTiers[tier.id].description 
                        : tier.description || ''}
                      onChange={(e) => handleTierChange(tier.id, 'description', e.target.value)}
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
                          color="primary"
                        />
                      }
                      label="Niveau actif"
                    />
                  </Grid>
                </Grid>
              </AccordionDetails>
            </Accordion>
          ))}
        </CardContent>
      </Card>

      {/* Aperçu des avantages */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            <TrendingUpIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
            Aperçu des Avantages
          </Typography>
          
          <Typography variant="body2" color="textSecondary" paragraph>
            Visualisez comment vos paramètres affectent l'expérience de vos clients
          </Typography>

          <Grid container spacing={2}>
            {tiers.filter(t => t.is_active).map((tier) => (
              <Grid item xs={12} sm={6} md={4} key={tier.id}>
                <Paper 
                  elevation={2} 
                  sx={{ 
                    p: 2, 
                    borderLeft: `4px solid ${tier.color}`,
                    bgcolor: 'background.paper'
                  }}
                >
                  <Typography variant="h6" gutterBottom>
                    {tier.name}
                  </Typography>
                  <Typography variant="body2" color="textSecondary" paragraph>
                    {tier.description}
                  </Typography>
                  
                  <Box display="flex" alignItems="center" mb={1}>
                    <StarIcon color="primary" sx={{ mr: 1 }} />
                    <Typography variant="subtitle2">
                      {tier.points_required} points requis
                    </Typography>
                  </Box>
                  
                  {tier.discount_percentage > 0 && (
                    <Box display="flex" alignItems="center" mb={1}>
                      <EuroIcon color="success" sx={{ mr: 1 }} />
                      <Typography variant="subtitle2" color="success.main">
                        {tier.discount_percentage}% de réduction
                      </Typography>
                    </Box>
                  )}
                  
                  {tier.benefits && tier.benefits.length > 0 && (
                    <Box mt={1}>
                      {tier.benefits.map((benefit, index) => (
                        <Chip
                          key={index}
                          label={benefit}
                          size="small"
                          variant="outlined"
                          sx={{ mr: 0.5, mb: 0.5 }}
                        />
                      ))}
                    </Box>
                  )}
                </Paper>
              </Grid>
            ))}
          </Grid>
        </CardContent>
      </Card>

      {/* Dialog de prévisualisation */}
      <Dialog 
        open={previewDialogOpen} 
        onClose={() => setPreviewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box display="flex" alignItems="center">
            <TuneIcon sx={{ mr: 1 }} />
            Prévisualisation du Système de Fidélité
          </Box>
        </DialogTitle>
        
        <DialogContent>
          {previewData && (
            <Box>
              <Typography variant="h6" gutterBottom>
                Configuration Actuelle
              </Typography>
              
              <Grid container spacing={2} sx={{ mb: 3 }}>
                <Grid item xs={6}>
                  <Typography variant="body2">
                    <strong>Points par euro:</strong> {previewData.config.points_per_euro}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2">
                    <strong>Seuil minimum:</strong> {previewData.config.minimum_purchase_for_points}€
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2">
                    <strong>Bonus 50€+:</strong> {previewData.config.bonus_threshold_50}€
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2">
                    <strong>Bonus 100€+:</strong> {previewData.config.bonus_threshold_100}€
                  </Typography>
                </Grid>
              </Grid>

              <Divider sx={{ my: 2 }} />

              <Typography variant="h6" gutterBottom>
                Exemples de Calcul
              </Typography>
              
              <Grid container spacing={2}>
                {previewData.previewResults.map((result, index) => (
                  <Grid item xs={12} sm={6} key={index}>
                    <Paper elevation={1} sx={{ p: 2 }}>
                      <Typography variant="subtitle1" gutterBottom>
                        Achat de {result.amount}€
                      </Typography>
                      <Typography variant="h6" color="primary">
                        {result.points} points gagnés
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Niveau: {result.tier}
                      </Typography>
                    </Paper>
                  </Grid>
                ))}
              </Grid>
            </Box>
          )}
        </DialogContent>
        
        <DialogActions>
          <Button onClick={() => setPreviewDialogOpen(false)}>
            Fermer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default LoyaltySettings;

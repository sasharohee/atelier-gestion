import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  CircularProgress,
  Alert,
  Avatar,
  Chip,
  IconButton,
  Tooltip
} from '@mui/material';
import {
  Star as StarIcon,
  Refresh as RefreshIcon,
  Edit as EditIcon
} from '@mui/icons-material';
import { supabase } from '../../lib/supabase';

interface LoyaltyTier {
  id: string;
  name: string;
  description: string;
  points_required: number;
  discount_percentage: number;
  color: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface LoyaltyTiersDisplayProps {
  onTierUpdate?: () => void;
  refreshTrigger?: number; // Pour forcer le rafraîchissement
}

const LoyaltyTiersDisplay: React.FC<LoyaltyTiersDisplayProps> = ({ onTierUpdate, refreshTrigger }) => {
  const [tiers, setTiers] = useState<LoyaltyTier[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  
  // États pour l'édition (supprimés - modification uniquement via paramètres)

  // Charger les niveaux au montage et quand refreshTrigger change
  useEffect(() => {
    loadTiers();
  }, [refreshTrigger]);

  const loadTiers = async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('🔄 Chargement des niveaux de fidélité avec isolation par atelier...');

      // Attendre un petit délai pour s'assurer que la base est à jour
      await new Promise(resolve => setTimeout(resolve, 500));

      // Vérifier l'utilisateur connecté
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }

      // Charger les niveaux avec isolation par atelier
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
            .order('points_required', { ascending: true });

          if (fallbackError) {
            console.error('❌ Erreur chargement fallback:', fallbackError);
            setError(`Erreur de chargement: ${fallbackError.message}`);
            return;
          }
          
          tiersData = fallbackData;
          console.log('✅ Niveaux chargés via fallback (RLS):', fallbackData?.length || 0);
        } else {
          tiersData = data;
          console.log('✅ Niveaux chargés avec isolation par atelier:', data?.length || 0);
        }
      } catch (error) {
        console.warn('⚠️ Erreur lors du chargement des tiers, utilisation du fallback:', error);
        
        // Fallback final: charger directement depuis la table
        const { data: fallbackData, error: fallbackError } = await supabase
          .from('loyalty_tiers_advanced')
          .select('*')
          .order('points_required', { ascending: true });

        if (fallbackError) {
          console.error('❌ Erreur chargement fallback final:', fallbackError);
          setError(`Erreur de chargement: ${fallbackError.message}`);
          return;
        }
        
        tiersData = fallbackData;
        console.log('✅ Niveaux chargés via fallback final:', fallbackData?.length || 0);
      }

      console.log('✅ Niveaux chargés depuis la base:', tiersData);
      console.log('📊 Nombre de niveaux:', tiersData?.length || 0);
      
      // Supprimer les doublons en gardant le plus récent
      const uniqueTiers = tiersData?.reduce((acc: LoyaltyTier[], tier: LoyaltyTier) => {
        const existingIndex = acc.findIndex(t => t.name === tier.name);
        if (existingIndex === -1) {
          acc.push(tier);
        } else {
          // Garder le plus récent
          const existing = acc[existingIndex];
          const existingDate = new Date(existing.updated_at || existing.created_at);
          const newDate = new Date(tier.updated_at || tier.created_at);
          if (newDate > existingDate) {
            acc[existingIndex] = tier;
          }
        }
        return acc;
      }, []) || [];

      console.log('✅ Niveaux uniques après déduplication:', uniqueTiers);
      console.log('📊 Détail des niveaux:', uniqueTiers.map((t: any) => ({ name: t.name, points: t.points_required })));
      
      setTiers(uniqueTiers);

    } catch (err: any) {
      console.error('❌ Erreur générale:', err);
      setError(`Erreur: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const refreshTiers = async () => {
    try {
      setRefreshing(true);
      console.log('🔄 Rafraîchissement des niveaux...');
      
      // Attendre un délai pour s'assurer que la DB est à jour
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      await loadTiers();
      
      setSuccess('✅ Niveaux rafraîchis avec succès !');
      setTimeout(() => setSuccess(null), 3000);
      
    } catch (err: any) {
      console.error('❌ Erreur rafraîchissement:', err);
      setError(`Erreur de rafraîchissement: ${err.message}`);
    } finally {
      setRefreshing(false);
    }
  };

  // Fonctions d'édition supprimées - modification uniquement via paramètres

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 200 }}>
        <CircularProgress />
        <Typography sx={{ ml: 2 }}>Chargement des niveaux...</Typography>
      </Box>
    );
  }

  return (
    <Box>
      {/* En-tête avec bouton de rafraîchissement */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h6">Niveaux de Fidélité</Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          {success && (
            <Alert severity="success" sx={{ py: 0.5, px: 1 }}>
              {success}
            </Alert>
          )}
          <Button
            variant="outlined"
            startIcon={refreshing ? <CircularProgress size={16} /> : <RefreshIcon />}
            onClick={refreshTiers}
            disabled={refreshing}
            size="small"
          >
            {refreshing ? 'Actualisation...' : 'Actualiser'}
          </Button>
        </Box>
      </Box>

      {/* Messages d'erreur */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Grille des niveaux */}
      <Grid container spacing={3}>
        {tiers.map((tier) => (
          <Grid item xs={12} sm={6} md={4} key={tier.id}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Avatar sx={{ bgcolor: tier.color, mr: 2 }}>
                    <StarIcon />
                  </Avatar>
                  <Box sx={{ flexGrow: 1 }}>
                    <Typography variant="h6">{tier.name}</Typography>
                    <Chip
                      label={tier.is_active ? 'Actif' : 'Inactif'}
                      color={tier.is_active ? 'success' : 'default'}
                      size="small"
                    />
                  </Box>
                  <Tooltip title="Modifier dans les paramètres">
                    <IconButton
                      size="small"
                      onClick={() => {
                        // Ouvrir les paramètres au lieu de modifier directement
                        window.alert('Pour modifier ce niveau, allez dans Paramètres → Niveaux de Fidélité');
                      }}
                      disabled={false}
                    >
                      <EditIcon />
                    </IconButton>
                  </Tooltip>
                </Box>

                <Typography variant="h4" color="primary" sx={{ mb: 1 }}>
                  {tier.discount_percentage}%
                </Typography>
                
                <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                  {tier.points_required} points requis
                </Typography>
                
                <Typography variant="body2" color="text.secondary">
                  {tier.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Dialogue d'édition supprimé - modification uniquement via paramètres */}
    </Box>
  );
};

export default LoyaltyTiersDisplay;

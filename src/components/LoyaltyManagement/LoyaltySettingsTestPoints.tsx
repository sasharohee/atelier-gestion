import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Card,
  CardContent,
  TextField,
  Grid
} from '@mui/material';
import { supabase } from '../../lib/supabase';

const LoyaltySettingsTestPoints: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [tiersData, setTiersData] = useState<any[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [testPoints, setTestPoints] = useState('100');
  const [testDiscount, setTestDiscount] = useState('5');

  useEffect(() => {
    loadTiers();
  }, []);

  const loadTiers = async () => {
    try {
      setLoading(true);
      setError(null);

      console.log('🔄 Chargement des niveaux...');
      const { data, error } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .order('points_required');

      if (error) {
        console.error('❌ Erreur chargement:', error);
        setError(`Erreur chargement: ${error.message}`);
      } else {
        console.log('✅ Niveaux chargés:', data);
        setTiersData(data || []);
      }
    } catch (err: any) {
      console.error('❌ Erreur générale:', err);
      setError(`Erreur: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const testPointsUpdate = async () => {
    if (tiersData.length === 0) {
      setError('Aucun niveau trouvé pour tester');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      const tierToUpdate = tiersData.find(t => t.name === 'Argent') || tiersData[0];
      console.log('🧪 Test de mise à jour des points pour:', tierToUpdate);

      const newPoints = parseInt(testPoints);
      const newDiscount = parseFloat(testDiscount);

      console.log('📝 Nouvelles valeurs:', { points: newPoints, discount: newDiscount });

      // Test de mise à jour des points
      const { data: updateData, error: updateError } = await supabase
        .from('loyalty_tiers_advanced')
        .update({ 
          points_required: newPoints,
          discount_percentage: newDiscount,
          updated_at: new Date().toISOString()
        })
        .eq('id', tierToUpdate.id)
        .select();

      console.log('📊 Résultat mise à jour:', { data: updateData, error: updateError });

      if (updateError) {
        throw new Error(`Erreur mise à jour: ${updateError.message}`);
      }

      setSuccess(`✅ Mise à jour réussie ! Points: ${newPoints}, Réduction: ${newDiscount}%`);

      // Recharger les données après 2 secondes
      setTimeout(() => {
        loadTiers();
      }, 2000);

    } catch (err: any) {
      console.error('❌ Erreur test:', err);
      setError(`Erreur test: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const testDirectUpdate = async () => {
    if (tiersData.length === 0) {
      setError('Aucun niveau trouvé pour tester');
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const tierToUpdate = tiersData.find(t => t.name === 'Or') || tiersData[0];
      console.log('🧪 Test de mise à jour directe pour:', tierToUpdate);

      // Test avec des valeurs fixes
      const { data: updateData, error: updateError } = await supabase
        .from('loyalty_tiers_advanced')
        .update({ 
          points_required: 750,
          discount_percentage: 12.5,
          description: 'Test de mise à jour directe',
          updated_at: new Date().toISOString()
        })
        .eq('id', tierToUpdate.id)
        .select();

      console.log('📊 Résultat mise à jour directe:', { data: updateData, error: updateError });

      if (updateError) {
        setError(`Erreur mise à jour directe: ${updateError.message}`);
      } else {
        setSuccess('✅ Mise à jour directe réussie !');
        setTimeout(() => {
          loadTiers();
        }, 2000);
      }

    } catch (err: any) {
      console.error('❌ Erreur test direct:', err);
      setError(`Erreur test direct: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        🧪 Test de Mise à Jour des Points
      </Typography>
      
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Test spécifique pour les mises à jour des points et réductions
      </Typography>

      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <Button
          variant="contained"
          onClick={loadTiers}
          disabled={loading}
        >
          {loading ? <CircularProgress size={20} /> : '🔄 Recharger'}
        </Button>

        <Button
          variant="outlined"
          onClick={testPointsUpdate}
          disabled={loading || tiersData.length === 0}
        >
          {loading ? <CircularProgress size={20} /> : '🧪 Tester Points'}
        </Button>

        <Button
          variant="outlined"
          onClick={testDirectUpdate}
          disabled={loading || tiersData.length === 0}
        >
          {loading ? <CircularProgress size={20} /> : '🎯 Test Direct'}
        </Button>
      </Box>

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

      {/* Configuration du test */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            ⚙️ Configuration du Test
          </Typography>
          
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Points requis"
                type="number"
                value={testPoints}
                onChange={(e) => setTestPoints(e.target.value)}
                size="small"
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Réduction (%)"
                type="number"
                value={testDiscount}
                onChange={(e) => setTestDiscount(e.target.value)}
                size="small"
              />
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Affichage des niveaux */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            🏆 Niveaux de Fidélité ({tiersData.length} éléments)
          </Typography>
          
          {tiersData.length === 0 ? (
            <Typography color="text.secondary">
              Aucun niveau trouvé
            </Typography>
          ) : (
            <Grid container spacing={2}>
              {tiersData.map((tier, index) => (
                <Grid item xs={12} sm={6} key={tier.id}>
                  <Box sx={{ p: 2, border: '1px solid #ddd', borderRadius: 1 }}>
                    <Typography variant="subtitle1">
                      <strong>{tier.name}</strong>
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {tier.description}
                    </Typography>
                    <Typography variant="body2">
                      <strong>{tier.points_required}</strong> points • <strong>{tier.discount_percentage}%</strong> réduction
                    </Typography>
                    <Typography variant="caption" display="block">
                      ID: {tier.id}
                    </Typography>
                    <Typography variant="caption" display="block">
                      Actif: {tier.is_active ? 'Oui' : 'Non'}
                    </Typography>
                  </Box>
                </Grid>
              ))}
            </Grid>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default LoyaltySettingsTestPoints;







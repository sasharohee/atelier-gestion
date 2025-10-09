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

const LoyaltySettingsTestUpdate: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [tiersData, setTiersData] = useState<any[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [testValue, setTestValue] = useState('Test Description');

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

  const testUpdate = async () => {
    if (tiersData.length === 0) {
      setError('Aucun niveau trouvé pour tester');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      const tierToUpdate = tiersData[0]; // Premier niveau
      console.log('🧪 Test de mise à jour du tier:', tierToUpdate);

      // Test 1: Mise à jour simple
      console.log('📝 Test 1: Mise à jour simple...');
      const { data: update1, error: error1 } = await supabase
        .from('loyalty_tiers_advanced')
        .update({ 
          description: testValue,
          updated_at: new Date().toISOString()
        })
        .eq('id', tierToUpdate.id)
        .select();

      console.log('📊 Résultat test 1:', { data: update1, error: error1 });

      if (error1) {
        throw new Error(`Test 1 échoué: ${error1.message}`);
      }

      setSuccess('✅ Test 1 réussi ! Mise à jour simple effectuée.');

      // Test 2: Mise à jour avec plus de champs
      setTimeout(async () => {
        try {
          console.log('📝 Test 2: Mise à jour avec plus de champs...');
          const { data: update2, error: error2 } = await supabase
            .from('loyalty_tiers_advanced')
            .update({ 
              description: `${testValue} - Test 2`,
              discount_percentage: 25,
              is_active: true,
              updated_at: new Date().toISOString()
            })
            .eq('id', tierToUpdate.id)
            .select();

          console.log('📊 Résultat test 2:', { data: update2, error: error2 });

          if (error2) {
            setError(`Test 2 échoué: ${error2.message}`);
          } else {
            setSuccess('✅ Test 2 réussi ! Mise à jour complexe effectuée.');
          }

          // Recharger les données
          setTimeout(() => {
            loadTiers();
          }, 1000);

        } catch (err: any) {
          setError(`Test 2 échoué: ${err.message}`);
        }
      }, 2000);

    } catch (err: any) {
      console.error('❌ Erreur test:', err);
      setError(`Erreur test: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const testPermissions = async () => {
    try {
      setLoading(true);
      setError(null);

      console.log('🔍 Test des permissions...');

      // Test SELECT
      const { data: selectData, error: selectError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('count')
        .limit(1);

      console.log('📊 Test SELECT:', { data: selectData, error: selectError });

      // Test INSERT
      const { data: insertData, error: insertError } = await supabase
        .from('loyalty_tiers_advanced')
        .insert({
          name: 'Test Tier',
          description: 'Tier de test temporaire',
          points_required: 9999,
          discount_percentage: 0,
          color: '#000000',
          benefits: ['Test'],
          is_active: false
        })
        .select();

      console.log('📊 Test INSERT:', { data: insertData, error: insertError });

      // Test UPDATE
      if (insertData && insertData.length > 0) {
        const { data: updateData, error: updateError } = await supabase
          .from('loyalty_tiers_advanced')
          .update({ description: 'Tier de test modifié' })
          .eq('id', insertData[0].id)
          .select();

        console.log('📊 Test UPDATE:', { data: updateData, error: updateError });

        // Nettoyer - supprimer le tier de test
        const { error: deleteError } = await supabase
          .from('loyalty_tiers_advanced')
          .delete()
          .eq('id', insertData[0].id);

        console.log('📊 Test DELETE:', { error: deleteError });
      }

      setSuccess('✅ Tests de permissions terminés. Vérifiez la console.');

    } catch (err: any) {
      console.error('❌ Erreur permissions:', err);
      setError(`Erreur permissions: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        🧪 Test de Sauvegarde - Niveaux de Fidélité
      </Typography>
      
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Ce composant teste spécifiquement les mises à jour des niveaux de fidélité
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
          onClick={testUpdate}
          disabled={loading || tiersData.length === 0}
        >
          {loading ? <CircularProgress size={20} /> : '🧪 Tester Mise à Jour'}
        </Button>

        <Button
          variant="outlined"
          onClick={testPermissions}
          disabled={loading}
        >
          {loading ? <CircularProgress size={20} /> : '🔍 Tester Permissions'}
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
          
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <TextField
              label="Valeur de test"
              value={testValue}
              onChange={(e) => setTestValue(e.target.value)}
              size="small"
              sx={{ minWidth: 200 }}
            />
            
            <Typography variant="body2" color="text.secondary">
              Cette valeur sera utilisée pour tester les mises à jour
            </Typography>
          </Box>
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
                    <Typography variant="caption">
                      {tier.points_required} points • {tier.discount_percentage}% réduction
                    </Typography>
                    <Typography variant="caption" display="block">
                      ID: {tier.id}
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

export default LoyaltySettingsTestUpdate;

























import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Card,
  CardContent,
  Divider,
  TextField,
  Grid
} from '@mui/material';
import { supabase } from '../../lib/supabase';

const LoyaltySettingsDebug: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [configData, setConfigData] = useState<any[]>([]);
  const [tiersData, setTiersData] = useState<any[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [testValue, setTestValue] = useState('');

  const testDatabaseConnection = async () => {
    setLoading(true);
    setError(null);
    setConfigData([]);
    setTiersData([]);

    try {
      console.log('🔍 Test de connexion à la base de données...');

      // Test 1: Vérifier la connexion Supabase
      const { data: connectionTest, error: connectionError } = await supabase
        .from('clients')
        .select('count')
        .limit(1);

      if (connectionError) {
        throw new Error(`Erreur de connexion: ${connectionError.message}`);
      }

      console.log('✅ Connexion Supabase OK');

      // Test 2: Vérifier loyalty_config
      console.log('📊 Test de loyalty_config...');
      const { data: config, error: configError } = await supabase
        .from('loyalty_config')
        .select('*');

      console.log('📊 Résultat loyalty_config:', { data: config, error: configError });
      
      if (configError) {
        console.error('❌ Erreur loyalty_config:', configError);
        setError(`Erreur loyalty_config: ${configError.message}`);
      } else {
        setConfigData(config || []);
        console.log('✅ loyalty_config chargé:', config);
      }

      // Test 3: Vérifier loyalty_tiers_advanced
      console.log('🏆 Test de loyalty_tiers_advanced...');
      const { data: tiers, error: tiersError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*');

      console.log('🏆 Résultat loyalty_tiers_advanced:', { data: tiers, error: tiersError });
      
      if (tiersError) {
        console.error('❌ Erreur loyalty_tiers_advanced:', tiersError);
        setError(`Erreur loyalty_tiers_advanced: ${tiersError.message}`);
      } else {
        setTiersData(tiers || []);
        console.log('✅ loyalty_tiers_advanced chargé:', tiers);
      }

      // Test 4: Test d'insertion simple
      console.log('🧪 Test d\'insertion...');
      const { data: insertTest, error: insertError } = await supabase
        .from('loyalty_config')
        .insert([
          { key: 'test_key', value: 'test_value', description: 'Test insertion' }
        ])
        .select();

      console.log('🧪 Résultat insertion:', { data: insertTest, error: insertError });

      if (insertError) {
        console.error('❌ Erreur insertion:', insertError);
        setError(`Erreur insertion: ${insertError.message}`);
      } else {
        console.log('✅ Insertion réussie:', insertTest);
      }

    } catch (err: any) {
      console.error('❌ Erreur générale:', err);
      setError(`Erreur: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const insertDefaultData = async () => {
    setLoading(true);
    setError(null);

    try {
      console.log('📝 Insertion des données par défaut...');

      // Insérer la configuration par défaut
      const { error: configError } = await supabase
        .from('loyalty_config')
        .upsert([
          { key: 'points_per_euro', value: '1', description: 'Points par euro' },
          { key: 'minimum_purchase_for_points', value: '5', description: 'Achat minimum' },
          { key: 'bonus_threshold_50', value: '50', description: 'Seuil bonus 50€' },
          { key: 'bonus_threshold_100', value: '100', description: 'Seuil bonus 100€' },
          { key: 'bonus_threshold_200', value: '200', description: 'Seuil bonus 200€' },
          { key: 'points_expiry_months', value: '24', description: 'Expiration points' },
          { key: 'auto_tier_upgrade', value: 'true', description: 'Mise à jour auto' }
        ]);

      if (configError) {
        throw new Error(`Erreur config: ${configError.message}`);
      }

      // Insérer les niveaux par défaut
      const { error: tiersError } = await supabase
        .from('loyalty_tiers_advanced')
        .upsert([
          { name: 'Bronze', description: 'Niveau de base', points_required: 0, discount_percentage: 0, color: '#CD7F32', benefits: ['Accès aux promotions de base'], is_active: true },
          { name: 'Argent', description: 'Client régulier', points_required: 100, discount_percentage: 5, color: '#C0C0C0', benefits: ['5% de réduction', 'Promotions exclusives'], is_active: true },
          { name: 'Or', description: 'Client fidèle', points_required: 500, discount_percentage: 10, color: '#FFD700', benefits: ['10% de réduction', 'Service prioritaire'], is_active: true },
          { name: 'Platine', description: 'Client VIP', points_required: 1000, discount_percentage: 15, color: '#E5E4E2', benefits: ['15% de réduction', 'Service VIP'], is_active: true },
          { name: 'Diamant', description: 'Client Premium', points_required: 2000, discount_percentage: 20, color: '#B9F2FF', benefits: ['20% de réduction', 'Service Premium'], is_active: true }
        ]);

      if (tiersError) {
        throw new Error(`Erreur tiers: ${tiersError.message}`);
      }

      console.log('✅ Données par défaut insérées');
      setError('✅ Données par défaut insérées avec succès !');

      // Recharger les données
      setTimeout(() => {
        testDatabaseConnection();
      }, 1000);

    } catch (err: any) {
      console.error('❌ Erreur insertion:', err);
      setError(`Erreur insertion: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        🔧 Debug - Système de Fidélité
      </Typography>
      
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Ce composant teste la connexion et les données de fidélité
      </Typography>

      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <Button
          variant="contained"
          onClick={testDatabaseConnection}
          disabled={loading}
        >
          {loading ? <CircularProgress size={20} /> : '🔍 Tester la Connexion'}
        </Button>

        <Button
          variant="outlined"
          onClick={insertDefaultData}
          disabled={loading}
        >
          {loading ? <CircularProgress size={20} /> : '📝 Insérer Données Défaut'}
        </Button>
      </Box>

      {error && (
        <Alert severity={error.includes('✅') ? 'success' : 'error'} sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Résultats des tests */}
      <Grid container spacing={3}>
        {/* Configuration */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                📊 Configuration ({configData.length} éléments)
              </Typography>
              
              {configData.length === 0 ? (
                <Typography color="text.secondary">
                  Aucune donnée de configuration trouvée
                </Typography>
              ) : (
                <Box>
                  {configData.map((item, index) => (
                    <Box key={index} sx={{ mb: 1, p: 1, backgroundColor: '#f5f5f5', borderRadius: 1 }}>
                      <Typography variant="body2">
                        <strong>{item.key}:</strong> {item.value}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {item.description}
                      </Typography>
                    </Box>
                  ))}
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Niveaux */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🏆 Niveaux de Fidélité ({tiersData.length} éléments)
              </Typography>
              
              {tiersData.length === 0 ? (
                <Typography color="text.secondary">
                  Aucun niveau de fidélité trouvé
                </Typography>
              ) : (
                <Box>
                  {tiersData.map((tier, index) => (
                    <Box key={index} sx={{ mb: 1, p: 1, backgroundColor: '#f5f5f5', borderRadius: 1 }}>
                      <Typography variant="body2">
                        <strong>{tier.name}:</strong> {tier.points_required} points, {tier.discount_percentage}% réduction
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {tier.description} - {tier.is_active ? 'Actif' : 'Inactif'}
                      </Typography>
                    </Box>
                  ))}
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Test de modification */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            🧪 Test de Modification
          </Typography>
          
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <TextField
              label="Valeur de test"
              value={testValue}
              onChange={(e) => setTestValue(e.target.value)}
              size="small"
            />
            
            <Button
              variant="outlined"
              onClick={async () => {
                if (testValue && configData.length > 0) {
                  const { error } = await supabase
                    .from('loyalty_config')
                    .update({ value: testValue })
                    .eq('key', configData[0].key);
                  
                  if (error) {
                    setError(`Erreur modification: ${error.message}`);
                  } else {
                    setError('✅ Modification réussie !');
                    testDatabaseConnection();
                  }
                }
              }}
            >
              Modifier Premier Élément
            </Button>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LoyaltySettingsDebug;























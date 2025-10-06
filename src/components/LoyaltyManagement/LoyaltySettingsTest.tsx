import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Card,
  CardContent,
  Divider
} from '@mui/material';
import { supabase } from '../../lib/supabase';

const LoyaltySettingsTest: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [testResults, setTestResults] = useState<any>(null);

  const testDatabaseConnection = async () => {
    setLoading(true);
    setError(null);
    setTestResults(null);

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

      // Test 2: Vérifier si loyalty_config existe
      const { data: configData, error: configError } = await supabase
        .from('loyalty_config')
        .select('*')
        .limit(5);

      console.log('📊 Résultat test loyalty_config:', { data: configData, error: configError });

      // Test 3: Vérifier si loyalty_tiers_advanced existe
      const { data: tiersData, error: tiersError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .limit(5);

      console.log('📊 Résultat test loyalty_tiers_advanced:', { data: tiersData, error: tiersError });

      // Test 4: Vérifier les permissions RLS
      const { data: rpcTest, error: rpcError } = await supabase
        .rpc('get_loyalty_statistics');

      console.log('📊 Résultat test RPC:', { data: rpcTest, error: rpcError });

      // Compiler les résultats
      const results = {
        connection: { success: true, message: 'Connexion OK' },
        loyalty_config: { 
          success: !configError, 
          message: configError ? configError.message : 'Table trouvée',
          data: configData,
          error: configError
        },
        loyalty_tiers_advanced: { 
          success: !tiersError, 
          message: tiersError ? tiersError.message : 'Table trouvée',
          data: tiersData,
          error: tiersError
        },
        rpc_function: { 
          success: !rpcError, 
          message: rpcError ? rpcError.message : 'Fonction RPC OK',
          data: rpcTest,
          error: rpcError
        }
      };

      setTestResults(results);

      // Déterminer le problème principal
      if (configError && configError.code === 'PGRST116') {
        setError('❌ Table loyalty_config n\'existe pas. Exécutez le script systeme_fidelite_automatique.sql');
      } else if (tiersError && tiersError.code === 'PGRST116') {
        setError('❌ Table loyalty_tiers_advanced n\'existe pas. Exécutez le script systeme_fidelite_automatique.sql');
      } else if (rpcError && rpcError.code === 'PGRST116') {
        setError('❌ Fonction get_loyalty_statistics n\'existe pas. Exécutez le script systeme_fidelite_automatique.sql');
      } else if (configError || tiersError || rpcError) {
        setError(`❌ Erreur de permissions RLS: ${configError?.message || tiersError?.message || rpcError?.message}`);
      } else {
        setError('✅ Toutes les tables et fonctions existent. Le problème vient du composant.');
      }

    } catch (err: any) {
      console.error('❌ Erreur lors du test:', err);
      setError(`❌ Erreur: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        🔍 Diagnostic du Système de Fidélité
      </Typography>
      
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Ce test vérifie si les tables et fonctions de fidélité existent dans votre base de données.
      </Typography>

      <Button
        variant="contained"
        onClick={testDatabaseConnection}
        disabled={loading}
        sx={{ mb: 3 }}
      >
        {loading ? <CircularProgress size={20} /> : '🔍 Lancer le Diagnostic'}
      </Button>

      {error && (
        <Alert severity={error.includes('✅') ? 'success' : 'error'} sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {testResults && (
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              📊 Résultats du Diagnostic
            </Typography>
            
            <Divider sx={{ mb: 2 }} />

            {Object.entries(testResults).map(([testName, result]: [string, any]) => (
              <Box key={testName} sx={{ mb: 2 }}>
                <Typography variant="subtitle2" color={result.success ? 'success.main' : 'error.main'}>
                  {result.success ? '✅' : '❌'} {testName.replace('_', ' ').toUpperCase()}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {result.message}
                </Typography>
                {result.data && (
                  <Typography variant="caption" color="text.secondary">
                    Données: {JSON.stringify(result.data).substring(0, 100)}...
                  </Typography>
                )}
                {result.error && (
                  <Typography variant="caption" color="error">
                    Erreur: {result.error.message}
                  </Typography>
                )}
              </Box>
            ))}

            <Divider sx={{ my: 2 }} />

            <Typography variant="h6" gutterBottom>
              📋 Actions Recommandées
            </Typography>
            
            {testResults.loyalty_config.success && testResults.loyalty_tiers_advanced.success ? (
              <Alert severity="success">
                ✅ Toutes les tables existent. Le problème vient probablement des permissions RLS.
                <br />
                <strong>Solution:</strong> Exécutez le script de correction RLS.
              </Alert>
            ) : (
              <Alert severity="error">
                ❌ Tables manquantes dans la base de données.
                <br />
                <strong>Solution:</strong> Exécutez le script systeme_fidelite_automatique.sql dans Supabase SQL Editor.
              </Alert>
            )}
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default LoyaltySettingsTest;























import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Divider
} from '@mui/material';
import {
  Security as SecurityIcon,
  ExpandMore as ExpandMoreIcon,
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Info as InfoIcon
} from '@mui/icons-material';
import { supabase } from '../lib/supabase';
import { toast } from 'react-hot-toast';

interface DiagnosticResult {
  table: string;
  rlsEnabled: boolean;
  policiesCount: number;
  workshopIdColumn: boolean;
  orphanData: number;
  totalRecords: number;
  userRecords: number;
  otherRecords: number;
  isolationWorking: boolean;
}

const LoyaltyIsolationDiagnostic: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState<DiagnosticResult[]>([]);
  const [showDetails, setShowDetails] = useState(false);

  const runDiagnostic = async () => {
    setLoading(true);
    setResults([]);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        toast.error('Utilisateur non connecté');
        return;
      }

      console.log('🔍 Diagnostic isolation points de fidélité pour:', user.email);

      const tables = [
        'loyalty_points_history',
        'loyalty_tiers_advanced', 
        'referrals',
        'client_loyalty_points'
      ];

      const diagnosticResults: DiagnosticResult[] = [];

      for (const table of tables) {
        console.log(`🔍 Diagnostic de la table: ${table}`);

        // Vérifier RLS
        const { data: rlsData } = await supabase
          .from('pg_tables')
          .select('rowsecurity')
          .eq('schemaname', 'public')
          .eq('tablename', table)
          .single();

        // Vérifier les politiques
        const { data: policiesData } = await supabase
          .from('pg_policies')
          .select('policyname')
          .eq('tablename', table);

        // Vérifier la colonne workshop_id
        const { data: columnsData } = await supabase
          .from('information_schema.columns')
          .select('column_name')
          .eq('table_schema', 'public')
          .eq('table_name', table)
          .eq('column_name', 'workshop_id');

        // Compter les enregistrements
        const { data: allRecords } = await supabase
          .from(table)
          .select('*', { count: 'exact', head: true });

        const { data: userRecords } = await supabase
          .from(table)
          .select('*', { count: 'exact', head: true })
          .eq('workshop_id', user.id);

        const { data: otherRecords } = await supabase
          .from(table)
          .select('*', { count: 'exact', head: true })
          .neq('workshop_id', user.id);

        const { data: orphanRecords } = await supabase
          .from(table)
          .select('*', { count: 'exact', head: true })
          .is('workshop_id', null);

        const result: DiagnosticResult = {
          table,
          rlsEnabled: rlsData?.rowsecurity || false,
          policiesCount: policiesData?.length || 0,
          workshopIdColumn: (columnsData?.length || 0) > 0,
          orphanData: orphanRecords?.length || 0,
          totalRecords: allRecords?.length || 0,
          userRecords: userRecords?.length || 0,
          otherRecords: otherRecords?.length || 0,
          isolationWorking: (otherRecords?.length || 0) === 0 && (rlsData?.rowsecurity || false)
        };

        diagnosticResults.push(result);
        console.log(`📊 Résultat pour ${table}:`, result);
      }

      setResults(diagnosticResults);
      console.log('✅ Diagnostic terminé:', diagnosticResults);

    } catch (error) {
      console.error('❌ Erreur lors du diagnostic:', error);
      toast.error('Erreur lors du diagnostic');
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (result: DiagnosticResult) => {
    if (result.isolationWorking) {
      return <CheckIcon color="success" />;
    } else if (result.otherRecords > 0) {
      return <ErrorIcon color="error" />;
    } else if (!result.rlsEnabled || result.policiesCount === 0) {
      return <WarningIcon color="warning" />;
    } else {
      return <InfoIcon color="info" />;
    }
  };

  const getStatusColor = (result: DiagnosticResult) => {
    if (result.isolationWorking) {
      return 'success';
    } else if (result.otherRecords > 0) {
      return 'error';
    } else if (!result.rlsEnabled || result.policiesCount === 0) {
      return 'warning';
    } else {
      return 'info';
    }
  };

  const getStatusText = (result: DiagnosticResult) => {
    if (result.isolationWorking) {
      return 'Isolation parfaite';
    } else if (result.otherRecords > 0) {
      return 'PROBLÈME: Données d\'autres utilisateurs visibles';
    } else if (!result.rlsEnabled) {
      return 'RLS désactivé';
    } else if (result.policiesCount === 0) {
      return 'Aucune politique RLS';
    } else if (!result.workshopIdColumn) {
      return 'Colonne workshop_id manquante';
    } else {
      return 'Problème d\'isolation';
    }
  };

  const getOverallStatus = () => {
    if (results.length === 0) return 'info';
    
    const hasErrors = results.some(r => r.otherRecords > 0);
    const hasWarnings = results.some(r => !r.rlsEnabled || r.policiesCount === 0);
    
    if (hasErrors) return 'error';
    if (hasWarnings) return 'warning';
    return 'success';
  };

  const getOverallMessage = () => {
    if (results.length === 0) return 'Lancez le diagnostic pour vérifier l\'isolation';
    
    const hasErrors = results.some(r => r.otherRecords > 0);
    const hasWarnings = results.some(r => !r.rlsEnabled || r.policiesCount === 0);
    
    if (hasErrors) {
      return '🚨 PROBLÈME CRITIQUE: Vous pouvez voir des données d\'autres utilisateurs';
    } else if (hasWarnings) {
      return '⚠️ Problèmes de configuration détectés';
    } else {
      return '✅ Isolation parfaite sur toutes les tables de fidélité';
    }
  };

  return (
    <Card sx={{ mb: 3 }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <SecurityIcon color="primary" />
          <Typography variant="h6">
            Diagnostic Isolation Points de Fidélité
          </Typography>
        </Box>

        <Alert 
          severity={getOverallStatus() as any} 
          sx={{ mb: 2 }}
          action={
            <Button
              color="inherit"
              size="small"
              onClick={runDiagnostic}
              disabled={loading}
              startIcon={loading ? <CircularProgress size={16} /> : <SecurityIcon />}
            >
              {loading ? 'Diagnostic...' : 'Lancer le diagnostic'}
            </Button>
          }
        >
          {getOverallMessage()}
        </Alert>

        {results.length > 0 && (
          <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="subtitle1">
                Résultats du diagnostic ({results.length} tables)
              </Typography>
              <Button
                size="small"
                onClick={() => setShowDetails(!showDetails)}
                endIcon={<ExpandMoreIcon sx={{ transform: showDetails ? 'rotate(180deg)' : 'none' }} />}
              >
                {showDetails ? 'Masquer' : 'Afficher'} détails
              </Button>
            </Box>

            <TableContainer component={Paper} variant="outlined">
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Table</TableCell>
                    <TableCell align="center">Statut</TableCell>
                    <TableCell align="center">RLS</TableCell>
                    <TableCell align="center">Politiques</TableCell>
                    <TableCell align="center">Mes données</TableCell>
                    <TableCell align="center">Autres données</TableCell>
                    <TableCell align="center">Orphelines</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {results.map((result) => (
                    <TableRow key={result.table}>
                      <TableCell>
                        <Typography variant="body2" fontFamily="monospace">
                          {result.table}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          icon={getStatusIcon(result)}
                          label={getStatusText(result)}
                          color={getStatusColor(result) as any}
                          size="small"
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={result.rlsEnabled ? 'Activé' : 'Désactivé'}
                          color={result.rlsEnabled ? 'success' : 'error'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={result.policiesCount}
                          color={result.policiesCount > 0 ? 'success' : 'error'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Typography variant="body2" color="success.main">
                          {result.userRecords}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Typography 
                          variant="body2" 
                          color={result.otherRecords > 0 ? 'error.main' : 'text.secondary'}
                        >
                          {result.otherRecords}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Typography 
                          variant="body2" 
                          color={result.orphanData > 0 ? 'warning.main' : 'text.secondary'}
                        >
                          {result.orphanData}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            {showDetails && (
              <Box sx={{ mt: 2 }}>
                <Accordion>
                  <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                    <Typography variant="subtitle2">
                      Détails techniques
                    </Typography>
                  </AccordionSummary>
                  <AccordionDetails>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                      {results.map((result) => (
                        <Box key={result.table}>
                          <Typography variant="subtitle2" gutterBottom>
                            Table: {result.table}
                          </Typography>
                          <Box sx={{ pl: 2 }}>
                            <Typography variant="body2">
                              • RLS activé: {result.rlsEnabled ? 'Oui' : 'Non'}
                            </Typography>
                            <Typography variant="body2">
                              • Nombre de politiques: {result.policiesCount}
                            </Typography>
                            <Typography variant="body2">
                              • Colonne workshop_id: {result.workshopIdColumn ? 'Présente' : 'Manquante'}
                            </Typography>
                            <Typography variant="body2">
                              • Total enregistrements: {result.totalRecords}
                            </Typography>
                            <Typography variant="body2">
                              • Mes enregistrements: {result.userRecords}
                            </Typography>
                            <Typography variant="body2">
                              • Enregistrements autres utilisateurs: {result.otherRecords}
                            </Typography>
                            <Typography variant="body2">
                              • Enregistrements orphelins: {result.orphanData}
                            </Typography>
                          </Box>
                          {result !== results[results.length - 1] && <Divider sx={{ mt: 1 }} />}
                        </Box>
                      ))}
                    </Box>
                  </AccordionDetails>
                </Accordion>
              </Box>
            )}

            <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
              <Typography variant="subtitle2" gutterBottom>
                Actions recommandées:
              </Typography>
              <Typography variant="body2" component="div">
                {results.some(r => r.otherRecords > 0) && (
                  <Box sx={{ color: 'error.main', mb: 1 }}>
                    🚨 URGENT: Exécuter correction_isolation_loyalty_complete.sql
                  </Box>
                )}
                {results.some(r => !r.rlsEnabled) && (
                  <Box sx={{ color: 'warning.main', mb: 1 }}>
                    ⚠️ Activer RLS sur toutes les tables de fidélité
                  </Box>
                )}
                {results.some(r => r.policiesCount === 0) && (
                  <Box sx={{ color: 'warning.main', mb: 1 }}>
                    ⚠️ Créer des politiques RLS ultra-strictes
                  </Box>
                )}
                {results.some(r => !r.workshopIdColumn) && (
                  <Box sx={{ color: 'warning.main', mb: 1 }}>
                    ⚠️ Ajouter les colonnes workshop_id manquantes
                  </Box>
                )}
                {results.every(r => r.isolationWorking) && (
                  <Box sx={{ color: 'success.main' }}>
                    ✅ Aucune action requise - isolation parfaite
                  </Box>
                )}
              </Typography>
            </Box>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default LoyaltyIsolationDiagnostic;

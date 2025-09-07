import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Divider,
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  PersonAdd as PersonAddIcon,
  BugReport as BugReportIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Security as SecurityIcon,
} from '@mui/icons-material';
import { supabase } from '../lib/supabase';
import { clientService } from '../services/supabaseService';

interface DiagnosticResult {
  test: string;
  status: 'success' | 'error' | 'warning';
  message: string;
  details?: any;
}

const NewAccountDiagnostic: React.FC = () => {
  const [isRunning, setIsRunning] = useState(false);
  const [results, setResults] = useState<DiagnosticResult[]>([]);
  const [expanded, setExpanded] = useState<string | false>(false);

  const handleChange = (panel: string) => (event: React.SyntheticEvent, isExpanded: boolean) => {
    setExpanded(isExpanded ? panel : false);
  };

  const addResult = (test: string, status: 'success' | 'error' | 'warning', message: string, details?: any) => {
    setResults(prev => [...prev, { test, status, message, details }]);
  };

  const runDiagnostic = async () => {
    setIsRunning(true);
    setResults([]);

    try {
      // Test 1: Vérifier l'authentification
      addResult('auth', 'warning', 'Vérification de l\'authentification...');
      
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      
      if (userError || !user) {
        addResult('auth', 'error', 'Aucun utilisateur connecté', userError);
        return;
      }
      
      addResult('auth', 'success', `Utilisateur connecté: ${user.email}`, { 
        userId: user.id,
        createdAt: user.created_at,
        isNewAccount: new Date(user.created_at) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
      });

      // Test 2: Vérifier si c'est un nouveau compte
      const isNewAccount = new Date(user.created_at) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      
      if (isNewAccount) {
        addResult('new_account', 'warning', 'Nouveau compte détecté (créé dans les 7 derniers jours)', {
          createdAt: user.created_at,
          daysSinceCreation: Math.floor((Date.now() - new Date(user.created_at).getTime()) / (1000 * 60 * 60 * 24))
        });
      } else {
        addResult('new_account', 'success', 'Compte existant (créé il y a plus de 7 jours)', {
          createdAt: user.created_at,
          daysSinceCreation: Math.floor((Date.now() - new Date(user.created_at).getTime()) / (1000 * 60 * 60 * 24))
        });
      }

      // Test 3: Test du clientService.getAll()
      addResult('service', 'warning', 'Test du clientService.getAll()...');
      
      const serviceResult = await clientService.getAll();
      
      if (serviceResult.success && 'data' in serviceResult && serviceResult.data) {
        addResult('service', 'success', `${serviceResult.data.length} clients récupérés via le service`, {
          clients: serviceResult.data.map(c => ({ id: c.id, name: `${c.firstName} ${c.lastName}`, userId: (c as any).user_id || c.id }))
        });
      } else {
        addResult('service', 'error', 'Erreur lors de la récupération via le service', serviceResult);
      }

      // Test 4: Test direct RLS (sans filtrage)
      addResult('rls', 'warning', 'Test de l\'isolation RLS directe...');
      
      const { data: allClients, error: rlsError } = await supabase
        .from('clients')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (rlsError) {
        addResult('rls', 'success', 'RLS fonctionne: accès refusé sans filtrage', rlsError);
      } else {
        // Analyser les clients visibles
        const userCounts: { [key: string]: number } = {};
        allClients.forEach(client => {
          const userId = client.user_id || 'NULL';
          userCounts[userId] = (userCounts[userId] || 0) + 1;
        });
        
        const myClients = allClients.filter(client => client.user_id === user.id);
        const otherClients = allClients.filter(client => client.user_id !== user.id);
        
        if (otherClients.length > 0) {
          addResult('rls', 'error', `PROBLÈME: ${otherClients.length} clients d'autres utilisateurs visibles`, {
            totalClients: allClients.length,
            myClients: myClients.length,
            otherClients: otherClients.length,
            userCounts,
            otherClientsDetails: otherClients.slice(0, 5).map(c => ({
              id: c.id,
              name: `${c.first_name} ${c.last_name}`,
              userId: c.user_id,
              createdAt: c.created_at
            }))
          });
        } else {
          addResult('rls', 'success', `Isolation parfaite: ${myClients.length} clients visibles (uniquement les vôtres)`, {
            totalClients: allClients.length,
            myClients: myClients.length
          });
        }
      }

      // Test 5: Test de création d'un client
      addResult('create', 'warning', 'Test de création d\'un client...');
      
      const testClient = {
        first_name: 'Test',
        last_name: 'NouveauCompte',
        email: `test.nouveaucompte.${Date.now()}@example.com`,
        phone: '0123456789',
        address: '123 Test Street',
        user_id: user.id
      };
      
      const { data: createdClient, error: createError } = await supabase
        .from('clients')
        .insert([testClient])
        .select()
        .single();
      
      if (createError) {
        addResult('create', 'error', 'Erreur lors de la création', createError);
      } else {
        addResult('create', 'success', 'Client créé avec succès', { clientId: createdClient.id });
        
        // Vérifier que le client est visible
        const { data: retrievedClient, error: retrieveError } = await supabase
          .from('clients')
          .select('*')
          .eq('id', createdClient.id)
          .single();
        
        if (retrieveError) {
          addResult('create', 'error', 'Client non visible après création', retrieveError);
        } else {
          addResult('create', 'success', 'Client visible après création');
        }
        
        // Nettoyer le test
        await supabase
          .from('clients')
          .delete()
          .eq('id', createdClient.id);
      }

      // Test 6: Test spécifique aux nouveaux comptes
      if (isNewAccount) {
        addResult('new_account_specific', 'warning', 'Test spécifique aux nouveaux comptes...');
        
        // Vérifier s'il y a des clients de démonstration
        const { data: demoClients, error: demoError } = await supabase
          .from('clients')
          .select('*')
          .eq('user_id', user.id)
          .ilike('email', '%demo%');
        
        if (demoError) {
          addResult('new_account_specific', 'error', 'Erreur lors de la vérification des clients de démonstration', demoError);
        } else {
          if (demoClients.length > 0) {
            addResult('new_account_specific', 'success', `${demoClients.length} clients de démonstration trouvés`, {
              demoClients: demoClients.map(c => ({ id: c.id, name: `${c.first_name} ${c.last_name}`, email: c.email }))
            });
          } else {
            addResult('new_account_specific', 'warning', 'Aucun client de démonstration trouvé pour ce nouveau compte');
          }
        }
      }

    } catch (error) {
      addResult('general', 'error', 'Erreur générale lors du diagnostic', error);
    } finally {
      setIsRunning(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckCircleIcon color="success" />;
      case 'error':
        return <ErrorIcon color="error" />;
      case 'warning':
        return <WarningIcon color="warning" />;
      default:
        return <BugReportIcon />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success':
        return 'success';
      case 'error':
        return 'error';
      case 'warning':
        return 'warning';
      default:
        return 'default';
    }
  };

  return (
    <Box sx={{ p: 2 }}>
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <PersonAddIcon sx={{ mr: 1 }} />
            <Typography variant="h6" component="h2">
              Diagnostic Nouveaux Comptes Réparateurs
            </Typography>
          </Box>
          
          <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
            Ce diagnostic teste spécifiquement les problèmes d'isolation des données pour les nouveaux comptes de réparateurs.
          </Typography>

          <Button
            variant="contained"
            onClick={runDiagnostic}
            disabled={isRunning}
            startIcon={isRunning ? <CircularProgress size={20} /> : <BugReportIcon />}
            sx={{ mb: 3 }}
          >
            {isRunning ? 'Diagnostic en cours...' : 'Lancer le diagnostic nouveaux comptes'}
          </Button>

          {results.length > 0 && (
            <Box>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Résultats du diagnostic
              </Typography>
              
              {results.map((result, index) => (
                <Accordion
                  key={index}
                  expanded={expanded === `panel${index}`}
                  onChange={handleChange(`panel${index}`)}
                  sx={{ mb: 1 }}
                >
                  <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                    <Box sx={{ display: 'flex', alignItems: 'center', width: '100%' }}>
                      {getStatusIcon(result.status)}
                      <Typography sx={{ ml: 1, flexGrow: 1 }}>
                        {result.test}
                      </Typography>
                      <Chip
                        label={result.status}
                        color={getStatusColor(result.status) as any}
                        size="small"
                        sx={{ mr: 1 }}
                      />
                    </Box>
                  </AccordionSummary>
                  <AccordionDetails>
                    <Typography variant="body2" sx={{ mb: 2 }}>
                      {result.message}
                    </Typography>
                    
                    {result.details && (
                      <Box>
                        <Typography variant="subtitle2" sx={{ mb: 1 }}>
                          Détails:
                        </Typography>
                        <pre style={{ 
                          backgroundColor: '#f5f5f5', 
                          padding: '10px', 
                          borderRadius: '4px',
                          fontSize: '12px',
                          overflow: 'auto',
                          maxHeight: '200px'
                        }}>
                          {JSON.stringify(result.details, null, 2)}
                        </pre>
                      </Box>
                    )}
                  </AccordionDetails>
                </Accordion>
              ))}
            </Box>
          )}

          {results.length > 0 && (
            <Box sx={{ mt: 3 }}>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Résumé
              </Typography>
              
              <TableContainer component={Paper} variant="outlined">
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Test</TableCell>
                      <TableCell>Statut</TableCell>
                      <TableCell>Message</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {results.map((result, index) => (
                      <TableRow key={index}>
                        <TableCell>{result.test}</TableCell>
                        <TableCell>
                          <Chip
                            label={result.status}
                            color={getStatusColor(result.status) as any}
                            size="small"
                            icon={getStatusIcon(result.status)}
                          />
                        </TableCell>
                        <TableCell>{result.message}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </Box>
          )}

          {results.some(r => r.status === 'error') && (
            <Alert severity="error" sx={{ mt: 3 }}>
              <Typography variant="subtitle2" sx={{ mb: 1 }}>
                Problèmes détectés pour les nouveaux comptes:
              </Typography>
              <ul>
                {results.filter(r => r.status === 'error').map((result, index) => (
                  <li key={index}>{result.test}: {result.message}</li>
                ))}
              </ul>
              <Divider sx={{ my: 2 }} />
              <Typography variant="body2" sx={{ mt: 1 }}>
                <strong>Actions recommandées pour les nouveaux comptes:</strong>
                <br />
                1. Exécuter le script de correction spécifique aux nouveaux comptes
                <br />
                2. Vérifier l'initialisation des données de démonstration
                <br />
                3. Tester avec un nouveau compte de réparateur
                <br />
                4. Redéployer l'application
              </Typography>
            </Alert>
          )}

          {results.length > 0 && results.every(r => r.status === 'success') && (
            <Alert severity="success" sx={{ mt: 3 }}>
              <Typography variant="subtitle2">
                ✅ Tous les tests sont passés avec succès!
              </Typography>
              <Typography variant="body2">
                L'isolation des clients fonctionne correctement pour les nouveaux comptes. 
                Si vous rencontrez encore des problèmes, vérifiez la configuration RLS et redéployez l'application.
              </Typography>
            </Alert>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default NewAccountDiagnostic;

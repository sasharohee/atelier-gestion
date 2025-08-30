import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Alert,
  CircularProgress,
  IconButton,
  Tooltip,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Accordion,
  AccordionSummary,
  AccordionDetails
} from '@mui/material';
import {
  Settings as SettingsIcon,
  Dashboard as DashboardIcon,
  TrendingUp as TrendingUpIcon,
  People as PeopleIcon,
  Star as StarIcon,
  ExpandMore as ExpandMoreIcon,
  Edit as EditIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  Refresh as RefreshIcon,
  Euro as EuroIcon,
  Points as PointsIcon
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

interface LoyaltyDashboardItem {
  client_id: string;
  first_name: string;
  last_name: string;
  email: string;
  current_points: number;
  current_tier: string;
  discount_percentage: number;
  tier_color: string;
  benefits: string[];
  total_transactions: number;
  total_points_earned: number;
  total_points_used: number;
  client_since: string;
  last_activity: string;
}

interface LoyaltyStatistics {
  total_clients_with_points: number;
  average_points: number;
  total_points_distributed: number;
  tier_distribution: Record<string, number>;
  top_clients: Array<{
    client_id: string;
    name: string;
    points: number;
    tier: string;
  }>;
}

const LoyaltyManagement: React.FC = () => {
  const [config, setConfig] = useState<LoyaltyConfig[]>([]);
  const [tiers, setTiers] = useState<LoyaltyTier[]>([]);
  const [dashboard, setDashboard] = useState<LoyaltyDashboardItem[]>([]);
  const [statistics, setStatistics] = useState<LoyaltyStatistics | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [configDialogOpen, setConfigDialogOpen] = useState(false);
  const [editingConfig, setEditingConfig] = useState<LoyaltyConfig | null>(null);
  const [testDialogOpen, setTestDialogOpen] = useState(false);
  const [testClientId, setTestClientId] = useState('');
  const [testAmount, setTestAmount] = useState('');

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

      // Charger le tableau de bord
      const { data: dashboardData, error: dashboardError } = await supabase
        .from('loyalty_dashboard')
        .select('*');

      if (dashboardError) throw dashboardError;
      setDashboard(dashboardData || []);

      // Charger les statistiques
      const { data: statsData, error: statsError } = await supabase
        .rpc('get_loyalty_statistics');

      if (statsError) throw statsError;
      setStatistics(statsData);

    } catch (err) {
      console.error('Erreur lors du chargement des données:', err);
      setError('Erreur lors du chargement des données');
    } finally {
      setLoading(false);
    }
  };

  const updateConfig = async (configItem: LoyaltyConfig) => {
    try {
      const { error } = await supabase
        .from('loyalty_config')
        .update({ value: configItem.value, updated_at: new Date().toISOString() })
        .eq('key', configItem.key);

      if (error) throw error;

      setConfig(prev => prev.map(item => 
        item.key === configItem.key ? { ...item, value: configItem.value } : item
      ));
      setEditingConfig(null);
    } catch (err) {
      console.error('Erreur lors de la mise à jour:', err);
      setError('Erreur lors de la mise à jour de la configuration');
    }
  };

  const testLoyaltyPoints = async () => {
    if (!testClientId || !testAmount) return;

    try {
      setLoading(true);
      const { data, error } = await supabase.rpc('auto_add_loyalty_points_from_purchase', {
        p_client_id: testClientId,
        p_amount: parseFloat(testAmount),
        p_source_type: 'test',
        p_description: 'Test manuel du système de fidélité'
      });

      if (error) throw error;

      if (data.success) {
        alert(`✅ Points attribués avec succès !\nPoints gagnés: ${data.points_earned}\nNouveau total: ${data.points_after}`);
        loadData(); // Recharger les données
      } else {
        alert(`❌ ${data.message}`);
      }
    } catch (err) {
      console.error('Erreur lors du test:', err);
      setError('Erreur lors du test du système de fidélité');
    } finally {
      setLoading(false);
    }
  };

  const getTierColor = (tierName: string) => {
    const tier = tiers.find(t => t.name === tierName);
    return tier?.color || '#000000';
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('fr-FR');
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>
        🏆 Gestion du Système de Fidélité
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Configuration du système */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
            <Typography variant="h6">
              <SettingsIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
              Configuration du Système
            </Typography>
            <Button
              variant="outlined"
              startIcon={<EditIcon />}
              onClick={() => setConfigDialogOpen(true)}
            >
              Modifier
            </Button>
          </Box>

          <Grid container spacing={2}>
            {config.map((item) => (
              <Grid item xs={12} sm={6} md={4} key={item.key}>
                <Box p={2} border={1} borderColor="divider" borderRadius={1}>
                  <Typography variant="subtitle2" color="textSecondary">
                    {item.description}
                  </Typography>
                  <Typography variant="h6" color="primary">
                    {item.value}
                  </Typography>
                  <Typography variant="caption" color="textSecondary">
                    Clé: {item.key}
                  </Typography>
                </Box>
              </Grid>
            ))}
          </Grid>
        </CardContent>
      </Card>

      {/* Statistiques générales */}
      {statistics && (
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              <TrendingUpIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
              Statistiques Générales
            </Typography>

            <Grid container spacing={3}>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center" p={2}>
                  <Typography variant="h4" color="primary">
                    {statistics.total_clients_with_points}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Clients avec points
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center" p={2}>
                  <Typography variant="h4" color="success.main">
                    {Math.round(statistics.average_points)}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Points moyens
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center" p={2}>
                  <Typography variant="h4" color="warning.main">
                    {statistics.total_points_distributed}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Total distribué
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box textAlign="center" p={2}>
                  <Button
                    variant="outlined"
                    startIcon={<RefreshIcon />}
                    onClick={loadData}
                  >
                    Actualiser
                  </Button>
                </Box>
              </Grid>
            </Grid>

            {/* Distribution des niveaux */}
            <Box mt={3}>
              <Typography variant="subtitle1" gutterBottom>
                Distribution par Niveau
              </Typography>
              <Grid container spacing={1}>
                {Object.entries(statistics.tier_distribution).map(([tier, count]) => (
                  <Grid item key={tier}>
                    <Chip
                      label={`${tier}: ${count}`}
                      color="primary"
                      variant="outlined"
                    />
                  </Grid>
                ))}
              </Grid>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* Niveaux de fidélité */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            <StarIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
            Niveaux de Fidélité
          </Typography>

          <Grid container spacing={2}>
            {tiers.map((tier) => (
              <Grid item xs={12} sm={6} md={4} key={tier.id}>
                <Box
                  p={2}
                  border={1}
                  borderColor="divider"
                  borderRadius={1}
                  sx={{ borderLeft: `4px solid ${tier.color}` }}
                >
                  <Box display="flex" alignItems="center" mb={1}>
                    <Box
                      width={20}
                      height={20}
                      borderRadius="50%"
                      bgcolor={tier.color}
                      mr={1}
                    />
                    <Typography variant="h6">{tier.name}</Typography>
                  </Box>
                  <Typography variant="body2" color="textSecondary" mb={1}>
                    {tier.description}
                  </Typography>
                  <Typography variant="subtitle2" color="primary">
                    {tier.points_required} points requis
                  </Typography>
                  {tier.discount_percentage > 0 && (
                    <Typography variant="subtitle2" color="success.main">
                      {tier.discount_percentage}% de réduction
                    </Typography>
                  )}
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
                </Box>
              </Grid>
            ))}
          </Grid>
        </CardContent>
      </Card>

      {/* Tableau de bord des clients */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
            <Typography variant="h6">
              <DashboardIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
              Tableau de Bord des Clients
            </Typography>
            <Button
              variant="outlined"
              startIcon={<RefreshIcon />}
              onClick={loadData}
            >
              Actualiser
            </Button>
          </Box>

          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Client</TableCell>
                  <TableCell>Points</TableCell>
                  <TableCell>Niveau</TableCell>
                  <TableCell>Réduction</TableCell>
                  <TableCell>Transactions</TableCell>
                  <TableCell>Dernière activité</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {dashboard.map((item) => (
                  <TableRow key={item.client_id}>
                    <TableCell>
                      <Box>
                        <Typography variant="subtitle2">
                          {item.first_name} {item.last_name}
                        </Typography>
                        <Typography variant="caption" color="textSecondary">
                          {item.email}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box display="flex" alignItems="center">
                        <PointsIcon sx={{ mr: 0.5, color: 'primary.main' }} />
                        <Typography variant="h6" color="primary">
                          {item.current_points}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={item.current_tier || 'Sans niveau'}
                        sx={{
                          bgcolor: getTierColor(item.current_tier || ''),
                          color: 'white'
                        }}
                      />
                    </TableCell>
                    <TableCell>
                      {item.discount_percentage > 0 ? (
                        <Typography variant="subtitle2" color="success.main">
                          {item.discount_percentage}%
                        </Typography>
                      ) : (
                        <Typography variant="body2" color="textSecondary">
                          Aucune
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {item.total_transactions}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {formatDate(item.last_activity)}
                      </Typography>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Test du système */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            🧪 Test du Système de Fidélité
          </Typography>
          <Typography variant="body2" color="textSecondary" mb={2}>
            Testez manuellement l'attribution de points de fidélité
          </Typography>
          
          <Button
            variant="contained"
            startIcon={<EuroIcon />}
            onClick={() => setTestDialogOpen(true)}
          >
            Tester l'Attribution de Points
          </Button>
        </CardContent>
      </Card>

      {/* Dialog de configuration */}
      <Dialog open={configDialogOpen} onClose={() => setConfigDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Configuration du Système de Fidélité</DialogTitle>
        <DialogContent>
          <Grid container spacing={2}>
            {config.map((item) => (
              <Grid item xs={12} sm={6} key={item.key}>
                <TextField
                  fullWidth
                  label={item.description}
                  value={editingConfig?.key === item.key ? editingConfig.value : item.value}
                  onChange={(e) => {
                    if (editingConfig?.key === item.key) {
                      setEditingConfig({ ...editingConfig, value: e.target.value });
                    }
                  }}
                  onFocus={() => setEditingConfig(item)}
                  InputProps={{
                    endAdornment: editingConfig?.key === item.key ? (
                      <Box>
                        <IconButton
                          size="small"
                          onClick={() => updateConfig(editingConfig)}
                          color="primary"
                        >
                          <SaveIcon />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => setEditingConfig(null)}
                          color="error"
                        >
                          <CancelIcon />
                        </IconButton>
                      </Box>
                    ) : null
                  }}
                />
              </Grid>
            ))}
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfigDialogOpen(false)}>Fermer</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog de test */}
      <Dialog open={testDialogOpen} onClose={() => setTestDialogOpen(false)}>
        <DialogTitle>Test du Système de Fidélité</DialogTitle>
        <DialogContent>
          <Box mt={2}>
            <TextField
              fullWidth
              label="ID du Client"
              value={testClientId}
              onChange={(e) => setTestClientId(e.target.value)}
              placeholder="UUID du client"
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              label="Montant de l'achat (€)"
              value={testAmount}
              onChange={(e) => setTestAmount(e.target.value)}
              placeholder="50.00"
              type="number"
              inputProps={{ step: "0.01", min: "0" }}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setTestDialogOpen(false)}>Annuler</Button>
          <Button
            onClick={testLoyaltyPoints}
            variant="contained"
            disabled={!testClientId || !testAmount}
          >
            Tester
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default LoyaltyManagement;

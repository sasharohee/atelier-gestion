import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Button,
  Chip,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  CircularProgress,
  Divider,
  Grid,
  Avatar,
  Badge,
  Switch,
  FormControlLabel,
  Accordion,
  AccordionSummary,
  AccordionDetails
} from '@mui/material';
import {
  CheckCircle as CheckIcon,
  Cancel as CancelIcon,
  Edit as EditIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
  Email as EmailIcon,
  Lock as LockIcon,
  LockOpen as LockOpenIcon,
  AdminPanelSettings as AdminIcon,
  ExpandMore as ExpandMoreIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  Warning as WarningIcon,
  Info as InfoIcon
} from '@mui/icons-material';
import { subscriptionService } from '../../services/supabaseService';
import { useAuth } from '../../hooks/useAuth';
import { SubscriptionStatus } from '../../types';
import { supabase } from '../../lib/supabase';

const UserAccessManagement: React.FC = () => {
  const { user: authUser } = useAuth();
  const [subscriptions, setSubscriptions] = useState<SubscriptionStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'inactive'>('all');
  const [showAdvanced, setShowAdvanced] = useState(false);
  
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    subscription: SubscriptionStatus | null;
    action: 'activate' | 'deactivate' | 'edit' | 'view';
    title: string;
  }>({
    open: false,
    subscription: null,
    action: 'activate',
    title: ''
  });
  
  const [formData, setFormData] = useState({
    notes: '',
    subscriptionType: 'free' as 'free' | 'premium' | 'enterprise'
  });
  
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);

  // Vérifier si l'utilisateur est administrateur ou technicien
  const userRole = authUser && (authUser as any).user_metadata?.role;
  const isAdmin = userRole === 'admin' || userRole === 'technician';

  const loadSubscriptions = async (forceRefresh = false) => {
    try {
      setLoading(true);
      setError(null);
      setSuccess(null);
      
      console.log('🔄 Rechargement des utilisateurs...', forceRefresh ? '(force refresh)' : '');
      
      // D'abord synchroniser les utilisateurs manquants
      try {
        console.log('🔄 Synchronisation des utilisateurs manquants...');
        const { data: syncResult, error: syncError } = await supabase.rpc('sync_missing_users_to_subscription');
        
        if (syncError) {
          console.warn('⚠️ Erreur lors de la synchronisation:', syncError);
        } else if (syncResult && syncResult.length > 0) {
          const syncData = syncResult[0];
          console.log(`✅ ${syncData.synchronized_count} utilisateurs synchronisés`);
          if (syncData.users_added && syncData.users_added.length > 0) {
            setSuccess(`${syncData.synchronized_count} utilisateurs synchronisés automatiquement`);
          }
        }
      } catch (syncErr) {
        console.warn('⚠️ Erreur lors de la synchronisation automatique:', syncErr);
      }
      
      // Ensuite charger les données
      const result = await subscriptionService.getAllSubscriptionStatuses();
      
      if (result.success && 'data' in result) {
        setSubscriptions(result.data || []);
        setLastRefresh(new Date());
        console.log(`✅ ${result.data?.length || 0} utilisateurs chargés`);
        if (!success) {
          setSuccess(`Liste actualisée : ${result.data?.length || 0} utilisateurs`);
        }
      } else if ('error' in result) {
        console.error('❌ Erreur lors du chargement:', result.error);
        setError(result.error);
      }
    } catch (err) {
      console.error('❌ Exception lors du chargement:', err);
      setError('Erreur lors du chargement des utilisateurs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Chargement temporairement autorisé pour tous les utilisateurs
    loadSubscriptions();
    
    // Rafraîchir automatiquement la liste toutes les 30 secondes
    const interval = setInterval(() => {
      loadSubscriptions();
    }, 30000);
    
    return () => clearInterval(interval);
  }, []);

  // Filtrer les utilisateurs
  const filteredSubscriptions = subscriptions.filter(subscription => {
    const matchesSearch = 
      subscription.first_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      subscription.last_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      subscription.email.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = 
      filterStatus === 'all' ||
      (filterStatus === 'active' && subscription.is_active) ||
      (filterStatus === 'inactive' && !subscription.is_active);
    
    return matchesSearch && matchesFilter;
  });

  const handleAction = (subscription: SubscriptionStatus, action: 'activate' | 'deactivate' | 'edit' | 'view') => {
    const titles = {
      activate: 'Activer l\'accès',
      deactivate: 'Désactiver l\'accès',
      edit: 'Modifier l\'utilisateur',
      view: 'Détails de l\'utilisateur'
    };

    setActionDialog({
      open: true,
      subscription,
      action,
      title: titles[action]
    });

    setFormData({
      notes: subscription.notes || '',
      subscriptionType: subscription.subscription_type
    });
  };

  const handleConfirmAction = async () => {
    if (!actionDialog.subscription) return;

    try {
      let result;
      
      switch (actionDialog.action) {
        case 'activate':
          result = await subscriptionService.activateSubscription(
            actionDialog.subscription.user_id,
            authUser?.id || 'admin',
            formData.notes
          );
          break;
        case 'deactivate':
          result = await subscriptionService.deactivateSubscription(
            actionDialog.subscription.user_id,
            formData.notes
          );
          break;
        case 'edit':
          result = await subscriptionService.updateSubscriptionType(
            actionDialog.subscription.user_id,
            formData.subscriptionType,
            formData.notes
          );
          break;
        default:
          return;
      }

      if (result.success) {
        const actionText = actionDialog.action === 'activate' ? 'activé' : 
                          actionDialog.action === 'deactivate' ? 'désactivé' : 'modifié';
        setSuccess(`Utilisateur ${actionText} avec succès - Rechargement automatique...`);
        
        // Recharger les données après un délai pour laisser le temps à la base de données
        setTimeout(() => {
          loadSubscriptions();
        }, 500);
        
        setActionDialog({ open: false, subscription: null, action: 'activate', title: '' });
      } else if ('error' in result) {
        setError(result.error);
      }
    } catch (err) {
      setError('Erreur lors de l\'exécution de l\'action');
    }
  };

  const getStatusColor = (isActive: boolean) => {
    return isActive ? 'success' : 'error';
  };

  const getStatusIcon = (isActive: boolean) => {
    return isActive ? <LockOpenIcon /> : <LockIcon />;
  };

  const getStatusText = (isActive: boolean) => {
    return isActive ? 'Accès Actif' : 'Accès Verrouillé';
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'premium': return 'warning';
      case 'enterprise': return 'error';
      default: return 'default';
    }
  };

  // Accès temporairement ouvert pour tous les utilisateurs
  // TODO: Remettre la vérification d'admin plus tard

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" component="h1" gutterBottom>
            Gestion des Accès Utilisateurs
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Interface d'administration pour activer/désactiver l'accès des utilisateurs
          </Typography>
          {lastRefresh && (
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
              Dernière actualisation : {lastRefresh.toLocaleTimeString('fr-FR')}
            </Typography>
          )}
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={async () => {
              try {
                console.log('🔄 Synchronisation manuelle...');
                const { data: syncResult, error: syncError } = await supabase.rpc('sync_missing_users_to_subscription');
                
                if (syncError) {
                  setError('Erreur lors de la synchronisation: ' + syncError.message);
                } else if (syncResult && syncResult.length > 0) {
                  const syncData = syncResult[0];
                  setSuccess(`${syncData.synchronized_count} utilisateurs synchronisés`);
                  loadSubscriptions(true);
                } else {
                  setSuccess('Tous les utilisateurs sont déjà synchronisés');
                }
              } catch (err) {
                setError('Erreur lors de la synchronisation');
              }
            }}
            disabled={loading}
          >
            Synchroniser
          </Button>
          <Button
            variant="contained"
            startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <RefreshIcon />}
            onClick={() => loadSubscriptions(true)}
            disabled={loading}
            sx={{ minWidth: 120 }}
          >
            {loading ? 'Actualisation...' : 'Actualiser'}
          </Button>
        </Box>
      </Box>

      {/* Messages d'alerte */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      {/* Statistiques */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <PersonIcon sx={{ mr: 2, color: 'primary.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Total utilisateurs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {subscriptions.length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <LockOpenIcon sx={{ mr: 2, color: 'success.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Accès actifs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {subscriptions.filter(s => s.is_active).length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <LockIcon sx={{ mr: 2, color: 'error.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Accès verrouillés
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {subscriptions.filter(s => !s.is_active).length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <WarningIcon sx={{ mr: 2, color: 'warning.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    En attente
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {subscriptions.filter(s => !s.is_active && !s.activated_at).length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filtres et recherche */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Rechercher par nom ou email..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Statut</InputLabel>
                <Select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value as any)}
                  label="Statut"
                >
                  <MenuItem value="all">Tous</MenuItem>
                  <MenuItem value="active">Actifs</MenuItem>
                  <MenuItem value="inactive">Verrouillés</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={3}>
              <Button
                variant="outlined"
                startIcon={<FilterIcon />}
                onClick={() => setShowAdvanced(!showAdvanced)}
              >
                {showAdvanced ? 'Masquer' : 'Afficher'} les filtres avancés
              </Button>
            </Grid>
            <Grid item xs={12} md={2}>
              <Typography variant="body2" color="text.secondary">
                {filteredSubscriptions.length} résultat(s)
              </Typography>
            </Grid>
          </Grid>

          {/* Filtres avancés */}
          {showAdvanced && (
            <Box sx={{ mt: 2, pt: 2, borderTop: 1, borderColor: 'divider' }}>
              <Grid container spacing={2}>
                <Grid item xs={12} md={4}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={filterStatus === 'active'}
                        onChange={(e) => setFilterStatus(e.target.checked ? 'active' : 'all')}
                      />
                    }
                    label="Afficher seulement les accès actifs"
                  />
                </Grid>
                <Grid item xs={12} md={4}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={filterStatus === 'inactive'}
                        onChange={(e) => setFilterStatus(e.target.checked ? 'inactive' : 'all')}
                      />
                    }
                    label="Afficher seulement les accès verrouillés"
                  />
                </Grid>
              </Grid>
            </Box>
          )}
        </CardContent>
      </Card>

      {/* Liste des utilisateurs */}
      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Utilisateur</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Date de création</TableCell>
                  <TableCell>Dernière action</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredSubscriptions.map((subscription) => (
                  <TableRow key={subscription.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Avatar sx={{ width: 32, height: 32 }}>
                          {subscription.first_name.charAt(0)}
                        </Avatar>
                        <Box>
                          <Typography variant="body2" fontWeight="medium">
                            {subscription.first_name} {subscription.last_name}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            ID: {subscription.user_id.slice(0, 8)}...
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <EmailIcon color="action" fontSize="small" />
                        {subscription.email}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        icon={getStatusIcon(subscription.is_active)}
                        label={getStatusText(subscription.is_active)}
                        color={getStatusColor(subscription.is_active)}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={subscription.subscription_type}
                        color={getTypeColor(subscription.subscription_type)}
                        variant="outlined"
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {new Date(subscription.created_at).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell>
                      {subscription.activated_at ? (
                        <Box>
                          <Typography variant="caption" display="block">
                            Activé le {new Date(subscription.activated_at).toLocaleDateString('fr-FR')}
                          </Typography>
                          {subscription.notes && (
                            <Typography variant="caption" color="text.secondary">
                              {subscription.notes.slice(0, 30)}...
                            </Typography>
                          )}
                        </Box>
                      ) : (
                        <Typography variant="caption" color="text.secondary">
                          Jamais activé
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
                        {subscription.is_active ? (
                          <Tooltip title="Désactiver l'accès">
                            <IconButton
                              color="error"
                              size="small"
                              onClick={() => handleAction(subscription, 'deactivate')}
                            >
                              <CancelIcon />
                            </IconButton>
                          </Tooltip>
                        ) : (
                          <Tooltip title="Activer l'accès">
                            <IconButton
                              color="success"
                              size="small"
                              onClick={() => handleAction(subscription, 'activate')}
                            >
                              <CheckIcon />
                            </IconButton>
                          </Tooltip>
                        )}
                        <Tooltip title="Modifier">
                          <IconButton
                            color="primary"
                            size="small"
                            onClick={() => handleAction(subscription, 'edit')}
                          >
                            <EditIcon />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Voir les détails">
                          <IconButton
                            color="info"
                            size="small"
                            onClick={() => handleAction(subscription, 'view')}
                          >
                            <VisibilityIcon />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Dialog d'action */}
      <Dialog 
        open={actionDialog.open} 
        onClose={() => setActionDialog({ open: false, subscription: null, action: 'activate', title: '' })}
        maxWidth="sm" 
        fullWidth
      >
        <DialogTitle>
          {actionDialog.title}
        </DialogTitle>
        <DialogContent>
          {actionDialog.subscription && (
            <Box sx={{ mt: 2 }}>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                    <Avatar sx={{ width: 48, height: 48 }}>
                      {actionDialog.subscription.first_name.charAt(0)}
                    </Avatar>
                    <Box>
                      <Typography variant="h6">
                        {actionDialog.subscription.first_name} {actionDialog.subscription.last_name}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {actionDialog.subscription.email}
                      </Typography>
                    </Box>
                  </Box>
                </Grid>
                
                <Grid item xs={12}>
                  <Divider />
                </Grid>

                <Grid item xs={12}>
                  <Typography variant="subtitle2" gutterBottom>
                    Statut actuel
                  </Typography>
                  <Chip
                    icon={getStatusIcon(actionDialog.subscription.is_active)}
                    label={getStatusText(actionDialog.subscription.is_active)}
                    color={getStatusColor(actionDialog.subscription.is_active)}
                  />
                </Grid>

                {actionDialog.action === 'edit' && (
                  <Grid item xs={12}>
                    <FormControl fullWidth>
                      <InputLabel>Type d'abonnement</InputLabel>
                      <Select
                        value={formData.subscriptionType}
                        onChange={(e) => setFormData({ ...formData, subscriptionType: e.target.value as any })}
                        label="Type d'abonnement"
                      >
                        <MenuItem value="free">Gratuit</MenuItem>
                        <MenuItem value="premium">Premium</MenuItem>
                        <MenuItem value="enterprise">Entreprise</MenuItem>
                      </Select>
                    </FormControl>
                  </Grid>
                )}

                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Notes (optionnel)"
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    placeholder="Raison de l'action, commentaires..."
                  />
                </Grid>

                {actionDialog.action === 'view' && actionDialog.subscription.notes && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" gutterBottom>
                      Notes existantes
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {actionDialog.subscription.notes}
                    </Typography>
                  </Grid>
                )}
              </Grid>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setActionDialog({ open: false, subscription: null, action: 'activate', title: '' })}>
            Annuler
          </Button>
          {actionDialog.action !== 'view' && (
            <Button
              onClick={handleConfirmAction}
              variant="contained"
              color={actionDialog.action === 'activate' ? 'success' : actionDialog.action === 'deactivate' ? 'error' : 'primary'}
            >
              Confirmer
            </Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default UserAccessManagement;

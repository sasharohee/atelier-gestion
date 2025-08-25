import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Alert,
  CircularProgress,
  Container,
  Paper,
  Divider,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Avatar,
  AppBar,
  Toolbar,
  TextField,
  Button
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
  Warning as WarningIcon,
  Security as SecurityIcon
} from '@mui/icons-material';
import { subscriptionService } from '../../services/supabaseService';
import { SubscriptionStatus } from '../../types';

const AdminAccess: React.FC = () => {
  // États de gestion des utilisateurs
  const [subscriptions, setSubscriptions] = useState<SubscriptionStatus[]>([]);
  const [loadingUsers, setLoadingUsers] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    subscription: SubscriptionStatus | null;
    action: 'activate' | 'deactivate' | 'edit';
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

  // Charger les utilisateurs au montage
  useEffect(() => {
    loadSubscriptions();
  }, []);

  const loadSubscriptions = async () => {
    try {
      setLoadingUsers(true);
      setError(null);
      
      // Utiliser le nouveau service qui combine les utilisateurs et les statuts
      const result = await subscriptionService.getUsersWithSubscriptionStatus();
      
      if (result.success && 'data' in result) {
        setSubscriptions(result.data || []);
      } else if ('error' in result) {
        setError(result.error);
      }
    } catch (err) {
      setError('Erreur lors du chargement des utilisateurs');
    } finally {
      setLoadingUsers(false);
    }
  };

  const handleAction = (subscription: SubscriptionStatus, action: 'activate' | 'deactivate' | 'edit') => {
    const titles = {
      activate: 'Donner l\'accès à l\'utilisateur',
      deactivate: 'Verrouiller l\'accès de l\'utilisateur',
      edit: 'Modifier le type d\'abonnement'
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
            undefined,
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
      }

      if (result.success) {
        const actionText = actionDialog.action === 'activate' ? 'a maintenant accès à l\'application' : 
                          actionDialog.action === 'deactivate' ? 'n\'a plus accès à l\'application' : 'a été modifié';
        setSuccess(`${actionDialog.subscription?.first_name} ${actionDialog.subscription?.last_name} ${actionText}`);
        
        // Rafraîchir la liste des utilisateurs
        console.log('🔄 Rafraîchissement de la liste des utilisateurs...');
        await loadSubscriptions();
        
        // Fermer le dialogue
        setActionDialog({ open: false, subscription: null, action: 'activate', title: '' });
        
        // Afficher un message de succès temporaire
        setTimeout(() => {
          setSuccess(null);
        }, 5000);
        
        // Afficher une notification pour l'utilisateur
        if (actionDialog.action === 'activate') {
          setSuccess(prev => prev + ' - L\'utilisateur devra se reconnecter pour voir les changements.');
        }
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

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'grey.50' }}>
      {/* Header */}
      <AppBar position="static" elevation={0}>
        <Toolbar>
          <SecurityIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Gestion des Accès Utilisateurs
          </Typography>
          <Typography variant="body2" color="inherit">
            Interface d'administration
          </Typography>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ py: 3 }}>
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

        {/* Actions */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
          <Typography variant="h5" component="h2">
            Liste des utilisateurs
          </Typography>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={loadSubscriptions}
            disabled={loadingUsers}
          >
            Actualiser
          </Button>
        </Box>

        {/* Liste des utilisateurs */}
        <Card>
          <CardContent>
            {loadingUsers ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
                <CircularProgress />
              </Box>
            ) : (
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
                    {subscriptions.map((subscription) => (
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
                          <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center', flexWrap: 'wrap' }}>
                            {subscription.is_active ? (
                              <Tooltip title="Verrouiller l'accès">
                                <Button
                                  variant="outlined"
                                  color="error"
                                  size="small"
                                  startIcon={<LockIcon />}
                                  onClick={() => handleAction(subscription, 'deactivate')}
                                  sx={{ minWidth: 'auto', px: 1 }}
                                >
                                  Verrouiller
                                </Button>
                              </Tooltip>
                            ) : (
                              <Tooltip title="Donner l'accès">
                                <Button
                                  variant="outlined"
                                  color="success"
                                  size="small"
                                  startIcon={<LockOpenIcon />}
                                  onClick={() => handleAction(subscription, 'activate')}
                                  sx={{ minWidth: 'auto', px: 1 }}
                                >
                                  Donner accès
                                </Button>
                              </Tooltip>
                            )}
                            <Tooltip title="Modifier le type d'abonnement">
                              <IconButton
                                color="primary"
                                size="small"
                                onClick={() => handleAction(subscription, 'edit')}
                              >
                                <EditIcon />
                              </IconButton>
                            </Tooltip>
                          </Box>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}
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
                </Grid>
              </Box>
            )}
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setActionDialog({ open: false, subscription: null, action: 'activate', title: '' })}>
              Annuler
            </Button>
            <Button
              onClick={handleConfirmAction}
              variant="contained"
              color={actionDialog.action === 'activate' ? 'success' : actionDialog.action === 'deactivate' ? 'error' : 'primary'}
            >
              {actionDialog.action === 'activate' ? 'Donner l\'accès' : 
               actionDialog.action === 'deactivate' ? 'Verrouiller l\'accès' : 'Modifier'}
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </Box>
  );
};

export default AdminAccess;

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
  CircularProgress
} from '@mui/material';
import {
  CheckCircle as CheckIcon,
  Cancel as CancelIcon,
  Edit as EditIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
  Email as EmailIcon
} from '@mui/icons-material';
import { subscriptionService } from '../../services/supabaseService';
import { SubscriptionStatus } from '../../types';

const SubscriptionManagement: React.FC = () => {
  const [subscriptions, setSubscriptions] = useState<SubscriptionStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [editDialog, setEditDialog] = useState<{
    open: boolean;
    subscription: SubscriptionStatus | null;
    action: 'activate' | 'deactivate' | 'edit';
  }>({
    open: false,
    subscription: null,
    action: 'activate'
  });
  const [notes, setNotes] = useState('');

  const loadSubscriptions = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const result = await subscriptionService.getAllSubscriptionStatuses();
      
      if (result.success && 'data' in result) {
        setSubscriptions(result.data || []);
      } else if ('error' in result) {
        setError(result.error);
      }
    } catch (err) {
      setError('Erreur lors du chargement des utilisateurs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSubscriptions();
  }, []);

  const handleActivate = async (subscription: SubscriptionStatus) => {
    setEditDialog({
      open: true,
      subscription,
      action: 'activate'
    });
    setNotes('');
  };

  const handleDeactivate = async (subscription: SubscriptionStatus) => {
    setEditDialog({
      open: true,
      subscription,
      action: 'deactivate'
    });
    setNotes('');
  };

  const handleEdit = async (subscription: SubscriptionStatus) => {
    setEditDialog({
      open: true,
      subscription,
      action: 'edit'
    });
    setNotes(subscription.notes || '');
  };

  const handleConfirmAction = async () => {
    if (!editDialog.subscription) return;

    try {
      let result;
      
      switch (editDialog.action) {
        case 'activate':
          result = await subscriptionService.activateSubscription(
            editDialog.subscription.user_id,
            'admin', // ID de l'administrateur actuel
            notes
          );
          break;
        case 'deactivate':
          result = await subscriptionService.deactivateSubscription(
            editDialog.subscription.user_id,
            notes
          );
          break;
        case 'edit':
          result = await subscriptionService.updateSubscriptionType(
            editDialog.subscription.user_id,
            editDialog.subscription.subscription_type,
            notes
          );
          break;
      }

      if (result.success) {
        setSuccess(`Action ${editDialog.action === 'activate' ? 'd\'activation' : editDialog.action === 'deactivate' ? 'de désactivation' : 'de modification'} réussie`);
        loadSubscriptions();
        setEditDialog({ open: false, subscription: null, action: 'activate' });
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

  const getStatusText = (isActive: boolean) => {
    return isActive ? 'Actif' : 'Verrouillé';
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Gestion des Accès Utilisateurs
        </Typography>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadSubscriptions}
        >
          Actualiser
        </Button>
      </Box>

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

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Utilisateurs ({subscriptions.length})
          </Typography>
          
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Utilisateur</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Date de création</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {subscriptions.map((subscription) => (
                  <TableRow key={subscription.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <PersonIcon color="action" />
                        <Box>
                          <Typography variant="body2" fontWeight="medium">
                            {subscription.first_name} {subscription.last_name}
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
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        {subscription.is_active ? (
                          <Tooltip title="Désactiver l'accès">
                            <IconButton
                              color="error"
                              size="small"
                              onClick={() => handleDeactivate(subscription)}
                            >
                              <CancelIcon />
                            </IconButton>
                          </Tooltip>
                        ) : (
                          <Tooltip title="Activer l'accès">
                            <IconButton
                              color="success"
                              size="small"
                              onClick={() => handleActivate(subscription)}
                            >
                              <CheckIcon />
                            </IconButton>
                          </Tooltip>
                        )}
                        <Tooltip title="Modifier">
                          <IconButton
                            color="primary"
                            size="small"
                            onClick={() => handleEdit(subscription)}
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
        </CardContent>
      </Card>

      {/* Dialog de confirmation */}
      <Dialog open={editDialog.open} onClose={() => setEditDialog({ open: false, subscription: null, action: 'activate' })} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editDialog.action === 'activate' && 'Activer l\'accès'}
          {editDialog.action === 'deactivate' && 'Désactiver l\'accès'}
          {editDialog.action === 'edit' && 'Modifier l\'utilisateur'}
        </DialogTitle>
        <DialogContent>
          {editDialog.subscription && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Utilisateur : {editDialog.subscription.first_name} {editDialog.subscription.last_name}
              </Typography>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Email : {editDialog.subscription.email}
              </Typography>
              
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Notes (optionnel)"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                sx={{ mt: 2 }}
                placeholder="Raison de l'action..."
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialog({ open: false, subscription: null, action: 'activate' })}>
            Annuler
          </Button>
          <Button
            onClick={handleConfirmAction}
            variant="contained"
            color={editDialog.action === 'activate' ? 'success' : editDialog.action === 'deactivate' ? 'error' : 'primary'}
          >
            Confirmer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default SubscriptionManagement;

import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  TextField,
  Button,
  Card,
  CardContent,
  Grid,
  Chip,
  Alert,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions
} from '@mui/material';
import {
  Search as SearchIcon,
  Visibility as VisibilityIcon,
  History as HistoryIcon,
  Email as EmailIcon,
  Build as BuildIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  Receipt as ReceiptIcon,
  Assignment as AssignmentIcon,
  Person as PersonIcon,
  DeviceHub as DeviceIcon,
  Euro as EuroIcon,
  CalendarToday as CalendarIcon,
  AccessTime as TimeIcon,
  PriorityHigh as PriorityIcon,
  Home as HomeIcon
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { repairTrackingService, RepairHistoryItem, RepairTrackingData } from '../../services/repairTrackingService';
import { useNavigate } from 'react-router-dom';

const repairStatuses = {
  'new': { label: 'Nouvelle', color: 'default', icon: InfoIcon },
  'in_progress': { label: 'En cours', color: 'primary', icon: BuildIcon },
  'waiting_parts': { label: 'En attente de pièces', color: 'warning', icon: ScheduleIcon },
  'waiting_delivery': { label: 'Livraison attendue', color: 'info', icon: ScheduleIcon },
  'completed': { label: 'Terminée', color: 'success', icon: CheckCircleIcon },
  'cancelled': { label: 'Annulée', color: 'error', icon: WarningIcon },
  'returned': { label: 'Restituée', color: 'success', icon: CheckCircleIcon }
};

const RepairHistory: React.FC = () => {
  const [email, setEmail] = useState('');
  const [repairHistory, setRepairHistory] = useState<RepairHistoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedRepair, setSelectedRepair] = useState<RepairTrackingData | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const navigate = useNavigate();

  const searchHistory = async () => {
    if (!email) {
      setError('Veuillez saisir votre email');
      return;
    }

    setLoading(true);
    setError(null);
    setRepairHistory([]);

    try {
      const data = await repairTrackingService.getClientRepairHistory(email);
      setRepairHistory(data);
      
      if (data.length === 0) {
        setError('Aucune réparation trouvée pour cet email');
      }
    } catch (err) {
      setError('Erreur lors de la recherche de votre historique');
    } finally {
      setLoading(false);
    }
  };

  const viewRepairDetails = async (repairId: string) => {
    try {
      const data = await repairTrackingService.getRepairTracking(repairId, email);
      if (data) {
        setSelectedRepair(data);
        setDialogOpen(true);
      }
    } catch (err) {
      setError('Erreur lors du chargement des détails');
    }
  };

  const getStatusIcon = (status: string) => {
    const statusConfig = repairStatuses[status as keyof typeof repairStatuses];
    return statusConfig ? statusConfig.icon : InfoIcon;
  };

  const getStatusColor = (status: string) => {
    const statusConfig = repairStatuses[status as keyof typeof repairStatuses];
    return statusConfig ? statusConfig.color : 'default';
  };

  const getStatusLabel = (status: string) => {
    const statusConfig = repairStatuses[status as keyof typeof repairStatuses];
    if (statusConfig) {
      return statusConfig.label;
    }
    
    // Fallback pour les statuts non mappés
    const statusFallbacks: { [key: string]: string } = {
      'pending': 'En attente',
      'delivered': 'Livrée',
      'shipped': 'Expédiée',
      'diagnosed': 'Diagnostiquée',
      'quoted': 'Devisé',
      'approved': 'Approuvée',
      'rejected': 'Rejetée',
      'on_hold': 'En pause',
      'scheduled': 'Programmée',
      'in_diagnosis': 'En diagnostic',
      'parts_ordered': 'Pièces commandées',
      'quality_check': 'Contrôle qualité',
      'ready_for_pickup': 'Prête à récupérer',
      'picked_up': 'Récupérée'
    };
    
    return statusFallbacks[status] || status;
  };

  const formatDate = (dateString: string) => {
    return format(new Date(dateString), 'dd/MM/yyyy à HH:mm', { locale: fr });
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(price);
  };

  const handleGoToTracking = () => {
    navigate('/repair-tracking');
  };

  const handleGoToHome = () => {
    navigate('/');
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ textAlign: 'center', mb: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Button
            variant="outlined"
            onClick={handleGoToHome}
            startIcon={<HomeIcon />}
            sx={{ minWidth: 'auto' }}
          >
            Accueil
          </Button>
          <Box sx={{ flex: 1 }} />
        </Box>
        <Typography variant="h3" component="h1" gutterBottom>
          Historique des Réparations
        </Typography>
        <Typography variant="h6" color="text.secondary">
          Consultez l'historique complet de vos réparations
        </Typography>
      </Box>

      {/* Formulaire de recherche */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h5" gutterBottom>
            Rechercher votre historique
          </Typography>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={8}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="votre@email.com"
                InputProps={{
                  startAdornment: <EmailIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <Button
                fullWidth
                variant="contained"
                onClick={searchHistory}
                disabled={loading || !email}
                startIcon={loading ? <CircularProgress size={20} /> : <SearchIcon />}
                sx={{ height: 56 }}
              >
                {loading ? 'Recherche...' : 'Rechercher'}
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Message d'erreur */}
      {error && (
        <Alert severity="error" sx={{ mb: 4 }}>
          {error}
        </Alert>
      )}

      {/* Affichage de l'historique */}
      {repairHistory.length > 0 && (
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                  <Typography variant="h6">
                    Vos réparations ({repairHistory.length})
                  </Typography>
                  <Button
                    variant="outlined"
                    onClick={handleGoToTracking}
                    startIcon={<AssignmentIcon />}
                  >
                    Suivre une réparation
                  </Button>
                </Box>

                <TableContainer component={Paper} variant="outlined">
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell>Réparation</TableCell>
                        <TableCell>Appareil</TableCell>
                        <TableCell>Statut</TableCell>
                        <TableCell>Prix</TableCell>
                        <TableCell>Date</TableCell>
                        <TableCell>Actions</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {repairHistory.map((repair) => (
                        <TableRow key={repair.id} hover>
                                                     <TableCell>
                             <Box>
                               <Typography variant="body2" fontWeight="medium">
                                 {repair.repairNumber || `#${repair.id.slice(0, 8)}`}
                               </Typography>
                               <Typography variant="caption" color="text.secondary">
                                 {repair.description}
                               </Typography>
                             </Box>
                           </TableCell>
                          <TableCell>
                            {repair.device ? (
                              <Box>
                                <Typography variant="body2">
                                  {repair.device.brand} {repair.device.model}
                                </Typography>
                              </Box>
                            ) : (
                              <Typography variant="body2" color="text.secondary">
                                Non spécifié
                              </Typography>
                            )}
                          </TableCell>
                          <TableCell>
                            <Chip
                              icon={React.createElement(getStatusIcon(repair.status))}
                              label={getStatusLabel(repair.status)}
                              color={getStatusColor(repair.status) as any}
                              size="small"
                            />
                          </TableCell>
                          <TableCell>
                            <Box>
                              <Typography variant="body2" fontWeight="medium">
                                {formatPrice(repair.totalPrice)}
                              </Typography>
                              <Chip
                                label={repair.isPaid ? 'Payé' : 'En attente'}
                                color={repair.isPaid ? 'success' : 'warning'}
                                size="small"
                                variant="outlined"
                              />
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Typography variant="body2">
                              {formatDate(repair.createdAt)}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Tooltip title="Voir les détails">
                              <IconButton
                                size="small"
                                onClick={() => viewRepairDetails(repair.id)}
                                color="primary"
                              >
                                <VisibilityIcon />
                              </IconButton>
                            </Tooltip>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Dialog pour les détails de réparation */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
                     Détails de la réparation
           {selectedRepair && (
             <Typography variant="subtitle2" color="text.secondary">
               {selectedRepair.repairNumber || `#${selectedRepair.id.slice(0, 8)}`}
             </Typography>
           )}
        </DialogTitle>
        <DialogContent>
          {selectedRepair && (
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Chip
                    icon={React.createElement(getStatusIcon(selectedRepair.status))}
                    label={getStatusLabel(selectedRepair.status)}
                    color={getStatusColor(selectedRepair.status) as any}
                    size="medium"
                  />
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Typography variant="h6" gutterBottom>
                  Description
                </Typography>
                <Typography variant="body2" paragraph>
                  {selectedRepair.description}
                </Typography>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Typography variant="h6" gutterBottom>
                  Problème identifié
                </Typography>
                <Typography variant="body2" paragraph>
                  {selectedRepair.issue}
                </Typography>
              </Grid>

              {selectedRepair.device && (
                <Grid item xs={12}>
                  <Typography variant="h6" gutterBottom>
                    Appareil
                  </Typography>
                  <Typography variant="body2">
                    {selectedRepair.device.brand} {selectedRepair.device.model} ({selectedRepair.device.type})
                  </Typography>
                </Grid>
              )}

              <Grid item xs={12} md={6}>
                <Typography variant="h6" gutterBottom>
                  Prix
                </Typography>
                <Typography variant="h5" color="primary" gutterBottom>
                  {formatPrice(selectedRepair.totalPrice)}
                </Typography>
                <Chip
                  label={selectedRepair.isPaid ? 'Payé' : 'En attente de paiement'}
                  color={selectedRepair.isPaid ? 'success' : 'warning'}
                  icon={selectedRepair.isPaid ? <CheckCircleIcon /> : <ReceiptIcon />}
                />
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="h6" gutterBottom>
                  Dates importantes
                </Typography>
                <Typography variant="body2">
                  Créée le : {formatDate(selectedRepair.createdAt)}
                </Typography>
                {selectedRepair.startDate && (
                  <Typography variant="body2">
                    Début : {formatDate(selectedRepair.startDate)}
                  </Typography>
                )}
                {selectedRepair.endDate && (
                  <Typography variant="body2">
                    Fin : {formatDate(selectedRepair.endDate)}
                  </Typography>
                )}
              </Grid>

              {selectedRepair.notes && (
                <Grid item xs={12}>
                  <Typography variant="h6" gutterBottom>
                    Notes du technicien
                  </Typography>
                  <Typography variant="body2">
                    {selectedRepair.notes}
                  </Typography>
                </Grid>
              )}
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>
            Fermer
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default RepairHistory;

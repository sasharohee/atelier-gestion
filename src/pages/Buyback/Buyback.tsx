import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Card,
  CardContent,
  Fab,
  Tooltip,
  Alert,
  CircularProgress,
  Menu,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Print as PrintIcon,
  Visibility as ViewIcon,
  MoreVert as MoreVertIcon,
  MonetizationOn as MonetizationOnIcon,
  Search as SearchIcon,
  FilterList as FilterListIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  AttachMoney as AttachMoneyIcon,
  Schedule as ScheduleIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Buyback, BuybackStatus } from '../../types';
import { buybackService } from '../../services/supabaseService';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
// import BuybackForm from './BuybackForm';
// import BuybackTicket from '../../components/BuybackTicket';
import toast from 'react-hot-toast';

const Buyback: React.FC = () => {
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';
  
  const [buybacks, setBuybacks] = useState<Buyback[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBuyback, setSelectedBuyback] = useState<Buyback | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [showTicket, setShowTicket] = useState(false);
  const [showDetails, setShowDetails] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<BuybackStatus | 'all'>('all');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [actionBuyback, setActionBuyback] = useState<Buyback | null>(null);

  useEffect(() => {
    loadBuybacks();
  }, []);

  const loadBuybacks = async () => {
    setLoading(true);
    try {
      const result = await buybackService.getAll();
      if (result.success) {
        setBuybacks(result.data || []);
      } else {
        toast.error('Erreur lors du chargement des rachats');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des rachats:', error);
      toast.error('Erreur lors du chargement des rachats');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (buyback: Buyback) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce rachat ?')) {
      try {
        const result = await buybackService.delete(buyback.id);
        if (result.success) {
          toast.success('Rachat supprimé avec succès');
          loadBuybacks();
        } else {
          toast.error('Erreur lors de la suppression');
        }
      } catch (error) {
        console.error('Erreur lors de la suppression:', error);
        toast.error('Erreur lors de la suppression');
      }
    }
  };

  const handleStatusUpdate = async (buyback: Buyback, newStatus: BuybackStatus) => {
    try {
      const result = await buybackService.updateStatus(buyback.id, newStatus);
      if (result.success) {
        toast.success('Statut mis à jour avec succès');
        loadBuybacks();
      } else {
        toast.error('Erreur lors de la mise à jour du statut');
      }
    } catch (error) {
      console.error('Erreur lors de la mise à jour:', error);
      toast.error('Erreur lors de la mise à jour du statut');
    }
  };

  const getStatusColor = (status: BuybackStatus) => {
    const colors: { [key: string]: 'default' | 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning' } = {
      'pending': 'warning',
      'accepted': 'info',
      'rejected': 'error',
      'paid': 'success'
    };
    return colors[status] || 'default';
  };

  const getStatusLabel = (status: BuybackStatus) => {
    const labels: { [key: string]: string } = {
      'pending': 'En attente',
      'accepted': 'Accepté',
      'rejected': 'Refusé',
      'paid': 'Payé'
    };
    return labels[status] || status;
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels: { [key: string]: string } = {
      'cash': 'Espèces',
      'transfer': 'Virement',
      'check': 'Chèque',
      'credit': 'Avoir'
    };
    return labels[method] || method;
  };

  const filteredBuybacks = buybacks.filter(buyback => {
    const matchesSearch = 
      buyback.clientFirstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      buyback.clientLastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      buyback.deviceBrand.toLowerCase().includes(searchTerm.toLowerCase()) ||
      buyback.deviceModel.toLowerCase().includes(searchTerm.toLowerCase()) ||
      buyback.deviceImei?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'all' || buyback.status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });

  const getStats = () => {
    const total = buybacks.length;
    const pending = buybacks.filter(b => b.status === 'pending').length;
    const accepted = buybacks.filter(b => b.status === 'accepted').length;
    const paid = buybacks.filter(b => b.status === 'paid').length;
    const totalValue = buybacks
      .filter(b => b.status === 'paid')
      .reduce((sum, b) => sum + (b.finalPrice || b.offeredPrice), 0);

    return { total, pending, accepted, paid, totalValue };
  };

  const stats = getStats();

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, buyback: Buyback) => {
    setAnchorEl(event.currentTarget);
    setActionBuyback(buyback);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setActionBuyback(null);
  };

  const handleMenuAction = (action: string) => {
    if (!actionBuyback) return;

    switch (action) {
      case 'view':
        setSelectedBuyback(actionBuyback);
        setShowDetails(true);
        break;
      case 'edit':
        setSelectedBuyback(actionBuyback);
        setShowForm(true);
        break;
      case 'print':
        setSelectedBuyback(actionBuyback);
        setShowTicket(true);
        break;
      case 'delete':
        handleDelete(actionBuyback);
        break;
      case 'accept':
        handleStatusUpdate(actionBuyback, 'accepted');
        break;
      case 'reject':
        handleStatusUpdate(actionBuyback, 'rejected');
        break;
      case 'markPaid':
        handleStatusUpdate(actionBuyback, 'paid');
        break;
    }

    handleMenuClose();
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
      <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <MonetizationOnIcon sx={{ color: '#10b981' }} />
        Rachat d'appareils
      </Typography>

      {/* Statistiques */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Total rachats
                  </Typography>
                  <Typography variant="h4">
                    {stats.total}
                  </Typography>
                </Box>
                <MonetizationOnIcon sx={{ fontSize: 40, color: '#10b981' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    En attente
                  </Typography>
                  <Typography variant="h4">
                    {stats.pending}
                  </Typography>
                </Box>
                <ScheduleIcon sx={{ fontSize: 40, color: '#f59e0b' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Acceptés
                  </Typography>
                  <Typography variant="h4">
                    {stats.accepted}
                  </Typography>
                </Box>
                <CheckCircleIcon sx={{ fontSize: 40, color: '#3b82f6' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Valeur totale
                  </Typography>
                  <Typography variant="h4">
                    {formatFromEUR(stats.totalValue, currency)}
                  </Typography>
                </Box>
                <AttachMoneyIcon sx={{ fontSize: 40, color: '#10b981' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filtres et recherche */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={4}>
            <TextField
              fullWidth
              placeholder="Rechercher..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
              }}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>Statut</InputLabel>
              <Select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as BuybackStatus | 'all')}
              >
                <MenuItem value="all">Tous les statuts</MenuItem>
                <MenuItem value="pending">En attente</MenuItem>
                <MenuItem value="accepted">Accepté</MenuItem>
                <MenuItem value="rejected">Refusé</MenuItem>
                <MenuItem value="paid">Payé</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={12} md={5}>
            <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => {
                  setSelectedBuyback(null);
                  setShowForm(true);
                }}
                sx={{ backgroundColor: '#10b981', '&:hover': { backgroundColor: '#059669' } }}
              >
                Nouveau rachat
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Table des rachats */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Client</TableCell>
              <TableCell>Appareil</TableCell>
              <TableCell>IMEI</TableCell>
              <TableCell>Prix proposé</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Date</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredBuybacks.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  <Box sx={{ py: 4 }}>
                    <Typography variant="body1" color="textSecondary">
                      {buybacks.length === 0 ? 'Aucun rachat trouvé' : 'Aucun résultat pour cette recherche'}
                    </Typography>
                    {buybacks.length === 0 && (
                      <Button
                        variant="contained"
                        startIcon={<AddIcon />}
                        onClick={() => {
                          setSelectedBuyback(null);
                          setShowForm(true);
                        }}
                        sx={{ mt: 2, backgroundColor: '#10b981', '&:hover': { backgroundColor: '#059669' } }}
                      >
                        Créer le premier rachat
                      </Button>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ) : (
              filteredBuybacks.map((buyback) => (
                <TableRow key={buyback.id} hover>
                  <TableCell>
                    <Box>
                      <Typography variant="body2" fontWeight="medium">
                        {buyback.clientFirstName} {buyback.clientLastName}
                      </Typography>
                      <Typography variant="caption" color="textSecondary">
                        {buyback.clientEmail}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box>
                      <Typography variant="body2" fontWeight="medium">
                        {buyback.deviceBrand} {buyback.deviceModel}
                      </Typography>
                      <Typography variant="caption" color="textSecondary">
                        {buyback.deviceType} • {buyback.deviceColor}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {buyback.deviceImei || '-'}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" fontWeight="medium">
                      {formatFromEUR(buyback.offeredPrice, currency)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(buyback.status)}
                      color={getStatusColor(buyback.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {format(new Date(buyback.createdAt), 'dd/MM/yyyy', { locale: fr })}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <IconButton
                      onClick={(e) => handleMenuClick(e, buyback)}
                      size="small"
                    >
                      <MoreVertIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Menu contextuel */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={() => handleMenuAction('view')}>
          <ListItemIcon>
            <ViewIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Voir les détails</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => handleMenuAction('edit')}>
          <ListItemIcon>
            <EditIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Modifier</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => handleMenuAction('print')}>
          <ListItemIcon>
            <PrintIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Imprimer ticket</ListItemText>
        </MenuItem>
        {actionBuyback?.status === 'pending' && (
          <>
            <MenuItem onClick={() => handleMenuAction('accept')}>
              <ListItemIcon>
                <CheckCircleIcon fontSize="small" />
              </ListItemIcon>
              <ListItemText>Accepter</ListItemText>
            </MenuItem>
            <MenuItem onClick={() => handleMenuAction('reject')}>
              <ListItemIcon>
                <CancelIcon fontSize="small" />
              </ListItemIcon>
              <ListItemText>Refuser</ListItemText>
            </MenuItem>
          </>
        )}
        {actionBuyback?.status === 'accepted' && (
          <MenuItem onClick={() => handleMenuAction('markPaid')}>
            <ListItemIcon>
              <AttachMoneyIcon fontSize="small" />
            </ListItemIcon>
            <ListItemText>Marquer comme payé</ListItemText>
          </MenuItem>
        )}
        <MenuItem onClick={() => handleMenuAction('delete')} sx={{ color: 'error.main' }}>
          <ListItemIcon>
            <DeleteIcon fontSize="small" color="error" />
          </ListItemIcon>
          <ListItemText>Supprimer</ListItemText>
        </MenuItem>
      </Menu>

      {/* Formulaire */}
      {/* {showForm && (
        <Dialog open={showForm} onClose={() => setShowForm(false)} maxWidth="lg" fullWidth>
          <DialogContent sx={{ p: 0 }}>
            <BuybackForm
              buyback={selectedBuyback || undefined}
              onSave={(buyback) => {
                setShowForm(false);
                loadBuybacks();
              }}
              onCancel={() => setShowForm(false)}
            />
          </DialogContent>
        </Dialog>
      )} */}

      {/* Ticket de rachat */}
      {/* {showTicket && selectedBuyback && (
        <BuybackTicket
          buyback={selectedBuyback}
          open={showTicket}
          onClose={() => setShowTicket(false)}
        />
      )} */}

      {/* Détails */}
      {showDetails && selectedBuyback && (
        <Dialog open={showDetails} onClose={() => setShowDetails(false)} maxWidth="md" fullWidth>
          <DialogTitle>
            <Typography variant="h6">
              Détails du rachat #{selectedBuyback.id.slice(0, 8)}
            </Typography>
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                <Typography variant="h6" gutterBottom>Informations Client</Typography>
                <Typography variant="body2"><strong>Nom:</strong> {selectedBuyback.clientFirstName} {selectedBuyback.clientLastName}</Typography>
                <Typography variant="body2"><strong>Email:</strong> {selectedBuyback.clientEmail}</Typography>
                <Typography variant="body2"><strong>Téléphone:</strong> {selectedBuyback.clientPhone}</Typography>
                {selectedBuyback.clientAddress && (
                  <Typography variant="body2"><strong>Adresse:</strong> {selectedBuyback.clientAddress}</Typography>
                )}
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <Typography variant="h6" gutterBottom>Informations Appareil</Typography>
                <Typography variant="body2"><strong>Type:</strong> {selectedBuyback.deviceType}</Typography>
                <Typography variant="body2"><strong>Marque/Modèle:</strong> {selectedBuyback.deviceBrand} {selectedBuyback.deviceModel}</Typography>
                <Typography variant="body2"><strong>IMEI:</strong> {selectedBuyback.deviceImei || 'Non renseigné'}</Typography>
                <Typography variant="body2"><strong>Couleur:</strong> {selectedBuyback.deviceColor || 'Non renseigné'}</Typography>
                <Typography variant="body2"><strong>Capacité:</strong> {selectedBuyback.deviceStorageCapacity || 'Non renseigné'}</Typography>
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <Typography variant="h6" gutterBottom>État Technique</Typography>
                <Typography variant="body2"><strong>État physique:</strong> {selectedBuyback.physicalCondition}</Typography>
                <Typography variant="body2"><strong>Santé batterie:</strong> {selectedBuyback.batteryHealth ? `${selectedBuyback.batteryHealth}%` : 'Non renseigné'}</Typography>
                <Typography variant="body2"><strong>État écran:</strong> {selectedBuyback.screenCondition || 'Non renseigné'}</Typography>
                <Typography variant="body2"><strong>Blocages:</strong> {
                  [selectedBuyback.icloudLocked && 'iCloud', selectedBuyback.googleLocked && 'Google', selectedBuyback.carrierLocked && 'Opérateur']
                    .filter(Boolean).join(', ') || 'Aucun'
                }</Typography>
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <Typography variant="h6" gutterBottom>Détails Financiers</Typography>
                <Typography variant="body2"><strong>Prix suggéré:</strong> {selectedBuyback.suggestedPrice ? formatFromEUR(selectedBuyback.suggestedPrice, currency) : 'Non calculé'}</Typography>
                <Typography variant="body2"><strong>Prix proposé:</strong> {formatFromEUR(selectedBuyback.offeredPrice, currency)}</Typography>
                <Typography variant="body2"><strong>Prix final:</strong> {selectedBuyback.finalPrice ? formatFromEUR(selectedBuyback.finalPrice, currency) : 'Non défini'}</Typography>
                <Typography variant="body2"><strong>Mode de paiement:</strong> {getPaymentMethodLabel(selectedBuyback.paymentMethod)}</Typography>
                <Typography variant="body2"><strong>Raison:</strong> {selectedBuyback.buybackReason}</Typography>
              </Grid>
              
              {selectedBuyback.internalNotes && (
                <Grid item xs={12}>
                  <Typography variant="h6" gutterBottom>Notes Internes</Typography>
                  <Typography variant="body2">{selectedBuyback.internalNotes}</Typography>
                </Grid>
              )}
              
              {selectedBuyback.clientNotes && (
                <Grid item xs={12}>
                  <Typography variant="h6" gutterBottom>Notes du Client</Typography>
                  <Typography variant="body2">{selectedBuyback.clientNotes}</Typography>
                </Grid>
              )}
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setShowDetails(false)}>Fermer</Button>
            <Button 
              variant="contained" 
              startIcon={<EditIcon />}
              onClick={() => {
                setShowDetails(false);
                setShowForm(true);
              }}
            >
              Modifier
            </Button>
            <Button 
              variant="contained" 
              startIcon={<PrintIcon />}
              onClick={() => {
                setShowDetails(false);
                setShowTicket(true);
              }}
            >
              Imprimer
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </Box>
  );
};

export default Buyback;

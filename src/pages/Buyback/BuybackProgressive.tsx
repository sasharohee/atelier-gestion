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
  DialogContent,
  DialogTitle,
  DialogActions,
  Grid,
  Card,
  CardContent,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Print as PrintIcon,
  Visibility as ViewIcon,
  MonetizationOn as MonetizationOnIcon,
  Search as SearchIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  AttachMoney as AttachMoneyIcon,
  Schedule as ScheduleIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Buyback, BuybackStatus } from '../../types';
import { buybackService } from '../../services/supabaseService';
import { toast } from 'react-hot-toast';
import BuybackForm from './BuybackForm';
import BuybackTicket from '../../components/BuybackTicket';

const BuybackProgressive: React.FC = () => {
  const [buybacks, setBuybacks] = useState<Buyback[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<BuybackStatus | 'all'>('all');
  const [showForm, setShowForm] = useState(false);
  const [selectedBuyback, setSelectedBuyback] = useState<Buyback | null>(null);
  const [showDetails, setShowDetails] = useState(false);
  const [showTicket, setShowTicket] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [buybackToDelete, setBuybackToDelete] = useState<Buyback | null>(null);

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

  const handleViewDetails = (buyback: Buyback) => {
    setSelectedBuyback(buyback);
    setShowDetails(true);
  };

  const handleEdit = (buyback: Buyback) => {
    setSelectedBuyback(buyback);
    setShowForm(true);
  };

  const handlePrintTicket = (buyback: Buyback) => {
    setSelectedBuyback(buyback);
    setShowTicket(true);
  };

  const handleDeleteClick = (buyback: Buyback) => {
    setBuybackToDelete(buyback);
    setShowDeleteDialog(true);
  };

  const handleConfirmDelete = async () => {
    if (!buybackToDelete) return;
    
    try {
      const result = await buybackService.delete(buybackToDelete.id);
      if (result.success) {
        toast.success('Rachat supprimé avec succès');
        loadBuybacks();
      } else {
        toast.error('Erreur lors de la suppression');
      }
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
      toast.error('Erreur lors de la suppression');
    } finally {
      setShowDeleteDialog(false);
      setBuybackToDelete(null);
    }
  };

  const handleUpdateStatus = async (buyback: Buyback, newStatus: BuybackStatus) => {
    try {
      const result = await buybackService.updateStatus(buyback.id, newStatus);
      if (result.success) {
        if (newStatus === 'paid') {
          toast.success(`Rachat marqué comme payé et dépense créée automatiquement dans la comptabilité`, {
            duration: 5000,
            icon: '💰'
          });
        } else {
          toast.success(`Statut mis à jour vers ${getStatusLabel(newStatus)}`);
        }
        loadBuybacks();
      } else {
        toast.error('Erreur lors de la mise à jour du statut');
      }
    } catch (error) {
      console.error('Erreur lors de la mise à jour du statut:', error);
      toast.error('Erreur lors de la mise à jour du statut');
    }
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
                    {stats.totalValue.toLocaleString('fr-FR')} €
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
              <TableCell>Prix final</TableCell>
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
                      <Alert severity="info" sx={{ mt: 2 }}>
                        La base de données est vide. Créez votre premier rachat d'appareil.
                      </Alert>
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
                      {(buyback.finalPrice || buyback.offeredPrice).toLocaleString('fr-FR')} €
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
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <IconButton 
                        size="small" 
                        title="Voir les détails"
                        onClick={() => handleViewDetails(buyback)}
                      >
                        <ViewIcon />
                      </IconButton>
                      <IconButton 
                        size="small" 
                        title="Modifier"
                        onClick={() => handleEdit(buyback)}
                      >
                        <EditIcon />
                      </IconButton>
                      <IconButton 
                        size="small" 
                        title="Imprimer ticket"
                        onClick={() => handlePrintTicket(buyback)}
                      >
                        <PrintIcon />
                      </IconButton>
                      <IconButton 
                        size="small" 
                        title="Supprimer" 
                        color="error"
                        onClick={() => handleDeleteClick(buyback)}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Formulaire */}
      {showForm && (
        <Dialog open={showForm} onClose={() => setShowForm(false)} maxWidth="lg" fullWidth>
          <DialogContent sx={{ p: 0 }}>
            <BuybackForm
              buyback={selectedBuyback || undefined}
              onSave={(buyback) => {
                setShowForm(false);
                loadBuybacks();
                toast.success(selectedBuyback ? 'Rachat modifié avec succès' : 'Rachat créé avec succès');
              }}
              onCancel={() => setShowForm(false)}
            />
          </DialogContent>
        </Dialog>
      )}

      {/* Détails du rachat */}
      {showDetails && selectedBuyback && (
        <Dialog open={showDetails} onClose={() => setShowDetails(false)} maxWidth="md" fullWidth>
          <DialogTitle>
            Détails du rachat #{selectedBuyback.id.slice(0, 8)}
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
                <Typography variant="body2"><strong>Appareil:</strong> {selectedBuyback.deviceBrand} {selectedBuyback.deviceModel}</Typography>
                <Typography variant="body2"><strong>Type:</strong> {selectedBuyback.deviceType}</Typography>
                {selectedBuyback.deviceImei && (
                  <Typography variant="body2"><strong>IMEI:</strong> {selectedBuyback.deviceImei}</Typography>
                )}
                <Typography variant="body2"><strong>État:</strong> {getStatusLabel(selectedBuyback.status)}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="h6" gutterBottom>Détails Financiers</Typography>
                <Typography variant="body2"><strong>Prix proposé:</strong> {selectedBuyback.offeredPrice.toLocaleString('fr-FR')} €</Typography>
                {selectedBuyback.finalPrice && (
                  <Typography variant="body2"><strong>Prix final:</strong> {selectedBuyback.finalPrice.toLocaleString('fr-FR')} €</Typography>
                )}
                <Typography variant="body2"><strong>Mode de paiement:</strong> {selectedBuyback.paymentMethod}</Typography>
                <Typography variant="body2"><strong>Raison:</strong> {selectedBuyback.buybackReason}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="h6" gutterBottom>Actions rapides</Typography>
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  {selectedBuyback.status === 'pending' && (
                    <Button 
                      size="small" 
                      variant="contained" 
                      color="success"
                      onClick={() => handleUpdateStatus(selectedBuyback, 'accepted')}
                    >
                      Accepter
                    </Button>
                  )}
                  {selectedBuyback.status === 'accepted' && (
                    <Button 
                      size="small" 
                      variant="contained" 
                      color="success"
                      onClick={() => handleUpdateStatus(selectedBuyback, 'paid')}
                    >
                      Marquer comme payé
                    </Button>
                  )}
                  <Button 
                    size="small" 
                    variant="outlined"
                    onClick={() => {
                      setShowDetails(false);
                      handleEdit(selectedBuyback);
                    }}
                  >
                    Modifier
                  </Button>
                </Box>
              </Grid>
            </Grid>
          </DialogContent>
        </Dialog>
      )}

      {/* Dialog de suppression */}
      {showDeleteDialog && buybackToDelete && (
        <Dialog open={showDeleteDialog} onClose={() => setShowDeleteDialog(false)}>
          <DialogTitle>Confirmer la suppression</DialogTitle>
          <DialogContent>
            <Typography>
              Êtes-vous sûr de vouloir supprimer le rachat de {buybackToDelete.clientFirstName} {buybackToDelete.clientLastName} ?
              Cette action est irréversible.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setShowDeleteDialog(false)}>Annuler</Button>
            <Button onClick={handleConfirmDelete} color="error" variant="contained">
              Supprimer
            </Button>
          </DialogActions>
        </Dialog>
      )}

      {/* Ticket de rachat */}
      {showTicket && selectedBuyback && (
        <BuybackTicket
          buyback={selectedBuyback}
          open={showTicket}
          onClose={() => setShowTicket(false)}
        />
      )}
    </Box>
  );
};

export default BuybackProgressive;

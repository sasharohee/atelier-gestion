import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  IconButton,
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
  Alert,
  CircularProgress,
  Fab,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Refresh as RefreshIcon,
  Visibility as ViewIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  LocalShipping as ShippingIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
  Cancel as CancelIcon,
  List as ListIcon,
} from '@mui/icons-material';
import { InputAdornment } from '@mui/material';
import { useAppStore } from '../../../store';

import OrderStats from './OrderStats';
import { Order } from '../../../types/order';
import orderService from '../../../services/orderService';

const OrderTracking: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [filteredOrders, setFilteredOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [editMode, setEditMode] = useState(false);

  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    confirmed: 0,
    shipped: 0,
    delivered: 0,
    cancelled: 0,
    totalAmount: 0
  });

  useEffect(() => {
    // Vérifier la compatibilité des données et nettoyer si nécessaire
    const checkAndCleanup = async () => {
      try {
        const compatibility = await orderService.checkDataCompatibility();
        if (compatibility.hasOldData) {
          console.log('🔄 Anciennes données détectées, nettoyage en cours...');
          console.log('📊 Données trouvées:', compatibility.recommendations);
          await orderService.cleanupOldData();
        }
      } catch (error) {
        console.error('Erreur lors de la vérification de compatibilité:', error);
      }
    };

    checkAndCleanup().then(() => {
      loadOrders();
    });
  }, []);

  useEffect(() => {
    console.log('🔄 useEffect filterOrders déclenché - orders:', orders.length, 'searchTerm:', searchTerm, 'statusFilter:', statusFilter);
    filterOrders();
  }, [orders, searchTerm, statusFilter]);

  const loadOrders = async () => {
    setLoading(true);
    try {
      console.log('🔄 Chargement des commandes et statistiques...');
      
      const [ordersData, statsData] = await Promise.all([
        orderService.getAllOrders(),
        orderService.getOrderStats()
      ]);
      
      console.log('📊 Commandes chargées:', ordersData?.length || 0);
      console.log('📈 Statistiques chargées:', statsData);
      
      setOrders(ordersData);
      setStats(statsData);
    } catch (error) {
      console.error('❌ Erreur lors du chargement des commandes:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterOrders = () => {
    console.log('🔄 filterOrders appelé - orders:', orders.length);
    let filtered = orders;

    // Filtre par recherche
    if (searchTerm) {
      filtered = filtered.filter(order =>
        order.orderNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.supplierName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.trackingNumber?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Filtre par statut
    if (statusFilter !== 'all') {
      filtered = filtered.filter(order => order.status === statusFilter);
    }

    console.log('📊 filterOrders - filtered:', filtered.length, 'orders');
    setFilteredOrders(filtered);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'warning';
      case 'confirmed': return 'info';
      case 'shipped': return 'primary';
      case 'delivered': return 'success';
      case 'cancelled': return 'error';
      default: return 'default';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending': return <ScheduleIcon />;
      case 'confirmed': return <CheckCircleIcon />;
      case 'shipped': return <ShippingIcon />;
      case 'delivered': return <CheckCircleIcon />;
      case 'cancelled': return <CancelIcon />;
      default: return <ScheduleIcon />;
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'shipped': return 'Expédiée';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  };

  const handleViewOrder = (order: Order) => {
    setSelectedOrder(order);
    setEditMode(false);
    setOpenDialog(true);
  };

  const handleEditOrder = (order: Order) => {
    setSelectedOrder(order);
    setEditMode(true);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setSelectedOrder(null);
    setEditMode(false);
  };

  const handleSaveOrder = async (updatedOrder: Order) => {
    try {
      console.log('🔄 Sauvegarde commande:', updatedOrder);
      
      // Vérifier si l'ID est un UUID valide
      const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(updatedOrder.id || '');
      
      if (updatedOrder.id && isUUID) {
        // Mise à jour d'une commande existante
        console.log('📝 Mise à jour commande existante:', updatedOrder.id);
        const result = await orderService.updateOrder(updatedOrder.id, updatedOrder);
        if (result) {
          console.log('✅ Commande mise à jour:', result);
          setOrders(prev => {
            const updated = prev.map(order => 
              order.id === updatedOrder.id ? result : order
            );
            console.log('📊 Liste des commandes mise à jour:', updated.length, 'commandes');
            return updated;
          });
        } else {
          console.error('❌ Échec de la mise à jour de la commande');
        }
      } else {
        // Création d'une nouvelle commande
        console.log('🆕 Création nouvelle commande');
        const { id, ...orderData } = updatedOrder;
        const newOrder = await orderService.createOrder(orderData);
        console.log('✅ Nouvelle commande créée:', newOrder);
        
        // Ajouter la nouvelle commande à l'état local IMMÉDIATEMENT
        setOrders(prev => {
          const updated = [newOrder, ...prev]; // Ajouter au début de la liste
          console.log('📊 Liste des commandes mise à jour:', updated.length, 'commandes');
          return updated;
        });
      }
      
      handleCloseDialog();
      
      // Mettre à jour les statistiques
      try {
        const newStats = await orderService.getOrderStats();
        setStats(newStats);
        console.log('✅ Statistiques mises à jour:', newStats);
      } catch (statsError) {
        console.error('❌ Erreur mise à jour statistiques:', statsError);
      }
      
      // Le useEffect se déclenchera automatiquement quand orders change
      console.log('🔄 Mise à jour terminée, useEffect se déclenchera automatiquement');
      
      // Forcer un re-rendu en ajoutant un timestamp unique
      setOrders(currentOrders => {
        console.log('🔄 Forçage du re-rendu avec orders:', currentOrders.length);
        return [...currentOrders]; // Créer un nouveau tableau pour forcer le re-rendu
      });
    } catch (error) {
      console.error('❌ Erreur lors de la sauvegarde de la commande:', error);
    }
  };

  const handleDeleteOrder = async (orderId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cette commande ?')) {
      try {
        const success = await orderService.deleteOrder(orderId);
        if (success) {
          setOrders(prev => prev.filter(order => order.id !== orderId));
          
          // Recharger les statistiques après suppression
          try {
            const newStats = await orderService.getOrderStats();
            setStats(newStats);
            console.log('✅ Statistiques mises à jour après suppression:', newStats);
          } catch (statsError) {
            console.error('❌ Erreur mise à jour statistiques:', statsError);
          }
        }
      } catch (error) {
        console.error('Erreur lors de la suppression de la commande:', error);
      }
    }
  };

  const handleAddOrder = () => {
    setSelectedOrder(null);
    setEditMode(true);
    setOpenDialog(true);
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Suivi des Commandes
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gérez et suivez vos commandes auprès des fournisseurs
        </Typography>
        {orders.length === 0 && (
          <Alert severity="info" sx={{ mt: 2 }}>
            Bienvenue ! Cette page vous permettra de suivre toutes vos commandes auprès de vos fournisseurs. 
            Commencez par créer votre première commande pour organiser vos achats.
          </Alert>
        )}
      </Box>

      {/* Statistiques */}
      <OrderStats stats={stats} />

      {/* Filtres et recherche */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Rechercher..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                }}
              />
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Statut</InputLabel>
                <Select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  label="Statut"
                >
                  <MenuItem value="all">Tous les statuts</MenuItem>
                  <MenuItem value="pending">En attente</MenuItem>
                  <MenuItem value="confirmed">Confirmée</MenuItem>
                  <MenuItem value="shipped">Expédiée</MenuItem>
                  <MenuItem value="delivered">Livrée</MenuItem>
                  <MenuItem value="cancelled">Annulée</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <Button
                fullWidth
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={loadOrders}
                disabled={loading}
              >
                Actualiser
              </Button>
            </Grid>
            <Grid item xs={12} md={3}>
              <Button
                fullWidth
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleAddOrder}
              >
                Nouvelle Commande
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Liste des commandes */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : filteredOrders.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              width: 120,
              height: 120,
              borderRadius: '50%',
              backgroundColor: '#f5f5f5',
              mx: 'auto',
              mb: 3,
            }}
          >
            <ShippingIcon sx={{ fontSize: 60, color: '#2196f3' }} />
          </Box>
          <Typography variant="h5" gutterBottom sx={{ fontWeight: 600, color: '#333' }}>
            {searchTerm || statusFilter !== 'all' ? 'Aucune commande trouvée' : 'Aucune commande pour le moment'}
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4, maxWidth: 500, mx: 'auto' }}>
            {searchTerm || statusFilter !== 'all' 
              ? 'Essayez de modifier vos critères de recherche ou vos filtres pour trouver ce que vous cherchez.'
              : 'Commencez par créer votre première commande auprès d\'un fournisseur pour suivre vos achats.'
            }
          </Typography>
          {!searchTerm && statusFilter === 'all' && (
            <Button
              variant="contained"
              size="large"
              startIcon={<AddIcon />}
              onClick={handleAddOrder}
              sx={{ px: 4, py: 1.5 }}
            >
              Créer votre première commande
            </Button>
          )}
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>N° Commande</TableCell>
                <TableCell>Fournisseur</TableCell>
                <TableCell>Date Commande</TableCell>
                <TableCell>Livraison Prévue</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Montant</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredOrders.map((order) => (
                <TableRow key={order.id} hover>
                  <TableCell>
                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {order.orderNumber}
                    </Typography>
                    {order.trackingNumber && (
                      <Typography variant="caption" color="text.secondary">
                        Suivi: {order.trackingNumber}
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    <Typography variant="subtitle2">{order.supplierName}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {order.supplierEmail}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    {new Date(order.orderDate).toLocaleDateString('fr-FR')}
                  </TableCell>
                  <TableCell>
                    {new Date(order.expectedDeliveryDate).toLocaleDateString('fr-FR')}
                    {order.actualDeliveryDate && (
                      <Typography variant="caption" display="block" color="success.main">
                        Livrée le {new Date(order.actualDeliveryDate).toLocaleDateString('fr-FR')}
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    <Chip
                      icon={getStatusIcon(order.status)}
                      label={getStatusLabel(order.status)}
                      color={getStatusColor(order.status) as any}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {order.totalAmount.toLocaleString('fr-FR', {
                        style: 'currency',
                        currency: 'EUR'
                      })}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      size="small"
                      onClick={() => handleViewOrder(order)}
                      title="Voir les détails"
                    >
                      <ViewIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      onClick={() => handleEditOrder(order)}
                      title="Modifier"
                    >
                      <EditIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      onClick={() => handleDeleteOrder(order.id)}
                      title="Supprimer"
                      color="error"
                    >
                      <DeleteIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Dialog pour voir/modifier une commande */}
      <OrderDialog
        open={openDialog}
        order={selectedOrder}
        editMode={editMode}
        onClose={handleCloseDialog}
        onSave={handleSaveOrder}
      />

      {/* Bouton flottant pour ajouter une commande */}
      <Tooltip title="Nouvelle commande">
        <Fab
          color="primary"
          aria-label="add"
          sx={{ position: 'fixed', bottom: 16, right: 16 }}
          onClick={handleAddOrder}
        >
          <AddIcon />
        </Fab>
      </Tooltip>
    </Box>
  );
};

// Composant Dialog pour voir/modifier une commande
interface OrderDialogProps {
  open: boolean;
  order: Order | null;
  editMode: boolean;
  onClose: () => void;
  onSave: (order: Order) => void;
}

const OrderDialog: React.FC<OrderDialogProps> = ({
  open,
  order,
  editMode,
  onClose,
  onSave
}) => {
  const [formData, setFormData] = useState<Partial<Order>>({});

  useEffect(() => {
    if (order) {
      setFormData(order);
    } else {
      setFormData({
        orderNumber: '',
        supplierName: '',
        supplierEmail: '',
        supplierPhone: '',
        orderDate: new Date().toISOString().split('T')[0],
        expectedDeliveryDate: '',
        status: 'pending',
        totalAmount: 0,
        trackingNumber: '',
        items: [],
        notes: ''
      });
    }
  }, [order]);

  const handleSave = () => {
    if (formData.id) {
      onSave(formData as Order);
    } else {
      // Créer une nouvelle commande
      const newOrder: Order = {
        id: Date.now().toString(),
        orderNumber: formData.orderNumber || '',
        supplierName: formData.supplierName || '',
        supplierEmail: formData.supplierEmail || '',
        supplierPhone: formData.supplierPhone || '',
        orderDate: formData.orderDate || '',
        expectedDeliveryDate: formData.expectedDeliveryDate || '',
        status: formData.status || 'pending',
        totalAmount: formData.totalAmount || 0,
        trackingNumber: formData.trackingNumber || '',
        items: [],
        notes: formData.notes || ''
      };
      onSave(newOrder);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        {editMode ? (order ? 'Modifier la commande' : 'Nouvelle commande') : 'Détails de la commande'}
      </DialogTitle>
      <DialogContent>
        <Grid container spacing={2} sx={{ mt: 1 }}>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="N° Commande"
              value={formData.orderNumber || ''}
              onChange={(e) => setFormData({ ...formData, orderNumber: e.target.value })}
              disabled={!editMode}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Fournisseur"
              value={formData.supplierName || ''}
              onChange={(e) => setFormData({ ...formData, supplierName: e.target.value })}
              disabled={!editMode}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Email fournisseur"
              value={formData.supplierEmail || ''}
              onChange={(e) => setFormData({ ...formData, supplierEmail: e.target.value })}
              disabled={!editMode}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Téléphone fournisseur"
              value={formData.supplierPhone || ''}
              onChange={(e) => setFormData({ ...formData, supplierPhone: e.target.value })}
              disabled={!editMode}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Date de commande"
              type="date"
              value={formData.orderDate || ''}
              onChange={(e) => setFormData({ ...formData, orderDate: e.target.value })}
              disabled={!editMode}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Date de livraison prévue"
              type="date"
              value={formData.expectedDeliveryDate || ''}
              onChange={(e) => setFormData({ ...formData, expectedDeliveryDate: e.target.value })}
              disabled={!editMode}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <FormControl fullWidth>
              <InputLabel>Statut</InputLabel>
              <Select
                value={formData.status || 'pending'}
                onChange={(e) => setFormData({ ...formData, status: e.target.value as any })}
                label="Statut"
                disabled={!editMode}
              >
                <MenuItem value="pending">En attente</MenuItem>
                <MenuItem value="confirmed">Confirmée</MenuItem>
                <MenuItem value="shipped">Expédiée</MenuItem>
                <MenuItem value="delivered">Livrée</MenuItem>
                <MenuItem value="cancelled">Annulée</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Numéro de suivi"
              value={formData.trackingNumber || ''}
              onChange={(e) => setFormData({ ...formData, trackingNumber: e.target.value })}
              disabled={!editMode}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Montant total (€)"
              type="number"
              value={formData.totalAmount || 0}
              onChange={(e) => setFormData({ ...formData, totalAmount: parseFloat(e.target.value) || 0 })}
              disabled={!editMode}
              inputProps={{ 
                min: 0, 
                step: 0.01,
                placeholder: "0.00"
              }}
              InputProps={{
                startAdornment: <InputAdornment position="start">€</InputAdornment>,
              }}
            />
          </Grid>
          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Notes"
              multiline
              rows={3}
              value={formData.notes || ''}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              disabled={!editMode}
            />
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Annuler</Button>
        {editMode && (
          <Button onClick={handleSave} variant="contained">
            Enregistrer
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default OrderTracking;

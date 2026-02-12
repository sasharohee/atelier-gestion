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
  Tabs,
  Tab,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Print as PrintIcon,
  Visibility as ViewIcon,
  MonetizationOn as MonetizationOnIcon,
  Search as SearchIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  AttachMoney as AttachMoneyIcon,
  Schedule as ScheduleIcon,
  FlashOn as FlashOnIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Buyback, BuybackStatus } from '../../types';
import { buybackService } from '../../services/supabaseService';
import { toast } from 'react-hot-toast';
import BuybackForm from './BuybackForm';
import BuybackExpressForm from './BuybackExpressForm';
import BuybackTicket from '../../components/BuybackTicket';
import BuybackProductsTvaMarge from './BuybackProductsTvaMarge';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

const BuybackProgressive: React.FC = () => {
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';
  
  const [buybacks, setBuybacks] = useState<Buyback[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<BuybackStatus | 'all'>('all');
  const [showForm, setShowForm] = useState(false);
  const [isExpressMode, setIsExpressMode] = useState(false);
  const [selectedBuyback, setSelectedBuyback] = useState<Buyback | null>(null);
  const [showDetails, setShowDetails] = useState(false);
  const [showTicket, setShowTicket] = useState(false);
  const [activeTab, setActiveTab] = useState(0);

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
    setIsExpressMode(false);
    setShowForm(true);
  };

  const handlePrintTicket = (buyback: Buyback) => {
    setSelectedBuyback(buyback);
    setShowTicket(true);
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

      {/* Onglets */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
          <Tab label="Rachats" />
          <Tab label="Produits TVA sur marge" />
        </Tabs>
      </Paper>

      {/* Contenu de l'onglet Rachats */}
      {activeTab === 0 && (
        <>
          {/* Statistiques */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{
            background: 'linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%)',
            border: '1px solid #bbf7d0',
            transition: 'transform 0.2s, box-shadow 0.2s',
            '&:hover': { transform: 'translateY(-2px)', boxShadow: '0 4px 12px rgba(16,185,129,0.15)' }
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom sx={{ fontSize: '0.85rem' }}>
                    Total rachats
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#374151' }}>
                    {stats.total}
                  </Typography>
                </Box>
                <MonetizationOnIcon sx={{ fontSize: 40, color: '#10b981' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{
            background: 'linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%)',
            border: '1px solid #fde68a',
            transition: 'transform 0.2s, box-shadow 0.2s',
            '&:hover': { transform: 'translateY(-2px)', boxShadow: '0 4px 12px rgba(245,158,11,0.15)' }
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom sx={{ fontSize: '0.85rem' }}>
                    En attente
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#374151' }}>
                    {stats.pending}
                  </Typography>
                </Box>
                <ScheduleIcon sx={{ fontSize: 40, color: '#f59e0b' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{
            background: 'linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)',
            border: '1px solid #bfdbfe',
            transition: 'transform 0.2s, box-shadow 0.2s',
            '&:hover': { transform: 'translateY(-2px)', boxShadow: '0 4px 12px rgba(59,130,246,0.15)' }
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom sx={{ fontSize: '0.85rem' }}>
                    Acceptés
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#374151' }}>
                    {stats.accepted}
                  </Typography>
                </Box>
                <CheckCircleIcon sx={{ fontSize: 40, color: '#3b82f6' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{
            background: 'linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%)',
            border: '1px solid #a7f3d0',
            transition: 'transform 0.2s, box-shadow 0.2s',
            '&:hover': { transform: 'translateY(-2px)', boxShadow: '0 4px 12px rgba(16,185,129,0.15)' }
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom sx={{ fontSize: '0.85rem' }}>
                    Valeur totale
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#374151' }}>
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
                variant="outlined"
                startIcon={<FlashOnIcon />}
                onClick={() => {
                  setSelectedBuyback(null);
                  setIsExpressMode(true);
                  setShowForm(true);
                }}
                sx={{ borderColor: '#374151', color: '#374151', '&:hover': { borderColor: '#1f2937', backgroundColor: '#f3f4f6' } }}
              >
                Rachat expresse
              </Button>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => {
                  setSelectedBuyback(null);
                  setIsExpressMode(false);
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
      <TableContainer component={Paper} sx={{ borderRadius: 2, overflow: 'hidden' }}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: '#f9fafb' }}>
              <TableCell sx={{ fontWeight: 600, color: '#374151' }}>Client</TableCell>
              <TableCell sx={{ fontWeight: 600, color: '#374151' }}>Appareil</TableCell>
              <TableCell sx={{ fontWeight: 600, color: '#374151' }}>IMEI</TableCell>
              <TableCell sx={{ fontWeight: 600, color: '#374151' }}>Prix final</TableCell>
              <TableCell sx={{ fontWeight: 600, color: '#374151' }}>Statut</TableCell>
              <TableCell sx={{ fontWeight: 600, color: '#374151' }}>Date</TableCell>
              <TableCell sx={{ fontWeight: 600, color: '#374151' }}>Actions</TableCell>
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
              filteredBuybacks.map((buyback) => {
                const statusBorderColor: Record<string, string> = {
                  'pending': '#f59e0b',
                  'accepted': '#3b82f6',
                  'rejected': '#ef4444',
                  'paid': '#10b981',
                };
                return (
                <TableRow
                  key={buyback.id}
                  hover
                  sx={{
                    borderLeft: `4px solid ${statusBorderColor[buyback.status] || '#e5e7eb'}`,
                    '&:hover': { backgroundColor: '#f9fafb' },
                    transition: 'background-color 0.15s',
                  }}
                >
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
                      {formatFromEUR(buyback.finalPrice || buyback.offeredPrice, currency)}
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
                    </Box>
                  </TableCell>
                </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Formulaire */}
      {showForm && (
        <Dialog open={showForm} onClose={() => setShowForm(false)} maxWidth="lg" fullWidth>
          <DialogContent sx={{ p: 0 }}>
            {isExpressMode ? (
              <BuybackExpressForm
                buyback={selectedBuyback || undefined}
                onSave={(buyback) => {
                  setShowForm(false);
                  setIsExpressMode(false);
                  loadBuybacks();
                  toast.success(selectedBuyback ? 'Rachat modifié avec succès' : 'Rachat expresse créé avec succès');
                }}
                onCancel={() => {
                  setShowForm(false);
                  setIsExpressMode(false);
                }}
              />
            ) : (
              <BuybackForm
                buyback={selectedBuyback || undefined}
                onSave={(buyback) => {
                  setShowForm(false);
                  setIsExpressMode(false);
                  loadBuybacks();
                  toast.success(selectedBuyback ? 'Rachat modifié avec succès' : 'Rachat créé avec succès');
                }}
                onCancel={() => {
                  setShowForm(false);
                  setIsExpressMode(false);
                }}
              />
            )}
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
                <Typography variant="body2"><strong>Prix proposé:</strong> {formatFromEUR(selectedBuyback.offeredPrice, currency)}</Typography>
                {selectedBuyback.finalPrice && (
                  <Typography variant="body2"><strong>Prix final:</strong> {formatFromEUR(selectedBuyback.finalPrice, currency)}</Typography>
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

      {/* Ticket de rachat */}
      {showTicket && selectedBuyback && (
        <BuybackTicket
          buyback={selectedBuyback}
          open={showTicket}
          onClose={() => setShowTicket(false)}
        />
      )}
        </>
      )}

      {/* Contenu de l'onglet Produits TVA sur marge */}
      {activeTab === 1 && (
        <BuybackProductsTvaMarge />
      )}
    </Box>
  );
};

export default BuybackProgressive;

import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Button,
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
  Alert,
  CircularProgress,
  Tooltip,
  Fab,
  Menu,
  ListItemIcon,
  ListItemText,
  ListItem,
  Divider,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  MoreVert as MoreVertIcon,
  ExpandMore as ExpandMoreIcon,
  Settings as SettingsIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  Info as InfoIcon,
} from '@mui/icons-material';
import { DeviceMarketPrice } from '../../types';
import { deviceMarketPriceService } from '../../services/supabaseService';
import { formatFromEUR } from '../../utils/currencyUtils';
import toast from 'react-hot-toast';

const BuybackPriceManagement: React.FC = () => {
  const [devicePrices, setDevicePrices] = useState<DeviceMarketPrice[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPrice, setSelectedPrice] = useState<DeviceMarketPrice | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [showStats, setShowStats] = useState(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [actionPrice, setActionPrice] = useState<DeviceMarketPrice | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [brandFilter, setBrandFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');

  useEffect(() => {
    loadDevicePrices();
  }, []);

  const loadDevicePrices = async () => {
    setLoading(true);
    try {
      const result = await deviceMarketPriceService.getAll();
      if (result.success) {
        setDevicePrices(result.data || []);
      } else {
        toast.error('Erreur lors du chargement des prix');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des prix:', error);
      toast.error('Erreur lors du chargement des prix');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = () => {
    setSelectedPrice(null);
    setShowForm(true);
  };

  const handleEdit = (price: DeviceMarketPrice) => {
    setSelectedPrice(price);
    setShowForm(true);
  };

  const handleDelete = async (price: DeviceMarketPrice) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce prix de référence ?')) {
      try {
        const result = await deviceMarketPriceService.delete(price.id);
        if (result.success) {
          toast.success('Prix supprimé avec succès');
          loadDevicePrices();
        } else {
          toast.error('Erreur lors de la suppression');
        }
      } catch (error) {
        console.error('Erreur lors de la suppression:', error);
        toast.error('Erreur lors de la suppression');
      }
    }
  };

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, price: DeviceMarketPrice) => {
    setAnchorEl(event.currentTarget);
    setActionPrice(price);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setActionPrice(null);
  };

  const handleMenuAction = (action: string) => {
    if (!actionPrice) return;

    switch (action) {
      case 'edit':
        handleEdit(actionPrice);
        break;
      case 'delete':
        handleDelete(actionPrice);
        break;
    }

    handleMenuClose();
  };

  const filteredPrices = devicePrices.filter(price => {
    const matchesSearch = 
      price.deviceBrand.toLowerCase().includes(searchTerm.toLowerCase()) ||
      price.deviceModel.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesBrand = brandFilter === 'all' || price.deviceBrand === brandFilter;
    const matchesType = typeFilter === 'all' || price.deviceType === typeFilter;
    
    return matchesSearch && matchesBrand && matchesType;
  });

  const getStats = () => {
    const total = devicePrices.length;
    const brands = [...new Set(devicePrices.map(p => p.deviceBrand))];
    const types = [...new Set(devicePrices.map(p => p.deviceType))];
    const avgPrice = devicePrices.length > 0 
      ? devicePrices.reduce((sum, p) => {
          const prices = Object.values(p.pricesByCapacity);
          return sum + (prices.length > 0 ? prices.reduce((a, b) => a + b, 0) / prices.length : 0);
        }, 0) / devicePrices.length
      : 0;

    return { total, brands, types, avgPrice };
  };

  const stats = getStats();

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
        <SettingsIcon sx={{ color: '#10b981' }} />
        Gestion des prix de rachat
      </Typography>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Configurez les prix de référence pour chaque modèle d'appareil et personnalisez 
        les coefficients d'ajustement selon l'état et les accessoires.
      </Typography>

      {/* Statistiques */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Modèles configurés
                  </Typography>
                  <Typography variant="h4">
                    {stats.total}
                  </Typography>
                </Box>
                <TrendingUpIcon sx={{ fontSize: 40, color: '#10b981' }} />
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
                    Marques
                  </Typography>
                  <Typography variant="h4">
                    {stats.brands.length}
                  </Typography>
                </Box>
                <SettingsIcon sx={{ fontSize: 40, color: '#3b82f6' }} />
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
                    Types d'appareils
                  </Typography>
                  <Typography variant="h4">
                    {stats.types.length}
                  </Typography>
                </Box>
                <TrendingDownIcon sx={{ fontSize: 40, color: '#f59e0b' }} />
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
                    Prix moyen
                  </Typography>
                  <Typography variant="h4">
                    {formatFromEUR(stats.avgPrice, 'EUR')}
                  </Typography>
                </Box>
                <TrendingUpIcon sx={{ fontSize: 40, color: '#10b981' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filtres et actions */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              fullWidth
              placeholder="Rechercher un modèle..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              size="small"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Marque</InputLabel>
              <Select
                value={brandFilter}
                onChange={(e) => setBrandFilter(e.target.value)}
              >
                <MenuItem value="all">Toutes les marques</MenuItem>
                {stats.brands.map(brand => (
                  <MenuItem key={brand} value={brand}>{brand}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Type</InputLabel>
              <Select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
              >
                <MenuItem value="all">Tous les types</MenuItem>
                {stats.types.map(type => (
                  <MenuItem key={type} value={type}>{type}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={12} md={5}>
            <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={loadDevicePrices}
              >
                Actualiser
              </Button>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleCreate}
                sx={{ backgroundColor: '#10b981', '&:hover': { backgroundColor: '#059669' } }}
              >
                Nouveau prix
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Table des prix */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Marque/Modèle</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Capacités</TableCell>
              <TableCell>Prix moyen</TableCell>
              <TableCell>Dernière MAJ</TableCell>
              <TableCell>Source</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredPrices.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  <Box sx={{ py: 4 }}>
                    <Typography variant="body1" color="textSecondary">
                      {devicePrices.length === 0 ? 'Aucun prix configuré' : 'Aucun résultat pour cette recherche'}
                    </Typography>
                    {devicePrices.length === 0 && (
                      <Button
                        variant="contained"
                        startIcon={<AddIcon />}
                        onClick={handleCreate}
                        sx={{ mt: 2, backgroundColor: '#10b981', '&:hover': { backgroundColor: '#059669' } }}
                      >
                        Configurer le premier prix
                      </Button>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ) : (
              filteredPrices.map((price) => {
                const capacities = Object.keys(price.pricesByCapacity);
                const avgPrice = Object.values(price.pricesByCapacity).reduce((a, b) => a + b, 0) / Object.values(price.pricesByCapacity).length;
                
                return (
                  <TableRow key={price.id} hover>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" fontWeight="medium">
                          {price.deviceBrand} {price.deviceModel}
                        </Typography>
                        <Typography variant="caption" color="textSecondary">
                          {price.marketSegment && (
                            <Chip 
                              label={price.marketSegment} 
                              size="small" 
                              color={price.marketSegment === 'premium' ? 'primary' : 'default'}
                            />
                          )}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {price.deviceType}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {capacities.map(capacity => (
                          <Chip 
                            key={capacity}
                            label={`${capacity}: ${formatFromEUR(price.pricesByCapacity[capacity], 'EUR')}`}
                            size="small"
                            variant="outlined"
                          />
                        ))}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" fontWeight="medium">
                        {formatFromEUR(avgPrice, 'EUR')}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {new Date(price.lastPriceUpdate).toLocaleDateString('fr-FR')}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip 
                        label={price.priceSource} 
                        size="small" 
                        color={price.priceSource === 'api' ? 'success' : 'default'}
                      />
                    </TableCell>
                    <TableCell>
                      <IconButton
                        onClick={(e) => handleMenuClick(e, price)}
                        size="small"
                      >
                        <MoreVertIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                );
              })
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
        <ListItem onClick={() => handleMenuAction('edit')}>
          <ListItemIcon>
            <EditIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Modifier</ListItemText>
        </ListItem>
        <ListItem onClick={() => handleMenuAction('delete')} sx={{ color: 'error.main' }}>
          <ListItemIcon>
            <DeleteIcon fontSize="small" color="error" />
          </ListItemIcon>
          <ListItemText>Supprimer</ListItemText>
        </ListItem>
      </Menu>

      {/* Formulaire de création/édition */}
      {showForm && (
        <Dialog open={showForm} onClose={() => setShowForm(false)} maxWidth="lg" fullWidth>
          <DialogTitle>
            <Typography variant="h6">
              {selectedPrice ? 'Modifier le prix' : 'Nouveau prix de référence'}
            </Typography>
          </DialogTitle>
          <DialogContent>
            <Alert severity="info" sx={{ mb: 3 }}>
              <Typography variant="body2">
                <strong>Configuration des prix :</strong> Définissez les prix de base par capacité de stockage 
                et configurez les coefficients d'ajustement pour l'état physique, l'écran, les accessoires, etc.
              </Typography>
            </Alert>
            
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Marque *"
                  value={selectedPrice?.deviceBrand || ''}
                  disabled={!!selectedPrice}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Modèle *"
                  value={selectedPrice?.deviceModel || ''}
                  disabled={!!selectedPrice}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Type d'appareil *</InputLabel>
                  <Select
                    value={selectedPrice?.deviceType || ''}
                    disabled={!!selectedPrice}
                  >
                    <MenuItem value="smartphone">Smartphone</MenuItem>
                    <MenuItem value="tablet">Tablette</MenuItem>
                    <MenuItem value="laptop">Ordinateur portable</MenuItem>
                    <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Année de sortie"
                  type="number"
                  value={selectedPrice?.releaseYear || ''}
                />
              </Grid>
            </Grid>

            <Divider sx={{ my: 3 }} />

            <Typography variant="h6" gutterBottom>
              Configuration des prix par capacité
            </Typography>
            <Alert severity="warning" sx={{ mb: 2 }}>
              Cette fonctionnalité sera implémentée dans une version future. 
              Pour l'instant, utilisez l'interface de base de données directement.
            </Alert>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setShowForm(false)}>
              Annuler
            </Button>
            <Button 
              variant="contained" 
              startIcon={<SaveIcon />}
              disabled
            >
              Sauvegarder
            </Button>
          </DialogActions>
        </Dialog>
      )}

      {/* FAB pour actions rapides */}
      <Fab
        color="primary"
        aria-label="add"
        onClick={handleCreate}
        sx={{
          position: 'fixed',
          bottom: 16,
          right: 16,
          backgroundColor: '#10b981',
          '&:hover': { backgroundColor: '#059669' }
        }}
      >
        <AddIcon />
      </Fab>
    </Box>
  );
};

export default BuybackPriceManagement;

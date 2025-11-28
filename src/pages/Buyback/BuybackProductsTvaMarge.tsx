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
  Dialog,
  DialogContent,
  DialogTitle,
  DialogActions,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Divider,
  Card,
  CardContent,
} from '@mui/material';
import {
  Add as AddIcon,
  ShoppingCart as ShoppingCartIcon,
  Calculate as CalculateIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Buyback } from '../../types';
import { buybackService, productService } from '../../services/supabaseService';
import { toast } from 'react-hot-toast';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import { useAppStore } from '../../store';

const BuybackProductsTvaMarge: React.FC = () => {
  const { workshopSettings } = useWorkshopSettings();
  const { loadProducts } = useAppStore();
  
  const currency = workshopSettings?.currency || 'EUR';
  const vatRate = workshopSettings?.vatRate ? parseFloat(workshopSettings.vatRate) : 20;
  
  const [buybacks, setBuybacks] = useState<Buyback[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBuyback, setSelectedBuyback] = useState<Buyback | null>(null);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [creating, setCreating] = useState(false);
  
  // Formulaire de création de produit
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: 'smartphone',
    subcategory: '',
    sellingPrice: 0,
    stockQuantity: 1,
    minStockLevel: 1,
  });

  const productCategories = [
    { value: 'console', label: 'Console de jeux' },
    { value: 'ordinateur_portable', label: 'Ordinateur portable' },
    { value: 'ordinateur_fixe', label: 'Ordinateur fixe' },
    { value: 'smartphone', label: 'Smartphone' },
    { value: 'montre', label: 'Montre connectée' },
    { value: 'manette_jeux', label: 'Manette de jeux' },
    { value: 'ecouteur', label: 'Écouteur' },
    { value: 'casque', label: 'Casque audio' },
    { value: 'accessoire', label: 'Accessoire' },
    { value: 'protection', label: 'Protection' },
    { value: 'connectique', label: 'Connectique' },
    { value: 'logiciel', label: 'Logiciel' },
    { value: 'autre', label: 'Autre' },
  ];

  useEffect(() => {
    loadBuybacks();
  }, []);

  const loadBuybacks = async () => {
    setLoading(true);
    try {
      const result = await buybackService.getAll();
      if (result.success && 'data' in result) {
        // Filtrer uniquement les rachats payés
        const paidBuybacks = (result.data || []).filter(b => b.status === 'paid');
        setBuybacks(paidBuybacks);
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

  const handleOpenCreateDialog = (buyback: Buyback) => {
    setSelectedBuyback(buyback);
    // Pré-remplir le formulaire avec les informations du rachat
    const purchasePrice = buyback.finalPrice || buyback.offeredPrice;
    setFormData({
      name: `${buyback.deviceBrand} ${buyback.deviceModel}`,
      description: `Produit d'occasion - ${buyback.deviceType} ${buyback.deviceBrand} ${buyback.deviceModel}${buyback.deviceColor ? ` - ${buyback.deviceColor}` : ''}`,
      category: buyback.deviceType === 'smartphone' ? 'smartphone' : 
                buyback.deviceType === 'tablet' ? 'autre' : 
                buyback.deviceType === 'laptop' ? 'ordinateur_portable' : 
                buyback.deviceType === 'desktop' ? 'ordinateur_fixe' : 'autre',
      subcategory: '',
      sellingPrice: Math.round(purchasePrice * 1.3), // Prix de vente suggéré : 30% de marge
      stockQuantity: 1,
      minStockLevel: 1,
    });
    setShowCreateDialog(true);
  };

  const handleCloseDialog = () => {
    setShowCreateDialog(false);
    setSelectedBuyback(null);
    setFormData({
      name: '',
      description: '',
      category: 'smartphone',
      subcategory: '',
      sellingPrice: 0,
      stockQuantity: 1,
      minStockLevel: 1,
    });
  };

  // Calculs TVA sur marge
  const purchasePrice = selectedBuyback ? (selectedBuyback.finalPrice || selectedBuyback.offeredPrice) : 0;
  const sellingPrice = formData.sellingPrice;
  const margin = sellingPrice - purchasePrice;
  const vatOnMargin = margin > 0 ? Math.round(margin * (vatRate / 100) * 100) / 100 : 0;
  const totalWithVat = sellingPrice + vatOnMargin;

  const handleCreateProduct = async () => {
    if (!selectedBuyback) return;

    // Validations
    if (!formData.name.trim()) {
      toast.error('Le nom du produit est obligatoire');
      return;
    }

    if (formData.sellingPrice <= purchasePrice) {
      toast.error('Le prix de vente doit être supérieur au prix d\'achat');
      return;
    }

    if (formData.sellingPrice <= 0) {
      toast.error('Le prix de vente doit être supérieur à 0');
      return;
    }

    if (formData.stockQuantity < 1) {
      toast.error('La quantité en stock doit être au moins de 1');
      return;
    }

    if (formData.minStockLevel < 1) {
      toast.error('Le stock minimum doit être au moins de 1');
      return;
    }

    setCreating(true);
    try {
      // Le prix stocké est le prix de vente HT (sans la TVA sur marge)
      // La TVA sur marge sera calculée lors de la vente
      const productData = {
        name: formData.name.trim(),
        description: formData.description || '',
        category: formData.category,
        subcategory: formData.subcategory || undefined,
        price: sellingPrice, // Prix de vente HT
        stockQuantity: formData.stockQuantity > 0 ? formData.stockQuantity : 1, // S'assurer que le stock est au moins à 1
        minStockLevel: formData.minStockLevel > 0 ? formData.minStockLevel : 1, // S'assurer que le stock minimum est au moins à 1
        isActive: true, // Toujours actif par défaut
        buybackId: selectedBuyback.id,
        purchasePrice: purchasePrice,
        vatOnMargin: true,
      };

      console.log('📦 Données du produit à créer:', productData);

      const result = await productService.create(productData);
      
      console.log('📦 Résultat de la création:', result);
      
      if (result.success && 'data' in result) {
        // Recharger les produits pour avoir les données à jour
        await loadProducts();
        
        toast.success('Produit créé avec succès avec TVA sur marge');
        handleCloseDialog();
        loadBuybacks(); // Recharger pour mettre à jour la liste
      } else if ('error' in result) {
        toast.error(result.error?.message || 'Erreur lors de la création du produit');
      } else {
        toast.error('Erreur lors de la création du produit');
      }
    } catch (error) {
      console.error('Erreur lors de la création du produit:', error);
      toast.error('Erreur lors de la création du produit');
    } finally {
      setCreating(false);
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
      <Typography variant="h5" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}>
        <ShoppingCartIcon sx={{ color: '#10b981' }} />
        Produits TVA sur marge
      </Typography>

      <Alert severity="info" sx={{ mb: 3 }}>
        <Typography variant="body2">
          <strong>Régime TVA sur marge :</strong> Pour les produits d'occasion, la TVA s'applique uniquement sur la marge 
          (différence entre le prix de vente et le prix d'achat), et non sur le prix de vente total.
        </Typography>
      </Alert>

      {buybacks.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="body1" color="textSecondary">
            Aucun rachat payé disponible pour créer un produit.
          </Typography>
          <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
            Les rachats doivent être marqués comme "Payé" pour apparaître ici.
          </Typography>
        </Paper>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Client</TableCell>
                <TableCell>Appareil</TableCell>
                <TableCell>Prix d'achat</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {buybacks.map((buyback) => (
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
                        {buyback.deviceType} • {buyback.deviceColor || 'N/A'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" fontWeight="medium">
                      {formatFromEUR(buyback.finalPrice || buyback.offeredPrice, currency)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {format(new Date(buyback.createdAt), 'dd/MM/yyyy', { locale: fr })}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="contained"
                      size="small"
                      startIcon={<AddIcon />}
                      onClick={() => handleOpenCreateDialog(buyback)}
                      sx={{ backgroundColor: '#10b981', '&:hover': { backgroundColor: '#059669' } }}
                    >
                      Créer produit
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Dialog de création de produit */}
      {showCreateDialog && selectedBuyback && (
        <Dialog open={showCreateDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
          <DialogTitle>
            Créer un produit avec TVA sur marge
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={3} sx={{ mt: 1 }}>
              {/* Informations du rachat (lecture seule) */}
              <Grid item xs={12}>
                <Alert severity="info">
                  <Typography variant="subtitle2" gutterBottom>
                    Informations du rachat
                  </Typography>
                  <Typography variant="body2">
                    <strong>Client:</strong> {selectedBuyback.clientFirstName} {selectedBuyback.clientLastName}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Appareil:</strong> {selectedBuyback.deviceBrand} {selectedBuyback.deviceModel}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Prix d'achat:</strong> {formatFromEUR(purchasePrice, currency)}
                  </Typography>
                </Alert>
              </Grid>

              {/* Formulaire */}
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Nom du produit *"
                  value={formData.name}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  required
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Catégorie *</InputLabel>
                  <Select
                    value={formData.category}
                    onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
                    required
                  >
                    {productCategories.map(cat => (
                      <MenuItem key={cat.value} value={cat.value}>{cat.label}</MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description"
                  multiline
                  rows={3}
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Sous-catégorie"
                  value={formData.subcategory}
                  onChange={(e) => setFormData(prev => ({ ...prev, subcategory: e.target.value }))}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Prix de vente HT *"
                  type="number"
                  value={formData.sellingPrice}
                  onChange={(e) => setFormData(prev => ({ ...prev, sellingPrice: parseFloat(e.target.value) || 0 }))}
                  required
                  inputProps={{ min: purchasePrice + 0.01, step: 0.01 }}
                  helperText={`Doit être supérieur à ${formatFromEUR(purchasePrice, currency)} (prix d'achat)`}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Quantité en stock *"
                  type="number"
                  value={formData.stockQuantity}
                  onChange={(e) => {
                    const value = parseInt(e.target.value);
                    setFormData(prev => ({ ...prev, stockQuantity: isNaN(value) || value < 1 ? 1 : value }));
                  }}
                  required
                  inputProps={{ min: 1, step: 1 }}
                  helperText="Quantité en stock du produit"
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Stock minimum *"
                  type="number"
                  value={formData.minStockLevel}
                  onChange={(e) => {
                    const value = parseInt(e.target.value);
                    setFormData(prev => ({ ...prev, minStockLevel: isNaN(value) || value < 1 ? 1 : value }));
                  }}
                  required
                  inputProps={{ min: 1, step: 1 }}
                  helperText="Stock minimum pour déclencher une alerte"
                />
              </Grid>

              {/* Calcul TVA sur marge */}
              <Grid item xs={12}>
                <Divider sx={{ my: 2 }} />
                <Card variant="outlined" sx={{ bgcolor: '#f5f5f5' }}>
                  <CardContent>
                    <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <CalculateIcon />
                      Calcul TVA sur marge
                    </Typography>
                    <Grid container spacing={2} sx={{ mt: 1 }}>
                      <Grid item xs={12} sm={6}>
                        <Typography variant="body2" color="textSecondary">
                          Prix d'achat
                        </Typography>
                        <Typography variant="h6">
                          {formatFromEUR(purchasePrice, currency)}
                        </Typography>
                      </Grid>
                      <Grid item xs={12} sm={6}>
                        <Typography variant="body2" color="textSecondary">
                          Prix de vente HT
                        </Typography>
                        <Typography variant="h6">
                          {formatFromEUR(sellingPrice, currency)}
                        </Typography>
                      </Grid>
                      <Grid item xs={12}>
                        <Divider />
                      </Grid>
                      <Grid item xs={12} sm={6}>
                        <Typography variant="body2" color="textSecondary">
                          Marge
                        </Typography>
                        <Typography variant="h6" color={margin > 0 ? 'success.main' : 'error.main'}>
                          {formatFromEUR(margin, currency)}
                        </Typography>
                      </Grid>
                      <Grid item xs={12} sm={6}>
                        <Typography variant="body2" color="textSecondary">
                          TVA sur marge ({vatRate}%)
                        </Typography>
                        <Typography variant="h6" color="primary.main">
                          {formatFromEUR(vatOnMargin, currency)}
                        </Typography>
                      </Grid>
                      <Grid item xs={12}>
                        <Divider />
                      </Grid>
                      <Grid item xs={12}>
                        <Typography variant="body2" color="textSecondary">
                          Prix TTC (Prix de vente + TVA sur marge)
                        </Typography>
                        <Typography variant="h5" fontWeight="bold" color="primary.main">
                          {formatFromEUR(totalWithVat, currency)}
                        </Typography>
                      </Grid>
                    </Grid>
                    {margin <= 0 && (
                      <Alert severity="warning" sx={{ mt: 2 }}>
                        Le prix de vente doit être supérieur au prix d'achat pour calculer la marge.
                      </Alert>
                    )}
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCloseDialog} disabled={creating}>
              Annuler
            </Button>
            <Button
              onClick={handleCreateProduct}
              variant="contained"
              disabled={creating || margin <= 0 || !formData.name.trim()}
              sx={{ backgroundColor: '#10b981', '&:hover': { backgroundColor: '#059669' } }}
            >
              {creating ? <CircularProgress size={20} /> : 'Créer le produit'}
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </Box>
  );
};

export default BuybackProductsTvaMarge;


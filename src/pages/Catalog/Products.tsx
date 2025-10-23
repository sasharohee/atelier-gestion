import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  Switch,
  FormControlLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  QrCode2 as QrCodeIcon,
  Print as PrintIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import { BarcodeService } from '../../services/barcodeService';
import BarcodeDisplay from '../../components/BarcodeDisplay';
import BarcodePrintDialog from '../../components/BarcodePrintDialog';

const Products: React.FC = () => {
  const { products, addProduct, deleteProduct, updateProduct, loadProducts } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';
  const [openDialog, setOpenDialog] = useState(false);
  const [editingProduct, setEditingProduct] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [printDialogOpen, setPrintDialogOpen] = useState(false);
  const [printProduct, setPrintProduct] = useState<any>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: 'smartphone',
    price: 0,
    stockQuantity: 0,
    minStockLevel: 1,
    isActive: true,
    barcode: '',
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

  const handleOpenDialog = (product?: any) => {
    setOpenDialog(true);
    setError(null);
    if (product) {
      setEditingProduct(product.id);
      setFormData({
        name: product.name || '',
        description: product.description || '',
        category: product.category || 'smartphone',
        price: product.price || 0,
        stockQuantity: product.stockQuantity || 0,
        minStockLevel: product.minStockLevel || 1,
        isActive: product.isActive !== undefined ? product.isActive : true,
        barcode: product.barcode || '',
      });
    } else {
      setEditingProduct(null);
      setFormData({
        name: '',
        description: '',
        category: 'smartphone',
        price: 0,
        stockQuantity: 0,
        minStockLevel: 1,
        isActive: true,
        barcode: '',
      });
    }
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setError(null);
    setEditingProduct(null);
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleDeleteProduct = async (productId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce produit ?')) {
      try {
        await deleteProduct(productId);
        // Recharger les données après suppression
        await loadProducts();
      } catch (error) {
        console.error('Erreur lors de la suppression du produit:', error);
        alert('Erreur lors de la suppression du produit');
      }
    }
  };

  const handleGenerateBarcode = () => {
    try {
      // Récupérer tous les codes-barres existants pour éviter les doublons
      const existingBarcodes = products
        .filter(p => p.barcode)
        .map(p => p.barcode!);
      
      const newBarcode = BarcodeService.generateUniqueEAN13(existingBarcodes);
      setFormData(prev => ({
        ...prev,
        barcode: newBarcode
      }));
    } catch (error) {
      console.error('Erreur lors de la génération du code-barres:', error);
      setError('Erreur lors de la génération du code-barres');
    }
  };

  const handlePrintBarcode = (product: any) => {
    setPrintProduct(product);
    setPrintDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (!formData.name) {
      setError('Le nom du produit est obligatoire');
      return;
    }

    if (formData.price < 0) {
      setError('Le prix ne peut pas être négatif');
      return;
    }

    if (formData.stockQuantity < 0) {
      setError('Le stock ne peut pas être négatif');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Log pour debug
      console.log('🔍 Données à sauvegarder:', {
        editingProduct,
        formData,
        barcode: formData.barcode
      });

      if (editingProduct) {
        // Mode édition
        console.log('📝 Mise à jour du produit:', editingProduct);
        const updateData = {
          name: formData.name,
          description: formData.description,
          category: formData.category,
          price: formData.price,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          isActive: formData.isActive,
          barcode: formData.barcode || null, // S'assurer que c'est null si vide
        };
        console.log('📝 Données de mise à jour:', updateData);
        
        await updateProduct(editingProduct, updateData);
      } else {
        // Mode création
        console.log('➕ Création du produit');
        const createData = {
          name: formData.name,
          description: formData.description,
          category: formData.category,
          price: formData.price,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          isActive: formData.isActive,
          barcode: formData.barcode || null, // S'assurer que c'est null si vide
        };
        console.log('➕ Données de création:', createData);
        
        await addProduct(createData as any);
      }
      
      console.log('✅ Produit sauvegardé avec succès');
      
      // Recharger les données pour afficher le code-barres
      console.log('🔄 Rechargement des données...');
      await loadProducts();
      console.log('✅ Données rechargées');
      
      handleCloseDialog();
    } catch (err) {
      setError('Erreur lors de la sauvegarde du produit');
      console.error('❌ Erreur sauvegarde produit:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Produits
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Produits et accessoires
        </Typography>
      </Box>

      <Box sx={{ mb: 3 }}>
        <Button 
          variant="contained" 
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Nouveau produit
        </Button>
      </Box>

      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Produit</TableCell>
                  <TableCell>Catégorie</TableCell>
                  <TableCell>Stock</TableCell>
                  <TableCell>Stock Min.</TableCell>
                  <TableCell>Prix</TableCell>
                  <TableCell>Code-Barres</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {products.filter(product => product.id).map((product) => {
                  // Log pour debug
                  console.log('🔍 Affichage produit:', { 
                    id: product.id, 
                    name: product.name, 
                    barcode: product.barcode 
                  });
                  
                  return (
                  <TableRow key={product.id}>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {product.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {product.description}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip label={product.category} size="small" />
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        <Chip
                          label={`${product.stockQuantity} en stock`}
                          color={product.stockQuantity === 0 ? 'error' : 
                                 product.stockQuantity <= (product.minStockLevel || 1) ? 'warning' : 'success'}
                          size="small"
                        />
                        {product.stockQuantity <= (product.minStockLevel || 1) && product.stockQuantity > 0 && (
                          <Typography variant="caption" color="warning.main" sx={{ fontSize: '0.7rem' }}>
                            Seuil: {product.minStockLevel || 1}
                          </Typography>
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {product.minStockLevel || 1}
                      </Typography>
                    </TableCell>
                    <TableCell>{formatFromEUR(product.price, currency)}</TableCell>
                    <TableCell>
                      {product.barcode ? (
                        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.5, maxWidth: 180 }}>
                          <BarcodeDisplay 
                            barcode={product.barcode} 
                            width={160} 
                            height={50} 
                            showValue={false}
                            scale={1}
                          />
                          <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.7rem' }}>
                            {BarcodeService.formatBarcode(product.barcode)}
                          </Typography>
                        </Box>
                      ) : (
                        <Typography variant="caption" color="text.secondary">
                          Non généré
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={product.isActive ? 'Actif' : 'Inactif'}
                        color={product.isActive ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <IconButton 
                          size="small" 
                          title="Modifier"
                          onClick={() => handleOpenDialog(product)}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                        {product.barcode && (
                          <IconButton 
                            size="small" 
                            title="Imprimer code-barres"
                            color="primary"
                            onClick={() => handlePrintBarcode(product)}
                          >
                            <PrintIcon fontSize="small" />
                          </IconButton>
                        )}
                        <IconButton 
                          size="small" 
                          title="Supprimer" 
                          color="error"
                          onClick={() => handleDeleteProduct(product.id)}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </TableCell>
                  </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Dialogue de création/édition */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>{editingProduct ? 'Modifier le produit' : 'Créer un nouveau produit'}</DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Nom du produit *"
              value={formData.name}
              onChange={(e) => handleInputChange('name', e.target.value)}
              required
            />
            
            <TextField
              fullWidth
              label="Description"
              value={formData.description}
              onChange={(e) => handleInputChange('description', e.target.value)}
              multiline
              rows={3}
            />
            
            <FormControl fullWidth>
              <InputLabel>Catégorie</InputLabel>
              <Select
                value={formData.category}
                label="Catégorie"
                onChange={(e) => handleInputChange('category', e.target.value)}
              >
                {productCategories.map((category) => (
                  <MenuItem key={category.value} value={category.value}>
                    {category.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label={`Prix TTC (${currency})`}
                type="number"
                value={formData.price}
                onChange={(e) => handleInputChange('price', parseFloat(e.target.value) || 0)}
                inputProps={{ min: 0, step: 0.01 }}
                helperText="Prix toutes taxes comprises"
              />
              
              <TextField
                fullWidth
                label="Stock"
                type="number"
                value={formData.stockQuantity}
                onChange={(e) => handleInputChange('stockQuantity', parseInt(e.target.value) || 0)}
                inputProps={{ min: 0 }}
              />
            </Box>
            
            <TextField
              fullWidth
              label="Stock minimum (alerte)"
              type="number"
              value={formData.minStockLevel}
              onChange={(e) => handleInputChange('minStockLevel', parseInt(e.target.value) || 0)}
              inputProps={{ min: 0 }}
              helperText="Seuil d'alerte quand le stock devient faible"
            />
            
            {/* Section Code-barres */}
            <Box sx={{ border: '1px solid #e0e0e0', borderRadius: 1, p: 2, mt: 2 }}>
              <Typography variant="subtitle2" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                <QrCodeIcon fontSize="small" />
                Code-barres EAN-13
              </Typography>
              
              <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-start' }}>
                <TextField
                  fullWidth
                  label="Code-barres"
                  value={formData.barcode}
                  InputProps={{ readOnly: true }}
                  helperText="Code-barres généré automatiquement"
                  sx={{ flex: 1 }}
                />
                <Button
                  variant="outlined"
                  startIcon={<QrCodeIcon />}
                  onClick={handleGenerateBarcode}
                  sx={{ minWidth: 200 }}
                >
                  {formData.barcode ? 'Régénérer' : 'Générer'}
                </Button>
              </Box>
              
              {formData.barcode && (
                <Box sx={{ mt: 2, textAlign: 'center' }}>
                  <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                    Aperçu du code-barres:
                  </Typography>
                  <BarcodeDisplay 
                    barcode={formData.barcode} 
                    width={200} 
                    height={50} 
                    showValue={true}
                    scale={2}
                  />
                </Box>
              )}
            </Box>
            
            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive}
                  onChange={(e) => handleInputChange('isActive', e.target.checked)}
                />
              }
              label="Produit actif"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog} disabled={loading}>
            Annuler
          </Button>
          <Button 
            onClick={handleSubmit} 
            variant="contained" 
            disabled={loading || !formData.name}
          >
            {loading ? (editingProduct ? 'Modification...' : 'Création...') : (editingProduct ? 'Modifier' : 'Créer')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog d'impression du code-barres */}
      {printProduct && (
        <BarcodePrintDialog
          open={printDialogOpen}
          onClose={() => {
            setPrintDialogOpen(false);
            setPrintProduct(null);
          }}
          product={printProduct}
          currency={currency}
        />
      )}
    </Box>
  );
};

export default Products;

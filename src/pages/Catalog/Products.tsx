import React, { useState, useMemo, useEffect } from 'react';
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
  Autocomplete,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  QrCode2 as QrCodeIcon,
  Print as PrintIcon,
  Search as SearchIcon,
  Clear as ClearIcon,
  QrCodeScanner as ScannerIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import { useSnackbar } from 'notistack';
import { BarcodeService } from '../../services/barcodeService';
import BarcodeDisplay from '../../components/BarcodeDisplay';
import BarcodePrintDialog from '../../components/BarcodePrintDialog';
import BarcodeScannerService from '../../services/barcodeScannerService';
import { productService } from '../../services/supabaseService';
import PriceInputFields from '../../components/PriceInputFields';

const Products: React.FC = () => {
  const { products, addProduct, deleteProduct, updateProduct, loadProducts } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const { enqueueSnackbar } = useSnackbar();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';
  const [openDialog, setOpenDialog] = useState(false);
  const [editingProduct, setEditingProduct] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [printDialogOpen, setPrintDialogOpen] = useState(false);
  const [printProduct, setPrintProduct] = useState<any>(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: 'smartphone',
    subcategory: '',
    price: 0,
    price_ht: 0,
    price_ttc: 0,
    price_is_ttc: false,
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
      
      // Toujours utiliser les données fraîches du store si disponible
      const freshProduct = products.find(p => p.id === product.id);
      const productToUse = freshProduct || product;
      
      console.log('📊 Données utilisées pour le dialogue:', {
        id: productToUse.id,
        name: productToUse.name,
        stockQuantity: productToUse.stockQuantity,
        source: freshProduct ? 'store local' : 'données passées',
        rawProduct: productToUse
      });
      
      // Vérifier le stock dans le dialogue
      if (productToUse.stockQuantity === 0 || productToUse.stockQuantity === undefined) {
        console.log('⚠️ Stock à 0 dans le dialogue, données brutes:', {
          id: productToUse.id,
          name: productToUse.name,
          stockQuantity: productToUse.stockQuantity,
          price: productToUse.price,
          category: productToUse.category
        });
      }
      
      setFormData({
        name: productToUse.name || '',
        description: productToUse.description || '',
        category: productToUse.category || 'smartphone',
        subcategory: productToUse.subcategory || '',
        price: productToUse.price || 0,
        price_ht: productToUse.price_ht || productToUse.price || 0,
        price_ttc: productToUse.price_ttc || (productToUse.price ? productToUse.price * 1.20 : 0),
        price_is_ttc: productToUse.price_is_ttc || false,
        stockQuantity: productToUse.stockQuantity || 0,
        minStockLevel: productToUse.minStockLevel || 1,
        isActive: productToUse.isActive !== undefined ? productToUse.isActive : true,
        barcode: productToUse.barcode || '',
      });
    } else {
      setEditingProduct(null);
      setFormData({
        name: '',
        description: '',
        category: 'smartphone',
        subcategory: '',
        price: 0,
        price_ht: 0,
        price_ttc: 0,
        price_is_ttc: false,
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

  // Fonction de filtrage des produits avec useMemo pour optimiser les performances
  const filteredProducts = useMemo(() => {
    if (!searchTerm) return products;
    
    const searchLower = searchTerm.toLowerCase();
    return products.filter(product => 
      product.name.toLowerCase().includes(searchLower) ||
      product.description.toLowerCase().includes(searchLower) ||
      product.category.toLowerCase().includes(searchLower) ||
      (product.barcode && product.barcode.includes(searchTerm))
    );
  }, [products, searchTerm]);

  const handleClearSearch = () => {
    setSearchTerm('');
  };

  // Fonctions de gestion du scan
  const handleBarcodeScanned = async (barcode: string) => {
    try {
      const result = await productService.getByBarcode(barcode);
      
      if (result.success && result.data) {
        // Récupérer directement les données fraîches depuis la base de données
        console.log('🔄 Récupération des données fraîches depuis la base...');
        try {
          const freshResult = await productService.getByBarcode(barcode);
          if (freshResult.success && freshResult.data) {
            console.log('📊 Données fraîches récupérées:', {
              id: freshResult.data.id,
              name: freshResult.data.name,
              stockQuantity: freshResult.data.stockQuantity,
              price: freshResult.data.price,
              rawData: freshResult.data
            });
            
            // Vérifier si le stock est correct
            if (freshResult.data.stockQuantity === 0 || freshResult.data.stockQuantity === undefined) {
              console.log('⚠️ Stock à 0 ou undefined, vérification des données brutes...');
              console.log('🔍 Données brutes du produit:', {
                id: freshResult.data.id,
                name: freshResult.data.name,
                stockQuantity: freshResult.data.stockQuantity,
                price: freshResult.data.price,
                category: freshResult.data.category,
                description: freshResult.data.description
              });
            }
            
            // Ouvrir le dialogue avec les données fraîches de la base
            handleOpenDialog(freshResult.data);
            
            // Recharger les données en arrière-plan pour synchroniser le store
            loadProducts();
          } else {
            console.log('❌ Impossible de récupérer les données fraîches, utilisation des données de base');
            handleOpenDialog(result.data);
          }
        } catch (error) {
          console.log('❌ Erreur lors de la récupération des données fraîches:', error);
          handleOpenDialog(result.data);
        }
        
        // Notification de succès
        enqueueSnackbar(`Produit scanné: ${result.data.name}`, { 
          variant: 'success',
          autoHideDuration: 2000
        });
      } else {
        // Notification rapide d'erreur
        enqueueSnackbar(`Aucun produit trouvé avec le code-barres: ${barcode}`, { 
          variant: 'warning',
          autoHideDuration: 3000
        });
      }
    } catch (error) {
      // Notification d'erreur
      enqueueSnackbar('Erreur lors de la recherche du produit', { 
        variant: 'error',
        autoHideDuration: 3000
      });
    }
  };


  // Démarrer l'écoute des codes-barres au montage du composant
  useEffect(() => {
    const scannerService = BarcodeScannerService.getInstance();
    scannerService.addScanListener(handleBarcodeScanned);
    scannerService.startListening();


    return () => {
      scannerService.removeScanListener(handleBarcodeScanned);
      scannerService.stopListening();
    };
  }, []);

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
      console.log('📝 handleSubmit - formData complet:', formData);
      console.log('📝 handleSubmit - subcategory value:', formData.subcategory);

      if (editingProduct) {
        // Mode édition
        const updateData = {
          name: formData.name,
          description: formData.description,
          category: formData.category,
          subcategory: formData.subcategory || null,
          price: formData.price,
          price_ht: formData.price_ht,
          price_ttc: formData.price_ttc,
          price_is_ttc: formData.price_is_ttc,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          isActive: formData.isActive,
          barcode: formData.barcode || null, // S'assurer que c'est null si vide
        };
        
        console.log('📝 handleSubmit - updateData avant envoi:', updateData);
        await updateProduct(editingProduct, updateData);
      } else {
        // Mode création
        const createData = {
          name: formData.name,
          description: formData.description,
          category: formData.category,
          subcategory: formData.subcategory || null,
          price: formData.price,
          price_ht: formData.price_ht,
          price_ttc: formData.price_ttc,
          price_is_ttc: formData.price_is_ttc,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          isActive: formData.isActive,
          barcode: formData.barcode || null, // S'assurer que c'est null si vide
        };
        
        await addProduct(createData as any);
      }
      
      
      // Recharger les données pour afficher le code-barres
      await loadProducts();
      
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
        
        {/* Indicateur de scan actif */}
        <Box sx={{ mt: 1, display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <ScannerIcon color="success" fontSize="small" />
            <Typography variant="caption" color="success.main">
              Lecteur de codes-barres actif - Scannez un produit pour l'identifier
            </Typography>
          </Box>
          
        </Box>
      </Box>


      {/* Barre de recherche */}
      <Box sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Rechercher un produit par nom, description, catégorie ou code-barres..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
            endAdornment: searchTerm && (
              <IconButton
                size="small"
                onClick={handleClearSearch}
                sx={{ mr: -1 }}
              >
                <ClearIcon />
              </IconButton>
            ),
          }}
          sx={{ mb: 2 }}
        />
        
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Button 
            variant="contained" 
            startIcon={<AddIcon />}
            onClick={handleOpenDialog}
          >
            Nouveau produit
          </Button>
          
          {searchTerm && (
            <Typography variant="body2" color="text.secondary">
              {filteredProducts.length} produit(s) trouvé(s)
            </Typography>
          )}
        </Box>
      </Box>

      <Card>
        <CardContent>
          {filteredProducts.length === 0 ? (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <Typography variant="h6" color="text.secondary" gutterBottom>
                {searchTerm ? 'Aucun produit trouvé' : 'Aucun produit enregistré'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {searchTerm 
                  ? `Aucun produit ne correspond à "${searchTerm}"`
                  : 'Commencez par ajouter votre premier produit'
                }
              </Typography>
            </Box>
          ) : (
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
                  {filteredProducts.filter(product => product.id).map((product) => {
                  
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
          )}
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
            
            <Autocomplete
              freeSolo
              options={Array.from(new Set(
                products
                  .filter(p => p.subcategory)
                  .map(p => p.subcategory!)
              )).sort()}
              value={formData.subcategory || null}
              onChange={(event, newValue) => {
                console.log('🎯 Autocomplete onChange - newValue:', newValue);
                handleInputChange('subcategory', newValue || '');
              }}
              onInputChange={(event, newInputValue, reason) => {
                console.log('🎯 Autocomplete onInputChange - newInputValue:', newInputValue, 'reason:', reason);
                // Enregistrer la valeur lors de la saisie libre
                if (reason === 'input') {
                  handleInputChange('subcategory', newInputValue || '');
                }
              }}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Sous-catégorie"
                  placeholder="Créer une sous-catégorie ou sélectionner"
                />
              )}
            />
            
            <PriceInputFields
              priceHT={formData.price_ht || 0}
              priceTTC={formData.price_ttc || 0}
              priceIsTTC={formData.price_is_ttc}
              currency={currency}
              onChange={(values) => {
                setFormData(prev => ({
                  ...prev,
                  price_ht: values.price_ht,
                  price_ttc: values.price_ttc,
                  price_is_ttc: values.price_is_ttc,
                  price: values.price_is_ttc ? values.price_ttc : values.price_ht // pour compatibilité
                }));
              }}
              disabled={loading}
              error={error}
            />
            
            <Box sx={{ display: 'flex', gap: 2 }}>
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

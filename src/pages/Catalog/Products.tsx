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
  Grid,
  InputAdornment,
  alpha,
  Divider,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  QrCode2 as QrCodeIcon,
  Print as PrintIcon,
  Search as SearchIcon,
  QrCodeScanner as ScannerIcon,
  Close as CloseIcon,
  ShoppingBag as ProductIcon,
  CheckCircle as ActiveIcon,
  Warning as WarningIcon,
  AttachMoney as MoneyIcon,
  Inventory2 as StockIcon,
  Category as CategoryIcon,
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

/* ─── Design tokens ─── */
const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': { boxShadow: '0 8px 32px rgba(0,0,0,0.10)', transform: 'translateY(-2px)' },
} as const;

const CARD_STATIC = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
} as const;

const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;

const BTN_DARK = {
  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;

const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── KPI Mini ─── */
function KpiMini({ icon, iconColor, label, value }: {
  icon: React.ReactNode; iconColor: string; label: string; value: string | number;
}) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{
            width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0, boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
          }}>{icon}</Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>{value}</Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>{label}</Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── Category color map ─── */
const CATEGORY_COLORS: Record<string, string> = {
  'console': '#8b5cf6',
  'ordinateur_portable': '#3b82f6',
  'ordinateur_fixe': '#6366f1',
  'smartphone': '#10b981',
  'montre': '#f59e0b',
  'manette_jeux': '#ef4444',
  'ecouteur': '#ec4899',
  'casque': '#14b8a6',
  'accessoire': '#f97316',
  'protection': '#06b6d4',
  'connectique': '#84cc16',
  'logiciel': '#a855f7',
  'autre': '#6b7280',
};

/* ─── Stock status helpers ─── */
const getStockStatus = (qty: number, min: number) => {
  if (qty <= 0) return { label: 'Rupture', color: '#ef4444' };
  if (qty <= min) return { label: 'Stock bas', color: '#f59e0b' };
  return { label: 'En stock', color: '#22c55e' };
};

const Products: React.FC = () => {
  const { products, addProduct, deleteProduct, updateProduct, loadProducts } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const { enqueueSnackbar } = useSnackbar();

  const currency = workshopSettings?.currency || 'EUR';
  const [openDialog, setOpenDialog] = useState(false);
  const [editingProduct, setEditingProduct] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [printDialogOpen, setPrintDialogOpen] = useState(false);
  const [printProduct, setPrintProduct] = useState<any>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>('all');

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
    { value: 'ordinateur_portable', label: 'PC portable' },
    { value: 'ordinateur_fixe', label: 'PC fixe' },
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

      const freshProduct = products.find(p => p.id === product.id);
      const productToUse = freshProduct || product;

      const priceHT = productToUse.price || 0;
      const priceTTC = Math.round(priceHT * 1.20 * 100) / 100;

      setFormData({
        name: productToUse.name || '',
        description: productToUse.description || '',
        category: productToUse.category || 'smartphone',
        subcategory: productToUse.subcategory || '',
        price: priceHT,
        price_ht: priceHT,
        price_ttc: priceTTC,
        price_is_ttc: false,
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
        await loadProducts();
      } catch (error) {
        console.error('Erreur lors de la suppression du produit:', error);
        alert('Erreur lors de la suppression du produit');
      }
    }
  };

  const handleGenerateBarcode = () => {
    try {
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

  /* ─── Filtered products ─── */
  const filteredProducts = useMemo(() => {
    let filtered = products;
    if (searchTerm) {
      const searchLower = searchTerm.toLowerCase();
      filtered = filtered.filter(product =>
        product.name.toLowerCase().includes(searchLower) ||
        product.description.toLowerCase().includes(searchLower) ||
        product.category.toLowerCase().includes(searchLower) ||
        (product.barcode && product.barcode.includes(searchTerm))
      );
    }
    if (filterCategory !== 'all') {
      filtered = filtered.filter(p => p.category === filterCategory);
    }
    return filtered;
  }, [products, searchTerm, filterCategory]);

  /* ─── KPI values ─── */
  const totalProducts = products.length;
  const totalStock = products.reduce((acc, p) => acc + (p.stockQuantity || 0), 0);
  const lowStockCount = products.filter(p => (p.stockQuantity || 0) <= (p.minStockLevel || 1) && (p.stockQuantity || 0) > 0).length;
  const outOfStockCount = products.filter(p => (p.stockQuantity || 0) <= 0).length;
  const totalValue = products.reduce((acc, p) => acc + ((p.price || 0) * (p.stockQuantity || 0)), 0);

  /* ─── Active categories for filter chips ─── */
  const activeCategories = useMemo(() => {
    const cats = new Set(products.map(p => p.category));
    return productCategories.filter(c => cats.has(c.value));
  }, [products]);

  // Barcode scanning
  const handleBarcodeScanned = async (barcode: string) => {
    try {
      const result = await productService.getByBarcode(barcode);

      if (result.success && result.data) {
        try {
          const freshResult = await productService.getByBarcode(barcode);
          if (freshResult.success && freshResult.data) {
            handleOpenDialog(freshResult.data);
            loadProducts();
          } else {
            handleOpenDialog(result.data);
          }
        } catch {
          handleOpenDialog(result.data);
        }

        enqueueSnackbar(`Produit scanné: ${result.data.name}`, {
          variant: 'success',
          autoHideDuration: 2000
        });
      } else {
        enqueueSnackbar(`Aucun produit trouvé avec le code-barres: ${barcode}`, {
          variant: 'warning',
          autoHideDuration: 3000
        });
      }
    } catch {
      enqueueSnackbar('Erreur lors de la recherche du produit', {
        variant: 'error',
        autoHideDuration: 3000
      });
    }
  };

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
      if (editingProduct) {
        await updateProduct(editingProduct, {
          name: formData.name,
          description: formData.description,
          category: formData.category,
          subcategory: formData.subcategory || null,
          price: formData.price_ht,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          isActive: formData.isActive,
          barcode: formData.barcode || null,
        });
      } else {
        await addProduct({
          name: formData.name,
          description: formData.description,
          category: formData.category,
          subcategory: formData.subcategory || null,
          price: formData.price_ht,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          isActive: formData.isActive,
          barcode: formData.barcode || null,
        } as any);
      }

      await loadProducts();
      handleCloseDialog();
    } catch (err) {
      setError('Erreur lors de la sauvegarde du produit');
      console.error('Erreur sauvegarde produit:', err);
    } finally {
      setLoading(false);
    }
  };

  const getCategoryColor = (category: string) => CATEGORY_COLORS[category] || '#6b7280';
  const getCategoryLabel = (value: string) => productCategories.find(c => c.value === value)?.label || value;

  return (
    <Box>
      {/* ─── Header ─── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.02em', color: '#111827' }}>
            Produits & accessoires
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mt: 0.5 }}>
            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
              Gérez votre catalogue de produits en vente
            </Typography>
            <Chip
              icon={<ScannerIcon sx={{ fontSize: 14 }} />}
              label="Scanner actif"
              size="small"
              sx={{
                fontWeight: 600, borderRadius: '6px', fontSize: '0.65rem', height: 22,
                bgcolor: alpha('#22c55e', 0.1), color: '#22c55e',
                '& .MuiChip-icon': { color: '#22c55e' },
              }}
            />
          </Box>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
          sx={BTN_DARK}
        >
          Nouveau produit
        </Button>
      </Box>

      {/* ─── KPI Cards ─── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<ProductIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total produits" value={totalProducts} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<StockIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Unités en stock" value={totalStock} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<WarningIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="Alertes stock" value={lowStockCount + outOfStockCount} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<MoneyIcon sx={{ fontSize: 20 }} />} iconColor="#3b82f6" label="Valeur stock HT" value={formatFromEUR(totalValue, currency)} />
        </Grid>
      </Grid>

      {/* ─── Search & Filters ─── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <TextField
            placeholder="Rechercher par nom, catégorie ou code-barres..."
            size="small"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            sx={{ flex: 1, minWidth: 260, ...INPUT_SX }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: 'text.disabled', fontSize: 20 }} />
                </InputAdornment>
              ),
            }}
          />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            <Chip
              label="Tous"
              onClick={() => setFilterCategory('all')}
              size="small"
              sx={{
                fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                ...(filterCategory === 'all'
                  ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
                  : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
              }}
            />
            {activeCategories.map(cat => (
              <Chip
                key={cat.value}
                label={cat.label}
                onClick={() => setFilterCategory(cat.value)}
                size="small"
                sx={{
                  fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                  ...(filterCategory === cat.value
                    ? { bgcolor: getCategoryColor(cat.value), color: '#fff', '&:hover': { bgcolor: getCategoryColor(cat.value) } }
                    : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
                }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* ─── Products Table ─── */}
      <Card sx={CARD_STATIC}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Produit</TableCell>
                <TableCell>Catégorie</TableCell>
                <TableCell align="center">Stock</TableCell>
                <TableCell align="right">Prix HT</TableCell>
                <TableCell>Code-barres</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredProducts.filter(product => product.id).map((product) => {
                const catColor = getCategoryColor(product.category);
                const stock = getStockStatus(product.stockQuantity || 0, product.minStockLevel || 1);
                return (
                  <TableRow
                    key={product.id}
                    sx={{
                      '&:last-child td': { borderBottom: 0 },
                      '& td': { py: 1.5 },
                      '&:hover': { bgcolor: 'rgba(0,0,0,0.015)' },
                      transition: 'background-color 0.15s ease',
                    }}
                  >
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box sx={{
                          width: 36, height: 36, borderRadius: '10px', display: 'flex',
                          alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                          bgcolor: alpha(catColor, 0.08),
                        }}>
                          <ProductIcon sx={{ fontSize: 18, color: catColor }} />
                        </Box>
                        <Box sx={{ minWidth: 0 }}>
                          <Typography variant="body2" sx={{ fontWeight: 600, color: '#111827' }}>
                            {product.name}
                          </Typography>
                          <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 220 }}>
                            {product.description}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getCategoryLabel(product.category)}
                        size="small"
                        sx={{
                          fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                          bgcolor: alpha(catColor, 0.1), color: catColor,
                        }}
                      />
                      {product.subcategory && (
                        <Typography variant="caption" sx={{ display: 'block', color: 'text.disabled', mt: 0.3, fontSize: '0.68rem' }}>
                          {product.subcategory}
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.3 }}>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: stock.color }}>
                          {product.stockQuantity}
                        </Typography>
                        <Chip
                          label={stock.label}
                          size="small"
                          sx={{
                            fontWeight: 600, borderRadius: '6px', fontSize: '0.65rem', height: 20,
                            bgcolor: alpha(stock.color, 0.1), color: stock.color,
                          }}
                        />
                      </Box>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" sx={{ fontWeight: 700, color: '#111827' }}>
                        {formatFromEUR(product.price, currency)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      {product.barcode ? (
                        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.3, maxWidth: 160 }}>
                          <BarcodeDisplay
                            barcode={product.barcode}
                            width={140}
                            height={40}
                            showValue={false}
                            scale={1}
                          />
                          <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.65rem', fontFamily: 'monospace' }}>
                            {BarcodeService.formatBarcode(product.barcode)}
                          </Typography>
                        </Box>
                      ) : (
                        <Typography variant="caption" sx={{ color: 'text.disabled' }}>—</Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={product.isActive ? 'Actif' : 'Inactif'}
                        size="small"
                        sx={{
                          fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                          bgcolor: product.isActive ? alpha('#22c55e', 0.1) : alpha('#6b7280', 0.1),
                          color: product.isActive ? '#22c55e' : '#6b7280',
                        }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'flex-end' }}>
                        <Tooltip title="Modifier" arrow>
                          <IconButton
                            size="small"
                            onClick={() => handleOpenDialog(product)}
                            sx={{
                              bgcolor: alpha('#6366f1', 0.08), borderRadius: '8px',
                              '&:hover': { bgcolor: alpha('#6366f1', 0.15) },
                            }}
                          >
                            <EditIcon sx={{ fontSize: 18, color: '#6366f1' }} />
                          </IconButton>
                        </Tooltip>
                        {product.barcode && (
                          <Tooltip title="Imprimer code-barres" arrow>
                            <IconButton
                              size="small"
                              onClick={() => handlePrintBarcode(product)}
                              sx={{
                                bgcolor: alpha('#3b82f6', 0.08), borderRadius: '8px',
                                '&:hover': { bgcolor: alpha('#3b82f6', 0.15) },
                              }}
                            >
                              <PrintIcon sx={{ fontSize: 18, color: '#3b82f6' }} />
                            </IconButton>
                          </Tooltip>
                        )}
                        <Tooltip title="Supprimer" arrow>
                          <IconButton
                            size="small"
                            onClick={() => handleDeleteProduct(product.id)}
                            sx={{
                              bgcolor: alpha('#ef4444', 0.08), borderRadius: '8px',
                              '&:hover': { bgcolor: alpha('#ef4444', 0.15) },
                            }}
                          >
                            <DeleteIcon sx={{ fontSize: 18, color: '#ef4444' }} />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>

        {filteredProducts.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 8 }}>
            <Box sx={{
              width: 56, height: 56, borderRadius: '16px', display: 'flex',
              alignItems: 'center', justifyContent: 'center', mb: 2,
              bgcolor: alpha('#6366f1', 0.08),
            }}>
              <ProductIcon sx={{ fontSize: 28, color: '#6366f1' }} />
            </Box>
            <Typography variant="body1" sx={{ fontWeight: 600, color: '#111827', mb: 0.5 }}>
              Aucun produit trouvé
            </Typography>
            <Typography variant="body2" color="text.disabled">
              {searchTerm || filterCategory !== 'all'
                ? 'Essayez de modifier vos filtres de recherche'
                : 'Ajoutez votre premier produit au catalogue'}
            </Typography>
            {!searchTerm && filterCategory === 'all' && (
              <Button
                variant="contained"
                size="small"
                startIcon={<AddIcon />}
                onClick={() => handleOpenDialog()}
                sx={{ ...BTN_DARK, mt: 2.5, fontSize: '0.8rem' }}
              >
                Ajouter un produit
              </Button>
            )}
          </Box>
        )}

        {/* Results count */}
        {products.length > 0 && (
          <Box sx={{ px: 2.5, py: 1.5, borderTop: '1px solid', borderColor: 'divider', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="caption" sx={{ color: 'text.disabled' }}>
              {filteredProducts.length} produit{filteredProducts.length > 1 ? 's' : ''} sur {products.length}
            </Typography>
          </Box>
        )}
      </Card>

      {/* ─── Create/Edit Dialog ─── */}
      <Dialog
        open={openDialog}
        onClose={handleCloseDialog}
        maxWidth="md"
        fullWidth
        disableEnforceFocus
        disableAutoFocus
        disableRestoreFocus
        hideBackdrop={false}
        BackdropProps={{
          sx: { backgroundColor: 'rgba(0, 0, 0, 0.5)' }
        }}
        PaperProps={{ sx: { borderRadius: '16px' } }}
      >
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', pb: 1 }}>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#111827' }}>
              {editingProduct ? 'Modifier le produit' : 'Nouveau produit'}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              {editingProduct ? 'Modifiez les informations du produit' : 'Remplissez les informations pour ajouter un produit'}
            </Typography>
          </Box>
          <IconButton onClick={handleCloseDialog} size="small" sx={{ bgcolor: 'grey.100', borderRadius: '8px' }}>
            <CloseIcon sx={{ fontSize: 18 }} />
          </IconButton>
        </DialogTitle>

        <Divider />

        <DialogContent sx={{ pt: 2.5 }}>
          {error && (
            <Alert severity="error" sx={{ mb: 2, borderRadius: '10px' }}>
              {error}
            </Alert>
          )}

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
            <TextField
              fullWidth
              label="Nom du produit *"
              value={formData.name}
              onChange={(e) => handleInputChange('name', e.target.value)}
              required
              sx={INPUT_SX}
            />

            <TextField
              fullWidth
              label="Description"
              value={formData.description}
              onChange={(e) => handleInputChange('description', e.target.value)}
              multiline
              rows={3}
              sx={INPUT_SX}
            />

            <Box sx={{ display: 'flex', gap: 2 }}>
              <FormControl fullWidth sx={INPUT_SX}>
                <InputLabel>Catégorie</InputLabel>
                <Select
                  value={formData.category}
                  label="Catégorie"
                  onChange={(e) => handleInputChange('category', e.target.value)}
                >
                  {productCategories.map((category) => (
                    <MenuItem key={category.value} value={category.value}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Box sx={{
                          width: 8, height: 8, borderRadius: '50%',
                          bgcolor: getCategoryColor(category.value),
                        }} />
                        {category.label}
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <Autocomplete
                fullWidth
                freeSolo
                options={Array.from(new Set(
                  products
                    .filter(p => p.subcategory)
                    .map(p => p.subcategory!)
                )).sort()}
                value={formData.subcategory || null}
                onChange={(event, newValue) => {
                  handleInputChange('subcategory', newValue || '');
                }}
                onInputChange={(event, newInputValue, reason) => {
                  if (reason === 'input') {
                    handleInputChange('subcategory', newInputValue || '');
                  }
                }}
                renderInput={(params) => (
                  <TextField
                    {...params}
                    label="Sous-catégorie"
                    placeholder="Sélectionner ou créer"
                    sx={INPUT_SX}
                  />
                )}
              />
            </Box>

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
                  price: values.price_is_ttc ? values.price_ttc : values.price_ht
                }));
              }}
              disabled={loading}
              error={error}
            />

            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label="Stock actuel"
                type="number"
                value={formData.stockQuantity}
                onChange={(e) => handleInputChange('stockQuantity', parseInt(e.target.value) || 0)}
                inputProps={{ min: 0 }}
                sx={INPUT_SX}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <StockIcon sx={{ color: 'text.disabled', fontSize: 18 }} />
                    </InputAdornment>
                  ),
                }}
              />
              <TextField
                fullWidth
                label="Stock minimum"
                type="number"
                value={formData.minStockLevel}
                onChange={(e) => handleInputChange('minStockLevel', parseInt(e.target.value) || 0)}
                inputProps={{ min: 0 }}
                sx={INPUT_SX}
                helperText="Seuil d'alerte stock faible"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <WarningIcon sx={{ color: 'text.disabled', fontSize: 18 }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Box>

            {/* ─── Barcode Section ─── */}
            <Box sx={{
              border: '1px solid rgba(0,0,0,0.06)', borderRadius: '12px', p: 2.5,
              bgcolor: 'rgba(0,0,0,0.01)',
            }}>
              <Typography variant="body2" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1, fontWeight: 600, color: '#111827' }}>
                <QrCodeIcon sx={{ fontSize: 18, color: '#6366f1' }} />
                Code-barres EAN-13
              </Typography>

              <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-start' }}>
                <TextField
                  fullWidth
                  label="Code-barres"
                  value={formData.barcode}
                  InputProps={{ readOnly: true }}
                  helperText="Code-barres généré automatiquement"
                  sx={{ flex: 1, ...INPUT_SX }}
                />
                <Button
                  variant="outlined"
                  startIcon={<QrCodeIcon sx={{ fontSize: 18 }} />}
                  onClick={handleGenerateBarcode}
                  sx={{
                    minWidth: 160, borderRadius: '10px', textTransform: 'none', fontWeight: 600,
                    borderColor: alpha('#6366f1', 0.3), color: '#6366f1',
                    '&:hover': { borderColor: '#6366f1', bgcolor: alpha('#6366f1', 0.04) },
                  }}
                >
                  {formData.barcode ? 'Régénérer' : 'Générer'}
                </Button>
              </Box>

              {formData.barcode && (
                <Box sx={{ mt: 2.5, textAlign: 'center', p: 2, bgcolor: '#fff', borderRadius: '10px', border: '1px solid rgba(0,0,0,0.04)' }}>
                  <Typography variant="caption" color="text.disabled" sx={{ mb: 1, display: 'block', fontSize: '0.68rem' }}>
                    Aperçu
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
                  sx={{
                    '& .MuiSwitch-switchBase.Mui-checked': { color: '#22c55e' },
                    '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { bgcolor: '#22c55e' },
                  }}
                />
              }
              label={
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  Produit actif
                </Typography>
              }
            />
          </Box>
        </DialogContent>

        <Divider />

        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button
            onClick={handleCloseDialog}
            disabled={loading}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}
          >
            Annuler
          </Button>
          <Button
            onClick={handleSubmit}
            variant="contained"
            disabled={loading || !formData.name}
            sx={BTN_DARK}
          >
            {loading ? (editingProduct ? 'Modification...' : 'Création...') : (editingProduct ? 'Modifier' : 'Créer le produit')}
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

import React, { useState, useMemo } from 'react';
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
  Search as SearchIcon,
  Inventory2 as PartsIcon,
  CheckCircle as ActiveIcon,
  Warning as WarningIcon,
  AttachMoney as MoneyIcon,
  LocalShipping as SupplierIcon,
  Close as CloseIcon,
  QrCode as RefIcon,
  BrandingWatermark as BrandIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
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

/* ─── Stock status helpers ─── */
const getStockStatus = (qty: number, min: number) => {
  if (qty <= 0) return { label: 'Rupture', color: '#ef4444' };
  if (qty <= min) return { label: 'Stock bas', color: '#f59e0b' };
  return { label: 'En stock', color: '#22c55e' };
};

const Parts: React.FC = () => {
  const { parts, addPart, deletePart, updatePart } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();

  const currency = workshopSettings?.currency || 'EUR';
  const [openDialog, setOpenDialog] = useState(false);
  const [editingPart, setEditingPart] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStock, setFilterStock] = useState<string>('all');
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    partNumber: '',
    brand: '',
    subcategory: '',
    compatibleDevices: [] as string[],
    stockQuantity: 0,
    minStockLevel: 1,
    price: 0,
    price_ht: 0,
    price_ttc: 0,
    price_is_ttc: false,
    supplier: '',
    isActive: true,
  });

  const deviceTypes = [
    { value: 'smartphone', label: 'Smartphone' },
    { value: 'tablet', label: 'Tablette' },
    { value: 'laptop', label: 'Ordinateur portable' },
    { value: 'desktop', label: 'Ordinateur fixe' },
    { value: 'other', label: 'Autre' },
  ];

  const stockFilterOptions = [
    { value: 'all', label: 'Tous' },
    { value: 'in_stock', label: 'En stock' },
    { value: 'low', label: 'Stock bas' },
    { value: 'out', label: 'Rupture' },
  ];

  /* ─── Filtered parts ─── */
  const filteredParts = useMemo(() => {
    let filtered = parts;
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(term) ||
        p.description?.toLowerCase().includes(term) ||
        p.partNumber?.toLowerCase().includes(term) ||
        p.brand?.toLowerCase().includes(term) ||
        p.supplier?.toLowerCase().includes(term)
      );
    }
    if (filterStock === 'in_stock') {
      filtered = filtered.filter(p => p.stockQuantity > p.minStockLevel);
    } else if (filterStock === 'low') {
      filtered = filtered.filter(p => p.stockQuantity > 0 && p.stockQuantity <= p.minStockLevel);
    } else if (filterStock === 'out') {
      filtered = filtered.filter(p => p.stockQuantity <= 0);
    }
    return filtered;
  }, [parts, searchTerm, filterStock]);

  /* ─── KPI values ─── */
  const totalParts = parts.length;
  const totalStock = parts.reduce((acc, p) => acc + (p.stockQuantity || 0), 0);
  const lowStockCount = parts.filter(p => p.stockQuantity > 0 && p.stockQuantity <= p.minStockLevel).length;
  const outOfStockCount = parts.filter(p => p.stockQuantity <= 0).length;
  const totalValue = parts.reduce((acc, p) => acc + ((p.price || 0) * (p.stockQuantity || 0)), 0);

  const handleOpenDialog = (part?: any) => {
    setOpenDialog(true);
    setError(null);
    if (part) {
      setEditingPart(part.id);
      const priceHT = part.price || 0;
      const priceTTC = Math.round(priceHT * 1.20 * 100) / 100;

      setFormData({
        name: part.name,
        description: part.description,
        partNumber: part.partNumber,
        brand: part.brand,
        subcategory: part.subcategory || '',
        compatibleDevices: part.compatibleDevices || [],
        stockQuantity: part.stockQuantity,
        minStockLevel: part.minStockLevel,
        price: priceHT,
        price_ht: priceHT,
        price_ttc: priceTTC,
        price_is_ttc: false,
        supplier: part.supplier,
        isActive: part.isActive,
      });
    } else {
      setEditingPart(null);
      setFormData({
        name: '',
        description: '',
        partNumber: '',
        brand: '',
        subcategory: '',
        compatibleDevices: [],
        stockQuantity: 0,
        minStockLevel: 1,
        price: 0,
        price_ht: 0,
        price_ttc: 0,
        price_is_ttc: false,
        supplier: '',
        isActive: true,
      });
    }
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setError(null);
    setEditingPart(null);
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleDeletePart = async (partId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cette pièce ?')) {
      try {
        await deletePart(partId);
      } catch (error) {
        console.error('Erreur lors de la suppression de la pièce:', error);
        alert('Erreur lors de la suppression de la pièce');
      }
    }
  };

  const handleSubmit = async () => {
    if (!formData.name) {
      setError('Le nom est obligatoire');
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
      if (editingPart) {
        await updatePart(editingPart, {
          name: formData.name,
          description: formData.description,
          partNumber: formData.partNumber || undefined,
          brand: formData.brand || undefined,
          subcategory: formData.subcategory || null,
          compatibleDevices: formData.compatibleDevices,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          price: formData.price_ht,
          price_ht: formData.price_ht,
          price_ttc: formData.price_ttc,
          price_is_ttc: formData.price_is_ttc,
          supplier: formData.supplier || undefined,
          isActive: formData.isActive,
        });
      } else {
        const newPart = {
          name: formData.name,
          description: formData.description,
          partNumber: formData.partNumber || undefined,
          brand: formData.brand || undefined,
          subcategory: formData.subcategory || null,
          compatibleDevices: formData.compatibleDevices,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          price: formData.price_ht,
          price_ht: formData.price_ht,
          price_ttc: formData.price_ttc,
          price_is_ttc: formData.price_is_ttc,
          supplier: formData.supplier || undefined,
          isActive: formData.isActive,
        };

        await addPart(newPart as any);
      }

      handleCloseDialog();
    } catch (err) {
      setError('Erreur lors de la sauvegarde de la pièce');
      console.error('Erreur sauvegarde pièce:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      {/* ─── Header ─── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.02em', color: '#111827' }}>
            Pièces détachées
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gérez votre inventaire de pièces et composants
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
          sx={BTN_DARK}
        >
          Nouvelle pièce
        </Button>
      </Box>

      {/* ─── KPI Cards ─── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<PartsIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total pièces" value={totalParts} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<ActiveIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Unités en stock" value={totalStock} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<WarningIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="Stock bas" value={lowStockCount + outOfStockCount} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<MoneyIcon sx={{ fontSize: 20 }} />} iconColor="#3b82f6" label="Valeur stock HT" value={formatFromEUR(totalValue, currency)} />
        </Grid>
      </Grid>

      {/* ─── Search & Filters ─── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <TextField
            placeholder="Rechercher une pièce..."
            size="small"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            sx={{ flex: 1, minWidth: 220, ...INPUT_SX }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: 'text.disabled', fontSize: 20 }} />
                </InputAdornment>
              ),
            }}
          />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {stockFilterOptions.map(opt => {
              const chipColors: Record<string, string> = {
                'in_stock': '#22c55e',
                'low': '#f59e0b',
                'out': '#ef4444',
              };
              const isActive = filterStock === opt.value;
              const activeColor = chipColors[opt.value];
              return (
                <Chip
                  key={opt.value}
                  label={opt.label}
                  onClick={() => setFilterStock(opt.value)}
                  size="small"
                  sx={{
                    fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                    ...(isActive
                      ? activeColor
                        ? { bgcolor: activeColor, color: '#fff', '&:hover': { bgcolor: activeColor } }
                        : { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
                      : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
                  }}
                />
              );
            })}
          </Box>
        </CardContent>
      </Card>

      {/* ─── Parts Table ─── */}
      <Card sx={CARD_STATIC}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Pièce</TableCell>
                <TableCell>Référence</TableCell>
                <TableCell>Marque</TableCell>
                <TableCell align="center">Stock</TableCell>
                <TableCell align="right">Prix HT</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredParts.map((part) => {
                const stock = getStockStatus(part.stockQuantity, part.minStockLevel);
                return (
                  <TableRow
                    key={part.id}
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
                          bgcolor: alpha('#6366f1', 0.08),
                        }}>
                          <PartsIcon sx={{ fontSize: 18, color: '#6366f1' }} />
                        </Box>
                        <Box sx={{ minWidth: 0 }}>
                          <Typography variant="body2" sx={{ fontWeight: 600, color: '#111827' }}>
                            {part.name}
                          </Typography>
                          <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 250 }}>
                            {part.description}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      {part.partNumber ? (
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                          <RefIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                          <Typography variant="body2" sx={{ fontWeight: 500, color: '#6366f1', fontFamily: 'monospace', fontSize: '0.8rem' }}>
                            {part.partNumber}
                          </Typography>
                        </Box>
                      ) : (
                        <Typography variant="caption" sx={{ color: 'text.disabled' }}>—</Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      {part.brand ? (
                        <Chip
                          label={part.brand}
                          size="small"
                          sx={{
                            fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                            bgcolor: alpha('#8b5cf6', 0.08), color: '#8b5cf6',
                          }}
                        />
                      ) : (
                        <Typography variant="caption" sx={{ color: 'text.disabled' }}>—</Typography>
                      )}
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.3 }}>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: stock.color }}>
                          {part.stockQuantity}
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
                        {formatFromEUR(part.price, currency)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={part.isActive ? 'Actif' : 'Inactif'}
                        size="small"
                        sx={{
                          fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                          bgcolor: part.isActive ? alpha('#22c55e', 0.1) : alpha('#6b7280', 0.1),
                          color: part.isActive ? '#22c55e' : '#6b7280',
                        }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'flex-end' }}>
                        <Tooltip title="Modifier" arrow>
                          <IconButton
                            size="small"
                            onClick={() => handleOpenDialog(part)}
                            sx={{
                              bgcolor: alpha('#6366f1', 0.08), borderRadius: '8px',
                              '&:hover': { bgcolor: alpha('#6366f1', 0.15) },
                            }}
                          >
                            <EditIcon sx={{ fontSize: 18, color: '#6366f1' }} />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Supprimer" arrow>
                          <IconButton
                            size="small"
                            onClick={() => handleDeletePart(part.id)}
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

        {filteredParts.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 8 }}>
            <Box sx={{
              width: 56, height: 56, borderRadius: '16px', display: 'flex',
              alignItems: 'center', justifyContent: 'center', mb: 2,
              bgcolor: alpha('#6366f1', 0.08),
            }}>
              <PartsIcon sx={{ fontSize: 28, color: '#6366f1' }} />
            </Box>
            <Typography variant="body1" sx={{ fontWeight: 600, color: '#111827', mb: 0.5 }}>
              Aucune pièce trouvée
            </Typography>
            <Typography variant="body2" color="text.disabled">
              {searchTerm || filterStock !== 'all'
                ? 'Essayez de modifier vos filtres de recherche'
                : 'Ajoutez votre première pièce détachée'}
            </Typography>
            {!searchTerm && filterStock === 'all' && (
              <Button
                variant="contained"
                size="small"
                startIcon={<AddIcon />}
                onClick={() => handleOpenDialog()}
                sx={{ ...BTN_DARK, mt: 2.5, fontSize: '0.8rem' }}
              >
                Ajouter une pièce
              </Button>
            )}
          </Box>
        )}

        {/* Results count */}
        {parts.length > 0 && (
          <Box sx={{ px: 2.5, py: 1.5, borderTop: '1px solid', borderColor: 'divider', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="caption" sx={{ color: 'text.disabled' }}>
              {filteredParts.length} pièce{filteredParts.length > 1 ? 's' : ''} sur {parts.length}
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
              {editingPart ? 'Modifier la pièce' : 'Nouvelle pièce'}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              {editingPart ? 'Modifiez les informations de la pièce' : 'Remplissez les informations pour ajouter une pièce'}
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
              label="Nom de la pièce *"
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
              rows={2}
              sx={INPUT_SX}
            />

            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label="Référence"
                value={formData.partNumber}
                onChange={(e) => handleInputChange('partNumber', e.target.value)}
                sx={INPUT_SX}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <RefIcon sx={{ color: 'text.disabled', fontSize: 18 }} />
                    </InputAdornment>
                  ),
                }}
              />
              <TextField
                fullWidth
                label="Marque"
                value={formData.brand}
                onChange={(e) => handleInputChange('brand', e.target.value)}
                sx={INPUT_SX}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <BrandIcon sx={{ color: 'text.disabled', fontSize: 18 }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Box>

            <Autocomplete
              freeSolo
              options={Array.from(new Set(
                parts
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

            <FormControl fullWidth sx={INPUT_SX}>
              <InputLabel>Appareils compatibles</InputLabel>
              <Select
                multiple
                value={formData.compatibleDevices}
                label="Appareils compatibles"
                onChange={(e) => handleInputChange('compatibleDevices', e.target.value)}
                renderValue={(selected) => (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                    {(selected as string[]).map(value => {
                      const device = deviceTypes.find(d => d.value === value);
                      return (
                        <Chip
                          key={value}
                          label={device?.label || value}
                          size="small"
                          sx={{ borderRadius: '6px', fontWeight: 500, fontSize: '0.72rem' }}
                        />
                      );
                    })}
                  </Box>
                )}
              >
                {deviceTypes.map((type) => (
                  <MenuItem key={type.value} value={type.value}>
                    {type.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

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
                      <PartsIcon sx={{ color: 'text.disabled', fontSize: 18 }} />
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
                helperText="Alerte quand le stock atteint ce seuil"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <WarningIcon sx={{ color: 'text.disabled', fontSize: 18 }} />
                    </InputAdornment>
                  ),
                }}
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
                  price: values.price_ht
                }));
              }}
              disabled={loading}
              error={error}
            />

            <TextField
              fullWidth
              label="Fournisseur"
              value={formData.supplier}
              onChange={(e) => handleInputChange('supplier', e.target.value)}
              sx={INPUT_SX}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SupplierIcon sx={{ color: 'text.disabled', fontSize: 18 }} />
                  </InputAdornment>
                ),
              }}
            />

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
                  Pièce active
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
            disabled={loading || !formData.name || !formData.partNumber || !formData.brand}
            sx={BTN_DARK}
          >
            {loading ? (editingPart ? 'Modification...' : 'Création...') : (editingPart ? 'Modifier' : 'Créer la pièce')}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Parts;

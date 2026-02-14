import React, { useState, useEffect, useMemo } from 'react';
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
  Snackbar,
  Grid,
  InputAdornment,
  alpha,
  Divider,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Search as SearchIcon,
  Close as CloseIcon,
  ErrorOutline as ErrorIcon,
  Inventory2 as StockIcon,
  ReportProblem as AlertIcon,
  AccessTime as TimeIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

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

const OutOfStock: React.FC = () => {
  const {
    getActiveStockAlerts,
    parts,
    products,
    addStockAlert,
    resolveStockAlert,
    deleteStockAlert,
    loadStockAlerts
  } = useAppStore();

  const [openDialog, setOpenDialog] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [formData, setFormData] = useState({
    partId: '',
    type: 'low_stock' as 'low_stock' | 'out_of_stock',
    message: '',
  });

  const stockAlerts = getActiveStockAlerts();

  useEffect(() => {
    loadStockAlerts();
  }, [loadStockAlerts]);

  /* ─── Filtered alerts ─── */
  const filteredAlerts = useMemo(() => {
    let filtered = stockAlerts;
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(alert => {
        const part = parts.find(p => p.id === alert.partId);
        const product = products.find(p => p.id === alert.partId);
        const item = part || product;
        return (
          item?.name?.toLowerCase().includes(term) ||
          alert.message?.toLowerCase().includes(term)
        );
      });
    }
    if (filterType === 'low_stock') {
      filtered = filtered.filter(a => a.type === 'low_stock');
    } else if (filterType === 'out_of_stock') {
      filtered = filtered.filter(a => a.type === 'out_of_stock');
    } else if (filterType === 'resolved') {
      filtered = filtered.filter(a => a.isResolved);
    } else if (filterType === 'pending') {
      filtered = filtered.filter(a => !a.isResolved);
    }
    return filtered;
  }, [stockAlerts, searchTerm, filterType, parts, products]);

  /* ─── KPI values ─── */
  const totalAlerts = stockAlerts.length;
  const outOfStockCount = stockAlerts.filter(a => a.type === 'out_of_stock').length;
  const lowStockCount = stockAlerts.filter(a => a.type === 'low_stock').length;
  const pendingCount = stockAlerts.filter(a => !a.isResolved).length;

  const filterOptions = [
    { value: 'all', label: 'Toutes' },
    { value: 'pending', label: 'En attente' },
    { value: 'out_of_stock', label: 'Ruptures' },
    { value: 'low_stock', label: 'Stock faible' },
  ];

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSubmit = async () => {
    if (!formData.partId || !formData.message) {
      setError('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await addStockAlert({
        partId: formData.partId,
        type: formData.type,
        message: formData.message,
        isResolved: false,
      });

      setSuccess('Alerte créée avec succès');
      handleCloseDialog();
    } catch (err) {
      setError('Erreur lors de la création de l\'alerte');
      console.error('Erreur création alerte:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setFormData({
      partId: '',
      type: 'low_stock',
      message: '',
    });
    setError(null);
  };

  const handleResolveAlert = async (alertId: string) => {
    try {
      await resolveStockAlert(alertId);
      setSuccess('Alerte marquée comme résolue');
    } catch (err) {
      setError('Erreur lors de la résolution de l\'alerte');
      console.error('Erreur résolution alerte:', err);
    }
  };

  const handleDeleteAlert = async (alertId: string) => {
    try {
      await deleteStockAlert(alertId);
      setSuccess('Alerte supprimée avec succès');
    } catch (err) {
      setError('Erreur lors de la suppression de l\'alerte');
      console.error('Erreur suppression alerte:', err);
    }
  };

  const handleCloseSnackbar = () => {
    setSuccess(null);
    setError(null);
  };

  return (
    <Box>
      {/* ─── Header ─── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.02em', color: '#111827' }}>
            Ruptures de stock
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Suivez et gérez les alertes de stock de vos articles
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setOpenDialog(true)}
          sx={BTN_DARK}
        >
          Nouvelle alerte
        </Button>
      </Box>

      {/* ─── KPI Cards ─── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<AlertIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total alertes" value={totalAlerts} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<ErrorIcon sx={{ fontSize: 20 }} />} iconColor="#ef4444" label="Ruptures" value={outOfStockCount} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<WarningIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="Stock faible" value={lowStockCount} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<TimeIcon sx={{ fontSize: 20 }} />} iconColor="#3b82f6" label="En attente" value={pendingCount} />
        </Grid>
      </Grid>

      {/* ─── Search & Filters ─── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <TextField
            placeholder="Rechercher un article..."
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
            {filterOptions.map(opt => {
              const chipColors: Record<string, string> = {
                'pending': '#3b82f6',
                'out_of_stock': '#ef4444',
                'low_stock': '#f59e0b',
              };
              const isActive = filterType === opt.value;
              const activeColor = chipColors[opt.value];
              return (
                <Chip
                  key={opt.value}
                  label={opt.label}
                  onClick={() => setFilterType(opt.value)}
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

      {/* ─── Alerts Table ─── */}
      <Card sx={CARD_STATIC}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Article</TableCell>
                <TableCell>Type d'alerte</TableCell>
                <TableCell align="center">Stock actuel</TableCell>
                <TableCell align="center">Seuil min.</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredAlerts.map((alert) => {
                const part = parts.find(p => p.id === alert.partId);
                const product = products.find(p => p.id === alert.partId);
                const item = part || product;
                const isPart = !!part;
                const currentStock = part ? part.stockQuantity : product ? product.stockQuantity : 0;
                const minStock = part ? part.minStockLevel : product ? product.minStockLevel : 0;
                const isOutOfStock = alert.type === 'out_of_stock';
                const alertColor = isOutOfStock ? '#ef4444' : '#f59e0b';

                return (
                  <TableRow
                    key={alert.id}
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
                          bgcolor: alpha(alertColor, 0.08),
                        }}>
                          {isOutOfStock
                            ? <ErrorIcon sx={{ fontSize: 18, color: alertColor }} />
                            : <WarningIcon sx={{ fontSize: 18, color: alertColor }} />
                          }
                        </Box>
                        <Box sx={{ minWidth: 0 }}>
                          <Typography variant="body2" sx={{ fontWeight: 600, color: '#111827' }}>
                            {item?.name || 'Article inconnu'}
                          </Typography>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.2 }}>
                            <Chip
                              label={isPart ? 'Pièce' : 'Produit'}
                              size="small"
                              sx={{
                                height: 18, fontSize: '0.6rem', fontWeight: 600, borderRadius: '4px',
                                bgcolor: isPart ? alpha('#6366f1', 0.08) : alpha('#10b981', 0.08),
                                color: isPart ? '#6366f1' : '#10b981',
                              }}
                            />
                            <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.7rem' }}>
                              {part ? part.partNumber : product ? product.category : ''}
                            </Typography>
                          </Box>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={isOutOfStock ? 'Rupture' : 'Stock faible'}
                        size="small"
                        sx={{
                          fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                          bgcolor: alpha(alertColor, 0.1), color: alertColor,
                        }}
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Typography variant="body2" sx={{
                        fontWeight: 700,
                        color: currentStock <= 0 ? '#ef4444' : currentStock <= minStock ? '#f59e0b' : '#22c55e',
                      }}>
                        {currentStock}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                        {minStock}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ color: 'text.secondary', fontSize: '0.82rem' }}>
                        {new Date(alert.createdAt).toLocaleDateString('fr-FR', {
                          day: '2-digit', month: 'short', year: 'numeric'
                        })}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={alert.isResolved ? 'Résolue' : 'En attente'}
                        size="small"
                        sx={{
                          fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                          bgcolor: alert.isResolved ? alpha('#22c55e', 0.1) : alpha('#3b82f6', 0.1),
                          color: alert.isResolved ? '#22c55e' : '#3b82f6',
                        }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'flex-end' }}>
                        {!alert.isResolved && (
                          <Tooltip title="Marquer résolue" arrow>
                            <IconButton
                              size="small"
                              onClick={() => handleResolveAlert(alert.id)}
                              sx={{
                                bgcolor: alpha('#22c55e', 0.08), borderRadius: '8px',
                                '&:hover': { bgcolor: alpha('#22c55e', 0.15) },
                              }}
                            >
                              <CheckCircleIcon sx={{ fontSize: 18, color: '#22c55e' }} />
                            </IconButton>
                          </Tooltip>
                        )}
                        <Tooltip title="Supprimer" arrow>
                          <IconButton
                            size="small"
                            onClick={() => handleDeleteAlert(alert.id)}
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

        {filteredAlerts.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 8 }}>
            <Box sx={{
              width: 56, height: 56, borderRadius: '16px', display: 'flex',
              alignItems: 'center', justifyContent: 'center', mb: 2,
              bgcolor: alpha('#22c55e', 0.08),
            }}>
              <CheckCircleIcon sx={{ fontSize: 28, color: '#22c55e' }} />
            </Box>
            <Typography variant="body1" sx={{ fontWeight: 600, color: '#111827', mb: 0.5 }}>
              {searchTerm || filterType !== 'all' ? 'Aucune alerte trouvée' : 'Aucune alerte active'}
            </Typography>
            <Typography variant="body2" color="text.disabled">
              {searchTerm || filterType !== 'all'
                ? 'Essayez de modifier vos filtres de recherche'
                : 'Tous vos stocks sont à un niveau satisfaisant'}
            </Typography>
          </Box>
        )}

        {/* Results count */}
        {stockAlerts.length > 0 && (
          <Box sx={{ px: 2.5, py: 1.5, borderTop: '1px solid', borderColor: 'divider' }}>
            <Typography variant="caption" sx={{ color: 'text.disabled' }}>
              {filteredAlerts.length} alerte{filteredAlerts.length > 1 ? 's' : ''} sur {stockAlerts.length}
            </Typography>
          </Box>
        )}
      </Card>

      {/* ─── Create Alert Dialog ─── */}
      <Dialog
        open={openDialog}
        onClose={handleCloseDialog}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: '16px' } }}
      >
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', pb: 1 }}>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#111827' }}>
              Nouvelle alerte
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              Signalez un problème de stock sur un article
            </Typography>
          </Box>
          <IconButton onClick={handleCloseDialog} size="small" sx={{ bgcolor: 'grey.100', borderRadius: '8px' }}>
            <CloseIcon sx={{ fontSize: 18 }} />
          </IconButton>
        </DialogTitle>

        <Divider />

        <DialogContent sx={{ pt: 2.5 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
            <FormControl fullWidth sx={INPUT_SX}>
              <InputLabel>Article *</InputLabel>
              <Select
                value={formData.partId}
                onChange={(e) => handleInputChange('partId', e.target.value)}
                label="Article *"
              >
                {parts.length > 0 && (
                  <MenuItem disabled sx={{ fontSize: '0.75rem', fontWeight: 600, color: 'text.secondary', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Pièces détachées
                  </MenuItem>
                )}
                {parts.map((part) => (
                  <MenuItem key={`part-${part.id}`} value={part.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Chip
                        label="Pièce"
                        size="small"
                        sx={{
                          height: 18, fontSize: '0.6rem', fontWeight: 600, borderRadius: '4px',
                          bgcolor: alpha('#6366f1', 0.08), color: '#6366f1',
                        }}
                      />
                      <Typography variant="body2">{part.name}</Typography>
                      {part.partNumber && (
                        <Typography variant="caption" sx={{ color: 'text.disabled', fontFamily: 'monospace' }}>
                          {part.partNumber}
                        </Typography>
                      )}
                    </Box>
                  </MenuItem>
                ))}
                {products.length > 0 && (
                  <MenuItem disabled sx={{ fontSize: '0.75rem', fontWeight: 600, color: 'text.secondary', textTransform: 'uppercase', letterSpacing: '0.05em', mt: 1 }}>
                    Produits
                  </MenuItem>
                )}
                {products.map((product) => (
                  <MenuItem key={`product-${product.id}`} value={product.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Chip
                        label="Produit"
                        size="small"
                        sx={{
                          height: 18, fontSize: '0.6rem', fontWeight: 600, borderRadius: '4px',
                          bgcolor: alpha('#10b981', 0.08), color: '#10b981',
                        }}
                      />
                      <Typography variant="body2">{product.name}</Typography>
                      <Typography variant="caption" sx={{ color: 'text.disabled' }}>
                        {product.category}
                      </Typography>
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl fullWidth sx={INPUT_SX}>
              <InputLabel>Type d'alerte</InputLabel>
              <Select
                value={formData.type}
                onChange={(e) => handleInputChange('type', e.target.value)}
                label="Type d'alerte"
              >
                <MenuItem value="low_stock">
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: '#f59e0b' }} />
                    Stock faible
                  </Box>
                </MenuItem>
                <MenuItem value="out_of_stock">
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: '#ef4444' }} />
                    Rupture de stock
                  </Box>
                </MenuItem>
              </Select>
            </FormControl>

            <TextField
              label="Message *"
              value={formData.message}
              onChange={(e) => handleInputChange('message', e.target.value)}
              multiline
              rows={3}
              fullWidth
              placeholder="Décrivez le problème de stock..."
              sx={INPUT_SX}
            />
          </Box>
        </DialogContent>

        <Divider />

        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button
            onClick={handleCloseDialog}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}
          >
            Annuler
          </Button>
          <Button
            onClick={handleSubmit}
            variant="contained"
            disabled={loading || !formData.partId || !formData.message}
            sx={BTN_DARK}
          >
            {loading ? 'Création...' : 'Créer l\'alerte'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={!!success || !!error}
        autoHideDuration={4000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          onClose={handleCloseSnackbar}
          severity={success ? 'success' : 'error'}
          sx={{ borderRadius: '10px', fontWeight: 500 }}
        >
          {success || error}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default OutOfStock;

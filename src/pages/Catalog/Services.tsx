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
  Checkbox,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListItemSecondaryAction,
  LinearProgress,
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
  FileDownload as FileDownloadIcon,
  Search as SearchIcon,
  Build as BuildIcon,
  Timer as TimerIcon,
  AttachMoney as MoneyIcon,
  Category as CategoryIcon,
  CheckCircle as ActiveIcon,
  Close as CloseIcon,
  FilterList as FilterIcon,
  ContentCopy as CopyIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import PriceInputFields from '../../components/PriceInputFields';
import { predefinedServicePacks, PredefinedService } from '../../data/predefinedServices';

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
  'réparation': '#6366f1',
  'maintenance': '#f59e0b',
  'diagnostic': '#3b82f6',
  'installation': '#10b981',
  'autre': '#8b5cf6',
};

const Services: React.FC = () => {
  const { services, addService, updateService, deleteService } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();

  const currency = workshopSettings?.currency || 'EUR';
  const [openDialog, setOpenDialog] = useState(false);
  const [editingService, setEditingService] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    duration: 0,
    price: 0,
    price_ht: 0,
    price_ttc: 0,
    price_is_ttc: true,
    category: 'réparation' as string,
    subcategory: '',
    applicableDevices: [] as string[],
    isActive: true,
  });

  // Import dialog state
  const [importDialogOpen, setImportDialogOpen] = useState(false);
  const [selectedImportServices, setSelectedImportServices] = useState<Set<number>>(new Set());
  const [importing, setImporting] = useState(false);
  const [importProgress, setImportProgress] = useState(0);
  const [importResult, setImportResult] = useState<{ created: number; skipped: number } | null>(null);

  const serviceCategories = [
    { value: 'réparation', label: 'Réparation' },
    { value: 'maintenance', label: 'Maintenance' },
    { value: 'diagnostic', label: 'Diagnostic' },
    { value: 'installation', label: 'Installation' },
    { value: 'autre', label: 'Autre' },
  ];

  const deviceTypes = [
    { value: 'smartphone', label: 'Smartphone' },
    { value: 'tablet', label: 'Tablette' },
    { value: 'laptop', label: 'Ordinateur portable' },
    { value: 'desktop', label: 'Ordinateur fixe' },
    { value: 'other', label: 'Autre' },
  ];

  /* ─── Filtered services ─── */
  const filteredServices = useMemo(() => {
    let filtered = services;
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(s =>
        s.name.toLowerCase().includes(term) ||
        s.description?.toLowerCase().includes(term) ||
        s.category?.toLowerCase().includes(term) ||
        s.subcategory?.toLowerCase().includes(term)
      );
    }
    if (filterCategory !== 'all') {
      filtered = filtered.filter(s => s.category === filterCategory);
    }
    return filtered;
  }, [services, searchTerm, filterCategory]);

  /* ─── KPI values ─── */
  const totalServices = services.length;
  const activeServices = services.filter(s => s.isActive).length;
  const uniqueCategories = new Set(services.map(s => s.category)).size;
  const avgPrice = services.length > 0
    ? services.reduce((acc, s) => acc + (s.price || 0), 0) / services.length
    : 0;

  /* ─── Predefined services ─── */
  const allPredefinedServices = predefinedServicePacks.flatMap(pack => pack.services);

  const isServiceExisting = (predefined: PredefinedService): boolean => {
    return services.some(
      s => s.name.toLowerCase().trim() === predefined.name.toLowerCase().trim()
    );
  };

  const selectableServices = allPredefinedServices
    .map((s, i) => ({ ...s, index: i }))
    .filter(s => !isServiceExisting(s));

  const handleToggleImportService = (index: number) => {
    setSelectedImportServices(prev => {
      const next = new Set(prev);
      if (next.has(index)) next.delete(index);
      else next.add(index);
      return next;
    });
  };

  const handleToggleAllImportServices = () => {
    if (selectedImportServices.size === selectableServices.length) {
      setSelectedImportServices(new Set());
    } else {
      setSelectedImportServices(new Set(selectableServices.map(s => s.index)));
    }
  };

  const handleOpenImportDialog = () => {
    setImportDialogOpen(true);
    setSelectedImportServices(new Set());
    setImportResult(null);
    setImporting(false);
    setImportProgress(0);
  };

  const handleCloseImportDialog = () => {
    if (!importing) setImportDialogOpen(false);
  };

  const handleImportServices = async () => {
    const toImport = allPredefinedServices.filter((_, i) => selectedImportServices.has(i));
    if (toImport.length === 0) return;

    setImporting(true);
    setImportProgress(0);
    let created = 0;
    let skipped = 0;

    for (let i = 0; i < toImport.length; i++) {
      const predefined = toImport[i];

      if (isServiceExisting(predefined)) {
        skipped++;
      } else {
        try {
          await addService({
            name: predefined.name,
            description: predefined.description,
            duration: predefined.duration,
            price: predefined.price,
            category: predefined.category,
            subcategory: predefined.subcategory,
            applicableDevices: ['smartphone'],
            isActive: true,
          } as any);
          created++;
        } catch (err) {
          console.error(`Erreur lors de l'import de "${predefined.name}":`, err);
          skipped++;
        }
      }

      setImportProgress(Math.round(((i + 1) / toImport.length) * 100));
    }

    setImporting(false);
    setImportResult({ created, skipped });
    setSelectedImportServices(new Set());
  };

  const handleOpenDialog = (service?: any) => {
    setOpenDialog(true);
    setError(null);

    if (service) {
      setEditingService(service.id);
      const priceHT = service.price || 0;
      const priceTTC = Math.round(priceHT * 1.20 * 100) / 100;

      setFormData({
        name: service.name,
        description: service.description,
        duration: service.duration,
        price: priceHT,
        price_ht: priceHT,
        price_ttc: priceTTC,
        price_is_ttc: false,
        category: service.category || 'réparation',
        subcategory: service.subcategory || '',
        applicableDevices: service.applicableDevices || [],
        isActive: service.isActive !== undefined ? service.isActive : true,
      });
    } else {
      setEditingService(null);
      setFormData({
        name: '',
        description: '',
        duration: 0,
        price: 0,
        price_ht: 0,
        price_ttc: 0,
        price_is_ttc: false,
        category: 'réparation' as string,
        subcategory: '',
        applicableDevices: [] as string[],
        isActive: true,
      });
    }
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setError(null);
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value !== undefined ? value : (field === 'duration' ? 0 : field === 'price' ? 0 : field === 'isActive' ? true : field === 'applicableDevices' ? [] : ''),
    }));
  };

  const handleDeleteService = async (serviceId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce service ?')) {
      try {
        await deleteService(serviceId);
      } catch (error) {
        console.error('Erreur lors de la suppression du service:', error);
        alert('Erreur lors de la suppression du service');
      }
    }
  };

  const handleSubmit = async () => {
    if (!formData.name || !formData.description) {
      setError('Le nom et la description sont obligatoires');
      return;
    }

    if (formData.price < 0) {
      setError('Le prix ne peut pas être négatif');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const serviceData = {
        name: formData.name,
        description: formData.description,
        duration: formData.duration,
        price: formData.price_ht,
        category: formData.category,
        subcategory: formData.subcategory || null,
        applicableDevices: formData.applicableDevices,
        isActive: formData.isActive,
      };

      if (editingService) {
        await updateService(editingService, serviceData);
      } else {
        await addService(serviceData as any);
      }

      handleCloseDialog();
    } catch (err) {
      setError(editingService ? 'Erreur lors de la modification du service' : 'Erreur lors de la création du service');
      console.error('Erreur service:', err);
    } finally {
      setLoading(false);
    }
  };

  const getCategoryColor = (category: string) => CATEGORY_COLORS[category] || '#6b7280';

  return (
    <Box>
      {/* ─── Header ─── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.02em', color: '#111827' }}>
            Catalogue de services
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gérez vos prestations de réparation et maintenance
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5 }}>
          <Button
            variant="outlined"
            startIcon={<FileDownloadIcon sx={{ fontSize: 18 }} />}
            onClick={handleOpenImportDialog}
            sx={{
              borderRadius: '10px', textTransform: 'none', fontWeight: 600,
              borderColor: 'rgba(0,0,0,0.12)', color: 'text.primary',
              '&:hover': { borderColor: 'rgba(0,0,0,0.24)', bgcolor: 'grey.50' },
            }}
          >
            Importer
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpenDialog()}
            sx={BTN_DARK}
          >
            Nouveau service
          </Button>
        </Box>
      </Box>

      {/* ─── KPI Cards ─── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<BuildIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total services" value={totalServices} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<ActiveIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Services actifs" value={activeServices} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<CategoryIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="Catégories" value={uniqueCategories} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<MoneyIcon sx={{ fontSize: 20 }} />} iconColor="#3b82f6" label="Prix moyen HT" value={formatFromEUR(avgPrice, currency)} />
        </Grid>
      </Grid>

      {/* ─── Search & Filters ─── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <TextField
            placeholder="Rechercher un service..."
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
            {serviceCategories.map(cat => (
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

      {/* ─── Services Table ─── */}
      <Card sx={CARD_STATIC}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Service</TableCell>
                <TableCell>Catégorie</TableCell>
                <TableCell>Durée</TableCell>
                <TableCell align="right">Prix HT</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredServices.map((service) => {
                const catColor = getCategoryColor(service.category);
                return (
                  <TableRow
                    key={service.id}
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
                          <BuildIcon sx={{ fontSize: 18, color: catColor }} />
                        </Box>
                        <Box sx={{ minWidth: 0 }}>
                          <Typography variant="body2" sx={{ fontWeight: 600, color: '#111827' }}>
                            {service.name}
                          </Typography>
                          <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 280 }}>
                            {service.description}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={serviceCategories.find(c => c.value === service.category)?.label || service.category}
                        size="small"
                        sx={{
                          fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                          bgcolor: alpha(catColor, 0.1), color: catColor,
                        }}
                      />
                      {service.subcategory && (
                        <Typography variant="caption" sx={{ display: 'block', color: 'text.disabled', mt: 0.3, fontSize: '0.68rem' }}>
                          {service.subcategory}
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <TimerIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                        <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                          {service.duration}h
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" sx={{ fontWeight: 700, color: '#111827' }}>
                        {formatFromEUR(service.price, currency)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={service.isActive ? 'Actif' : 'Inactif'}
                        size="small"
                        sx={{
                          fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                          bgcolor: service.isActive ? alpha('#22c55e', 0.1) : alpha('#6b7280', 0.1),
                          color: service.isActive ? '#22c55e' : '#6b7280',
                        }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'flex-end' }}>
                        <Tooltip title="Modifier" arrow>
                          <IconButton
                            size="small"
                            onClick={() => handleOpenDialog(service)}
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
                            onClick={() => handleDeleteService(service.id)}
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

        {filteredServices.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 8 }}>
            <Box sx={{
              width: 56, height: 56, borderRadius: '16px', display: 'flex',
              alignItems: 'center', justifyContent: 'center', mb: 2,
              bgcolor: alpha('#6366f1', 0.08),
            }}>
              <BuildIcon sx={{ fontSize: 28, color: '#6366f1' }} />
            </Box>
            <Typography variant="body1" sx={{ fontWeight: 600, color: '#111827', mb: 0.5 }}>
              Aucun service trouvé
            </Typography>
            <Typography variant="body2" color="text.disabled">
              {searchTerm || filterCategory !== 'all'
                ? 'Essayez de modifier vos filtres de recherche'
                : 'Créez votre premier service ou importez des services prédéfinis'}
            </Typography>
            {!searchTerm && filterCategory === 'all' && (
              <Box sx={{ display: 'flex', gap: 1.5, mt: 2.5 }}>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<FileDownloadIcon sx={{ fontSize: 16 }} />}
                  onClick={handleOpenImportDialog}
                  sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 600, borderColor: 'rgba(0,0,0,0.12)' }}
                >
                  Importer
                </Button>
                <Button
                  variant="contained"
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={() => handleOpenDialog()}
                  sx={{ ...BTN_DARK, fontSize: '0.8rem' }}
                >
                  Créer un service
                </Button>
              </Box>
            )}
          </Box>
        )}

        {/* Results count */}
        {services.length > 0 && (
          <Box sx={{ px: 2.5, py: 1.5, borderTop: '1px solid', borderColor: 'divider', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="caption" sx={{ color: 'text.disabled' }}>
              {filteredServices.length} service{filteredServices.length > 1 ? 's' : ''} sur {services.length}
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
              {editingService ? 'Modifier le service' : 'Nouveau service'}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              {editingService ? 'Modifiez les informations du service' : 'Remplissez les informations pour créer un service'}
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
              label="Nom du service *"
              value={formData.name || ''}
              onChange={(e) => handleInputChange('name', e.target.value)}
              required
              sx={INPUT_SX}
            />

            <TextField
              fullWidth
              label="Description *"
              value={formData.description || ''}
              onChange={(e) => handleInputChange('description', e.target.value)}
              multiline
              rows={3}
              required
              sx={INPUT_SX}
            />

            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label="Durée (heures)"
                type="number"
                value={formData.duration || 0}
                onChange={(e) => handleInputChange('duration', parseFloat(e.target.value) || 0)}
                inputProps={{ min: 0, step: 0.1 }}
                helperText="Durée en heures"
                sx={INPUT_SX}
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

            <Box sx={{ display: 'flex', gap: 2 }}>
              <FormControl fullWidth sx={INPUT_SX}>
                <InputLabel>Catégorie</InputLabel>
                <Select
                  value={formData.category || 'réparation'}
                  label="Catégorie"
                  onChange={(e) => handleInputChange('category', e.target.value)}
                >
                  {serviceCategories.map((category) => (
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
                  services
                    .filter(s => s.subcategory)
                    .map(s => s.subcategory!)
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

            <FormControl fullWidth sx={INPUT_SX}>
              <InputLabel>Appareils compatibles</InputLabel>
              <Select
                multiple
                value={formData.applicableDevices || []}
                label="Appareils compatibles"
                onChange={(e) => handleInputChange('applicableDevices', e.target.value)}
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

            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive || false}
                  onChange={(e) => handleInputChange('isActive', e.target.checked)}
                  sx={{
                    '& .MuiSwitch-switchBase.Mui-checked': { color: '#22c55e' },
                    '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { bgcolor: '#22c55e' },
                  }}
                />
              }
              label={
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  Service actif
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
            disabled={loading || !formData.name || !formData.description}
            sx={BTN_DARK}
          >
            {loading
              ? (editingService ? 'Modification...' : 'Création...')
              : (editingService ? 'Modifier' : 'Créer le service')
            }
          </Button>
        </DialogActions>
      </Dialog>

      {/* ─── Import Dialog ─── */}
      <Dialog
        open={importDialogOpen}
        onClose={handleCloseImportDialog}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: '16px' } }}
      >
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', pb: 1 }}>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, color: '#111827' }}>
              Importer des services
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              Sélectionnez les services prédéfinis à ajouter
            </Typography>
          </Box>
          <IconButton onClick={handleCloseImportDialog} disabled={importing} size="small" sx={{ bgcolor: 'grey.100', borderRadius: '8px' }}>
            <CloseIcon sx={{ fontSize: 18 }} />
          </IconButton>
        </DialogTitle>

        <Divider />

        <DialogContent sx={{ pt: 2 }}>
          {importResult ? (
            <Alert severity="success" sx={{ borderRadius: '10px' }} icon={<ActiveIcon />}>
              <Typography variant="body2" sx={{ fontWeight: 600 }}>Import terminé</Typography>
              <Typography variant="caption">
                {importResult.created} service{importResult.created > 1 ? 's' : ''} créé{importResult.created > 1 ? 's' : ''}
                {importResult.skipped > 0 && ` · ${importResult.skipped} ignoré${importResult.skipped > 1 ? 's' : ''}`}
              </Typography>
            </Alert>
          ) : (
            <>
              {importing && (
                <Box sx={{ mb: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary' }}>
                      Import en cours...
                    </Typography>
                    <Typography variant="caption" sx={{ fontWeight: 700, color: '#6366f1' }}>
                      {importProgress}%
                    </Typography>
                  </Box>
                  <LinearProgress
                    variant="determinate"
                    value={importProgress}
                    sx={{
                      borderRadius: '4px', height: 6,
                      bgcolor: alpha('#6366f1', 0.1),
                      '& .MuiLinearProgress-bar': { bgcolor: '#6366f1', borderRadius: '4px' },
                    }}
                  />
                </Box>
              )}

              {!importing && (
                <Box sx={{
                  display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                  p: 1.5, mb: 1, bgcolor: 'grey.50', borderRadius: '10px',
                }}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={selectableServices.length > 0 && selectedImportServices.size === selectableServices.length}
                        indeterminate={selectedImportServices.size > 0 && selectedImportServices.size < selectableServices.length}
                        onChange={handleToggleAllImportServices}
                        disabled={selectableServices.length === 0}
                        size="small"
                        sx={{ '&.Mui-checked': { color: '#6366f1' } }}
                      />
                    }
                    label={
                      <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>
                        Tout sélectionner
                      </Typography>
                    }
                    sx={{ ml: 0 }}
                  />
                  <Chip
                    label={`${selectableServices.length} disponible${selectableServices.length > 1 ? 's' : ''}`}
                    size="small"
                    sx={{ fontWeight: 600, borderRadius: '6px', fontSize: '0.7rem', bgcolor: alpha('#6366f1', 0.1), color: '#6366f1' }}
                  />
                </Box>
              )}

              <List dense sx={{ maxHeight: 400, overflow: 'auto' }}>
                {allPredefinedServices.map((predefined, index) => {
                  const existing = isServiceExisting(predefined);
                  const catColor = getCategoryColor(predefined.category);
                  return (
                    <ListItem
                      key={index}
                      dense
                      sx={{
                        opacity: existing ? 0.45 : 1,
                        borderRadius: '10px',
                        mb: 0.5,
                        transition: 'background-color 0.15s ease',
                        '&:hover': { bgcolor: existing ? 'transparent' : alpha('#6366f1', 0.04) },
                      }}
                    >
                      <ListItemIcon sx={{ minWidth: 36 }}>
                        <Checkbox
                          edge="start"
                          checked={selectedImportServices.has(index)}
                          onChange={() => handleToggleImportService(index)}
                          disabled={existing || importing}
                          size="small"
                          sx={{ '&.Mui-checked': { color: '#6366f1' } }}
                        />
                      </ListItemIcon>
                      <ListItemText
                        primary={
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.82rem' }}>
                              {predefined.name}
                            </Typography>
                            {existing && (
                              <Chip
                                label="Existant"
                                size="small"
                                sx={{
                                  height: 18, fontSize: '0.65rem', fontWeight: 600,
                                  borderRadius: '6px', bgcolor: alpha('#6b7280', 0.1), color: '#6b7280',
                                }}
                              />
                            )}
                          </Box>
                        }
                        secondary={
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.3 }}>
                            <Chip
                              label={predefined.subcategory}
                              size="small"
                              sx={{
                                height: 18, fontSize: '0.62rem', fontWeight: 500,
                                borderRadius: '4px', bgcolor: alpha(catColor, 0.08), color: catColor,
                              }}
                            />
                            <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.7rem' }}>
                              · {predefined.duration}h
                            </Typography>
                          </Box>
                        }
                      />
                      <ListItemSecondaryAction>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: '#6366f1', fontSize: '0.82rem' }}>
                          {predefined.price}€
                        </Typography>
                      </ListItemSecondaryAction>
                    </ListItem>
                  );
                })}
              </List>
            </>
          )}
        </DialogContent>

        <Divider />

        <DialogActions sx={{ px: 3, py: 2 }}>
          {importResult ? (
            <Button onClick={handleCloseImportDialog} variant="contained" sx={BTN_DARK}>
              Fermer
            </Button>
          ) : (
            <>
              <Button
                onClick={handleCloseImportDialog}
                disabled={importing}
                sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}
              >
                Annuler
              </Button>
              <Button
                onClick={handleImportServices}
                variant="contained"
                disabled={importing || selectedImportServices.size === 0}
                startIcon={<FileDownloadIcon sx={{ fontSize: 18 }} />}
                sx={BTN_DARK}
              >
                {importing
                  ? 'Import en cours...'
                  : `Importer ${selectedImportServices.size} service${selectedImportServices.size > 1 ? 's' : ''}`}
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Services;

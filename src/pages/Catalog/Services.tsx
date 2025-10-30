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
  Autocomplete,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import PriceInputFields from '../../components/PriceInputFields';

const Services: React.FC = () => {
  const { services, addService, updateService, deleteService } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';
  const [openDialog, setOpenDialog] = useState(false);
  const [editingService, setEditingService] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    duration: 0,
    price: 0,
    price_ht: 0,
    price_ttc: 0,
    price_is_ttc: true, // Services sont par défaut en TTC
    category: 'réparation' as string,
    subcategory: '',
    applicableDevices: [] as string[],
    isActive: true,
  });

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

  const handleOpenDialog = (service?: any) => {
    setOpenDialog(true);
    setError(null);
    
    if (service) {
      // Mode édition
      setEditingService(service.id);
      setFormData({
        name: service.name,
        description: service.description,
        duration: service.duration,
        price: service.price,
        price_ht: service.price_ht || (service.price ? service.price / 1.20 : 0),
        price_ttc: service.price_ttc || service.price || 0,
        price_is_ttc: service.price_is_ttc !== undefined ? service.price_is_ttc : true,
        category: service.category || 'réparation',
        subcategory: service.subcategory || '',
        applicableDevices: service.applicableDevices || [],
        isActive: service.isActive !== undefined ? service.isActive : true,
      });
    } else {
      // Mode création
      setEditingService(null);
      setFormData({
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
        price: formData.price,
        price_ht: formData.price_ht,
        price_ttc: formData.price_ttc,
        price_is_ttc: formData.price_is_ttc,
        category: formData.category,
        subcategory: formData.subcategory || null,
        applicableDevices: formData.applicableDevices,
        isActive: formData.isActive,
      };

      if (editingService) {
        // Mode édition
        await updateService(editingService, serviceData);
      } else {
        // Mode création
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

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Services
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Services de réparation proposés
        </Typography>
      </Box>

      <Box sx={{ mb: 3 }}>
        <Button 
          variant="contained" 
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Nouveau service
        </Button>
      </Box>

      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Service</TableCell>
                  <TableCell>Catégorie</TableCell>
                  <TableCell>Durée</TableCell>
                  <TableCell>Prix</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {services.map((service) => (
                  <TableRow key={service.id}>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {service.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {service.description}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip label={service.category} size="small" />
                    </TableCell>
                    <TableCell>{service.duration}h</TableCell>
                    <TableCell>{formatFromEUR(service.price, currency)}</TableCell>
                    <TableCell>
                      <Chip
                        label={service.isActive ? 'Actif' : 'Inactif'}
                        color={service.isActive ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <IconButton 
                          size="small" 
                          title="Modifier"
                          onClick={() => handleOpenDialog(service)}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton 
                          size="small" 
                          title="Supprimer" 
                          color="error"
                          onClick={() => handleDeleteService(service.id)}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Dialogue de création/édition */}
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
      >
        <DialogTitle>{editingService ? 'Modifier le service' : 'Créer un nouveau service'}</DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Nom du service *"
              value={formData.name || ''}
              onChange={(e) => handleInputChange('name', e.target.value)}
              required
            />
            
            <TextField
              fullWidth
              label="Description *"
              value={formData.description || ''}
              onChange={(e) => handleInputChange('description', e.target.value)}
              multiline
              rows={3}
              required
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
                  price: values.price_is_ttc ? values.price_ttc : values.price_ht // pour compatibilité
                }));
              }}
              disabled={loading}
              error={error}
            />
            
            <FormControl fullWidth>
              <InputLabel>Catégorie</InputLabel>
              <Select
                value={formData.category || 'réparation'}
                label="Catégorie"
                onChange={(e) => handleInputChange('category', e.target.value)}
              >
                {serviceCategories.map((category) => (
                  <MenuItem key={category.value} value={category.value}>
                    {category.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <Autocomplete
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
                  placeholder="Créer une sous-catégorie ou sélectionner"
                />
              )}
            />
            
            <FormControl fullWidth>
              <InputLabel>Appareils compatibles</InputLabel>
              <Select
                multiple
                value={formData.applicableDevices || []}
                label="Appareils compatibles"
                onChange={(e) => handleInputChange('applicableDevices', e.target.value)}
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
                />
              }
              label="Service actif"
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
            disabled={loading || !formData.name || !formData.description}
          >
            {loading 
              ? (editingService ? 'Modification...' : 'Création...') 
              : (editingService ? 'Modifier' : 'Créer')
            }
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Services;

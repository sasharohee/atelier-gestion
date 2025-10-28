import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  Alert,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  FormControlLabel,
  Switch,
  Chip,
  OutlinedInput,
  ListItemText,
  Checkbox,
} from '@mui/material';
import {
  Add as AddIcon,
  Save as SaveIcon,
} from '@mui/icons-material';
import { useAppStore } from '../store';
import { useWorkshopSettings } from '../contexts/WorkshopSettingsContext';
import PriceInputFields from './PriceInputFields';

interface QuickCreateItemDialogProps {
  open: boolean;
  onClose: () => void;
  type: 'product' | 'service' | 'part';
  onSave: (itemData: any) => void;
}

const QuickCreateItemDialog: React.FC<QuickCreateItemDialogProps> = ({
  open,
  onClose,
  type,
  onSave,
}) => {
  // États pour les formulaires complets selon le type
  const [productFormData, setProductFormData] = useState({
    name: '',
    description: '',
    category: 'smartphone',
    price: 0,
    price_ht: 0,
    price_ttc: 0,
    price_is_ttc: false,
    stockQuantity: 0,
    minStockLevel: 1,
    isActive: true,
  });

  const [serviceFormData, setServiceFormData] = useState({
    name: '',
    description: '',
    duration: 0,
    price: 0,
    price_ht: 0,
    price_ttc: 0,
    price_is_ttc: true, // Services par défaut en TTC
    category: 'réparation',
    applicableDevices: [] as string[],
    isActive: true,
  });

  const [partFormData, setPartFormData] = useState({
    name: '',
    description: '',
    partNumber: '',
    brand: '',
    compatibleDevices: [] as string[],
    stockQuantity: 0,
    minStockLevel: 1,
    price: 0,
    price_ht: 0,
    price_ttc: 0,
    price_is_ttc: false, // Parts par défaut en HT
    supplier: '',
    isActive: true,
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';

  // Fonction pour obtenir les données du formulaire actuel
  const getCurrentFormData = () => {
    switch (type) {
      case 'product':
        return productFormData;
      case 'service':
        return serviceFormData;
      case 'part':
        return partFormData;
      default:
        return productFormData;
    }
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'product':
        return 'Produit';
      case 'service':
        return 'Service';
      case 'part':
        return 'Pièce détachée';
      default:
        return 'Article';
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'product':
        return '#1976d2';
      case 'service':
        return '#9c27b0';
      case 'part':
        return '#2e7d32';
      default:
        return '#666';
    }
  };

  // Catégories complètes pour les produits
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

  // Catégories pour les services
  const serviceCategories = [
    { value: 'réparation', label: 'Réparation' },
    { value: 'maintenance', label: 'Maintenance' },
    { value: 'diagnostic', label: 'Diagnostic' },
    { value: 'installation', label: 'Installation' },
    { value: 'autre', label: 'Autre' },
  ];

  // Types d'appareils pour services et pièces
  const deviceTypes = [
    { value: 'smartphone', label: 'Smartphone' },
    { value: 'tablet', label: 'Tablette' },
    { value: 'laptop', label: 'Ordinateur portable' },
    { value: 'desktop', label: 'Ordinateur fixe' },
    { value: 'other', label: 'Autre' },
  ];

  const handleSave = async () => {
    let currentFormData;
    
    // Récupérer les données du formulaire selon le type
    switch (type) {
      case 'product':
        currentFormData = productFormData;
        break;
      case 'service':
        currentFormData = serviceFormData;
        break;
      case 'part':
        currentFormData = partFormData;
        break;
    }

    if (!currentFormData.name.trim()) {
      setError('Le nom est obligatoire');
      return;
    }
    if (currentFormData.price <= 0) {
      setError('Le prix doit être supérieur à 0');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await onSave(currentFormData);
      
      // Réinitialiser les formulaires
      setProductFormData({
        name: '',
        description: '',
        category: 'smartphone',
        price: 0,
        price_ht: 0,
        price_ttc: 0,
        price_is_ttc: false,
        stockQuantity: 0,
        minStockLevel: 1,
        isActive: true,
      });
      setServiceFormData({
        name: '',
        description: '',
        duration: 0,
        price: 0,
        price_ht: 0,
        price_ttc: 0,
        price_is_ttc: true,
        category: 'réparation',
        applicableDevices: [],
        isActive: true,
      });
      setPartFormData({
        name: '',
        description: '',
        partNumber: '',
        brand: '',
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
      onClose();
    } catch (err) {
      setError('Erreur lors de la création de l\'article');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      // Réinitialiser tous les formulaires
      setProductFormData({
        name: '',
        description: '',
        category: 'smartphone',
        price: 0,
        stockQuantity: 0,
        minStockLevel: 1,
        isActive: true,
      });
      setServiceFormData({
        name: '',
        description: '',
        duration: 0,
        price: 0,
        category: 'réparation',
        applicableDevices: [],
        isActive: true,
      });
      setPartFormData({
        name: '',
        description: '',
        partNumber: '',
        brand: '',
        compatibleDevices: [],
        stockQuantity: 0,
        minStockLevel: 1,
        price: 0,
        supplier: '',
        isActive: true,
      });
      setError(null);
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ 
        bgcolor: getTypeColor(type), 
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        gap: 1
      }}>
        <AddIcon />
        Créer un nouveau {getTypeLabel(type).toLowerCase()}
      </DialogTitle>
      
      <DialogContent sx={{ mt: 2 }}>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {/* Formulaire pour les PRODUITS */}
        {type === 'product' && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nom du produit"
                value={productFormData.name}
                onChange={(e) => setProductFormData(prev => ({ ...prev, name: e.target.value }))}
                required
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={2}
                value={productFormData.description}
                onChange={(e) => setProductFormData(prev => ({ ...prev, description: e.target.value }))}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Catégorie</InputLabel>
                <Select
                  value={productFormData.category}
                  onChange={(e) => setProductFormData(prev => ({ ...prev, category: e.target.value }))}
                  label="Catégorie"
                  disabled={loading}
                >
                  {productCategories.map((category) => (
                    <MenuItem key={category.value} value={category.value}>
                      {category.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <PriceInputFields
                priceHT={productFormData.price_ht || 0}
                priceTTC={productFormData.price_ttc || 0}
                priceIsTTC={productFormData.price_is_ttc}
                currency={currency}
                onChange={(values) => {
                  setProductFormData(prev => ({
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
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Quantité en stock"
                type="number"
                value={productFormData.stockQuantity}
                onChange={(e) => setProductFormData(prev => ({ ...prev, stockQuantity: parseInt(e.target.value) || 0 }))}
                disabled={loading}
                inputProps={{ min: 0 }}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Stock minimum"
                type="number"
                value={productFormData.minStockLevel}
                onChange={(e) => setProductFormData(prev => ({ ...prev, minStockLevel: parseInt(e.target.value) || 1 }))}
                disabled={loading}
                inputProps={{ min: 1 }}
              />
            </Grid>

            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={productFormData.isActive}
                    onChange={(e) => setProductFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    disabled={loading}
                  />
                }
                label="Produit actif"
              />
            </Grid>
          </Grid>
        )}

        {/* Formulaire pour les SERVICES */}
        {type === 'service' && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nom du service"
                value={serviceFormData.name}
                onChange={(e) => setServiceFormData(prev => ({ ...prev, name: e.target.value }))}
                required
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={2}
                value={serviceFormData.description}
                onChange={(e) => setServiceFormData(prev => ({ ...prev, description: e.target.value }))}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Catégorie</InputLabel>
                <Select
                  value={serviceFormData.category}
                  onChange={(e) => setServiceFormData(prev => ({ ...prev, category: e.target.value }))}
                  label="Catégorie"
                  disabled={loading}
                >
                  {serviceCategories.map((category) => (
                    <MenuItem key={category.value} value={category.value}>
                      {category.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <PriceInputFields
                priceHT={serviceFormData.price_ht || 0}
                priceTTC={serviceFormData.price_ttc || 0}
                priceIsTTC={serviceFormData.price_is_ttc}
                currency={currency}
                onChange={(values) => {
                  setServiceFormData(prev => ({
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
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Durée (heures)"
                type="number"
                value={serviceFormData.duration}
                onChange={(e) => setServiceFormData(prev => ({ ...prev, duration: parseFloat(e.target.value) || 0 }))}
                disabled={loading}
                inputProps={{ min: 0, step: 0.5 }}
              />
            </Grid>

            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Appareils compatibles</InputLabel>
                <Select
                  multiple
                  value={serviceFormData.applicableDevices}
                  onChange={(e) => setServiceFormData(prev => ({ ...prev, applicableDevices: e.target.value as string[] }))}
                  input={<OutlinedInput label="Appareils compatibles" />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {selected.map((value) => (
                        <Chip key={value} label={deviceTypes.find(dt => dt.value === value)?.label || value} />
                      ))}
                    </Box>
                  )}
                  disabled={loading}
                >
                  {deviceTypes.map((device) => (
                    <MenuItem key={device.value} value={device.value}>
                      <Checkbox checked={serviceFormData.applicableDevices.indexOf(device.value) > -1} />
                      <ListItemText primary={device.label} />
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={serviceFormData.isActive}
                    onChange={(e) => setServiceFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    disabled={loading}
                  />
                }
                label="Service actif"
              />
            </Grid>
          </Grid>
        )}

        {/* Formulaire pour les PIÈCES DÉTACHÉES */}
        {type === 'part' && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nom de la pièce"
                value={partFormData.name}
                onChange={(e) => setPartFormData(prev => ({ ...prev, name: e.target.value }))}
                required
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={2}
                value={partFormData.description}
                onChange={(e) => setPartFormData(prev => ({ ...prev, description: e.target.value }))}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Numéro de pièce"
                value={partFormData.partNumber}
                onChange={(e) => setPartFormData(prev => ({ ...prev, partNumber: e.target.value }))}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Marque"
                value={partFormData.brand}
                onChange={(e) => setPartFormData(prev => ({ ...prev, brand: e.target.value }))}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12}>
              <PriceInputFields
                priceHT={partFormData.price_ht || 0}
                priceTTC={partFormData.price_ttc || 0}
                priceIsTTC={partFormData.price_is_ttc}
                currency={currency}
                onChange={(values) => {
                  setPartFormData(prev => ({
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
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Fournisseur"
                value={partFormData.supplier}
                onChange={(e) => setPartFormData(prev => ({ ...prev, supplier: e.target.value }))}
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Quantité en stock"
                type="number"
                value={partFormData.stockQuantity}
                onChange={(e) => setPartFormData(prev => ({ ...prev, stockQuantity: parseInt(e.target.value) || 0 }))}
                disabled={loading}
                inputProps={{ min: 0 }}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Stock minimum"
                type="number"
                value={partFormData.minStockLevel}
                onChange={(e) => setPartFormData(prev => ({ ...prev, minStockLevel: parseInt(e.target.value) || 1 }))}
                disabled={loading}
                inputProps={{ min: 1 }}
              />
            </Grid>

            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Appareils compatibles</InputLabel>
                <Select
                  multiple
                  value={partFormData.compatibleDevices}
                  onChange={(e) => setPartFormData(prev => ({ ...prev, compatibleDevices: e.target.value as string[] }))}
                  input={<OutlinedInput label="Appareils compatibles" />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {selected.map((value) => (
                        <Chip key={value} label={deviceTypes.find(dt => dt.value === value)?.label || value} />
                      ))}
                    </Box>
                  )}
                  disabled={loading}
                >
                  {deviceTypes.map((device) => (
                    <MenuItem key={device.value} value={device.value}>
                      <Checkbox checked={partFormData.compatibleDevices.indexOf(device.value) > -1} />
                      <ListItemText primary={device.label} />
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={partFormData.isActive}
                    onChange={(e) => setPartFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    disabled={loading}
                  />
                }
                label="Pièce active"
              />
            </Grid>
          </Grid>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 2 }}>
        <Button 
          onClick={handleClose}
          disabled={loading}
          variant="outlined"
        >
          Annuler
        </Button>
        <Button 
          onClick={handleSave}
          disabled={loading || !getCurrentFormData().name.trim() || getCurrentFormData().price <= 0}
          variant="contained"
          startIcon={<SaveIcon />}
          sx={{
            bgcolor: getTypeColor(type),
            '&:hover': {
              bgcolor: getTypeColor(type),
              opacity: 0.8,
            },
          }}
        >
          {loading ? 'Création...' : 'Créer'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default QuickCreateItemDialog;

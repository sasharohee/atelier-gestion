import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Checkbox,
  FormGroup,
  Stepper,
  Step,
  StepLabel,
  Divider,
  Alert,
  IconButton,
  Card,
  CardContent,
  Chip,
  Slider,
  FormLabel,
  RadioGroup,
  Radio,
  Autocomplete,
} from '@mui/material';
import {
  Save as SaveIcon,
  Cancel as CancelIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { Buyback, DeviceType, DeviceCondition, PaymentMethod, BuybackReason, IDType, BuybackPricing } from '../../types';
import { buybackService, deviceModelService } from '../../services/supabaseService';
import { buybackPricingService } from '../../services/buybackPricingService';
import BuybackPriceBreakdown from '../../components/BuybackPriceBreakdown';
import { toast } from 'react-hot-toast';

interface BuybackFormProps {
  buyback?: Buyback;
  onSave: (buyback: Buyback) => void;
  onCancel: () => void;
}

const BuybackForm: React.FC<BuybackFormProps> = ({ buyback, onSave, onCancel }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [deviceModels, setDeviceModels] = useState<any[]>([]);
  const [priceBreakdown, setPriceBreakdown] = useState<BuybackPricing | null>(null);
  const [calculatingPrice, setCalculatingPrice] = useState(false);
  const [formData, setFormData] = useState<Partial<Buyback>>({
    // Informations client
    clientFirstName: '',
    clientLastName: '',
    clientEmail: '',
    clientPhone: '',
    clientAddress: '',
    clientAddressComplement: '',
    clientPostalCode: '',
    clientCity: '',
    clientIdType: 'cni',
    clientIdNumber: '',
    
    // Informations appareil
    deviceType: 'smartphone',
    deviceBrand: '',
    deviceModel: '',
    deviceImei: '',
    deviceSerialNumber: '',
    deviceColor: '',
    deviceStorageCapacity: '',
    
    // État technique
    physicalCondition: 'good',
    functionalCondition: {
      powersOn: true,
      touchWorks: true,
      soundWorks: true,
      camerasWork: true,
      buttonsWork: true,
    },
    batteryHealth: 80,
    screenCondition: 'perfect',
    buttonCondition: 'perfect',
    
    // Blocages
    icloudLocked: false,
    googleLocked: false,
    carrierLocked: false,
    otherLocks: '',
    
    // Accessoires
    accessories: {
      charger: false,
      cable: false,
      headphones: false,
      originalBox: false,
      screenProtector: false,
      case: false,
      manual: false,
    },
    
    // Informations commerciales
    suggestedPrice: 0,
    offeredPrice: 0,
    finalPrice: 0,
    paymentMethod: 'cash',
    buybackReason: 'resale',
    
    // Garantie
    hasWarranty: false,
    warrantyExpiresAt: undefined,
    
    // Photos et documents
    photos: [],
    documents: [],
    
    // Statut et notes
    status: 'pending',
    internalNotes: '',
    clientNotes: '',
    
    // Conditions acceptées
    termsAccepted: false,
    termsAcceptedAt: undefined,
  });

  const steps = [
    'Informations Client',
    'Informations Appareil',
    'État Technique',
    'Accessoires',
    'Évaluation',
    'Compléments'
  ];

  useEffect(() => {
    if (buyback) {
      setFormData(buyback);
    }
  }, [buyback]);

  useEffect(() => {
    loadDeviceModels();
  }, []);

  const loadDeviceModels = async () => {
    try {
      const result = await deviceModelService.getAll();
      if (result.success) {
        setDeviceModels(result.data || []);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des modèles:', error);
    }
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleNestedChange = (parent: string, field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [parent]: {
        ...(prev as any)[parent],
        [field]: value
      }
    }));
  };


  // Style commun pour les TextField
  const textFieldStyle = {
    '& .MuiOutlinedInput-root': {
      borderRadius: 2,
      '&:hover .MuiOutlinedInput-notchedOutline': {
        borderColor: '#4caf50',
      },
      '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
        borderColor: '#4caf50',
        borderWidth: 2,
      },
    },
  };

  // Style commun pour les Select
  const selectStyle = {
    '& .MuiOutlinedInput-root': {
      borderRadius: 2,
      '&:hover .MuiOutlinedInput-notchedOutline': {
        borderColor: '#4caf50',
      },
      '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
        borderColor: '#4caf50',
        borderWidth: 2,
      },
    },
  };

  const handleNext = () => {
    setActiveStep(prev => prev + 1);
  };

  const handleBack = () => {
    setActiveStep(prev => prev - 1);
  };

  const validateStep = (step: number): boolean => {
    switch (step) {
      case 0: // Informations Client
        return !!(formData.clientFirstName && formData.clientLastName && formData.clientEmail && formData.clientPhone);
      case 1: // Informations Appareil
        return !!(formData.deviceBrand && formData.deviceModel && formData.deviceType);
      case 2: // État Technique
        return !!formData.physicalCondition;
      case 3: // Accessoires - toujours valide
        return true;
      case 4: // Évaluation
        return !!(formData.offeredPrice && formData.paymentMethod && formData.buybackReason);
      case 5: // Compléments
        return formData.termsAccepted === true;
      default:
        return true;
    }
  };

  const calculateSuggestedPrice = async () => {
    if (!formData.deviceBrand || !formData.deviceModel || !formData.deviceType || !formData.physicalCondition) {
      return;
    }

    setCalculatingPrice(true);
    
    try {
      const pricingResult = await buybackPricingService.calculateEstimatedPrice({
        deviceBrand: formData.deviceBrand,
        deviceModel: formData.deviceModel,
        deviceType: formData.deviceType,
        storageCapacity: formData.deviceStorageCapacity,
        physicalCondition: formData.physicalCondition,
        batteryHealth: formData.batteryHealth,
        screenCondition: formData.screenCondition,
        buttonCondition: formData.buttonCondition,
        functionalCondition: formData.functionalCondition || {
          powersOn: true,
          touchWorks: true,
          soundWorks: true,
          camerasWork: true,
          buttonsWork: true,
        },
        accessories: formData.accessories || {
          charger: false,
          cable: false,
          headphones: false,
          originalBox: false,
          screenProtector: false,
          case: false,
          manual: false,
        },
        hasWarranty: formData.hasWarranty,
        warrantyExpiresAt: formData.warrantyExpiresAt,
        icloudLocked: formData.icloudLocked,
        googleLocked: formData.googleLocked,
        carrierLocked: formData.carrierLocked,
      });

      if (pricingResult.success && pricingResult.data) {
        setPriceBreakdown(pricingResult.data);
        setFormData(prev => ({
          ...prev,
          suggestedPrice: pricingResult.data!.estimatedPrice,
          offeredPrice: prev.offeredPrice || pricingResult.data!.estimatedPrice
        }));
      } else {
        console.warn('⚠️ Erreur lors du calcul du prix:', pricingResult.error);
        // Fallback sur l'ancien système
        calculateDefaultPrice();
      }
    } catch (error) {
      console.error('❌ Erreur lors du calcul du prix:', error);
      calculateDefaultPrice();
    } finally {
      setCalculatingPrice(false);
    }
  };

  const calculateDefaultPrice = () => {
    // Logique simplifiée pour calculer le prix suggéré (fallback)
    let basePrice = 0;
    
    // Prix de base selon le type d'appareil
    switch (formData.deviceType) {
      case 'smartphone':
        basePrice = 200;
        break;
      case 'tablet':
        basePrice = 150;
        break;
      case 'laptop':
        basePrice = 400;
        break;
      case 'desktop':
        basePrice = 300;
        break;
      default:
        basePrice = 100;
    }
    
    // Ajustement selon l'état physique
    const conditionMultiplier = {
      'excellent': 1.0,
      'good': 0.8,
      'fair': 0.6,
      'poor': 0.4,
      'broken': 0.2
    };
    
    const multiplier = conditionMultiplier[formData.physicalCondition || 'good'];
    const suggestedPrice = Math.round(basePrice * multiplier);
    
    setFormData(prev => ({
      ...prev,
      suggestedPrice,
      offeredPrice: prev.offeredPrice || suggestedPrice
    }));
  };

  useEffect(() => {
    if (formData.deviceType && formData.physicalCondition && formData.deviceBrand && formData.deviceModel) {
      calculateSuggestedPrice();
    }
  }, [
    formData.deviceType, 
    formData.physicalCondition, 
    formData.deviceBrand, 
    formData.deviceModel,
    formData.deviceStorageCapacity,
    formData.batteryHealth,
    formData.screenCondition,
    formData.buttonCondition,
    formData.functionalCondition,
    formData.accessories,
    formData.hasWarranty,
    formData.warrantyExpiresAt,
    formData.icloudLocked,
    formData.googleLocked,
    formData.carrierLocked
  ]);

  const handleSave = async () => {
    if (!validateStep(5)) {
      toast.error('Veuillez accepter les conditions générales');
      return;
    }

    setLoading(true);
    try {
      const buybackData = {
        ...formData,
        termsAcceptedAt: new Date(),
        userId: '', // Sera rempli par le service
      } as Omit<Buyback, 'id' | 'createdAt' | 'updatedAt' | 'userId'>;

      const result = buyback ? 
        await buybackService.update(buyback.id, buybackData) :
        await buybackService.create(buybackData);

      if (result.success) {
        toast.success(buyback ? 'Rachat mis à jour avec succès' : 'Rachat créé avec succès');
        onSave(result.data);
      } else {
        toast.error(result.error?.message || 'Erreur lors de la sauvegarde');
      }
    } catch (error) {
      console.error('Erreur lors de la sauvegarde:', error);
      toast.error('Erreur lors de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  const renderStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prénom *"
                value={formData.clientFirstName || ''}
                onChange={(e) => handleInputChange('clientFirstName', e.target.value)}
                required
                sx={textFieldStyle}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Nom *"
                value={formData.clientLastName || ''}
                onChange={(e) => handleInputChange('clientLastName', e.target.value)}
                required
                sx={textFieldStyle}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Email *"
                type="email"
                value={formData.clientEmail || ''}
                onChange={(e) => handleInputChange('clientEmail', e.target.value)}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Téléphone *"
                value={formData.clientPhone || ''}
                onChange={(e) => handleInputChange('clientPhone', e.target.value)}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Adresse"
                value={formData.clientAddress || ''}
                onChange={(e) => handleInputChange('clientAddress', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Complément d'adresse"
                value={formData.clientAddressComplement || ''}
                onChange={(e) => handleInputChange('clientAddressComplement', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={3}>
              <TextField
                fullWidth
                label="Code postal"
                value={formData.clientPostalCode || ''}
                onChange={(e) => handleInputChange('clientPostalCode', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={3}>
              <TextField
                fullWidth
                label="Ville"
                value={formData.clientCity || ''}
                onChange={(e) => handleInputChange('clientCity', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Type de pièce d'identité</InputLabel>
                <Select
                  value={formData.clientIdType || 'cni'}
                  onChange={(e) => handleInputChange('clientIdType', e.target.value)}
                >
                  <MenuItem value="cni">CNI</MenuItem>
                  <MenuItem value="passeport">Passeport</MenuItem>
                  <MenuItem value="permis">Permis de conduire</MenuItem>
                  <MenuItem value="autre">Autre</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Numéro de pièce d'identité"
                value={formData.clientIdNumber || ''}
                onChange={(e) => handleInputChange('clientIdNumber', e.target.value)}
              />
            </Grid>
          </Grid>
        );

      case 1:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Type d'appareil *</InputLabel>
                <Select
                  value={formData.deviceType || 'smartphone'}
                  onChange={(e) => handleInputChange('deviceType', e.target.value)}
                  required
                >
                  <MenuItem value="smartphone">Smartphone</MenuItem>
                  <MenuItem value="tablet">Tablette</MenuItem>
                  <MenuItem value="laptop">Ordinateur portable</MenuItem>
                  <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                  <MenuItem value="other">Autre</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Autocomplete
                freeSolo
                options={[...new Set(deviceModels.map(model => model.brandName || model.brand))]}
                value={formData.deviceBrand || ''}
                onInputChange={(event, newValue) => handleInputChange('deviceBrand', newValue)}
                renderInput={(params) => (
                  <TextField {...params} label="Marque *" required />
                )}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <Autocomplete
                freeSolo
                options={deviceModels
                  .filter(model => (model.brandName || model.brand) === formData.deviceBrand)
                  .map(model => model.model)
                }
                value={formData.deviceModel || ''}
                onInputChange={(event, newValue) => handleInputChange('deviceModel', newValue)}
                renderInput={(params) => (
                  <TextField {...params} label="Modèle *" required />
                )}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="IMEI (15 chiffres)"
                value={formData.deviceImei || ''}
                onChange={(e) => handleInputChange('deviceImei', e.target.value)}
                inputProps={{ maxLength: 15 }}
                helperText={formData.deviceImei && formData.deviceImei.length !== 15 ? 'L\'IMEI doit contenir 15 chiffres' : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Numéro de série"
                value={formData.deviceSerialNumber || ''}
                onChange={(e) => handleInputChange('deviceSerialNumber', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Couleur"
                value={formData.deviceColor || ''}
                onChange={(e) => handleInputChange('deviceColor', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Capacité de stockage"
                value={formData.deviceStorageCapacity || ''}
                onChange={(e) => handleInputChange('deviceStorageCapacity', e.target.value)}
                placeholder="ex: 64GB, 128GB, 256GB"
              />
            </Grid>
          </Grid>
        );

      case 2:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>État physique général *</InputLabel>
                <Select
                  value={formData.physicalCondition || 'good'}
                  onChange={(e) => handleInputChange('physicalCondition', e.target.value)}
                  required
                >
                  <MenuItem value="excellent">Excellent</MenuItem>
                  <MenuItem value="good">Bon</MenuItem>
                  <MenuItem value="fair">Correct</MenuItem>
                  <MenuItem value="poor">Mauvais</MenuItem>
                  <MenuItem value="broken">Cassé</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>État de l'écran</InputLabel>
                <Select
                  value={formData.screenCondition || 'perfect'}
                  onChange={(e) => handleInputChange('screenCondition', e.target.value)}
                >
                  <MenuItem value="perfect">Parfait</MenuItem>
                  <MenuItem value="minor_scratches">Petites rayures</MenuItem>
                  <MenuItem value="major_scratches">Grosses rayures</MenuItem>
                  <MenuItem value="cracked">Fêlé</MenuItem>
                  <MenuItem value="broken">Cassé</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>État des boutons</InputLabel>
                <Select
                  value={formData.buttonCondition || 'perfect'}
                  onChange={(e) => handleInputChange('buttonCondition', e.target.value)}
                >
                  <MenuItem value="perfect">Parfait</MenuItem>
                  <MenuItem value="sticky">Collant</MenuItem>
                  <MenuItem value="broken">Cassé</MenuItem>
                  <MenuItem value="missing">Manquant</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Box>
                <Typography gutterBottom>
                  Santé de la batterie: {formData.batteryHealth || 80}%
                </Typography>
                <Slider
                  value={formData.batteryHealth || 80}
                  onChange={(e, value) => handleInputChange('batteryHealth', value)}
                  min={0}
                  max={100}
                  step={5}
                  marks={[
                    { value: 0, label: '0%' },
                    { value: 50, label: '50%' },
                    { value: 100, label: '100%' }
                  ]}
                />
              </Box>
            </Grid>
            
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                État fonctionnel
              </Typography>
              <FormGroup>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.functionalCondition?.powersOn || false}
                      onChange={(e) => handleNestedChange('functionalCondition', 'powersOn', e.target.checked)}
                    />
                  }
                  label="S'allume et démarre"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.functionalCondition?.touchWorks || false}
                      onChange={(e) => handleNestedChange('functionalCondition', 'touchWorks', e.target.checked)}
                    />
                  }
                  label="Écran tactile fonctionne"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.functionalCondition?.soundWorks || false}
                      onChange={(e) => handleNestedChange('functionalCondition', 'soundWorks', e.target.checked)}
                    />
                  }
                  label="Son fonctionne"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.functionalCondition?.camerasWork || false}
                      onChange={(e) => handleNestedChange('functionalCondition', 'camerasWork', e.target.checked)}
                    />
                  }
                  label="Caméras fonctionnent"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.functionalCondition?.buttonsWork || false}
                      onChange={(e) => handleNestedChange('functionalCondition', 'buttonsWork', e.target.checked)}
                    />
                  }
                  label="Boutons fonctionnent"
                />
              </FormGroup>
            </Grid>

            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Blocages
              </Typography>
              <FormGroup row>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.icloudLocked || false}
                      onChange={(e) => handleInputChange('icloudLocked', e.target.checked)}
                    />
                  }
                  label="iCloud"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.googleLocked || false}
                      onChange={(e) => handleInputChange('googleLocked', e.target.checked)}
                    />
                  }
                  label="Google"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.carrierLocked || false}
                      onChange={(e) => handleInputChange('carrierLocked', e.target.checked)}
                    />
                  }
                  label="Opérateur"
                />
              </FormGroup>
              <TextField
                fullWidth
                label="Autres blocages"
                value={formData.otherLocks || ''}
                onChange={(e) => handleInputChange('otherLocks', e.target.value)}
                multiline
                rows={2}
                sx={{ mt: 2 }}
              />
            </Grid>
          </Grid>
        );

      case 3:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Accessoires inclus avec l'appareil
              </Typography>
              <FormGroup>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.accessories?.charger || false}
                      onChange={(e) => handleNestedChange('accessories', 'charger', e.target.checked)}
                    />
                  }
                  label="Chargeur"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.accessories?.cable || false}
                      onChange={(e) => handleNestedChange('accessories', 'cable', e.target.checked)}
                    />
                  }
                  label="Câble"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.accessories?.headphones || false}
                      onChange={(e) => handleNestedChange('accessories', 'headphones', e.target.checked)}
                    />
                  }
                  label="Écouteurs"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.accessories?.originalBox || false}
                      onChange={(e) => handleNestedChange('accessories', 'originalBox', e.target.checked)}
                    />
                  }
                  label="Boîte d'origine"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.accessories?.screenProtector || false}
                      onChange={(e) => handleNestedChange('accessories', 'screenProtector', e.target.checked)}
                    />
                  }
                  label="Protection écran"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.accessories?.case || false}
                      onChange={(e) => handleNestedChange('accessories', 'case', e.target.checked)}
                    />
                  }
                  label="Coque"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.accessories?.manual || false}
                      onChange={(e) => handleNestedChange('accessories', 'manual', e.target.checked)}
                    />
                  }
                  label="Manuel d'utilisation"
                />
              </FormGroup>
            </Grid>
          </Grid>
        );

      case 4:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Alert severity="warning" sx={{ mb: 3 }}>
                <Typography variant="body2">
                  <strong>Version bêta :</strong> La partie évaluation est actuellement en bêta. 
                  Les prix calculés automatiquement ne sont pas corrects et doivent être ajustés manuellement.
                </Typography>
              </Alert>
            </Grid>
            
            {/* Affichage du détail du calcul si disponible */}
            {priceBreakdown && (
              <Grid item xs={12}>
                <BuybackPriceBreakdown 
                  pricing={priceBreakdown} 
                  showDetails={true}
                  compact={false}
                />
              </Grid>
            )}
            
            {/* Champs de prix */}
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prix suggéré"
                type="number"
                value={formData.suggestedPrice || 0}
                InputProps={{ 
                  readOnly: true,
                  endAdornment: calculatingPrice ? <CircularProgress size={20} /> : null
                }}
                helperText={calculatingPrice ? "Calcul en cours..." : "Calculé automatiquement selon le modèle et l'état"}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prix proposé *"
                type="number"
                value={formData.offeredPrice || 0}
                onChange={(e) => handleInputChange('offeredPrice', parseFloat(e.target.value) || 0)}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prix final"
                type="number"
                value={formData.finalPrice || 0}
                onChange={(e) => handleInputChange('finalPrice', parseFloat(e.target.value) || 0)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Mode de paiement *</InputLabel>
                <Select
                  value={formData.paymentMethod || 'cash'}
                  onChange={(e) => handleInputChange('paymentMethod', e.target.value)}
                  required
                >
                  <MenuItem value="cash">Espèces</MenuItem>
                  <MenuItem value="transfer">Virement</MenuItem>
                  <MenuItem value="check">Chèque</MenuItem>
                  <MenuItem value="credit">Avoir</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Raison du rachat *</InputLabel>
                <Select
                  value={formData.buybackReason || 'resale'}
                  onChange={(e) => handleInputChange('buybackReason', e.target.value)}
                  required
                >
                  <MenuItem value="resale">Revente</MenuItem>
                  <MenuItem value="parts">Pièces détachées</MenuItem>
                  <MenuItem value="collection">Collection</MenuItem>
                  <MenuItem value="other">Autre</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={formData.hasWarranty || false}
                    onChange={(e) => handleInputChange('hasWarranty', e.target.checked)}
                  />
                }
                label="Garantie restante"
              />
            </Grid>
            {formData.hasWarranty && (
              <Grid item xs={12} sm={6}>
                <DatePicker
                  label="Date d'expiration de la garantie"
                  value={formData.warrantyExpiresAt ? new Date(formData.warrantyExpiresAt) : null}
                  onChange={(date) => handleInputChange('warrantyExpiresAt', date)}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                    }
                  }}
                />
              </Grid>
            )}
          </Grid>
        );

      case 5:
        return (
          <Grid container spacing={3}>
            
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Notes internes"
                multiline
                rows={4}
                value={formData.internalNotes || ''}
                onChange={(e) => handleInputChange('internalNotes', e.target.value)}
                helperText="Notes privées pour l'équipe (non visibles par le client)"
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Notes du client"
                multiline
                rows={3}
                value={formData.clientNotes || ''}
                onChange={(e) => handleInputChange('clientNotes', e.target.value)}
                helperText="Notes du client sur l'appareil"
              />
            </Grid>

            <Grid item xs={12}>
              <Alert severity="info" sx={{ mb: 2 }}>
                <Typography variant="body2">
                  <strong>Conditions générales de rachat :</strong>
                </Typography>
                <ul style={{ marginTop: 8, paddingLeft: 20 }}>
                  <li>Le vendeur certifie être propriétaire légitime de l'appareil</li>
                  <li>L'appareil est vendu en l'état, sans garantie</li>
                  <li>En cas de blocage découvert après le rachat, le vendeur s'engage à le résoudre</li>
                  <li>Le paiement sera effectué selon le mode choisi</li>
                </ul>
              </Alert>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={formData.termsAccepted || false}
                    onChange={(e) => handleInputChange('termsAccepted', e.target.checked)}
                    required
                  />
                }
                label="J'accepte les conditions générales de rachat"
              />
            </Grid>
          </Grid>
        );

      default:
        return null;
    }
  };

  return (
    <Box sx={{ 
      minHeight: '100vh', 
      background: 'linear-gradient(135deg, #f5f5f5 0%, #e0e0e0 100%)',
      p: 3 
    }}>
      {/* Header avec titre et progression */}
      <Box sx={{ 
        textAlign: 'center', 
        mb: 4,
        color: '#333'
      }}>
        <Typography variant="h4" gutterBottom sx={{ 
          fontWeight: 'bold',
          textShadow: '0 2px 4px rgba(0,0,0,0.3)'
        }}>
          {buyback ? 'Modifier le Rachat' : 'Nouveau Rachat d\'Appareil'}
        </Typography>
        <Typography variant="body1" sx={{ 
          opacity: 0.9,
          mb: 3
        }}>
          Remplissez les informations pour créer un nouveau rachat
        </Typography>
        
        {/* Indicateur de progression personnalisé */}
        <Box sx={{ 
          display: 'flex', 
          justifyContent: 'center', 
          alignItems: 'center',
          mb: 4,
          gap: 2,
          flexWrap: 'wrap'
        }}>
          {steps.map((step, index) => (
            <Box key={step} sx={{ display: 'flex', alignItems: 'center' }}>
              <Box
                sx={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  backgroundColor: index <= activeStep ? '#4caf50' : '#ccc',
                  color: index <= activeStep ? 'white' : '#666',
                  fontWeight: 'bold',
                  fontSize: '14px',
                  boxShadow: index <= activeStep ? '0 4px 12px rgba(76,175,80,0.4)' : 'none',
                  transition: 'all 0.3s ease'
                }}
              >
                {index < activeStep ? '✓' : index + 1}
              </Box>
              <Typography 
                variant="body2" 
                sx={{ 
                  ml: 1, 
                  color: '#333',
                  fontWeight: index === activeStep ? 'bold' : 'normal',
                  display: { xs: 'none', sm: 'block' }
                }}
              >
                {step}
              </Typography>
              {index < steps.length - 1 && (
                <Box
                  sx={{
                    width: 60,
                    height: 2,
                    backgroundColor: index < activeStep ? '#4caf50' : '#ccc',
                    mx: 2,
                    display: { xs: 'none', sm: 'block' }
                  }}
                />
              )}
            </Box>
          ))}
        </Box>
      </Box>

      {/* Contenu du formulaire */}
      <Paper 
        elevation={8} 
        sx={{ 
          maxWidth: 1000,
          mx: 'auto',
          p: 4, 
          mb: 4, 
          borderRadius: 3,
          background: 'rgba(255,255,255,0.95)',
          backdropFilter: 'blur(10px)',
          border: '1px solid rgba(255,255,255,0.2)'
        }}
      >
        <Box sx={{ mb: 3 }}>
          <Typography variant="h5" sx={{ 
            color: '#333',
            fontWeight: 'bold',
            mb: 1,
            display: 'flex',
            alignItems: 'center',
            gap: 1
          }}>
            <Box sx={{ 
              width: 4, 
              height: 24, 
              backgroundColor: '#4caf50', 
              borderRadius: 2 
            }} />
            {steps[activeStep]}
          </Typography>
          <Typography variant="body2" sx={{ color: '#666' }}>
            Étape {activeStep + 1} sur {steps.length}
          </Typography>
        </Box>

        <Box sx={{ mb: 4 }}>
          {renderStepContent(activeStep)}
        </Box>
      </Paper>

      {/* Boutons de navigation */}
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'space-between',
        alignItems: 'center',
        maxWidth: 1000,
        mx: 'auto',
        px: 2
      }}>
        <Button
          disabled={activeStep === 0}
          onClick={handleBack}
          variant="outlined"
          size="large"
          sx={{
            borderRadius: 2,
            px: 4,
            py: 1.5,
            borderColor: '#666',
            color: '#666',
            '&:hover': {
              borderColor: '#333',
              backgroundColor: 'rgba(0,0,0,0.05)'
            },
            '&:disabled': {
              borderColor: '#ccc',
              color: '#ccc'
            }
          }}
        >
          ← Précédent
        </Button>

        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            onClick={onCancel}
            variant="outlined"
            size="large"
            sx={{
              borderRadius: 2,
              px: 4,
              py: 1.5,
              borderColor: '#666',
              color: '#666',
              '&:hover': {
                borderColor: '#333',
                backgroundColor: 'rgba(0,0,0,0.05)'
              }
            }}
          >
            Annuler
          </Button>

          <Button
            variant="contained"
            onClick={activeStep === steps.length - 1 ? handleSave : handleNext}
            disabled={loading || !validateStep(activeStep)}
            size="large"
            sx={{
              borderRadius: 2,
              px: 4,
              py: 1.5,
              background: 'linear-gradient(45deg, #4caf50 30%, #45a049 90%)',
              boxShadow: '0 4px 12px rgba(76,175,80,0.4)',
              '&:hover': {
                background: 'linear-gradient(45deg, #45a049 30%, #4caf50 90%)',
                boxShadow: '0 6px 16px rgba(76,175,80,0.5)'
              },
              '&:disabled': {
                background: 'rgba(255,255,255,0.3)',
                boxShadow: 'none'
              }
            }}
          >
            {loading ? 'Sauvegarde...' : (
              activeStep === steps.length - 1 ? 
                (buyback ? '✓ Modifier le Rachat' : '✓ Créer le Rachat') : 
                'Suivant →'
            )}
          </Button>
        </Box>
      </Box>
    </Box>
  );
};

export default BuybackForm;

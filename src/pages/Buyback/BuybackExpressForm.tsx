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
  Stepper,
  Step,
  StepLabel,
  Divider,
  Alert,
  Autocomplete,
} from '@mui/material';
import {
  Save as SaveIcon,
  Cancel as CancelIcon,
  ArrowBack as ArrowBackIcon,
  ArrowForward as ArrowForwardIcon,
  FlashOn as FlashOnIcon,
} from '@mui/icons-material';
import { Buyback, DeviceType, PaymentMethod, BuybackReason } from '../../types';
import { buybackService, deviceModelService } from '../../services/supabaseService';
import { toast } from 'react-hot-toast';

interface BuybackExpressFormProps {
  buyback?: Buyback;
  onSave: (buyback: Buyback) => void;
  onCancel: () => void;
}

const BuybackExpressForm: React.FC<BuybackExpressFormProps> = ({ buyback, onSave, onCancel }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [deviceModels, setDeviceModels] = useState<any[]>([]);
  const [formData, setFormData] = useState<Partial<Buyback>>({
    // Informations client (obligatoires)
    clientFirstName: '',
    clientLastName: '',
    clientEmail: '',
    clientPhone: '',
    
    // Informations appareil (obligatoires)
    deviceType: 'smartphone',
    deviceBrand: '',
    deviceModel: '',
    deviceImei: '',
    
    // Valeurs par défaut pré-remplies
    clientAddress: '',
    clientAddressComplement: '',
    clientPostalCode: '',
    clientCity: '',
    clientIdType: 'cni',
    clientIdNumber: '',
    deviceSerialNumber: '',
    deviceColor: '',
    deviceStorageCapacity: '',
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
    icloudLocked: false,
    googleLocked: false,
    carrierLocked: false,
    otherLocks: '',
    accessories: {
      charger: false,
      cable: false,
      headphones: false,
      originalBox: false,
      screenProtector: false,
      case: false,
      manual: false,
    },
    suggestedPrice: 0,
    offeredPrice: 0,
    finalPrice: 0,
    paymentMethod: 'cash',
    buybackReason: 'resale',
    hasWarranty: false,
    warrantyExpiresAt: undefined,
    photos: [],
    documents: [],
    status: 'pending',
    internalNotes: '',
    clientNotes: '',
    termsAccepted: true,
    termsAcceptedAt: new Date(),
  });

  const steps = [
    'Informations Essentielles',
    'Prix'
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

  const handleNext = () => {
    if (validateStep(activeStep)) {
      setActiveStep(prev => prev + 1);
    } else {
      toast.error('Veuillez remplir tous les champs obligatoires');
    }
  };

  const handleBack = () => {
    setActiveStep(prev => prev - 1);
  };

  const validateStep = (step: number): boolean => {
    switch (step) {
      case 0: // Informations Essentielles
        return !!(
          formData.clientFirstName &&
          formData.clientLastName &&
          formData.clientPhone &&
          formData.deviceBrand &&
          formData.deviceModel
        );
      case 1: // Prix
        return !!formData.offeredPrice && formData.offeredPrice > 0;
      default:
        return true;
    }
  };

  const handleSave = async () => {
    if (!validateStep(activeStep)) {
      toast.error('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setLoading(true);
    try {
      const buybackData = {
        ...formData,
        termsAccepted: true,
        termsAcceptedAt: new Date(),
        userId: '', // Sera rempli par le service
      } as Omit<Buyback, 'id' | 'createdAt' | 'updatedAt' | 'userId'>;

      const result = buyback ? 
        await buybackService.update(buyback.id, buybackData) :
        await buybackService.create(buybackData);

      if (result.success) {
        toast.success(buyback ? 'Rachat modifié avec succès' : 'Rachat expresse créé avec succès');
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
          <Grid container spacing={3} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <Alert severity="info" sx={{ mb: 2 }}>
                <Typography variant="body2">
                  <strong>Rachat expresse :</strong> Remplissez uniquement les informations essentielles. 
                  Les autres champs seront remplis avec des valeurs par défaut.
                </Typography>
              </Alert>
            </Grid>
            
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom sx={{ color: '#10b981' }}>
                Informations Client
              </Typography>
              <Divider sx={{ mb: 2 }} />
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prénom *"
                value={formData.clientFirstName || ''}
                onChange={(e) => handleInputChange('clientFirstName', e.target.value)}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Nom *"
                value={formData.clientLastName || ''}
                onChange={(e) => handleInputChange('clientLastName', e.target.value)}
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
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={formData.clientEmail || ''}
                onChange={(e) => handleInputChange('clientEmail', e.target.value)}
              />
            </Grid>
            
            <Grid item xs={12} sx={{ mt: 2 }}>
              <Typography variant="h6" gutterBottom sx={{ color: '#10b981' }}>
                Informations Appareil
              </Typography>
              <Divider sx={{ mb: 2 }} />
            </Grid>
            
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
                label="IMEI"
                value={formData.deviceImei || ''}
                onChange={(e) => handleInputChange('deviceImei', e.target.value)}
                inputProps={{ maxLength: 15 }}
                helperText={formData.deviceImei && formData.deviceImei.length !== 15 ? 'L\'IMEI doit contenir 15 chiffres' : ''}
              />
            </Grid>
          </Grid>
        );

      case 1:
        return (
          <Grid container spacing={3} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prix proposé *"
                type="number"
                value={formData.offeredPrice || 0}
                onChange={(e) => handleInputChange('offeredPrice', parseFloat(e.target.value) || 0)}
                required
                inputProps={{ min: 0, step: 0.01 }}
                InputProps={{
                  startAdornment: <Typography sx={{ mr: 1 }}>€</Typography>
                }}
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
                <InputLabel>Raison du rachat</InputLabel>
                <Select
                  value={formData.buybackReason || 'resale'}
                  onChange={(e) => handleInputChange('buybackReason', e.target.value)}
                >
                  <MenuItem value="resale">Revente</MenuItem>
                  <MenuItem value="parts">Pièces détachées</MenuItem>
                  <MenuItem value="collection">Collection</MenuItem>
                  <MenuItem value="other">Autre</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Notes internes (optionnel)"
                multiline
                rows={3}
                value={formData.internalNotes || ''}
                onChange={(e) => handleInputChange('internalNotes', e.target.value)}
                placeholder="Notes internes pour ce rachat..."
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
      background: 'linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%)',
      p: 3 
    }}>
      {/* Header avec titre */}
      <Box sx={{ 
        textAlign: 'center', 
        mb: 4,
        color: '#333'
      }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1, mb: 2 }}>
          <FlashOnIcon sx={{ color: '#10b981', fontSize: 32 }} />
          <Typography variant="h4" sx={{ 
            fontWeight: 'bold',
            textShadow: '0 2px 4px rgba(0,0,0,0.1)'
          }}>
            {buyback ? 'Modifier le Rachat' : 'Rachat Express'}
          </Typography>
        </Box>
        <Typography variant="body1" sx={{ 
          opacity: 0.9,
          mb: 3
        }}>
          Mode rapide - Remplissez uniquement les informations essentielles
        </Typography>
        
        <Stepper activeStep={activeStep} sx={{ mb: 3 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
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
          border: '1px solid rgba(16, 185, 129, 0.2)'
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
              backgroundColor: '#10b981',
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
          onClick={onCancel}
          variant="outlined"
          size="large"
          startIcon={<CancelIcon />}
          disabled={loading}
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

        <Box sx={{ display: 'flex', gap: 2 }}>
          {activeStep > 0 && (
            <Button
              onClick={handleBack}
              variant="outlined"
              size="large"
              startIcon={<ArrowBackIcon />}
              disabled={loading}
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
              Précédent
            </Button>
          )}

          <Button
            variant="contained"
            onClick={activeStep === steps.length - 1 ? handleSave : handleNext}
            disabled={loading || !validateStep(activeStep)}
            size="large"
            endIcon={activeStep < steps.length - 1 ? <ArrowForwardIcon /> : <SaveIcon />}
            sx={{
              borderRadius: 2,
              px: 4,
              py: 1.5,
              background: 'linear-gradient(45deg, #10b981 30%, #059669 90%)',
              boxShadow: '0 4px 12px rgba(16, 185, 129, 0.4)',
              '&:hover': {
                background: 'linear-gradient(45deg, #059669 30%, #10b981 90%)',
                boxShadow: '0 6px 16px rgba(16, 185, 129, 0.5)'
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
                'Suivant'
            )}
          </Button>
        </Box>
      </Box>
    </Box>
  );
};

export default BuybackExpressForm;


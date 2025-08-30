import React, { useState, useEffect } from 'react';
import {
  Box,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Tabs,
  Tab,
  Typography,
  FormControlLabel,
  Checkbox,
  Radio,
  RadioGroup,
  IconButton,
  Alert,
  Chip,
} from '@mui/material';
import {
  Close as CloseIcon,
  Person as PersonIcon,
  Home as HomeIcon,
  Info as InfoIcon,
  Business as BusinessIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  LocationOn as LocationIcon,
} from '@mui/icons-material';

interface ClientFormData {
  // Détails Client
  category: string;
  title: string;
  firstName: string;
  lastName: string;
  companyName: string;
  vatNumber: string;
  sirenNumber: string;
  email: string;
  countryCode: string;
  mobile: string;
  
  // Détails Adresse
  address: string;
  addressComplement: string;
  region: string;
  postalCode: string;
  city: string;
  billingAddressSame: boolean;
  billingAddress: string;
  billingAddressComplement: string;
  billingRegion: string;
  billingPostalCode: string;
  billingCity: string;
  
  // Autres informations
  accountingCode: string;
  cniIdentifier: string;
  attachedFile?: File | null;
  internalNote: string;
  status: 'displayed' | 'hidden';
  smsNotification: boolean;
  emailNotification: boolean;
  smsMarketing: boolean;
  emailMarketing: boolean;
}

interface ClientFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (clientData: ClientFormData) => void;
  existingEmails?: string[];
  initialData?: ClientFormData;
  isEditing?: boolean;
}

const ClientForm: React.FC<ClientFormProps> = ({ open, onClose, onSubmit, existingEmails = [], initialData, isEditing = false }) => {
  const [activeTab, setActiveTab] = useState(0);
  const [formData, setFormData] = useState<ClientFormData>({
    category: '',
    title: '',
    firstName: '',
    lastName: '',
    companyName: '',
    vatNumber: '',
    sirenNumber: '',
    email: '',
    countryCode: '33',
    mobile: '',
    address: '',
    addressComplement: '',
    region: '',
    postalCode: '',
    city: '',
    billingAddressSame: true,
    billingAddress: '',
    billingAddressComplement: '',
    billingRegion: '',
    billingPostalCode: '',
    billingCity: '',
    accountingCode: '',
    cniIdentifier: '',
    attachedFile: null,
    internalNote: '',
    status: 'displayed',
    smsNotification: true,
    emailNotification: true,
    smsMarketing: true,
    emailMarketing: true,
  });

  const handleInputChange = (field: keyof ClientFormData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };



  const handleSubmit = () => {
    console.log('🔍 DEBUG - Données du formulaire avant soumission:', formData);
    console.log('🔍 DEBUG - Champs critiques:');
    console.log('  - companyName:', formData.companyName);
    console.log('  - vatNumber:', formData.vatNumber);
    console.log('  - sirenNumber:', formData.sirenNumber);
    console.log('  - postalCode:', formData.postalCode);
    console.log('  - accountingCode:', formData.accountingCode);
    console.log('  - cniIdentifier:', formData.cniIdentifier);
    
    onSubmit(formData);
    // Réinitialiser le formulaire après la soumission si ce n'est pas en mode édition
    if (!isEditing) {
      resetForm();
    }
  };

  const isEmailDuplicate = Boolean(formData.email && existingEmails.includes(formData.email.toLowerCase()));
  const isFormValid = formData.firstName && formData.lastName && formData.email && !isEmailDuplicate;

  // Initialiser les données du formulaire quand initialData change ou quand le formulaire s'ouvre
  useEffect(() => {
    if (initialData) {
      console.log('📝 CLIENTFORM - Initialisation avec les données:', initialData);
      setFormData(initialData);
    } else if (open && !isEditing) {
      console.log('📝 CLIENTFORM - Réinitialisation pour nouveau client');
      resetForm();
    }
  }, [initialData, open, isEditing]);

  const resetForm = () => {
    setFormData({
      category: '',
      title: '',
      firstName: '',
      lastName: '',
      companyName: '',
      vatNumber: '',
      sirenNumber: '',
      email: '',
      countryCode: '33',
      mobile: '',
      address: '',
      addressComplement: '',
      region: '',
      postalCode: '',
      city: '',
      billingAddressSame: true,
      billingAddress: '',
      billingAddressComplement: '',
      billingRegion: '',
      billingPostalCode: '',
      billingCity: '',
      accountingCode: '',
      cniIdentifier: '',
      internalNote: '',
      status: 'displayed',
      smsNotification: true,
      emailNotification: true,
      smsMarketing: true,
      emailMarketing: true,
    });
    setActiveTab(0);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="lg"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 2,
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
        }
      }}
    >
      {/* Header */}
      <DialogTitle
        sx={{
          background: 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)',
          color: 'white',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          py: 2,
          px: 3,
        }}
      >
        <Typography variant="h5" component="span" sx={{ fontWeight: 600 }}>
          {isEditing ? 'Modifier le Client' : 'Nouveau Client'}
        </Typography>
        <IconButton
          onClick={handleClose}
          sx={{ color: 'white' }}
        >
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', px: 3, pt: 2 }}>
        <Tabs 
          value={activeTab} 
          onChange={(e, newValue) => setActiveTab(newValue)}
          sx={{
            '& .MuiTab-root': {
              minHeight: 48,
              textTransform: 'none',
              fontWeight: 500,
            },
            '& .Mui-selected': {
              color: '#6b7280',
            },
            '& .MuiTabs-indicator': {
              backgroundColor: '#6b7280',
            },
          }}
        >
          <Tab 
            label="Détails Client" 
            icon={<PersonIcon />} 
            iconPosition="start"
          />
          <Tab 
            label="Détails Adresse" 
            icon={<HomeIcon />} 
            iconPosition="start"
          />
          <Tab 
            label="Autres informations" 
            icon={<InfoIcon />} 
            iconPosition="start"
          />
        </Tabs>
      </Box>

      <DialogContent sx={{ p: 3 }}>
        {/* Tab 1: Détails Client */}
        {activeTab === 0 && (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Alert severity="info" sx={{ mb: 3 }}>
                Remplissez les informations de base du client
              </Alert>
            </Grid>

            {/* Catégorie Client */}
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Catégorie Client</InputLabel>
                <Select
                  value={formData.category}
                  label="Catégorie Client"
                  onChange={(e) => handleInputChange('category', e.target.value)}
                >
                  <MenuItem value="particulier">Particulier</MenuItem>
                  <MenuItem value="professionnel">Professionnel</MenuItem>
                  <MenuItem value="entreprise">Entreprise</MenuItem>
                  <MenuItem value="association">Association</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            {/* Informations personnelles */}
            <Grid item xs={12} md={4}>
              <FormControl fullWidth>
                <InputLabel>Titre</InputLabel>
                <Select
                  value={formData.title}
                  label="Titre"
                  onChange={(e) => handleInputChange('title', e.target.value)}
                >
                  <MenuItem value="mr">M.</MenuItem>
                  <MenuItem value="mrs">Mme</MenuItem>
                  <MenuItem value="ms">Mlle</MenuItem>
                  <MenuItem value="dr">Dr</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Prénom"
                value={formData.firstName}
                onChange={(e) => handleInputChange('firstName', e.target.value)}
                placeholder="Saisir Prénom"
                required
              />
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Nom"
                value={formData.lastName}
                onChange={(e) => handleInputChange('lastName', e.target.value)}
                placeholder="Saisir Nom"
                required
              />
            </Grid>

            {/* Informations entreprise */}
            <Grid item xs={12}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: '#6b7280' }}>
                <BusinessIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
                Informations entreprise
              </Typography>
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Nom Société"
                value={formData.companyName}
                onChange={(e) => handleInputChange('companyName', e.target.value)}
                placeholder="Saisir nom société"
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="N° TVA"
                value={formData.vatNumber}
                onChange={(e) => handleInputChange('vatNumber', e.target.value)}
                placeholder="Veuillez Saisir N° TVA"
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="N° SIREN"
                value={formData.sirenNumber}
                onChange={(e) => handleInputChange('sirenNumber', e.target.value)}
                placeholder="Veuillez Saisir N° SIREN"
              />
            </Grid>

            {/* Informations de contact */}
            <Grid item xs={12}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: '#6b7280' }}>
                <EmailIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
                Informations de contact
              </Typography>
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={formData.email}
                onChange={(e) => handleInputChange('email', e.target.value)}
                placeholder="Saisir Email"
                required
                error={isEmailDuplicate}
                helperText={isEmailDuplicate ? 'Cet email existe déjà' : ''}
              />
            </Grid>

            <Grid item xs={12} md={2}>
              <TextField
                fullWidth
                label="Ind"
                value={formData.countryCode}
                onChange={(e) => handleInputChange('countryCode', e.target.value)}
                size="small"
              />
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Mobile (Sans Le 0)"
                value={formData.mobile}
                onChange={(e) => handleInputChange('mobile', e.target.value)}
                placeholder="Saisir N° (sans indicatif et sans le 0)"
                required
                error={!formData.mobile}
                helperText={!formData.mobile ? 'Numéro de téléphone requis' : ''}
              />
            </Grid>
          </Grid>
        )}

        {/* Tab 2: Détails Adresse */}
        {activeTab === 1 && (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Alert severity="info" sx={{ mb: 3 }}>
                <LocationIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
                Informations d'adresse du client
              </Alert>
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Adresse"
                value={formData.address}
                onChange={(e) => handleInputChange('address', e.target.value)}
                placeholder="Saisir Adresse"
                multiline
                rows={2}
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Complément Adresse"
                value={formData.addressComplement}
                onChange={(e) => handleInputChange('addressComplement', e.target.value)}
                placeholder="Complément Adresse"
              />
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Région"
                value={formData.region}
                onChange={(e) => handleInputChange('region', e.target.value)}
                placeholder="Saisir Région"
              />
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Code Postal"
                value={formData.postalCode}
                onChange={(e) => handleInputChange('postalCode', e.target.value)}
                placeholder="Saisir Code Postal"
              />
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Ville"
                value={formData.city}
                onChange={(e) => handleInputChange('city', e.target.value)}
                placeholder="Saisir une ville"
              />
            </Grid>

            <Grid item xs={12}>
                              <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.billingAddressSame}
                      onChange={(e) => handleInputChange('billingAddressSame', e.target.checked)}
                      sx={{ color: '#6b7280' }}
                    />
                  }
                  label="Adresse De Facturation Identique À L'adresse De Résidence"
                />
            </Grid>

            {!formData.billingAddressSame && (
              <>
                <Grid item xs={12}>
                  <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: '#6b7280' }}>
                    <BusinessIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
                    Détails Adresse de Facturation
                  </Typography>
                </Grid>

                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Adresse de facturation"
                    value={formData.billingAddress}
                    onChange={(e) => handleInputChange('billingAddress', e.target.value)}
                    placeholder="Saisir Adresse de facturation"
                    multiline
                    rows={2}
                  />
                </Grid>

                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Complément Adresse de facturation"
                    value={formData.billingAddressComplement}
                    onChange={(e) => handleInputChange('billingAddressComplement', e.target.value)}
                    placeholder="Complément Adresse de facturation"
                  />
                </Grid>

                <Grid item xs={12} md={4}>
                  <TextField
                    fullWidth
                    label="Région de facturation"
                    value={formData.billingRegion}
                    onChange={(e) => handleInputChange('billingRegion', e.target.value)}
                    placeholder="Saisir Région de facturation"
                  />
                </Grid>

                <Grid item xs={12} md={4}>
                  <TextField
                    fullWidth
                    label="Code Postal de facturation"
                    value={formData.billingPostalCode}
                    onChange={(e) => handleInputChange('billingPostalCode', e.target.value)}
                    placeholder="Saisir Code Postal de facturation"
                  />
                </Grid>

                <Grid item xs={12} md={4}>
                  <TextField
                    fullWidth
                    label="Ville de facturation"
                    value={formData.billingCity}
                    onChange={(e) => handleInputChange('billingCity', e.target.value)}
                    placeholder="Saisir Ville de facturation"
                  />
                </Grid>
              </>
            )}
          </Grid>
        )}

        {/* Tab 3: Autres informations */}
        {activeTab === 2 && (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Alert severity="info" sx={{ mb: 3 }}>
                <InfoIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
                Informations complémentaires et préférences
              </Alert>
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Code Comptable"
                value={formData.accountingCode}
                onChange={(e) => handleInputChange('accountingCode', e.target.value)}
                placeholder="Code Comptable"
              />
            </Grid>

            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Identifiant CNI"
                value={formData.cniIdentifier}
                onChange={(e) => handleInputChange('cniIdentifier', e.target.value)}
                placeholder="Veuillez saisir identifiant CNI"
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Note Interne"
                value={formData.internalNote}
                onChange={(e) => handleInputChange('internalNote', e.target.value)}
                placeholder="Saisir note interne client"
                multiline
                rows={4}
              />
            </Grid>

            <Grid item xs={12} md={4}>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
                Statut
              </Typography>
              <RadioGroup
                value={formData.status}
                onChange={(e) => handleInputChange('status', e.target.value)}
                row
              >
                <FormControlLabel
                  value="displayed"
                  control={<Radio sx={{ color: '#6b7280' }} />}
                  label="Affiché"
                />
                <FormControlLabel
                  value="hidden"
                  control={<Radio sx={{ color: '#6b7280' }} />}
                  label="Masqué"
                />
              </RadioGroup>
            </Grid>

            <Grid item xs={12} md={4}>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
                Préférence Notifications
              </Typography>
                              <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.smsNotification}
                      onChange={(e) => handleInputChange('smsNotification', e.target.checked)}
                      sx={{ color: '#6b7280' }}
                    />
                  }
                  label="SMS"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.emailNotification}
                      onChange={(e) => handleInputChange('emailNotification', e.target.checked)}
                      sx={{ color: '#6b7280' }}
                    />
                  }
                  label="Email"
                />
            </Grid>

            <Grid item xs={12} md={4}>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
                Préférence Marketing
              </Typography>
                              <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.smsMarketing}
                      onChange={(e) => handleInputChange('smsMarketing', e.target.checked)}
                      sx={{ color: '#6b7280' }}
                    />
                  }
                  label="SMS"
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.emailMarketing}
                      onChange={(e) => handleInputChange('emailMarketing', e.target.checked)}
                      sx={{ color: '#6b7280' }}
                    />
                  }
                  label="Email"
                />
            </Grid>
          </Grid>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 3, pt: 0 }}>

        
        <Button 
          onClick={handleClose}
          variant="outlined"
          sx={{ 
            color: '#666',
            borderColor: '#666',
            '&:hover': {
              borderColor: '#333',
              backgroundColor: '#f5f5f5'
            }
          }}
        >
          Fermer
        </Button>
        <Button 
          onClick={handleSubmit}
          variant="contained"
          disabled={!isFormValid}
          sx={{ 
            background: 'linear-gradient(135deg, #00bcd4 0%, #0097a7 100%)',
            '&:hover': {
              background: 'linear-gradient(135deg, #0097a7 0%, #00695c 100%)',
            },
            '&:disabled': {
              background: '#ccc',
            }
          }}
        >
          {isEditing ? 'Modifier' : 'Créer'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ClientForm;

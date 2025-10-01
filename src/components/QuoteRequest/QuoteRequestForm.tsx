import React, { useState, useRef } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  RadioGroup,
  Radio,
  Alert,
  CircularProgress,
  Chip,
  IconButton,
  Paper,
  Divider,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  CloudUpload as CloudUploadIcon,
  Delete as DeleteIcon,
  Send as SendIcon,
  CheckCircle as CheckCircleIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Person as PersonIcon,
  Description as DescriptionIcon,
  Build as BuildIcon,
  AttachFile as AttachFileIcon,
} from '@mui/icons-material';
import { toast } from 'react-hot-toast';
import { quoteRequestServiceReal } from '../../services/quoteRequestServiceReal';
// Types simplifiés pour éviter les erreurs de compilation
interface QuoteRequest {
  id: string;
  requestNumber: string;
  customUrl: string;
  technicianId: string;
  clientFirstName: string;
  clientLastName: string;
  clientEmail: string;
  clientPhone: string;
  description: string;
  deviceType?: string;
  deviceBrand?: string;
  deviceModel?: string;
  issueDescription: string;
  urgency: 'low' | 'medium' | 'high';
  attachments: QuoteRequestAttachment[];
  status: 'pending' | 'in_review' | 'quoted' | 'accepted' | 'rejected' | 'cancelled';
  priority: 'low' | 'medium' | 'high';
  source: 'website' | 'mobile' | 'api';
  createdAt: Date;
  updatedAt: Date;
}

interface QuoteRequestAttachment {
  id: string;
  quoteRequestId: string;
  fileName: string;
  originalName: string;
  fileSize: number;
  mimeType: string;
  filePath: string;
  uploadedAt: Date;
}

interface QuoteRequestFormProps {
  customUrl: string;
  technicianId: string;
  onSuccess?: (request: QuoteRequest) => void;
}

interface FormData {
  clientFirstName: string;
  clientLastName: string;
  clientEmail: string;
  clientPhone: string;
  description: string;
  deviceType: string;
  deviceBrand: string;
  deviceModel: string;
  issueDescription: string;
  urgency: 'low' | 'medium' | 'high';
}

const deviceTypes = [
  'Smartphone',
  'Tablette',
  'Ordinateur portable',
  'Ordinateur de bureau',
  'Console de jeu',
  'Autre',
];

const urgencyLevels = [
  { value: 'low', label: 'Faible', color: '#10b981' },
  { value: 'medium', label: 'Moyenne', color: '#f59e0b' },
  { value: 'high', label: 'Élevée', color: '#ef4444' },
];

const QuoteRequestForm: React.FC<QuoteRequestFormProps> = ({
  customUrl,
  technicianId,
  onSuccess,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  
  const [formData, setFormData] = useState<FormData>({
    clientFirstName: '',
    clientLastName: '',
    clientEmail: '',
    clientPhone: '',
    description: '',
    deviceType: '',
    deviceBrand: '',
    deviceModel: '',
    issueDescription: '',
    urgency: 'medium',
  });

  const [attachments, setAttachments] = useState<File[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.clientFirstName.trim()) {
      newErrors.clientFirstName = 'Le prénom est requis';
    }

    if (!formData.clientLastName.trim()) {
      newErrors.clientLastName = 'Le nom est requis';
    }

    if (!formData.clientEmail.trim()) {
      newErrors.clientEmail = 'L\'email est requis';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.clientEmail)) {
      newErrors.clientEmail = 'Format d\'email invalide';
    }

    if (!formData.clientPhone.trim()) {
      newErrors.clientPhone = 'Le téléphone est requis';
    } else if (!/^[0-9+\-\s()]+$/.test(formData.clientPhone)) {
      newErrors.clientPhone = 'Format de téléphone invalide';
    }

    if (!formData.description.trim()) {
      newErrors.description = 'La description est requise';
    }

    if (!formData.issueDescription.trim()) {
      newErrors.issueDescription = 'La description du problème est requise';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleInputChange = (field: keyof FormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Effacer l'erreur quand l'utilisateur commence à taper
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    const validFiles: File[] = [];
    const maxFileSize = 10 * 1024 * 1024; // 10MB
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];

    files.forEach(file => {
      if (file.size > maxFileSize) {
        toast.error(`Le fichier ${file.name} est trop volumineux (max 10MB)`);
        return;
      }

      if (!allowedTypes.includes(file.type)) {
        toast.error(`Le type de fichier ${file.type} n'est pas autorisé`);
        return;
      }

      validFiles.push(file);
    });

    if (validFiles.length > 0) {
      setAttachments(prev => [...prev, ...validFiles]);
      toast.success(`${validFiles.length} fichier(s) ajouté(s)`);
    }

    // Réinitialiser l'input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const removeAttachment = (index: number) => {
    setAttachments(prev => prev.filter((_, i) => i !== index));
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!validateForm()) {
      toast.error('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    setIsSubmitting(true);

    try {
      // Créer la demande avec le vrai service
      const requestData = {
        customUrl,
        technicianId,
        ...formData,
        ipAddress: '', // À récupérer côté serveur
        userAgent: navigator.userAgent,
      };

      const newRequest = await quoteRequestServiceReal.createQuoteRequest(requestData);

      if (!newRequest) {
        throw new Error('Erreur lors de la création de la demande');
      }

      setIsSuccess(true);
      toast.success('Votre demande de devis a été envoyée avec succès !');
      
      if (onSuccess) {
        onSuccess(newRequest);
      }

    } catch (error) {
      console.error('Erreur lors de l\'envoi:', error);
      toast.error('Une erreur est survenue lors de l\'envoi de votre demande');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isSuccess) {
    return (
      <Box sx={{ maxWidth: 600, mx: 'auto', p: 3 }}>
        <Card sx={{ textAlign: 'center', p: 4 }}>
          <CheckCircleIcon sx={{ fontSize: 80, color: 'success.main', mb: 2 }} />
          <Typography variant="h4" gutterBottom color="success.main">
            Demande envoyée !
          </Typography>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
            Votre demande de devis a été transmise avec succès
          </Typography>
          <Typography variant="body1" sx={{ mb: 3 }}>
            Nous vous contacterons dans les plus brefs délais pour vous fournir un devis détaillé.
            Vous recevrez une confirmation par email.
          </Typography>
          <Button
            variant="contained"
            onClick={() => {
              setIsSuccess(false);
              setFormData({
                clientFirstName: '',
                clientLastName: '',
                clientEmail: '',
                clientPhone: '',
                description: '',
                deviceType: '',
                deviceBrand: '',
                deviceModel: '',
                issueDescription: '',
                urgency: 'medium',
              });
              setAttachments([]);
            }}
            sx={{ mt: 2 }}
          >
            Faire une nouvelle demande
          </Button>
        </Card>
      </Box>
    );
  }

  return (
    <Box sx={{ maxWidth: 800, mx: 'auto', p: isMobile ? 2 : 3 }}>
      <Card sx={{ 
        boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
        borderRadius: 3,
        overflow: 'hidden',
      }}>
        {/* Header avec gradient */}
        <Box sx={{
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          color: 'white',
          p: 4,
          textAlign: 'center',
        }}>
          <BuildIcon sx={{ fontSize: 48, mb: 2 }} />
          <Typography variant="h4" gutterBottom sx={{ fontWeight: 700 }}>
            Demande de Devis
          </Typography>
          <Typography variant="h6" sx={{ opacity: 0.9 }}>
            Remplissez ce formulaire pour obtenir un devis personnalisé
          </Typography>
        </Box>

        <CardContent sx={{ p: 4 }}>
          <form onSubmit={handleSubmit}>
            {/* Informations personnelles */}
            <Box sx={{ mb: 4 }}>
              <Typography variant="h6" gutterBottom sx={{ 
                display: 'flex', 
                alignItems: 'center', 
                gap: 1,
                color: 'primary.main',
                fontWeight: 600,
              }}>
                <PersonIcon />
                Informations personnelles
              </Typography>
              <Divider sx={{ mb: 3 }} />
              
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Prénom *"
                    value={formData.clientFirstName}
                    onChange={(e) => handleInputChange('clientFirstName', e.target.value)}
                    error={!!errors.clientFirstName}
                    helperText={errors.clientFirstName}
                    variant="outlined"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Nom *"
                    value={formData.clientLastName}
                    onChange={(e) => handleInputChange('clientLastName', e.target.value)}
                    error={!!errors.clientLastName}
                    helperText={errors.clientLastName}
                    variant="outlined"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Email *"
                    type="email"
                    value={formData.clientEmail}
                    onChange={(e) => handleInputChange('clientEmail', e.target.value)}
                    error={!!errors.clientEmail}
                    helperText={errors.clientEmail}
                    variant="outlined"
                    InputProps={{
                      startAdornment: <EmailIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                    }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Téléphone *"
                    value={formData.clientPhone}
                    onChange={(e) => handleInputChange('clientPhone', e.target.value)}
                    error={!!errors.clientPhone}
                    helperText={errors.clientPhone}
                    variant="outlined"
                    InputProps={{
                      startAdornment: <PhoneIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                    }}
                  />
                </Grid>
              </Grid>
            </Box>

            {/* Détails de l'appareil */}
            <Box sx={{ mb: 4 }}>
              <Typography variant="h6" gutterBottom sx={{ 
                display: 'flex', 
                alignItems: 'center', 
                gap: 1,
                color: 'primary.main',
                fontWeight: 600,
              }}>
                <BuildIcon />
                Détails de l'appareil
              </Typography>
              <Divider sx={{ mb: 3 }} />
              
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth>
                    <InputLabel>Type d'appareil</InputLabel>
                    <Select
                      value={formData.deviceType}
                      onChange={(e) => handleInputChange('deviceType', e.target.value)}
                      label="Type d'appareil"
                    >
                      {deviceTypes.map((type) => (
                        <MenuItem key={type} value={type}>
                          {type}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Marque"
                    value={formData.deviceBrand}
                    onChange={(e) => handleInputChange('deviceBrand', e.target.value)}
                    variant="outlined"
                    placeholder="Ex: Apple, Samsung, HP..."
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Modèle"
                    value={formData.deviceModel}
                    onChange={(e) => handleInputChange('deviceModel', e.target.value)}
                    variant="outlined"
                    placeholder="Ex: iPhone 14, Galaxy S23, MacBook Pro..."
                  />
                </Grid>
              </Grid>
            </Box>

            {/* Description du problème */}
            <Box sx={{ mb: 4 }}>
              <Typography variant="h6" gutterBottom sx={{ 
                display: 'flex', 
                alignItems: 'center', 
                gap: 1,
                color: 'primary.main',
                fontWeight: 600,
              }}>
                <DescriptionIcon />
                Description du problème
              </Typography>
              <Divider sx={{ mb: 3 }} />
              
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Description générale *"
                    multiline
                    rows={3}
                    value={formData.description}
                    onChange={(e) => handleInputChange('description', e.target.value)}
                    error={!!errors.description}
                    helperText={errors.description}
                    variant="outlined"
                    placeholder="Décrivez brièvement votre demande..."
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Description détaillée du problème *"
                    multiline
                    rows={4}
                    value={formData.issueDescription}
                    onChange={(e) => handleInputChange('issueDescription', e.target.value)}
                    error={!!errors.issueDescription}
                    helperText={errors.issueDescription}
                    variant="outlined"
                    placeholder="Décrivez en détail le problème rencontré, les symptômes, quand cela a commencé..."
                  />
                </Grid>
              </Grid>
            </Box>

            {/* Niveau d'urgence */}
            <Box sx={{ mb: 4 }}>
              <Typography variant="h6" gutterBottom sx={{ 
                color: 'primary.main',
                fontWeight: 600,
              }}>
                Niveau d'urgence
              </Typography>
              <Divider sx={{ mb: 3 }} />
              
              <FormControl component="fieldset">
                <RadioGroup
                  value={formData.urgency}
                  onChange={(e) => handleInputChange('urgency', e.target.value as 'low' | 'medium' | 'high')}
                  row={!isMobile}
                >
                  {urgencyLevels.map((level) => (
                    <FormControlLabel
                      key={level.value}
                      value={level.value}
                      control={<Radio />}
                      label={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Chip
                            label={level.label}
                            size="small"
                            sx={{
                              backgroundColor: level.color,
                              color: 'white',
                              fontWeight: 600,
                            }}
                          />
                        </Box>
                      }
                    />
                  ))}
                </RadioGroup>
              </FormControl>
            </Box>

            {/* Pièces jointes */}
            <Box sx={{ mb: 4 }}>
              <Typography variant="h6" gutterBottom sx={{ 
                display: 'flex', 
                alignItems: 'center', 
                gap: 1,
                color: 'primary.main',
                fontWeight: 600,
              }}>
                <AttachFileIcon />
                Pièces jointes (optionnel)
              </Typography>
              <Divider sx={{ mb: 3 }} />
              
              <Box sx={{ mb: 2 }}>
                <input
                  ref={fileInputRef}
                  type="file"
                  multiple
                  accept="image/*,.pdf"
                  onChange={handleFileUpload}
                  style={{ display: 'none' }}
                />
                <Button
                  variant="outlined"
                  startIcon={<CloudUploadIcon />}
                  onClick={() => fileInputRef.current?.click()}
                  sx={{ mb: 2 }}
                >
                  Ajouter des fichiers
                </Button>
                <Typography variant="caption" display="block" color="text.secondary">
                  Formats acceptés: JPG, PNG, GIF, PDF (max 10MB par fichier)
                </Typography>
              </Box>

              {attachments.length > 0 && (
                <Box sx={{ mt: 2 }}>
                  {attachments.map((file, index) => (
                    <Paper
                      key={index}
                      sx={{
                        p: 2,
                        mb: 1,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        backgroundColor: 'grey.50',
                      }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <AttachFileIcon color="primary" />
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {file.name}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {formatFileSize(file.size)}
                          </Typography>
                        </Box>
                      </Box>
                      <IconButton
                        size="small"
                        onClick={() => removeAttachment(index)}
                        color="error"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Paper>
                  ))}
                </Box>
              )}
            </Box>

            {/* Bouton d'envoi */}
            <Box sx={{ textAlign: 'center', mt: 4 }}>
              <Button
                type="submit"
                variant="contained"
                size="large"
                disabled={isSubmitting}
                startIcon={isSubmitting ? <CircularProgress size={20} /> : <SendIcon />}
                sx={{
                  px: 6,
                  py: 1.5,
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  borderRadius: 2,
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
                  },
                }}
              >
                {isSubmitting ? 'Envoi en cours...' : 'Envoyer la demande'}
              </Button>
            </Box>
          </form>
        </CardContent>
      </Card>
    </Box>
  );
};

export default QuoteRequestForm;

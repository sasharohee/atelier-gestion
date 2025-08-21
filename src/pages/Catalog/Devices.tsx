import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
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
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { deviceTypeColors } from '../../theme';

const Devices: React.FC = () => {
  const { devices, addDevice } = useAppStore();
  const [openDialog, setOpenDialog] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    brand: '',
    model: '',
    type: 'smartphone',
    serialNumber: '',
    specifications: {
      processor: '',
      ram: '',
      storage: '',
      screen: '',
    },
  });

  const deviceTypes = [
    { value: 'smartphone', label: 'Smartphone' },
    { value: 'tablet', label: 'Tablette' },
    { value: 'laptop', label: 'Ordinateur portable' },
    { value: 'desktop', label: 'Ordinateur fixe' },
    { value: 'other', label: 'Autre' },
  ];

  const handleOpenDialog = () => {
    setOpenDialog(true);
    setError(null);
    setFormData({
      brand: '',
      model: '',
      type: 'smartphone',
      serialNumber: '',
      specifications: {
        processor: '',
        ram: '',
        storage: '',
        screen: '',
      },
    });
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setError(null);
  };

  const handleInputChange = (field: string, value: string) => {
    if (field.startsWith('specifications.')) {
      const specField = field.split('.')[1];
      setFormData(prev => ({
        ...prev,
        specifications: {
          ...prev.specifications,
          [specField]: value,
        },
      }));
    } else {
      setFormData(prev => ({
        ...prev,
        [field]: value,
      }));
    }
  };

  const handleSubmit = async () => {
    if (!formData.brand || !formData.model) {
      setError('La marque et le modèle sont obligatoires');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const newDevice = {
        brand: formData.brand,
        model: formData.model,
        type: formData.type as 'smartphone' | 'tablet' | 'laptop' | 'desktop' | 'other',
        serialNumber: formData.serialNumber || undefined,
        specifications: formData.specifications,
      };

      await addDevice(newDevice as any);
      handleCloseDialog();
      // Le store se met à jour automatiquement
    } catch (err) {
      setError('Erreur lors de la création de l\'appareil');
      console.error('Erreur création appareil:', err);
    } finally {
      setLoading(false);
    }
  };

  const getDeviceTypeIcon = (type: string) => {
    const icons = {
      smartphone: <PhoneIcon />,
      tablet: <TabletIcon />,
      laptop: <LaptopIcon />,
      desktop: <ComputerIcon />,
      other: <ComputerIcon />,
    };
    return icons[type as keyof typeof icons] || <ComputerIcon />;
  };

  const getDeviceTypeColor = (type: string) => {
    return deviceTypeColors[type as keyof typeof deviceTypeColors] || '#757575';
  };

  const getDeviceTypeLabel = (type: string) => {
    const labels = {
      smartphone: 'Smartphone',
      tablet: 'Tablette',
      laptop: 'Ordinateur portable',
      desktop: 'Ordinateur fixe',
      other: 'Autre',
    };
    return labels[type as keyof typeof labels] || type;
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Appareils
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des modèles d'appareils
        </Typography>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Nouvel appareil
        </Button>
      </Box>

      {/* Liste des appareils */}
      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Appareil</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Numéro de série</TableCell>
                  <TableCell>Spécifications</TableCell>
                  <TableCell>Date de création</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {devices.map((device) => (
                  <TableRow key={device.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Box
                          sx={{
                            backgroundColor: getDeviceTypeColor(device.type),
                            borderRadius: 1,
                            p: 1,
                            mr: 2,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                        >
                          {getDeviceTypeIcon(device.type)}
                        </Box>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {device.brand} {device.model}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getDeviceTypeLabel(device.type)}
                        size="small"
                        sx={{ backgroundColor: getDeviceTypeColor(device.type), color: 'white' }}
                      />
                    </TableCell>
                    <TableCell>{device.serialNumber || '-'}</TableCell>
                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {device.specifications ? Object.entries(device.specifications).map(([key, value]) => `${key}: ${value}`).join(', ') : '-'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      {new Date(device.createdAt).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <IconButton size="small" title="Modifier">
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton size="small" title="Supprimer" color="error">
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

      {/* Dialogue de création */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>Créer un nouvel appareil</DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Marque *"
                value={formData.brand}
                onChange={(e) => handleInputChange('brand', e.target.value)}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Modèle *"
                value={formData.model}
                onChange={(e) => handleInputChange('model', e.target.value)}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Type d'appareil</InputLabel>
                <Select
                  value={formData.type}
                  label="Type d'appareil"
                  onChange={(e) => handleInputChange('type', e.target.value)}
                >
                  {deviceTypes.map((type) => (
                    <MenuItem key={type.value} value={type.value}>
                      {type.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Numéro de série"
                value={formData.serialNumber}
                onChange={(e) => handleInputChange('serialNumber', e.target.value)}
              />
            </Grid>
            
            <Grid item xs={12}>
              <Typography variant="h6" sx={{ mt: 2, mb: 1 }}>
                Spécifications
              </Typography>
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Processeur"
                value={formData.specifications.processor}
                onChange={(e) => handleInputChange('specifications.processor', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="RAM"
                value={formData.specifications.ram}
                onChange={(e) => handleInputChange('specifications.ram', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Stockage"
                value={formData.specifications.storage}
                onChange={(e) => handleInputChange('specifications.storage', e.target.value)}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Écran"
                value={formData.specifications.screen}
                onChange={(e) => handleInputChange('specifications.screen', e.target.value)}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog} disabled={loading}>
            Annuler
          </Button>
          <Button 
            onClick={handleSubmit} 
            variant="contained" 
            disabled={loading || !formData.brand || !formData.model}
          >
            {loading ? 'Création...' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Devices;

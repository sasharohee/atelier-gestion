import React, { useState, useEffect } from 'react';
import {
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
  Typography,
  Box,
  Alert,
  Chip,
  Autocomplete,
  FormControlLabel,
  Switch,
} from '@mui/material';
import {
  Build as BuildIcon,
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
  DevicesOther as OtherIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { addDays } from 'date-fns';
import { Device, Client } from '../../types';

interface RepairFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (repairData: RepairFormData) => void;
  clients: Client[];
  devices: Device[];
  selectedClientId?: string;
}

export interface RepairFormData {
  clientId: string;
  deviceId?: string;
  description: string;
  issue?: string;
  estimatedDuration: number;
  estimatedStartDate: Date;
  estimatedEndDate: Date;
  isUrgent: boolean;
  estimatedPrice: number;
}

const RepairForm: React.FC<RepairFormProps> = ({
  open,
  onClose,
  onSubmit,
  clients,
  devices,
  selectedClientId,
}) => {
  const [formData, setFormData] = useState<RepairFormData>({
    clientId: selectedClientId || '',
    deviceId: '',
    description: '',
    issue: '',
    estimatedDuration: 60,
    estimatedStartDate: new Date(),
    estimatedEndDate: addDays(new Date(), 1),
    isUrgent: false,
    estimatedPrice: 0,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  // Réinitialiser le formulaire quand il s'ouvre
  useEffect(() => {
    if (open) {
      setFormData({
        clientId: selectedClientId || '',
        deviceId: '',
        description: '',
        issue: '',
        estimatedDuration: 60,
        estimatedStartDate: new Date(),
        estimatedEndDate: addDays(new Date(), 1),
        isUrgent: false,
        estimatedPrice: 0,
      });
      setErrors({});
    }
  }, [open, selectedClientId]);

  // Calculer la date de fin estimée basée sur la durée
  useEffect(() => {
    const endDate = addDays(formData.estimatedStartDate, Math.ceil(formData.estimatedDuration / 1440)); // 1440 minutes = 1 jour
    setFormData(prev => ({ ...prev, estimatedEndDate: endDate }));
  }, [formData.estimatedStartDate, formData.estimatedDuration]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.clientId) {
      newErrors.clientId = 'Le client est requis';
    }

    if (!formData.description.trim()) {
      newErrors.description = 'La description est requise';
    }

    if (formData.estimatedDuration <= 0) {
      newErrors.estimatedDuration = 'La durée estimée doit être positive';
    }

    if (formData.estimatedPrice < 0) {
      newErrors.estimatedPrice = 'Le prix estimé ne peut pas être négatif';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = () => {
    if (validateForm()) {
      onSubmit(formData);
      onClose();
    }
  };

  const getDeviceIcon = (type: string) => {
    switch (type) {
      case 'smartphone':
        return <PhoneIcon sx={{ fontSize: '16px' }} />;
      case 'laptop':
        return <LaptopIcon sx={{ fontSize: '16px' }} />;
      case 'tablet':
        return <TabletIcon sx={{ fontSize: '16px' }} />;
      case 'desktop':
        return <ComputerIcon sx={{ fontSize: '16px' }} />;
      default:
        return <OtherIcon sx={{ fontSize: '16px' }} />;
    }
  };

  const getDeviceLabel = (device: Device) => {
    return `${device.brand} ${device.model}`;
  };

  const getClientLabel = (client: Client) => {
    return `${client.firstName} ${client.lastName}`;
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <BuildIcon sx={{ color: '#1976d2' }} />
          <Typography variant="h6">Créer une réparation</Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Grid container spacing={3} sx={{ mt: 1 }}>
          {/* Client */}
          <Grid item xs={12} md={6}>
            <FormControl fullWidth error={!!errors.clientId}>
              <InputLabel>Client *</InputLabel>
              <Select
                value={formData.clientId}
                onChange={(e) => setFormData(prev => ({ ...prev, clientId: e.target.value }))}
                label="Client *"
              >
                {clients.map((client) => (
                  <MenuItem key={client.id} value={client.id}>
                    {getClientLabel(client)}
                  </MenuItem>
                ))}
              </Select>
              {errors.clientId && (
                <Typography variant="caption" color="error" sx={{ mt: 0.5 }}>
                  {errors.clientId}
                </Typography>
              )}
            </FormControl>
          </Grid>

          {/* Appareil */}
          <Grid item xs={12} md={6}>
            <Autocomplete
              options={devices}
              getOptionLabel={getDeviceLabel}
              value={devices.find(d => d.id === formData.deviceId) || null}
              onChange={(_, newValue) => setFormData(prev => ({ 
                ...prev, 
                deviceId: newValue?.id || '' 
              }))}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Appareil (optionnel)"
                  placeholder="Sélectionner un appareil"
                />
              )}
              renderOption={(props, option) => {
                const { key, ...otherProps } = props;
                return (
                  <Box component="li" key={key} {...otherProps}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {getDeviceIcon(option.type)}
                      <Box>
                        <Typography variant="body2">
                          {getDeviceLabel(option)}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {option.type}
                        </Typography>
                      </Box>
                    </Box>
                  </Box>
                );
              }}
            />
          </Grid>

          {/* Description */}
          <Grid item xs={12}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Description de la réparation *"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Décrivez le problème et la réparation à effectuer..."
              error={!!errors.description}
              helperText={errors.description}
            />
          </Grid>

          {/* Problème */}
          <Grid item xs={12}>
            <TextField
              fullWidth
              multiline
              rows={2}
              label="Problème identifié (optionnel)"
              value={formData.issue}
              onChange={(e) => setFormData(prev => ({ ...prev, issue: e.target.value }))}
              placeholder="Décrivez le problème technique identifié..."
            />
          </Grid>

          {/* Durée estimée */}
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              type="number"
              label="Durée estimée (minutes) *"
              value={formData.estimatedDuration}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                estimatedDuration: parseInt(e.target.value) || 0 
              }))}
              error={!!errors.estimatedDuration}
              helperText={errors.estimatedDuration}
              inputProps={{ min: 1 }}
            />
          </Grid>

          {/* Prix estimé */}
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              type="number"
              label="Prix estimé (€) *"
              value={formData.estimatedPrice}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                estimatedPrice: parseFloat(e.target.value) || 0 
              }))}
              error={!!errors.estimatedPrice}
              helperText={errors.estimatedPrice}
              inputProps={{ min: 0, step: 0.01 }}
            />
          </Grid>

          {/* Date de début estimée */}
          <Grid item xs={12} md={6}>
            <DatePicker
              label="Date de début estimée *"
              value={formData.estimatedStartDate}
              onChange={(newValue) => newValue && setFormData(prev => ({ 
                ...prev, 
                estimatedStartDate: newValue 
              }))}
              slotProps={{
                textField: {
                  fullWidth: true,
                }
              }}
            />
          </Grid>

          {/* Date de fin estimée */}
          <Grid item xs={12} md={6}>
            <DatePicker
              label="Date de fin estimée"
              value={formData.estimatedEndDate}
              onChange={(newValue) => newValue && setFormData(prev => ({ 
                ...prev, 
                estimatedEndDate: newValue 
              }))}
              slotProps={{
                textField: {
                  fullWidth: true,
                  helperText: 'Calculée automatiquement selon la durée',
                }
              }}
            />
          </Grid>

          {/* Urgence */}
          <Grid item xs={12}>
            <FormControlLabel
              control={
                <Switch
                  checked={formData.isUrgent}
                  onChange={(e) => setFormData(prev => ({ ...prev, isUrgent: e.target.checked }))}
                  color="warning"
                />
              }
              label={
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <WarningIcon sx={{ color: formData.isUrgent ? '#ff9800' : 'text.secondary' }} />
                  <Typography>Réparation urgente</Typography>
                  {formData.isUrgent && (
                    <Chip 
                      label="URGENT" 
                      size="small" 
                      color="warning" 
                      variant="filled"
                    />
                  )}
                </Box>
              }
            />
          </Grid>

          {/* Résumé */}
          <Grid item xs={12}>
            <Alert severity="info" icon={<ScheduleIcon />}>
              <Typography variant="body2">
                <strong>Résumé :</strong> Réparation estimée à {formData.estimatedDuration} minutes 
                ({Math.ceil(formData.estimatedDuration / 60)}h{formData.estimatedDuration % 60 > 0 ? ` ${formData.estimatedDuration % 60}min` : ''}) 
                pour un montant de {formData.estimatedPrice.toLocaleString('fr-FR')} €
              </Typography>
            </Alert>
          </Grid>
        </Grid>
      </DialogContent>
      
      <DialogActions sx={{ p: 3 }}>
        <Button onClick={onClose} variant="outlined">
          Annuler
        </Button>
        <Button 
          onClick={handleSubmit} 
          variant="contained"
          startIcon={<BuildIcon />}
          sx={{ 
            backgroundColor: '#1976d2',
            '&:hover': { backgroundColor: '#1565c0' }
          }}
        >
          Créer la réparation
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default RepairForm;

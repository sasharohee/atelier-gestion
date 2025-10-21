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
  Autocomplete,
  FormControlLabel,
  Checkbox,
  Grid,
  Box,
  Typography,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  Person as PersonIcon,
  DeviceHub as DeviceIcon,
  Description as DescriptionIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { addDays } from 'date-fns';
import { Client, Device, User, RepairStatus, Repair } from '../../types';
import { savService } from '../../services/savService';

interface NewRepairDialogProps {
  open: boolean;
  onClose: () => void;
  clients: Client[];
  devices: Device[];
  users: User[];
  repairStatuses: RepairStatus[];
  onSubmit: (repair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
}

interface FormData {
  clientId: string;
  deviceId: string;
  description: string;
  issue: string;
  isUrgent: boolean;
  dueDate: Date;
  estimatedDuration: number;
  totalPrice: number;
  assignedTechnicianId: string;
}

const initialFormData: FormData = {
  clientId: '',
  deviceId: '',
  description: '',
  issue: '',
  isUrgent: false,
  dueDate: addDays(new Date(), 3),
  estimatedDuration: 60,
  totalPrice: 0,
  assignedTechnicianId: '',
};

export const NewRepairDialog: React.FC<NewRepairDialogProps> = ({
  open,
  onClose,
  clients,
  devices,
  users,
  repairStatuses,
  onSubmit,
}) => {
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [errors, setErrors] = useState<Partial<Record<keyof FormData, string>>>({});
  const [loading, setLoading] = useState(false);
  const [filteredDevices, setFilteredDevices] = useState<Device[]>([]);

  // Filtrer les appareils selon le client sélectionné
  useEffect(() => {
    if (formData.clientId) {
      // Dans une vraie app, on filtrerait par client_id
      // Pour l'instant, on affiche tous les appareils
      setFilteredDevices(devices);
      // Réinitialiser l'appareil si le client change
      if (formData.deviceId && !devices.find(d => d.id === formData.deviceId)) {
        setFormData(prev => ({ ...prev, deviceId: '' }));
      }
    } else {
      setFilteredDevices([]);
      setFormData(prev => ({ ...prev, deviceId: '' }));
    }
  }, [formData.clientId, devices]);

  // Réinitialiser le formulaire à l'ouverture
  useEffect(() => {
    if (open) {
      setFormData(initialFormData);
      setErrors({});
    }
  }, [open]);

  // Validation
  const validate = (): boolean => {
    const newErrors: Partial<Record<keyof FormData, string>> = {};

    if (!formData.clientId) {
      newErrors.clientId = 'Le client est obligatoire';
    }

    if (!formData.deviceId) {
      newErrors.deviceId = 'L\'appareil est obligatoire';
    }

    if (!formData.description || formData.description.length < 10) {
      newErrors.description = 'La description doit contenir au moins 10 caractères';
    }

    if (!formData.issue || formData.issue.length < 10) {
      newErrors.issue = 'Le problème doit contenir au moins 10 caractères';
    }

    if (formData.dueDate <= new Date()) {
      newErrors.dueDate = 'La date limite doit être dans le futur';
    }

    if (formData.estimatedDuration <= 0) {
      newErrors.estimatedDuration = 'La durée doit être supérieure à 0';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Soumission du formulaire
  const handleSubmit = async () => {
    if (!validate()) {
      return;
    }

    setLoading(true);

    try {
      // Trouver le statut "nouvelle" ou "new"
      const newStatus = repairStatuses.find(
        s => s.name.toLowerCase().includes('new') || s.name.toLowerCase().includes('nouvelle')
      ) || repairStatuses[0];

      // Générer le numéro de réparation
      const repairNumber = savService.generateRepairNumber();

      // Créer l'objet réparation
      const newRepair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'> = {
        repairNumber,
        clientId: formData.clientId,
        deviceId: formData.deviceId,
        status: newStatus.id,
        description: formData.description,
        issue: formData.issue,
        isUrgent: formData.isUrgent,
        dueDate: formData.dueDate,
        estimatedDuration: formData.estimatedDuration,
        totalPrice: formData.totalPrice,
        assignedTechnicianId: formData.assignedTechnicianId || undefined,
        services: [],
        parts: [],
        isPaid: false,
        notes: '',
      };

      await onSubmit(newRepair);
      onClose();
    } catch (error) {
      console.error('Erreur lors de la création de la prise en charge:', error);
    } finally {
      setLoading(false);
    }
  };

  // Gestionnaires de changement
  const handleChange = (field: keyof FormData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Effacer l'erreur du champ modifié
    if (errors[field]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <DescriptionIcon sx={{ color: '#16a34a' }} />
          <Typography variant="h6">Nouvelle prise en charge SAV</Typography>
        </Box>
      </DialogTitle>

      <DialogContent>
        <Box sx={{ pt: 2 }}>
          {/* Alertes si pas de clients ou appareils */}
          {clients.length === 0 && (
            <Alert severity="warning" sx={{ mb: 2 }}>
              Aucun client trouvé. Veuillez d'abord créer un client dans Transaction → Clients
            </Alert>
          )}

          {devices.length === 0 && (
            <Alert severity="warning" sx={{ mb: 2 }}>
              Aucun appareil trouvé. Veuillez d'abord créer un appareil dans Catalogue → Gestion des Appareils
            </Alert>
          )}

          <Grid container spacing={3}>
            {/* Sélection du client */}
            <Grid item xs={12}>
              <Typography variant="subtitle2" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <PersonIcon fontSize="small" color="primary" />
                Client
              </Typography>
              <Autocomplete
                options={clients}
                getOptionLabel={(option) => `${option.firstName} ${option.lastName} - ${option.email}`}
                value={clients.find(c => c.id === formData.clientId) || null}
                onChange={(_, newValue) => handleChange('clientId', newValue?.id || '')}
                renderInput={(params) => (
                  <TextField
                    {...params}
                    placeholder="Rechercher un client..."
                    error={!!errors.clientId}
                    helperText={errors.clientId}
                    autoFocus
                  />
                )}
                disabled={clients.length === 0}
              />
            </Grid>

            {/* Sélection de l'appareil */}
            <Grid item xs={12}>
              <Typography variant="subtitle2" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <DeviceIcon fontSize="small" color="primary" />
                Appareil
              </Typography>
              <FormControl fullWidth error={!!errors.deviceId}>
                <InputLabel>Sélectionner un appareil</InputLabel>
                <Select
                  value={formData.deviceId}
                  label="Sélectionner un appareil"
                  onChange={(e) => handleChange('deviceId', e.target.value)}
                  disabled={!formData.clientId || filteredDevices.length === 0}
                >
                  {filteredDevices.map((device) => (
                    <MenuItem key={device.id} value={device.id}>
                      {device.brand} {device.model} ({device.type})
                      {device.serialNumber && ` - S/N: ${device.serialNumber}`}
                    </MenuItem>
                  ))}
                </Select>
                {errors.deviceId && (
                  <Typography variant="caption" color="error" sx={{ mt: 0.5, ml: 1.5 }}>
                    {errors.deviceId}
                  </Typography>
                )}
                {formData.clientId && filteredDevices.length === 0 && (
                  <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, ml: 1.5 }}>
                    Aucun appareil disponible pour ce client
                  </Typography>
                )}
              </FormControl>
            </Grid>

            {/* Description */}
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Description du problème"
                placeholder="Ex: Écran cassé, ne s'allume plus, problème de batterie..."
                value={formData.description}
                onChange={(e) => handleChange('description', e.target.value)}
                error={!!errors.description}
                helperText={errors.description || `${formData.description.length}/10 caractères minimum`}
                required
              />
            </Grid>

            {/* Problème constaté */}
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Problème constaté"
                placeholder="Ex: Écran fissuré suite à une chute, appareil ne démarre pas après contact avec l'eau..."
                value={formData.issue}
                onChange={(e) => handleChange('issue', e.target.value)}
                error={!!errors.issue}
                helperText={errors.issue || `${formData.issue.length}/10 caractères minimum`}
                required
              />
            </Grid>

            {/* Urgence */}
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={formData.isUrgent}
                    onChange={(e) => handleChange('isUrgent', e.target.checked)}
                    color="error"
                  />
                }
                label="Réparation urgente"
              />
            </Grid>

            {/* Date limite */}
            <Grid item xs={12} sm={6}>
              <DatePicker
                label="Date limite estimée"
                value={formData.dueDate}
                onChange={(newDate) => newDate && handleChange('dueDate', newDate)}
                slotProps={{
                  textField: {
                    fullWidth: true,
                    error: !!errors.dueDate,
                    helperText: errors.dueDate,
                  },
                }}
                minDate={new Date()}
              />
            </Grid>

            {/* Durée estimée */}
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="number"
                label="Durée estimée (minutes)"
                value={formData.estimatedDuration}
                onChange={(e) => handleChange('estimatedDuration', parseInt(e.target.value) || 0)}
                error={!!errors.estimatedDuration}
                helperText={errors.estimatedDuration}
                inputProps={{ min: 1, step: 15 }}
              />
            </Grid>

            {/* Prix estimé */}
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="number"
                label="Prix estimé (€)"
                value={formData.totalPrice}
                onChange={(e) => handleChange('totalPrice', parseFloat(e.target.value) || 0)}
                inputProps={{ min: 0, step: 5 }}
                helperText="Peut être ajusté ultérieurement"
              />
            </Grid>

            {/* Technicien assigné */}
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Technicien assigné (optionnel)</InputLabel>
                <Select
                  value={formData.assignedTechnicianId}
                  label="Technicien assigné (optionnel)"
                  onChange={(e) => handleChange('assignedTechnicianId', e.target.value)}
                >
                  <MenuItem value="">
                    <em>Aucun</em>
                  </MenuItem>
                  {users.map((user) => (
                    <MenuItem key={user.id} value={user.id}>
                      {user.firstName} {user.lastName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </Box>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} disabled={loading}>
          Annuler
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={loading || clients.length === 0 || devices.length === 0}
          startIcon={loading ? <CircularProgress size={20} /> : null}
          sx={{ backgroundColor: '#16a34a', '&:hover': { backgroundColor: '#15803d' } }}
        >
          {loading ? 'Création...' : 'Créer la prise en charge'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default NewRepairDialog;










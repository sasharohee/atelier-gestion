import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Chip,
  Avatar,
  IconButton,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Schedule as ScheduleIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const Calendar: React.FC = () => {
  const {
    appointments,
    clients,
    users,
    getClientById,
    getUserById,
  } = useAppStore();

  const [newAppointmentDialogOpen, setNewAppointmentDialogOpen] = useState(false);

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Calendrier
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des rendez-vous et planification
        </Typography>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewAppointmentDialogOpen(true)}
        >
          Nouveau rendez-vous
        </Button>
      </Box>

      {/* Calendrier (placeholder) */}
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 400 }}>
            <Box sx={{ textAlign: 'center' }}>
              <ScheduleIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary" gutterBottom>
                Calendrier en cours de développement
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Intégration d'un composant de calendrier avancé prévue
              </Typography>
            </Box>
          </Box>
        </CardContent>
      </Card>

      {/* Liste des rendez-vous */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          Rendez-vous à venir
        </Typography>
        <Grid container spacing={2}>
          {appointments
            .filter(appointment => new Date(appointment.startDate) > new Date())
            .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime())
            .map((appointment) => {
              const client = getClientById(appointment.clientId);
              const technician = appointment.assignedTechnicianId ? getUserById(appointment.assignedTechnicianId) : null;
              
              return (
                <Grid item xs={12} md={6} lg={4} key={appointment.id}>
                  <Card>
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                        <Typography variant="h6">
                          {appointment.title}
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 0.5 }}>
                          <IconButton size="small">
                            <EditIcon fontSize="small" />
                          </IconButton>
                          <IconButton size="small">
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Box>
                      </Box>
                      
                      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        {appointment.description}
                      </Typography>
                      
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                        <Avatar sx={{ width: 24, height: 24, fontSize: '0.75rem' }}>
                          {client?.firstName?.charAt(0)}
                        </Avatar>
                        <Typography variant="body2">
                          {client?.firstName} {client?.lastName}
                        </Typography>
                      </Box>
                      
                      {technician && (
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                          <Avatar sx={{ width: 24, height: 24, fontSize: '0.75rem' }}>
                            {technician.name.charAt(0)}
                          </Avatar>
                          <Typography variant="body2" color="text.secondary">
                            {technician.name}
                          </Typography>
                        </Box>
                      )}
                      
                      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <Chip
                          label={appointment.status}
                          size="small"
                          color={appointment.status === 'confirmed' ? 'success' : 'default'}
                        />
                        <Typography variant="caption" color="text.secondary">
                          {new Date(appointment.startDate).toLocaleDateString('fr-FR')}
                        </Typography>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              );
            })}
        </Grid>
      </Box>

      {/* Dialog nouveau rendez-vous */}
      <Dialog open={newAppointmentDialogOpen} onClose={() => setNewAppointmentDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nouveau rendez-vous</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Titre"
                placeholder="Ex: Diagnostic iPhone"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={3}
                placeholder="Description du rendez-vous"
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Client</InputLabel>
                <Select label="Client">
                  {clients.map((client) => (
                    <MenuItem key={client.id} value={client.id}>
                      {client.firstName} {client.lastName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Technicien</InputLabel>
                <Select label="Technicien">
                  {users
                    .filter(user => user.role === 'technician')
                    .map((user) => (
                      <MenuItem key={user.id} value={user.id}>
                        {user.name}
                      </MenuItem>
                    ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Date de début"
                type="datetime-local"
                InputLabelProps={{
                  shrink: true,
                }}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Date de fin"
                type="datetime-local"
                InputLabelProps={{
                  shrink: true,
                }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewAppointmentDialogOpen(false)}>Annuler</Button>
          <Button variant="contained">Créer</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Calendar;

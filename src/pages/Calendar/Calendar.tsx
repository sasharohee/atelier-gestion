import React, { useState, useMemo } from 'react';
import {
  Box,
  Paper,
  Typography,
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
  Chip,
  Grid,
  Card,
  CardContent,
  IconButton,
  Tooltip,
  Alert,
} from '@mui/material';
import {
  Add as AddIcon,
  Event as EventIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
} from '@mui/icons-material';
import FullCalendar from '@fullcalendar/react';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import listPlugin from '@fullcalendar/list';
import { DateSelectArg, EventClickArg, EventApi } from '@fullcalendar/core';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Appointment, Repair, Client, User } from '../../types';

const Calendar: React.FC = () => {
  const {
    appointments,
    repairs,
    devices,
    clients,
    users,
    addAppointment,
    updateAppointment,
    deleteAppointment,
    getClientById,
    getUserById,
  } = useAppStore();

  const [openDialog, setOpenDialog] = useState(false);
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedEvent, setSelectedEvent] = useState<Appointment | null>(null);
  const [view, setView] = useState<'dayGridMonth' | 'timeGridWeek' | 'timeGridDay' | 'listWeek'>('dayGridMonth');
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    startDate: '',
    endDate: '',
    clientId: '',
    repairId: '',
    assignedUserId: '',
    type: 'appointment' as 'appointment' | 'repair',
  });

  // Convertir les rendez-vous et réparations en événements FullCalendar
  const calendarEvents = useMemo(() => {
    const events: any[] = [];

    // Ajouter les rendez-vous
    appointments.forEach(appointment => {
      events.push({
        id: `appointment-${appointment.id}`,
        title: appointment.title,
        start: appointment.startDate,
        end: appointment.endDate,
        backgroundColor: '#1976d2',
        borderColor: '#1976d2',
        textColor: '#ffffff',
        extendedProps: {
          type: 'appointment',
          appointment,
        },
      });
    });

    // Ajouter les réparations avec dates estimées
    repairs.forEach(repair => {
      if (repair.estimatedStartDate && repair.estimatedEndDate) {
        const device = devices.find(d => d.id === repair.deviceId);
        events.push({
          id: `repair-${repair.id}`,
          title: `Réparation: ${device?.brand} ${device?.model}`,
          start: repair.estimatedStartDate,
          end: repair.estimatedEndDate,
          backgroundColor: repair.status === 'completed' ? '#4caf50' : 
                          repair.status === 'in_progress' ? '#ff9800' : '#f44336',
          borderColor: repair.status === 'completed' ? '#4caf50' : 
                      repair.status === 'in_progress' ? '#ff9800' : '#f44336',
          textColor: '#ffffff',
          extendedProps: {
            type: 'repair',
            repair,
          },
        });
      }
    });

    return events;
  }, [appointments, repairs, devices]);

  const handleDateSelect = (selectInfo: DateSelectArg) => {
    setSelectedDate(new Date(selectInfo.start));
    setFormData({
      title: '',
      description: '',
      startDate: format(selectInfo.start, 'yyyy-MM-dd\'T\'HH:mm'),
      endDate: format(selectInfo.end, 'yyyy-MM-dd\'T\'HH:mm'),
      clientId: '',
      repairId: '',
      assignedUserId: '',
      type: 'appointment',
    });
    setOpenDialog(true);
  };

  const handleEventClick = (clickInfo: EventClickArg) => {
    const event = clickInfo.event;
    const extendedProps = event.extendedProps;
    
    if (extendedProps.type === 'appointment') {
      setSelectedEvent(extendedProps.appointment);
      setFormData({
        title: extendedProps.appointment.title,
        description: extendedProps.appointment.description || '',
        startDate: format(new Date(extendedProps.appointment.startDate), 'yyyy-MM-dd\'T\'HH:mm'),
        endDate: format(new Date(extendedProps.appointment.endDate), 'yyyy-MM-dd\'T\'HH:mm'),
        clientId: extendedProps.appointment.clientId || '',
        repairId: extendedProps.appointment.repairId || '',
        assignedUserId: extendedProps.appointment.assignedUserId || '',
        type: 'appointment',
      });
    } else if (extendedProps.type === 'repair') {
      // Afficher les détails de la réparation
      setSelectedEvent(null);
      // Ici on pourrait ouvrir un dialog pour voir les détails de la réparation
    }
    
    setOpenDialog(true);
  };

  const handleSubmit = () => {
    if (selectedEvent) {
      // Mettre à jour le rendez-vous existant
      updateAppointment(selectedEvent.id, {
        ...selectedEvent,
        title: formData.title,
        description: formData.description,
        startDate: new Date(formData.startDate),
        endDate: new Date(formData.endDate),
        clientId: formData.clientId,
        repairId: formData.repairId,
        assignedUserId: formData.assignedUserId,
      });
    } else {
      // Créer un nouveau rendez-vous
      const newAppointment: Omit<Appointment, 'id'> = {
        title: formData.title,
        description: formData.description,
        startDate: new Date(formData.startDate),
        endDate: new Date(formData.endDate),
        clientId: formData.clientId,
        repairId: formData.repairId,
        assignedUserId: formData.assignedUserId,
        status: 'scheduled',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      addAppointment(newAppointment);
    }
    
    setOpenDialog(false);
    setSelectedEvent(null);
    setFormData({
      title: '',
      description: '',
      startDate: '',
      endDate: '',
      clientId: '',
      repairId: '',
      assignedUserId: '',
      type: 'appointment',
    });
  };

  const handleDelete = () => {
    if (selectedEvent) {
      deleteAppointment(selectedEvent.id);
      setOpenDialog(false);
      setSelectedEvent(null);
    }
  };

  const getClientName = (clientId: string) => {
    const client = getClientById(clientId);
    return client ? `${client.firstName} ${client.lastName}` : 'Client inconnu';
  };

  const getUserName = (userId: string) => {
    const user = getUserById(userId);
    return user ? `${user.firstName} ${user.lastName}` : 'Utilisateur inconnu';
  };

  const getRepairTitle = (repairId: string) => {
    const repair = repairs.find(r => r.id === repairId);
    if (!repair) return 'Réparation inconnue';
    const device = devices.find(d => d.id === repair.deviceId);
    return device ? `${device.brand} ${device.model}` : 'Appareil inconnu';
  };

  // Rendez-vous du jour
  const todayAppointments = appointments.filter(appointment => {
    const today = new Date();
    const appointmentDate = new Date(appointment.startDate);
    return appointmentDate.toDateString() === today.toDateString();
  });

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Calendrier
        </Typography>
        <Box>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => {
              setSelectedEvent(null);
              setFormData({
                title: '',
                description: '',
                startDate: format(new Date(), 'yyyy-MM-dd\'T\'HH:mm'),
                endDate: format(new Date(Date.now() + 60 * 60 * 1000), 'yyyy-MM-dd\'T\'HH:mm'),
                clientId: '',
                repairId: '',
                assignedUserId: '',
                type: 'appointment',
              });
              setOpenDialog(true);
            }}
          >
            Nouveau rendez-vous
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Calendrier principal */}
        <Grid item xs={12} lg={8}>
          <Paper sx={{ p: 2 }}>
            <Box sx={{ mb: 2 }}>
              <Button
                variant={view === 'dayGridMonth' ? 'contained' : 'outlined'}
                onClick={() => setView('dayGridMonth')}
                sx={{ mr: 1 }}
              >
                Mois
              </Button>
              <Button
                variant={view === 'timeGridWeek' ? 'contained' : 'outlined'}
                onClick={() => setView('timeGridWeek')}
                sx={{ mr: 1 }}
              >
                Semaine
              </Button>
              <Button
                variant={view === 'timeGridDay' ? 'contained' : 'outlined'}
                onClick={() => setView('timeGridDay')}
                sx={{ mr: 1 }}
              >
                Jour
              </Button>
              <Button
                variant={view === 'listWeek' ? 'contained' : 'outlined'}
                onClick={() => setView('listWeek')}
              >
                Liste
              </Button>
            </Box>
            
            <FullCalendar
              plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin, listPlugin]}
              headerToolbar={false}
              initialView={view}
              editable={true}
              selectable={true}
              selectMirror={true}
              dayMaxEvents={true}
              weekends={true}
              events={calendarEvents}
              select={handleDateSelect}
              eventClick={handleEventClick}
              height="auto"
              locale="fr"
              firstDay={1}
              slotMinTime="08:00:00"
              slotMaxTime="20:00:00"
              allDaySlot={false}
            />
          </Paper>
        </Grid>

        {/* Panneau latéral */}
        <Grid item xs={12} lg={4}>
          {/* Rendez-vous du jour */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Rendez-vous du jour
              </Typography>
              {todayAppointments.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  Aucun rendez-vous aujourd'hui
                </Typography>
              ) : (
                todayAppointments.map((appointment) => (
                  <Box key={appointment.id} sx={{ mb: 2, p: 2, border: '1px solid #e0e0e0', borderRadius: 1 }}>
                    <Typography variant="subtitle2" fontWeight="bold">
                      {appointment.title}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {format(new Date(appointment.startDate), 'HH:mm', { locale: fr })} - 
                      {format(new Date(appointment.endDate), 'HH:mm', { locale: fr })}
                    </Typography>
                    {appointment.clientId && (
                      <Typography variant="body2" color="text.secondary">
                        Client: {getClientName(appointment.clientId)}
                      </Typography>
                    )}
                    {appointment.assignedUserId && (
                      <Typography variant="body2" color="text.secondary">
                        Assigné à: {getUserName(appointment.assignedUserId)}
                      </Typography>
                    )}
                  </Box>
                ))
              )}
            </CardContent>
          </Card>

          {/* Légende */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Légende
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Box sx={{ width: 16, height: 16, backgroundColor: '#1976d2', borderRadius: 1 }} />
                  <Typography variant="body2">Rendez-vous</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Box sx={{ width: 16, height: 16, backgroundColor: '#f44336', borderRadius: 1 }} />
                  <Typography variant="body2">Réparation en attente</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Box sx={{ width: 16, height: 16, backgroundColor: '#ff9800', borderRadius: 1 }} />
                  <Typography variant="body2">Réparation en cours</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Box sx={{ width: 16, height: 16, backgroundColor: '#4caf50', borderRadius: 1 }} />
                  <Typography variant="body2">Réparation terminée</Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Dialog pour créer/éditer un rendez-vous */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedEvent ? 'Modifier le rendez-vous' : 'Nouveau rendez-vous'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Titre"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                type="datetime-local"
                label="Date de début"
                value={formData.startDate}
                onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                type="datetime-local"
                label="Date de fin"
                value={formData.endDate}
                onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Client</InputLabel>
                <Select
                  value={formData.clientId}
                  onChange={(e) => setFormData({ ...formData, clientId: e.target.value })}
                  label="Client"
                >
                  <MenuItem value="">
                    <em>Aucun client</em>
                  </MenuItem>
                  {clients.map((client) => (
                    <MenuItem key={client.id} value={client.id}>
                      {client.firstName} {client.lastName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Réparation associée</InputLabel>
                <Select
                  value={formData.repairId}
                  onChange={(e) => setFormData({ ...formData, repairId: e.target.value })}
                  label="Réparation associée"
                >
                  <MenuItem value="">
                    <em>Aucune réparation</em>
                  </MenuItem>
                                     {repairs.map((repair) => {
                     const device = devices.find(d => d.id === repair.deviceId);
                     return (
                       <MenuItem key={repair.id} value={repair.id}>
                         {device?.brand} {device?.model} - {repair.issue}
                       </MenuItem>
                     );
                   })}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Assigné à</InputLabel>
                <Select
                  value={formData.assignedUserId}
                  onChange={(e) => setFormData({ ...formData, assignedUserId: e.target.value })}
                  label="Assigné à"
                >
                  <MenuItem value="">
                    <em>Non assigné</em>
                  </MenuItem>
                  {users.filter(user => user.role === 'technician').map((user) => (
                    <MenuItem key={user.id} value={user.id}>
                      {user.firstName} {user.lastName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          {selectedEvent && (
            <Button onClick={handleDelete} color="error">
              Supprimer
            </Button>
          )}
          <Button onClick={() => setOpenDialog(false)}>
            Annuler
          </Button>
          <Button onClick={handleSubmit} variant="contained">
            {selectedEvent ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Calendar;

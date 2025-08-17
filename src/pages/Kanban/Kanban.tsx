import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Avatar,
  Button,
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
  Grid,
  Tooltip,
  Badge,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { deviceTypeColors, repairStatusColors } from '../../theme';
import { Repair, RepairStatus } from '../../types';

const Kanban: React.FC = () => {
  const {
    repairs,
    repairStatuses,
    clients,
    devices,
    users,
    getClientById,
    getDeviceById,
    getUserById,
    updateRepair,
  } = useAppStore();

  const [selectedRepair, setSelectedRepair] = useState<Repair | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [newRepairDialogOpen, setNewRepairDialogOpen] = useState(false);

  const getStatusColor = (status: string) => {
    return repairStatusColors[status as keyof typeof repairStatusColors] || '#757575';
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

  const handleDragEnd = (result: any) => {
    if (!result.destination) return;

    const { source, destination, draggableId } = result;
    
    if (source.droppableId === destination.droppableId) {
      // Même colonne, pas de changement de statut
      return;
    }

    // Mettre à jour le statut de la réparation
    const repair = repairs.find(r => r.id === draggableId);
    if (repair) {
      updateRepair(repair.id, { status: destination.droppableId });
    }
  };

  const handleEditRepair = (repair: Repair) => {
    setSelectedRepair(repair);
    setEditDialogOpen(true);
  };

  const handleSaveRepair = () => {
    if (selectedRepair) {
      // Logique de sauvegarde
      setEditDialogOpen(false);
      setSelectedRepair(null);
    }
  };

  const RepairCard: React.FC<{ repair: Repair }> = ({ repair }) => {
    const client = getClientById(repair.clientId);
    const device = getDeviceById(repair.deviceId);
    const technician = repair.assignedTechnicianId ? getUserById(repair.assignedTechnicianId) : null;
    const isOverdue = new Date(repair.dueDate) < new Date();

    return (
      <Card
        sx={{
          mb: 2,
          cursor: 'pointer',
          '&:hover': {
            boxShadow: 4,
          },
          border: isOverdue ? '2px solid #f44336' : 'none',
        }}
      >
        <CardContent sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
            <Avatar
              sx={{
                backgroundColor: getDeviceTypeColor(device?.type || 'other'),
                width: 32,
                height: 32,
              }}
            >
              {getDeviceTypeIcon(device?.type || 'other')}
            </Avatar>
            <Box sx={{ display: 'flex', gap: 0.5 }}>
              <Tooltip title="Modifier">
                <IconButton size="small" onClick={(e) => { e.stopPropagation(); handleEditRepair(repair); }}>
                  <EditIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </Box>
          </Box>

          <Typography variant="subtitle2" gutterBottom>
            {client?.firstName} {client?.lastName}
          </Typography>

          <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
            {device?.brand} {device?.model}
          </Typography>

          <Typography variant="body2" sx={{ mb: 1 }}>
            {repair.description}
          </Typography>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
            <Chip
              label={repair.isUrgent ? 'Urgent' : 'Normal'}
              size="small"
              color={repair.isUrgent ? 'error' : 'default'}
            />
            {isOverdue && (
              <Chip
                icon={<WarningIcon />}
                label="En retard"
                size="small"
                color="error"
              />
            )}
          </Box>

          {technician && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              <Avatar sx={{ width: 20, height: 20, fontSize: '0.75rem' }}>
                {technician.name.charAt(0)}
              </Avatar>
              <Typography variant="caption" color="text.secondary">
                {technician.name}
              </Typography>
            </Box>
          )}

          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography variant="h6" color="primary">
              {repair.totalPrice} €
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {format(new Date(repair.dueDate), 'dd/MM')}
            </Typography>
          </Box>
        </CardContent>
      </Card>
    );
  };

  const KanbanColumn: React.FC<{ status: RepairStatus }> = ({ status }) => {
    const statusRepairs = repairs.filter(repair => repair.status === status.id);
    const isOverdue = statusRepairs.filter(repair => new Date(repair.dueDate) < new Date()).length;

    return (
      <Box sx={{ minWidth: 300, maxWidth: 300 }}>
        <Card sx={{ height: '100%' }}>
          <CardContent sx={{ p: 2, height: '100%', display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  {status.name}
                </Typography>
                <Badge badgeContent={statusRepairs.length} color="primary" />
                {isOverdue > 0 && (
                  <Badge badgeContent={isOverdue} color="error" />
                )}
              </Box>
              <Chip
                label={statusRepairs.length}
                size="small"
                sx={{
                  backgroundColor: status.color,
                  color: 'white',
                }}
              />
            </Box>

            <Droppable droppableId={status.id}>
              {(provided) => (
                <Box
                  ref={provided.innerRef}
                  {...provided.droppableProps}
                  sx={{ flexGrow: 1, minHeight: 200 }}
                >
                  {statusRepairs.map((repair, index) => (
                    <Draggable key={repair.id} draggableId={repair.id} index={index}>
                      {(provided) => (
                        <Box
                          ref={provided.innerRef}
                          {...provided.draggableProps}
                          {...provided.dragHandleProps}
                        >
                          <RepairCard repair={repair} />
                        </Box>
                      )}
                    </Draggable>
                  ))}
                  {provided.placeholder}
                </Box>
              )}
            </Droppable>

            <Button
              startIcon={<AddIcon />}
              variant="outlined"
              size="small"
              fullWidth
              sx={{ mt: 2 }}
              onClick={() => setNewRepairDialogOpen(true)}
            >
              Nouvelle réparation
            </Button>
          </CardContent>
        </Card>
      </Box>
    );
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Tableau Kanban
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Suivi des réparations par statut
        </Typography>
      </Box>

      {/* Tableau Kanban */}
      <DragDropContext onDragEnd={handleDragEnd}>
        <Box sx={{ display: 'flex', gap: 2, overflowX: 'auto', pb: 2 }}>
          {repairStatuses
            .sort((a, b) => a.order - b.order)
            .map((status) => (
              <KanbanColumn key={status.id} status={status} />
            ))}
        </Box>
      </DragDropContext>

      {/* Dialog d'édition */}
      <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Modifier la réparation</DialogTitle>
        <DialogContent>
          {selectedRepair && (
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Description"
                  multiline
                  rows={3}
                  defaultValue={selectedRepair.description}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Statut</InputLabel>
                  <Select
                    defaultValue={selectedRepair.status}
                    label="Statut"
                  >
                    {repairStatuses.map((status) => (
                      <MenuItem key={status.id} value={status.id}>
                        {status.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Technicien assigné</InputLabel>
                  <Select
                    defaultValue={selectedRepair.assignedTechnicianId || ''}
                    label="Technicien assigné"
                  >
                    <MenuItem value="">Aucun</MenuItem>
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
                  label="Prix total"
                  type="number"
                  defaultValue={selectedRepair.totalPrice}
                />
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>Annuler</Button>
          <Button onClick={handleSaveRepair} variant="contained">
            Sauvegarder
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog nouvelle réparation */}
      <Dialog open={newRepairDialogOpen} onClose={() => setNewRepairDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nouvelle réparation</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
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
                <InputLabel>Appareil</InputLabel>
                <Select label="Appareil">
                  {devices.map((device) => (
                    <MenuItem key={device.id} value={device.id}>
                      {device.brand} {device.model}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={3}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewRepairDialogOpen(false)}>Annuler</Button>
          <Button variant="contained">
            Créer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Kanban;

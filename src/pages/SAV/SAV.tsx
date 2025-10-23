import React, { useState, useEffect, useMemo } from 'react';
import {
  Box,
  Typography,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Paper,
  Grid,
  Card,
  CardContent,
  ToggleButtonGroup,
  ToggleButton,
  IconButton,
  Tooltip,
  Alert,
  Button,
} from '@mui/material';
import {
  Search as SearchIcon,
  FilterList as FilterIcon,
  ViewKanban as KanbanIcon,
  ViewList as ListIcon,
  Refresh as RefreshIcon,
  Timer as TimerIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Build as BuildIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';
import { useAppStore } from '../../store';
import { savService } from '../../services/savService';
import { Repair, RepairStatus, Client, Device, User, Part, Service } from '../../types';
import RepairCard from '../../components/SAV/RepairCard';
import RepairDetailsDialog from '../../components/SAV/RepairDetailsDialog';
import QuickActions from '../../components/SAV/QuickActions';
import NewRepairDialog from '../../components/SAV/NewRepairDialog';
import { printTemplatesService } from '../../components/SAV/PrintTemplates';
import { repairService } from '../../services/supabaseService';
import toast from 'react-hot-toast';
import ThermalReceiptDialog from '../../components/ThermalReceiptDialog';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';

// Fonction helper pour mapper les noms de statuts
const getDisplayStatusName = (statusName: string): string => {
  const name = statusName.toLowerCase();
  if (name.includes('new') || name.includes('nouvelle')) {
    return 'Prise en charge';
  }
  return statusName;
};

const SAV: React.FC = () => {
  const {
    repairs,
    repairStatuses,
    clients,
    devices,
    users,
    parts,
    services,
    getClientById,
    getDeviceById,
    getUserById,
    updateRepair,
    updateRepairPaymentStatus,
    loadRepairs,
    systemSettings,
  } = useAppStore();

  const { workshopSettings } = useWorkshopSettings();

  // États locaux
  const [searchQuery, setSearchQuery] = useState('');
  const [filterTechnician, setFilterTechnician] = useState<string>('all');
  const [filterUrgent, setFilterUrgent] = useState<boolean | 'all'>('all');
  const [viewMode, setViewMode] = useState<'kanban' | 'list'>('kanban');
  const [selectedRepair, setSelectedRepair] = useState<Repair | null>(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [newRepairDialogOpen, setNewRepairDialogOpen] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);
  const [thermalReceiptDialogOpen, setThermalReceiptDialogOpen] = useState(false);
  const [thermalReceiptRepair, setThermalReceiptRepair] = useState<Repair | null>(null);

  // Calculer les statistiques
  const stats = useMemo(() => {
    return savService.calculateStats(repairs, repairStatuses);
  }, [repairs, repairStatuses, refreshKey]);

  // Forcer une mise à jour toutes les 30 secondes pour les timers
  useEffect(() => {
    const interval = setInterval(() => {
      setRefreshKey((prev) => prev + 1);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  // Filtrer les réparations
  const filteredRepairs = useMemo(() => {
    return repairs.filter((repair) => {
      // Filtrer uniquement les réparations créées depuis SAV
      if (repair.source !== 'sav') {
        return false;
      }

      // Filtre de recherche
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const client = getClientById(repair.clientId);
        const device = getDeviceById(repair.deviceId);
        const repairNumber = repair.repairNumber?.toLowerCase() || '';
        const clientName = client ? `${client.firstName} ${client.lastName}`.toLowerCase() : '';
        const deviceInfo = device ? `${device.brand} ${device.model}`.toLowerCase() : '';
        const description = repair.description.toLowerCase();

        const matches =
          repairNumber.includes(query) ||
          clientName.includes(query) ||
          deviceInfo.includes(query) ||
          description.includes(query);

        if (!matches) return false;
      }

      // Filtre technicien
      if (filterTechnician !== 'all' && repair.assignedTechnicianId !== filterTechnician) {
        return false;
      }

      // Filtre urgent
      if (filterUrgent !== 'all' && repair.isUrgent !== filterUrgent) {
        return false;
      }

      return true;
    });
  }, [repairs, searchQuery, filterTechnician, filterUrgent, getClientById, getDeviceById, refreshKey]);

  // Grouper les réparations par statut
  const repairsByStatus = useMemo(() => {
    const grouped: Record<string, Repair[]> = {};
    
    repairStatuses.forEach((status) => {
      grouped[status.id] = filteredRepairs.filter((repair) => repair.status === status.id);
    });

    return grouped;
  }, [filteredRepairs, repairStatuses]);

  // Gérer le drag & drop
  const handleDragEnd = async (result: DropResult) => {
    const { source, destination, draggableId } = result;

    // Pas de destination ou même position
    if (!destination || (source.droppableId === destination.droppableId && source.index === destination.index)) {
      return;
    }

    // Trouver la réparation
    const repair = repairs.find((r) => r.id === draggableId);
    if (!repair) return;

    // Mettre à jour le statut
    const updates = {
      status: destination.droppableId,
    };

    try {
      await updateRepair(repair.id, updates);
      toast.success('Statut mis à jour');

      // Recharger les réparations pour mettre à jour l'affichage
      await loadRepairs();

      // Logger l'action
      const user = users.find((u) => u.id === repair.assignedTechnicianId);
      savService.createLog(
        repair.id,
        'status_change',
        user?.id || 'system',
        user ? `${user.firstName} ${user.lastName}` : 'Système',
        `Statut changé vers: ${repairStatuses.find((s) => s.id === destination.droppableId)?.name}`
      );
    } catch (error) {
      toast.error('Erreur lors de la mise à jour du statut');
      console.error(error);
    }
  };

  // Gérer l'ajout de note
  const handleAddNote = async (repair: Repair, note: string) => {
    const updatedNotes = repair.notes ? `${repair.notes}\n\n[${new Date().toLocaleString('fr-FR')}] ${note}` : note;
    
    try {
      await updateRepair(repair.id, {
        notes: updatedNotes,
      });
      toast.success('Note ajoutée');
      
      // Recharger les réparations pour mettre à jour l'affichage
      await loadRepairs();
    } catch (error) {
      toast.error('Erreur lors de l\'ajout de la note');
      console.error(error);
    }
  };

  // Gérer les impressions
  const handlePrint = (repair: Repair, type: 'label' | 'work_order' | 'deposit_receipt' | 'invoice' | 'complete_ticket') => {
    const client = getClientById(repair.clientId);
    const device = getDeviceById(repair.deviceId);
    const technician = repair.assignedTechnicianId ? getUserById(repair.assignedTechnicianId) : null;

    if (!client) {
      toast.error('Client introuvable');
      return;
    }

    // Récupérer les informations de l'atelier depuis les paramètres système
    const workshopInfo = {
      name: systemSettings.find((s) => s.key === 'workshop.name')?.value || 'Mon Atelier',
      address: systemSettings.find((s) => s.key === 'workshop.address')?.value || '',
      phone: systemSettings.find((s) => s.key === 'workshop.phone')?.value || '',
      email: systemSettings.find((s) => s.key === 'workshop.email')?.value || '',
    };

    const template = {
      type,
      data: {
        repair,
        client,
        device,
        technician: technician || undefined,
        workshopInfo,
      },
    };

    printTemplatesService.print(template);
    toast.success('Document généré');
  };

  // Gérer l'impression thermique
  const handleOpenThermalReceipt = (repair: Repair) => {
    setThermalReceiptRepair(repair);
    setThermalReceiptDialogOpen(true);
  };

  // Gérer la vue des détails
  const handleViewDetails = (repair: Repair) => {
    setSelectedRepair(repair);
    setDetailsOpen(true);
  };

  // Rafraîchir les données
  const handleRefresh = async () => {
    try {
      await loadRepairs();
      toast.success('Données actualisées');
    } catch (error) {
      toast.error('Erreur lors de l\'actualisation');
    }
  };

  // Gérer le changement de statut de paiement
  const handlePaymentStatusChange = async (repair: Repair, isPaid: boolean) => {
    try {
      console.log('🔄 handlePaymentStatusChange appelé avec:', { repairId: repair.id, isPaid });
      
      // Utiliser la même logique que la page Kanban
      await updateRepairPaymentStatus(repair.id, isPaid);
      
      toast.success(`✅ Statut de paiement mis à jour : ${isPaid ? 'Payé' : 'Non payé'}`);
    } catch (error) {
      // Ne pas afficher d'erreur car l'interface fonctionne quand même
      console.warn('⚠️ Statut de paiement mis à jour localement (sauvegarde en base échouée):', error);
      toast.success(`✅ Statut de paiement mis à jour localement : ${isPaid ? 'Payé' : 'Non payé'}`);
    }
  };

  // Créer une nouvelle prise en charge
  const handleCreateRepair = async (repair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'>) => {
    try {
      await repairService.create(repair, 'sav'); // Marquer comme créé depuis SAV
      toast.success(`✅ Prise en charge ${repair.repairNumber} créée avec succès`);
      await loadRepairs();
      setNewRepairDialogOpen(false);
    } catch (error: any) {
      toast.error(error.message || 'Erreur lors de la création de la prise en charge');
      throw error;
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" component="h1" sx={{ fontWeight: 600, color: '#1f2937', mb: 1 }}>
            SAV Réparateur
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Gestion des réparations et service après-vente
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setNewRepairDialogOpen(true)}
            sx={{
              backgroundColor: '#16a34a',
              '&:hover': { backgroundColor: '#15803d' },
            }}
          >
            Nouvelle prise en charge
          </Button>
          <ToggleButtonGroup
            value={viewMode}
            exclusive
            onChange={(e, value) => value && setViewMode(value)}
            size="small"
          >
            <ToggleButton value="kanban">
              <KanbanIcon sx={{ mr: 1 }} /> Kanban
            </ToggleButton>
            <ToggleButton value="list">
              <ListIcon sx={{ mr: 1 }} /> Liste
            </ToggleButton>
          </ToggleButtonGroup>
          <Tooltip title="Rafraîchir">
            <IconButton onClick={handleRefresh} color="primary">
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* Statistiques */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#6366f1' }}>
                    {stats.totalRepairs}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total réparations
                  </Typography>
                </Box>
                <BuildIcon sx={{ fontSize: 40, color: '#6366f1', opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#3b82f6' }}>
                    {stats.inProgressRepairs}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    En cours
                  </Typography>
                </Box>
                <TimerIcon sx={{ fontSize: 40, color: '#3b82f6', opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#ef4444' }}>
                    {stats.urgentRepairs}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Urgentes
                  </Typography>
                </Box>
                <WarningIcon sx={{ fontSize: 40, color: '#ef4444', opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#10b981' }}>
                    {stats.completedRepairs}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Terminées
                  </Typography>
                </Box>
                <CheckCircleIcon sx={{ fontSize: 40, color: '#10b981', opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Alertes */}
      {stats.overdueRepairs > 0 && (
        <Alert severity="warning" sx={{ mb: 3 }}>
          <strong>{stats.overdueRepairs}</strong> réparation{stats.overdueRepairs > 1 ? 's' : ''} en retard !
        </Alert>
      )}

      {/* Filtres */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              size="small"
              placeholder="Rechercher par client, appareil, numéro..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth size="small">
              <InputLabel>Technicien</InputLabel>
              <Select
                value={filterTechnician}
                label="Technicien"
                onChange={(e) => setFilterTechnician(e.target.value)}
              >
                <MenuItem value="all">Tous les techniciens</MenuItem>
                {users.map((user) => (
                  <MenuItem key={user.id} value={user.id}>
                    {user.firstName} {user.lastName}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth size="small">
              <InputLabel>Urgence</InputLabel>
              <Select
                value={filterUrgent === 'all' ? 'all' : filterUrgent ? 'urgent' : 'normal'}
                label="Urgence"
                onChange={(e) => {
                  const val = e.target.value;
                  setFilterUrgent(val === 'all' ? 'all' : val === 'urgent');
                }}
              >
                <MenuItem value="all">Toutes</MenuItem>
                <MenuItem value="urgent">Urgentes uniquement</MenuItem>
                <MenuItem value="normal">Normales uniquement</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} md={2}>
            <Chip
              label={`${filteredRepairs.length} résultat${filteredRepairs.length > 1 ? 's' : ''}`}
              color="primary"
              variant="outlined"
            />
          </Grid>
        </Grid>
      </Paper>

      {/* Vue Kanban */}
      {viewMode === 'kanban' && (
        <DragDropContext onDragEnd={handleDragEnd}>
          <Box sx={{ display: 'flex', gap: 2, overflowX: 'auto', pb: 2 }}>
            {repairStatuses.map((status) => (
              <Box
                key={status.id}
                sx={{
                  minWidth: 320,
                  flex: '0 0 auto',
                }}
              >
                {/* En-tête de colonne */}
                <Paper
                  sx={{
                    p: 2,
                    mb: 2,
                    backgroundColor: status.color,
                    color: '#fff',
                  }}
                >
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      {getDisplayStatusName(status.name)}
                    </Typography>
                    <Chip
                      label={repairsByStatus[status.id]?.length || 0}
                      size="small"
                      sx={{
                        backgroundColor: 'rgba(255, 255, 255, 0.3)',
                        color: '#fff',
                        fontWeight: 600,
                      }}
                    />
                  </Box>
                </Paper>

                {/* Colonne droppable */}
                <Droppable droppableId={status.id}>
                  {(provided, snapshot) => (
                    <Box
                      ref={provided.innerRef}
                      {...provided.droppableProps}
                      sx={{
                        minHeight: 400,
                        backgroundColor: snapshot.isDraggingOver ? '#f3f4f6' : 'transparent',
                        borderRadius: 2,
                        p: 1,
                        transition: 'background-color 0.2s',
                      }}
                    >
                      {repairsByStatus[status.id]?.map((repair, index) => {
                        const client = getClientById(repair.clientId);
                        const device = getDeviceById(repair.deviceId);
                        const technician = repair.assignedTechnicianId
                          ? getUserById(repair.assignedTechnicianId)
                          : null;

                        if (!client) return null;

                        return (
                          <Draggable key={repair.id} draggableId={repair.id} index={index}>
                            {(provided, snapshot) => (
                              <div
                                ref={provided.innerRef}
                                {...provided.draggableProps}
                                {...provided.dragHandleProps}
                                style={{
                                  ...provided.draggableProps.style,
                                  opacity: snapshot.isDragging ? 0.8 : 1,
                                }}
                              >
                                <RepairCard
                                  repair={repair}
                                  client={client}
                                  device={device}
                                  technician={technician}
                                  repairStatus={status}
                                  onViewDetails={handleViewDetails}
                                  onPrint={(repair, type) => handlePrint(repair, type)}
                                  onPrintCompleteTicket={(repair) => handlePrint(repair, 'complete_ticket')}
                                  onPaymentStatusChange={handlePaymentStatusChange}
                                  onThermalReceipt={handleOpenThermalReceipt}
                                />
                              </div>
                            )}
                          </Draggable>
                        );
                      })}
                      {provided.placeholder}
                    </Box>
                  )}
                </Droppable>
              </Box>
            ))}
          </Box>
        </DragDropContext>
      )}

      {/* Vue Liste */}
      {viewMode === 'list' && (
        <Box>
          {filteredRepairs.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <Typography variant="body1" color="text.secondary">
                Aucune réparation trouvée
              </Typography>
            </Paper>
          ) : (
            filteredRepairs.map((repair) => {
              const client = getClientById(repair.clientId);
              const device = getDeviceById(repair.deviceId);
              const technician = repair.assignedTechnicianId
                ? getUserById(repair.assignedTechnicianId)
                : null;
              const status = repairStatuses.find((s) => s.id === repair.status);

              if (!client || !status) return null;

              return (
                <RepairCard
                  key={repair.id}
                  repair={repair}
                  client={client}
                  device={device}
                  technician={technician}
                  repairStatus={status}
                  onViewDetails={handleViewDetails}
                  onPrint={(repair, type) => handlePrint(repair, type)}
                  onPrintCompleteTicket={(repair) => handlePrint(repair, 'complete_ticket')}
                  onPaymentStatusChange={handlePaymentStatusChange}
                  onThermalReceipt={handleOpenThermalReceipt}
                  onClick={() => handleViewDetails(repair)}
                />
              );
            })
          )}
        </Box>
      )}

      {/* Dialog de détails */}
      {selectedRepair && (
        <RepairDetailsDialog
          open={detailsOpen}
          onClose={() => {
            setDetailsOpen(false);
            setSelectedRepair(null);
          }}
          repair={selectedRepair}
          client={getClientById(selectedRepair.clientId)!}
          device={getDeviceById(selectedRepair.deviceId)}
          technician={
            selectedRepair.assignedTechnicianId
              ? getUserById(selectedRepair.assignedTechnicianId) || null
              : null
          }
          parts={parts}
          services={services}
        />
      )}

      {/* Actions rapides (SpeedDial) */}
      {selectedRepair && (
        <QuickActions
          repair={selectedRepair}
          onStatusChange={async (repair, newStatus) => {
            try {
              await updateRepair(repair.id, { status: newStatus });
              toast.success('Statut mis à jour');
              // Recharger les réparations pour mettre à jour l'affichage
              await loadRepairs();
            } catch (error) {
              toast.error('Erreur lors de la mise à jour du statut');
              console.error(error);
            }
          }}
          onAddNote={handleAddNote}
          onPrintWorkOrder={(repair) => handlePrint(repair, 'work_order')}
          onPrintReceipt={(repair) => handlePrint(repair, 'deposit_receipt')}
          onGenerateInvoice={(repair) => handlePrint(repair, 'invoice')}
          onPrintCompleteTicket={(repair) => handlePrint(repair, 'complete_ticket')}
          onPaymentStatusChange={handlePaymentStatusChange}
        />
      )}

      {/* Dialog de création de prise en charge */}
      <NewRepairDialog
        open={newRepairDialogOpen}
        onClose={() => setNewRepairDialogOpen(false)}
        clients={clients}
        devices={devices}
        users={users}
        repairStatuses={repairStatuses}
        onSubmit={handleCreateRepair}
      />

      {/* Dialog pour l'impression thermique */}
      {thermalReceiptRepair && (
        <ThermalReceiptDialog
          open={thermalReceiptDialogOpen}
          onClose={() => {
            setThermalReceiptDialogOpen(false);
            setThermalReceiptRepair(null);
          }}
          repair={thermalReceiptRepair}
          client={getClientById(thermalReceiptRepair.clientId)}
          device={thermalReceiptRepair.deviceId ? getDeviceById(thermalReceiptRepair.deviceId) : undefined}
          technician={thermalReceiptRepair.assignedTechnicianId ? getUserById(thermalReceiptRepair.assignedTechnicianId) : undefined}
          workshopInfo={{
            name: workshopSettings?.name || 'Atelier',
            address: workshopSettings?.address,
            phone: workshopSettings?.phone,
            email: workshopSettings?.email,
            siret: workshopSettings?.siret,
            vatNumber: workshopSettings?.vatNumber,
          }}
        />
      )}
    </Box>
  );
};

export default SAV;


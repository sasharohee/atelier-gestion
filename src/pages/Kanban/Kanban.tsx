import React, { useState, useEffect } from 'react';
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
  Tabs,
  Tab,
  Divider,
  Alert,
  Switch,
  FormControlLabel,
  Accordion,
  AccordionSummary,
  AccordionDetails,
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
  ExpandMore as ExpandMoreIcon,
  Receipt as ReceiptIcon,
  Print as PrintIcon,
  Email as EmailIcon,
  PersonAdd as PersonAddIcon,
  DeviceHub as DeviceHubIcon,
  Archive as ArchiveIcon,
} from '@mui/icons-material';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useNavigate } from 'react-router-dom';
import { useAppStore } from '../../store';
import { deviceTypeColors, repairStatusColors } from '../../theme';
import { Repair, RepairStatus, Device, Client } from '../../types';
import Invoice from '../../components/Invoice';
import { supabase } from '../../lib/supabase';

const Kanban: React.FC = () => {
  const navigate = useNavigate();
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
    addRepair,
    deleteRepair,
    addDevice,
    addClient,
    loadUsers,
  } = useAppStore();

  const [selectedRepair, setSelectedRepair] = useState<Repair | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [newRepairDialogOpen, setNewRepairDialogOpen] = useState(false);
  const [invoiceOpen, setInvoiceOpen] = useState(false);
  const [selectedRepairForInvoice, setSelectedRepairForInvoice] = useState<Repair | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [repairToDelete, setRepairToDelete] = useState<Repair | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  
  // États pour le formulaire de nouvelle réparation
  const [newRepair, setNewRepair] = useState({
    clientId: '' as string,
    deviceId: '' as string,
    description: '',
    issue: '',
    status: 'new' as string,
    isUrgent: false,
    totalPrice: 0,
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 jours par défaut
    assignedTechnicianId: '' as string,
  });

  // États pour le nouvel appareil
  const [newDevice, setNewDevice] = useState({
    brand: '',
    model: '',
    serialNumber: '',
    type: 'smartphone' as 'smartphone' | 'tablet' | 'laptop' | 'desktop' | 'other',
  });

  // États pour le nouveau client
  const [newClient, setNewClient] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    address: '',
  });

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

  // Charger les utilisateurs au montage du composant
  useEffect(() => {
    const loadUsersData = async () => {
      try {
        console.log('🔄 Chargement des utilisateurs dans Kanban...');
        await loadUsers();
        console.log('✅ Utilisateurs chargés dans Kanban');
      } catch (error) {
        console.error('❌ Erreur lors du chargement des utilisateurs:', error);
      }
    };
    
    loadUsersData();
  }, [loadUsers]); // Retirer 'users' des dépendances pour éviter la boucle infinie

  // Debug: Afficher les informations des utilisateurs quand ils changent (sans recharger)
  useEffect(() => {
    if (users.length > 0) {
      console.log('📊 Utilisateurs dans le store:', users);
      console.log('🔍 Détail des utilisateurs chargés:');
      users.forEach((user, index) => {
        console.log(`${index + 1}. ${user.firstName} ${user.lastName} (${user.role}) - ID: ${user.id}`);
      });
    }
  }, [users]);

  // Fonction utilitaire pour sécuriser les dates
  const safeFormatDate = (date: any, formatString: string) => {
    try {
      if (!date) return 'Date inconnue';
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) return 'Date invalide';
      return format(dateObj, formatString, { locale: fr });
    } catch (error) {
      console.error('Erreur de formatage de date:', error);
      return 'Date invalide';
    }
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
      
      // Notification spéciale si la réparation est déplacée vers "Restitué"
      if (destination.droppableId === 'returned') {
        const client = getClientById(repair.clientId);
        const clientName = client ? `${client.firstName} ${client.lastName}` : 'Client';
        const device = getDeviceById(repair.deviceId);
        const deviceInfo = device ? `${device.brand} ${device.model}` : 'Appareil';
        
        alert(`✅ Réparation restituée et archivée !\n\nClient: ${clientName}\nAppareil: ${deviceInfo}\n\nLa réparation a été automatiquement archivée et ne sera plus visible dans le Kanban.\nVous pouvez la consulter dans la page "Archives".`);
      }
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

  const handleDeleteRepair = (repair: Repair) => {
    setRepairToDelete(repair);
    setDeleteDialogOpen(true);
  };

  const confirmDeleteRepair = async () => {
    if (repairToDelete) {
      try {
        await deleteRepair(repairToDelete.id);
        setDeleteDialogOpen(false);
        setRepairToDelete(null);
        alert('✅ Réparation supprimée avec succès !');
      } catch (error) {
        console.error('Erreur lors de la suppression de la réparation:', error);
        alert('❌ Erreur lors de la suppression de la réparation');
      }
    }
  };

  const handleCreateRepair = async () => {
    try {
      if (!newRepair.clientId || !newRepair.deviceId || !newRepair.description) {
        alert('Veuillez remplir tous les champs obligatoires');
        return;
      }

      // Préparer les données pour Supabase (sans id, createdAt, updatedAt)
      const repairData: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'> = {
        clientId: newRepair.clientId,
        deviceId: newRepair.deviceId,
        description: newRepair.description,
        issue: newRepair.issue,
        status: newRepair.status,
        assignedTechnicianId: newRepair.assignedTechnicianId || undefined,
        estimatedDuration: 0,
        isUrgent: newRepair.isUrgent,
        totalPrice: newRepair.totalPrice,
        dueDate: new Date(newRepair.dueDate),
        services: [],
        parts: [],
        isPaid: false,
      };

      await addRepair(repairData as Repair);
      
      // Réinitialiser le formulaire
      resetNewRepairForm();
      
      setNewRepairDialogOpen(false);
      alert('✅ Réparation créée avec succès !');
    } catch (error) {
      console.error('Erreur lors de la création de la réparation:', error);
      alert('❌ Erreur lors de la création de la réparation');
    }
  };

  const handleNewRepairChange = (field: string, value: any) => {
    setNewRepair(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const resetNewRepairForm = () => {
    setNewRepair({
      clientId: '' as string,
      deviceId: '' as string,
      description: '',
      issue: '',
      status: 'new' as string,
      isUrgent: false,
      totalPrice: 0,
      dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      assignedTechnicianId: '' as string,
    });
  };

  // Fonctions pour gérer les nouveaux appareils et clients
  const handleCreateNewDevice = async () => {
    try {
      // Vérifier si le numéro de série existe déjà (seulement si fourni)
      if (newDevice.serialNumber && newDevice.serialNumber.trim()) {
        const existingDevice = devices.find(d => 
          d.serialNumber && 
          d.serialNumber.trim().toLowerCase() === newDevice.serialNumber.trim().toLowerCase()
        );
        if (existingDevice) {
          alert(`❌ Un appareil avec le numéro de série "${newDevice.serialNumber}" existe déjà.\n\nAppareil: ${existingDevice.brand} ${existingDevice.model}\n\nVeuillez utiliser un numéro de série différent, laisser le champ vide, ou sélectionner l'appareil existant.`);
          return;
        }
      }

      // Validation supplémentaire des champs requis
      if (!newDevice.brand.trim() || !newDevice.model.trim()) {
        alert('❌ Veuillez remplir la marque et le modèle de l\'appareil.');
        return;
      }

      const deviceData: Omit<Device, 'id' | 'createdAt' | 'updatedAt'> = {
        brand: newDevice.brand.trim(),
        model: newDevice.model.trim(),
        serialNumber: newDevice.serialNumber.trim() || undefined, // Numéro de série optionnel
        type: newDevice.type,
        specifications: {},
      };

      await addDevice(deviceData as Device);
      
      // Trouver le nouvel appareil créé dans la liste mise à jour
      const newDeviceCreated = devices.find(d => 
        d.brand === newDevice.brand.trim() && 
        d.model === newDevice.model.trim() && 
        (newDevice.serialNumber ? d.serialNumber === newDevice.serialNumber.trim() : !d.serialNumber)
      );
      
      // Sélectionner automatiquement le nouvel appareil
      if (newDeviceCreated) {
        handleNewRepairChange('deviceId', newDeviceCreated.id);
      }
      
      // Réinitialiser le formulaire
      setNewDevice({
        brand: '',
        model: '',
        serialNumber: '',
        type: 'smartphone',
      });
      
      // Retourner à l'onglet réparation
      setActiveTab(0);
      
      alert('✅ Appareil créé avec succès et sélectionné !');
    } catch (error: any) {
      console.error('Erreur lors de la création de l\'appareil:', error);
      
      // Gestion spécifique des erreurs
      if (error.message && error.message.includes('duplicate key value violates unique constraint "devices_serial_number_key"')) {
        alert(`❌ Un appareil avec le numéro de série "${newDevice.serialNumber}" existe déjà dans la base de données.\n\nVeuillez utiliser un numéro de série différent.`);
      } else if (error.message && error.message.includes('duplicate key')) {
        alert('❌ Un appareil avec ces informations existe déjà.\n\nVeuillez vérifier les données saisies.');
      } else {
        alert('❌ Erreur lors de la création de l\'appareil.\n\nVeuillez vérifier les informations saisies et réessayer.');
      }
    }
  };

  const handleCreateNewClient = async () => {
    try {
      // Vérifier si l'email existe déjà
      const existingClient = clients.find(c => c.email.toLowerCase() === newClient.email.toLowerCase());
      if (existingClient) {
        alert(`❌ Un client avec l'email "${newClient.email}" existe déjà.\n\nNom: ${existingClient.firstName} ${existingClient.lastName}\n\nVeuillez utiliser un email différent ou sélectionner le client existant.`);
        return;
      }

      const clientData: Omit<Client, 'id' | 'createdAt' | 'updatedAt'> = {
        firstName: newClient.firstName,
        lastName: newClient.lastName,
        email: newClient.email,
        phone: newClient.phone,
        address: newClient.address,
        notes: '',
      };

      await addClient(clientData as Client);
      
      // Trouver le nouveau client créé dans la liste mise à jour
      const newClientCreated = clients.find(c => 
        c.firstName === newClient.firstName && 
        c.lastName === newClient.lastName && 
        c.email === newClient.email
      );
      
      // Sélectionner automatiquement le nouveau client
      if (newClientCreated) {
        handleNewRepairChange('clientId', newClientCreated.id);
      }
      
      // Réinitialiser le formulaire
      setNewClient({
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        address: '',
      });
      
      // Retourner à l'onglet réparation
      setActiveTab(0);
      
      alert('✅ Client créé avec succès et sélectionné !');
    } catch (error: any) {
      console.error('Erreur lors de la création du client:', error);
      
      // Gestion spécifique des erreurs
      if (error.message && error.message.includes('duplicate key value violates unique constraint "clients_email_key"')) {
        alert(`❌ Un client avec l'email "${newClient.email}" existe déjà dans la base de données.\n\nVeuillez utiliser un email différent.`);
      } else if (error.message && error.message.includes('duplicate key')) {
        alert('❌ Un client avec ces informations existe déjà.\n\nVeuillez vérifier les données saisies.');
      } else {
        alert('❌ Erreur lors de la création du client.\n\nVeuillez vérifier les informations saisies et réessayer.');
      }
    }
  };

  // Fonctions pour gérer les factures
  const openInvoice = (repair: Repair) => {
    setSelectedRepairForInvoice(repair);
    setInvoiceOpen(true);
  };

  const closeInvoice = () => {
    setInvoiceOpen(false);
    setSelectedRepairForInvoice(null);
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
              <Tooltip title="Supprimer">
                <IconButton 
                  size="small" 
                  onClick={(e) => { e.stopPropagation(); handleDeleteRepair(repair); }}
                  sx={{ color: 'error.main' }}
                >
                  <DeleteIcon fontSize="small" />
                </IconButton>
              </Tooltip>
                              {(repair.status === 'completed' || repair.status === 'returned') && (
                <>
                  <Tooltip title="Voir facture">
                    <IconButton 
                      size="small" 
                      onClick={(e) => { e.stopPropagation(); openInvoice(repair); }}
                    >
                      <ReceiptIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Imprimer facture">
                    <IconButton 
                      size="small" 
                      onClick={(e) => { e.stopPropagation(); openInvoice(repair); }}
                    >
                      <PrintIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </>
              )}
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
                {technician.firstName.charAt(0)}
              </Avatar>
              <Typography variant="caption" color="text.secondary">
                {`${technician.firstName} ${technician.lastName}`}
              </Typography>
            </Box>
          )}

          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography variant="h6" color="primary">
              {repair.totalPrice} €
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {safeFormatDate(repair.dueDate, 'dd/MM')}
            </Typography>
          </Box>
        </CardContent>
      </Card>
    );
  };

  const KanbanColumn: React.FC<{ status: RepairStatus }> = ({ status }) => {
    // Filtrer les réparations pour exclure celles avec le statut "returned" (archivées)
    const statusRepairs = repairs.filter(repair => repair.status === status.id && repair.status !== 'returned');
    const isOverdue = statusRepairs.filter(repair => {
      try {
        if (!repair.dueDate) return false;
        const dueDate = new Date(repair.dueDate);
        if (isNaN(dueDate.getTime())) return false;
        return dueDate < new Date();
      } catch (error) {
        console.error('Erreur de date dans la réparation:', error);
        return false;
      }
    }).length;

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
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h4" sx={{ fontWeight: 600 }}>
            Tableau Kanban
          </Typography>
          <Button
            variant="outlined"
            startIcon={<ArchiveIcon />}
            onClick={() => navigate('/app/archive')}
            sx={{ ml: 2 }}
          >
            Voir les archives
            <Badge 
              badgeContent={repairs.filter(r => r.status === 'returned').length} 
              color="primary" 
              sx={{ ml: 1 }}
            />
          </Button>
        </Box>
        <Typography variant="body1" color="text.secondary">
          Suivi des réparations par statut (réparations restituées automatiquement archivées)
        </Typography>
        {/* Debug: Bouton pour recharger les utilisateurs */}
        <Button
          variant="outlined"
          size="small"
          onClick={async () => {
            console.log('🔄 Rechargement manuel des utilisateurs...');
            await loadUsers();
            console.log('📊 Utilisateurs après rechargement:', users);
            console.log('🔍 Détail des utilisateurs:');
            users.forEach((user, index) => {
              console.log(`${index + 1}. ${user.firstName} ${user.lastName} (${user.role}) - ID: ${user.id}`);
            });
          }}
          sx={{ mt: 1 }}
        >
          Recharger utilisateurs (Debug)
        </Button>
        <Button
          variant="outlined"
          size="small"
          onClick={async () => {
            console.log('🧪 Test d\'accès direct à la table users...');
            try {
              const { data, error } = await supabase
                .from('users')
                .select('*')
                .order('created_at', { ascending: false });
              
              if (error) {
                console.error('❌ Erreur accès direct:', error);
              } else {
                console.log('✅ Accès direct réussi:', data);
                console.log('📊 Nombre d\'utilisateurs trouvés:', data?.length || 0);
                data?.forEach((user, index) => {
                  console.log(`${index + 1}. ${user.first_name} ${user.last_name} (${user.role}) - ID: ${user.id}`);
                });
              }
            } catch (err) {
              console.error('💥 Exception lors du test d\'accès direct:', err);
            }
          }}
          sx={{ mt: 1, ml: 1 }}
        >
          Test Accès Direct (Debug)
        </Button>
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
                    value={selectedRepair.status || ''}
                    label="Statut"
                    onChange={(e) => {
                      if (selectedRepair) {
                        setSelectedRepair({
                          ...selectedRepair,
                          status: e.target.value
                        });
                      }
                    }}
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
                    value={selectedRepair.assignedTechnicianId || ''}
                    label="Technicien assigné"
                    onChange={(e) => {
                      if (selectedRepair) {
                        setSelectedRepair({
                          ...selectedRepair,
                          assignedTechnicianId: e.target.value || undefined
                        });
                      }
                    }}
                  >
                    <MenuItem value="">Aucun</MenuItem>
                    {users
                      .filter(user => user.role === 'technician')
                      .map((user) => (
                        <MenuItem key={user.id} value={user.id}>
                          {`${user.firstName} ${user.lastName}`}
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

      {/* Dialog nouvelle réparation amélioré */}
      <Dialog 
        open={newRepairDialogOpen} 
        onClose={() => {
          setNewRepairDialogOpen(false);
          resetNewRepairForm();
        }} 
        maxWidth="lg" 
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography variant="h6">Nouvelle réparation</Typography>
            <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
              <Tab label="Réparation" />
              <Tab label="Nouveau client" />
              <Tab label="Nouvel appareil" />
            </Tabs>
          </Box>
        </DialogTitle>
        <DialogContent>
          {activeTab === 0 && (
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12}>
                <Alert severity="info" sx={{ mb: 2 }}>
                  Remplissez les informations de base pour créer une nouvelle réparation.
                  Vous pouvez également créer un nouveau client ou un nouvel appareil si nécessaire.
                </Alert>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Client *</InputLabel>
                  <Select 
                    label="Client *"
                    value={newRepair.clientId || ''}
                    onChange={(e) => handleNewRepairChange('clientId', e.target.value)}
                  >
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
                  <InputLabel>Appareil *</InputLabel>
                  <Select 
                    label="Appareil *"
                    value={newRepair.deviceId || ''}
                    onChange={(e) => handleNewRepairChange('deviceId', e.target.value)}
                  >
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
                  label="Description du problème *"
                  multiline
                  rows={3}
                  value={newRepair.description}
                  onChange={(e) => handleNewRepairChange('description', e.target.value)}
                  placeholder="Décrivez le problème rencontré..."
                />
              </Grid>
              
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Diagnostic initial"
                  multiline
                  rows={2}
                  value={newRepair.issue}
                  onChange={(e) => handleNewRepairChange('issue', e.target.value)}
                  placeholder="Diagnostic préliminaire (optionnel)..."
                />
              </Grid>
              
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="Prix estimé (€)"
                  type="number"
                  value={newRepair.totalPrice}
                  onChange={(e) => handleNewRepairChange('totalPrice', parseFloat(e.target.value) || 0)}
                />
              </Grid>
              
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="Date d'échéance"
                  type="date"
                  value={newRepair.dueDate}
                  onChange={(e) => handleNewRepairChange('dueDate', e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Statut initial</InputLabel>
                  <Select 
                    label="Statut initial"
                    value={newRepair.status || ''}
                    onChange={(e) => handleNewRepairChange('status', e.target.value)}
                  >
                    {repairStatuses.map((status) => (
                      <MenuItem key={status.id} value={status.id}>
                        {status.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Technicien assigné</InputLabel>
                  <Select 
                    label="Technicien assigné"
                    value={newRepair.assignedTechnicianId || ''}
                    onChange={(e) => handleNewRepairChange('assignedTechnicianId', e.target.value)}
                  >
                    <MenuItem value="">Aucun technicien</MenuItem>
                    {users
                      .filter(user => user.role === 'technician' || user.role === 'admin' || user.role === 'manager')
                      .map((user) => (
                        <MenuItem key={user.id} value={user.id}>
                          {`${user.firstName} ${user.lastName} (${user.role})`}
                        </MenuItem>
                      ))}
                  </Select>
                </FormControl>
                {/* Debug: Afficher le nombre d'utilisateurs et de techniciens */}
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                  Total utilisateurs: {users.length} | Techniciens: {users.filter(user => user.role === 'technician').length}
                </Typography>
                {/* Debug détaillé des utilisateurs */}
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                  Utilisateurs: {users.map(u => `${u.firstName} ${u.lastName} (${u.role})`).join(', ')}
                </Typography>
                {/* Debug: Afficher les utilisateurs avec rôle technician, admin, ou manager */}
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                  Utilisateurs éligibles: {users.filter(user => user.role === 'technician' || user.role === 'admin' || user.role === 'manager').map(u => `${u.firstName} ${u.lastName} (${u.role})`).join(', ')}
                </Typography>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={newRepair.isUrgent}
                      onChange={(e) => handleNewRepairChange('isUrgent', e.target.checked)}
                    />
                  }
                  label="Réparation urgente"
                />
              </Grid>
            </Grid>
          )}
          
          {activeTab === 1 && (
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12}>
                <Alert severity="info" sx={{ mb: 2 }}>
                  Créez un nouveau client pour cette réparation.
                </Alert>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Prénom *"
                  value={newClient.firstName}
                  onChange={(e) => setNewClient(prev => ({ ...prev, firstName: e.target.value }))}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nom *"
                  value={newClient.lastName}
                  onChange={(e) => setNewClient(prev => ({ ...prev, lastName: e.target.value }))}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Email *"
                  type="email"
                  value={newClient.email}
                  onChange={(e) => setNewClient(prev => ({ ...prev, email: e.target.value.trim() }))}
                  error={Boolean(newClient.email && newClient.email.trim() && clients.some(c => c.email && c.email.trim().toLowerCase() === newClient.email.trim().toLowerCase()))}
                  helperText={newClient.email && newClient.email.trim() && clients.some(c => c.email && c.email.trim().toLowerCase() === newClient.email.trim().toLowerCase()) ? 
                    'Cet email existe déjà' : ''}
                  placeholder="exemple@email.com"
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Téléphone"
                  value={newClient.phone}
                  onChange={(e) => setNewClient(prev => ({ ...prev, phone: e.target.value }))}
                />
              </Grid>
              
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Adresse"
                  multiline
                  rows={2}
                  value={newClient.address}
                  onChange={(e) => setNewClient(prev => ({ ...prev, address: e.target.value }))}
                />
              </Grid>
              
              <Grid item xs={12}>
                <Button
                  variant="contained"
                  startIcon={<PersonAddIcon />}
                  onClick={handleCreateNewClient}
                  disabled={Boolean(
                    !newClient.firstName || 
                    !newClient.lastName || 
                    !newClient.email ||
                    (newClient.email && newClient.email.trim() && clients.some(c => c.email && c.email.trim().toLowerCase() === newClient.email.trim().toLowerCase()))
                  )}
                  fullWidth
                >
                  Créer le client
                </Button>
              </Grid>
            </Grid>
          )}
          
          {activeTab === 2 && (
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12}>
                <Alert severity="info" sx={{ mb: 2 }}>
                  Créez un nouvel appareil pour cette réparation.
                </Alert>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Marque *"
                  value={newDevice.brand}
                  onChange={(e) => setNewDevice(prev => ({ ...prev, brand: e.target.value }))}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Modèle *"
                  value={newDevice.model}
                  onChange={(e) => setNewDevice(prev => ({ ...prev, model: e.target.value }))}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Numéro de série (optionnel)"
                  value={newDevice.serialNumber}
                  onChange={(e) => setNewDevice(prev => ({ ...prev, serialNumber: e.target.value.trim() }))}
                  error={Boolean(newDevice.serialNumber && newDevice.serialNumber.trim() && devices.some(d => 
                    d.serialNumber && 
                    d.serialNumber.trim().toLowerCase() === newDevice.serialNumber.trim().toLowerCase()
                  ))}
                  helperText={
                    newDevice.serialNumber && newDevice.serialNumber.trim() && devices.some(d => 
                      d.serialNumber && 
                      d.serialNumber.trim().toLowerCase() === newDevice.serialNumber.trim().toLowerCase()
                    ) ? 'Ce numéro de série existe déjà' : 
                    'Laissez vide si le numéro de série n\'est pas disponible'
                  }
                  placeholder="SN123456789 (optionnel)"
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Type d'appareil *</InputLabel>
                  <Select
                    label="Type d'appareil *"
                    value={newDevice.type || ''}
                    onChange={(e) => setNewDevice(prev => ({ ...prev, type: e.target.value as any }))}
                  >
                    <MenuItem value="smartphone">Smartphone</MenuItem>
                    <MenuItem value="tablet">Tablette</MenuItem>
                    <MenuItem value="laptop">Ordinateur portable</MenuItem>
                    <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                    <MenuItem value="other">Autre</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12}>
                <Button
                  variant="contained"
                  startIcon={<DeviceHubIcon />}
                  onClick={handleCreateNewDevice}
                  disabled={Boolean(
                    !newDevice.brand || 
                    !newDevice.model ||
                    (newDevice.serialNumber && newDevice.serialNumber.trim() && devices.some(d => 
                      d.serialNumber && 
                      d.serialNumber.trim().toLowerCase() === newDevice.serialNumber.trim().toLowerCase()
                    ))
                  )}
                  fullWidth
                >
                  Créer l'appareil
                </Button>
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {
            setNewRepairDialogOpen(false);
            resetNewRepairForm();
            setActiveTab(0);
          }}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={handleCreateRepair}
            disabled={!newRepair.clientId || !newRepair.deviceId || !newRepair.description}
          >
            Créer la réparation
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog de facture */}
      {selectedRepairForInvoice && (
        <Dialog
          open={invoiceOpen}
          onClose={closeInvoice}
          maxWidth="md"
          fullWidth
        >
          <DialogTitle>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Typography variant="h6">Facture de réparation</Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <Button
                  startIcon={<PrintIcon />}
                  onClick={() => window.print()}
                  variant="outlined"
                  size="small"
                >
                  Imprimer
                </Button>
                <Button
                  startIcon={<EmailIcon />}
                  variant="outlined"
                  size="small"
                >
                  Envoyer
                </Button>
              </Box>
            </Box>
          </DialogTitle>
          <DialogContent>
            <Invoice
              open={invoiceOpen}
              sale={{
                id: selectedRepairForInvoice.id,
                clientId: selectedRepairForInvoice.clientId,
                items: [
                  {
                    id: '1',
                    type: 'service',
                    itemId: selectedRepairForInvoice.id,
                    name: `Réparation - ${selectedRepairForInvoice.description}`,
                    quantity: 1,
                    unitPrice: selectedRepairForInvoice.totalPrice,
                    totalPrice: selectedRepairForInvoice.totalPrice,
                  }
                ],
                subtotal: selectedRepairForInvoice.totalPrice,
                tax: 0,
                total: selectedRepairForInvoice.totalPrice,
                paymentMethod: 'card',
                status: 'completed',
                createdAt: selectedRepairForInvoice.createdAt,
                updatedAt: selectedRepairForInvoice.updatedAt,
              }}
              client={getClientById(selectedRepairForInvoice.clientId)}
              onClose={closeInvoice}
            />
          </DialogContent>
        </Dialog>
      )}

      {/* Dialog de confirmation de suppression */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <DeleteIcon color="error" />
            <Typography variant="h6">Confirmer la suppression</Typography>
          </Box>
        </DialogTitle>
        <DialogContent>
          {repairToDelete && (
            <Box>
              <Alert severity="warning" sx={{ mb: 2 }}>
                <Typography variant="body1" sx={{ fontWeight: 600 }}>
                  Êtes-vous sûr de vouloir supprimer cette réparation ?
                </Typography>
              </Alert>
              
              <Box sx={{ p: 2, bgcolor: 'grey.50', borderRadius: 1, mb: 2 }}>
                <Typography variant="subtitle1" gutterBottom>
                  <strong>Détails de la réparation :</strong>
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Client :</strong> {getClientById(repairToDelete.clientId)?.firstName} {getClientById(repairToDelete.clientId)?.lastName}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Appareil :</strong> {getDeviceById(repairToDelete.deviceId)?.brand} {getDeviceById(repairToDelete.deviceId)?.model}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Description :</strong> {repairToDelete.description}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Statut :</strong> {repairStatuses.find(s => s.id === repairToDelete.status)?.name}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Prix :</strong> {repairToDelete.totalPrice} €
                </Typography>
              </Box>
              
              <Alert severity="error">
                <Typography variant="body2">
                  <strong>Attention :</strong> Cette action est irréversible. Toutes les données de cette réparation seront définitivement supprimées.
                </Typography>
              </Alert>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setDeleteDialogOpen(false)}
            variant="outlined"
          >
            Annuler
          </Button>
          <Button 
            onClick={confirmDeleteRepair}
            variant="contained" 
            color="error"
            startIcon={<DeleteIcon />}
          >
            Supprimer définitivement
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Kanban;

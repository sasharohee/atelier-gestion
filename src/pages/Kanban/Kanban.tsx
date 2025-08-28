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
  Checkbox,
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
  Payment as PaymentIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useNavigate } from 'react-router-dom';
import { useAppStore } from '../../store';
import { deviceTypeColors, repairStatusColors } from '../../theme';
import { Repair, RepairStatus, Device, Client } from '../../types';
import Invoice from '../../components/Invoice';
import InterventionForm from '../../components/InterventionForm';
import { getRepairEligibleUsers, getRepairUserDisplayName } from '../../utils/userUtils';
import ClientForm from '../../components/ClientForm';
import { supabase } from '../../lib/supabase';

const Kanban: React.FC = () => {
  const navigate = useNavigate();
  const {
    repairs,
    repairStatuses,
    clients,
    devices,
    users,
    systemSettings,
    getClientById,
    getDeviceById,
    getUserById,
    updateRepair,
    addRepair,
    deleteRepair,
    addDevice,
    addClient,
    loadUsers,
    loadSystemSettings,
  } = useAppStore();

  const [selectedRepair, setSelectedRepair] = useState<Repair | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [newRepairDialogOpen, setNewRepairDialogOpen] = useState(false);
  const [invoiceOpen, setInvoiceOpen] = useState(false);
  const [selectedRepairForInvoice, setSelectedRepairForInvoice] = useState<Repair | null>(null);
  const [interventionFormOpen, setInterventionFormOpen] = useState(false);
  const [selectedRepairForIntervention, setSelectedRepairForIntervention] = useState<Repair | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [repairToDelete, setRepairToDelete] = useState<Repair | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  
  // Charger les paramètres système au montage du composant
  useEffect(() => {
    if (systemSettings.length === 0) {
      loadSystemSettings();
    }
  }, [systemSettings.length, loadSystemSettings]);

  // Fonction pour obtenir le taux de TVA configuré
  const getVatRate = () => {
    const vatSetting = systemSettings.find(s => s.key === 'vat_rate');
    return vatSetting ? parseFloat(vatSetting.value) / 100 : 0.20; // 20% par défaut
  };

  // États pour le formulaire de nouvelle réparation
  const [newRepair, setNewRepair] = useState({
    clientId: '' as string,
    deviceId: '' as string,
    description: '',
    issue: '',
    status: 'new' as string,
    isUrgent: false,
    totalPrice: 0,
    discountPercentage: 0,
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 jours par défaut
    assignedTechnicianId: '' as string,
  });

  // États pour la sélection de marque et catégorie
  const [selectedBrand, setSelectedBrand] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');

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
  const [clientFormOpen, setClientFormOpen] = useState(false);

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

  // Fonctions utilitaires pour obtenir les marques et catégories uniques
  const getUniqueBrands = () => {
    const brands = devices.map(device => device.brand);
    return [...new Set(brands)].sort();
  };

  const getUniqueCategories = () => {
    const categories = devices.map(device => device.type);
    return [...new Set(categories)].sort();
  };

  const getFilteredDevices = () => {
    return devices.filter(device => {
      const brandMatch = !selectedBrand || device.brand === selectedBrand;
      const categoryMatch = !selectedCategory || device.type === selectedCategory;
      return brandMatch && categoryMatch;
    });
  };

  // Charger les utilisateurs au montage du composant
  useEffect(() => {
    const loadUsersData = async () => {
      try {
        console.log('🔄 Chargement des utilisateurs dans le suivi des réparations...');
        await loadUsers();
        console.log('✅ Utilisateurs chargés dans le suivi des réparations');
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
    // Restaurer le style du body
    document.body.style.userSelect = '';
    
    console.log('🎯 handleDragEnd appelé avec:', result);
    
    if (!result.destination) {
      console.log('❌ Pas de destination, arrêt');
      return;
    }

    const { source, destination, draggableId } = result;
    console.log('📋 Détails du drag:', { source, destination, draggableId });
    
    if (source.droppableId === destination.droppableId) {
      console.log('⚠️ Même colonne, pas de changement de statut');
      return;
    }

    // Mettre à jour le statut de la réparation
    const repair = repairs.find(r => r.id === draggableId);
    console.log('🔍 Réparation trouvée:', repair);
    
    if (repair) {
      console.log('🔄 Mise à jour du statut de', repair.status, 'vers', destination.droppableId);
      
      // Préparer les mises à jour
      const updates: any = { status: destination.droppableId };
      
      // Si la réparation passe en "terminé" ou "restitué", retirer l'urgence et le retard
      if (destination.droppableId === 'completed' || destination.droppableId === 'returned') {
        console.log('✅ Réparation terminée/restituée - Retrait de l\'urgence et du retard');
        updates.isUrgent = false;
        // Pour le retard, on peut soit le laisser tel quel (historique) soit le retirer
        // Ici on choisit de le retirer en mettant à jour la date d'échéance
        if (repair.dueDate && new Date(repair.dueDate) < new Date()) {
          updates.dueDate = new Date(); // Mettre la date d'échéance à aujourd'hui
        }
      }
      
      updateRepair(repair.id, updates);
      
      // Notification spéciale si la réparation est déplacée vers "Restitué"
      if (destination.droppableId === 'returned') {
        const client = getClientById(repair.clientId);
        const clientName = client ? `${client.firstName} ${client.lastName}` : 'Client';
        const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
        const deviceInfo = device ? `${device.brand} ${device.model}` : 'Appareil';
        
        alert(`✅ Réparation restituée et archivée !\n\nClient: ${clientName}\nAppareil: ${deviceInfo}\n\nLa réparation a été automatiquement archivée et ne sera plus visible dans le suivi des réparations.\nVous pouvez la consulter dans la page "Archives".`);
      }
    } else {
      console.error('❌ Réparation non trouvée pour l\'ID:', draggableId);
    }
  };

  const handleEditRepair = (repair: Repair) => {
    setSelectedRepair(repair);
    setEditDialogOpen(true);
  };

  const handleSaveRepair = async () => {
    if (selectedRepair) {
      try {
        console.log('🔄 Sauvegarde de la réparation:', selectedRepair);
        
        // Récupérer les valeurs des champs du formulaire
        const form = document.querySelector('#edit-repair-form') as HTMLFormElement;
        const formData = new FormData(form);
        
        // Récupérer les valeurs des champs contrôlés
        const description = (form.querySelector('[name="description"]') as HTMLInputElement)?.value || selectedRepair.description;
        const status = selectedRepair.status; // Utiliser la valeur du state
        const assignedTechnicianId = selectedRepair.assignedTechnicianId; // Utiliser la valeur du state
        const totalPrice = parseFloat((form.querySelector('[name="totalPrice"]') as HTMLInputElement)?.value || '0');
        const issue = (form.querySelector('[name="issue"]') as HTMLInputElement)?.value || selectedRepair.issue;
        const dueDate = (form.querySelector('[name="dueDate"]') as HTMLInputElement)?.value || selectedRepair.dueDate?.toISOString().split('T')[0];
        const isUrgent = (form.querySelector('[name="isUrgent"]') as HTMLInputElement)?.checked || selectedRepair.isUrgent;
        
        // Préparer les mises à jour de base
        const updates: any = {
          description,
          status,
          assignedTechnicianId,
          totalPrice,
          issue,
          dueDate: dueDate ? new Date(dueDate) : selectedRepair.dueDate,
          isUrgent,
        };
        
        // Si la réparation passe en "terminé" ou "restitué", retirer l'urgence et le retard
        if (status === 'completed' || status === 'returned') {
          console.log('✅ Réparation terminée/restituée - Retrait automatique de l\'urgence et du retard');
          updates.isUrgent = false;
          // Pour le retard, mettre la date d'échéance à aujourd'hui si elle est en retard
          if (updates.dueDate && new Date(updates.dueDate) < new Date()) {
            updates.dueDate = new Date();
          }
        }
        
        console.log('📤 Mise à jour avec:', updates);
        
        await updateRepair(selectedRepair.id, updates);
        
        setEditDialogOpen(false);
        setSelectedRepair(null);
        
        console.log('✅ Réparation mise à jour avec succès');
        alert('✅ Réparation mise à jour avec succès !');
      } catch (error) {
        console.error('❌ Erreur lors de la mise à jour:', error);
        alert('❌ Erreur lors de la mise à jour de la réparation');
      }
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

      // Calculer le prix final après réduction
      const originalPrice = newRepair.totalPrice;
      const discountAmount = (originalPrice * newRepair.discountPercentage) / 100;
      const finalPrice = originalPrice - discountAmount;

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
        totalPrice: finalPrice, // Prix final après réduction
        discountPercentage: newRepair.discountPercentage,
        discountAmount: discountAmount,
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
      discountPercentage: 0,
      dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      assignedTechnicianId: '' as string,
    });
    // Réinitialiser les filtres de marque et catégorie
    setSelectedBrand('');
    setSelectedCategory('');
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

  const handleCreateNewClient = async (clientFormData: any) => {
    try {
      // Vérifier si l'email existe déjà
      const existingClient = clients.find(c => c.email.toLowerCase() === clientFormData.email.toLowerCase());
      if (existingClient) {
        alert(`❌ Un client avec l'email "${clientFormData.email}" existe déjà.\n\nNom: ${existingClient.firstName} ${existingClient.lastName}\n\nVeuillez utiliser un email différent ou sélectionner le client existant.`);
        return;
      }

      const clientData: Omit<Client, 'id' | 'createdAt' | 'updatedAt'> = {
        firstName: clientFormData.firstName,
        lastName: clientFormData.lastName,
        email: clientFormData.email,
        phone: clientFormData.countryCode + clientFormData.mobile,
        address: `${clientFormData.address}${clientFormData.addressComplement ? ', ' + clientFormData.addressComplement : ''}, ${clientFormData.postalCode} ${clientFormData.city}`,
        notes: clientFormData.internalNote || '',
      };

      await addClient(clientData as Client);
      
      // Trouver le nouveau client créé dans la liste mise à jour
      const newClientCreated = clients.find(c => 
        c.firstName === clientFormData.firstName && 
        c.lastName === clientFormData.lastName && 
        c.email === clientFormData.email
      );
      
      // Sélectionner automatiquement le nouveau client
      if (newClientCreated) {
        handleNewRepairChange('clientId', newClientCreated.id);
      }
      
      // Fermer le formulaire
      setClientFormOpen(false);
      
      alert('✅ Client créé avec succès et sélectionné !');
    } catch (error: any) {
      console.error('Erreur lors de la création du client:', error);
      
      // Gestion spécifique des erreurs
      if (error.message && error.message.includes('duplicate key value violates unique constraint "clients_email_key"')) {
        alert(`❌ Un client avec l'email "${clientFormData.email}" existe déjà dans la base de données.\n\nVeuillez utiliser un email différent.`);
      } else if (error.message && error.message.includes('duplicate key')) {
        alert('❌ Un client avec ces informations existe déjà.\n\nVeuillez vérifier les données saisies.');
      } else {
        alert('❌ Erreur lors de la création du client.\n\nVeuillez vérifier les informations saisies et réessayer.');
      }
    }
  };

  // Fonctions pour gérer les factures
  const openInvoice = async (repair: Repair) => {
    try {
      // Récupérer les données fraîches de la réparation depuis la base de données
      const result = await repairService.getById(repair.id);
      if (result.success && result.data) {
        setSelectedRepairForInvoice(result.data);
        setInvoiceOpen(true);
      } else {
        console.error('Erreur lors de la récupération de la réparation:', result.error);
        // Fallback : utiliser les données locales
        setSelectedRepairForInvoice(repair);
        setInvoiceOpen(true);
      }
    } catch (error) {
      console.error('Erreur lors de l\'ouverture de la facture:', error);
      // Fallback : utiliser les données locales
      setSelectedRepairForInvoice(repair);
      setInvoiceOpen(true);
    }
  };

  const closeInvoice = () => {
    setInvoiceOpen(false);
    setSelectedRepairForInvoice(null);
  };

  // Fonctions pour gérer le bon d'intervention
  const openInterventionForm = (repair: Repair) => {
    setSelectedRepairForIntervention(repair);
    setInterventionFormOpen(true);
  };

  const closeInterventionForm = () => {
    setInterventionFormOpen(false);
    setSelectedRepairForIntervention(null);
  };

  const handlePaymentValidation = async (repair: Repair, event: React.MouseEvent) => {
    // Empêcher la propagation et le comportement par défaut
    event.preventDefault();
    event.stopPropagation();
    
    try {
      console.log('🔄 Validation du paiement pour la réparation:', repair.id);
      
      // Appeler updateRepair avec l'ID et les mises à jour
      await updateRepair(repair.id, { isPaid: !repair.isPaid });
      
      // Afficher un message de confirmation
      const message = !repair.isPaid 
        ? `✅ Paiement validé pour la réparation #${repair.id.slice(0, 8)}`
        : `❌ Paiement annulé pour la réparation #${repair.id.slice(0, 8)}`;
      
      // Vous pouvez ajouter ici une notification ou un toast
      console.log(message);
    } catch (error) {
      console.error('Erreur lors de la validation du paiement:', error);
      // Vous pouvez ajouter ici une notification d'erreur
    }
  };

  const RepairCard: React.FC<{ repair: Repair }> = ({ repair }) => {
    const client = getClientById(repair.clientId);
    const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
    const technician = repair.assignedTechnicianId ? getUserById(repair.assignedTechnicianId) : null;
    
    // Ne pas afficher le retard pour les réparations terminées ou restituées
    const isOverdue = (repair.status === 'completed' || repair.status === 'returned') 
      ? false 
      : new Date(repair.dueDate) < new Date();

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
                <IconButton 
                  size="small" 
                  onClick={(e) => { e.stopPropagation(); handleEditRepair(repair); }}
                  onMouseDown={(e) => e.stopPropagation()}
                  onTouchStart={(e) => e.stopPropagation()}
                >
                  <EditIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title="Supprimer">
                <IconButton 
                  size="small" 
                  onClick={(e) => { e.stopPropagation(); handleDeleteRepair(repair); }}
                  onMouseDown={(e) => e.stopPropagation()}
                  onTouchStart={(e) => e.stopPropagation()}
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
                      onMouseDown={(e) => e.stopPropagation()}
                      onTouchStart={(e) => e.stopPropagation()}
                    >
                      <ReceiptIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Imprimer facture">
                    <IconButton 
                      size="small" 
                      onClick={(e) => { e.stopPropagation(); openInvoice(repair); }}
                      onMouseDown={(e) => e.stopPropagation()}
                      onTouchStart={(e) => e.stopPropagation()}
                    >
                      <PrintIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title={repair.isPaid ? "Annuler le paiement" : "Valider le paiement"}>
                    <IconButton 
                      size="small" 
                      onClick={(e) => handlePaymentValidation(repair, e)}
                      onMouseDown={(e) => e.stopPropagation()}
                      onTouchStart={(e) => e.stopPropagation()}
                      sx={{ 
                        color: repair.isPaid ? 'success.main' : 'warning.main',
                        '&:hover': {
                          backgroundColor: repair.isPaid ? 'success.light' : 'warning.light',
                        }
                      }}
                    >
                      {repair.isPaid ? <CheckCircleIcon fontSize="small" /> : <PaymentIcon fontSize="small" />}
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

          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Typography variant="h6" color="primary">
                {repair.totalPrice} € TTC
              </Typography>
              {(repair.status === 'completed' || repair.status === 'returned') && (
                <Chip
                  label={repair.isPaid ? "Payé" : "Non payé"}
                  size="small"
                  color={repair.isPaid ? "success" : "warning"}
                  variant="outlined"
                  icon={repair.isPaid ? <CheckCircleIcon /> : <PaymentIcon />}
                />
              )}
            </Box>
            <Typography variant="caption" color="text.secondary">
              {safeFormatDate(repair.dueDate, 'dd/MM')}
            </Typography>
          </Box>

          {/* Bouton Bon d'intervention - uniquement pour les réparations "Nouvelle" */}
          {repair.status === 'new' && (
            <Box sx={{ mt: 1 }}>
              <Button
                variant="contained"
                size="medium"
                startIcon={<PrintIcon />}
                onClick={(e) => { e.stopPropagation(); openInterventionForm(repair); }}
                onMouseDown={(e) => e.stopPropagation()}
                onTouchStart={(e) => e.stopPropagation()}
                sx={{ 
                  width: '100%',
                  backgroundColor: '#1976d2',
                  color: 'white',
                  '&:hover': {
                    backgroundColor: '#1565c0',
                  },
                  py: 1,
                  fontSize: '0.875rem',
                  fontWeight: 600
                }}
              >
                📋 Bon d'Intervention
              </Button>
            </Box>
          )}
        </CardContent>
      </Card>
    );
  };

  const KanbanColumn: React.FC<{ status: RepairStatus }> = ({ status }) => {
    // Filtrer les réparations pour exclure celles avec le statut "returned" (archivées)
    const statusRepairs = repairs.filter(repair => repair.status === status.id && repair.status !== 'returned');
    
    // Ne pas compter les retards pour les colonnes "Terminé" et "Restitué"
    const isOverdue = statusRepairs.filter(repair => {
      try {
        // Ne pas afficher le retard pour les réparations terminées ou restituées
        if (repair.status === 'completed' || repair.status === 'returned') {
          return false;
        }
        
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
            Suivi des Réparations
          </Typography>
          <Button
            variant="outlined"
            startIcon={<ArchiveIcon />}
            onClick={() => navigate('/app/archive')}
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
          Suivi des réparations par statut - Réparations restituées automatiquement archivées
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

      {/* Tableau de suivi des réparations */}
      <DragDropContext 
        onDragEnd={handleDragEnd}
        onDragStart={() => {
          // Empêcher les interactions pendant le drag
          document.body.style.userSelect = 'none';
        }}
        onDragUpdate={() => {
          // Gérer les mises à jour pendant le drag
        }}
      >
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
            <form id="edit-repair-form">
              <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    name="description"
                    label="Description"
                    multiline
                    rows={3}
                    defaultValue={selectedRepair.description}
                    required
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControl fullWidth>
                    <InputLabel>Statut</InputLabel>
                    <Select
                      name="status"
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
                      name="assignedTechnicianId"
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
                        .filter(user => user.role === 'technician' || user.role === 'admin' || user.role === 'manager')
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
                    name="totalPrice"
                    label="Prix total"
                    type="number"
                    defaultValue={selectedRepair.totalPrice}
                    inputProps={{ min: 0, step: 0.01 }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    name="issue"
                    label="Problème"
                    multiline
                    rows={2}
                    defaultValue={selectedRepair.issue || ''}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    name="dueDate"
                    label="Date limite"
                    type="date"
                    defaultValue={selectedRepair.dueDate ? new Date(selectedRepair.dueDate).toISOString().split('T')[0] : ''}
                    InputLabelProps={{ shrink: true }}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        name="isUrgent"
                        defaultChecked={selectedRepair.isUrgent}
                      />
                    }
                    label="Urgent"
                  />
                </Grid>
              </Grid>
            </form>
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
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Marque</InputLabel>
                  <Select 
                    label="Marque"
                    value={selectedBrand}
                    onChange={(e) => {
                      setSelectedBrand(e.target.value);
                      setNewRepair(prev => ({ ...prev, deviceId: '' })); // Réinitialiser la sélection d'appareil
                    }}
                  >
                    <MenuItem value="">Toutes les marques</MenuItem>
                    {getUniqueBrands().map((brand) => (
                      <MenuItem key={brand} value={brand}>
                        {brand}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Catégorie</InputLabel>
                  <Select 
                    label="Catégorie"
                    value={selectedCategory}
                    onChange={(e) => {
                      setSelectedCategory(e.target.value);
                      setNewRepair(prev => ({ ...prev, deviceId: '' })); // Réinitialiser la sélection d'appareil
                    }}
                  >
                    <MenuItem value="">Toutes les catégories</MenuItem>
                    <MenuItem value="smartphone">Smartphone</MenuItem>
                    <MenuItem value="tablet">Tablette</MenuItem>
                    <MenuItem value="laptop">Ordinateur portable</MenuItem>
                    <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                    <MenuItem value="other">Autre</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Appareil *</InputLabel>
                  <Select 
                    label="Appareil *"
                    value={newRepair.deviceId || ''}
                    onChange={(e) => handleNewRepairChange('deviceId', e.target.value)}
                    disabled={getFilteredDevices().length === 0}
                  >
                    {getFilteredDevices().map((device) => (
                      <MenuItem key={device.id} value={device.id}>
                        {device.brand} {device.model}
                      </MenuItem>
                    ))}
                  </Select>
                  {getFilteredDevices().length === 0 && (
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                      Aucun appareil trouvé avec les filtres sélectionnés
                    </Typography>
                  )}
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
                  label="Réduction (%)"
                  type="number"
                  value={newRepair.discountPercentage}
                  onChange={(e) => handleNewRepairChange('discountPercentage', Math.max(0, Math.min(100, parseFloat(e.target.value) || 0)))}
                  inputProps={{ 
                    min: 0,
                    max: 100,
                    step: 0.1
                  }}
                />
                {newRepair.discountPercentage > 0 && (
                  <Typography variant="caption" color="success.main" sx={{ mt: 1, display: 'block' }}>
                    Prix final: {((newRepair.totalPrice * (100 - newRepair.discountPercentage)) / 100).toFixed(2)} €
                  </Typography>
                )}
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
                                          {getRepairEligibleUsers(users).map((user) => (
                        <MenuItem key={user.id} value={user.id}>
                          {getRepairUserDisplayName(user)}
                        </MenuItem>
                      ))}
                  </Select>
                </FormControl>
                {/* Debug: Afficher le nombre d'utilisateurs et de techniciens */}
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                  Total utilisateurs: {users.length} | Éligibles pour réparations: {getRepairEligibleUsers(users).length}
                </Typography>
                {/* Debug: Afficher les utilisateurs éligibles */}
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                  Utilisateurs éligibles: {getRepairEligibleUsers(users).map(u => getRepairUserDisplayName(u)).join(', ')}
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
                  Créez un nouveau client pour cette réparation avec notre formulaire complet.
                </Alert>
              </Grid>
              
              <Grid item xs={12}>
                <Button
                  variant="contained"
                  startIcon={<PersonAddIcon />}
                  onClick={() => setClientFormOpen(true)}
                  fullWidth
                  sx={{ 
                    background: 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)',
                    '&:hover': {
                      background: 'linear-gradient(135deg, #4b5563 0%, #374151 100%)',
                    }
                  }}
                >
                  Ouvrir le formulaire de création de client
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
                    !newDevice.model
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
                      unitPrice: selectedRepairForInvoice.totalPrice / (1 + getVatRate()), // Prix HT
                      totalPrice: selectedRepairForInvoice.totalPrice / (1 + getVatRate()), // Prix HT
                    }
                  ],
                subtotal: selectedRepairForInvoice.totalPrice / (1 + getVatRate()), // Prix HT calculé depuis le prix TTC
                tax: selectedRepairForInvoice.totalPrice - (selectedRepairForInvoice.totalPrice / (1 + getVatRate())), // TVA calculée
                total: selectedRepairForInvoice.totalPrice, // Prix TTC (prix affiché)
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
                  <strong>Appareil :</strong> {repairToDelete.deviceId ? getDeviceById(repairToDelete.deviceId)?.brand : 'N/A'} {repairToDelete.deviceId ? getDeviceById(repairToDelete.deviceId)?.model : ''}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Description :</strong> {repairToDelete.description}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Statut :</strong> {repairStatuses.find(s => s.id === repairToDelete.status)?.name}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Prix TTC :</strong> {repairToDelete.totalPrice} €
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

      {/* Formulaire de création de client */}
      <ClientForm
        open={clientFormOpen}
        onClose={() => setClientFormOpen(false)}
        onSubmit={handleCreateNewClient}
        existingEmails={clients.map(c => c.email).filter(Boolean)}
      />

      {/* Formulaire de bon d'intervention */}
      {selectedRepairForIntervention && (
        <InterventionForm
          repair={selectedRepairForIntervention}
          open={interventionFormOpen}
          onClose={closeInterventionForm}
        />
      )}
    </Box>
  );
};

export default Kanban;

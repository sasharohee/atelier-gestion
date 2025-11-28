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
  CircularProgress,
  Autocomplete,
  Snackbar,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Build as BuildIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
  ExpandMore as ExpandMoreIcon,
  Receipt as ReceiptIcon,
  Print as PrintIcon,
  Email as EmailIcon,
  PersonAdd as PersonAddIcon,
  DeviceHub as DeviceHubIcon,
  Archive as ArchiveIcon,
  Category as CategoryIcon,
  CheckCircle as CheckCircleIcon,
  CheckCircleOutline as CheckCircleOutlineIcon,
  ErrorOutline as ErrorOutlineIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useNavigate } from 'react-router-dom';
import { useAppStore } from '../../store';
import { deviceTypeColors, repairStatusColors } from '../../theme';
import { Repair, RepairStatus, Device, Client, DeviceType } from '../../types';
import Invoice from '../../components/Invoice';
import InterventionForm from '../../components/InterventionForm';
import { getRepairEligibleUsers, getRepairUserDisplayName } from '../../utils/userUtils';
import ClientForm from '../../components/ClientForm';
import { supabase } from '../../lib/supabase';
import { repairService } from '../../services/supabaseService';
import { deviceCategoryService } from '../../services/deviceCategoryService';
import { DeviceCategory } from '../../types/deviceManagement';
import { brandService, BrandWithCategories } from '../../services/brandService';
import { deviceModelServiceService } from '../../services/deviceModelServiceService';
import { deviceModelService } from '../../services/deviceModelService';
import { DeviceModel } from '../../types/deviceManagement';
import CategoryIconDisplay from '../../components/CategoryIconDisplay';
import CategoryIconGrid from '../../components/CategoryIconGrid';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR, getCurrencySymbol } from '../../utils/currencyUtils';
import ThermalReceiptDialog from '../../components/ThermalReceiptDialog';

const Kanban: React.FC = () => {
  const navigate = useNavigate();
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';
  const currencySymbol = getCurrencySymbol(currency);
  
  const {
    repairs,
    repairStatuses,
    clients,
    devices,
    deviceCategories,
    deviceBrands,
    deviceModels,
    deviceModelServices,
    users,
    systemSettings,
    getClientById,
    getDeviceById,
    getUserById,
    updateRepair,
    addRepair,
    addDevice,
    addDeviceModel,
    addClient,
    loadUsers,
    loadDeviceModels,
    loadDeviceModelServices,
    loadSystemSettings,
    loadRepairs,
    updateRepairPaymentStatus,
    loadDevices,
    getServicesForModel,
  } = useAppStore();

  const [selectedRepair, setSelectedRepair] = useState<Repair | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [thermalReceiptDialogOpen, setThermalReceiptDialogOpen] = useState(false);
  const [thermalReceiptRepair, setThermalReceiptRepair] = useState<Repair | null>(null);
  
  // État pour le formulaire de modification (comme newRepair mais pour l'édition)
  const [editRepair, setEditRepair] = useState({
    clientId: '' as string,
    deviceId: '' as string,
    description: '',
    issue: '',
    status: 'new' as string,
    isUrgent: false,
    totalPrice: 0,
    discountPercentage: 0,
    deposit: 0, // Acompte payé par le client
    depositPaymentMethod: 'cash' as 'cash' | 'card' | 'transfer' | 'check' | 'payment_link', // Mode de paiement de l'acompte
    finalPaymentMethod: '' as '' | 'cash' | 'card' | 'transfer' | 'check' | 'payment_link', // Mode de paiement du solde final
    paymentMethod: 'cash' as 'cash' | 'card' | 'transfer' | 'check' | 'payment_link', // Mode de paiement (pour compatibilité)
    isPaid: false, // Statut de paiement
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    assignedTechnicianId: '' as string,
    selectedServices: [] as string[],
  });

  // État pour le bon d'intervention dans le formulaire de modification
  const [editInterventionData, setEditInterventionData] = useState({
    technicianName: '',
    deviceCondition: '',
    visibleDamages: '',
    missingParts: '',
    passwordProvided: false,
    dataBackup: false,
    accessConfirmed: false,
    clientAuthorizesRepair: false,
    clientAuthorizesDataAccess: false,
    clientAuthorizesReplacement: false,
    initialDiagnosis: '',
    proposedSolution: '',
    estimatedDuration: '',
    dataLossRisk: false,
    dataLossRiskDetails: '',
    cosmeticChanges: false,
    cosmeticChangesDetails: '',
    warrantyVoid: false,
    warrantyVoidDetails: '',
    additionalNotes: '',
    specialInstructions: '',
    termsAccepted: false,
    liabilityAccepted: false,
    authType: '',
    accessCode: '',
    patternPoints: [] as number[],
    patternDescription: '',
    securityInfo: '',
    backupBeforeAccess: false,
  });
  const [newRepairDialogOpen, setNewRepairDialogOpen] = useState(false);
  const [invoiceOpen, setInvoiceOpen] = useState(false);
  const [selectedRepairForInvoice, setSelectedRepairForInvoice] = useState<Repair | null>(null);
  const [interventionFormOpen, setInterventionFormOpen] = useState(false);
  const [selectedRepairForIntervention, setSelectedRepairForIntervention] = useState<Repair | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  
  // États pour le bon d'intervention
  const [interventionData, setInterventionData] = useState({
    technicianName: '',
    deviceCondition: '',
    visibleDamages: '',
    missingParts: '',
    passwordProvided: false,
    dataBackup: false,
    initialDiagnosis: '',
    proposedSolution: '',
    estimatedDuration: '',
    dataLossRisk: false,
    dataLossRiskDetails: '',
    cosmeticChanges: false,
    cosmeticChangesDetails: '',
    warrantyVoid: false,
    warrantyVoidDetails: '',
    clientAuthorizesRepair: false,
    clientAuthorizesDataAccess: false,
    clientAuthorizesReplacement: false,
    additionalNotes: '',
    specialInstructions: '',
    termsAccepted: true, // Coché par défaut
    liabilityAccepted: true, // Coché par défaut
    // Nouveaux champs pour le système de schéma et mots de passe
    authType: '',
    accessCode: '',
    patternPoints: [] as number[],
    patternDescription: '',
    securityInfo: '',
    accessConfirmed: false,
    backupBeforeAccess: false,
  });

  // Charger les paramètres système au montage du composant
  useEffect(() => {
    if (systemSettings.length === 0) {
      loadSystemSettings();
    }
  }, [systemSettings.length, loadSystemSettings]);

  // Charger les catégories depuis la base de données
  useEffect(() => {
    const loadCategories = async () => {
      try {
        setCategoriesLoading(true);
        const result = await deviceCategoryService.getAll();
        if (result.success && result.data) {
          setDbCategories(result.data);
        } else {
          console.warn('⚠️ Aucune catégorie d\'appareil trouvée ou erreur:', result.error);
          setDbCategories([]);
        }
      } catch (error) {
        console.error('❌ Erreur lors du chargement des catégories d\'appareils:', error);
        setDbCategories([]);
      } finally {
        setCategoriesLoading(false);
      }
    };

    loadCategories();
  }, []);

  // Charger les marques depuis la base de données
  useEffect(() => {
    const loadBrands = async () => {
      try {
        setBrandsLoading(true);
        const brands = await brandService.getAll();
        setDbBrands(brands);
      } catch (error) {
        console.error('❌ Erreur lors du chargement des marques:', error);
        setDbBrands([]);
      } finally {
        setBrandsLoading(false);
      }
    };

    loadBrands();
  }, []);

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
    deposit: 0, // Acompte payé par le client
    paymentMethod: 'cash' as 'cash' | 'card' | 'transfer' | 'check' | 'payment_link', // Mode de paiement
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 jours par défaut
    assignedTechnicianId: '' as string,
    selectedServices: [] as string[], // Services sélectionnés pour le modèle
  });

  // États pour la sélection de marque et catégorie
  const [selectedBrand, setSelectedBrand] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  
  // État pour les catégories depuis la base de données
  const [dbCategories, setDbCategories] = useState<DeviceCategory[]>([]);
  const [categoriesLoading, setCategoriesLoading] = useState(true);
  
  // État pour les marques depuis la base de données
  const [dbBrands, setDbBrands] = useState<BrandWithCategories[]>([]);
  const [brandsLoading, setBrandsLoading] = useState(true);

  // États pour le nouveau modèle (format DeviceManagement)
  const [newModel, setNewModel] = useState({
    name: '',
    description: '',
    brandId: '',
    categoryId: '',
    isActive: true,
  });

  // États pour les nouveaux éléments
  const [newCategory, setNewCategory] = useState({
    name: '',
    description: '',
    icon: 'category',
    isActive: true
  });

  const [newBrand, setNewBrand] = useState({
    name: '',
    description: '',
    categoryIds: [] as string[],
    isActive: true
  });
  
  // États pour les dialogues
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // États pour le nouveau client
  const [newClient, setNewClient] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    address: '',
  });
  const [clientFormOpen, setClientFormOpen] = useState(false);
  const [categoryDialogOpen, setCategoryDialogOpen] = useState(false);
  const [brandDialogOpen, setBrandDialogOpen] = useState(false);
  
  // État pour la notification de succès
  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');

  const getStatusColor = (status: string) => {
    return repairStatusColors[status as keyof typeof repairStatusColors] || '#757575';
  };

  const getDeviceTypeIcon = (type: string) => {
    // Retourner toujours une clé à molette pour toutes les réparations
    return <BuildIcon />;
  };

  const getDeviceTypeColor = (type: string) => {
    return deviceTypeColors[type as keyof typeof deviceTypeColors] || '#757575';
  };

  // Fonction pour obtenir le label lisible de la catégorie d'appareil
  const getDeviceTypeLabel = (type: string) => {
    const typeLabels: { [key: string]: string } = {
      'smartphone': 'Smartphone',
      'smartphones': 'Smartphones',
      'phone': 'Téléphone',
      'mobile': 'Mobile',
      'tablet': 'Tablette',
      'tablets': 'Tablettes',
      'laptop': 'Ordinateur portable',
      'laptops': 'Ordinateurs portables',
      'notebook': 'Ordinateur portable',
      'desktop': 'Ordinateur fixe',
      'desktops': 'Ordinateurs fixes',
      'pc': 'PC',
      'computer': 'Ordinateur',
      'other': 'Autre',
      'others': 'Autres'
    };
    
    return typeLabels[type.toLowerCase()] || type;
  };

  // Fonctions utilitaires pour obtenir les marques et catégories uniques
  const getUniqueBrands = () => {
    // Utiliser les marques de la base de données (comme DeviceManagement)
    let filteredBrands = dbBrands.filter(brand => brand.isActive);
    
    // Si une catégorie est sélectionnée, filtrer les marques par cette catégorie
    if (selectedCategory) {
      // Chercher la catégorie par nom
      const category = dbCategories.find(c => c.name === selectedCategory);
      
      if (category) {
        // Filtrer les marques qui ont cette catégorie dans leurs catégories associées
        filteredBrands = filteredBrands.filter(brand => 
          brand.categories.some(cat => cat.id === category.id)
        );
      }
    }
    
    const brandNames = filteredBrands.map(brand => brand.name);
    return Array.from(new Set(brandNames)).sort();
  };

  const getUniqueCategories = () => {
    // Utiliser les catégories de la base de données (comme DeviceManagement)
    if (dbCategories && dbCategories.length > 0) {
      return dbCategories
        .filter(category => category.isActive)
        .map(category => category.name)
        .sort();
    }
    
    // Fallback vers les catégories du store si pas de données en base
    if (deviceCategories && deviceCategories.length > 0) {
      return deviceCategories
        .filter(category => category.isActive)
        .map(category => category.name)
        .sort();
    }
    
    // Dernier fallback vers les catégories par défaut du store
    return [
      'Smartphones',
      'Tablettes', 
      'Ordinateurs portables',
      'Ordinateurs fixes'
    ].sort();
  };

  const getFilteredModels = () => {
    // Utiliser les modèles du store centralisé
    const filtered = deviceModels.filter(model => {
      // Filtrage par marque - essayer les deux propriétés possibles
      const brandMatch = !selectedBrand || model.brandName === selectedBrand || (model as any).brand === selectedBrand;
      
      // Filtrage par catégorie - essayer les deux propriétés possibles
      const categoryMatch = !selectedCategory || model.categoryName === selectedCategory || (model as any).type === selectedCategory;
      
      const isActive = model.isActive;
      const finalMatch = brandMatch && categoryMatch && isActive;
      
      return finalMatch;
    });
    
    return filtered;
  };

  // Fonction pour récupérer les services associés au modèle sélectionné
  const getServicesForSelectedModel = () => {
    if (!newRepair.deviceId) {
      return [];
    }
    
    // Utiliser deviceModelServices du store en priorité, sinon localDeviceModelServices
    const servicesToUse = deviceModelServices.length > 0 ? deviceModelServices : localDeviceModelServices;
    
    const filteredServices = servicesToUse.filter(service => 
      service.device_model_id === newRepair.deviceId || 
      service.deviceModelId === newRepair.deviceId ||
      (service as any).device_model_id === newRepair.deviceId
    );
    
    return filteredServices;
  };

  const getServicesForEditModel = () => {
    if (!editRepair.deviceId) {
      return [];
    }
    
    // Utiliser deviceModelServices du store en priorité, sinon localDeviceModelServices
    const servicesToUse = deviceModelServices.length > 0 ? deviceModelServices : localDeviceModelServices;
    
    const filteredServices = servicesToUse.filter(service => 
      service.device_model_id === editRepair.deviceId || 
      service.deviceModelId === editRepair.deviceId ||
      (service as any).device_model_id === editRepair.deviceId
    );
    return filteredServices;
  };

  // Charger les utilisateurs au montage du composant
  useEffect(() => {
    const loadUsersData = async () => {
      try {
        await loadUsers();
      } catch (error) {
        console.error('❌ Erreur lors du chargement des utilisateurs:', error);
      }
    };
    
    loadUsersData();
  }, [loadUsers]); // Retirer 'users' des dépendances pour éviter la boucle infinie

  // Charger les modèles d'appareils au montage du composant
  useEffect(() => {
    const loadModelsData = async () => {
      try {
        await loadDeviceModels();
      } catch (error) {
        console.error('❌ Erreur lors du chargement des modèles d\'appareils:', error);
      }
    };
    
    loadModelsData();
  }, [loadDeviceModels]);

  // État local pour les services par modèle
  const [localDeviceModelServices, setLocalDeviceModelServices] = useState([]);

  // Charger les services par modèle au montage du composant et synchroniser avec le store
  useEffect(() => {
    const loadServicesData = async () => {
      try {
        const result = await deviceModelServiceService.getAll();
        if (result.success && result.data) {
          setLocalDeviceModelServices(result.data);
        } else {
          console.warn('⚠️ Aucun service par modèle trouvé ou erreur:', result.error);
          setLocalDeviceModelServices([]);
        }
      } catch (error) {
        console.error('❌ Erreur lors du chargement des services par modèle:', error);
        setLocalDeviceModelServices([]);
      }
    };
    
    loadServicesData();
  }, []);

  // Synchroniser localDeviceModelServices avec deviceModelServices du store
  useEffect(() => {
    if (deviceModelServices.length > 0) {
      setLocalDeviceModelServices(deviceModelServices);
    }
  }, [deviceModelServices]);

  // Debug: Afficher les informations des utilisateurs quand ils changent (sans recharger)
  useEffect(() => {
    if (users.length > 0) {
    }
  }, [users]);

  // Mettre à jour automatiquement le prix estimé quand les services sélectionnés changent
  useEffect(() => {
    if (newRepair.selectedServices.length > 0) {
      const selectedServicesData = getServicesForSelectedModel().filter(service => 
        newRepair.selectedServices.includes(service.id)
      );
      const servicesTotalPrice = selectedServicesData.reduce((sum, service) => 
        sum + (service.effective_price || service.effectivePrice || 0), 0);
      
      // Mettre à jour le prix estimé avec le prix des services
      setNewRepair(prev => ({
        ...prev,
        totalPrice: servicesTotalPrice
      }));
    } else {
      // Si aucun service sélectionné, remettre le prix à 0
      setNewRepair(prev => ({
        ...prev,
        totalPrice: 0
      }));
    }
  }, [newRepair.selectedServices, newRepair.deviceId]);

  // Mettre à jour automatiquement le prix estimé pour le formulaire de modification
  useEffect(() => {
    if (editRepair.selectedServices.length > 0) {
      const selectedServicesData = getServicesForEditModel().filter(service => 
        editRepair.selectedServices.includes(service.id)
      );
      const servicesTotalPrice = selectedServicesData.reduce((sum, service) => 
        sum + (service.effective_price || service.effectivePrice || 0), 0);
      
      // Mettre à jour le prix estimé avec le prix des services
      setEditRepair(prev => ({
        ...prev,
        totalPrice: servicesTotalPrice
      }));
    }
    // Ne pas remettre le prix à 0 si aucun service n'est sélectionné
    // Garder le prix existant de la réparation
  }, [editRepair.selectedServices, editRepair.deviceId]);

  // Calculer le prix total (prix de base + services) pour l'affichage
  const calculateTotalPrice = () => {
    const basePrice = newRepair.totalPrice; // Prix saisi manuellement ou prix des services
    const selectedServicesData = getServicesForSelectedModel().filter(service => 
      newRepair.selectedServices.includes(service.id)
    );
    const servicesTotalPrice = selectedServicesData.reduce((sum, service) => 
      sum + (service.effective_price || service.effectivePrice || 0), 0);
    
    return basePrice + servicesTotalPrice;
  };


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
    
    if (!result.destination) {
      return;
    }

    const { source, destination, draggableId } = result;
    
    if (source.droppableId === destination.droppableId) {
      return;
    }

    // Mettre à jour le statut de la réparation
    const repair = repairs.find(r => r.id === draggableId);
    
    if (repair) {
      
      // Préparer les mises à jour
      const updates: any = { status: destination.droppableId };
      
      // Si la réparation passe en "terminé" ou "restitué", retirer l'urgence et le retard
      if (destination.droppableId === 'completed' || destination.droppableId === 'returned') {
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

  const handleEditRepair = async (repair: Repair) => {
    // Recharger la réparation complète depuis la base de données pour avoir les services à jour
    const repairResult = await repairService.getById(repair.id);
    
    if (!repairResult.success || !('data' in repairResult) || !repairResult.data) {
      console.error('❌ Erreur lors du rechargement de la réparation:', repairResult);
      alert('Erreur lors du chargement de la réparation');
      return;
    }
    
    const repairWithServices = repairResult.data;
    
    setSelectedRepair(repairWithServices);
    
    // S'assurer que les données sont chargées avant d'initialiser le formulaire
    if (deviceModels.length === 0) {
      await loadDeviceModels();
    }
    
    // Toujours recharger les services pour s'assurer qu'ils sont à jour
    await loadDeviceModelServices();
    
    // Recharger aussi les services locaux
    try {
      const { deviceModelServiceService } = await import('../../services/deviceModelServiceService');
      const result = await deviceModelServiceService.getAll();
      if (result.success && result.data) {
        setLocalDeviceModelServices(result.data);
      }
    } catch (error) {
      console.error('❌ Erreur lors du rechargement des services:', error);
    }
    
    // Attendre un tick pour que les données soient mises à jour
    setTimeout(() => {
      initializeEditForm(repairWithServices);
    }, 100);
    
    setEditDialogOpen(true);
  };

  const handleOpenThermalReceipt = (repair: Repair) => {
    setThermalReceiptRepair(repair);
    setThermalReceiptDialogOpen(true);
  };

  const handleSaveRepair = async () => {
    if (selectedRepair) {
      try {
        
        // Calculer le prix final avec réduction
        const totalBeforeDiscount = editRepair.totalPrice;
        const discountAmount = (totalBeforeDiscount * editRepair.discountPercentage) / 100;
        const finalPrice = totalBeforeDiscount - discountAmount;
        
        // Préparer les services pour la réparation
        const selectedServicesData = getServicesForEditModel().filter(service => 
          editRepair.selectedServices.includes(service.id)
        );
        const repairServices = selectedServicesData.map(service => ({
          id: crypto.randomUUID(),
          serviceId: service.service_id || service.serviceId,
          quantity: 1,
          price: service.effective_price || service.effectivePrice || 0,
        }));
        
        // Préparer les mises à jour de base
        const updates: any = {
          clientId: editRepair.clientId,
          deviceId: selectedRepair.deviceId, // Garder l'ID de l'appareil existant
          description: editRepair.description,
          status: editRepair.status,
          assignedTechnicianId: editRepair.assignedTechnicianId || undefined,
          totalPrice: finalPrice,
          issue: editRepair.issue,
          dueDate: new Date(editRepair.dueDate),
          isUrgent: editRepair.isUrgent,
          discountPercentage: editRepair.discountPercentage,
          discountAmount: discountAmount,
          deposit: editRepair.deposit || 0, // Acompte payé par le client
          depositPaymentMethod: editRepair.depositPaymentMethod || undefined, // Mode de paiement de l'acompte (convertir chaîne vide en undefined)
          finalPaymentMethod: editRepair.finalPaymentMethod && editRepair.finalPaymentMethod.trim() !== '' ? editRepair.finalPaymentMethod : undefined, // Mode de paiement du solde final (convertir chaîne vide en undefined)
          paymentMethod: editRepair.paymentMethod || 'cash', // Mode de paiement (pour compatibilité)
          services: repairServices,
        };
        
        // Si la réparation passe en "terminé" ou "restitué", retirer l'urgence et le retard
        if (editRepair.status === 'completed' || editRepair.status === 'returned') {
          updates.isUrgent = false;
          // Pour le retard, mettre la date d'échéance à aujourd'hui si elle est en retard
          if (updates.dueDate && new Date(updates.dueDate) < new Date()) {
            updates.dueDate = new Date();
          }
        }
        
        
        // Vérifier que le statut est bien défini
        if (!updates.status) {
          console.error('❌ ERREUR: Le statut est undefined dans les updates!');
          alert('❌ Erreur: Le statut n\'est pas défini. Veuillez sélectionner un statut.');
          return;
        }
        
        // Mettre à jour la réparation
        await updateRepair(selectedRepair.id, updates);
        
        // Attendre un peu pour que le store se mette à jour
        await new Promise(resolve => setTimeout(resolve, 300));
        
        // Recharger les réparations pour mettre à jour le kanban
        await loadRepairs();
        
        // Attendre encore un peu pour que le rechargement soit terminé
        await new Promise(resolve => setTimeout(resolve, 300));
        
        // Vérifier que le statut a bien été mis à jour
        const updatedRepair = repairs.find(r => r.id === selectedRepair.id);
        
        if (updatedRepair?.status !== updates.status) {
          console.error('❌ ERREUR: Le statut n\'a pas été mis à jour correctement!');
          console.error('❌ Statut attendu:', updates.status);
          console.error('❌ Statut actuel:', updatedRepair?.status);
          // Essayer de recharger une dernière fois
          await loadRepairs();
        }
        
        setEditDialogOpen(false);
        setSelectedRepair(null);
        
        alert('✅ Réparation mise à jour avec succès !');
      } catch (error) {
        console.error('❌ Erreur lors de la mise à jour:', error);
        alert('❌ Erreur lors de la mise à jour de la réparation');
      }
    }
  };

  const handleTogglePayment = async (repair: Repair, e: React.MouseEvent) => {
    e.stopPropagation();
    
    try {
      const newPaymentStatus = !repair.isPaid;
      
      // Mise à jour optimiste immédiate de l'interface utilisateur
      // Mettre à jour directement l'état des réparations dans le store
      updateRepairPaymentStatus(repair.id, newPaymentStatus);
      
      // Afficher un message de succès immédiatement
      alert(newPaymentStatus ? '✅ Paiement validé avec succès !' : '✅ Validation du paiement annulée !');
      
      // Essayer la mise à jour via le service en arrière-plan (optionnel)
      try {
        const result = await repairService.updatePaymentStatus(repair.id, newPaymentStatus);
        
        if (result.success) {
        } else {
          // Mise à jour échouée en arrière-plan, mais l'interface est mise à jour
        }
      } catch (backgroundError) {
        // Erreur en arrière-plan ignorée, l'interface reste mise à jour
      }
      
    } catch (error) {
      console.error('Erreur lors de la mise à jour du paiement:', error);
      
      // En cas d'erreur, restaurer l'état précédent
      await loadRepairs();
      alert('❌ Erreur lors de la mise à jour du paiement');
    }
  };

  const handleValidateDeposit = async (repair: Repair) => {
    try {
      if (!repair.deposit || repair.deposit === 0) {
        alert('⚠️ Aucun acompte n\'a été défini pour cette réparation.');
        return;
      }

      const confirmMessage = `Confirmer la validation du paiement de l'acompte de ${formatFromEUR(repair.deposit, currency)} ?`;
      if (!window.confirm(confirmMessage)) {
        return;
      }

      
      // Enregistrer le paiement dans l'historique
      try {
        await repairService.addPayment(repair.id, {
          paymentType: 'deposit',
          amount: repair.deposit,
          paymentMethod: repair.depositPaymentMethod || repair.paymentMethod || 'cash',
          paymentDate: new Date(),
          notes: 'Acompte validé'
        });
        
      } catch (error) {
        console.error('⚠️ Erreur lors de l\'enregistrement du paiement:', error);
        // Continuer même si l'enregistrement échoue
      }

      // Recharger les réparations pour refléter les changements
      await loadRepairs();
      
      // Mettre à jour le statut local
      setDepositValidated(prev => ({
        ...prev,
        [repair.id]: true
      }));
      
      alert(`✅ Paiement de l'acompte de ${formatFromEUR(repair.deposit, currency)} validé avec succès !`);
      
    } catch (error) {
      console.error('❌ Erreur lors de la validation de l\'acompte:', error);
      alert('❌ Erreur lors de la validation du paiement. Veuillez réessayer.');
    }
  };

  const handleUnvalidateDeposit = async (repair: Repair) => {
    try {
      if (!repair.deposit || repair.deposit === 0) {
        alert('⚠️ Aucun acompte n\'a été défini pour cette réparation.');
        return;
      }

      const confirmMessage = `Confirmer la dévalidation du paiement de l'acompte de ${formatFromEUR(repair.deposit, currency)} ?`;
      if (!window.confirm(confirmMessage)) {
        return;
      }

      
      // Récupérer les paiements pour trouver celui de type 'deposit'
      try {
        const paymentsResult = await repairService.getPaymentsByRepairId(repair.id);
        
        if (paymentsResult.success && 'data' in paymentsResult && paymentsResult.data) {
          // Trouver le paiement de type 'deposit'
          const depositPayment = paymentsResult.data.find(
            (payment: any) => payment.paymentType === 'deposit'
          );
          
          if (depositPayment) {
            // Supprimer le paiement de l'historique
            const deleteResult = await repairService.deletePayment(depositPayment.id);
            
            if (deleteResult.success) {
            } else {
              console.error('⚠️ Erreur lors de la suppression du paiement:', deleteResult);
            }
          } else {
            console.warn('⚠️ Aucun paiement d\'acompte trouvé dans l\'historique');
          }
        } else {
          console.warn('⚠️ Impossible de récupérer les paiements');
        }
      } catch (error) {
        console.error('⚠️ Erreur lors de la suppression du paiement:', error);
        // Continuer même si la suppression échoue
      }

      // Recharger les réparations pour refléter les changements
      await loadRepairs();
      
      // Mettre à jour le statut local
      setDepositValidated(prev => ({
        ...prev,
        [repair.id]: false
      }));
      
      alert(`✅ Paiement de l'acompte de ${formatFromEUR(repair.deposit, currency)} dévalidé avec succès !`);
      
    } catch (error) {
      console.error('❌ Erreur lors de la dévalidation de l\'acompte:', error);
      alert('❌ Erreur lors de la dévalidation du paiement. Veuillez réessayer.');
    }
  };

  // Vérifier si l'acompte est validé (si un paiement de type 'deposit' existe)
  const [depositValidated, setDepositValidated] = useState<Record<string, boolean>>({});
  
  useEffect(() => {
    // Charger le statut de validation des acomptes pour toutes les réparations
    const loadDepositStatus = async () => {
      const statusMap: Record<string, boolean> = {};
      
      // Traiter les réparations en parallèle pour améliorer les performances
      const statusPromises = repairs
        .filter(repair => repair.deposit && repair.deposit > 0)
        .map(async (repair) => {
          try {
            const paymentsResult = await repairService.getPaymentsByRepairId(repair.id);
            if (paymentsResult.success && 'data' in paymentsResult && paymentsResult.data) {
              const hasDepositPayment = paymentsResult.data.some(
                (payment: any) => payment.paymentType === 'deposit'
              );
              return { repairId: repair.id, validated: hasDepositPayment };
            }
            return { repairId: repair.id, validated: false };
          } catch (error) {
            console.error(`Erreur lors du chargement du statut pour la réparation ${repair.id}:`, error);
            return { repairId: repair.id, validated: false };
          }
        });
      
      const results = await Promise.all(statusPromises);
      results.forEach(({ repairId, validated }) => {
        statusMap[repairId] = validated;
      });
      
      setDepositValidated(statusMap);
    };
    
    if (repairs.length > 0) {
      loadDepositStatus();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [repairs.length]); // Ne se déclenche que lorsque le nombre de réparations change

  const handleCreateRepair = async () => {
    try {
      if (!newRepair.clientId || !newRepair.deviceId || !newRepair.description) {
        alert('Veuillez remplir tous les champs obligatoires');
        return;
      }

      // Vérifier que le modèle sélectionné existe
      const selectedModel = deviceModels.find(m => m.id === newRepair.deviceId);
      if (!selectedModel) {
        throw new Error('Modèle sélectionné non trouvé');
      }

      // Créer un appareil à partir du modèle sélectionné
      // Utiliser un UUID pour garantir l'unicité du numéro de série
      const uniqueSerialNumber = `REPAIR-${crypto.randomUUID()}`;
      const deviceData: Omit<Device, 'id' | 'createdAt' | 'updatedAt'> = {
        brand: selectedModel.brandName || (selectedModel as any).brand || 'Unknown',
        model: selectedModel.model || 'Unknown',
        serialNumber: uniqueSerialNumber, // Numéro de série unique pour la réparation
        type: (selectedModel.categoryName || (selectedModel as any).type || 'other') as DeviceType,
        specifications: {},
      };

      
      // Utiliser directement deviceService.create pour obtenir l'ID créé
      const { deviceService } = await import('../../services/supabaseService');
      const deviceResult = await deviceService.create(deviceData);
      
      if (!deviceResult.success || !('data' in deviceResult)) {
        throw new Error('Erreur lors de la création de l\'appareil');
      }
      
      const createdDeviceId = deviceResult.data.id;
      
      // Ajouter l'appareil au store local pour qu'il soit immédiatement disponible
      const createdDevice: Device = {
        id: deviceResult.data.id,
        brand: deviceResult.data.brand,
        model: deviceResult.data.model,
        serialNumber: deviceResult.data.serial_number,
        type: deviceResult.data.type,
        specifications: deviceResult.data.specifications,
        createdAt: new Date(deviceResult.data.created_at),
        updatedAt: new Date(deviceResult.data.updated_at),
      };
      
      // Ajouter l'appareil au store local
      await addDevice(createdDevice);

      // Calculer le prix des services sélectionnés
      const selectedServicesData = getServicesForSelectedModel().filter(service => 
        newRepair.selectedServices.includes(service.id)
      );
      const servicesTotalPrice = selectedServicesData.reduce((sum, service) => 
        sum + (service.effective_price || service.effectivePrice || 0), 0);
      
      // Calculer le prix final (prix estimé + réduction)
      // newRepair.totalPrice contient déjà le prix des services (mis à jour par useEffect)
      const totalBeforeDiscount = newRepair.totalPrice;
      const discountAmount = (totalBeforeDiscount * newRepair.discountPercentage) / 100;
      const finalPrice = totalBeforeDiscount - discountAmount;

      // Préparer les services pour la réparation
      const repairServices = selectedServicesData.map(service => ({
        id: crypto.randomUUID(),
        serviceId: service.service_id || service.serviceId,
        quantity: 1,
        price: service.effective_price || service.effectivePrice || 0,
      }));

      // Préparer les données pour Supabase (sans id, createdAt, updatedAt)
      const repairData: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'> = {
        clientId: newRepair.clientId,
        deviceId: createdDeviceId, // Utiliser l'ID de l'appareil créé
        description: newRepair.description,
        issue: newRepair.issue,
        status: newRepair.status,
        assignedTechnicianId: newRepair.assignedTechnicianId || undefined,
        estimatedDuration: 0,
        isUrgent: newRepair.isUrgent,
        totalPrice: finalPrice, // Prix final après services et réduction
        discountPercentage: newRepair.discountPercentage,
        discountAmount: discountAmount,
        deposit: newRepair.deposit || 0, // Acompte payé par le client
        paymentMethod: newRepair.paymentMethod || 'cash', // Mode de paiement
        dueDate: new Date(newRepair.dueDate),
        services: repairServices, // Services sélectionnés
        parts: [],
        isPaid: false,
      };

      
      const createdRepair = await addRepair(repairData as Repair, 'kanban'); // Marquer comme créé depuis Kanban
      
      // Recharger les réparations et les appareils pour mettre à jour l'affichage
      await loadRepairs();
      await loadDevices();
      
      // Vérifier que la réparation a bien été ajoutée au store
      
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

  const handleEditRepairChange = (field: string, value: any) => {
    if (field === 'status') {
    }
    setEditRepair(prev => {
      const updated = {
        ...prev,
        [field]: value
      };
      if (field === 'status') {
      }
      return updated;
    });
  };

  // Initialiser le formulaire de modification avec les données de la réparation
  const initializeEditForm = (repair: Repair) => {
    
    // Vérifier que les données nécessaires sont chargées
    if (deviceModels.length === 0) {
      console.warn('⚠️ Aucun modèle d\'appareil disponible');
    }
    
    if (deviceModelServices.length === 0 && localDeviceModelServices.length === 0) {
      console.warn('⚠️ Aucun service de modèle disponible - le mapping pourrait échouer');
    }
    
    const client = getClientById(repair.clientId);
    const device = getDeviceById(repair.deviceId);
    
    
    // Trouver le modèle d'appareil correspondant à l'appareil créé
    // Essayer plusieurs méthodes de comparaison
    let deviceModel = null;
    
    if (device) {
      // Méthode 1: Comparaison exacte brandName/model
      deviceModel = deviceModels.find(model => 
        model.brandName === device.brand && model.model === device.model
      );
      
      // Méthode 2: Comparaison avec fallbacks
      if (!deviceModel) {
        deviceModel = deviceModels.find(model => 
          (model.brandName || (model as any).brand) === device.brand && 
          model.model === device.model
        );
      }
      
      // Méthode 3: Comparaison insensible à la casse
      if (!deviceModel) {
        deviceModel = deviceModels.find(model => 
          (model.brandName || (model as any).brand)?.toLowerCase() === device.brand?.toLowerCase() && 
          model.model?.toLowerCase() === device.model?.toLowerCase()
        );
      }
    }
    
    // Utiliser deviceModelServices du store en priorité, sinon localDeviceModelServices
    const servicesToUse = deviceModelServices.length > 0 ? deviceModelServices : localDeviceModelServices;
    
    // Mapper les services existants - Approche simplifiée et plus robuste
    const mappedServices: string[] = [];
    
    if (repair.services && repair.services.length > 0) {
      repair.services.forEach((s, index) => {
        
        // Étape 1: Chercher d'abord par serviceId seulement (plus simple)
        const servicesByServiceId = servicesToUse.filter(dms => {
          const serviceId = dms.serviceId || (dms as any).service_id || (dms as any).serviceId;
          return serviceId === s.serviceId;
        });
        
        
        let serviceInModel = null;
        
        if (servicesByServiceId.length === 0) {
          // Aucun service trouvé par serviceId
          console.warn(`⚠️ Aucun service trouvé avec serviceId: ${s.serviceId}`);
        } else if (servicesByServiceId.length === 1) {
          // Un seul service correspond, l'utiliser directement
          serviceInModel = servicesByServiceId[0];
        } else {
          // Plusieurs services correspondent, filtrer par deviceModelId si disponible
          
          if (deviceModel) {
            const servicesByModel = servicesByServiceId.filter(dms => {
              const modelId = dms.device_model_id || (dms as any).deviceModelId || dms.deviceModelId;
              return modelId === deviceModel.id;
            });
            
            if (servicesByModel.length > 0) {
              serviceInModel = servicesByModel[0];
            } else {
              // Aucun service ne correspond au deviceModelId, utiliser le premier trouvé
              serviceInModel = servicesByServiceId[0];
              console.warn(`⚠️ Aucun service ne correspond au deviceModelId (${deviceModel.id}), utilisation du premier service trouvé:`, serviceInModel.id);
            }
          } else {
            // Pas de deviceModel, utiliser le premier service trouvé
            serviceInModel = servicesByServiceId[0];
            console.warn('⚠️ Pas de deviceModel trouvé, utilisation du premier service:', serviceInModel.id);
          }
        }
        
        if (serviceInModel) {
          mappedServices.push(serviceInModel.id);
        } else {
          console.warn(`⚠️ Service non mappé: ${s.serviceId}`);
        }
      });
    } else {
    }
    
    
    // Fallback : Si aucun service n'a été mappé mais qu'il y a des services dans la réparation,
    // essayer d'utiliser directement les serviceId comme valeurs sélectionnées
    // Cela permettra au moins d'indiquer qu'il y a des services associés
    let finalSelectedServices = mappedServices;
    
    if (mappedServices.length === 0 && repair.services && repair.services.length > 0) {
      console.warn('⚠️ Aucun service mappé, tentative de fallback avec les serviceId directs...');
      
      // Essayer de trouver les services par serviceId seulement, sans vérifier deviceModelId
      const fallbackServices: string[] = [];
      repair.services.forEach(s => {
        const foundService = servicesToUse.find(dms => {
          const serviceId = dms.serviceId || (dms as any).service_id || (dms as any).serviceId;
          return serviceId === s.serviceId;
        });
        
        if (foundService) {
          fallbackServices.push(foundService.id);
        } else {
          console.warn(`⚠️ Service non trouvé même en fallback: ${s.serviceId}`);
        }
      });
      
      if (fallbackServices.length > 0) {
        finalSelectedServices = fallbackServices;
      } else {
        console.error('❌ Échec du fallback, aucun service ne peut être mappé');
      }
    }
    
    
    setEditRepair({
      clientId: repair.clientId,
      deviceId: deviceModel?.id || '', // Utiliser l'ID du modèle, pas de l'appareil
      description: repair.description,
      issue: repair.issue || '',
      status: repair.status,
      isUrgent: repair.isUrgent,
      totalPrice: repair.totalPrice,
      discountPercentage: repair.discountPercentage || 0,
      deposit: repair.deposit || 0, // Acompte payé par le client
      depositPaymentMethod: repair.depositPaymentMethod || 'cash', // Mode de paiement de l'acompte
      finalPaymentMethod: repair.finalPaymentMethod || '', // Mode de paiement du solde final
      paymentMethod: repair.paymentMethod || 'cash', // Mode de paiement (pour compatibilité)
      isPaid: repair.isPaid || false, // Statut de paiement
      dueDate: repair.dueDate ? new Date(repair.dueDate).toISOString().split('T')[0] : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      assignedTechnicianId: repair.assignedTechnicianId || '',
      selectedServices: finalSelectedServices,
    });
    
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
      deposit: 0, // Réinitialiser l'acompte
      paymentMethod: 'cash', // Réinitialiser le mode de paiement
      dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      assignedTechnicianId: '' as string,
      selectedServices: [] as string[], // Réinitialiser les services sélectionnés
    });
    // Réinitialiser les filtres de marque et catégorie
    setSelectedBrand('');
    setSelectedCategory('');
  };

  // Fonctions pour gérer les nouveaux appareils et clients
  // Fonctions pour gérer les nouveaux modèles (format DeviceManagement)
  const handleCreateModel = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const result = await deviceModelService.create({
        name: newModel.name,
        description: newModel.description,
        brandId: newModel.brandId,
        categoryId: newModel.categoryId,
      });
      
      if (result.success) {
        // Mettre à jour la liste des modèles
        await loadDeviceModels();
        
        // Fermer le dialogue et réinitialiser le formulaire
        setModelDialogOpen(false);
        resetModelForm();
        
        // Trouver le nouveau modèle créé et le sélectionner
        const newModelCreated = deviceModels.find(d => 
          d.brandId === newModel.brandId && d.name === newModel.name
        );
        
        if (newModelCreated) {
          // Créer un appareil dans l'ancien système pour la compatibilité
          const deviceData: Omit<Device, 'id' | 'createdAt' | 'updatedAt'> = {
            brand: newModelCreated.brandName,
            model: newModelCreated.name,
            serialNumber: undefined,
            type: newModelCreated.categoryName.toLowerCase() as any,
            specifications: {},
          };
          
          await addDevice(deviceData as Device);
          
          // Trouver l'appareil créé et le sélectionner
          const newDeviceCreated = devices.find(d => 
            d.brand === newModelCreated.brandName && 
            d.model === newModelCreated.name
          );
          
          if (newDeviceCreated) {
            handleNewRepairChange('deviceId', newDeviceCreated.id);
          }
        }
        
        // Retourner à l'onglet réparation
        setActiveTab(0);
        
      } else {
        console.error('❌ Erreur lors de la création du modèle:', result.error);
        setError(result.error || 'Erreur lors de la création du modèle');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la création du modèle:', error);
      setError('Erreur lors de la création du modèle');
    } finally {
      setLoading(false);
    }
  };

  const resetModelForm = () => {
    setNewModel({
      name: '',
      description: '',
      brandId: '',
      categoryId: '',
      isActive: true,
    });
  };

  const openModelDialog = () => {
    resetModelForm();
    setModelDialogOpen(true);
  };

  const openCategoryDialog = () => {
    setNewCategory({ name: '', description: '', icon: 'category', isActive: true });
    setCategoryDialogOpen(true);
  };

  const openBrandDialog = () => {
    setNewBrand({ name: '', description: '', categoryIds: [], isActive: true });
    setBrandDialogOpen(true);
  };

  const handleCreateCategory = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!newCategory.name.trim()) {
        setError('Le nom de la catégorie est requis');
        return;
      }

      const result = await deviceCategoryService.create({
        name: newCategory.name.trim(),
        description: newCategory.description.trim(),
        icon: newCategory.icon
      });

      if (result.success && result.data) {
        // Recharger les catégories
        await loadCategories();
        
        // Fermer le dialogue et réinitialiser le formulaire
        setCategoryDialogOpen(false);
        setNewCategory({ name: '', description: '', icon: 'category' });
        
        // Sélectionner la nouvelle catégorie
        setSelectedCategory(result.data.name);
        
        alert('✅ Catégorie créée avec succès !');
      } else {
        setError(result.error || 'Erreur lors de la création de la catégorie');
      }
    } catch (error: any) {
      console.error('Erreur lors de la création de la catégorie:', error);
      setError(error.message || 'Erreur lors de la création de la catégorie');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateBrand = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!newBrand.name.trim()) {
        setError('Le nom de la marque est requis');
        return;
      }

      const result = await brandService.create({
        name: newBrand.name.trim(),
        description: newBrand.description.trim(),
        categoryIds: newBrand.categoryIds
      });

      if (result) {
        // Recharger les marques
        await loadBrands();
        
        // Fermer le dialogue et réinitialiser le formulaire
        setBrandDialogOpen(false);
        setNewBrand({ name: '', description: '', logo: '' });
        
        // Sélectionner la nouvelle marque
        setSelectedBrand(result.name);
        
        alert('✅ Marque créée avec succès !');
      } else {
        setError('Erreur lors de la création de la marque');
      }
    } catch (error: any) {
      console.error('Erreur lors de la création de la marque:', error);
      setError(error.message || 'Erreur lors de la création de la marque');
    } finally {
      setLoading(false);
    }
  };

  // Fonction pour obtenir l'icône d'une catégorie
  const getCategoryIcon = (categoryName: string, iconValue?: string) => {
    const iconType = iconValue || (categoryName || '').toLowerCase().replace(/\s+/g, '-');
    return <CategoryIconDisplay iconType={iconType} size={20} />;
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
      
      // Fermer le formulaire
      setClientFormOpen(false);
      
      // Attendre que le store soit mis à jour puis trouver et sélectionner le client créé
      setTimeout(() => {
        const newClientCreated = clients.find(c => 
          c.firstName === clientFormData.firstName && 
          c.lastName === clientFormData.lastName && 
          c.email === clientFormData.email
        );
        
        // Sélectionner automatiquement le nouveau client
        if (newClientCreated) {
          handleNewRepairChange('clientId', newClientCreated.id);
          setSnackbarMessage(`✅ Client ${clientFormData.firstName} ${clientFormData.lastName} créé avec succès et sélectionné !`);
          setSnackbarOpen(true);
        } else {
          // Si on ne trouve pas le client par email, chercher par nom
          const newClientByName = clients.find(c => 
            c.firstName === clientFormData.firstName && 
            c.lastName === clientFormData.lastName
          );
          if (newClientByName) {
            handleNewRepairChange('clientId', newClientByName.id);
            setSnackbarMessage(`✅ Client ${clientFormData.firstName} ${clientFormData.lastName} créé avec succès et sélectionné !`);
            setSnackbarOpen(true);
          }
        }
      }, 300);
    } catch (error: any) {
      console.error('Erreur lors de la création du client:', error);
      
      // Gestion spécifique des erreurs
      let errorMessage = '';
      if (error.message && error.message.includes('duplicate key value violates unique constraint "clients_email_key"')) {
        errorMessage = `❌ Un client avec l'email "${clientFormData.email}" existe déjà dans la base de données. Veuillez utiliser un email différent.`;
      } else if (error.message && error.message.includes('duplicate key')) {
        errorMessage = '❌ Un client avec ces informations existe déjà. Veuillez vérifier les données saisies.';
      } else {
        errorMessage = '❌ Erreur lors de la création du client. Veuillez vérifier les informations saisies et réessayer.';
      }
      setSnackbarMessage(errorMessage);
      setSnackbarOpen(true);
    }
  };

  // Fonctions pour gérer les factures
  const openInvoice = async (repair: Repair) => {
    try {
      // Récupérer les données fraîches de la réparation depuis la base de données
      const result = await repairService.getById(repair.id);
      if (result.success && 'data' in result && result.data) {
        setSelectedRepairForInvoice(result.data);
        setInvoiceOpen(true);
      } else {
        console.error('Erreur lors de la récupération de la réparation:', 'error' in result ? result.error : 'Erreur inconnue');
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

  // Fonction pour générer le bon d'intervention depuis l'onglet
  const handleGenerateInterventionFromTab = async () => {
    try {
      
      // Vérifier que les informations de base sont remplies
      if (!newRepair.clientId || !newRepair.deviceId || !newRepair.description) {
        alert('❌ Veuillez d\'abord remplir les informations de base dans l\'onglet "Réparation" (client, appareil, description).');
        return;
      }

      // Vérifier que les conditions légales sont acceptées
      if (!interventionData.termsAccepted || !interventionData.liabilityAccepted) {
        alert('❌ Veuillez accepter les conditions légales pour générer le bon d\'intervention.');
        return;
      }

      // Récupérer les informations du client et du modèle
      const client = getClientById(newRepair.clientId);
      const selectedModel = deviceModels.find(m => m.id === newRepair.deviceId);
      
      if (!client || !selectedModel) {
        alert('❌ Erreur : informations client ou modèle manquantes.');
        return;
      }

      // Créer un objet réparation temporaire pour le bon d'intervention
      const tempRepair: Repair = {
        id: 'temp-' + Date.now(),
        clientId: newRepair.clientId,
        deviceId: newRepair.deviceId,
        description: newRepair.description,
        issue: newRepair.issue,
        status: 'new',
        estimatedDuration: 0,
        isUrgent: newRepair.isUrgent,
        totalPrice: newRepair.totalPrice,
        dueDate: new Date(newRepair.dueDate),
        services: [],
        parts: [],
        isPaid: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      // Créer les données complètes pour le bon d'intervention
      const completeInterventionData = {
        interventionDate: new Date().toISOString().split('T')[0],
        technicianName: interventionData.technicianName,
        clientName: `${client.firstName} ${client.lastName}`,
        clientPhone: client.phone || '',
        clientEmail: client.email || '',
        deviceBrand: (selectedModel as any).brand,
        deviceModel: (selectedModel as any).model || (selectedModel as any).name,
        deviceSerialNumber: '', // Pas de numéro de série pour un modèle
        deviceType: (selectedModel as any).type,
        deviceCondition: interventionData.deviceCondition,
        visibleDamages: interventionData.visibleDamages,
        missingParts: interventionData.missingParts,
        passwordProvided: interventionData.passwordProvided,
        dataBackup: interventionData.dataBackup,
        reportedIssue: newRepair.description,
        initialDiagnosis: interventionData.initialDiagnosis,
        proposedSolution: interventionData.proposedSolution,
        estimatedCost: newRepair.totalPrice,
        estimatedDuration: interventionData.estimatedDuration,
        dataLossRisk: interventionData.dataLossRisk,
        dataLossRiskDetails: interventionData.dataLossRiskDetails,
        cosmeticChanges: interventionData.cosmeticChanges,
        cosmeticChangesDetails: interventionData.cosmeticChangesDetails,
        warrantyVoid: interventionData.warrantyVoid,
        warrantyVoidDetails: interventionData.warrantyVoidDetails,
        clientAuthorizesRepair: interventionData.clientAuthorizesRepair,
        clientAuthorizesDataAccess: interventionData.clientAuthorizesDataAccess,
        clientAuthorizesReplacement: interventionData.clientAuthorizesReplacement,
        additionalNotes: interventionData.additionalNotes,
        specialInstructions: interventionData.specialInstructions,
        termsAccepted: interventionData.termsAccepted,
        liabilityAccepted: interventionData.liabilityAccepted,
        // Nouveaux champs pour le système de schéma et mots de passe
        authType: interventionData.authType,
        accessCode: interventionData.accessCode,
        patternPoints: interventionData.patternPoints,
        patternDescription: interventionData.patternDescription,
        securityInfo: interventionData.securityInfo,
        accessConfirmed: interventionData.accessConfirmed,
        backupBeforeAccess: interventionData.backupBeforeAccess,
      };

      // Générer le PDF en utilisant la fonction du composant InterventionForm
      try {
        // Import dynamique pour éviter les problèmes de require
        const InterventionFormModule = await import('../../components/InterventionForm');
        
                  if (InterventionFormModule.generateInterventionPDF) {
            // Préparer les paramètres de l'atelier
            const workshopSettings = {
              workshop_name: systemSettings.find(s => s.key === 'workshop_name')?.value || 'Atelier de réparation',
              workshop_address: systemSettings.find(s => s.key === 'workshop_address')?.value || 'Adresse non configurée',
              workshop_phone: systemSettings.find(s => s.key === 'workshop_phone')?.value || 'Téléphone non configuré',
              workshop_email: systemSettings.find(s => s.key === 'workshop_email')?.value || 'Email non configuré',
              workshop_website: systemSettings.find(s => s.key === 'workshop_website')?.value || 'Site web non configuré',
              workshop_siret: systemSettings.find(s => s.key === 'workshop_siret')?.value || '',
              workshop_vat: systemSettings.find(s => s.key === 'workshop_vat')?.value || ''
            };
            
            InterventionFormModule.generateInterventionPDF(completeInterventionData, tempRepair, workshopSettings);
          
          alert('✅ Bon d\'intervention généré avec succès !\n\nVous pouvez maintenant créer la réparation dans l\'onglet "Réparation".');
        } else {
          throw new Error('Fonction generateInterventionPDF non trouvée');
        }
      } catch (pdfError: any) {
        console.error('❌ Erreur lors de la génération du PDF:', pdfError);
        throw new Error(`Erreur PDF: ${pdfError.message || 'Erreur inconnue'}`);
      }
      
    } catch (error) {
      console.error('❌ Erreur lors de la génération du bon d\'intervention:', error);
      alert('❌ Erreur lors de la génération du bon d\'intervention. Veuillez réessayer.');
    }
  };

  // Fonction pour générer le bon d'intervention depuis l'onglet de modification
  const handleGenerateInterventionFromEditTab = async () => {
    try {
      
      // Vérifier que les informations de base sont remplies
      if (!editRepair.clientId || !editRepair.deviceId || !editRepair.description) {
        alert('❌ Veuillez d\'abord remplir les informations de base dans l\'onglet "Réparation" (client, appareil, description).');
        return;
      }

      // Vérifier que les conditions légales sont acceptées
      if (!editInterventionData.termsAccepted || !editInterventionData.liabilityAccepted) {
        alert('❌ Veuillez accepter les conditions légales pour générer le bon d\'intervention.');
        return;
      }

      // Récupérer les informations du client et du modèle
      const client = getClientById(editRepair.clientId);
      const selectedModel = deviceModels.find(m => m.id === editRepair.deviceId);
      
      if (!client || !selectedModel) {
        alert('❌ Erreur : informations client ou modèle manquantes.');
        return;
      }

      // Créer un objet réparation temporaire pour le bon d'intervention
      const tempRepair: Repair = {
        id: 'temp-edit-' + Date.now(),
        clientId: editRepair.clientId,
        deviceId: editRepair.deviceId,
        description: editRepair.description,
        issue: editRepair.issue,
        status: editRepair.status,
        estimatedDuration: 0,
        isUrgent: editRepair.isUrgent,
        totalPrice: editRepair.totalPrice,
        dueDate: new Date(editRepair.dueDate),
        services: [],
        parts: [],
        isPaid: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      // Créer les données complètes pour le bon d'intervention
      const completeInterventionData = {
        interventionDate: new Date().toISOString().split('T')[0],
        technicianName: editInterventionData.technicianName,
        clientName: `${client.firstName} ${client.lastName}`,
        clientPhone: client.phone || '',
        clientEmail: client.email || '',
        deviceBrand: (selectedModel as any).brand,
        deviceModel: (selectedModel as any).model || (selectedModel as any).name,
        deviceSerialNumber: '', // Pas de numéro de série pour un modèle
        deviceType: (selectedModel as any).type,
        deviceCondition: editInterventionData.deviceCondition,
        visibleDamages: editInterventionData.visibleDamages,
        missingParts: editInterventionData.missingParts,
        passwordProvided: editInterventionData.passwordProvided,
        dataBackup: editInterventionData.dataBackup,
        reportedIssue: editRepair.description,
        initialDiagnosis: editInterventionData.initialDiagnosis,
        proposedSolution: editInterventionData.proposedSolution,
        estimatedCost: editRepair.totalPrice,
        estimatedDuration: editInterventionData.estimatedDuration,
        dataLossRisk: editInterventionData.dataLossRisk,
        dataLossRiskDetails: editInterventionData.dataLossRiskDetails,
        cosmeticChanges: editInterventionData.cosmeticChanges,
        cosmeticChangesDetails: editInterventionData.cosmeticChangesDetails,
        warrantyVoid: editInterventionData.warrantyVoid,
        warrantyVoidDetails: editInterventionData.warrantyVoidDetails,
        clientAuthorizesRepair: editInterventionData.clientAuthorizesRepair,
        clientAuthorizesDataAccess: editInterventionData.clientAuthorizesDataAccess,
        clientAuthorizesReplacement: editInterventionData.clientAuthorizesReplacement,
        additionalNotes: editInterventionData.additionalNotes,
        specialInstructions: editInterventionData.specialInstructions,
        termsAccepted: editInterventionData.termsAccepted,
        liabilityAccepted: editInterventionData.liabilityAccepted,
        // Nouveaux champs pour le système de schéma et mots de passe
        authType: editInterventionData.authType,
        accessCode: editInterventionData.accessCode,
        patternPoints: editInterventionData.patternPoints,
        patternDescription: editInterventionData.patternDescription,
        securityInfo: editInterventionData.securityInfo,
        accessConfirmed: editInterventionData.accessConfirmed,
        backupBeforeAccess: editInterventionData.backupBeforeAccess,
      };

      // Générer le PDF en utilisant la fonction du composant InterventionForm
      try {
        // Import dynamique pour éviter les problèmes de require
        const InterventionFormModule = await import('../../components/InterventionForm');
        
        if (InterventionFormModule.generateInterventionPDF) {
          // Préparer les paramètres de l'atelier
          const workshopSettings = {
            workshop_name: systemSettings.find(s => s.key === 'workshop_name')?.value || 'Atelier de réparation',
            workshop_address: systemSettings.find(s => s.key === 'workshop_address')?.value || 'Adresse non configurée',
            workshop_phone: systemSettings.find(s => s.key === 'workshop_phone')?.value || 'Téléphone non configuré',
            workshop_email: systemSettings.find(s => s.key === 'workshop_email')?.value || 'Email non configuré',
            workshop_website: systemSettings.find(s => s.key === 'workshop_website')?.value || 'Site web non configuré',
            workshop_siret: systemSettings.find(s => s.key === 'workshop_siret')?.value || '',
            workshop_vat: systemSettings.find(s => s.key === 'workshop_vat')?.value || ''
          };
          
          InterventionFormModule.generateInterventionPDF(completeInterventionData, tempRepair, workshopSettings);
        
          alert('✅ Bon d\'intervention généré avec succès !\n\nVous pouvez maintenant sauvegarder la réparation.');
        } else {
          throw new Error('Fonction generateInterventionPDF non trouvée');
        }
      } catch (pdfError: any) {
        console.error('❌ Erreur lors de la génération du PDF:', pdfError);
        throw new Error(`Erreur PDF: ${pdfError.message || 'Erreur inconnue'}`);
      }
      
    } catch (error) {
      console.error('❌ Erreur lors de la génération du bon d\'intervention:', error);
      alert('❌ Erreur lors de la génération du bon d\'intervention. Veuillez réessayer.');
    }
  };


  const RepairCard: React.FC<{ repair: Repair }> = ({ repair }) => {
    const client = getClientById(repair.clientId);
    const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
    const technician = repair.assignedTechnicianId ? getUserById(repair.assignedTechnicianId) : null;
    
    // Trouver le statut actuel de la réparation
    const currentStatus = repairStatuses.find(s => s.id === repair.status);
    const isNewStatus = currentStatus ? 
      (currentStatus.name.toLowerCase().includes('nouvelle') || 
       currentStatus.name.toLowerCase().includes('new') ||
       currentStatus.order === 0 || 
       currentStatus.order === 1) : false;
    
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
              
              {/* Reçu thermique pour statut "nouvelle" avec acompte */}
              {repair.deposit && repair.deposit > 0 && isNewStatus && (
                <>
                  <Tooltip title="Reçu thermique (acompte)">
                    <IconButton 
                      size="small" 
                      onClick={(e) => { e.stopPropagation(); handleOpenThermalReceipt(repair); }}
                      onMouseDown={(e) => e.stopPropagation()}
                      onTouchStart={(e) => e.stopPropagation()}
                      sx={{ 
                        color: '#3b82f6',
                        backgroundColor: '#eff6ff',
                        '&:hover': {
                          backgroundColor: '#dbeafe',
                        }
                      }}
                    >
                      <ReceiptIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  
                  {/* Afficher le bouton de validation ou de dévalidation selon l'état */}
                  {depositValidated[repair.id] ? (
                    <Tooltip title="Dévalider le paiement de l'acompte">
                      <IconButton 
                        size="small" 
                        onClick={(e) => { 
                          e.stopPropagation(); 
                          handleUnvalidateDeposit(repair);
                        }}
                        onMouseDown={(e) => e.stopPropagation()}
                        onTouchStart={(e) => e.stopPropagation()}
                        sx={{ 
                          color: '#ef4444',
                          backgroundColor: '#fef2f2',
                          '&:hover': {
                            backgroundColor: '#fee2e2',
                          }
                        }}
                      >
                        <CancelIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  ) : (
                    <Tooltip title="Valider le paiement de l'acompte">
                      <IconButton 
                        size="small" 
                        onClick={(e) => { 
                          e.stopPropagation(); 
                          handleValidateDeposit(repair);
                        }}
                        onMouseDown={(e) => e.stopPropagation()}
                        onTouchStart={(e) => e.stopPropagation()}
                        sx={{ 
                          color: '#10b981',
                          backgroundColor: '#f0fdf4',
                          '&:hover': {
                            backgroundColor: '#dcfce7',
                          }
                        }}
                      >
                        <CheckCircleIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  )}
                </>
              )}
              
              {repair.status === 'completed' && (
                <Tooltip title="Reçu thermique">
                  <IconButton 
                    size="small" 
                    onClick={(e) => { e.stopPropagation(); handleOpenThermalReceipt(repair); }}
                    onMouseDown={(e) => e.stopPropagation()}
                    onTouchStart={(e) => e.stopPropagation()}
                    sx={{ color: 'primary.main' }}
                  >
                    <ReceiptIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              )}

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
                  <Tooltip title={repair.isPaid ? "Annuler la validation du paiement" : "Valider le paiement"}>
                    <IconButton 
                      size="small" 
                      onClick={(e) => handleTogglePayment(repair, e)}
                      onMouseDown={(e) => e.stopPropagation()}
                      onTouchStart={(e) => e.stopPropagation()}
                      sx={{ 
                        color: repair.isPaid ? 'success.main' : 'warning.main',
                        '&:hover': {
                          backgroundColor: repair.isPaid ? 'success.light' : 'warning.light',
                          color: 'white'
                        }
                      }}
                    >
                      {repair.isPaid ? <CheckCircleIcon fontSize="small" /> : <CheckCircleOutlineIcon fontSize="small" />}
                    </IconButton>
                  </Tooltip>
                </>
              )}
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
            <Typography variant="subtitle2">
              {client?.firstName} {client?.lastName}
            </Typography>
            {repair.repairNumber && (
              <Typography variant="caption" color="primary" sx={{ fontWeight: 'bold' }}>
                {repair.repairNumber}
              </Typography>
            )}
          </Box>

          <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
            {device?.brand} {device?.model} {!device && 'Appareil'}
          </Typography>
          
          {/* Affichage de la catégorie de l'appareil */}
          {device?.type && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              <Chip
                label={getDeviceTypeLabel(device.type)}
                size="small"
                color="primary"
                variant="outlined"
                icon={<CategoryIcon />}
              />
            </Box>
          )}

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
            {(repair.status === 'completed' || repair.status === 'returned') && (
              <Chip
                icon={repair.isPaid ? <CheckCircleIcon /> : <ErrorOutlineIcon />}
                label={repair.isPaid ? 'Payé' : 'Non payé'}
                size="small"
                color={repair.isPaid ? 'success' : 'error'}
                variant={repair.isPaid ? 'filled' : 'outlined'}
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
                {formatFromEUR(repair.totalPrice, currency)} TTC
              </Typography>
            </Box>
            <Typography variant="caption" color="text.secondary">
              {safeFormatDate(repair.dueDate, 'dd/MM')}
            </Typography>
          </Box>

          {/* Affichage de l'acompte si présent */}
          {repair.deposit && repair.deposit > 0 && (
            <Box sx={{ 
              mt: 0.5,
              p: 1,
              backgroundColor: depositValidated[repair.id] ? '#f0fdf4' : '#eff6ff',
              borderRadius: 1,
              border: depositValidated[repair.id] ? '1px solid #10b981' : '1px solid #3b82f6',
            }}>
              <Typography 
                variant="caption" 
                sx={{ 
                  color: depositValidated[repair.id] ? '#10b981' : '#3b82f6',
                  fontWeight: 600,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 0.5,
                }}
              >
                💰 Acompte versé : {formatFromEUR(repair.deposit, currency)}
                {depositValidated[repair.id] && (
                  <span style={{ marginLeft: '4px', fontSize: '12px' }}>✓ PAYÉ</span>
                )}
              </Typography>
              <Typography 
                variant="caption" 
                sx={{ 
                  color: '#6b7280',
                  display: 'block',
                  mt: 0.25,
                }}
              >
                Reste : {formatFromEUR(repair.totalPrice - repair.deposit, currency)}
              </Typography>
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
      <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="lg" fullWidth>
        <DialogTitle>Modifier la réparation</DialogTitle>
        <DialogContent>
          <Alert severity="info" sx={{ mb: 2 }}>
            Modifiez les informations de la réparation. Vous pouvez changer le client, l'appareil, les services et tous les autres paramètres.
          </Alert>
          
          <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} sx={{ mb: 2 }}>
            <Tab label="Réparation" />
            <Tab label="Bon d'intervention" />
          </Tabs>

          {activeTab === 0 && (
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <Autocomplete
                    fullWidth
                    options={clients}
                    getOptionLabel={(client) => `${client.firstName} ${client.lastName}${client.email ? ` - ${client.email}` : ''}${client.phone ? ` - ${client.phone}` : ''}`}
                    value={clients.find(client => client.id === editRepair.clientId) || null}
                    onChange={(event, newValue) => {
                      handleEditRepairChange('clientId', newValue?.id || '');
                    }}
                    renderInput={(params) => (
                      <TextField
                        {...params}
                        label="Client *"
                        placeholder="Rechercher par nom, email ou téléphone..."
                        required
                      />
                    )}
                    renderOption={(props, client) => (
                      <Box component="li" {...props}>
                        <Box sx={{ display: 'flex', flexDirection: 'column', width: '100%' }}>
                          <Typography variant="body1" sx={{ fontWeight: 500 }}>
                            {client.firstName} {client.lastName}
                          </Typography>
                          {client.email && (
                            <Typography variant="body2" color="text.secondary">
                              📧 {client.email}
                            </Typography>
                          )}
                          {client.phone && (
                            <Typography variant="body2" color="text.secondary">
                              📱 {client.phone}
                            </Typography>
                          )}
                        </Box>
                      </Box>
                    )}
                    filterOptions={(options, { inputValue }) => {
                      const filterValue = inputValue.toLowerCase();
                      return options.filter(client => 
                        client.firstName.toLowerCase().includes(filterValue) ||
                        client.lastName.toLowerCase().includes(filterValue) ||
                        (client.email && client.email.toLowerCase().includes(filterValue)) ||
                        (client.phone && client.phone.includes(filterValue))
                      );
                    }}
                    noOptionsText="Aucun client trouvé"
                    clearOnEscape
                    selectOnFocus
                    handleHomeEndKeys
                  />
                  <Button
                    variant="contained"
                    size="small"
                    onClick={() => setClientFormOpen(true)}
                    sx={{ 
                      minWidth: '40px',
                      width: '40px',
                      height: '56px', // Même hauteur que l'Autocomplete
                      borderRadius: '4px',
                      backgroundColor: 'primary.main',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      }
                    }}
                    title="Créer un nouveau client"
                  >
                    <AddIcon fontSize="small" />
                  </Button>
                </Box>
              </Grid>

              <Grid item xs={12} md={6}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <FormControl fullWidth>
                    <InputLabel>Modèle *</InputLabel>
                    <Select
                      label="Modèle *"
                      value={editRepair.deviceId || ''}
                      onChange={(e) => {
                        handleEditRepairChange('deviceId', e.target.value);
                        // Réinitialiser les services sélectionnés quand on change de modèle
                        setEditRepair(prev => ({ ...prev, selectedServices: [] }));
                      }}
                      disabled={getFilteredModels().length === 0}
                    >
                      {getFilteredModels().map((model) => {
                        const brandName = model.brandName || (model as any).brand || 'N/A';
                        const modelName = model.model || 'N/A';
                        const categoryName = model.categoryName || (model as any).type || 'N/A';
                        
                        return (
                          <MenuItem key={model.id} value={model.id}>
                            {brandName} {modelName} ({categoryName})
                          </MenuItem>
                        );
                      })}
                    </Select>
                  </FormControl>
                  <Button
                    variant="contained"
                    size="small"
                    onClick={openModelDialog}
                    sx={{ 
                      minWidth: '40px',
                      width: '40px',
                      height: '56px', // Même hauteur que le Select
                      borderRadius: '4px',
                      backgroundColor: 'primary.main',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      }
                    }}
                    title="Créer un nouveau modèle"
                  >
                    <AddIcon fontSize="small" />
                  </Button>
                </Box>
              </Grid>

              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Services associés au modèle</InputLabel>
                  <Select
                    multiple
                    label="Services associés au modèle"
                    value={editRepair.selectedServices}
                    onChange={(e) => handleEditRepairChange('selectedServices', e.target.value)}
                    disabled={!editRepair.deviceId || getServicesForEditModel().length === 0}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {selected.map((serviceId) => {
                          const service = getServicesForEditModel().find(s => s.id === serviceId);
                          return service ? (
                            <Chip 
                              key={serviceId} 
                              label={`${service.service_name || service.serviceName || 'Service'} - ${formatFromEUR(service.effective_price || service.effectivePrice || 0, currency)}`} 
                              size="small" 
                            />
                          ) : null;
                        })}
                      </Box>
                    )}
                  >
                    {getServicesForEditModel().map((service) => (
                      <MenuItem key={service.id} value={service.id}>
                        <Box sx={{ display: 'flex', flexDirection: 'column', width: '100%' }}>
                          <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                            {service.service_name || service.serviceName || 'Service'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {service.service_description || service.serviceDescription || ''}
                          </Typography>
                          <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 0.5 }}>
                            <Typography variant="caption" color="primary">
                              {formatFromEUR(service.effective_price || service.effectivePrice || 0, currency)}
                            </Typography>
                          </Box>
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                  {!editRepair.deviceId && (
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                      Sélectionnez d'abord un modèle d'appareil
                    </Typography>
                  )}
                  {editRepair.deviceId && getServicesForEditModel().length === 0 && (
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                      Aucun service associé à ce modèle
                    </Typography>
                  )}
                  {editRepair.selectedServices.length > 0 && (
                    <Box sx={{ mt: 1, p: 1, bgcolor: 'grey.50', borderRadius: 1 }}>
                      <Typography variant="caption" color="text.secondary">
                        Services sélectionnés: {editRepair.selectedServices.length}
                      </Typography>
                      <Typography variant="caption" color="primary" sx={{ ml: 1, fontWeight: 'bold' }}>
                        Total: {formatFromEUR(getServicesForEditModel()
                          .filter(s => editRepair.selectedServices.includes(s.id))
                          .reduce((sum, s) => sum + (s.effective_price || s.effectivePrice || 0), 0), currency)}
                      </Typography>
                    </Box>
                  )}
                </FormControl>
              </Grid>
              
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description du problème *"
                  multiline
                  rows={3}
                  value={editRepair.description}
                  onChange={(e) => handleEditRepairChange('description', e.target.value)}
                  placeholder="Décrivez le problème rencontré..."
                />
              </Grid>
              
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Diagnostic initial"
                  multiline
                  rows={2}
                  value={editRepair.issue}
                  onChange={(e) => handleEditRepairChange('issue', e.target.value)}
                  placeholder="Diagnostic préliminaire (optionnel)..."
                />
              </Grid>
              
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label={`Prix estimé (${currencySymbol})`}
                  type="number"
                  value={editRepair.totalPrice}
                  onChange={(e) => handleEditRepairChange('totalPrice', parseFloat(e.target.value) || 0)}
                />
                {editRepair.selectedServices.length > 0 && (
                  <Typography variant="caption" color="primary" sx={{ mt: 1, display: 'block' }}>
                    Prix mis à jour automatiquement avec les services sélectionnés
                  </Typography>
                )}
              </Grid>
              
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="Réduction (%)"
                  type="number"
                  value={editRepair.discountPercentage}
                  onChange={(e) => handleEditRepairChange('discountPercentage', Math.max(0, Math.min(100, parseFloat(e.target.value) || 0)))}
                  inputProps={{ 
                    min: 0,
                    max: 100,
                    step: 0.1
                  }}
                />
                {editRepair.discountPercentage > 0 && (
                  <Typography variant="caption" color="success.main" sx={{ mt: 1, display: 'block' }}>
                    Prix final: {formatFromEUR(((editRepair.totalPrice * (100 - editRepair.discountPercentage)) / 100), currency)}
                  </Typography>
                )}
              </Grid>
              
              {/* Section Acompte */}
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label={`Acompte payé (${currencySymbol})`}
                  type="number"
                  value={editRepair.deposit}
                  onChange={(e) => handleEditRepairChange('deposit', parseFloat(e.target.value) || 0)}
                  inputProps={{ 
                    min: 0,
                    step: 0.01
                  }}
                  helperText="Montant de l'acompte versé"
                />
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Mode paiement acompte</InputLabel>
                  <Select
                    label="Mode paiement acompte"
                    value={editRepair.depositPaymentMethod || 'cash'}
                    onChange={(e) => handleEditRepairChange('depositPaymentMethod', e.target.value)}
                    disabled={!editRepair.deposit || editRepair.deposit === 0}
                  >
                    <MenuItem value="cash">Espèces</MenuItem>
                    <MenuItem value="card">Carte bancaire</MenuItem>
                    <MenuItem value="check">Chèque</MenuItem>
                    <MenuItem value="transfer">Virement</MenuItem>
                    <MenuItem value="payment_link">Lien de paiement</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              {/* Afficher le reste à payer */}
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label={`Reste à payer (${currencySymbol})`}
                  type="number"
                  value={Math.max(0, (editRepair.totalPrice * (100 - (editRepair.discountPercentage || 0)) / 100) - (editRepair.deposit || 0)).toFixed(2)}
                  InputProps={{ readOnly: true }}
                  helperText="Calculé automatiquement"
                  sx={{
                    '& .MuiInputBase-input': { 
                      fontWeight: 'bold', 
                      color: 'primary.main' 
                    }
                  }}
                />
              </Grid>

              {/* Section Paiement Final */}
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Mode paiement final</InputLabel>
                  <Select
                    label="Mode paiement final"
                    value={editRepair.finalPaymentMethod || ''}
                    onChange={(e) => handleEditRepairChange('finalPaymentMethod', e.target.value)}
                    disabled={!editRepair.isPaid}
                  >
                    <MenuItem value="">Non payé</MenuItem>
                    <MenuItem value="cash">Espèces</MenuItem>
                    <MenuItem value="card">Carte bancaire</MenuItem>
                    <MenuItem value="check">Chèque</MenuItem>
                    <MenuItem value="transfer">Virement</MenuItem>
                    <MenuItem value="payment_link">Lien de paiement</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="Date d'échéance"
                  type="date"
                  value={editRepair.dueDate}
                  onChange={(e) => handleEditRepairChange('dueDate', e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Statut initial</InputLabel>
                  <Select
                    label="Statut initial"
                    value={editRepair.status || ''}
                    onChange={(e) => handleEditRepairChange('status', e.target.value)}
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
                    value={editRepair.assignedTechnicianId || ''}
                    onChange={(e) => handleEditRepairChange('assignedTechnicianId', e.target.value)}
                  >
                    <MenuItem value="">Aucun technicien</MenuItem>
                    {getRepairEligibleUsers(users).map((user) => (
                      <MenuItem key={user.id} value={user.id}>
                        {getRepairUserDisplayName(user)}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={editRepair.isUrgent}
                      onChange={(e) => handleEditRepairChange('isUrgent', e.target.checked)}
                    />
                  }
                  label="Réparation urgente"
                />
              </Grid>
            </Grid>
          )}

          {/* Autres onglets - même contenu que le formulaire de création */}


          {activeTab === 1 && (
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12}>
                <Alert severity="info" sx={{ mb: 2 }}>
                  Configurez le bon d'intervention pour documenter l'état initial de l'appareil et les conditions de réparation.
                </Alert>
              </Grid>
              
              {/* Informations de base */}
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nom du technicien"
                  value={editInterventionData.technicianName}
                  onChange={(e) => setEditInterventionData(prev => ({ ...prev, technicianName: e.target.value }))}
                  required
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Durée estimée"
                  value={editInterventionData.estimatedDuration}
                  onChange={(e) => setEditInterventionData(prev => ({ ...prev, estimatedDuration: e.target.value }))}
                  placeholder="ex: 2-3 jours"
                />
              </Grid>

              {/* État de l'appareil */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="État de l'appareil"
                  value={editInterventionData.deviceCondition}
                  onChange={(e) => setEditInterventionData(prev => ({ ...prev, deviceCondition: e.target.value }))}
                  placeholder="Décrivez l'état général, dommages visibles, pièces manquantes..."
                />
              </Grid>

              {/* Section Sécurité */}
              <Grid item xs={12}>
                <Typography variant="h6" sx={{ mb: 2, color: '#1976d2', borderBottom: '2px solid #1976d2', pb: 1 }}>
                  🔐 Sécurité et Accès
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Type d'authentification</InputLabel>
                  <Select
                    value={editInterventionData.authType || ''}
                    onChange={(e) => setEditInterventionData(prev => ({ ...prev, authType: e.target.value }))}
                    label="Type d'authentification"
                  >
                    <MenuItem value="password">Mot de passe</MenuItem>
                    <MenuItem value="pattern">Schéma de déverrouillage</MenuItem>
                    <MenuItem value="pin">Code PIN</MenuItem>
                    <MenuItem value="fingerprint">Empreinte digitale</MenuItem>
                    <MenuItem value="face">Reconnaissance faciale</MenuItem>
                    <MenuItem value="none">Aucun</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Code d'accès"
                  value={editInterventionData.accessCode || ''}
                  onChange={(e) => setEditInterventionData(prev => ({ ...prev, accessCode: e.target.value }))}
                  placeholder="Mot de passe, PIN, ou description"
                  type="password"
                />
              </Grid>

              {/* Schéma interactif */}
              {editInterventionData.authType === 'pattern' && (
                <Grid item xs={12}>
                  <Box sx={{ 
                    p: 2, 
                    border: '2px dashed #1976d2', 
                    borderRadius: 2, 
                    backgroundColor: '#f8f9fa',
                    textAlign: 'center'
                  }}>
                    <Typography variant="h6" sx={{ mb: 2, color: '#1976d2' }}>
                      📱 Schéma de déverrouillage
                    </Typography>
                    
                    <Box sx={{ 
                      width: 150, 
                      height: 150, 
                      mx: 'auto',
                      border: '2px solid #ccc',
                      borderRadius: 2,
                      backgroundColor: '#fff',
                      mb: 2
                    }}>
                      <Box sx={{ 
                        display: 'grid', 
                        gridTemplateColumns: 'repeat(3, 1fr)', 
                        gap: 1,
                        p: 2,
                        height: '100%'
                      }}>
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((point) => (
                          <Box
                            key={point}
                            sx={{
                              width: 15,
                              height: 15,
                              borderRadius: '50%',
                              backgroundColor: editInterventionData.patternPoints?.includes(point) ? '#1976d2' : '#e0e0e0',
                              border: '2px solid #ccc',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '10px',
                              fontWeight: 'bold',
                              color: editInterventionData.patternPoints?.includes(point) ? 'white' : '#666',
                              '&:hover': {
                                backgroundColor: editInterventionData.patternPoints?.includes(point) ? '#1565c0' : '#f0f0f0',
                              }
                            }}
                            onClick={() => {
                              const currentPoints = editInterventionData.patternPoints || [];
                              const newPoints = currentPoints.includes(point) 
                                ? currentPoints.filter(p => p !== point)
                                : [...currentPoints, point];
                              setEditInterventionData(prev => ({ 
                                ...prev, 
                                patternPoints: newPoints,
                                accessCode: `Schéma: ${newPoints.join('-')}`
                              }));
                            }}
                          >
                            {point}
                          </Box>
                        ))}
                      </Box>
                    </Box>
                    
                    <Button
                      variant="outlined"
                      size="small"
                      onClick={() => setEditInterventionData(prev => ({ 
                        ...prev, 
                        patternPoints: [],
                        accessCode: '',
                        patternDescription: ''
                      }))}
                    >
                      Effacer le schéma
                    </Button>
                  </Box>
                </Grid>
              )}

              {/* Confirmations */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={editInterventionData.dataBackup}
                        onChange={(e) => setEditInterventionData(prev => ({ ...prev, dataBackup: e.target.checked }))}
                      />
                    }
                    label="Sauvegarde des données effectuée"
                  />
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={editInterventionData.accessConfirmed}
                        onChange={(e) => setEditInterventionData(prev => ({ ...prev, accessConfirmed: e.target.checked }))}
                      />
                    }
                    label="Accès testé et confirmé"
                  />
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={editInterventionData.clientAuthorizesRepair}
                        onChange={(e) => setEditInterventionData(prev => ({ ...prev, clientAuthorizesRepair: e.target.checked }))}
                      />
                    }
                    label="Client autorise la réparation"
                  />
                </Box>
              </Grid>

              {/* Diagnostic */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="Diagnostic et solution proposée"
                  value={editInterventionData.initialDiagnosis}
                  onChange={(e) => setEditInterventionData(prev => ({ ...prev, initialDiagnosis: e.target.value }))}
                  placeholder="Décrivez le problème et la solution..."
                />
              </Grid>

              {/* Notes */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={2}
                  label="Notes additionnelles"
                  value={editInterventionData.additionalNotes}
                  onChange={(e) => setEditInterventionData(prev => ({ ...prev, additionalNotes: e.target.value }))}
                  placeholder="Informations importantes, risques, etc."
                />
              </Grid>

              {/* Conditions */}
              <Grid item xs={12}>
                <Alert severity="warning" sx={{ mb: 2 }}>
                  <Typography variant="body2">
                    <strong>Important :</strong> Le client accepte les conditions de réparation et les risques potentiels.
                  </Typography>
                </Alert>
              </Grid>

              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={editInterventionData.termsAccepted}
                      onChange={(e) => setEditInterventionData(prev => ({ ...prev, termsAccepted: e.target.checked }))}
                      required
                    />
                  }
                  label="J'accepte les conditions de réparation"
                />
              </Grid>

              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={editInterventionData.liabilityAccepted}
                      onChange={(e) => setEditInterventionData(prev => ({ ...prev, liabilityAccepted: e.target.checked }))}
                      required
                    />
                  }
                  label="Je comprends et accepte les clauses de responsabilité"
                />
              </Grid>

              {/* Bouton de génération */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', justifyContent: 'center', mt: 2 }}>
                  <Button
                    variant="contained"
                    startIcon={<PrintIcon />}
                    onClick={handleGenerateInterventionFromEditTab}
                    disabled={!editInterventionData.technicianName || !editInterventionData.termsAccepted || !editInterventionData.liabilityAccepted}
                    sx={{ 
                      backgroundColor: '#1976d2',
                      '&:hover': {
                        backgroundColor: '#1565c0',
                      },
                      px: 4,
                      py: 1.5
                    }}
                  >
                    Générer le Bon d'Intervention
                  </Button>
                </Box>
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
              <Tab label="Bon d'intervention" />
            </Tabs>
          </Box>
        </DialogTitle>
        <DialogContent>
          {activeTab === 0 && (
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12}>
                <Alert severity="info" sx={{ mb: 2 }}>
                  Remplissez les informations de base pour créer une nouvelle réparation.
                  Vous pouvez également créer un nouveau client ou un nouveau modèle si nécessaire.
                </Alert>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <Autocomplete
                    fullWidth
                    options={clients}
                    getOptionLabel={(client) => `${client.firstName} ${client.lastName}${client.email ? ` - ${client.email}` : ''}${client.phone ? ` - ${client.phone}` : ''}`}
                    value={clients.find(client => client.id === newRepair.clientId) || null}
                    onChange={(event, newValue) => {
                      handleNewRepairChange('clientId', newValue?.id || '');
                    }}
                    renderInput={(params) => (
                      <TextField
                        {...params}
                        label="Client *"
                        placeholder="Rechercher par nom, email ou téléphone..."
                        required
                      />
                    )}
                    renderOption={(props, client) => (
                      <Box component="li" {...props}>
                        <Box sx={{ display: 'flex', flexDirection: 'column', width: '100%' }}>
                          <Typography variant="body1" sx={{ fontWeight: 500 }}>
                            {client.firstName} {client.lastName}
                          </Typography>
                          {client.email && (
                            <Typography variant="body2" color="text.secondary">
                              📧 {client.email}
                            </Typography>
                          )}
                          {client.phone && (
                            <Typography variant="body2" color="text.secondary">
                              📱 {client.phone}
                            </Typography>
                          )}
                        </Box>
                      </Box>
                    )}
                    filterOptions={(options, { inputValue }) => {
                      const filterValue = inputValue.toLowerCase();
                      return options.filter(client => 
                        client.firstName.toLowerCase().includes(filterValue) ||
                        client.lastName.toLowerCase().includes(filterValue) ||
                        (client.email && client.email.toLowerCase().includes(filterValue)) ||
                        (client.phone && client.phone.includes(filterValue))
                      );
                    }}
                    noOptionsText="Aucun client trouvé"
                    clearOnEscape
                    selectOnFocus
                    handleHomeEndKeys
                  />
                  <Button
                    variant="contained"
                    size="small"
                    onClick={() => setClientFormOpen(true)}
                    sx={{ 
                      minWidth: '40px',
                      width: '40px',
                      height: '56px', // Même hauteur que l'Autocomplete
                      borderRadius: '4px',
                      backgroundColor: 'primary.main',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      }
                    }}
                    title="Créer un nouveau client"
                  >
                    <AddIcon fontSize="small" />
                  </Button>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <FormControl fullWidth>
                    <InputLabel>Marque</InputLabel>
                    <Select 
                      label="Marque"
                      value={selectedBrand}
                      onChange={(e) => {
                        setSelectedBrand(e.target.value);
                        setNewRepair(prev => ({ ...prev, deviceId: '' })); // Réinitialiser la sélection de modèle
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
                  <Button
                    variant="contained"
                    size="small"
                    onClick={openBrandDialog}
                    sx={{ 
                      minWidth: '40px',
                      width: '40px',
                      height: '56px', // Même hauteur que le Select
                      borderRadius: '4px',
                      backgroundColor: 'primary.main',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      }
                    }}
                    title="Créer une nouvelle marque"
                  >
                    <AddIcon fontSize="small" />
                  </Button>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <FormControl fullWidth>
                    <InputLabel>Catégorie</InputLabel>
                    <Select 
                      label="Catégorie"
                      value={selectedCategory}
                      onChange={(e) => {
                        setSelectedCategory(e.target.value);
                        setSelectedBrand(''); // Réinitialiser la sélection de marque
                        setNewRepair(prev => ({ ...prev, deviceId: '' })); // Réinitialiser la sélection de modèle
                      }}
                    >
                      <MenuItem value="">Toutes les catégories</MenuItem>
                      {getUniqueCategories().map((category) => (
                        <MenuItem key={category} value={category}>
                          {category}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  <Button
                    variant="contained"
                    size="small"
                    onClick={openCategoryDialog}
                    sx={{ 
                      minWidth: '40px',
                      width: '40px',
                      height: '56px', // Même hauteur que le Select
                      borderRadius: '4px',
                      backgroundColor: 'primary.main',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      }
                    }}
                    title="Créer une nouvelle catégorie"
                  >
                    <AddIcon fontSize="small" />
                  </Button>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={4}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <FormControl fullWidth>
                    <InputLabel>Modèle *</InputLabel>
                    <Select
                      label="Modèle *"
                      value={newRepair.deviceId || ''}
                      onChange={(e) => {
                        handleNewRepairChange('deviceId', e.target.value);
                        // Réinitialiser les services sélectionnés quand on change de modèle
                        setNewRepair(prev => ({ ...prev, selectedServices: [] }));
                      }}
                      disabled={getFilteredModels().length === 0}
                    >
                      {getFilteredModels().map((model) => {
                        // Utiliser les propriétés avec fallbacks pour compatibilité
                        const brandName = model.brandName || (model as any).brand || 'N/A';
                        const modelName = model.model || (model as any).name || 'N/A';
                        const categoryName = model.categoryName || (model as any).type || 'N/A';
                        
                        return (
                          <MenuItem key={model.id} value={model.id}>
                            {brandName} {modelName} ({categoryName})
                          </MenuItem>
                        );
                      })}
                    </Select>
                    {getFilteredModels().length === 0 && (
                      <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                        Aucun modèle trouvé avec les filtres sélectionnés
                      </Typography>
                    )}
                  </FormControl>
                  <Button
                    variant="contained"
                    size="small"
                    onClick={openModelDialog}
                    sx={{ 
                      minWidth: '40px',
                      width: '40px',
                      height: '56px', // Même hauteur que le Select
                      borderRadius: '4px',
                      backgroundColor: 'primary.main',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      }
                    }}
                    title="Créer un nouveau modèle"
                  >
                    <AddIcon fontSize="small" />
                  </Button>
                </Box>
              </Grid>
              
              {/* Sélection des services associés au modèle */}
              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Services associés au modèle</InputLabel>
                  <Select
                    multiple
                    label="Services associés au modèle"
                    value={newRepair.selectedServices}
                    onChange={(e) => handleNewRepairChange('selectedServices', e.target.value)}
                    disabled={!newRepair.deviceId || getServicesForSelectedModel().length === 0}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                {selected.map((serviceId) => {
                  const service = getServicesForSelectedModel().find(s => s.id === serviceId);
                  return service ? (
                    <Chip 
                      key={serviceId} 
                      label={`${service.service_name || service.serviceName || 'Service'} - ${formatFromEUR(service.effective_price || service.effectivePrice || 0, currency)}`} 
                      size="small" 
                    />
                  ) : null;
                })}
                      </Box>
                    )}
                  >
            {getServicesForSelectedModel().map((service) => (
              <MenuItem key={service.id} value={service.id}>
                <Box sx={{ display: 'flex', flexDirection: 'column', width: '100%' }}>
                  <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                    {service.service_name || service.serviceName || 'Service'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {service.service_description || service.serviceDescription || ''}
                  </Typography>
                  <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 0.5 }}>
                    <Typography variant="caption" color="primary">
                      {formatFromEUR(service.effective_price || service.effectivePrice || 0, currency)}
                    </Typography>
                  </Box>
                </Box>
              </MenuItem>
            ))}
                  </Select>
                  {!newRepair.deviceId && (
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                      Sélectionnez d'abord un modèle d'appareil
                    </Typography>
                  )}
                  {newRepair.deviceId && getServicesForSelectedModel().length === 0 && (
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                      Aucun service associé à ce modèle
                    </Typography>
                  )}
                  {newRepair.selectedServices.length > 0 && (
                    <Box sx={{ mt: 1, p: 1, bgcolor: 'grey.50', borderRadius: 1 }}>
                      <Typography variant="caption" color="text.secondary">
                        Services sélectionnés: {newRepair.selectedServices.length}
                      </Typography>
              <Typography variant="caption" color="primary" sx={{ ml: 1, fontWeight: 'bold' }}>
                Total: {formatFromEUR(getServicesForSelectedModel()
                  .filter(s => newRepair.selectedServices.includes(s.id))
                  .reduce((sum, s) => sum + (s.effective_price || s.effectivePrice || 0), 0), currency)}
              </Typography>
                    </Box>
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
                  label={`Prix estimé (${currencySymbol})`}
                  type="number"
                  value={newRepair.totalPrice}
                  onChange={(e) => handleNewRepairChange('totalPrice', parseFloat(e.target.value) || 0)}
                />
                {newRepair.selectedServices.length > 0 && (
                  <Typography variant="caption" color="primary" sx={{ mt: 1, display: 'block' }}>
                    Prix mis à jour automatiquement avec les services sélectionnés
                  </Typography>
                )}
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
                    Prix final: {formatFromEUR(((newRepair.totalPrice * (100 - newRepair.discountPercentage)) / 100), currency)}
                  </Typography>
                )}
              </Grid>
              
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label={`Acompte payé (${currencySymbol})`}
                  type="number"
                  value={newRepair.deposit}
                  onChange={(e) => handleNewRepairChange('deposit', parseFloat(e.target.value) || 0)}
                  inputProps={{ 
                    min: 0,
                    step: 0.01
                  }}
                  helperText="Montant de l'acompte versé par le client"
                />
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Mode de paiement</InputLabel>
                  <Select
                    label="Mode de paiement"
                    value={newRepair.paymentMethod}
                    onChange={(e) => handleNewRepairChange('paymentMethod', e.target.value)}
                  >
                    <MenuItem value="cash">Espèces</MenuItem>
                    <MenuItem value="card">Carte bancaire</MenuItem>
                    <MenuItem value="check">Chèque</MenuItem>
                    <MenuItem value="transfer">Virement</MenuItem>
                    <MenuItem value="payment_link">Lien de paiement</MenuItem>
                  </Select>
                </FormControl>
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
                  Configurez le bon d'intervention pour documenter l'état initial de l'appareil et les conditions de réparation.
                </Alert>
              </Grid>
              
              {/* Informations de base */}
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nom du technicien"
                  value={interventionData.technicianName}
                  onChange={(e) => setInterventionData(prev => ({ ...prev, technicianName: e.target.value }))}
                  required
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Durée estimée"
                  value={interventionData.estimatedDuration}
                  onChange={(e) => setInterventionData(prev => ({ ...prev, estimatedDuration: e.target.value }))}
                  placeholder="ex: 2-3 jours"
                />
              </Grid>

              {/* État de l'appareil */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="État de l'appareil"
                  value={interventionData.deviceCondition}
                  onChange={(e) => setInterventionData(prev => ({ ...prev, deviceCondition: e.target.value }))}
                  placeholder="Décrivez l'état général, dommages visibles, pièces manquantes..."
                />
              </Grid>

              {/* Section Sécurité */}
              <Grid item xs={12}>
                <Typography variant="h6" sx={{ mb: 2, color: '#1976d2', borderBottom: '2px solid #1976d2', pb: 1 }}>
                  🔐 Sécurité et Accès
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Type d'authentification</InputLabel>
                  <Select
                    value={interventionData.authType || ''}
                    onChange={(e) => setInterventionData(prev => ({ ...prev, authType: e.target.value }))}
                    label="Type d'authentification"
                  >
                    <MenuItem value="password">Mot de passe</MenuItem>
                    <MenuItem value="pattern">Schéma de déverrouillage</MenuItem>
                    <MenuItem value="pin">Code PIN</MenuItem>
                    <MenuItem value="fingerprint">Empreinte digitale</MenuItem>
                    <MenuItem value="face">Reconnaissance faciale</MenuItem>
                    <MenuItem value="none">Aucun</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Code d'accès"
                  value={interventionData.accessCode || ''}
                  onChange={(e) => setInterventionData(prev => ({ ...prev, accessCode: e.target.value }))}
                  placeholder="Mot de passe, PIN, ou description"
                  type="password"
                />
              </Grid>

              {/* Schéma interactif */}
              {interventionData.authType === 'pattern' && (
                <Grid item xs={12}>
                  <Box sx={{ 
                    p: 2, 
                    border: '2px dashed #1976d2', 
                    borderRadius: 2, 
                    backgroundColor: '#f8f9fa',
                    textAlign: 'center'
                  }}>
                    <Typography variant="h6" sx={{ mb: 2, color: '#1976d2' }}>
                      📱 Schéma de déverrouillage
                    </Typography>
                    
                    <Box sx={{ 
                      width: 150, 
                      height: 150, 
                      mx: 'auto',
                      border: '2px solid #ccc',
                      borderRadius: 2,
                      backgroundColor: '#fff',
                      mb: 2
                    }}>
                      <Box sx={{ 
                        display: 'grid', 
                        gridTemplateColumns: 'repeat(3, 1fr)', 
                        gap: 1,
                        p: 2,
                        height: '100%'
                      }}>
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((point) => (
                          <Box
                            key={point}
                            sx={{
                              width: 15,
                              height: 15,
                              borderRadius: '50%',
                              backgroundColor: interventionData.patternPoints?.includes(point) ? '#1976d2' : '#e0e0e0',
                              border: '2px solid #ccc',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '10px',
                              fontWeight: 'bold',
                              color: interventionData.patternPoints?.includes(point) ? 'white' : '#666',
                              '&:hover': {
                                backgroundColor: interventionData.patternPoints?.includes(point) ? '#1565c0' : '#f0f0f0',
                              }
                            }}
                            onClick={() => {
                              const currentPoints = interventionData.patternPoints || [];
                              const newPoints = currentPoints.includes(point) 
                                ? currentPoints.filter(p => p !== point)
                                : [...currentPoints, point];
                              setInterventionData(prev => ({ 
                                ...prev, 
                                patternPoints: newPoints,
                                accessCode: `Schéma: ${newPoints.join('-')}`
                              }));
                            }}
                          >
                            {point}
                          </Box>
                        ))}
                      </Box>
                    </Box>
                    
                    <Button
                      variant="outlined"
                      size="small"
                      onClick={() => setInterventionData(prev => ({ 
                        ...prev, 
                        patternPoints: [],
                        accessCode: '',
                        patternDescription: ''
                      }))}
                    >
                      Effacer le schéma
                    </Button>
                  </Box>
                </Grid>
              )}

              {/* Confirmations */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={interventionData.dataBackup}
                        onChange={(e) => setInterventionData(prev => ({ ...prev, dataBackup: e.target.checked }))}
                      />
                    }
                    label="Sauvegarde des données effectuée"
                  />
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={interventionData.accessConfirmed}
                        onChange={(e) => setInterventionData(prev => ({ ...prev, accessConfirmed: e.target.checked }))}
                      />
                    }
                    label="Accès testé et confirmé"
                  />
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={interventionData.clientAuthorizesRepair}
                        onChange={(e) => setInterventionData(prev => ({ ...prev, clientAuthorizesRepair: e.target.checked }))}
                      />
                    }
                    label="Client autorise la réparation"
                  />
                </Box>
              </Grid>

              {/* Diagnostic */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="Diagnostic et solution proposée"
                  value={interventionData.initialDiagnosis}
                  onChange={(e) => setInterventionData(prev => ({ ...prev, initialDiagnosis: e.target.value }))}
                  placeholder="Décrivez le problème et la solution..."
                />
              </Grid>

              {/* Notes */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={2}
                  label="Notes additionnelles"
                  value={interventionData.additionalNotes}
                  onChange={(e) => setInterventionData(prev => ({ ...prev, additionalNotes: e.target.value }))}
                  placeholder="Informations importantes, risques, etc."
                />
              </Grid>

              {/* Conditions */}
              <Grid item xs={12}>
                <Alert severity="warning" sx={{ mb: 2 }}>
                  <Typography variant="body2">
                    <strong>Important :</strong> Le client accepte les conditions de réparation et les risques potentiels.
                  </Typography>
                </Alert>
              </Grid>

              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={interventionData.termsAccepted}
                      onChange={(e) => setInterventionData(prev => ({ ...prev, termsAccepted: e.target.checked }))}
                      required
                    />
                  }
                  label="J'accepte les conditions de réparation"
                />
              </Grid>

              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={interventionData.liabilityAccepted}
                      onChange={(e) => setInterventionData(prev => ({ ...prev, liabilityAccepted: e.target.checked }))}
                      required
                    />
                  }
                  label="Je comprends et accepte les clauses de responsabilité"
                />
              </Grid>

              {/* Bouton de génération */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', justifyContent: 'center', mt: 2 }}>
                  <Button
                    variant="contained"
                    startIcon={<PrintIcon />}
                    onClick={handleGenerateInterventionFromTab}
                    disabled={!interventionData.technicianName || !interventionData.termsAccepted || !interventionData.liabilityAccepted}
                    sx={{ 
                      backgroundColor: '#1976d2',
                      '&:hover': {
                        backgroundColor: '#1565c0',
                      },
                      px: 4,
                      py: 1.5
                    }}
                  >
                    Générer le Bon d'Intervention
                  </Button>
                </Box>
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
              repair={selectedRepairForInvoice}
              client={getClientById(selectedRepairForInvoice.clientId)}
              onClose={closeInvoice}
              depositValidated={depositValidated[selectedRepairForInvoice.id] || false}
              fromKanban={true}
            />
          </DialogContent>
        </Dialog>
      )}

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

      {/* Dialogue pour créer un nouveau modèle */}
      <Dialog open={modelDialogOpen} onClose={() => setModelDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          Créer un nouveau modèle
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            {/* Affichage des erreurs */}
            {error && (
              <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
                {error}
              </Alert>
            )}

            <TextField
              label="Nom du modèle"
              value={newModel.name}
              onChange={(e) => setNewModel({ ...newModel, name: e.target.value })}
              fullWidth
              required
              placeholder="Ex: iPhone 14, Galaxy S23, etc."
            />
            
            <TextField
              label="Description"
              value={newModel.description}
              onChange={(e) => setNewModel({ ...newModel, description: e.target.value })}
              fullWidth
              multiline
              rows={3}
            />
            
            <FormControl fullWidth required>
              <InputLabel>Marque</InputLabel>
              <Select
                value={newModel.brandId || ''}
                onChange={(e) => setNewModel({ ...newModel, brandId: e.target.value })}
                label="Marque"
              >
                {(dbBrands || []).map((brand) => (
                  <MenuItem key={brand.id} value={brand.id}>
                    {brand.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <FormControl fullWidth required>
              <InputLabel>Catégorie</InputLabel>
              <Select
                value={newModel.categoryId || ''}
                onChange={(e) => setNewModel({ ...newModel, categoryId: e.target.value })}
                label="Catégorie"
              >
                {(dbCategories || []).map((category) => (
                  <MenuItem key={category.id} value={category.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {getCategoryIcon(category.name, category.icon)}
                      <span>{category.name}</span>
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <FormControlLabel
              control={
                <Switch
                  checked={newModel.isActive}
                  onChange={(e) => setNewModel({ ...newModel, isActive: e.target.checked })}
                />
              }
              label="Modèle actif"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setModelDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={handleCreateModel}
            disabled={!newModel.name || !newModel.brandId || !newModel.categoryId || loading}
          >
            {loading ? <CircularProgress size={20} /> : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

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
          depositValidated={depositValidated[thermalReceiptRepair.id] || false}
        />
      )}

      {/* Dialogue pour créer une nouvelle catégorie */}
      <Dialog open={categoryDialogOpen} onClose={() => setCategoryDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Créer une nouvelle catégorie</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField
              label="Nom de la catégorie"
              value={newCategory.name}
              onChange={(e) => setNewCategory({ ...newCategory, name: e.target.value })}
              fullWidth
              required
            />
            
            <TextField
              label="Description"
              value={newCategory.description}
              onChange={(e) => setNewCategory({ ...newCategory, description: e.target.value })}
              fullWidth
              multiline
              rows={3}
            />
            
            <Box>
              <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 'bold' }}>
                Sélectionner une icône pour la catégorie
              </Typography>
              <Box sx={{ maxHeight: '400px', overflowY: 'auto', border: '1px solid #e0e0e0', borderRadius: 1, p: 2 }}>
                <CategoryIconGrid 
                  selectedIcon={newCategory.icon}
                  onIconSelect={(iconType) => setNewCategory({ ...newCategory, icon: iconType })}
                />
              </Box>
            </Box>
            
            <FormControlLabel
              control={
                <Switch
                  checked={newCategory.isActive}
                  onChange={(e) => setNewCategory({ ...newCategory, isActive: e.target.checked })}
                />
              }
              label="Catégorie active"
            />
          </Box>
          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCategoryDialogOpen(false)}>
            Annuler
          </Button>
          <Button
            onClick={handleCreateCategory}
            variant="contained"
            disabled={loading || !newCategory.name.trim()}
          >
            {loading ? <CircularProgress size={20} /> : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue pour créer une nouvelle marque */}
      <Dialog open={brandDialogOpen} onClose={() => setBrandDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Créer une nouvelle marque</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField
              label="Nom de la marque"
              value={newBrand.name}
              onChange={(e) => setNewBrand({ ...newBrand, name: e.target.value })}
              fullWidth
              required
            />
            
            <TextField
              label="Description"
              value={newBrand.description}
              onChange={(e) => setNewBrand({ ...newBrand, description: e.target.value })}
              fullWidth
              multiline
              rows={3}
            />
            
            <FormControl fullWidth>
              <InputLabel>Catégories</InputLabel>
              <Select
                multiple
                value={newBrand.categoryIds}
                onChange={(e) => setNewBrand({ ...newBrand, categoryIds: e.target.value as string[] })}
                label="Catégories"
                renderValue={(selected) => (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                    {(selected as string[]).map((value) => {
                      const category = dbCategories.find(cat => cat.id === value);
                      return (
                        <Chip
                          key={value}
                          label={category?.name || value}
                          size="small"
                        />
                      );
                    })}
                  </Box>
                )}
              >
                {dbCategories.map((category) => (
                  <MenuItem key={category.id} value={category.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {getCategoryIcon(category.name, category.icon)}
                      {category.name}
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <FormControlLabel
              control={
                <Switch
                  checked={newBrand.isActive}
                  onChange={(e) => setNewBrand({ ...newBrand, isActive: e.target.checked })}
                />
              }
              label="Marque active"
            />
          </Box>
          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBrandDialogOpen(false)}>
            Annuler
          </Button>
          <Button
            onClick={handleCreateBrand}
            variant="contained"
            disabled={loading || !newBrand.name.trim()}
          >
            {loading ? <CircularProgress size={20} /> : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Notification de succès */}
      <Snackbar
        open={snackbarOpen}
        autoHideDuration={4000}
        onClose={() => setSnackbarOpen(false)}
        message={snackbarMessage}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      />
    </Box>
  );
};

export default Kanban;

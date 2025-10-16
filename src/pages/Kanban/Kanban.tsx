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
  Payment as PaymentIcon,
  CheckCircle as CheckCircleIcon,
  Category as CategoryIcon,
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
import { repairService } from '../../services/supabaseService';
import { deviceCategoryService, DeviceCategory } from '../../services/deviceCategoryService';
import { brandService, BrandWithCategories } from '../../services/brandService';

const Kanban: React.FC = () => {
  const navigate = useNavigate();
  const {
    repairs,
    repairStatuses,
    clients,
    devices,
    deviceCategories,
    deviceBrands,
    deviceModels,
    users,
    systemSettings,
    getClientById,
    getDeviceById,
    getUserById,
    updateRepair,
    addRepair,
    deleteRepair,
    addDevice,
    addDeviceModel,
    addClient,
    loadUsers,
    loadDeviceModels,
    loadSystemSettings,
    loadRepairs,
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
          console.log('✅ Catégories d\'appareils chargées depuis la base de données:', result.data.length);
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
        console.log('✅ Marques chargées depuis la base de données:', brands.length);
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
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 jours par défaut
    assignedTechnicianId: '' as string,
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

  // États pour le nouveau modèle
  const [newDevice, setNewDevice] = useState({
    categoryId: '',
    brandId: '',
    model: '',
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
    console.log('🔍 getFilteredModels appelé avec:', { selectedCategory, selectedBrand, totalModels: deviceModels.length });
    
    const filtered = deviceModels.filter(model => {
      // Filtrage par marque - utiliser la propriété brand du modèle
      const brandMatch = !selectedBrand || model.brand === selectedBrand;
      
      // Filtrage par catégorie - utiliser la propriété type du modèle
      const categoryMatch = !selectedCategory || model.type === selectedCategory;
      
      const isActive = model.isActive;
      const finalMatch = brandMatch && categoryMatch && isActive;
      
      console.log(`📱 Modèle ${model.brand} ${model.model}: brandMatch=${brandMatch}, categoryMatch=${categoryMatch}, isActive=${isActive}, finalMatch=${finalMatch}`);
      
      return finalMatch;
    });
    
    console.log(`🎯 Modèles filtrés: ${filtered.length}/${deviceModels.length}`);
    return filtered;
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

  // Charger les modèles d'appareils au montage du composant
  useEffect(() => {
    const loadModelsData = async () => {
      try {
        console.log('🔄 Chargement des modèles d\'appareils dans le suivi des réparations...');
        await loadDeviceModels();
        console.log('✅ Modèles d\'appareils chargés dans le suivi des réparations');
      } catch (error) {
        console.error('❌ Erreur lors du chargement des modèles d\'appareils:', error);
      }
    };
    
    loadModelsData();
  }, [loadDeviceModels]);

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

  // Debug: Afficher les modèles d'appareils
  useEffect(() => {
    console.log('📱 Modèles d\'appareils dans le store:', deviceModels.length);
    if (deviceModels.length > 0) {
      console.log('🔍 Détail des modèles chargés:');
      deviceModels.forEach((model, index) => {
        console.log(`${index + 1}. ${(model as any).brand} ${(model as any).model} (${(model as any).type}) - Actif: ${model.isActive}`);
      });
      
      // Afficher les types uniques
      const uniqueTypes = Array.from(new Set(deviceModels.map(m => (m as any).type)));
      console.log('🎯 Types uniques trouvés:', uniqueTypes);
    }
  }, [deviceModels]);

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

      // Récupérer les informations du modèle sélectionné
      const selectedModel = deviceModels.find(m => m.id === newRepair.deviceId);
      if (!selectedModel) {
        throw new Error('Modèle sélectionné non trouvé');
      }

      // Créer un appareil temporaire basé sur le modèle
      const deviceData: Omit<Device, 'id' | 'createdAt' | 'updatedAt'> = {
        brand: (selectedModel as any).brand,
        model: (selectedModel as any).model || (selectedModel as any).name,
        serialNumber: undefined,
        type: (selectedModel as any).type as any,
        specifications: {},
      };

      // Créer l'appareil dans Supabase
      await addDevice(deviceData as Device);

      // Trouver l'appareil créé
      const createdDevice = devices.find(d => 
        d.brand === deviceData.brand && 
        d.model === deviceData.model
      );

      if (!createdDevice) {
        throw new Error('Impossible de créer l\'appareil');
      }

      // Calculer le prix final après réduction
      const originalPrice = newRepair.totalPrice;
      const discountAmount = (originalPrice * newRepair.discountPercentage) / 100;
      const finalPrice = originalPrice - discountAmount;

      // Préparer les données pour Supabase (sans id, createdAt, updatedAt)
      const repairData: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'> = {
        clientId: newRepair.clientId,
        deviceId: createdDevice.id,
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
      
      // Recharger les réparations pour mettre à jour l'affichage
      await loadRepairs();
      
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
      // Validation des champs requis
      if (!newDevice.categoryId || !newDevice.brandId || !newDevice.model.trim()) {
        alert('❌ Veuillez sélectionner une catégorie, une marque et saisir un modèle.');
        return;
      }

      // Vérifier si le modèle existe déjà pour cette marque
      const existingModel = deviceModels.find(m => 
                m.brand === newDevice.brandId &&
        m.model.toLowerCase() === newDevice.model.trim().toLowerCase()
      );
      
      if (existingModel) {
        alert('❌ Un modèle avec ce nom existe déjà pour cette marque.\n\nVeuillez utiliser un nom différent.');
        return;
      }

      // Créer le nouveau modèle
      const brand = dbBrands.find(b => b.id === newDevice.brandId);
      const category = dbCategories.find(c => c.id === newDevice.categoryId);
      
      if (!brand || !category) {
        alert('❌ Erreur : marque ou catégorie introuvable.');
        return;
      }

      // Créer le modèle dans le store centralisé
      const modelData = {
        brand: brand.name,
        model: newDevice.model.trim(),
        type: category.name.toLowerCase() as any,
        year: new Date().getFullYear(),
        specifications: {},
        commonIssues: [],
        repairDifficulty: 'medium' as 'easy' | 'medium' | 'hard',
        partsAvailability: 'medium' as 'high' | 'medium' | 'low',
        isActive: true,
      };

      // Utiliser la fonction du store pour ajouter le modèle
      await addDeviceModel(modelData as any);
      
      // Créer aussi un appareil dans l'ancien système pour la compatibilité
      const deviceData: Omit<Device, 'id' | 'createdAt' | 'updatedAt'> = {
        brand: brand.name,
        model: newDevice.model.trim(),
        serialNumber: undefined, // Pas de numéro de série lors de la création d'un modèle
        type: category.name.toLowerCase() as any,
        specifications: {},
      };

      await addDevice(deviceData as Device);
      
      // Trouver le nouveau modèle créé
      const newDeviceCreated = devices.find(d => 
        d.brand === brand.name && 
        d.model === newDevice.model.trim()
      );
      
      // Sélectionner automatiquement le nouveau modèle
      if (newDeviceCreated) {
        handleNewRepairChange('deviceId', newDeviceCreated.id);
      }
      
      // Réinitialiser le formulaire
      setNewDevice({
        categoryId: '',
        brandId: '',
        model: '',
      });
      
      // Retourner à l'onglet réparation
      setActiveTab(0);
      
      alert('✅ Modèle créé avec succès et sélectionné !');
    } catch (error: any) {
      console.error('Erreur lors de la création du modèle:', error);
      alert('❌ Erreur lors de la création du modèle.\n\nVeuillez vérifier les informations saisies et réessayer.');
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
      console.log('🔍 Début de la génération du bon d\'intervention');
      console.log('📋 Données de réparation:', newRepair);
      console.log('📋 Données d\'intervention:', interventionData);
      
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
      
      console.log('👤 Client trouvé:', client);
      console.log('📱 Modèle trouvé:', selectedModel);
      
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

      console.log('📄 Données complètes pour le PDF:', completeInterventionData);

      // Générer le PDF en utilisant la fonction du composant InterventionForm
      console.log('🔄 Tentative de génération du PDF...');
      try {
        // Import dynamique pour éviter les problèmes de require
        const InterventionFormModule = await import('../../components/InterventionForm');
        console.log('✅ Module InterventionForm importé');
        
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
            
            console.log('🏢 Paramètres de l\'atelier:', workshopSettings);
            InterventionFormModule.generateInterventionPDF(completeInterventionData, tempRepair, workshopSettings);
            console.log('✅ PDF généré avec succès');
          
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
              <Tab label="Nouveau modèle" />
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
              </Grid>
              
              <Grid item xs={12} md={4}>
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
              </Grid>
              
              <Grid item xs={12} md={4}>
                <FormControl fullWidth>
                  <InputLabel>Modèle *</InputLabel>
                  <Select 
                    label="Modèle *"
                    value={newRepair.deviceId || ''}
                    onChange={(e) => handleNewRepairChange('deviceId', e.target.value)}
                    disabled={getFilteredModels().length === 0}
                  >
                    {getFilteredModels().map((model) => {
                      // Utiliser les propriétés correctes du modèle
                      const brandName = model.brand || 'N/A';
                      const modelName = model.model || 'N/A';
                      const categoryName = model.type || 'N/A';
                      
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
                  Créez un nouveau modèle pour cette réparation.
                </Alert>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Catégorie *</InputLabel>
                  <Select
                    label="Catégorie *"
                    value={newDevice.categoryId || ''}
                    onChange={(e) => setNewDevice(prev => ({ ...prev, categoryId: e.target.value }))}
                  >
                    {dbCategories
                      .filter(category => category.isActive)
                      .map((category) => (
                        <MenuItem key={category.id} value={category.id}>
                          {category.name}
                        </MenuItem>
                      ))}
                    {dbCategories.length === 0 && deviceCategories
                      .filter(category => category.isActive)
                      .map((category) => (
                        <MenuItem key={category.id} value={category.id}>
                          {category.name}
                        </MenuItem>
                      ))}
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Marque *</InputLabel>
                  <Select
                    label="Marque *"
                    value={newDevice.brandId || ''}
                    onChange={(e) => setNewDevice(prev => ({ ...prev, brandId: e.target.value }))}
                    disabled={!newDevice.categoryId}
                  >
                    {dbBrands
                      .filter(brand => brand.isActive && (!newDevice.categoryId || brand.categories.some(cat => cat.id === newDevice.categoryId)))
                      .map((brand) => (
                        <MenuItem key={brand.id} value={brand.id}>
                          {brand.name}
                        </MenuItem>
                      ))}
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Modèle *"
                  value={newDevice.model}
                  onChange={(e) => setNewDevice(prev => ({ ...prev, model: e.target.value }))}
                  disabled={!newDevice.brandId}
                />
              </Grid>
              

              
              <Grid item xs={12}>
                <Button
                  variant="contained"
                  startIcon={<DeviceHubIcon />}
                  onClick={handleCreateNewDevice}
                  disabled={Boolean(
                    !newDevice.categoryId || 
                    !newDevice.brandId || 
                    !newDevice.model
                  )}
                  fullWidth
                >
                  Créer l'appareil
                </Button>
              </Grid>
            </Grid>
          )}
          
          {activeTab === 3 && (
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

import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Divider,
  Avatar,
  LinearProgress,
  Tooltip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Switch,
  FormControlLabel
} from '@mui/material';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  CheckCircle as CheckIcon,
  Cancel as CancelIcon,
  Star as StarIcon,
  People as PeopleIcon,
  TrendingUp as TrendingUpIcon,
  History as HistoryIcon,
  Settings as SettingsIcon,
  Refresh as RefreshIcon,
  Visibility as ViewIcon,
  Edit as EditIcon,
  Delete as DeleteIcon
} from '@mui/icons-material';
import { supabase } from '../../lib/supabase';
import { toast } from 'react-hot-toast';
import LoyaltyHistory from '../../components/LoyaltyHistory/LoyaltyHistory';
import ClientForm from '../../components/ClientForm';
import LoyaltySettings from '../../components/LoyaltyManagement/LoyaltySettings';
import LoyaltySettingsTest from '../../components/LoyaltyManagement/LoyaltySettingsTest';
import LoyaltySettingsSimple from '../../components/LoyaltyManagement/LoyaltySettingsSimple';
import LoyaltySettingsDebug from '../../components/LoyaltyManagement/LoyaltySettingsDebug';
import LoyaltySettingsTestUpdate from '../../components/LoyaltyManagement/LoyaltySettingsTestUpdate';
import LoyaltySettingsTestPoints from '../../components/LoyaltyManagement/LoyaltySettingsTestPoints';
import LoyaltyIsolationDiagnostic from '../../components/LoyaltyIsolationDiagnostic';

// Types pour les données de fidélité
interface LoyaltyTier {
  id: string;
  name: string;
  description: string;
  min_points: number;
  points_required: number;
  discount_percentage: number;
  color: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface ClientLoyalty {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  loyalty_points: number;
  current_tier_id: string;
  created_at: string;
  updated_at: string;
  used_points?: number;
  tier?: LoyaltyTier;
}

interface Referral {
  id: string;
  referrer_client_id: string;
  referred_client_id: string;
  status: 'pending' | 'confirmed' | 'rejected' | 'completed';
  points_awarded: number;
  created_at: string;
  referrer_client?: {
    first_name: string;
    last_name: string;
    email: string;
  };
  referred_client?: {
    first_name: string;
    last_name: string;
    email: string;
  };
}

interface LoyaltyStatistics {
  total_clients_with_points: number;
  total_points_distributed: number;
  total_points_used: number;
  total_referrals_pending: number;
  total_referrals_confirmed: number;
  total_discounts_applied: number;
  total_discount_amount: number;
  tier_distribution: Record<string, number>;
}

// Composant principal
const Loyalty: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(true);
  const [statistics, setStatistics] = useState<LoyaltyStatistics | null>(null);
  const [clients, setClients] = useState<ClientLoyalty[]>([]);
  const [allClients, setAllClients] = useState<any[]>([]);
  const [referrals, setReferrals] = useState<Referral[]>([]);
  const [loyaltyTiers, setLoyaltyTiers] = useState<LoyaltyTier[]>([]);
  
  // États pour les dialogues
  const [referralDialog, setReferralDialog] = useState(false);
  const [pointsDialog, setPointsDialog] = useState(false);
  const [usePointsDialog, setUsePointsDialog] = useState(false);
  const [settingsDialog, setSettingsDialog] = useState(false);
  const [historyDialog, setHistoryDialog] = useState(false);
  const [selectedClient, setSelectedClient] = useState<ClientLoyalty | null>(null);
  const [selectedReferral, setSelectedReferral] = useState<Referral | null>(null);
  
  // États pour les formulaires
  const [referralForm, setReferralForm] = useState({
    referrer_client_id: '',
    referred_client_id: '',
    notes: ''
  });
  const [pointsForm, setPointsForm] = useState({
    client_id: '',
    points: 0,
    description: ''
  });
  const [usePointsForm, setUsePointsForm] = useState({
    client_id: '',
    points: 0,
    description: ''
  });
  
  // État pour la création de nouveau client
  const [showNewClientForm, setShowNewClientForm] = useState(false);

  // Charger les données
  useEffect(() => {
    loadData();
  }, []);

  // Fonction pour rafraîchir les données après modification des paramètres
  const handleSettingsDataChanged = () => {
    console.log('🔄 Rafraîchissement des données après modification des paramètres...');
    loadData();
  };

  const loadData = async () => {
    try {
      setLoading(true);
      
      // Charger les statistiques
      const { data: statsData } = await supabase.rpc('get_loyalty_statistics');
      if (statsData?.success) {
        setStatistics(statsData.data);
      }
      
      // Récupérer l'utilisateur actuel
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        console.error('❌ Aucun utilisateur connecté');
        toast.error('Erreur d\'authentification');
        return;
      }

      // Charger SEULEMENT les clients de l'utilisateur connecté pour les formulaires
      const { data: allClientsData } = await supabase
        .from('clients')
        .select('id, first_name, last_name, email')
        .eq('user_id', user.id)  // Filtrage par user_id pour l'isolation
        .order('first_name');
      setAllClients(allClientsData || []);

      // Charger SEULEMENT les clients de l'utilisateur connecté avec leurs points
      console.log('🔍 Chargement des clients avec points...');
      console.log('🔍 User ID:', user.id);
      
      // Utiliser le filtre user_id pour l'isolation
      let { data: clientsData, error: clientsError } = await supabase
        .from('clients')
        .select(`
          id,
          first_name,
          last_name,
          email,
          phone,
          loyalty_points,
          current_tier_id,
          user_id,
          created_at,
          updated_at
        `)
        .eq('user_id', user.id)  // Filtrage par user_id pour l'isolation
        .order('loyalty_points', { ascending: false });
      
      // Diagnostic si aucun client trouvé
      if (!clientsData || clientsData.length === 0) {
        console.log('⚠️ Aucun client trouvé pour user_id:', user.id);
        console.log('🔍 Vérification de l\'isolation des clients...');
        
        // Vérifier combien de clients existent au total (pour diagnostic)
        const { data: totalClientsData } = await supabase
          .from('clients')
          .select('id, user_id', { count: 'exact', head: true });
        
        console.log('📊 Total clients dans la base:', totalClientsData?.length || 0);
      }
      
      if (clientsError) {
        console.error('❌ Erreur lors du chargement des clients:', clientsError);
      } else {
        console.log('✅ Clients chargés:', clientsData?.length || 0);
        console.log('📊 Détail des clients:', clientsData);
        
        // Diagnostic supplémentaire
        if (clientsData && clientsData.length > 0) {
          console.log('🔍 Premier client:', clientsData[0]);
          console.log('🔍 Workshop ID du premier client:', clientsData[0].workshop_id);
        } else {
          console.log('⚠️ Aucun client trouvé pour workshop_id:', user.id);
        }
      }
      
      // Charger les niveaux de fidélité pour cet utilisateur uniquement
      console.log('🔍 Chargement des niveaux de fidélité...');
      const { data: tiersData, error: tiersError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .eq('workshop_id', user.id)  // Utiliser workshop_id pour les niveaux
        .order('points_required', { ascending: true });

      if (tiersError) {
        console.error('❌ Erreur lors du chargement des niveaux:', tiersError);
      } else {
        console.log('✅ Niveaux chargés:', tiersData?.length || 0);
        setLoyaltyTiers(tiersData || []);
      }

      // Charger l'historique des points pour cet utilisateur uniquement
      console.log('🔍 Chargement de l\'historique des points...');
      const { data: historyData, error: historyError } = await supabase
        .from('loyalty_points_history')
        .select('client_id, points_change')
        .eq('workshop_id', user.id)  // Utiliser workshop_id pour l'historique
        .lt('points_change', 0); // Seulement les utilisations (points négatifs)

      if (historyError) {
        console.error('❌ Erreur lors du chargement de l\'historique:', historyError);
      } else {
        console.log('✅ Historique chargé:', historyData?.length || 0);
      }

      // Calculer les points utilisés par client
      const usedPointsByClient: Record<string, number> = {};
      (historyData || []).forEach(record => {
        const clientId = record.client_id;
        usedPointsByClient[clientId] = (usedPointsByClient[clientId] || 0) + Math.abs(record.points_change);
      });

      // Associer les niveaux aux clients et calculer les points utilisés
      const clientsWithTiers = (clientsData || []).map(client => {
        // Essayer plusieurs méthodes de correspondance
        let tier = null;
        
        // Méthode 1: Correspondance exacte
        tier = (tiersData || []).find(t => t.id === client.current_tier_id);
        
        // Méthode 2: Correspondance avec conversion string
        if (!tier && client.current_tier_id) {
          tier = (tiersData || []).find(t => String(t.id) === String(client.current_tier_id));
        }
        
        // Méthode 3: Correspondance par nom si current_tier_id est null
        if (!tier && !client.current_tier_id) {
          // Assigner le niveau selon les points
          if (client.loyalty_points >= 2000) {
            tier = (tiersData || []).find(t => t.name === 'Diamant');
          } else if (client.loyalty_points >= 1000) {
            tier = (tiersData || []).find(t => t.name === 'Platine');
          } else if (client.loyalty_points >= 500) {
            tier = (tiersData || []).find(t => t.name === 'Or');
          } else if (client.loyalty_points >= 100) {
            tier = (tiersData || []).find(t => t.name === 'Argent');
          } else {
            tier = (tiersData || []).find(t => t.name === 'Bronze');
          }
        }
        
        const usedPoints = usedPointsByClient[client.id] || 0;
        
        // Log d'erreur si aucun tier trouvé
        if (!tier && client.current_tier_id) {
          console.log(`⚠️ Client ${client.first_name} a un current_tier_id (${client.current_tier_id}) mais aucun tier trouvé`);
        }
        
        // Si aucun tier trouvé, créer un tier virtuel selon les points
        let finalTier = tier;
        if (!finalTier) {
          // Créer un tier virtuel selon les points
          if (client.loyalty_points >= 2000) {
            finalTier = { name: 'Diamant', color: '#B9F2FF', discount_percentage: 20 };
          } else if (client.loyalty_points >= 1000) {
            finalTier = { name: 'Platine', color: '#E5E4E2', discount_percentage: 15 };
          } else if (client.loyalty_points >= 500) {
            finalTier = { name: 'Or', color: '#FFD700', discount_percentage: 10 };
          } else if (client.loyalty_points >= 100) {
            finalTier = { name: 'Argent', color: '#C0C0C0', discount_percentage: 5 };
          } else {
            finalTier = { name: 'Bronze', color: '#CD7F32', discount_percentage: 0 };
          }
        }
        
        // Log final (après la déclaration de finalTier)
        console.log(`🔍 Client ${client.first_name} ${client.last_name}:`, {
          points: client.loyalty_points,
          current_tier_id: client.current_tier_id,
          tier_trouve: tier ? tier.name : 'Aucun',
          tier_id_trouve: tier ? tier.id : null,
          tier_object: tier,
          final_tier: finalTier ? finalTier.name : 'Aucun'
        });
        
        return {
          ...client,
          tier: finalTier,
          used_points: usedPoints
        };
      });

      setClients(clientsWithTiers);
      
      // Charger les parrainages pour cet utilisateur uniquement (avec gestion d'erreur)
      let referralsData = [];
      try {
        const { data: referralsResult, error: referralsError } = await supabase
          .from('referrals')
          .select(`
            *,
            referrer_client:clients!referrals_referrer_client_id_fkey(first_name, last_name, email),
            referred_client:clients!referrals_referred_client_id_fkey(first_name, last_name, email)
          `)
          .eq('workshop_id', user.id)  // Utiliser workshop_id pour les parrainages
          .order('created_at', { ascending: false });
        
        if (referralsError) {
          console.warn('⚠️ Erreur lors du chargement des parrainages:', referralsError);
          referralsData = [];
        } else {
          referralsData = referralsResult || [];
        }
      } catch (error) {
        console.warn('⚠️ Erreur lors du chargement des parrainages:', error);
        referralsData = [];
      }
      setReferrals(referralsData || []);
      
          } catch (error) {
        console.error('Erreur lors du chargement des données:', error);
        toast.error('Erreur lors du chargement des données');
      } finally {
        setLoading(false);
      }
      
      // Debug: afficher le nombre de clients chargés
      console.log('Clients chargés:', allClients.length);
      console.log('Clients avec points:', clients.length);
  };

  // Créer un parrainage
  const createReferral = async () => {
    try {
      const { data, error } = await supabase.rpc('create_referral', {
        p_referrer_client_id: referralForm.referrer_client_id,
        p_referred_client_id: referralForm.referred_client_id,
        p_notes: referralForm.notes
      });
      
      if (error) throw error;
      
      if (data?.success) {
        toast.success('Parrainage créé avec succès');
        setReferralDialog(false);
        setReferralForm({ referrer_client_id: '', referred_client_id: '', notes: '' });
        loadData();
      } else {
        toast.error(data?.error || 'Erreur lors de la création du parrainage');
      }
    } catch (error) {
      console.error('Erreur:', error);
      toast.error('Erreur lors de la création du parrainage');
    }
  };

  // Confirmer un parrainage
  const confirmReferral = async (referralId: string) => {
    try {
      const { data, error } = await supabase.rpc('confirm_referral', {
        p_referral_id: referralId
      });
      
      if (error) throw error;
      
      if (data?.success) {
        toast.success('Parrainage confirmé avec succès');
        loadData();
      } else {
        toast.error(data?.error || 'Erreur lors de la confirmation');
      }
    } catch (error) {
      console.error('Erreur:', error);
      toast.error('Erreur lors de la confirmation');
    }
  };

  // Rejeter un parrainage
  const rejectReferral = async (referralId: string) => {
    try {
      const { data, error } = await supabase.rpc('reject_referral', {
        p_referral_id: referralId
      });
      
      if (error) throw error;
      
      if (data?.success) {
        toast.success('Parrainage rejeté');
        loadData();
      } else {
        toast.error(data?.error || 'Erreur lors du rejet');
      }
    } catch (error) {
      console.error('Erreur:', error);
      toast.error('Erreur lors du rejet');
    }
  };

  // Supprimer un parrainage
  const handleDeleteReferral = async (referralId: string) => {
    try {
      // Confirmation de suppression
      const confirmed = window.confirm(
        'Êtes-vous sûr de vouloir supprimer ce parrainage ? Cette action est irréversible.'
      );
      
      if (!confirmed) return;
      
      // Supprimer le parrainage
      const { error } = await supabase
        .from('referrals')
        .delete()
        .eq('id', referralId);
      
      if (error) {
        console.error('Erreur lors de la suppression du parrainage:', error);
        toast.error('Erreur lors de la suppression du parrainage');
        return;
      }
      
      toast.success('Parrainage supprimé avec succès');
      loadData(); // Recharger les données
    } catch (error) {
      console.error('Erreur lors de la suppression du parrainage:', error);
      toast.error('Erreur lors de la suppression du parrainage');
    }
  };

  // Créer un nouveau client
  const handleCreateNewClient = async (clientData: any) => {
    try {
      // Convertir les données du formulaire vers le format de la base de données
      const clientToInsert = {
        first_name: clientData.firstName,
        last_name: clientData.lastName,
        email: clientData.email,
        phone: clientData.mobile,
        address: clientData.address,
        city: clientData.city,
        postal_code: clientData.postalCode,
        region: clientData.region,
        company_name: clientData.companyName,
        vat_number: clientData.vatNumber,
        siren_number: clientData.sirenNumber,
        country_code: clientData.countryCode,
        address_complement: clientData.addressComplement,
        billing_address: clientData.billingAddress,
        billing_address_complement: clientData.billingAddressComplement,
        billing_region: clientData.billingRegion,
        billing_postal_code: clientData.billingPostalCode,
        billing_city: clientData.billingCity,
        accounting_code: clientData.accountingCode,
        cni_identifier: clientData.cniIdentifier,
        internal_note: clientData.internalNote,
        status: clientData.status,
        sms_notification: clientData.smsNotification,
        email_notification: clientData.emailNotification,
        sms_marketing: clientData.smsMarketing,
        email_marketing: clientData.emailMarketing,
        category: clientData.category,
        title: clientData.title
      };
      
      const { data, error } = await supabase
        .from('clients')
        .insert([clientToInsert])
        .select()
        .single();
      
      if (error) throw error;
      
      if (data) {
        toast.success('Client créé avec succès');
        setShowNewClientForm(false);
        
        // Mettre à jour la liste des clients et sélectionner le nouveau client
        await loadData();
        setReferralForm({ ...referralForm, referred_client_id: data.id });
      }
    } catch (error) {
      console.error('Erreur lors de la création du client:', error);
      toast.error('Erreur lors de la création du client');
    }
  };

  // Ajouter des points manuellement
  const addPoints = async () => {
    try {
      console.log('🔍 Appel add_loyalty_points avec:', {
        p_client_id: pointsForm.client_id,
        p_points: pointsForm.points,
        p_description: pointsForm.description
      });

      const { data, error } = await supabase.rpc('add_loyalty_points', {
        p_client_id: pointsForm.client_id,
        p_points: pointsForm.points,
        p_description: pointsForm.description
      });
      
      console.log('📊 Réponse Supabase:', { data, error });
      
      if (error) {
        console.error('❌ Erreur Supabase:', error);
        throw error;
      }
      
      if (data?.success) {
        console.log('✅ Points ajoutés avec succès:', data);
        
        // Mettre à jour les niveaux après l'ajout de points (temporairement sans isolation)
        try {
          const { data: tierData, error: tierError } = await supabase.rpc('update_client_tiers');
          if (tierError) {
            console.warn('⚠️ Erreur lors de la mise à jour des niveaux:', tierError);
          } else {
            console.log('✅ Niveaux mis à jour:', tierData);
          }
        } catch (tierError) {
          console.warn('⚠️ Exception lors de la mise à jour des niveaux:', tierError);
        }
        
        toast.success('Points ajoutés avec succès');
        setPointsDialog(false);
        setPointsForm({ client_id: '', points: 0, description: '' });
        loadData();
      } else {
        console.error('❌ Erreur dans la réponse:', data?.error);
        toast.error(data?.error || 'Erreur lors de l\'ajout des points');
      }
    } catch (error) {
      console.error('💥 Exception dans addPoints:', error);
      toast.error('Erreur lors de l\'ajout des points');
    }
  };

  // Utiliser des points
  const usePoints = async () => {
    try {
      console.log('🔍 Appel use_loyalty_points avec:', {
        p_client_id: usePointsForm.client_id,
        p_points: usePointsForm.points,
        p_description: usePointsForm.description
      });

      const { data, error } = await supabase.rpc('use_loyalty_points', {
        p_client_id: usePointsForm.client_id,
        p_points: usePointsForm.points,
        p_description: usePointsForm.description
      });
      
      console.log('📊 Réponse Supabase:', { data, error });
      
      if (error) {
        console.error('❌ Erreur Supabase:', error);
        throw error;
      }
      
      if (data?.success) {
        console.log('✅ Points utilisés avec succès:', data);
        toast.success('Points utilisés avec succès');
        setUsePointsDialog(false);
        setUsePointsForm({ client_id: '', points: 0, description: '' });
        loadData();
      } else {
        console.error('❌ Erreur dans la réponse:', data?.error);
        toast.error(data?.error || 'Erreur lors de l\'utilisation des points');
      }
    } catch (error) {
      console.error('💥 Exception dans usePoints:', error);
      toast.error('Erreur lors de l\'utilisation des points');
    }
  };

  // Supprimer un client
  const handleDeleteClient = async (clientId: string) => {
    try {
      // Confirmation de suppression
      const confirmed = window.confirm(
        'Êtes-vous sûr de vouloir supprimer ce client ? Cette action est irréversible et supprimera également tous ses points de fidélité.'
      );
      
      if (!confirmed) return;
      
      // Supprimer le client
      const { error } = await supabase
        .from('clients')
        .delete()
        .eq('id', clientId);
      
      if (error) {
        console.error('Erreur lors de la suppression du client:', error);
        toast.error('Erreur lors de la suppression du client');
        return;
      }
      
      toast.success('Client supprimé avec succès');
      loadData(); // Recharger les données
    } catch (error) {
      console.error('Erreur lors de la suppression du client:', error);
      toast.error('Erreur lors de la suppression du client');
    }
  };

  // Supprimer les points de fidélité d'un client
  const handleDeleteLoyaltyPoints = async (clientId: string) => {
    try {
      // Confirmation de suppression
      const confirmed = window.confirm(
        'Êtes-vous sûr de vouloir supprimer tous les points de fidélité de ce client ? Cette action est irréversible.'
      );
      
      if (!confirmed) return;
      
      // Supprimer les points de fidélité du client
      const { error } = await supabase
        .from('client_loyalty_points')
        .delete()
        .eq('client_id', clientId);
      
      if (error) {
        console.error('Erreur lors de la suppression des points de fidélité:', error);
        toast.error('Erreur lors de la suppression des points de fidélité');
        return;
      }
      
      toast.success('Points de fidélité supprimés avec succès');
      loadData(); // Recharger les données
    } catch (error) {
      console.error('Erreur lors de la suppression des points de fidélité:', error);
      toast.error('Erreur lors de la suppression des points de fidélité');
    }
  };

  // Obtenir le statut coloré
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'warning';
      case 'confirmed': return 'success';
      case 'rejected': return 'error';
      case 'completed': return 'info';
      default: return 'default';
    }
  };

  // Obtenir le texte du statut
  const getStatusText = (status: string) => {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmé';
      case 'rejected': return 'Rejeté';
      case 'completed': return 'Terminé';
      default: return status;
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h4" component="h1" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <StarIcon color="primary" />
          Gestion des Points de Fidélité
        </Typography>
        <Box>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={loadData}
            sx={{ mr: 1 }}
          >
            Actualiser
          </Button>
          <Button
            variant="contained"
            startIcon={<SettingsIcon />}
            onClick={() => setSettingsDialog(true)}
          >
            Paramètres
          </Button>
        </Box>
      </Box>

      {/* Diagnostic d'isolation */}
      <LoyaltyIsolationDiagnostic />

      {/* Statistiques */}
      {statistics && (
        <Grid container spacing={3} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <PeopleIcon color="primary" sx={{ mr: 1 }} />
                  <Box>
                    <Typography variant="h6">{statistics.total_clients_with_points}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Clients avec points
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <TrendingUpIcon color="success" sx={{ mr: 1 }} />
                  <Box>
                    <Typography variant="h6">{statistics.total_points_distributed}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Points distribués
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <HistoryIcon color="info" sx={{ mr: 1 }} />
                  <Box>
                    <Typography variant="h6">{statistics.total_referrals_pending}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Parrainages en attente
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <StarIcon color="warning" sx={{ mr: 1 }} />
                  <Box>
                    <Typography variant="h6">{statistics.total_discounts_applied}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Réductions appliquées
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Onglets */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={activeTab} onChange={(_, newValue) => {
          setActiveTab(newValue);
          // Recharger les données quand on change d'onglet pour s'assurer que les niveaux sont à jour
          if (newValue === 0) {
            loadData();
          }
        }}>
          <Tab label="Clients Fidèles" />
          <Tab label="Parrainages" />
          <Tab label="Niveaux de Fidélité" />
        </Tabs>
      </Paper>

      {/* Contenu des onglets */}
      {activeTab === 0 && (
        <Box>
                     <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
             <Typography variant="h6">Clients avec Points de Fidélité</Typography>
             <Box sx={{ display: 'flex', gap: 1 }}>
               <Button
                 variant="contained"
                 startIcon={<AddIcon />}
                 onClick={() => setPointsDialog(true)}
                 disabled={allClients.length === 0}
               >
                 Ajouter des Points
               </Button>
               <Button
                 variant="outlined"
                 color="warning"
                 startIcon={<RemoveIcon />}
                 onClick={() => setUsePointsDialog(true)}
                 disabled={allClients.length === 0}
               >
                 Utiliser des Points
               </Button>
               <Button
                 variant="outlined"
                 startIcon={<RefreshIcon />}
                 onClick={loadData}
               >
                 Actualiser
               </Button>
             </Box>
           </Box>
           
           {allClients.length === 0 && (
             <Alert severity="info" sx={{ mb: 2 }}>
               Aucun client trouvé. Veuillez d'abord créer des clients dans la section Transaction → Clients.
             </Alert>
           )}
          
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Client</TableCell>
                  <TableCell>Points Totaux</TableCell>
                  <TableCell>Points Utilisés</TableCell>
                  <TableCell>Points Disponibles</TableCell>
                  <TableCell>Niveau Actuel</TableCell>
                  <TableCell>Progression</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {clients.map((client) => {
                  const availablePoints = (client.loyalty_points || 0) - (client.used_points || 0);
                  const nextTier = loyaltyTiers.find(t => t.points_required > availablePoints);
                  const progress = nextTier 
                    ? ((availablePoints - (client.tier?.points_required || 0)) / (nextTier.points_required - (client.tier?.points_required || 0))) * 100
                    : 100;
                  
                  return (
                    <TableRow key={client.id}>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Avatar sx={{ bgcolor: client.tier?.color || 'grey.500' }}>
                            {client.first_name?.[0]}{client.last_name?.[0]}
                          </Avatar>
                          <Box>
                            <Typography variant="body2">
                              {client.first_name} {client.last_name}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {client.email}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>{client.loyalty_points || 0}</TableCell>
                      <TableCell>{client.used_points}</TableCell>
                      <TableCell>
                        <Typography variant="body2" color="primary" fontWeight="bold">
                          {availablePoints}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {client.tier ? (
                          <Chip
                            label={client.tier.name}
                            sx={{ bgcolor: client.tier.color, color: 'white' }}
                            size="small"
                          />
                        ) : (
                          <Chip
                            label="Sans niveau"
                            sx={{ bgcolor: '#ccc', color: 'white' }}
                            size="small"
                          />
                        )}
                      </TableCell>
                      <TableCell>
                        <Box sx={{ width: '100%', maxWidth: 200 }}>
                          <LinearProgress
                            variant="determinate"
                            value={Math.min(progress, 100)}
                            sx={{ height: 8, borderRadius: 4 }}
                          />
                          {nextTier && (
                            <Typography variant="caption" color="text.secondary">
                              {Math.round(progress)}% vers {nextTier.name}
                            </Typography>
                          )}
                        </Box>
                      </TableCell>
                                             <TableCell>
                         <Tooltip title="Voir l'historique">
                           <IconButton 
                             size="small"
                             onClick={() => {
                               setSelectedClient(client);
                               setHistoryDialog(true);
                             }}
                           >
                             <ViewIcon />
                           </IconButton>
                         </Tooltip>
                        <Tooltip title="Modifier les points">
                          <IconButton 
                            size="small"
                            onClick={() => {
                              setSelectedClient(client);
                              setPointsForm({
                                client_id: client.id,
                                points: 0,
                                description: ''
                              });
                              setPointsDialog(true);
                            }}
                          >
                            <EditIcon />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Supprimer le client">
                          <IconButton 
                            size="small"
                            color="error"
                            onClick={() => handleDeleteClient(client.id)}
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Supprimer les points de fidélité">
                          <IconButton 
                            size="small"
                            color="warning"
                            onClick={() => handleDeleteLoyaltyPoints(client.id)}
                          >
                            <CancelIcon />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        </Box>
      )}

      {activeTab === 1 && (
        <Box>
                     <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
             <Typography variant="h6">Parrainages</Typography>
             <Button
               variant="contained"
               startIcon={<AddIcon />}
               onClick={() => setReferralDialog(true)}
               disabled={allClients.length === 0}
             >
               Créer un Parrainage
             </Button>
           </Box>
           
           {allClients.length === 0 && (
             <Alert severity="info" sx={{ mb: 2 }}>
               Aucun client trouvé. Veuillez d'abord créer des clients dans la section Transaction → Clients.
             </Alert>
           )}
          
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Parrain</TableCell>
                  <TableCell>Parrainé</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Points Attribués</TableCell>
                  <TableCell>Date de Création</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {referrals.map((referral) => (
                  <TableRow key={referral.id}>
                    <TableCell>
                      <Typography variant="body2">
                        {referral.referrer_client?.first_name} {referral.referrer_client?.last_name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {referral.referrer_client?.email}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {referral.referred_client?.first_name} {referral.referred_client?.last_name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {referral.referred_client?.email}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getStatusText(referral.status)}
                        color={getStatusColor(referral.status) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {referral.points_awarded > 0 ? (
                        <Typography variant="body2" color="success.main" fontWeight="bold">
                          +{referral.points_awarded}
                        </Typography>
                      ) : (
                        <Typography variant="body2" color="text.secondary">
                          -
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      {new Date(referral.created_at).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell>
                      {referral.status === 'pending' && (
                        <>
                          <Tooltip title="Confirmer">
                            <IconButton
                              size="small"
                              color="success"
                              onClick={() => confirmReferral(referral.id)}
                            >
                              <CheckIcon />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Rejeter">
                            <IconButton
                              size="small"
                              color="error"
                              onClick={() => rejectReferral(referral.id)}
                            >
                              <CancelIcon />
                            </IconButton>
                          </Tooltip>
                        </>
                      )}
                      <Tooltip title="Supprimer le parrainage">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => handleDeleteReferral(referral.id)}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Box>
      )}

      {activeTab === 2 && (
        <Box>
          <Typography variant="h6" sx={{ mb: 2 }}>Niveaux de Fidélité</Typography>
          
          <Grid container spacing={3}>
                            {loyaltyTiers.map((tier) => (
              <Grid item xs={12} sm={6} md={4} key={tier.id}>
                <Card>
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <Avatar sx={{ bgcolor: tier.color, mr: 2 }}>
                        <StarIcon />
                      </Avatar>
                      <Box>
                        <Typography variant="h6">{tier.name}</Typography>
                        <Typography variant="body2" color="text.secondary">
                          {tier.points_required} points requis
                        </Typography>
                      </Box>
                    </Box>
                    <Typography variant="h4" color="primary" sx={{ mb: 1 }}>
                      {tier.discount_percentage}%
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {tier.description}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {/* Dialogue de création de parrainage */}
      <Dialog open={referralDialog} onClose={() => setReferralDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Créer un Parrainage</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            {allClients.length === 0 ? (
              <Alert severity="warning" sx={{ mb: 2 }}>
                Aucun client trouvé. Veuillez d'abord créer des clients dans la section Transaction.
              </Alert>
            ) : (
              <>
                <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Client Parrain</InputLabel>
                             <Select
                 value={referralForm.referrer_client_id}
                 onChange={(e) => setReferralForm({ ...referralForm, referrer_client_id: e.target.value })}
                 label="Client Parrain"
               >
                 {allClients.map((client) => (
                   <MenuItem key={client.id} value={client.id}>
                     {client.first_name} {client.last_name} ({client.email})
                   </MenuItem>
                 ))}
               </Select>
            </FormControl>
            
            {referralForm.referrer_client_id && (
              <Box sx={{ mb: 2, display: 'flex', justifyContent: 'flex-end' }}>
                <Button
                  variant="outlined"
                  color="error"
                  size="small"
                  startIcon={<DeleteIcon />}
                  onClick={() => handleDeleteClient(referralForm.referrer_client_id)}
                >
                  Supprimer ce client
                </Button>
              </Box>
            )}
            
                         <FormControl fullWidth sx={{ mb: 2 }}>
               <InputLabel>Client Parrainé</InputLabel>
               <Select
                 value={referralForm.referred_client_id}
                 onChange={(e) => setReferralForm({ ...referralForm, referred_client_id: e.target.value })}
                 label="Client Parrainé"
               >
                 {allClients.map((client) => (
                   <MenuItem key={client.id} value={client.id}>
                     {client.first_name} {client.last_name} ({client.email})
                   </MenuItem>
                 ))}
               </Select>
             </FormControl>
             
             {referralForm.referred_client_id && (
               <Box sx={{ mb: 2, display: 'flex', justifyContent: 'flex-end' }}>
                 <Button
                   variant="outlined"
                   color="error"
                   size="small"
                   startIcon={<DeleteIcon />}
                   onClick={() => handleDeleteClient(referralForm.referred_client_id)}
                 >
                   Supprimer ce client
                 </Button>
               </Box>
             )}
             
             <Box sx={{ display: 'flex', justifyContent: 'center', mb: 2 }}>
               <Button
                 variant="outlined"
                 startIcon={<AddIcon />}
                 onClick={() => setShowNewClientForm(true)}
                 sx={{ borderStyle: 'dashed' }}
               >
                 Créer un nouveau client
               </Button>
             </Box>
            
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Notes"
              value={referralForm.notes}
              onChange={(e) => setReferralForm({ ...referralForm, notes: e.target.value })}
            />
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setReferralDialog(false)}>Annuler</Button>
          <Button onClick={createReferral} variant="contained">
            Créer le Parrainage
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue de création de nouveau client */}
      <ClientForm
        open={showNewClientForm}
        onClose={() => setShowNewClientForm(false)}
        onSubmit={handleCreateNewClient}
        existingEmails={allClients.map(client => client.email)}
      />

      {/* Dialogue d'ajout de points */}
      <Dialog open={pointsDialog} onClose={() => setPointsDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Ajouter des Points</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            {allClients.length === 0 ? (
              <Alert severity="warning" sx={{ mb: 2 }}>
                Aucun client trouvé. Veuillez d'abord créer des clients dans la section Transaction.
              </Alert>
            ) : (
              <>
                <FormControl fullWidth sx={{ mb: 2 }}>
               <InputLabel>Client</InputLabel>
               <Select
                 value={pointsForm.client_id}
                 onChange={(e) => setPointsForm({ ...pointsForm, client_id: e.target.value })}
                 label="Client"
               >
                 {allClients.map((client) => (
                   <MenuItem key={client.id} value={client.id}>
                     {client.first_name} {client.last_name} ({client.email})
                   </MenuItem>
                 ))}
               </Select>
             </FormControl>
             
             {pointsForm.client_id && (
               <Box sx={{ mb: 2, display: 'flex', justifyContent: 'flex-end' }}>
                 <Button
                   variant="outlined"
                   color="error"
                   size="small"
                   startIcon={<DeleteIcon />}
                   onClick={() => handleDeleteClient(pointsForm.client_id)}
                 >
                   Supprimer ce client
                 </Button>
               </Box>
             )}
            
            <TextField
              fullWidth
              type="number"
              label="Points à ajouter"
              value={pointsForm.points}
              onChange={(e) => setPointsForm({ ...pointsForm, points: parseInt(e.target.value) || 0 })}
              sx={{ mb: 2 }}
            />
            
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Description"
              value={pointsForm.description}
              onChange={(e) => setPointsForm({ ...pointsForm, description: e.target.value })}
            />
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPointsDialog(false)}>Annuler</Button>
          <Button onClick={addPoints} variant="contained">
            Ajouter les Points
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue d'utilisation de points */}
      <Dialog open={usePointsDialog} onClose={() => setUsePointsDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Utiliser des Points</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            {allClients.length === 0 ? (
              <Alert severity="warning" sx={{ mb: 2 }}>
                Aucun client trouvé. Veuillez d'abord créer des clients dans la section Transaction.
              </Alert>
            ) : (
              <>
                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Client</InputLabel>
                  <Select
                    value={usePointsForm.client_id}
                    onChange={(e) => setUsePointsForm({ ...usePointsForm, client_id: e.target.value })}
                    label="Client"
                  >
                    {allClients.map((client) => (
                      <MenuItem key={client.id} value={client.id}>
                        {client.first_name} {client.last_name} ({client.email})
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
                
                {usePointsForm.client_id && (
                  <Box sx={{ mb: 2, display: 'flex', justifyContent: 'flex-end' }}>
                    <Button
                      variant="outlined"
                      color="error"
                      size="small"
                      startIcon={<DeleteIcon />}
                      onClick={() => handleDeleteClient(usePointsForm.client_id)}
                    >
                      Supprimer ce client
                    </Button>
                  </Box>
                )}
                
                <TextField
                  fullWidth
                  type="number"
                  label="Points à utiliser"
                  value={usePointsForm.points}
                  onChange={(e) => setUsePointsForm({ ...usePointsForm, points: parseInt(e.target.value) || 0 })}
                  sx={{ mb: 2 }}
                />
                
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="Description"
                  value={usePointsForm.description}
                  onChange={(e) => setUsePointsForm({ ...usePointsForm, description: e.target.value })}
                />
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setUsePointsDialog(false)}>Annuler</Button>
          <Button onClick={usePoints} variant="contained" color="warning">
            Utiliser les Points
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue des paramètres - Composant simple */}
      <Dialog open={settingsDialog} onClose={() => setSettingsDialog(false)} maxWidth="xl" fullWidth>
        <DialogTitle>Paramètres de Fidélité</DialogTitle>
        <DialogContent>
          <LoyaltySettingsSimple onDataChanged={handleSettingsDataChanged} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSettingsDialog(false)}>Fermer</Button>
        </DialogActions>
      </Dialog>

       {/* Dialogue d'historique des points */}
       <LoyaltyHistory
         open={historyDialog}
         onClose={() => setHistoryDialog(false)}
                   clientId={selectedClient?.id || ''}
          clientName={selectedClient ? `${selectedClient.first_name} ${selectedClient.last_name}` : ''}
       />
     </Box>
   );
 };

export default Loyalty;

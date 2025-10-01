import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Chip,
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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Avatar,
  Tooltip,
  Badge,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  Menu,
  MenuList,
} from '@mui/material';
import {
  RequestQuote as RequestQuoteIcon,
  Visibility as VisibilityIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Schedule as ScheduleIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Build as BuildIcon,
  AttachFile as AttachFileIcon,
  TrendingUp as TrendingUpIcon,
  Add as AddIcon,
  Link as LinkIcon,
  ContentCopy as ContentCopyIcon,
  MoreVert as MoreVertIcon,
  PowerSettingsNew as PowerSettingsNewIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { toast } from 'react-hot-toast';
// Types simplifiés pour éviter les erreurs de compilation
interface QuoteRequest {
  id: string;
  requestNumber: string;
  customUrl: string;
  technicianId: string;
  clientFirstName: string;
  clientLastName: string;
  clientEmail: string;
  clientPhone: string;
  description: string;
  deviceType?: string;
  deviceBrand?: string;
  deviceModel?: string;
  issueDescription: string;
  urgency: 'low' | 'medium' | 'high';
  attachments: any[];
  status: 'pending' | 'in_review' | 'quoted' | 'accepted' | 'rejected' | 'completed';
  priority: 'low' | 'medium' | 'high';
  source: 'website' | 'mobile' | 'api';
  createdAt: Date;
  updatedAt: Date;
  // Nouveaux champs client
  company?: string;
  vatNumber?: string;
  sirenNumber?: string;
  // Nouveaux champs adresse
  address?: string;
  addressComplement?: string;
  city?: string;
  postalCode?: string;
  region?: string;
  // Nouveaux champs appareil
  deviceId?: string;
  color?: string;
  accessories?: string;
  deviceRemarks?: string;
}

interface QuoteRequestStats {
  total: number;
  pending: number;
  inReview: number;
  quoted: number;
  accepted: number;
  rejected: number;
  byUrgency: Record<string, number>;
  byStatus: Record<string, number>;
  monthly: number;
  weekly: number;
  daily: number;
}

interface TechnicianCustomUrl {
  id: string;
  technicianId: string;
  customUrl: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}
// import { useAppStore } from '../../store'; // Temporairement désactivé pour éviter les erreurs
import { quoteRequestServiceReal } from '../../services/quoteRequestServiceReal';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`quote-tabpanel-${index}`}
      aria-labelledby={`quote-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const QuoteRequestsManagement: React.FC = () => {
  // Utilisation d'un utilisateur simulé temporaire
  // TODO: Remplacer par l'utilisateur authentifié du store
  const currentUser = {
    id: 'temp-user-id', // Sera remplacé par l'ID de l'utilisateur authentifié
    firstName: 'Jean',
    lastName: 'Dupont',
    email: 'jean.dupont@atelier.com'
  };
  const [tabValue, setTabValue] = useState(0);
  const [quoteRequests, setQuoteRequests] = useState<QuoteRequest[]>([]);
  const [stats, setStats] = useState<QuoteRequestStats | null>(null);
  const [customUrls, setCustomUrls] = useState<TechnicianCustomUrl[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedRequest, setSelectedRequest] = useState<QuoteRequest | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isUrlDialogOpen, setIsUrlDialogOpen] = useState(false);
  const [isEditUrlDialogOpen, setIsEditUrlDialogOpen] = useState(false);
  const [newCustomUrl, setNewCustomUrl] = useState('');
  const [editingUrl, setEditingUrl] = useState<TechnicianCustomUrl | null>(null);
  const [editCustomUrl, setEditCustomUrl] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedUrlForMenu, setSelectedUrlForMenu] = useState<TechnicianCustomUrl | null>(null);

  // Chargement des données depuis l'API
  useEffect(() => {
    const loadData = async () => {
      if (!currentUser?.id) return;
      
      setIsLoading(true);
      
      try {
        // Charger les demandes de devis
        const requests = await quoteRequestServiceReal.getQuoteRequestsByTechnician(currentUser.id);
        setQuoteRequests(requests);

        // Charger les statistiques
        const statistics = await quoteRequestServiceReal.getQuoteRequestStats(currentUser.id);
        setStats(statistics);

        // Charger les URLs personnalisées
        const urls = await quoteRequestServiceReal.getCustomUrls(currentUser.id);
        setCustomUrls(urls);
        
      } catch (error) {
        console.error('Erreur lors du chargement:', error);
        toast.error('Erreur lors du chargement des données');
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [currentUser?.id]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleRefresh = async () => {
    if (!currentUser?.id) return;
    
    setIsLoading(true);
    
    try {
      // Recharger les demandes de devis
      const requests = await quoteRequestServiceReal.getQuoteRequestsByTechnician(currentUser.id);
      setQuoteRequests(requests);

      // Recharger les statistiques
      const statistics = await quoteRequestServiceReal.getQuoteRequestStats(currentUser.id);
      setStats(statistics);

      // Recharger les URLs personnalisées
      const urls = await quoteRequestServiceReal.getCustomUrls(currentUser.id);
      setCustomUrls(urls);
      
      toast.success('Données actualisées');
    } catch (error) {
      console.error('Erreur lors du rechargement:', error);
      toast.error('Erreur lors du rechargement des données');
    } finally {
      setIsLoading(false);
    }
  };

  const handleViewRequest = (request: QuoteRequest) => {
    setSelectedRequest(request);
    setIsDialogOpen(true);
  };

  const handleUpdateStatus = async (requestId: string, newStatus: string) => {
    try {
      const success = await quoteRequestServiceReal.updateQuoteRequestStatus(requestId, newStatus);
      if (success) {
        // Recharger les données
        if (currentUser?.id) {
          const requests = await quoteRequestServiceReal.getQuoteRequestsByTechnician(currentUser.id);
          setQuoteRequests(requests);
          
          const statistics = await quoteRequestServiceReal.getQuoteRequestStats(currentUser.id);
          setStats(statistics);
        }
        toast.success('Statut mis à jour avec succès');
      } else {
        toast.error('Erreur lors de la mise à jour du statut');
      }
    } catch (error) {
      console.error('Erreur lors de la mise à jour:', error);
      toast.error('Erreur lors de la mise à jour du statut');
    }
  };

  const handleReply = (request: QuoteRequest) => {
    // Créer un lien mailto avec les informations du client
    const subject = `Réponse à votre demande de devis ${request.requestNumber}`;
    const body = `Bonjour ${request.clientFirstName} ${request.clientLastName},\n\nMerci pour votre demande de devis.\n\nCordialement,\n[Votre nom]`;
    const mailtoLink = `mailto:${request.clientEmail}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    
    // Ouvrir le client email
    window.open(mailtoLink, '_blank');
  };

  const handleAddCustomUrl = async () => {
    if (!newCustomUrl.trim()) {
      toast.error('Veuillez saisir une URL personnalisée');
      return;
    }

    if (!currentUser?.id) {
      toast.error('Utilisateur non connecté');
      return;
    }

    try {
      const newUrl = await quoteRequestServiceReal.createCustomUrl(
        currentUser.id, 
        newCustomUrl.trim()
      );

      if (newUrl) {
        setCustomUrls(prev => [...prev, newUrl]);
        setNewCustomUrl('');
        setIsUrlDialogOpen(false);
        toast.success('URL personnalisée ajoutée');
      } else {
        toast.error('Erreur lors de la création de l\'URL');
      }
    } catch (error) {
      console.error('Erreur:', error);
      toast.error('Erreur lors de la création de l\'URL');
    }
  };

  const handleEditUrl = (url: TechnicianCustomUrl) => {
    setEditingUrl(url);
    setEditCustomUrl(url.customUrl);
    setIsEditUrlDialogOpen(true);
  };

  const handleUpdateCustomUrl = async () => {
    if (!editCustomUrl.trim()) {
      toast.error('Veuillez saisir une URL personnalisée');
      return;
    }

    if (!editingUrl) {
      toast.error('Erreur: URL à modifier non trouvée');
      return;
    }

    try {
      const success = await quoteRequestServiceReal.updateCustomUrl(
        editingUrl.id, 
        editCustomUrl.trim()
      );

      if (success) {
        setCustomUrls(prev => 
          prev.map(url => 
            url.id === editingUrl.id 
              ? { ...url, customUrl: editCustomUrl.trim(), updatedAt: new Date() }
              : url
          )
        );

        setEditingUrl(null);
        setEditCustomUrl('');
        setIsEditUrlDialogOpen(false);
        toast.success('URL personnalisée modifiée');
      } else {
        toast.error('Erreur lors de la modification de l\'URL');
      }
    } catch (error) {
      console.error('Erreur:', error);
      toast.error('Erreur lors de la modification de l\'URL');
    }
  };

  const handleDeleteUrl = async (urlId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cette URL personnalisée ?')) {
      try {
        const success = await quoteRequestServiceReal.deleteCustomUrl(urlId);
        
        if (success) {
          setCustomUrls(prev => prev.filter(url => url.id !== urlId));
          toast.success('URL personnalisée supprimée');
        } else {
          toast.error('Impossible de supprimer cette URL (des demandes y sont associées)');
        }
      } catch (error) {
        console.error('Erreur:', error);
        toast.error('Erreur lors de la suppression de l\'URL');
      }
    }
  };

  const handleToggleUrlStatus = async (urlId: string) => {
    const url = customUrls.find(u => u.id === urlId);
    if (!url) return;

    try {
      const success = await quoteRequestServiceReal.updateCustomUrlStatus(urlId, !url.isActive);
      
      if (success) {
        setCustomUrls(prev => 
          prev.map(u => 
            u.id === urlId 
              ? { ...u, isActive: !u.isActive, updatedAt: new Date() }
              : u
          )
        );
        toast.success('Statut de l\'URL modifié');
      } else {
        toast.error('Erreur lors de la modification du statut');
      }
    } catch (error) {
      console.error('Erreur:', error);
      toast.error('Erreur lors de la modification du statut');
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success('URL copiée dans le presse-papiers');
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, url: TechnicianCustomUrl) => {
    setAnchorEl(event.currentTarget);
    setSelectedUrlForMenu(url);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedUrlForMenu(null);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'warning';
      case 'in_review': return 'info';
      case 'quoted': return 'primary';
      case 'accepted': return 'success';
      case 'rejected': return 'error';
      case 'cancelled': return 'default';
      default: return 'default';
    }
  };

  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case 'low': return 'success';
      case 'medium': return 'warning';
      case 'high': return 'error';
      default: return 'default';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'pending': return 'En attente';
      case 'in_review': return 'En cours d\'examen';
      case 'quoted': return 'Devis envoyé';
      case 'accepted': return 'Accepté';
      case 'rejected': return 'Rejeté';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  };

  const getUrgencyLabel = (urgency: string) => {
    switch (urgency) {
      case 'low': return 'Faible';
      case 'medium': return 'Moyenne';
      case 'high': return 'Élevée';
      default: return urgency;
    }
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Message de développement en cours */}
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '60vh',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          borderRadius: 3,
          p: 6,
          mb: 4,
        }}
      >
        <Box
          sx={{
            textAlign: 'center',
            background: 'rgba(255,255,255,0.95)',
            borderRadius: 3,
            p: 6,
            maxWidth: 600,
            boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
            backdropFilter: 'blur(10px)',
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 80,
              height: 80,
              borderRadius: '50%',
              background: 'linear-gradient(135deg, #ff9800 0%, #f57c00 100%)',
              color: 'white',
              mx: 'auto',
              mb: 3,
            }}
          >
            <BuildIcon sx={{ fontSize: 40 }} />
          </Box>
          
          <Typography variant="h4" gutterBottom sx={{ fontWeight: 700, color: '#ff9800' }}>
            🚧 Page en cours de développement
          </Typography>
          
          <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
            La gestion des demandes de devis est temporairement indisponible
          </Typography>
          
          <Alert severity="info" sx={{ mb: 4, textAlign: 'left' }}>
            <Typography variant="body1" sx={{ fontWeight: 500, mb: 1 }}>
              Nous travaillons actuellement sur l'amélioration de cette fonctionnalité.
            </Typography>
            <Typography variant="body2">
              Cette page sera bientôt disponible avec de nouvelles fonctionnalités pour gérer vos demandes de devis.
            </Typography>
          </Alert>

          <Box sx={{ mb: 4 }}>
            <Typography variant="body1" sx={{ fontWeight: 500, mb: 2 }}>
              En attendant, vous pouvez :
            </Typography>
            <Box sx={{ textAlign: 'left', maxWidth: 400, mx: 'auto' }}>
              <Typography variant="body2" sx={{ mb: 1 }}>
                • Gérer vos réparations via le Kanban
              </Typography>
              <Typography variant="body2" sx={{ mb: 1 }}>
                • Consulter vos statistiques
              </Typography>
              <Typography variant="body2" sx={{ mb: 1 }}>
                • Gérer votre catalogue de produits
              </Typography>
            </Box>
          </Box>

          <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
            Merci de votre compréhension
          </Typography>
        </Box>
      </Box>

    </Box>
  );
};

export default QuoteRequestsManagement;

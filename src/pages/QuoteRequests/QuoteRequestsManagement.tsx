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
import { useAuth } from '../../contexts/AuthContext';
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
  const { user: currentUser } = useAuth();
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

  if (!currentUser) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}>
        <Alert severity="warning">Veuillez vous connecter pour accéder aux demandes de devis.</Alert>
      </Box>
    );
  }

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Demandes de devis
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Gérez les demandes de devis de vos clients
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={handleRefresh}
          >
            Actualiser
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setIsUrlDialogOpen(true)}
          >
            Nouvelle URL
          </Button>
        </Box>
      </Box>

      {/* Statistiques */}
      {stats && (
        <Grid container spacing={2} sx={{ mb: 3 }}>
          <Grid item xs={6} sm={4} md={2}>
            <Card>
              <CardContent sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 700 }}>{stats.total}</Typography>
                <Typography variant="body2" color="text.secondary">Total</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={6} sm={4} md={2}>
            <Card>
              <CardContent sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, color: 'warning.main' }}>{stats.pending}</Typography>
                <Typography variant="body2" color="text.secondary">En attente</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={6} sm={4} md={2}>
            <Card>
              <CardContent sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, color: 'info.main' }}>{stats.inReview}</Typography>
                <Typography variant="body2" color="text.secondary">En examen</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={6} sm={4} md={2}>
            <Card>
              <CardContent sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, color: 'primary.main' }}>{stats.quoted}</Typography>
                <Typography variant="body2" color="text.secondary">Devis envoyé</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={6} sm={4} md={2}>
            <Card>
              <CardContent sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, color: 'success.main' }}>{stats.accepted}</Typography>
                <Typography variant="body2" color="text.secondary">Acceptés</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={6} sm={4} md={2}>
            <Card>
              <CardContent sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, color: 'error.main' }}>{stats.rejected}</Typography>
                <Typography variant="body2" color="text.secondary">Rejetés</Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Onglets */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={tabValue} onChange={handleTabChange}>
          <Tab label="Demandes" />
          <Tab label="URLs personnalisées" />
        </Tabs>
      </Paper>

      {/* Onglet Demandes */}
      <TabPanel value={tabValue} index={0}>
        {quoteRequests.length === 0 ? (
          <Alert severity="info">Aucune demande de devis pour le moment.</Alert>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>N°</TableCell>
                  <TableCell>Client</TableCell>
                  <TableCell>Appareil</TableCell>
                  <TableCell>Urgence</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Date</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {quoteRequests.map((request) => (
                  <TableRow key={request.id} hover>
                    <TableCell>{request.requestNumber}</TableCell>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 500 }}>
                          {request.clientFirstName} {request.clientLastName}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {request.clientEmail}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {request.deviceType} {request.deviceBrand && `- ${request.deviceBrand}`}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getUrgencyLabel(request.urgency)}
                        color={getUrgencyColor(request.urgency) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getStatusLabel(request.status)}
                        color={getStatusColor(request.status) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {new Date(request.createdAt).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell align="right">
                      <Tooltip title="Voir">
                        <IconButton size="small" onClick={() => handleViewRequest(request)}>
                          <VisibilityIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Répondre">
                        <IconButton size="small" onClick={() => handleReply(request)}>
                          <EmailIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </TabPanel>

      {/* Onglet URLs personnalisées */}
      <TabPanel value={tabValue} index={1}>
        {customUrls.length === 0 ? (
          <Alert severity="info">
            Aucune URL personnalisée. Créez-en une pour recevoir des demandes de devis.
          </Alert>
        ) : (
          <List>
            {customUrls.map((url) => (
              <ListItem key={url.id} sx={{ mb: 1, bgcolor: 'background.paper', borderRadius: 1 }}>
                <ListItemIcon>
                  <LinkIcon />
                </ListItemIcon>
                <ListItemText
                  primary={
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Typography variant="body1" sx={{ fontWeight: 500 }}>
                        {url.customUrl}
                      </Typography>
                      <Chip
                        label={url.isActive ? 'Active' : 'Inactive'}
                        color={url.isActive ? 'success' : 'default'}
                        size="small"
                      />
                    </Box>
                  }
                  secondary={`Créée le ${new Date(url.createdAt).toLocaleDateString('fr-FR')}`}
                />
                <ListItemSecondaryAction>
                  <Tooltip title="Copier l'URL">
                    <IconButton size="small" onClick={() => copyToClipboard(`${window.location.origin}/quote/${url.customUrl}`)}>
                      <ContentCopyIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title={url.isActive ? 'Désactiver' : 'Activer'}>
                    <IconButton size="small" onClick={() => handleToggleUrlStatus(url.id)}>
                      <PowerSettingsNewIcon fontSize="small" color={url.isActive ? 'success' : 'disabled'} />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Modifier">
                    <IconButton size="small" onClick={() => handleEditUrl(url)}>
                      <EditIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Supprimer">
                    <IconButton size="small" onClick={() => handleDeleteUrl(url.id)}>
                      <DeleteIcon fontSize="small" color="error" />
                    </IconButton>
                  </Tooltip>
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}
      </TabPanel>

      {/* Dialog détail demande */}
      <Dialog open={isDialogOpen} onClose={() => setIsDialogOpen(false)} maxWidth="md" fullWidth>
        {selectedRequest && (
          <>
            <DialogTitle>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h6">Demande {selectedRequest.requestNumber}</Typography>
                <Chip
                  label={getStatusLabel(selectedRequest.status)}
                  color={getStatusColor(selectedRequest.status) as any}
                />
              </Box>
            </DialogTitle>
            <DialogContent dividers>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>Client</Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <PersonIcon fontSize="small" color="action" />
                    <Typography>{selectedRequest.clientFirstName} {selectedRequest.clientLastName}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <EmailIcon fontSize="small" color="action" />
                    <Typography variant="body2">{selectedRequest.clientEmail}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <PhoneIcon fontSize="small" color="action" />
                    <Typography variant="body2">{selectedRequest.clientPhone}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>Appareil</Typography>
                  <Typography variant="body2">Type : {selectedRequest.deviceType || 'Non spécifié'}</Typography>
                  <Typography variant="body2">Marque : {selectedRequest.deviceBrand || 'Non spécifié'}</Typography>
                  <Typography variant="body2">Modèle : {selectedRequest.deviceModel || 'Non spécifié'}</Typography>
                </Grid>
                <Grid item xs={12}>
                  <Divider sx={{ my: 1 }} />
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>Description du problème</Typography>
                  <Typography variant="body2">{selectedRequest.issueDescription}</Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>Urgence</Typography>
                  <Chip
                    label={getUrgencyLabel(selectedRequest.urgency)}
                    color={getUrgencyColor(selectedRequest.urgency) as any}
                    size="small"
                  />
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>Changer le statut</Typography>
                  <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                    {['pending', 'in_review', 'quoted', 'accepted', 'rejected'].map((status) => (
                      <Button
                        key={status}
                        size="small"
                        variant={selectedRequest.status === status ? 'contained' : 'outlined'}
                        onClick={() => handleUpdateStatus(selectedRequest.id, status)}
                      >
                        {getStatusLabel(status)}
                      </Button>
                    ))}
                  </Box>
                </Grid>
              </Grid>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => handleReply(selectedRequest)} startIcon={<EmailIcon />}>
                Répondre par email
              </Button>
              <Button onClick={() => setIsDialogOpen(false)}>Fermer</Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Dialog ajout URL */}
      <Dialog open={isUrlDialogOpen} onClose={() => setIsUrlDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nouvelle URL personnalisée</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Créez une URL personnalisée que vos clients pourront utiliser pour vous envoyer des demandes de devis.
          </Typography>
          <TextField
            fullWidth
            label="URL personnalisée"
            value={newCustomUrl}
            onChange={(e) => setNewCustomUrl(e.target.value)}
            placeholder="mon-atelier"
            helperText={`L'URL sera : ${window.location.origin}/quote/${newCustomUrl || 'mon-atelier'}`}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setIsUrlDialogOpen(false)}>Annuler</Button>
          <Button variant="contained" onClick={handleAddCustomUrl}>Créer</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog modification URL */}
      <Dialog open={isEditUrlDialogOpen} onClose={() => setIsEditUrlDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Modifier l'URL personnalisée</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="URL personnalisée"
            value={editCustomUrl}
            onChange={(e) => setEditCustomUrl(e.target.value)}
            placeholder="mon-atelier"
            sx={{ mt: 1 }}
            helperText={`L'URL sera : ${window.location.origin}/quote/${editCustomUrl || 'mon-atelier'}`}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setIsEditUrlDialogOpen(false)}>Annuler</Button>
          <Button variant="contained" onClick={handleUpdateCustomUrl}>Enregistrer</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default QuoteRequestsManagement;

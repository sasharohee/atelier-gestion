import React, { useState, useMemo } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
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
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Divider,
  Alert,
  Autocomplete,
  InputAdornment,
  Tooltip,
  Badge,
  Chip,
  Fab,
} from '@mui/material';
import {
  Add as AddIcon,
  Description as DescriptionIcon,
  Print as PrintIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Info as InfoIcon,
  Inventory as InventoryIcon,
  Send as SendIcon,
  TrendingUp as TrendingUpIcon,
  MonetizationOn as MonetizationOnIcon,
  CalendarToday as CalendarTodayIcon,
  Assessment as AssessmentIcon,
  BarChart as BarChartIcon,
  PieChart as PieChartIcon,
  History as HistoryIcon,
  ShoppingCart as ShoppingCartIcon,
  Build as BuildIcon,
  Euro as EuroIcon,
  AttachMoney as AttachMoneyIcon,
  Edit as EditIcon,
  Visibility as VisibilityIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { format, addDays } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Quote, QuoteItem } from '../../types';
import { generateQuoteNumber, formatQuoteNumber } from '../../utils/quoteUtils';
import QuoteForm from './QuoteForm';
import QuoteView from './QuoteView';
import RepairForm, { RepairFormData } from './RepairForm';

interface QuoteItemForm {
  type: 'product' | 'service' | 'part' | 'repair';
  itemId: string;
  name: string;
  description?: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

const Quotes: React.FC = () => {
  const {
    clients,
    products,
    services,
    parts,
    devices,
    quotes,
    addQuote,
    updateQuote,
    deleteQuote,
    getClientById,
    getDeviceById,
  } = useAppStore();
  
  const [newQuoteDialogOpen, setNewQuoteDialogOpen] = useState(false);
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  const [quoteItems, setQuoteItems] = useState<QuoteItemForm[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedItemType, setSelectedItemType] = useState<'product' | 'service' | 'part' | 'repair'>('product');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedQuoteForView, setSelectedQuoteForView] = useState<Quote | null>(null);
  const [quoteViewOpen, setQuoteViewOpen] = useState(false);
  const [repairFormOpen, setRepairFormOpen] = useState(false);
  const [validUntil, setValidUntil] = useState<Date>(addDays(new Date(), 30));
  const [notes, setNotes] = useState('');
  const [terms, setTerms] = useState('');

  // Calcul des totaux
  const totals = useMemo(() => {
    const subtotal = quoteItems.reduce((sum, item) => sum + item.totalPrice, 0);
    const tax = subtotal * 0.20; // TVA 20%
    const total = subtotal + tax;
    
    return { subtotal, tax, total };
  }, [quoteItems]);

  // Filtrage des articles selon le type et la recherche
  const filteredItems = useMemo(() => {
    let items: Array<{ id: string; name: string; price: number; type: string; category?: string; description?: string }> = [];
    
    switch (selectedItemType) {
      case 'product':
        items = products
          .filter(product => product.isActive && product.id)
          .map(product => ({
            id: product.id,
            name: product.name,
            price: product.price,
            type: 'product',
            category: product.category,
            description: product.description
          }));
        break;
      case 'service':
        items = services
          .filter(service => service.isActive && service.id)
          .map(service => ({
            id: service.id,
            name: service.name,
            price: service.price,
            type: 'service',
            category: service.category,
            description: service.description
          }));
        break;
      case 'part':
        items = parts
          .filter(part => part.isActive && part.stockQuantity > 0 && part.id)
          .map(part => ({
            id: part.id,
            name: part.name,
            price: part.price,
            type: 'part',
            category: part.brand,
            description: part.description
          }));
        break;
      case 'repair':
        // Pour les réparations, on affiche un bouton pour créer une nouvelle réparation
        items = [];
        break;
    }
    
    // Filtrage par catégorie
    if (selectedCategory !== 'all') {
      items = items.filter(item => item.category === selectedCategory);
    }
    
    // Filtrage par recherche
    if (searchQuery) {
      items = items.filter(item => 
        item.name.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }
    
    return items;
  }, [selectedItemType, selectedCategory, searchQuery, products, services, parts]);

  // Obtenir les catégories disponibles selon le type sélectionné
  const availableCategories = useMemo(() => {
    let categories: string[] = [];
    
    switch (selectedItemType) {
      case 'product':
        categories = Array.from(new Set(products.filter(p => p.isActive).map(p => p.category)));
        break;
      case 'service':
        categories = Array.from(new Set(services.filter(s => s.isActive).map(s => s.category)));
        break;
      case 'part':
        categories = Array.from(new Set(parts.filter(p => p.isActive && p.stockQuantity > 0).map(p => p.brand)));
        break;
      case 'repair':
        categories = [];
        break;
    }
    
    return ['all', ...categories];
  }, [selectedItemType, products, services, parts]);

  // Fonction pour obtenir des informations détaillées sur un article
  const getItemDetails = (itemId: string, type: string) => {
    switch (type) {
      case 'product':
        return products.find(p => p.id === itemId);
      case 'service':
        return services.find(s => s.id === itemId);
      case 'part':
        return parts.find(p => p.id === itemId);
      case 'repair':
        return null; // Les réparations sont créées dynamiquement
      default:
        return null;
    }
  };

  // Fonction pour obtenir le libellé du statut
  const getStatusLabel = (status: string) => {
    const labels = {
      draft: 'Brouillon',
      sent: 'Envoyé',
      accepted: 'Accepté',
      rejected: 'Refusé',
      expired: 'Expiré',
    };
    return labels[status as keyof typeof labels] || status;
  };

  // Fonction pour obtenir la couleur du statut
  const getStatusColor = (status: string) => {
    const colors = {
      draft: 'default',
      sent: 'primary',
      accepted: 'success',
      rejected: 'error',
      expired: 'warning',
    };
    return colors[status as keyof typeof colors] || 'default';
  };

  // Ajouter un article au devis
  const addItemToQuote = (item: { id: string; name: string; price: number; type: string; description?: string }) => {
    const existingItem = quoteItems.find(quoteItem => quoteItem.itemId === item.id);
    
    if (existingItem) {
      // Augmenter la quantité si l'article existe déjà
      setQuoteItems(prev => prev.map(quoteItem => 
        quoteItem.itemId === item.id 
          ? { ...quoteItem, quantity: quoteItem.quantity + 1, totalPrice: (quoteItem.quantity + 1) * quoteItem.unitPrice }
          : quoteItem
      ));
    } else {
      // Ajouter un nouvel article
      const newItem: QuoteItemForm = {
        type: item.type as 'product' | 'service' | 'part',
        itemId: item.id,
        name: item.name,
        description: item.description,
        quantity: 1,
        unitPrice: item.price,
        totalPrice: item.price,
      };
      setQuoteItems(prev => [...prev, newItem]);
    }
  };

  // Supprimer un article du devis
  const removeItemFromQuote = (itemId: string) => {
    setQuoteItems(prev => prev.filter(item => item.itemId !== itemId));
  };

  // Modifier la quantité d'un article
  const updateItemQuantity = (itemId: string, quantity: number) => {
    if (quantity <= 0) {
      removeItemFromQuote(itemId);
      return;
    }
    
    setQuoteItems(prev => prev.map(item => 
      item.itemId === itemId 
        ? { ...item, quantity, totalPrice: quantity * item.unitPrice }
        : item
    ));
  };

  // Créer un nouveau devis
  const createQuote = async () => {
    if (quoteItems.length === 0) {
      alert('Veuillez ajouter au moins un article au devis.');
      return;
    }

    const quoteItemsFormatted: QuoteItem[] = quoteItems.map(item => ({
      id: item.itemId,
      type: item.type,
      itemId: item.itemId,
      name: item.name,
      description: item.description,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    }));

    const newQuote: Quote = {
      id: `quote_${Date.now()}`, // Généré par le backend
      quoteNumber: generateQuoteNumber(), // Numéro de devis unique
      clientId: selectedClientId || undefined,
      items: quoteItemsFormatted,
      subtotal: totals.subtotal,
      tax: totals.tax,
      total: totals.total,
      status: 'draft',
      validUntil,
      notes,
      terms,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // Ajouter le devis via le store
    await addQuote(newQuote);
    
    // Réinitialiser le formulaire
    setSelectedClientId('');
    setQuoteItems([]);
    setValidUntil(addDays(new Date(), 30));
    setNotes('');
    setTerms('');
    setNewQuoteDialogOpen(false);
  };

  // Supprimer un devis
  const handleDeleteQuote = async (quoteId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce devis ?')) {
      await deleteQuote(quoteId);
    }
  };

  // Changer le statut d'un devis
  const updateQuoteStatus = async (quoteId: string, newStatus: Quote['status']) => {
    await updateQuote(quoteId, { status: newStatus });
  };

  // Ouvrir la vue d'un devis
  const openQuoteView = (quote: Quote) => {
    setSelectedQuoteForView(quote);
    setQuoteViewOpen(true);
  };

  // Gérer la création d'une réparation
  const handleCreateRepair = (repairData: RepairFormData) => {
    const device = repairData.deviceId ? getDeviceById(repairData.deviceId) : null;
    const client = getClientById(repairData.clientId);
    
    const repairItem: QuoteItemForm = {
      type: 'repair',
      itemId: `repair_${Date.now()}`, // ID temporaire
      name: `Réparation ${device ? `${device.brand} ${device.model}` : 'Appareil'}`,
      description: repairData.description,
      quantity: 1,
      unitPrice: repairData.estimatedPrice,
      totalPrice: repairData.estimatedPrice,
    };

    setQuoteItems(prev => [...prev, repairItem]);
    
    // Mettre à jour le client sélectionné si pas encore défini
    if (!selectedClientId) {
      setSelectedClientId(repairData.clientId);
    }
  };

  // Filtrer les devis selon la recherche
  const filteredQuotes = quotes.filter(quote => {
    if (!searchQuery) return true;
    
    const client = getClientById(quote.clientId || '');
    const clientName = client ? `${client.firstName} ${client.lastName}` : 'Client anonyme';
    
    return (
      clientName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      quote.quoteNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      quote.status.toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box>
            <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
              Devis
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Gestion des devis et estimations
            </Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setNewQuoteDialogOpen(true)}
            sx={{ 
              backgroundColor: '#1976d2',
              '&:hover': { backgroundColor: '#1565c0' }
            }}
          >
            Nouveau devis
          </Button>
        </Box>

        {/* Statistiques rapides */}
        <Grid container spacing={2} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <DescriptionIcon sx={{ color: '#1976d2', mr: 1 }} />
                  <Box>
                    <Typography variant="h6">{quotes.length}</Typography>
                    <Typography variant="body2" color="text.secondary">Total devis</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <SendIcon sx={{ color: '#ff9800', mr: 1 }} />
                  <Box>
                    <Typography variant="h6">
                      {quotes.filter(q => q.status === 'sent').length}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">Envoyés</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <CheckCircleIcon sx={{ color: '#4caf50', mr: 1 }} />
                  <Box>
                    <Typography variant="h6">
                      {quotes.filter(q => q.status === 'accepted').length}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">Acceptés</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <MonetizationOnIcon sx={{ color: '#f44336', mr: 1 }} />
                  <Box>
                    <Typography variant="h6">
                      {quotes.filter(q => q.status === 'accepted').reduce((sum, q) => sum + q.total, 0).toLocaleString('fr-FR')} €
                    </Typography>
                    <Typography variant="body2" color="text.secondary">CA potentiel</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Box>

      {/* Barre de recherche */}
      <Box sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Rechercher un devis par client, numéro ou statut..."
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
      </Box>

      {/* Tableau des devis */}
      <TableContainer component={Paper} variant="outlined">
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <DescriptionIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                  N° Devis
                </Box>
              </TableCell>
              <TableCell>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <InfoIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                  Client
                </Box>
              </TableCell>
              <TableCell>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <CalendarTodayIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                  Date
                </Box>
              </TableCell>
              <TableCell>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <MonetizationOnIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                  Montant
                </Box>
              </TableCell>
              <TableCell>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <ScheduleIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                  Validité
                </Box>
              </TableCell>
              <TableCell>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <AssessmentIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                  Statut
                </Box>
              </TableCell>
              <TableCell align="center">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredQuotes.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <Box sx={{ textAlign: 'center' }}>
                    <DescriptionIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                    <Typography variant="h6" color="text.secondary" gutterBottom>
                      Aucun devis trouvé
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      {searchQuery ? 'Aucun devis ne correspond à votre recherche.' : 'Commencez par créer votre premier devis.'}
                    </Typography>
                    {!searchQuery && (
                      <Button
                        variant="contained"
                        startIcon={<AddIcon />}
                        onClick={() => setNewQuoteDialogOpen(true)}
                      >
                        Créer un devis
                      </Button>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ) : (
              filteredQuotes.map((quote) => {
                const client = getClientById(quote.clientId || '');
                const isExpired = new Date(quote.validUntil) < new Date();
                
                return (
                  <TableRow key={quote.id} hover>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {formatQuoteNumber(quote.quoteNumber)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {client ? `${client.firstName} ${client.lastName}` : 'Client anonyme'}
                      </Typography>
                      {client && (
                        <Typography variant="caption" color="text.secondary">
                          {client.email}
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {format(new Date(quote.createdAt), 'dd/MM/yyyy', { locale: fr })}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {quote.total.toLocaleString('fr-FR')} €
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {quote.items.length} article(s)
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Typography variant="body2">
                          {format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}
                        </Typography>
                        {isExpired && (
                          <WarningIcon sx={{ ml: 1, fontSize: '16px', color: 'warning.main' }} />
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getStatusLabel(quote.status)}
                        color={getStatusColor(quote.status) as any}
                        size="small"
                        variant={quote.status === 'draft' ? 'outlined' : 'filled'}
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
                        <Tooltip title="Voir le devis">
                          <IconButton
                            size="small"
                            onClick={() => openQuoteView(quote)}
                            sx={{ color: '#1976d2' }}
                          >
                            <VisibilityIcon />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Modifier">
                          <IconButton
                            size="small"
                            sx={{ color: '#ff9800' }}
                          >
                            <EditIcon />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Supprimer">
                          <IconButton
                            size="small"
                            onClick={() => handleDeleteQuote(quote.id)}
                            sx={{ color: '#f44336' }}
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Dialog de création de devis */}
      <QuoteForm
        open={newQuoteDialogOpen}
        onClose={() => setNewQuoteDialogOpen(false)}
        onSubmit={createQuote}
        clients={clients}
        products={products}
        services={services}
        parts={parts}
        devices={devices}
        selectedClientId={selectedClientId}
        setSelectedClientId={setSelectedClientId}
        quoteItems={quoteItems}
        setQuoteItems={setQuoteItems}
        totals={totals}
        validUntil={validUntil}
        setValidUntil={setValidUntil}
        notes={notes}
        setNotes={setNotes}
        terms={terms}
        setTerms={setTerms}
        filteredItems={filteredItems}
        selectedItemType={selectedItemType}
        setSelectedItemType={setSelectedItemType}
        selectedCategory={selectedCategory}
        setSelectedCategory={setSelectedCategory}
        searchQuery={searchQuery}
        setSearchQuery={setSearchQuery}
        availableCategories={availableCategories}
        addItemToQuote={addItemToQuote}
        removeItemFromQuote={removeItemFromQuote}
        updateItemQuantity={updateItemQuantity}
      />

      {/* Dialog de vue du devis */}
      <QuoteView
        open={quoteViewOpen}
        onClose={() => setQuoteViewOpen(false)}
        quote={selectedQuoteForView}
        client={selectedQuoteForView && selectedQuoteForView.clientId ? getClientById(selectedQuoteForView.clientId) || null : null}
        onStatusChange={updateQuoteStatus}
      />
    </Box>
  );
};

export default Quotes;

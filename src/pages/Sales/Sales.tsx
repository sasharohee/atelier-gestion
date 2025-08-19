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
  Chip,
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
} from '@mui/material';
import {
  Add as AddIcon,
  Receipt as ReceiptIcon,
  Print as PrintIcon,
  Email as EmailIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Sale, SaleItem } from '../../types';
import Invoice from '../../components/Invoice';

interface SaleItemForm {
  type: 'product' | 'service' | 'part';
  itemId: string;
  name: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

const Sales: React.FC = () => {
  const {
    sales,
    clients,
    products,
    services,
    parts,
    getClientById,
    addSale,
    deleteSale,
  } = useAppStore();

  const [newSaleDialogOpen, setNewSaleDialogOpen] = useState(false);
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'transfer'>('card');
  const [saleItems, setSaleItems] = useState<SaleItemForm[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedItemType, setSelectedItemType] = useState<'product' | 'service' | 'part'>('product');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedSaleForInvoice, setSelectedSaleForInvoice] = useState<Sale | null>(null);
  const [invoiceOpen, setInvoiceOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [saleToDelete, setSaleToDelete] = useState<Sale | null>(null);

  // Calcul des totaux
  const totals = useMemo(() => {
    const subtotal = saleItems.reduce((sum, item) => sum + item.totalPrice, 0);
    const tax = subtotal * 0.20; // TVA 20%
    const total = subtotal + tax;
    
    return { subtotal, tax, total };
  }, [saleItems]);

  // Filtrage des articles selon le type et la recherche
  const filteredItems = useMemo(() => {
    let items: Array<{ id: string; name: string; price: number; type: string; category?: string }> = [];
    
    switch (selectedItemType) {
      case 'product':
        items = products
          .filter(product => product.isActive)
          .map(product => ({
            id: product.id,
            name: product.name,
            price: product.price,
            type: 'product',
            category: product.category
          }));
        break;
      case 'service':
        items = services
          .filter(service => service.isActive)
          .map(service => ({
            id: service.id,
            name: service.name,
            price: service.price,
            type: 'service',
            category: service.category
          }));
        break;
      case 'part':
        items = parts
          .filter(part => part.isActive && part.stockQuantity > 0)
          .map(part => ({
            id: part.id,
            name: part.name,
            price: part.price,
            type: 'part',
            category: part.brand
          }));
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
        categories = [...new Set(products.filter(p => p.isActive).map(p => p.category))];
        break;
      case 'service':
        categories = [...new Set(services.filter(s => s.isActive).map(s => s.category))];
        break;
      case 'part':
        categories = [...new Set(parts.filter(p => p.isActive && p.stockQuantity > 0).map(p => p.brand))];
        break;
    }
    
    return ['all', ...categories];
  }, [selectedItemType, products, services, parts]);

  const getStatusColor = (status: string) => {
    const colors = {
      pending: 'warning',
      completed: 'success',
      cancelled: 'error',
    };
    return colors[status as keyof typeof colors] || 'default';
  };

  const getStatusLabel = (status: string) => {
    const labels = {
      pending: 'En attente',
      completed: 'Terminée',
      cancelled: 'Annulée',
    };
    return labels[status as keyof typeof labels] || status;
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels = {
      cash: 'Espèces',
      card: 'Carte',
      transfer: 'Virement',
    };
    return labels[method as keyof typeof labels] || method;
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

  // Ajouter un article à la vente
  const addItemToSale = (item: { id: string; name: string; price: number; type: string }) => {
    const existingItem = saleItems.find(saleItem => saleItem.itemId === item.id);
    
    if (existingItem) {
      // Augmenter la quantité si l'article existe déjà
      setSaleItems(prev => prev.map(saleItem => 
        saleItem.itemId === item.id 
          ? { ...saleItem, quantity: saleItem.quantity + 1, totalPrice: (saleItem.quantity + 1) * saleItem.unitPrice }
          : saleItem
      ));
    } else {
      // Ajouter un nouvel article
      const newItem: SaleItemForm = {
        type: item.type as 'product' | 'service' | 'part',
        itemId: item.id,
        name: item.name,
        quantity: 1,
        unitPrice: item.price,
        totalPrice: item.price,
      };
      setSaleItems(prev => [...prev, newItem]);
    }
  };

  // Supprimer un article de la vente
  const removeItemFromSale = (itemId: string) => {
    setSaleItems(prev => prev.filter(item => item.itemId !== itemId));
  };

  // Modifier la quantité d'un article
  const updateItemQuantity = (itemId: string, quantity: number) => {
    if (quantity <= 0) {
      removeItemFromSale(itemId);
      return;
    }
    
    setSaleItems(prev => prev.map(item => 
      item.itemId === itemId 
        ? { ...item, quantity, totalPrice: quantity * item.unitPrice }
        : item
    ));
  };

  // Créer une nouvelle vente
  const createSale = async () => {
    if (saleItems.length === 0) {
      alert('Veuillez ajouter au moins un article à la vente.');
      return;
    }

    const saleItemsFormatted: SaleItem[] = saleItems.map(item => ({
      id: item.itemId,
      type: item.type,
      itemId: item.itemId,
      name: item.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    }));

    const newSale: Sale = {
      id: '', // Sera généré par le backend
      clientId: selectedClientId || undefined,
      items: saleItemsFormatted,
      subtotal: totals.subtotal,
      tax: totals.tax,
      total: totals.total,
      paymentMethod,
      status: 'completed',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    try {
      await addSale(newSale);
      setNewSaleDialogOpen(false);
      resetForm();
      
      // Ouvrir automatiquement la facture de la vente créée
      const createdSale = { ...newSale, id: newSale.id || 'temp-id' };
      openInvoice(createdSale);
    } catch (error) {
      console.error('Erreur lors de la création de la vente:', error);
      alert('Erreur lors de la création de la vente.');
    }
  };

  // Réinitialiser le formulaire
  const resetForm = () => {
    setSelectedClientId('');
    setPaymentMethod('card');
    setSaleItems([]);
    setSearchQuery('');
    setSelectedItemType('product');
    setSelectedCategory('all');
  };

  // Ouvrir la facture
  const openInvoice = (sale: Sale) => {
    setSelectedSaleForInvoice(sale);
    setInvoiceOpen(true);
  };

  // Fermer la facture
  const closeInvoice = () => {
    setInvoiceOpen(false);
    setSelectedSaleForInvoice(null);
  };

  // Gestion de la suppression
  const handleDeleteSale = (sale: Sale) => {
    setSaleToDelete(sale);
    setDeleteDialogOpen(true);
  };

  const confirmDeleteSale = async () => {
    if (saleToDelete) {
      try {
        await deleteSale(saleToDelete.id);
        setDeleteDialogOpen(false);
        setSaleToDelete(null);
        alert('✅ Vente supprimée avec succès !');
      } catch (error) {
        console.error('Erreur lors de la suppression de la vente:', error);
        alert('❌ Erreur lors de la suppression de la vente');
      }
    }
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Ventes
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des ventes et facturation
        </Typography>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewSaleDialogOpen(true)}
        >
          Nouvelle vente
        </Button>
      </Box>

      {/* Statistiques rapides */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Ventes du jour
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales.filter(sale => {
                  try {
                    if (!sale.createdAt) return false;
                    const saleDate = new Date(sale.createdAt);
                    if (isNaN(saleDate.getTime())) return false;
                    return format(saleDate, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd');
                  } catch (error) {
                    console.error('Erreur de date dans la vente:', error);
                    return false;
                  }
                }).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                CA du jour
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales
                  .filter(sale => {
                    try {
                      if (!sale.createdAt) return false;
                      const saleDate = new Date(sale.createdAt);
                      if (isNaN(saleDate.getTime())) return false;
                      return format(saleDate, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd');
                    } catch (error) {
                      console.error('Erreur de date dans la vente:', error);
                      return false;
                    }
                  })
                  .reduce((sum, sale) => sum + sale.total, 0)
                  .toLocaleString('fr-FR')} €
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Ventes du mois
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales.filter(sale => {
                  try {
                    if (!sale.createdAt) return false;
                    const saleDate = new Date(sale.createdAt);
                    if (isNaN(saleDate.getTime())) return false;
                    return format(saleDate, 'yyyy-MM') === format(new Date(), 'yyyy-MM');
                  } catch (error) {
                    console.error('Erreur de date dans la vente:', error);
                    return false;
                  }
                }).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                CA du mois
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales
                  .filter(sale => {
                    try {
                      if (!sale.createdAt) return false;
                      const saleDate = new Date(sale.createdAt);
                      if (isNaN(saleDate.getTime())) return false;
                      return format(saleDate, 'yyyy-MM') === format(new Date(), 'yyyy-MM');
                    } catch (error) {
                      console.error('Erreur de date dans la vente:', error);
                      return false;
                    }
                  })
                  .reduce((sum, sale) => sum + sale.total, 0)
                  .toLocaleString('fr-FR')} €
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Liste des ventes */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Historique des ventes
          </Typography>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>N° Vente</TableCell>
                  <TableCell>Client</TableCell>
                  <TableCell>Date</TableCell>
                  <TableCell>Montant</TableCell>
                  <TableCell>Méthode</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {sales
                  .filter(sale => {
                    try {
                      if (!sale.createdAt) return false;
                      const date = new Date(sale.createdAt);
                      return !isNaN(date.getTime());
                    } catch (error) {
                      console.error('Erreur de date dans la vente:', error);
                      return false;
                    }
                  })
                  .sort((a, b) => {
                    try {
                      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
                    } catch (error) {
                      console.error('Erreur de tri des ventes:', error);
                      return 0;
                    }
                  })
                  .map((sale) => {
                    const client = sale.clientId ? getClientById(sale.clientId) : null;
                    return (
                      <TableRow key={sale.id}>
                        <TableCell>{sale.id.slice(0, 8)}</TableCell>
                        <TableCell>
                          {client ? `${client.firstName} ${client.lastName}` : 'Client anonyme'}
                        </TableCell>
                        <TableCell>
                          {safeFormatDate(sale.createdAt, 'dd/MM/yyyy HH:mm')}
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {sale.total.toLocaleString('fr-FR')} €
                          </Typography>
                        </TableCell>
                        <TableCell>
                          {getPaymentMethodLabel(sale.paymentMethod)}
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={getStatusLabel(sale.status)}
                            color={getStatusColor(sale.status) as any}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 1 }}>
                            <IconButton 
                              size="small" 
                              title="Voir facture"
                              onClick={() => openInvoice(sale)}
                            >
                              <ReceiptIcon fontSize="small" />
                            </IconButton>
                            <IconButton 
                              size="small" 
                              title="Imprimer"
                              onClick={() => openInvoice(sale)}
                            >
                              <PrintIcon fontSize="small" />
                            </IconButton>
                            <IconButton size="small" title="Envoyer par email">
                              <EmailIcon fontSize="small" />
                            </IconButton>
                            <IconButton 
                              size="small" 
                              title="Supprimer"
                              onClick={() => handleDeleteSale(sale)}
                              sx={{ color: 'error.main' }}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Box>
                        </TableCell>
                      </TableRow>
                    );
                  })}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Dialog nouvelle vente */}
      <Dialog open={newSaleDialogOpen} onClose={() => setNewSaleDialogOpen(false)} maxWidth="lg" fullWidth>
        <DialogTitle>Nouvelle vente</DialogTitle>
        <DialogContent>
          <Grid container spacing={3} sx={{ mt: 1 }}>
            {/* Informations client et paiement */}
            <Grid item xs={12} md={6}>
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Client</InputLabel>
                <Select 
                  value={selectedClientId} 
                  onChange={(e) => setSelectedClientId(e.target.value)}
                  label="Client"
                >
                  <MenuItem value="">Client anonyme</MenuItem>
                  {clients.map((client) => (
                    <MenuItem key={client.id} value={client.id}>
                      {client.firstName} {client.lastName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Méthode de paiement</InputLabel>
                <Select 
                  value={paymentMethod} 
                  onChange={(e) => setPaymentMethod(e.target.value as 'cash' | 'card' | 'transfer')}
                  label="Méthode de paiement"
                >
                  <MenuItem value="cash">Espèces</MenuItem>
                  <MenuItem value="card">Carte</MenuItem>
                  <MenuItem value="transfer">Virement</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            {/* Sélection d'articles */}
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Sélection d'articles
              </Typography>
              
              {/* Type d'article */}
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Type d'article</InputLabel>
                <Select 
                  value={selectedItemType} 
                  onChange={(e) => {
                    setSelectedItemType(e.target.value as 'product' | 'service' | 'part');
                    setSelectedCategory('all'); // Réinitialiser la catégorie
                  }}
                  label="Type d'article"
                >
                  <MenuItem value="product">🛍️ Produits & Accessoires</MenuItem>
                  <MenuItem value="service">🔧 Services de Réparation</MenuItem>
                  <MenuItem value="part">🔩 Pièces Détachées</MenuItem>
                </Select>
              </FormControl>

              {/* Catégorie */}
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Catégorie</InputLabel>
                <Select 
                  value={selectedCategory} 
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  label="Catégorie"
                >
                  {availableCategories.map((category) => (
                    <MenuItem key={category} value={category}>
                      {category === 'all' ? '📂 Toutes les catégories' : category}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {/* Recherche */}
              <TextField
                fullWidth
                placeholder="Rechercher un article..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon />
                    </InputAdornment>
                  ),
                }}
                sx={{ mb: 2 }}
              />

              {/* Liste des articles disponibles */}
              <Box sx={{ maxHeight: 300, overflow: 'auto', border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                <List dense>
                  {filteredItems.map((item) => (
                    <ListItem 
                      key={item.id} 
                      button 
                      onClick={() => addItemToSale(item)}
                      sx={{ cursor: 'pointer' }}
                    >
                      <ListItemText
                        primary={item.name}
                        secondary={
                          <Box>
                            <Typography variant="caption" display="block">
                              {item.category && `${item.category} • `}{item.price.toLocaleString('fr-FR')} €
                            </Typography>
                            {selectedItemType === 'part' && (
                              <Typography variant="caption" color="text.secondary">
                                En stock
                              </Typography>
                            )}
                          </Box>
                        }
                      />
                      <IconButton size="small" onClick={(e) => {
                        e.stopPropagation();
                        addItemToSale(item);
                      }}>
                        <AddIcon fontSize="small" />
                      </IconButton>
                    </ListItem>
                  ))}
                  {filteredItems.length === 0 && (
                    <ListItem>
                      <ListItemText 
                        primary="Aucun article trouvé" 
                        secondary="Essayez de modifier votre recherche"
                      />
                    </ListItem>
                  )}
                </List>
              </Box>
            </Grid>

            {/* Panier */}
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Panier ({saleItems.length} articles)
              </Typography>
              
              <Box sx={{ maxHeight: 300, overflow: 'auto', border: '1px solid', borderColor: 'divider', borderRadius: 1, p: 2 }}>
                {saleItems.length === 0 ? (
                  <Typography variant="body2" color="text.secondary" textAlign="center">
                    Aucun article dans le panier
                  </Typography>
                ) : (
                  <List dense>
                    {saleItems.map((item) => (
                      <ListItem key={item.itemId}>
                        <ListItemText
                          primary={item.name}
                          secondary={`${item.unitPrice.toLocaleString('fr-FR')} € x ${item.quantity}`}
                        />
                        <ListItemSecondaryAction>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <TextField
                              type="number"
                              size="small"
                              value={item.quantity}
                              onChange={(e) => updateItemQuantity(item.itemId, parseInt(e.target.value) || 0)}
                              sx={{ width: 60 }}
                              inputProps={{ min: 1 }}
                            />
                            <Typography variant="body2" sx={{ fontWeight: 600, minWidth: 60 }}>
                              {item.totalPrice.toLocaleString('fr-FR')} €
                            </Typography>
                            <IconButton 
                              size="small" 
                              onClick={() => removeItemFromSale(item.itemId)}
                              color="error"
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Box>
                        </ListItemSecondaryAction>
                      </ListItem>
                    ))}
                  </List>
                )}
              </Box>

              {/* Totaux */}
              {saleItems.length > 0 && (
                <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography>Sous-total:</Typography>
                    <Typography>{totals.subtotal.toLocaleString('fr-FR')} €</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography>TVA (20%):</Typography>
                    <Typography>{totals.tax.toLocaleString('fr-FR')} €</Typography>
                  </Box>
                  <Divider sx={{ my: 1 }} />
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>Total:</Typography>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      {totals.total.toLocaleString('fr-FR')} €
                    </Typography>
                  </Box>
                </Box>
              )}
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {
            setNewSaleDialogOpen(false);
            resetForm();
          }}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={createSale}
            disabled={saleItems.length === 0}
          >
            Créer la vente ({totals.total.toLocaleString('fr-FR')} €)
          </Button>
                  </DialogActions>
        </Dialog>

        {/* Composant Facture */}
        {selectedSaleForInvoice && (
          <Invoice
            sale={selectedSaleForInvoice}
            client={selectedSaleForInvoice.clientId ? getClientById(selectedSaleForInvoice.clientId) : undefined}
            open={invoiceOpen}
            onClose={closeInvoice}
          />
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
            {saleToDelete && (
              <Box>
                <Alert severity="warning" sx={{ mb: 2 }}>
                  <Typography variant="body1" sx={{ fontWeight: 600 }}>
                    Êtes-vous sûr de vouloir supprimer cette vente ?
                  </Typography>
                </Alert>
                
                <Box sx={{ p: 2, bgcolor: 'grey.50', borderRadius: 1, mb: 2 }}>
                  <Typography variant="subtitle1" gutterBottom>
                    <strong>Détails de la vente :</strong>
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    <strong>N° Vente :</strong> {saleToDelete.id.slice(0, 8)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    <strong>Client :</strong> {saleToDelete.clientId ? 
                      `${getClientById(saleToDelete.clientId)?.firstName} ${getClientById(saleToDelete.clientId)?.lastName}` : 
                      'Client anonyme'}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    <strong>Date :</strong> {safeFormatDate(saleToDelete.createdAt, 'dd/MM/yyyy HH:mm')}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    <strong>Montant :</strong> {saleToDelete.total.toLocaleString('fr-FR')} €
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    <strong>Méthode de paiement :</strong> {getPaymentMethodLabel(saleToDelete.paymentMethod)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    <strong>Articles :</strong> {saleToDelete.items.length} article(s)
                  </Typography>
                </Box>
                
                <Alert severity="error">
                  <Typography variant="body2">
                    <strong>Attention :</strong> Cette action est irréversible. Toutes les données de cette vente seront définitivement supprimées.
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
              onClick={confirmDeleteSale}
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

export default Sales;

import React, { useState, useMemo } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Grid,
  Paper,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Divider,
  Chip,
  Alert,
  Tooltip,
} from '@mui/material';
import {
  Delete as DeleteIcon,
  Edit as EditIcon,
  Receipt as ReceiptIcon,
  Person as PersonIcon,
  Payment as PaymentIcon,
  ShoppingCart as ShoppingCartIcon,
  Euro as EuroIcon,
  AttachMoney as AttachMoneyIcon,
  TouchApp as TouchAppIcon,
} from '@mui/icons-material';
import { useAppStore } from '../store';
import { Sale, SaleItem } from '../types';
import NumericKeypad from './NumericKeypad';
import ProductCategoryButtons from './ProductCategoryButtons';
import QuickCreateItemDialog from './QuickCreateItemDialog';
import Invoice from './Invoice';
import { useWorkshopSettings } from '../contexts/WorkshopSettingsContext';

interface SaleItemForm {
  type: 'product' | 'service' | 'part';
  itemId: string;
  name: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

interface SimplifiedSalesDialogProps {
  open: boolean;
  onClose: () => void;
}

const SimplifiedSalesDialog: React.FC<SimplifiedSalesDialogProps> = ({
  open,
  onClose,
}) => {
  const {
    clients,
    products,
    services,
    parts,
    getClientById,
    addSale,
    addProduct,
    addService,
    addPart,
  } = useAppStore();
  
  const { workshopSettings } = useWorkshopSettings();

  // États locaux
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'transfer' | 'check' | 'payment_link'>('card');
  const [saleItems, setSaleItems] = useState<SaleItemForm[]>([]);
  const [discountPercentage, setDiscountPercentage] = useState<number>(0);
  
  // États pour le clavier numérique
  const [isKeypadActive, setIsKeypadActive] = useState(false);
  const [editingItemId, setEditingItemId] = useState<string>('');
  const [keypadValue, setKeypadValue] = useState('');
  
  // États pour la facture
  const [selectedSaleForInvoice, setSelectedSaleForInvoice] = useState<Sale | null>(null);
  const [invoiceOpen, setInvoiceOpen] = useState(false);
  
  // États pour la création rapide d'articles
  const [quickCreateDialogOpen, setQuickCreateDialogOpen] = useState(false);
  const [quickCreateType, setQuickCreateType] = useState<'product' | 'service' | 'part'>('product');

  // Calcul des totaux
  const totals = useMemo(() => {
    const subtotal = saleItems.reduce((sum, item) => sum + item.totalPrice, 0);
    
    // Gestion du taux de TVA : utiliser la valeur configurée ou 20% par défaut
    let vatRate = 20; // Valeur par défaut
    if (workshopSettings.vatRate !== undefined && workshopSettings.vatRate !== null) {
      const parsedRate = parseFloat(workshopSettings.vatRate);
      if (!isNaN(parsedRate)) {
        vatRate = parsedRate;
      }
    }
    
    const tax = subtotal * (vatRate / 100);
    const totalBeforeDiscount = subtotal + tax;
    const discountAmount = (totalBeforeDiscount * discountPercentage) / 100;
    const total = totalBeforeDiscount - discountAmount;
    
    return { subtotal, tax, totalBeforeDiscount, discountAmount, total, vatRate };
  }, [saleItems, discountPercentage, workshopSettings.vatRate]);

  // Préparer les données pour ProductCategoryButtons
  const productItems = products
    .filter(p => p.isActive && p.id)
    .map(p => ({
      id: p.id,
      name: p.name,
      price: p.price,
      type: 'product' as const,
      category: p.category,
      subcategory: p.subcategory,
      description: p.description,
      stock: p.stockQuantity,
    }));

  const serviceItems = services
    .filter(s => s.isActive && s.id)
    .map(s => ({
      id: s.id,
      name: s.name,
      price: s.price,
      type: 'service' as const,
      category: s.category,
      subcategory: s.subcategory,
      description: s.description,
    }));

  const partItems = parts
    .filter(p => p.isActive && p.stockQuantity > 0 && p.id)
    .map(p => ({
      id: p.id,
      name: p.name,
      price: p.price,
      type: 'part' as const,
      category: p.brand,
      subcategory: p.subcategory,
      description: p.description,
      stock: p.stockQuantity,
    }));

  // Ajouter un article à la vente
  const addItemToSale = (item: any) => {
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
        type: item.type,
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

  // Activer le clavier pour modifier le prix d'un article
  const activateKeypadForItem = (itemId: string, currentPrice: number) => {
    setEditingItemId(itemId);
    setKeypadValue(currentPrice.toString());
    setIsKeypadActive(true);
  };

  // Valider la modification du prix
  const validatePriceChange = () => {
    if (editingItemId && keypadValue) {
      const newPrice = parseFloat(keypadValue);
      if (!isNaN(newPrice) && newPrice > 0) {
        setSaleItems(prev => prev.map(item => 
          item.itemId === editingItemId 
            ? { ...item, unitPrice: newPrice, totalPrice: item.quantity * newPrice }
            : item
        ));
      }
    }
    setIsKeypadActive(false);
    setEditingItemId('');
    setKeypadValue('');
  };

  // Annuler la modification du prix
  const cancelPriceChange = () => {
    setIsKeypadActive(false);
    setEditingItemId('');
    setKeypadValue('');
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
      discountPercentage: discountPercentage,
      discountAmount: totals.discountAmount,
      tax: totals.tax,
      total: totals.total,
      paymentMethod,
      status: 'completed',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    try {
      const createdSale = await addSale(newSale);
      onClose();
      resetForm();
      
      // Ouvrir automatiquement la facture de la vente créée avec le vrai ID
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
    setDiscountPercentage(0);
    setIsKeypadActive(false);
    setEditingItemId('');
    setKeypadValue('');
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

  // Gérer la création rapide d'un article
  const handleCreateItem = (type: 'product' | 'service' | 'part') => {
    setQuickCreateType(type);
    setQuickCreateDialogOpen(true);
  };

  // Sauvegarder un nouvel article créé rapidement
  const handleSaveQuickItem = async (itemData: any) => {
    try {
      let createdItem;
      switch (quickCreateType) {
        case 'product':
          createdItem = await addProduct(itemData);
          break;
        case 'service':
          createdItem = await addService(itemData);
          break;
        case 'part':
          createdItem = await addPart(itemData);
          break;
      }

      // Ajouter automatiquement l'article créé à la vente
      if (createdItem) {
        const newSaleItem: SaleItemForm = {
          type: quickCreateType,
          itemId: createdItem.id,
          name: createdItem.name,
          quantity: 1,
          unitPrice: createdItem.price,
          totalPrice: createdItem.price,
        };
        setSaleItems(prev => [...prev, newSaleItem]);
      }
    } catch (error) {
      console.error('Erreur lors de la création de l\'article:', error);
      throw error;
    }
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels = {
      cash: 'Espèces',
      card: 'Carte',
      transfer: 'Virement',
      check: 'Chèque',
      payment_link: 'Liens paiement',
    };
    return labels[method as keyof typeof labels] || method;
  };

  return (
    <>
      <Dialog 
        open={open} 
        onClose={onClose} 
        maxWidth="xl" 
        fullWidth
        PaperProps={{
          sx: {
            height: '90vh',
            maxHeight: '90vh',
          }
        }}
      >
        <DialogTitle sx={{ 
          bgcolor: '#4caf50', 
          color: 'white',
          display: 'flex',
          alignItems: 'center',
          gap: 1
        }}>
          <TouchAppIcon />
          Vente Simplifiée
        </DialogTitle>
        
        <DialogContent sx={{ p: 0, height: '100%' }}>
          <Grid container sx={{ height: '100%' }}>
            {/* Colonne gauche: Sélection d'articles */}
            <Grid item xs={12} md={4} sx={{ height: '100%', borderRight: '1px solid #e0e0e0' }}>
              <ProductCategoryButtons
                products={productItems}
                services={serviceItems}
                parts={partItems}
                onItemSelect={addItemToSale}
                onCreateItem={handleCreateItem}
                disabled={isKeypadActive}
              />
            </Grid>

            {/* Colonne centre: Clavier numérique */}
            <Grid item xs={12} md={4} sx={{ height: '100%', borderRight: '1px solid #e0e0e0' }}>
              <Box sx={{ p: 2, height: '100%', display: 'flex', flexDirection: 'column' }}>
                <Typography 
                  variant="h6" 
                  gutterBottom 
                  sx={{ 
                    fontWeight: 600, 
                    color: '#333',
                    textAlign: 'center',
                    mb: 1
                  }}
                >
                  ⌨️ Clavier Client
                </Typography>
                
                <Box sx={{ flexGrow: 1 }}>
                  {isKeypadActive && (
                    <Alert 
                      severity="info" 
                      sx={{ mb: 2, fontSize: '0.875rem' }}
                    >
                      Modification du prix de l'article sélectionné
                    </Alert>
                  )}
                  
                  <NumericKeypad
                    value={keypadValue}
                    onChange={setKeypadValue}
                    onValidate={validatePriceChange}
                    onCancel={cancelPriceChange}
                    disabled={false}
                  />
                  
                  {!isKeypadActive && (
                    <Box sx={{ 
                      mt: 2, 
                      p: 2, 
                      bgcolor: '#f5f5f5', 
                      borderRadius: 1,
                      textAlign: 'center'
                    }}>
                      <Typography variant="body2" color="text.secondary">
                        💡 Cliquez sur l'icône ✏️ d'un article dans le panier pour modifier son prix
                      </Typography>
                    </Box>
                  )}
                </Box>
              </Box>
            </Grid>

            {/* Colonne droite: Panier et totaux */}
            <Grid item xs={12} md={4} sx={{ height: '100%' }}>
              <Box sx={{ p: 2, height: '100%', display: 'flex', flexDirection: 'column' }}>
                <Typography 
                  variant="h6" 
                  gutterBottom 
                  sx={{ 
                    fontWeight: 600, 
                    color: '#333',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 1
                  }}
                >
                  <ShoppingCartIcon />
                  Panier ({saleItems.length})
                </Typography>

                {/* Liste des articles */}
                <Paper 
                  elevation={1} 
                  sx={{ 
                    flexGrow: 1, 
                    overflow: 'auto', 
                    mb: 2,
                    border: '1px solid #e0e0e0'
                  }}
                >
                  {saleItems.length === 0 ? (
                    <Box sx={{ textAlign: 'center', py: 4 }}>
                      <Typography variant="body1" color="text.secondary">
                        Votre panier est vide
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Sélectionnez des articles à gauche
                      </Typography>
                    </Box>
                  ) : (
                    <List dense>
                      {saleItems.map((item, index) => (
                        <ListItem 
                          key={item.itemId}
                          sx={{ 
                            borderBottom: index < saleItems.length - 1 ? '1px solid #e0e0e0' : 'none',
                            py: 1,
                            bgcolor: editingItemId === item.itemId ? '#e3f2fd' : 'transparent',
                            borderLeft: editingItemId === item.itemId ? '4px solid #1976d2' : 'none',
                            pl: editingItemId === item.itemId ? 1 : 2
                          }}
                        >
                          <ListItemText
                            primary={
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                  {item.name}
                                </Typography>
                                <Chip 
                                  label={item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'}
                                  size="small"
                                  color={item.type === 'product' ? 'primary' : item.type === 'service' ? 'secondary' : 'success'}
                                />
                              </Box>
                            }
                            secondary={
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 0.5 }}>
                                <Typography variant="caption" color="text.secondary">
                                  Quantité: {item.quantity}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  Prix unitaire: {item.unitPrice.toLocaleString('fr-FR')} €
                                </Typography>
                              </Box>
                            }
                          />
                          <ListItemSecondaryAction>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <TextField
                                type="number"
                                size="small"
                                value={item.quantity}
                                onChange={(e) => updateItemQuantity(item.itemId, parseInt(e.target.value) || 0)}
                                sx={{ width: 60 }}
                                inputProps={{ 
                                  min: 1,
                                  style: { textAlign: 'center' }
                                }}
                              />
                              <Tooltip title="Modifier le prix avec le clavier">
                                <IconButton 
                                  size="small" 
                                  onClick={() => activateKeypadForItem(item.itemId, item.unitPrice)}
                                  color="primary"
                                  sx={{
                                    bgcolor: editingItemId === item.itemId ? 'primary.main' : 'primary.light',
                                    color: editingItemId === item.itemId ? 'white' : 'primary.main',
                                    '&:hover': {
                                      bgcolor: 'primary.main',
                                      color: 'white'
                                    },
                                    border: editingItemId === item.itemId ? '2px solid #1976d2' : 'none'
                                  }}
                                >
                                  <EditIcon fontSize="small" />
                                </IconButton>
                              </Tooltip>
                              <Typography 
                                variant="body2" 
                                sx={{ 
                                  fontWeight: 600, 
                                  minWidth: 80, 
                                  textAlign: 'right',
                                  color: 'primary.main'
                                }}
                              >
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
                </Paper>

                {/* Informations client et paiement */}
                <Box sx={{ mb: 2 }}>
                  <FormControl fullWidth size="small" sx={{ mb: 1 }}>
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

                  <FormControl fullWidth size="small">
                    <InputLabel>Méthode de paiement</InputLabel>
                    <Select 
                      value={paymentMethod} 
                      onChange={(e) => setPaymentMethod(e.target.value as any)}
                      label="Méthode de paiement"
                    >
                      <MenuItem value="cash">Espèces</MenuItem>
                      <MenuItem value="card">Carte</MenuItem>
                      <MenuItem value="transfer">Virement</MenuItem>
                      <MenuItem value="check">Chèque</MenuItem>
                      <MenuItem value="payment_link">Liens paiement</MenuItem>
                    </Select>
                  </FormControl>
                </Box>

                {/* Réduction */}
                {saleItems.length > 0 && (
                  <Box sx={{ mb: 2 }}>
                    <TextField
                      fullWidth
                      type="number"
                      label="Réduction (%)"
                      value={discountPercentage}
                      onChange={(e) => setDiscountPercentage(Math.max(0, Math.min(100, parseFloat(e.target.value) || 0)))}
                      size="small"
                      inputProps={{ 
                        min: 0,
                        max: 100,
                        step: 0.1
                      }}
                    />
                    {discountPercentage > 0 && (
                      <Alert severity="info" sx={{ mt: 1, fontSize: '0.8rem' }}>
                        Réduction de {discountPercentage}% = {totals.discountAmount.toLocaleString('fr-FR')} €
                      </Alert>
                    )}
                  </Box>
                )}

                {/* Totaux */}
                {saleItems.length > 0 && (
                  <Paper 
                    elevation={2} 
                    sx={{ 
                      p: 2, 
                      bgcolor: '#f8f9fa',
                      border: '1px solid #e0e0e0'
                    }}
                  >
                    <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 600 }}>
                      📊 Récapitulatif
                    </Typography>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2">Sous-total:</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {totals.subtotal.toLocaleString('fr-FR')} €
                      </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2">TVA ({totals.vatRate}%):</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {totals.tax.toLocaleString('fr-FR')} €
                      </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2">Total TTC:</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {totals.totalBeforeDiscount.toLocaleString('fr-FR')} €
                      </Typography>
                    </Box>
                    {discountPercentage > 0 && (
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                        <Typography variant="body2" color="success.main">Réduction ({discountPercentage}%):</Typography>
                        <Typography variant="body2" sx={{ fontWeight: 500, color: 'success.main' }}>
                          -{totals.discountAmount.toLocaleString('fr-FR')} €
                        </Typography>
                      </Box>
                    )}
                    <Divider sx={{ my: 1 }} />
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Typography variant="h6" sx={{ fontWeight: 600 }}>Total:</Typography>
                      <Typography variant="h6" sx={{ fontWeight: 600, color: 'primary.main' }}>
                        {totals.total.toLocaleString('fr-FR')} €
                      </Typography>
                    </Box>
                  </Paper>
                )}
              </Box>
            </Grid>
          </Grid>
        </DialogContent>

        <DialogActions sx={{ p: 2, bgcolor: '#f5f5f5' }}>
          <Button 
            onClick={onClose}
            variant="outlined"
            color="error"
          >
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={createSale}
            disabled={saleItems.length === 0}
            startIcon={<ReceiptIcon />}
            sx={{
              bgcolor: '#4caf50',
              '&:hover': {
                bgcolor: '#45a049',
              },
            }}
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

      {/* Dialogue de création rapide d'article */}
      <QuickCreateItemDialog
        open={quickCreateDialogOpen}
        onClose={() => setQuickCreateDialogOpen(false)}
        type={quickCreateType}
        onSave={handleSaveQuickItem}
        existingSubcategories={Array.from(new Set([
          ...products.filter(p => p.subcategory).map(p => p.subcategory!),
          ...services.filter(s => s.subcategory).map(s => s.subcategory!),
          ...parts.filter(p => p.subcategory).map(p => p.subcategory!),
        ])).sort()}
      />
    </>
  );
};

export default SimplifiedSalesDialog;

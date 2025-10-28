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
} from '@mui/material';
import {
  Add as AddIcon,
  Receipt as ReceiptIcon,
  Print as PrintIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Info as InfoIcon,
  Inventory as InventoryIcon,
  Payment as PaymentIcon,
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
  TouchApp as TouchAppIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Sale, SaleItem } from '../../types';
import Invoice from '../../components/Invoice';
import SimplifiedSalesDialog from '../../components/SimplifiedSalesDialog';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import ThermalReceiptDialog from '../../components/ThermalReceiptDialog';

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
    repairs,
    clients,
    products,
    services,
    parts,
    getClientById,
    addSale,
    updateSale,
  } = useAppStore();
  
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';

  const [newSaleDialogOpen, setNewSaleDialogOpen] = useState(false);
  const [simplifiedSaleDialogOpen, setSimplifiedSaleDialogOpen] = useState(false);
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'transfer' | 'check' | 'payment_link'>('card');
  const [saleItems, setSaleItems] = useState<SaleItemForm[]>([]);
  const [thermalReceiptDialogOpen, setThermalReceiptDialogOpen] = useState(false);
  const [thermalReceiptSale, setThermalReceiptSale] = useState<Sale | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedItemType, setSelectedItemType] = useState<'product' | 'service' | 'part'>('product');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedSaleForInvoice, setSelectedSaleForInvoice] = useState<Sale | null>(null);
  const [invoiceOpen, setInvoiceOpen] = useState(false);
  const [discountPercentage, setDiscountPercentage] = useState<number>(0);

  // Fonction helper pour obtenir la source d'un item
  const getItemSource = (item: SaleItem) => {
    switch (item.type) {
      case 'product': return products.find(p => p.id === item.itemId);
      case 'service': return services.find(s => s.id === item.itemId);
      case 'part': return parts.find(p => p.id === item.itemId);
      default: return null;
    }
  };

  // Calcul des totaux (SANS TVA)
  const totals = useMemo(() => {
    // Calculer le sous-total total (tous les items)
    const subtotal = saleItems.reduce((sum, item) => sum + item.totalPrice, 0);
    
    // Total avant remise
    const totalBeforeDiscount = subtotal;
    
    // Calculer la remise
    const discountAmount = (totalBeforeDiscount * discountPercentage) / 100;
    
    // Total final
    const total = totalBeforeDiscount - discountAmount;
    
    return { 
      subtotal, 
      subtotalHT: 0, 
      subtotalTTC: subtotal,
      tax: 0, 
      totalBeforeDiscount, 
      discountAmount, 
      total 
    };
  }, [saleItems, discountPercentage]);

  // Filtrage des articles selon le type et la recherche
  const filteredItems = useMemo(() => {
    let items: Array<{ id: string; name: string; price: number; type: string; category?: string }> = [];
    
    switch (selectedItemType) {
      case 'product':
        items = products
          .filter(product => product.isActive && product.id) // Vérifier que l'ID existe
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
          .filter(service => service.isActive && service.id) // Vérifier que l'ID existe
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
          .filter(part => part.isActive && part.stockQuantity > 0 && part.id) // Vérifier que l'ID existe
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
        categories = Array.from(new Set(products.filter(p => p.isActive).map(p => p.category)));
        break;
      case 'service':
        categories = Array.from(new Set(services.filter(s => s.isActive).map(s => s.category)));
        break;
      case 'part':
        categories = Array.from(new Set(parts.filter(p => p.isActive && p.stockQuantity > 0).map(p => p.brand)));
        break;
    }
    
    return ['all', ...categories];
  }, [selectedItemType, products, services, parts]);

  // Fonction pour obtenir des informations détaillées sur un article
  const getItemDetails = (item: { id: string; name: string; price: number; type: string; category?: string }) => {
    switch (item.type) {
      case 'product':
        const product = products.find(p => p.id === item.id);
        return {
          description: product?.description || 'Aucune description',
          stock: product?.stockQuantity || 0,
          category: product?.category || 'Non catégorisé',
          type: 'Produit'
        };
      case 'service':
        const service = services.find(s => s.id === item.id);
        return {
          description: service?.description || 'Aucune description',
          duration: service?.duration || 0,
          category: service?.category || 'Non catégorisé',
          type: 'Service'
        };
      case 'part':
        const part = parts.find(p => p.id === item.id);
        return {
          description: part?.description || 'Aucune description',
          stock: part?.stockQuantity || 0,
          brand: part?.brand || 'Marque inconnue',
          partNumber: part?.partNumber || 'N/A',
          type: 'Pièce détachée'
        };
      default:
        return {
          description: 'Aucune information disponible',
          stock: 0,
          category: 'Inconnu',
          type: 'Article'
        };
    }
  };

    const getStatusColor = (status: string) => {
    const colors = {
      pending: 'warning',
      completed: 'success',
      returned: 'error',
    };
    return colors[status as keyof typeof colors] || 'default';
  };

  const getStatusLabel = (status: string) => {
    const labels = {
      pending: 'En attente',
      completed: 'Terminée',
      returned: 'Restitué',
    };
    return labels[status as keyof typeof labels] || status;
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
      subtotalHT: 0,
      subtotalTTC: totals.subtotal,
      discountPercentage: discountPercentage,
      discountAmount: totals.discountAmount,
      tax: 0,
      total: totals.total,
      paymentMethod,
      status: 'completed',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    try {
      const createdSale = await addSale(newSale);
      setNewSaleDialogOpen(false);
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
    setSearchQuery('');
    setSelectedItemType('product');
    setSelectedCategory('all');
    setDiscountPercentage(0);
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

  // Gérer l'impression thermique pour les ventes
  const handleOpenThermalReceipt = (sale: Sale) => {
    setThermalReceiptSale(sale);
    setThermalReceiptDialogOpen(true);
  };

  // Télécharger la facture en PDF
  const downloadInvoice = (sale: Sale) => {
    // Vérifier que la vente existe et a des données valides
    if (!sale || !sale.id) {
      console.error('Vente invalide pour le téléchargement:', sale);
      alert('Erreur: Impossible de télécharger la facture. Vente invalide.');
      return;
    }

    // Debug: vérifier la structure des données
    console.log('Données de la vente pour téléchargement:', {
      id: sale.id,
      items: sale.items,
      itemsType: typeof sale.items,
      isArray: Array.isArray(sale.items),
      subtotal: sale.subtotal,
      total: sale.total
    });

    // Créer le contenu HTML de la facture
    const client = sale.clientId ? getClientById(sale.clientId) : null;
    const clientName = client ? `${client.firstName} ${client.lastName}` : 'Client anonyme';
    const clientEmail = client?.email || '';
    const clientPhone = client?.phone || '';

    const invoiceContent = `
      <!DOCTYPE html>
      <html lang="fr">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Facture ${sale.id}</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: white;
            color: #333;
          }
          .invoice-header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #1976d2;
            padding-bottom: 20px;
          }
          .invoice-title {
            font-size: 28px;
            font-weight: bold;
            color: #1976d2;
            margin-bottom: 10px;
          }
          .invoice-number {
            font-size: 16px;
            color: #666;
          }
          .invoice-details {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
          }
          .workshop-info, .client-info {
            width: 45%;
          }
          .workshop-info h3, .client-info h3 {
            margin: 0 0 10px 0;
            color: #333;
            font-size: 18px;
          }
          .workshop-info p, .client-info p {
            margin: 5px 0;
            color: #666;
            font-size: 14px;
          }
          .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
          }
          .items-table th, .items-table td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
          }
          .items-table th {
            background-color: #f5f5f5;
            font-weight: bold;
            color: #333;
          }
          .items-table tr:nth-child(even) {
            background-color: #f9f9f9;
          }
          .totals {
            float: right;
            width: 300px;
            margin-top: 20px;
          }
          .total-line {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding: 5px 0;
          }
          .total-line.final {
            font-weight: bold;
            font-size: 18px;
            border-top: 2px solid #1976d2;
            padding-top: 10px;
            color: #1976d2;
          }
          .invoice-footer {
            margin-top: 50px;
            text-align: center;
            color: #666;
            font-size: 12px;
            border-top: 1px solid #ddd;
            padding-top: 20px;
          }
          @media print {
            body { margin: 0; padding: 15px; }
            .no-print { display: none; }
          }
        </style>
      </head>
      <body>
        <div class="invoice-header">
          <div class="invoice-title">FACTURE</div>
          <div class="invoice-number">N° ${sale.id}</div>
        </div>

        <div class="invoice-details">
          <div class="workshop-info">
            <h3>Atelier de Réparation</h3>
            <p>123 Rue de la Paix</p>
            <p>75001 Paris, France</p>
            <p>Tél: 07 59 23 91 70</p>
            <p>Email: contact.ateliergestion@gmail.com</p>
          </div>
          <div class="client-info">
            <h3>Facturé à</h3>
            <p><strong>${clientName}</strong></p>
            ${clientEmail ? `<p>Email: ${clientEmail}</p>` : ''}
            ${clientPhone ? `<p>Tél: ${clientPhone}</p>` : ''}
          </div>
        </div>

        <table class="items-table">
          <thead>
            <tr>
              <th>Article</th>
              <th>Quantité</th>
              <th>Prix unitaire</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            ${Array.isArray(sale.items) ? sale.items.map(item => `
              <tr>
                <td>${item.name || 'Article'}</td>
                <td>${item.quantity || 1}</td>
                <td>${formatFromEUR(item.unitPrice || 0, currency)}</td>
                <td>${formatFromEUR(item.totalPrice || 0, currency)}</td>
              </tr>
            `).join('') : '<tr><td colspan="4" style="text-align: center; color: #666;">Aucun article dans cette vente</td></tr>'}
          </tbody>
        </table>

        <div class="totals">
          <div class="total-line">
            <span>Sous-total HT:</span>
            <span>${formatFromEUR(sale.subtotal || 0, currency)}</span>
          </div>
          <div class="total-line">
            <span>TVA (${workshopSettings.vatRate || 20}%):</span>
            <span>${formatFromEUR(sale.tax || 0, currency)}</span>
          </div>
          ${(sale.discountPercentage || 0) > 0 ? `
            <div class="total-line">
              <span>Remise (${sale.discountPercentage}%):</span>
              <span>-${formatFromEUR(sale.discountAmount || 0, currency)}</span>
            </div>
          ` : ''}
          <div class="total-line final">
            <span>TOTAL TTC:</span>
            <span>${formatFromEUR(sale.total || 0, currency)}</span>
          </div>
        </div>

        <div class="invoice-footer">
          <p>Date d'émission: ${safeFormatDate(sale.createdAt, 'dd/MM/yyyy')}</p>
          <p>Méthode de paiement: ${getPaymentMethodLabel(sale.paymentMethod)}</p>
          <p>Merci de votre confiance !</p>
        </div>
      </body>
      </html>
    `;

    // Créer un blob avec le contenu HTML
    const blob = new Blob([invoiceContent], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    
    // Créer un lien de téléchargement
    const link = document.createElement('a');
    link.href = url;
    link.download = `Facture_${sale.id}_${safeFormatDate(sale.createdAt, 'yyyy-MM-dd')}.html`;
    
    // Déclencher le téléchargement
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    // Nettoyer l'URL
    URL.revokeObjectURL(url);
  };

  // Changer le statut de paiement
  const handleTogglePaymentStatus = async (sale: Sale) => {
    try {
      const newStatus = sale.status === 'completed' ? 'pending' : 'completed';
      await updateSale(sale.id, { status: newStatus });
      alert(`✅ Statut de paiement mis à jour : ${newStatus === 'completed' ? 'Payée' : 'En attente'}`);
    } catch (error) {
      console.error('Erreur lors de la mise à jour du statut de paiement:', error);
      alert('❌ Erreur lors de la mise à jour du statut de paiement');
    }
  };

  // Fonctions utilitaires pour les statistiques incluant les réparations
  const getSalesForDate = (date: Date, period: 'day' | 'month') => {
    const dateFormat = period === 'day' ? 'yyyy-MM-dd' : 'yyyy-MM';
    return sales.filter(sale => {
      try {
        if (!sale.createdAt) return false;
        const saleDate = new Date(sale.createdAt);
        if (isNaN(saleDate.getTime())) return false;
        return format(saleDate, dateFormat) === format(date, dateFormat);
      } catch (error) {
        console.error('Erreur de date dans la vente:', error);
        return false;
      }
    });
  };

  const getRepairsForDate = (date: Date, period: 'day' | 'month') => {
    const dateFormat = period === 'day' ? 'yyyy-MM-dd' : 'yyyy-MM';
    return repairs.filter(repair => {
      try {
        if (!repair.updatedAt && !repair.createdAt) return false;
        const repairDate = new Date(repair.updatedAt || repair.createdAt);
        if (isNaN(repairDate.getTime())) return false;
        return format(repairDate, dateFormat) === format(date, dateFormat) && repair.isPaid;
      } catch (error) {
        console.error('Erreur de date dans la réparation:', error);
        return false;
      }
    });
  };

  const getTotalRevenueForDate = (date: Date, period: 'day' | 'month') => {
    const salesForDate = getSalesForDate(date, period);
    const repairsForDate = getRepairsForDate(date, period);
    
    const salesRevenue = salesForDate.reduce((sum, sale) => sum + sale.total, 0);
    const repairsRevenue = repairsForDate.reduce((sum, repair) => sum + repair.totalPrice, 0);
    
    return salesRevenue + repairsRevenue;
  };

  const getTotalTransactionsForDate = (date: Date, period: 'day' | 'month') => {
    const salesForDate = getSalesForDate(date, period);
    const repairsForDate = getRepairsForDate(date, period);
    
    return salesForDate.length + repairsForDate.length;
  };



  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Ventes
        </Typography>
        <span style={{ color: 'text.secondary', fontSize: '1rem' }}>
          Gestion des ventes et facturation
        </span>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewSaleDialogOpen(true)}
        >
          Nouvelle vente
        </Button>
        <Button
          variant="contained"
          color="secondary"
          startIcon={<TouchAppIcon />}
          onClick={() => setSimplifiedSaleDialogOpen(true)}
        >
          Vente Simplifiée
        </Button>
      </Box>

      {/* Statistiques rapides */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <TrendingUpIcon sx={{ color: '#1976d2', mr: 1 }} />
                <Typography color="text.secondary">
                  Transactions du jour
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {getTotalTransactionsForDate(new Date(), 'day')}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Ventes + Réparations payées
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <MonetizationOnIcon sx={{ color: '#2e7d32', mr: 1 }} />
                <Typography color="text.secondary">
                  CA du jour
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {formatFromEUR(getTotalRevenueForDate(new Date(), 'day'), currency)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Ventes + Réparations payées
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <CalendarTodayIcon sx={{ color: '#ed6c02', mr: 1 }} />
                <Typography color="text.secondary">
                  Transactions du mois
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {getTotalTransactionsForDate(new Date(), 'month')}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Ventes + Réparations payées
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <AssessmentIcon sx={{ color: '#9c27b0', mr: 1 }} />
                <Typography color="text.secondary">
                  CA du mois
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {formatFromEUR(getTotalRevenueForDate(new Date(), 'month'), currency)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Ventes + Réparations payées
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Statistiques détaillées */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <BarChartIcon sx={{ color: '#1976d2', mr: 1 }} />
                <Typography variant="h6">
                  Répartition du jour
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <ShoppingCartIcon sx={{ color: '#1976d2', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    Ventes : {getSalesForDate(new Date(), 'day').length}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <BuildIcon sx={{ color: '#2e7d32', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    Réparations payées : {getRepairsForDate(new Date(), 'day').length}
                  </Typography>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <EuroIcon sx={{ color: '#1976d2', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    CA Ventes : {formatFromEUR(getSalesForDate(new Date(), 'day').reduce((sum, sale) => sum + sale.total, 0), currency)}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <AttachMoneyIcon sx={{ color: '#2e7d32', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    CA Réparations : {formatFromEUR(getRepairsForDate(new Date(), 'day').reduce((sum, repair) => sum + repair.totalPrice, 0), currency)}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <PieChartIcon sx={{ color: '#ed6c02', mr: 1 }} />
                <Typography variant="h6">
                  Répartition du mois
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <ShoppingCartIcon sx={{ color: '#1976d2', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    Ventes : {getSalesForDate(new Date(), 'month').length}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <BuildIcon sx={{ color: '#2e7d32', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    Réparations payées : {getRepairsForDate(new Date(), 'month').length}
                  </Typography>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <EuroIcon sx={{ color: '#1976d2', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    CA Ventes : {formatFromEUR(getSalesForDate(new Date(), 'month').reduce((sum, sale) => sum + sale.total, 0), currency)}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <AttachMoneyIcon sx={{ color: '#2e7d32', mr: 0.5, fontSize: '16px' }} />
                  <Typography variant="body2" color="text.secondary">
                    CA Réparations : {formatFromEUR(getRepairsForDate(new Date(), 'month').reduce((sum, repair) => sum + repair.totalPrice, 0), currency)}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Liste des ventes */}
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <HistoryIcon sx={{ color: '#1976d2', mr: 1 }} />
            <Typography variant="h6">
              Historique des ventes
            </Typography>
          </Box>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <ReceiptIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                      N° Vente
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
                      <PaymentIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                      Méthode
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <AssessmentIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                      Statut
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <InventoryIcon sx={{ mr: 0.5, fontSize: '16px' }} />
                      Actions
                    </Box>
                  </TableCell>
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
                          <span style={{ fontWeight: 600, fontSize: '0.875rem' }}>
                            {formatFromEUR(sale.total, currency)}
                          </span>
                        </TableCell>
                        <TableCell>
                          {getPaymentMethodLabel(sale.paymentMethod)}
                        </TableCell>
                        <TableCell>
                          <span style={{ 
                            display: 'inline-flex', 
                            alignItems: 'center',
                            padding: '4px 8px',
                            fontSize: '0.75rem',
                            fontWeight: 500,
                            color: getStatusColor(sale.status) === 'success' ? '#2e7d32' : 
                                   getStatusColor(sale.status) === 'warning' ? '#ed6c02' : 
                                   getStatusColor(sale.status) === 'error' ? '#d32f2f' : '#1976d2',
                            backgroundColor: getStatusColor(sale.status) === 'success' ? '#e8f5e8' : 
                                           getStatusColor(sale.status) === 'warning' ? '#fff4e5' : 
                                           getStatusColor(sale.status) === 'error' ? '#ffebee' : '#e3f2fd',
                            border: `1px solid ${getStatusColor(sale.status) === 'success' ? '#4caf50' : 
                                              getStatusColor(sale.status) === 'warning' ? '#ff9800' : 
                                              getStatusColor(sale.status) === 'error' ? '#f44336' : '#1976d2'}`,
                            borderRadius: '12px',
                            textTransform: 'uppercase'
                          }}>
                            {getStatusLabel(sale.status)}
                          </span>
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
                              title="Télécharger facture PDF"
                              onClick={() => downloadInvoice(sale)}
                              color="primary"
                            >
                              <DownloadIcon fontSize="small" />
                            </IconButton>
                            <IconButton 
                              size="small" 
                              title="Imprimer"
                              onClick={() => openInvoice(sale)}
                            >
                              <PrintIcon fontSize="small" />
                            </IconButton>
                            <IconButton 
                              size="small" 
                              title="Reçu thermique"
                              onClick={() => handleOpenThermalReceipt(sale)}
                              sx={{ color: 'primary.main' }}
                            >
                              <ReceiptIcon fontSize="small" />
                            </IconButton>

                            <IconButton 
                              size="small" 
                              title={sale.status === 'completed' ? "Marquer comme non payée" : "Marquer comme payée"}
                              onClick={() => handleTogglePaymentStatus(sale)}
                              color={sale.status === 'completed' ? "warning" : "success"}
                            >
                              <PaymentIcon fontSize="small" />
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
                  onChange={(e) => setPaymentMethod(e.target.value as 'cash' | 'card' | 'transfer' | 'check' | 'payment_link')}
                  label="Méthode de paiement"
                >
                  <MenuItem value="cash">Espèces</MenuItem>
                  <MenuItem value="card">Carte</MenuItem>
                  <MenuItem value="transfer">Virement</MenuItem>
                  <MenuItem value="check">Chèque</MenuItem>
                  <MenuItem value="payment_link">Liens paiement</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            {/* Sélection d'articles */}
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                📦 Sélection d'articles
              </Typography>
              
              {/* Type d'article */}
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Type d'article</InputLabel>
                <Select 
                  value={selectedItemType} 
                  onChange={(e) => {
                    setSelectedItemType(e.target.value as 'product' | 'service' | 'part');
                    setSelectedCategory('all'); // Réinitialiser la catégorie
                    setSearchQuery(''); // Réinitialiser la recherche
                  }}
                  label="Type d'article"
                >
                  <MenuItem value="product">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <span>🛍️ Produits & Accessoires</span>
                      <span style={{ 
                        display: 'inline-flex', 
                        alignItems: 'center',
                        padding: '2px 8px',
                        fontSize: '0.75rem',
                        fontWeight: 500,
                        color: '#1976d2',
                        backgroundColor: '#e3f2fd',
                        border: '1px solid #1976d2',
                        borderRadius: '12px'
                      }}>
                        {products.filter(p => p.isActive).length}
                      </span>
                    </Box>
                  </MenuItem>
                  <MenuItem value="service">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <span>🔧 Services de Réparation</span>
                      <span style={{ 
                        display: 'inline-flex', 
                        alignItems: 'center',
                        padding: '2px 8px',
                        fontSize: '0.75rem',
                        fontWeight: 500,
                        color: '#1976d2',
                        backgroundColor: '#e3f2fd',
                        border: '1px solid #1976d2',
                        borderRadius: '12px'
                      }}>
                        {services.filter(s => s.isActive).length}
                      </span>
                    </Box>
                  </MenuItem>
                  <MenuItem value="part">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <span>🔩 Pièces Détachées</span>
                      <span style={{ 
                        display: 'inline-flex', 
                        alignItems: 'center',
                        padding: '2px 8px',
                        fontSize: '0.75rem',
                        fontWeight: 500,
                        color: '#1976d2',
                        backgroundColor: '#e3f2fd',
                        border: '1px solid #1976d2',
                        borderRadius: '12px'
                      }}>
                        {parts.filter(p => p.isActive && p.stockQuantity > 0).length}
                      </span>
                    </Box>
                  </MenuItem>
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
                      {category === 'all' ? '📂 Toutes les catégories' : `🏷️ ${category}`}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {/* Recherche */}
              <TextField
                fullWidth
                placeholder={`Rechercher un ${selectedItemType === 'product' ? 'produit' : selectedItemType === 'service' ? 'service' : 'pièce'}...`}
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

              {/* Informations sur les articles disponibles */}
              <Box sx={{ mb: 2, p: 1, bgcolor: 'info.50', borderRadius: 1, border: '1px solid', borderColor: 'info.200' }}>
                <span style={{ color: 'info.main', fontSize: '0.875rem' }}>
                  📊 {filteredItems.length} article{filteredItems.length > 1 ? 's' : ''} disponible{filteredItems.length > 1 ? 's' : ''}
                  {selectedItemType === 'part' && (
                    <span> • Seules les pièces en stock sont affichées</span>
                  )}
                </span>
              </Box>

              {/* Liste des articles disponibles */}
              <Box sx={{ 
                maxHeight: 350, 
                overflow: 'auto', 
                border: '1px solid', 
                borderColor: 'divider', 
                borderRadius: 1,
                bgcolor: 'background.paper'
              }}>
                <List dense>
                  {filteredItems.map((item) => {
                    const details = getItemDetails(item);
                    return (
                      <ListItem 
                        key={item.id} 
                        button 
                        onClick={() => addItemToSale(item)}
                        sx={{ 
                          cursor: 'pointer',
                          '&:hover': {
                            bgcolor: 'action.hover'
                          },
                          borderBottom: '1px solid',
                          borderColor: 'divider'
                        }}
                      >
                        <ListItemText
                          primary={
                            <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                              <span style={{ fontWeight: 500 }}>
                                {item.name}
                              </span>
                              {selectedItemType === 'part' && (
                                <span style={{ 
                                  display: 'inline-flex', 
                                  alignItems: 'center',
                                  padding: '2px 8px',
                                  fontSize: '0.75rem',
                                  fontWeight: 500,
                                  color: '#2e7d32',
                                  backgroundColor: '#e8f5e8',
                                  border: '1px solid #4caf50',
                                  borderRadius: '12px',
                                  textTransform: 'uppercase'
                                }}>
                                  En stock
                                </span>
                              )}
                            </span>
                          }
                          secondary={
                            <span style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                              {details.description && (
                                <Tooltip title={details.description}>
                                  <InfoIcon fontSize="small" color="action" />
                                </Tooltip>
                              )}
                              {item.category && item.category !== 'all' && (
                                <span style={{ 
                                  display: 'inline-flex', 
                                  alignItems: 'center',
                                  padding: '2px 6px',
                                  fontSize: '0.7rem',
                                  fontWeight: 500,
                                  color: '#666',
                                  backgroundColor: '#f5f5f5',
                                  border: '1px solid #ddd',
                                  borderRadius: '8px'
                                }}>
                                  {item.category}
                                </span>
                              )}
                              <span style={{ color: 'text.secondary' }}>
                                💰 {formatFromEUR(item.price, currency)}
                              </span>
                              {selectedItemType === 'part' && (
                                <span style={{ color: 'text.secondary' }}>
                                  • Stock: {details.stock}
                                </span>
                              )}
                            </span>
                          }
                        />
                        <IconButton 
                          size="small" 
                          onClick={(e) => {
                            e.stopPropagation();
                            addItemToSale(item);
                          }}
                          sx={{ 
                            color: 'primary.main',
                            '&:hover': {
                              bgcolor: 'primary.light',
                              color: 'white'
                            }
                          }}
                        >
                          <AddIcon fontSize="small" />
                        </IconButton>
                      </ListItem>
                    );
                  })}
                  {filteredItems.length === 0 && (
                    <ListItem>
                      <ListItemText 
                        primary={
                          <span style={{ textAlign: 'center', padding: '16px 0' }}>
                            <span style={{ color: 'text.secondary', display: 'block', marginBottom: '8px' }}>
                              🔍 Aucun article trouvé
                            </span>
                            <span style={{ color: 'text.secondary', fontSize: '0.875rem' }}>
                              Essayez de modifier votre recherche ou changer de catégorie
                            </span>
                          </span>
                        }
                      />
                    </ListItem>
                  )}
                </List>
              </Box>
            </Grid>

            {/* Panier */}
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                🛒 Panier ({saleItems.length} article{saleItems.length > 1 ? 's' : ''})
              </Typography>
              
              <Box sx={{ 
                maxHeight: 350, 
                overflow: 'auto', 
                border: '1px solid', 
                borderColor: 'divider', 
                borderRadius: 1, 
                p: 2,
                bgcolor: 'background.paper'
              }}>
                {saleItems.length === 0 ? (
                  <Box sx={{ textAlign: 'center', py: 4 }}>
                    <span style={{ color: 'text.secondary', display: 'block', marginBottom: '8px' }}>
                      🛒 Votre panier est vide
                    </span>
                    <span style={{ color: 'text.secondary', fontSize: '0.875rem' }}>
                      Sélectionnez des articles dans la liste à gauche
                    </span>
                  </Box>
                ) : (
                  <List dense>
                    {saleItems.map((item, index) => (
                      <ListItem 
                        key={item.itemId}
                        sx={{ 
                          borderBottom: index < saleItems.length - 1 ? '1px solid' : 'none',
                          borderColor: 'divider',
                          py: 1
                        }}
                      >
                        <ListItemText
                          primary={
                            <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                              <span style={{ fontWeight: 500 }}>
                                {item.name}
                              </span>
                              <span style={{ 
                                display: 'inline-flex', 
                                alignItems: 'center',
                                padding: '2px 6px',
                                fontSize: '0.7rem',
                                fontWeight: 500,
                                color: item.type === 'product' ? '#1976d2' : item.type === 'service' ? '#9c27b0' : '#2e7d32',
                                backgroundColor: item.type === 'product' ? '#e3f2fd' : item.type === 'service' ? '#f3e5f5' : '#e8f5e8',
                                border: `1px solid ${item.type === 'product' ? '#1976d2' : item.type === 'service' ? '#9c27b0' : '#2e7d32'}`,
                                borderRadius: '8px',
                                textTransform: 'uppercase'
                              }}>
                                {item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'}
                              </span>
                            </span>
                          }
                          secondary={
                            <span style={{ display: 'flex', alignItems: 'center', gap: 16, marginTop: 4 }}>
                              <span style={{ color: 'text.secondary', fontSize: '0.875rem' }}>
                                💰 {formatFromEUR(item.unitPrice, currency)} l'unité
                              </span>
                              <span style={{ color: 'text.secondary', fontSize: '0.875rem' }}>
                                📦 Quantité: {item.quantity}
                              </span>
                            </span>
                          }
                        />
                        <ListItemSecondaryAction>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <TextField
                              type="number"
                              size="small"
                              value={item.quantity}
                              onChange={(e) => updateItemQuantity(item.itemId, parseInt(e.target.value) || 0)}
                              sx={{ width: 70 }}
                              inputProps={{ 
                                min: 1,
                                style: { textAlign: 'center' }
                              }}
                            />
                            <span style={{ fontWeight: 600, minWidth: 80, textAlign: 'right', fontSize: '0.875rem' }}>
                              {formatFromEUR(item.totalPrice, currency)}
                            </span>
                            <IconButton 
                              size="small" 
                              onClick={() => removeItemFromSale(item.itemId)}
                              color="error"
                              sx={{
                                '&:hover': {
                                  bgcolor: 'error.light',
                                  color: 'white'
                                }
                              }}
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

              {/* Réduction */}
              {saleItems.length > 0 && (
                <Box sx={{ 
                  mt: 2, 
                  p: 2, 
                  bgcolor: 'grey.50', 
                  borderRadius: 1,
                  border: '1px solid',
                  borderColor: 'grey.200'
                }}>
                  <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 600, color: 'text.primary' }}>
                    🎫 Réduction
                  </Typography>
                  <TextField
                    fullWidth
                    type="number"
                    label="Réduction (%)"
                    value={discountPercentage}
                    onChange={(e) => setDiscountPercentage(Math.max(0, Math.min(100, parseFloat(e.target.value) || 0)))}
                    inputProps={{ 
                      min: 0,
                      max: 100,
                      step: 0.1
                    }}
                    size="small"
                    sx={{ mb: 1 }}
                  />
                  {discountPercentage > 0 && (
                    <Alert severity="info" sx={{ fontSize: '0.875rem' }}>
                      Réduction de {discountPercentage}% sur le total TTC = {formatFromEUR(totals.discountAmount, currency)}
                    </Alert>
                  )}
                </Box>
              )}

              {/* Totaux */}
              {saleItems.length > 0 && (
                <Box sx={{ 
                  mt: 2, 
                  p: 2, 
                  bgcolor: 'grey.50', 
                  borderRadius: 1,
                  border: '1px solid',
                  borderColor: 'grey.200'
                }}>
                  <span style={{ display: 'block', marginBottom: '16px', fontWeight: 600, color: 'text.primary', fontSize: '0.875rem' }}>
                    📊 Récapitulatif
                  </span>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <span style={{ fontSize: '0.875rem' }}>Sous-total:</span>
                    <span style={{ fontSize: '0.875rem', fontWeight: 500 }}>
                      {formatFromEUR(totals.subtotal, currency)}
                    </span>
                  </Box>
                  {discountPercentage > 0 && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <span style={{ fontSize: '0.875rem', color: 'success.main' }}>Réduction ({discountPercentage}%):</span>
                      <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'success.main' }}>
                        -{formatFromEUR(totals.discountAmount, currency)}
                      </span>
                    </Box>
                  )}
                  <Divider sx={{ my: 1 }} />
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ fontWeight: 600, fontSize: '1.25rem' }}>Total:</span>
                    <span style={{ fontWeight: 600, color: 'primary.main', fontSize: '1.25rem' }}>
                      {formatFromEUR(totals.total, currency)}
                    </span>
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
            Créer la vente ({formatFromEUR(totals.total, currency)})
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

        {/* Dialogue Vente Simplifiée */}
        <SimplifiedSalesDialog
          open={simplifiedSaleDialogOpen}
          onClose={() => setSimplifiedSaleDialogOpen(false)}
        />

        {/* Dialog pour l'impression thermique */}
        {thermalReceiptSale && (
          <ThermalReceiptDialog
            open={thermalReceiptDialogOpen}
            onClose={() => {
              setThermalReceiptDialogOpen(false);
              setThermalReceiptSale(null);
            }}
            sale={thermalReceiptSale}
            client={thermalReceiptSale.clientId ? getClientById(thermalReceiptSale.clientId) : undefined}
            device={undefined}
            technician={undefined}
            workshopInfo={{
              name: workshopSettings?.name || 'Atelier',
              address: workshopSettings?.address,
              phone: workshopSettings?.phone,
              email: workshopSettings?.email,
              siret: workshopSettings?.siret,
              vatNumber: workshopSettings?.vatNumber,
            }}
          />
        )}

      </Box>
    );
  };

export default Sales;

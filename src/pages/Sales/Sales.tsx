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
  Snackbar,
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
  Close as CloseIcon,
  Person as PersonIcon,
  Discount as DiscountIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Sale, SaleItem, Client } from '../../types';
import Invoice from '../../components/Invoice';
import SimplifiedSalesDialog from '../../components/SimplifiedSalesDialog';
import ClientForm from '../../components/ClientForm';
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
    addClient,
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
  const [clientFormOpen, setClientFormOpen] = useState(false);
  
  // État pour la notification de succès
  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');

  // Fonction helper pour obtenir la source d'un item
  const getItemSource = (item: SaleItem) => {
    switch (item.type) {
      case 'product': return products.find(p => p.id === item.itemId);
      case 'service': return services.find(s => s.id === item.itemId);
      case 'part': return parts.find(p => p.id === item.itemId);
      default: return null;
    }
  };

  // Fonction pour arrondir à 2 décimales
  const roundToTwo = (num: number): number => {
    return Math.round(num * 100) / 100;
  };

  // Calcul des totaux (AVEC TVA)
  const totals = useMemo(() => {
    // Gestion du taux de TVA : utiliser la valeur configurée ou 20% par défaut
    let vatRate = 20; // Valeur par défaut
    if (workshopSettings?.vatRate !== undefined && workshopSettings?.vatRate !== null) {
      const parsedRate = parseFloat(workshopSettings.vatRate);
      if (!isNaN(parsedRate)) {
        vatRate = parsedRate;
      }
    }
    
    // Calculer par unité puis multiplier pour éviter les erreurs d'arrondi
    let subtotal = 0;
    let tax = 0;
    let totalTTC = 0;
    
    saleItems.forEach(item => {
      // Calculer pour UNE unité
      const unitHT = roundToTwo(item.unitPrice);
      const unitTax = roundToTwo(unitHT * (vatRate / 100));
      const unitTTC = roundToTwo(unitHT + unitTax);
      
      // Multiplier par la quantité
      const lineHT = roundToTwo(unitHT * item.quantity);
      const lineTax = roundToTwo(unitTax * item.quantity);
      const lineTTC = roundToTwo(unitTTC * item.quantity);
      
      subtotal += lineHT;
      tax += lineTax;
      totalTTC += lineTTC;
    });
    
    subtotal = roundToTwo(subtotal);
    tax = roundToTwo(tax);
    const totalBeforeDiscount = roundToTwo(totalTTC);
    
    // Calculer la remise
    const discountAmount = roundToTwo((totalBeforeDiscount * discountPercentage) / 100);
    
    // Total final
    const total = roundToTwo(totalBeforeDiscount - discountAmount);
    
    return { 
      subtotal, 
      subtotalHT: subtotal, 
      subtotalTTC: totalBeforeDiscount,
      tax, 
      vatRate,
      totalBeforeDiscount, 
      discountAmount, 
      total 
    };
  }, [saleItems, discountPercentage, workshopSettings?.vatRate]);

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
          ? { ...saleItem, quantity: saleItem.quantity + 1, totalPrice: roundToTwo((saleItem.quantity + 1) * saleItem.unitPrice) }
          : saleItem
      ));
    } else {
      // Ajouter un nouvel article
      const newItem: SaleItemForm = {
        type: item.type as 'product' | 'service' | 'part',
        itemId: item.id,
        name: item.name,
        quantity: 1,
        unitPrice: roundToTwo(item.price),
        totalPrice: roundToTwo(item.price),
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
        ? { ...item, quantity, totalPrice: roundToTwo(quantity * item.unitPrice) }
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
      subtotalHT: totals.subtotalHT,
      subtotalTTC: totals.subtotalTTC,
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

  // Créer un nouveau client
  const handleCreateNewClient = async (clientFormData: any) => {
    try {
      const firstName = clientFormData.firstName?.trim() || 'Client';
      const lastName = clientFormData.lastName?.trim() || 'Sans nom';
      
      const clientData = {
        firstName,
        lastName,
        email: clientFormData.email || '',
        phone: (clientFormData.countryCode || '33') + (clientFormData.mobile || ''),
        address: clientFormData.address || '',
        notes: clientFormData.internalNote || '',
        category: clientFormData.category || 'particulier',
        title: clientFormData.title || 'mr',
        companyName: clientFormData.companyName || '',
        vatNumber: clientFormData.vatNumber || '',
        sirenNumber: clientFormData.sirenNumber || '',
        countryCode: clientFormData.countryCode || '33',
        addressComplement: clientFormData.addressComplement || '',
        region: clientFormData.region || '',
        postalCode: clientFormData.postalCode || '',
        city: clientFormData.city || '',
        billingAddressSame: clientFormData.billingAddressSame !== undefined ? clientFormData.billingAddressSame : true,
        billingAddress: clientFormData.billingAddress || '',
        billingAddressComplement: clientFormData.billingAddressComplement || '',
        billingRegion: clientFormData.billingRegion || '',
        billingPostalCode: clientFormData.billingPostalCode || '',
        billingCity: clientFormData.billingCity || '',
        accountingCode: clientFormData.accountingCode || '',
        cniIdentifier: clientFormData.cniIdentifier || '',
        attachedFilePath: clientFormData.attachedFile ? clientFormData.attachedFile.name : '',
        internalNote: clientFormData.internalNote || '',
        status: clientFormData.status || 'displayed',
        smsNotification: clientFormData.smsNotification !== undefined ? clientFormData.smsNotification : true,
        emailNotification: clientFormData.emailNotification !== undefined ? clientFormData.emailNotification : true,
        smsMarketing: clientFormData.smsMarketing !== undefined ? clientFormData.smsMarketing : true,
        emailMarketing: clientFormData.emailMarketing !== undefined ? clientFormData.emailMarketing : true,
      };

      await addClient(clientData);
      
      setClientFormOpen(false);
      
      // Attendre que le store soit mis à jour puis trouver et sélectionner le client créé
      setTimeout(() => {
        const newClientCreated = clients.find(c => 
          c.firstName === firstName && 
          c.lastName === lastName && 
          c.email === clientFormData.email
        );
        
        if (newClientCreated) {
          setSelectedClientId(newClientCreated.id);
          setSnackbarMessage(`✅ Client ${firstName} ${lastName} créé avec succès !`);
          setSnackbarOpen(true);
        } else {
          // Si on ne trouve pas le client par email, chercher par nom
          const newClientByName = clients.find(c => 
            c.firstName === firstName && 
            c.lastName === lastName
          );
          if (newClientByName) {
            setSelectedClientId(newClientByName.id);
            setSnackbarMessage(`✅ Client ${firstName} ${lastName} créé avec succès !`);
            setSnackbarOpen(true);
          }
        }
      }, 300);
    } catch (error) {
      console.error('Erreur lors de la création du client:', error);
      setSnackbarMessage('❌ Erreur lors de la création du client');
      setSnackbarOpen(true);
      throw error;
    }
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
            ${(() => {
              let items = sale.items;
              
              // Parser les items si c'est une chaîne JSON
              if (typeof items === 'string') {
                try {
                  items = JSON.parse(items);
                } catch (error) {
                  console.error('Error parsing items in downloadInvoice:', error);
                  items = [];
                }
              }
              
              // Convertir en tableau si nécessaire
              const itemsArray = Array.isArray(items) ? items : (items && typeof items === 'object' ? Object.values(items) : []);
              
              return itemsArray.length > 0 ? itemsArray.map(item => `
                <tr>
                  <td>${item.name || 'Article'}</td>
                  <td>${item.quantity || 1}</td>
                  <td>${formatFromEUR(item.unitPrice || 0, currency)}</td>
                  <td>${formatFromEUR(item.totalPrice || 0, currency)}</td>
                </tr>
              `).join('') : '<tr><td colspan="4" style="text-align: center; color: #666;">Aucun article dans cette vente</td></tr>';
            })()}
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
      <Dialog 
        open={newSaleDialogOpen} 
        onClose={() => setNewSaleDialogOpen(false)} 
        maxWidth="xl" 
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 2,
            boxShadow: '0 8px 32px rgba(0, 0, 0, 0.12)',
            minHeight: '90vh',
          }
        }}
      >
        <DialogTitle
          sx={{
            background: 'linear-gradient(135deg, #1976d2 0%, #42a5f5 100%)',
            color: 'white',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            py: 2.5,
            px: 3,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <ShoppingCartIcon sx={{ fontSize: 32 }} />
            <Typography variant="h5" component="span" sx={{ fontWeight: 600 }}>
              Nouvelle vente
            </Typography>
          </Box>
          <IconButton
            onClick={() => {
              setNewSaleDialogOpen(false);
              resetForm();
            }}
            sx={{ 
              color: 'white',
              '&:hover': {
                bgcolor: 'rgba(255, 255, 255, 0.1)',
              }
            }}
          >
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent sx={{ p: 3, bgcolor: '#f8f9fa' }}>
          <Grid container spacing={3} sx={{ mt: 0 }}>
            {/* Informations client et paiement */}
            <Grid item xs={12}>
              <Paper 
                elevation={2}
                sx={{ 
                  p: 3, 
                  borderRadius: 2,
                  bgcolor: 'white',
                  border: '1px solid',
                  borderColor: 'divider',
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}>
                  <PersonIcon sx={{ color: 'primary.main', fontSize: 28 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: 'text.primary' }}>
                    Informations client
                  </Typography>
                </Box>
                
                <Grid container spacing={2}>
                  <Grid item xs={12} md={6}>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <Autocomplete
                        fullWidth
                        options={[{ id: '', firstName: 'Client', lastName: 'anonyme', email: '', phone: '' } as any, ...clients]}
                        value={selectedClientId ? clients.find(c => c.id === selectedClientId) || null : null}
                        onChange={(event, newValue) => {
                          setSelectedClientId(newValue?.id || '');
                        }}
                        getOptionLabel={(option) => 
                          option.id === '' 
                            ? 'Client anonyme' 
                            : `${option.firstName} ${option.lastName}${option.email ? ` - ${option.email}` : ''}${option.phone ? ` - ${option.phone}` : ''}`
                        }
                        filterOptions={(options, { inputValue }) => {
                          if (!inputValue) return options;
                          const searchTerm = inputValue.toLowerCase();
                          return options.filter(option => {
                            if (option.id === '') return 'client anonyme'.includes(searchTerm);
                            const firstName = (option.firstName || '').toLowerCase();
                            const lastName = (option.lastName || '').toLowerCase();
                            const email = (option.email || '').toLowerCase();
                            const phone = (option.phone || '').toLowerCase();
                            return firstName.includes(searchTerm) || 
                                   lastName.includes(searchTerm) || 
                                   email.includes(searchTerm) || 
                                   phone.includes(searchTerm);
                          });
                        }}
                        renderInput={(params) => (
                          <TextField 
                            {...params} 
                            label="Client" 
                            placeholder="Rechercher par nom, email ou téléphone..."
                          />
                        )}
                        isOptionEqualToValue={(option, value) => option.id === value.id}
                      />
                      <Tooltip title="Créer un nouveau client">
                        <IconButton
                          onClick={() => setClientFormOpen(true)}
                          sx={{
                            bgcolor: 'primary.main',
                            color: 'white',
                            '&:hover': {
                              bgcolor: 'primary.dark',
                            },
                          }}
                        >
                          <AddIcon />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <FormControl fullWidth>
                      <InputLabel>Méthode de paiement</InputLabel>
                      <Select 
                        value={paymentMethod} 
                        onChange={(e) => setPaymentMethod(e.target.value as 'cash' | 'card' | 'transfer' | 'check' | 'payment_link')}
                        label="Méthode de paiement"
                      >
                        <MenuItem value="cash">💵 Espèces</MenuItem>
                        <MenuItem value="card">💳 Carte</MenuItem>
                        <MenuItem value="transfer">🏦 Virement</MenuItem>
                        <MenuItem value="check">📝 Chèque</MenuItem>
                        <MenuItem value="payment_link">🔗 Liens paiement</MenuItem>
                      </Select>
                    </FormControl>
                  </Grid>
                </Grid>
              </Paper>
            </Grid>

            {/* Sélection d'articles */}
            <Grid item xs={12} md={6}>
              <Paper 
                elevation={2}
                sx={{ 
                  p: 3, 
                  borderRadius: 2,
                  bgcolor: 'white',
                  border: '1px solid',
                  borderColor: 'divider',
                  height: '100%',
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}>
                  <InventoryIcon sx={{ color: 'primary.main', fontSize: 28 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: 'text.primary' }}>
                    Sélection d'articles
                  </Typography>
                  <Badge 
                    badgeContent={filteredItems.length} 
                    color="primary"
                    sx={{ ml: 'auto' }}
                  />
                </Box>
              
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
              <Alert 
                severity="info" 
                sx={{ 
                  mb: 2,
                  '& .MuiAlert-message': {
                    width: '100%'
                  }
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Typography variant="body2">
                    {filteredItems.length} article{filteredItems.length > 1 ? 's' : ''} disponible{filteredItems.length > 1 ? 's' : ''}
                  </Typography>
                  {selectedItemType === 'part' && (
                    <Typography variant="caption">
                      Seules les pièces en stock
                    </Typography>
                  )}
                </Box>
              </Alert>

              {/* Liste des articles disponibles */}
              <Box sx={{ 
                maxHeight: 450, 
                overflow: 'auto', 
                border: '2px solid', 
                borderColor: 'primary.light', 
                borderRadius: 2,
                bgcolor: 'background.paper',
                '&::-webkit-scrollbar': {
                  width: '8px',
                },
                '&::-webkit-scrollbar-track': {
                  bgcolor: '#f1f1f1',
                },
                '&::-webkit-scrollbar-thumb': {
                  bgcolor: '#888',
                  borderRadius: '4px',
                  '&:hover': {
                    bgcolor: '#555',
                  },
                },
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
                          transition: 'all 0.2s ease',
                          '&:hover': {
                            bgcolor: 'primary.light',
                            transform: 'translateX(4px)',
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
                              <span style={{ color: 'text.secondary', fontSize: '0.75rem' }}>
                                💰 {formatFromEUR(item.price, currency)} HT / {formatFromEUR(item.price * (1 + (parseFloat(workshopSettings?.vatRate || '20') / 100)), currency)} TTC
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
              </Paper>
            </Grid>

            {/* Panier */}
            <Grid item xs={12} md={6}>
              <Paper 
                elevation={2}
                sx={{ 
                  p: 3, 
                  borderRadius: 2,
                  bgcolor: 'white',
                  border: '1px solid',
                  borderColor: 'divider',
                  height: '100%',
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}>
                  <ShoppingCartIcon sx={{ color: 'success.main', fontSize: 28 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: 'text.primary' }}>
                    Panier
                  </Typography>
                  <Badge 
                    badgeContent={saleItems.length} 
                    color="success"
                    sx={{ ml: 'auto' }}
                  />
                </Box>
              
              <Box sx={{ 
                maxHeight: 450, 
                overflow: 'auto', 
                border: '2px solid', 
                borderColor: 'success.light', 
                borderRadius: 2, 
                p: 2,
                bgcolor: 'background.paper',
                '&::-webkit-scrollbar': {
                  width: '8px',
                },
                '&::-webkit-scrollbar-track': {
                  bgcolor: '#f1f1f1',
                },
                '&::-webkit-scrollbar-thumb': {
                  bgcolor: '#888',
                  borderRadius: '4px',
                  '&:hover': {
                    bgcolor: '#555',
                  },
                },
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
                  bgcolor: 'warning.50', 
                  borderRadius: 2,
                  border: '2px solid',
                  borderColor: 'warning.light',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.05)',
                }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                    <DiscountIcon sx={{ color: 'warning.main' }} />
                    <Typography variant="subtitle2" sx={{ fontWeight: 600, color: 'text.primary' }}>
                      Réduction
                    </Typography>
                  </Box>
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
                    <Alert severity="success" sx={{ fontSize: '0.875rem', mt: 1 }}>
                      Réduction de {discountPercentage}% = {formatFromEUR(totals.discountAmount, currency)}
                    </Alert>
                  )}
                </Box>
              )}

              {/* Totaux */}
              {saleItems.length > 0 && (
                <Box sx={{ 
                  mt: 2, 
                  p: 2, 
                  background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)',
                  borderRadius: 2,
                  border: '2px solid',
                  borderColor: 'primary.main',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 1.5 }}>
                    <AssessmentIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                    <Typography variant="subtitle1" sx={{ fontWeight: 600, color: 'text.primary' }}>
                      Récapitulatif
                    </Typography>
                  </Box>
                  
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1, alignItems: 'center' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                      <MonetizationOnIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                      <Typography variant="body2">Prix HT:</Typography>
                    </Box>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {formatFromEUR(totals.subtotal, currency)}
                    </Typography>
                  </Box>
                  
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1, alignItems: 'center' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                      <AssessmentIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                      <Typography variant="body2">TVA ({totals.vatRate}%):</Typography>
                    </Box>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {formatFromEUR(totals.tax, currency)}
                    </Typography>
                  </Box>
                  
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1, alignItems: 'center' }}>
                    <Typography variant="body2">Total TTC:</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {formatFromEUR(totals.totalBeforeDiscount, currency)}
                    </Typography>
                  </Box>
                  
                  {discountPercentage > 0 && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1, alignItems: 'center' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <DiscountIcon sx={{ fontSize: 16, color: 'success.main' }} />
                        <Typography variant="body2" sx={{ color: 'success.main' }}>
                          Réduction ({discountPercentage}%):
                        </Typography>
                      </Box>
                      <Typography variant="body2" sx={{ fontWeight: 600, color: 'success.main' }}>
                        -{formatFromEUR(totals.discountAmount, currency)}
                      </Typography>
                    </Box>
                  )}
                  
                  <Divider sx={{ my: 1.5, borderColor: 'primary.main', borderWidth: 1 }} />
                  
                  <Box sx={{ 
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    alignItems: 'center',
                    p: 1.5,
                    bgcolor: 'primary.main',
                    borderRadius: 1,
                    color: 'white',
                  }}>
                    <Typography variant="h6" sx={{ fontWeight: 700 }}>
                      TOTAL:
                    </Typography>
                    <Typography variant="h6" sx={{ fontWeight: 700 }}>
                      {formatFromEUR(totals.total, currency)}
                    </Typography>
                  </Box>
                </Box>
              )}
              </Paper>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions 
          sx={{ 
            p: 3, 
            bgcolor: '#f8f9fa',
            borderTop: '2px solid',
            borderColor: 'divider',
            gap: 2,
          }}
        >
          <Button 
            onClick={() => {
              setNewSaleDialogOpen(false);
              resetForm();
            }}
            variant="outlined"
            color="error"
            size="large"
            sx={{
              minWidth: 120,
              fontWeight: 600,
            }}
          >
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={createSale}
            disabled={saleItems.length === 0}
            size="large"
            startIcon={<ReceiptIcon />}
            sx={{
              minWidth: 200,
              background: 'linear-gradient(135deg, #4caf50 0%, #66bb6a 100%)',
              fontWeight: 600,
              fontSize: '1rem',
              py: 1.5,
              boxShadow: '0 4px 12px rgba(76, 175, 80, 0.3)',
              '&:hover': {
                background: 'linear-gradient(135deg, #45a049 0%, #5db85f 100%)',
                boxShadow: '0 6px 16px rgba(76, 175, 80, 0.4)',
              },
              '&:disabled': {
                background: 'grey.300',
                color: 'grey.500',
              },
            }}
          >
            Créer la vente ({formatFromEUR(totals.subtotal, currency)} HT / {formatFromEUR(totals.total, currency)} TTC)
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

        {/* Dialogue de création de client */}
        <ClientForm
          open={clientFormOpen}
          onClose={() => setClientFormOpen(false)}
          onSubmit={handleCreateNewClient}
          existingEmails={clients.map(client => client.email?.toLowerCase() || '')}
        />

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

export default Sales;

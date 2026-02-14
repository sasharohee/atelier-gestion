import React, { useState, useMemo, useEffect } from 'react';
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
  Chip,
  Paper,
} from '@mui/material';
import { alpha } from '@mui/material/styles';
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
  PointOfSale as PointOfSaleIcon,
  SentimentDissatisfied as EmptyIcon,
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

/* ─── design tokens ─── */
const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': { boxShadow: '0 8px 32px rgba(0,0,0,0.10)', transform: 'translateY(-2px)' },
} as const;
const CARD_STATIC = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
} as const;
const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid',
    borderColor: 'divider',
    fontWeight: 600,
    fontSize: '0.75rem',
    color: 'text.secondary',
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;
const BTN_DARK = {
  borderRadius: '10px',
  textTransform: 'none',
  fontWeight: 600,
  bgcolor: '#111827',
  '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;
const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── KPI mini card ─── */
function KpiMini({ icon, iconColor, label, value, subtitle }: { icon: React.ReactNode; iconColor: string; label: string; value: string | number; subtitle?: string }) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box
            sx={{
              width: 40,
              height: 40,
              borderRadius: '12px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
              color: '#fff',
              flexShrink: 0,
              boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
            }}
          >
            {icon}
          </Box>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>
              {value}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>
              {label}
            </Typography>
            {subtitle && (
              <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.6rem', display: 'block' }}>
                {subtitle}
              </Typography>
            )}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── filter types ─── */
type SaleFilter = 'all' | 'completed' | 'pending' | 'returned';
const SALE_FILTERS: { key: SaleFilter; label: string; color: string }[] = [
  { key: 'all', label: 'Toutes', color: '#6366f1' },
  { key: 'completed', label: 'Payées', color: '#22c55e' },
  { key: 'pending', label: 'En attente', color: '#f59e0b' },
  { key: 'returned', label: 'Restituées', color: '#ef4444' },
];

const PAYMENT_COLORS: Record<string, string> = {
  cash: '#22c55e',
  card: '#6366f1',
  transfer: '#3b82f6',
  check: '#f59e0b',
  payment_link: '#8b5cf6',
};

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
    loadProducts,
    loadServices,
    loadParts,
  } = useAppStore();

  const { workshopSettings } = useWorkshopSettings();
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

  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');

  /* ─── sales list search/filter ─── */
  const [salesSearch, setSalesSearch] = useState('');
  const [salesFilter, setSalesFilter] = useState<SaleFilter>('all');

  useEffect(() => {
    const loadData = async () => {
      try {
        await Promise.all([loadProducts(), loadServices(), loadParts()]);
      } catch {
        // silently fail
      }
    };
    loadData();
  }, [loadProducts, loadServices, loadParts]);

  useEffect(() => {
    if (newSaleDialogOpen) {
      const reloadData = async () => {
        try {
          await Promise.all([loadProducts(), loadServices(), loadParts()]);
        } catch {
          // silently fail
        }
      };
      reloadData();
    }
  }, [newSaleDialogOpen, loadProducts, loadServices, loadParts]);

  /* ─── helpers ─── */
  const roundToTwo = (num: number): number => Math.round(num * 100) / 100;

  const getStatusColor = (status: string) => {
    const map: Record<string, string> = { pending: '#f59e0b', completed: '#22c55e', returned: '#ef4444' };
    return map[status] || '#6b7280';
  };

  const getStatusLabel = (status: string) => {
    const labels: Record<string, string> = { pending: 'En attente', completed: 'Payée', returned: 'Restituée' };
    return labels[status] || status;
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels: Record<string, string> = { cash: 'Espèces', card: 'Carte', transfer: 'Virement', check: 'Chèque', payment_link: 'Lien paiement' };
    return labels[method] || method;
  };

  const safeFormatDate = (date: any, formatString: string) => {
    try {
      if (!date) return 'Date inconnue';
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) return 'Date invalide';
      return format(dateObj, formatString, { locale: fr });
    } catch {
      return 'Date invalide';
    }
  };

  /* ─── totals ─── */
  const totals = useMemo(() => {
    let vatRate = 20;
    if (workshopSettings?.vatRate !== undefined && workshopSettings?.vatRate !== null) {
      const parsedRate = parseFloat(workshopSettings.vatRate);
      if (!isNaN(parsedRate)) vatRate = parsedRate;
    }

    let subtotal = 0;
    let tax = 0;
    let totalTTC = 0;

    saleItems.forEach((item) => {
      const unitHT = roundToTwo(item.unitPrice);
      const unitTax = roundToTwo(unitHT * (vatRate / 100));
      const unitTTC = roundToTwo(unitHT + unitTax);
      subtotal += roundToTwo(unitHT * item.quantity);
      tax += roundToTwo(unitTax * item.quantity);
      totalTTC += roundToTwo(unitTTC * item.quantity);
    });

    subtotal = roundToTwo(subtotal);
    tax = roundToTwo(tax);
    const totalBeforeDiscount = roundToTwo(totalTTC);
    const discountAmount = roundToTwo((totalBeforeDiscount * discountPercentage) / 100);
    const total = roundToTwo(totalBeforeDiscount - discountAmount);

    return { subtotal, subtotalHT: subtotal, subtotalTTC: totalBeforeDiscount, tax, vatRate, totalBeforeDiscount, discountAmount, total };
  }, [saleItems, discountPercentage, workshopSettings?.vatRate]);

  /* ─── dialog filtered items ─── */
  const filteredItems = useMemo(() => {
    let items: Array<{ id: string; name: string; price: number; type: string; category?: string }> = [];

    switch (selectedItemType) {
      case 'product':
        items = (products || []).filter((p) => p.isActive && p.id && p.name).map((p) => ({ id: p.id, name: p.name, price: p.price || 0, type: 'product', category: p.category || '' }));
        break;
      case 'service':
        items = (services || []).filter((s) => s.isActive && s.id && s.name).map((s) => ({ id: s.id, name: s.name, price: s.price || 0, type: 'service', category: s.category || '' }));
        break;
      case 'part':
        items = (parts || []).filter((p) => p.isActive && p.stockQuantity > 0 && p.id && p.name).map((p) => ({ id: p.id, name: p.name, price: p.price || 0, type: 'part', category: p.brand || '' }));
        break;
    }

    if (selectedCategory !== 'all') items = items.filter((i) => i.category && i.category.trim() === selectedCategory.trim());
    if (searchQuery) items = items.filter((i) => i.name.toLowerCase().includes(searchQuery.toLowerCase()));
    return items;
  }, [selectedItemType, selectedCategory, searchQuery, products, services, parts]);

  const availableCategories = useMemo(() => {
    let categories: string[] = [];
    switch (selectedItemType) {
      case 'product':
        categories = Array.from(new Set(products.filter((p) => p.isActive && p.category?.trim()).map((p) => p.category!)));
        break;
      case 'service':
        categories = Array.from(new Set(services.filter((s) => s.isActive && s.category?.trim()).map((s) => s.category!)));
        break;
      case 'part':
        categories = Array.from(new Set(parts.filter((p) => p.isActive && p.stockQuantity > 0 && p.brand?.trim()).map((p) => p.brand!)));
        break;
    }
    return ['all', ...categories];
  }, [selectedItemType, products, services, parts]);

  const getCategoryCount = (category: string) => {
    if (category === 'all') return filteredItems.length;
    switch (selectedItemType) {
      case 'product':
        return products.filter((p) => p.isActive && p.category === category).length;
      case 'service':
        return services.filter((s) => s.isActive && s.category === category).length;
      case 'part':
        return parts.filter((p) => p.isActive && p.stockQuantity > 0 && p.brand === category).length;
      default:
        return 0;
    }
  };

  const getItemDetails = (item: { id: string; type: string }) => {
    switch (item.type) {
      case 'product': {
        const p = products.find((x) => x.id === item.id);
        return { description: p?.description || '', stock: p?.stockQuantity || 0, category: p?.category || '', type: 'Produit' };
      }
      case 'service': {
        const s = services.find((x) => x.id === item.id);
        return { description: s?.description || '', duration: s?.duration || 0, category: s?.category || '', type: 'Service' };
      }
      case 'part': {
        const p = parts.find((x) => x.id === item.id);
        return { description: p?.description || '', stock: p?.stockQuantity || 0, brand: p?.brand || '', partNumber: p?.partNumber || '', type: 'Pièce' };
      }
      default:
        return { description: '', stock: 0, category: '', type: 'Article' };
    }
  };

  /* ─── revenue helpers ─── */
  const getSalesForDate = (date: Date, period: 'day' | 'month') => {
    const df = period === 'day' ? 'yyyy-MM-dd' : 'yyyy-MM';
    return sales.filter((s) => {
      try {
        if (!s.createdAt) return false;
        const d = new Date(s.createdAt);
        return !isNaN(d.getTime()) && format(d, df) === format(date, df);
      } catch {
        return false;
      }
    });
  };

  const getRepairsForDate = (date: Date, period: 'day' | 'month') => {
    const df = period === 'day' ? 'yyyy-MM-dd' : 'yyyy-MM';
    return repairs.filter((r) => {
      try {
        if (!r.updatedAt && !r.createdAt) return false;
        const d = new Date(r.updatedAt || r.createdAt);
        return !isNaN(d.getTime()) && format(d, df) === format(date, df) && r.isPaid;
      } catch {
        return false;
      }
    });
  };

  const getTotalRevenueForDate = (date: Date, period: 'day' | 'month') => {
    return getSalesForDate(date, period).reduce((s, sale) => s + sale.total, 0) + getRepairsForDate(date, period).reduce((s, r) => s + r.totalPrice, 0);
  };

  const getTotalTransactionsForDate = (date: Date, period: 'day' | 'month') => {
    return getSalesForDate(date, period).length + getRepairsForDate(date, period).length;
  };

  /* ─── filtered sales list ─── */
  const filteredSales = useMemo(() => {
    let list = sales
      .filter((s) => {
        try {
          if (!s.createdAt) return false;
          return !isNaN(new Date(s.createdAt).getTime());
        } catch {
          return false;
        }
      })
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    if (salesFilter !== 'all') list = list.filter((s) => s.status === salesFilter);

    if (salesSearch.trim()) {
      const q = salesSearch.toLowerCase();
      list = list.filter((s) => {
        const client = s.clientId ? getClientById(s.clientId) : null;
        const clientName = client ? `${client.firstName} ${client.lastName}`.toLowerCase() : 'client anonyme';
        return s.id.toLowerCase().includes(q) || clientName.includes(q) || getPaymentMethodLabel(s.paymentMethod).toLowerCase().includes(q);
      });
    }

    return list;
  }, [sales, salesFilter, salesSearch, getClientById]);

  /* ─── cart actions ─── */
  const addItemToSale = (item: { id: string; name: string; price: number; type: string }) => {
    const existing = saleItems.find((si) => si.itemId === item.id);
    if (existing) {
      setSaleItems((prev) => prev.map((si) => (si.itemId === item.id ? { ...si, quantity: si.quantity + 1, totalPrice: roundToTwo((si.quantity + 1) * si.unitPrice) } : si)));
    } else {
      setSaleItems((prev) => [...prev, { type: item.type as 'product' | 'service' | 'part', itemId: item.id, name: item.name, quantity: 1, unitPrice: roundToTwo(item.price), totalPrice: roundToTwo(item.price) }]);
    }
  };

  const removeItemFromSale = (itemId: string) => setSaleItems((prev) => prev.filter((i) => i.itemId !== itemId));

  const updateItemQuantity = (itemId: string, quantity: number) => {
    if (quantity <= 0) return removeItemFromSale(itemId);
    setSaleItems((prev) => prev.map((i) => (i.itemId === itemId ? { ...i, quantity, totalPrice: roundToTwo(quantity * i.unitPrice) } : i)));
  };

  const createSale = async () => {
    if (saleItems.length === 0) {
      setSnackbarMessage('Veuillez ajouter au moins un article.');
      setSnackbarOpen(true);
      return;
    }

    const saleItemsFormatted: SaleItem[] = saleItems.map((item) => ({
      id: item.itemId,
      type: item.type,
      itemId: item.itemId,
      name: item.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    }));

    const newSale: Sale = {
      id: '',
      clientId: selectedClientId || undefined,
      items: saleItemsFormatted,
      subtotal: totals.subtotal,
      subtotalHT: totals.subtotalHT,
      subtotalTTC: totals.subtotalTTC,
      discountPercentage,
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
      openInvoice(createdSale);
    } catch {
      setSnackbarMessage('Erreur lors de la création de la vente.');
      setSnackbarOpen(true);
    }
  };

  const resetForm = () => {
    setSelectedClientId('');
    setPaymentMethod('card');
    setSaleItems([]);
    setSearchQuery('');
    setSelectedItemType('product');
    setSelectedCategory('all');
    setDiscountPercentage(0);
  };

  const openInvoice = (sale: Sale) => {
    setSelectedSaleForInvoice(sale);
    setInvoiceOpen(true);
  };

  const closeInvoice = () => {
    setInvoiceOpen(false);
    setSelectedSaleForInvoice(null);
  };

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

      setTimeout(() => {
        const found = clients.find((c) => c.firstName === firstName && c.lastName === lastName && c.email === clientFormData.email) || clients.find((c) => c.firstName === firstName && c.lastName === lastName);
        if (found) {
          setSelectedClientId(found.id);
          setSnackbarMessage(`Client ${firstName} ${lastName} créé avec succès !`);
          setSnackbarOpen(true);
        }
      }, 300);
    } catch (error) {
      setSnackbarMessage('Erreur lors de la création du client');
      setSnackbarOpen(true);
      throw error;
    }
  };

  const handleOpenThermalReceipt = (sale: Sale) => {
    setThermalReceiptSale(sale);
    setThermalReceiptDialogOpen(true);
  };

  const downloadInvoice = (sale: Sale) => {
    if (!sale || !sale.id) {
      setSnackbarMessage('Vente invalide pour le téléchargement.');
      setSnackbarOpen(true);
      return;
    }

    const client = sale.clientId ? getClientById(sale.clientId) : null;
    const clientName = client ? `${client.firstName} ${client.lastName}` : 'Client anonyme';
    const clientEmail = client?.email || '';
    const clientPhone = client?.phone || '';

    const invoiceContent = `<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Facture ${sale.id}</title><style>body{font-family:Arial,sans-serif;margin:0;padding:20px;background:#fff;color:#333}.invoice-header{text-align:center;margin-bottom:30px;border-bottom:2px solid #1976d2;padding-bottom:20px}.invoice-title{font-size:28px;font-weight:700;color:#1976d2;margin-bottom:10px}.invoice-number{font-size:16px;color:#666}.invoice-details{display:flex;justify-content:space-between;margin-bottom:30px}.workshop-info,.client-info{width:45%}.workshop-info h3,.client-info h3{margin:0 0 10px;color:#333;font-size:18px}.workshop-info p,.client-info p{margin:5px 0;color:#666;font-size:14px}.items-table{width:100%;border-collapse:collapse;margin-bottom:30px}.items-table th,.items-table td{border:1px solid #ddd;padding:12px;text-align:left}.items-table th{background:#f5f5f5;font-weight:700;color:#333}.items-table tr:nth-child(even){background:#f9f9f9}.totals{float:right;width:300px;margin-top:20px}.total-line{display:flex;justify-content:space-between;margin-bottom:10px;padding:5px 0}.total-line.final{font-weight:700;font-size:18px;border-top:2px solid #1976d2;padding-top:10px;color:#1976d2}.invoice-footer{margin-top:50px;text-align:center;color:#666;font-size:12px;border-top:1px solid #ddd;padding-top:20px}@media print{body{margin:0;padding:15px}.no-print{display:none}}</style></head><body><div class="invoice-header"><div class="invoice-title">FACTURE</div><div class="invoice-number">N&deg; ${sale.id}</div></div><div class="invoice-details"><div class="workshop-info"><h3>Atelier de R&eacute;paration</h3><p>123 Rue de la Paix</p><p>75001 Paris, France</p><p>T&eacute;l: 07 59 23 91 70</p><p>Email: contact.ateliergestion@gmail.com</p></div><div class="client-info"><h3>Factur&eacute; &agrave;</h3><p><strong>${clientName}</strong></p>${clientEmail ? `<p>Email: ${clientEmail}</p>` : ''}${clientPhone ? `<p>T&eacute;l: ${clientPhone}</p>` : ''}</div></div><table class="items-table"><thead><tr><th>Article</th><th>Quantit&eacute;</th><th>Prix unitaire</th><th>Total</th></tr></thead><tbody>${(() => {
      let items = sale.items;
      if (typeof items === 'string') { try { items = JSON.parse(items); } catch { items = []; } }
      const arr = Array.isArray(items) ? items : items && typeof items === 'object' ? Object.values(items) : [];
      return arr.length > 0 ? arr.map((i: any) => `<tr><td>${i.name || 'Article'}</td><td>${i.quantity || 1}</td><td>${formatFromEUR(i.unitPrice || 0, currency)}</td><td>${formatFromEUR(i.totalPrice || 0, currency)}</td></tr>`).join('') : '<tr><td colspan="4" style="text-align:center;color:#666">Aucun article</td></tr>';
    })()}</tbody></table><div class="totals"><div class="total-line"><span>Sous-total HT:</span><span>${formatFromEUR(sale.subtotal || 0, currency)}</span></div><div class="total-line"><span>TVA (${workshopSettings?.vatRate || 20}%):</span><span>${formatFromEUR(sale.tax || 0, currency)}</span></div>${(sale.discountPercentage || 0) > 0 ? `<div class="total-line"><span>Remise (${sale.discountPercentage}%):</span><span>-${formatFromEUR(sale.discountAmount || 0, currency)}</span></div>` : ''}<div class="total-line final"><span>TOTAL TTC:</span><span>${formatFromEUR(sale.total || 0, currency)}</span></div></div><div class="invoice-footer"><p>Date d'&eacute;mission: ${safeFormatDate(sale.createdAt, 'dd/MM/yyyy')}</p><p>M&eacute;thode de paiement: ${getPaymentMethodLabel(sale.paymentMethod)}</p><p>Merci de votre confiance !</p></div></body></html>`;

    const blob = new Blob([invoiceContent], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Facture_${sale.id}_${safeFormatDate(sale.createdAt, 'yyyy-MM-dd')}.html`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const handleTogglePaymentStatus = async (sale: Sale) => {
    try {
      const newStatus = sale.status === 'completed' ? 'pending' : 'completed';
      await updateSale(sale.id, { status: newStatus });
      setSnackbarMessage(`Statut mis à jour : ${newStatus === 'completed' ? 'Payée' : 'En attente'}`);
      setSnackbarOpen(true);
    } catch {
      setSnackbarMessage('Erreur lors de la mise à jour du statut');
      setSnackbarOpen(true);
    }
  };

  /* ─── computed KPI values ─── */
  const todayTransactions = getTotalTransactionsForDate(new Date(), 'day');
  const todayRevenue = getTotalRevenueForDate(new Date(), 'day');
  const monthTransactions = getTotalTransactionsForDate(new Date(), 'month');
  const monthRevenue = getTotalRevenueForDate(new Date(), 'month');

  const todaySalesCount = getSalesForDate(new Date(), 'day').length;
  const todayRepairsCount = getRepairsForDate(new Date(), 'day').length;
  const todaySalesRevenue = getSalesForDate(new Date(), 'day').reduce((s, sale) => s + sale.total, 0);
  const todayRepairsRevenue = getRepairsForDate(new Date(), 'day').reduce((s, r) => s + r.totalPrice, 0);
  const monthSalesCount = getSalesForDate(new Date(), 'month').length;
  const monthRepairsCount = getRepairsForDate(new Date(), 'month').length;
  const monthSalesRevenue = getSalesForDate(new Date(), 'month').reduce((s, sale) => s + sale.total, 0);
  const monthRepairsRevenue = getRepairsForDate(new Date(), 'month').reduce((s, r) => s + r.totalPrice, 0);

  return (
    <Box>
      {/* ─── header ─── */}
      <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.01em' }}>
            Ventes
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gestion des ventes et facturation
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Vente simplifiée (encaissement rapide)">
            <Button
              variant="outlined"
              startIcon={<TouchAppIcon />}
              onClick={() => setSimplifiedSaleDialogOpen(true)}
              sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: '#e5e7eb', color: '#6b7280', '&:hover': { borderColor: '#8b5cf6', color: '#8b5cf6', bgcolor: alpha('#8b5cf6', 0.04) } }}
            >
              Vente rapide
            </Button>
          </Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewSaleDialogOpen(true)} sx={BTN_DARK}>
            Nouvelle vente
          </Button>
        </Box>
      </Box>

      {/* ─── KPI ─── */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2, mb: 3 }}>
        <KpiMini icon={<TrendingUpIcon fontSize="small" />} iconColor="#6366f1" label="Transactions du jour" value={todayTransactions} subtitle="Ventes + Réparations" />
        <KpiMini icon={<MonetizationOnIcon fontSize="small" />} iconColor="#22c55e" label="CA du jour" value={formatFromEUR(todayRevenue, currency)} subtitle="Ventes + Réparations" />
        <KpiMini icon={<CalendarTodayIcon fontSize="small" />} iconColor="#f59e0b" label="Transactions du mois" value={monthTransactions} subtitle="Ventes + Réparations" />
        <KpiMini icon={<AssessmentIcon fontSize="small" />} iconColor="#8b5cf6" label="CA du mois" value={formatFromEUR(monthRevenue, currency)} subtitle="Ventes + Réparations" />
      </Box>

      {/* ─── breakdown cards ─── */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2, mb: 3 }}>
        <Card sx={CARD_STATIC}>
          <CardContent sx={{ p: '20px !important' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
              <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: `linear-gradient(135deg, #3b82f6, ${alpha('#3b82f6', 0.7)})`, color: '#fff' }}>
                <BarChartIcon sx={{ fontSize: 18 }} />
              </Box>
              <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>Répartition du jour</Typography>
            </Box>
            <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
              <Box sx={{ flex: 1, minWidth: 120 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 0.5 }}>
                  <ShoppingCartIcon sx={{ fontSize: 14, color: '#6366f1' }} />
                  <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500 }}>Ventes</Typography>
                </Box>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>{todaySalesCount} vente{todaySalesCount > 1 ? 's' : ''}</Typography>
                <Typography variant="caption" sx={{ color: '#6366f1', fontWeight: 600 }}>{formatFromEUR(todaySalesRevenue, currency)}</Typography>
              </Box>
              <Box sx={{ flex: 1, minWidth: 120 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 0.5 }}>
                  <BuildIcon sx={{ fontSize: 14, color: '#22c55e' }} />
                  <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500 }}>Réparations payées</Typography>
                </Box>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>{todayRepairsCount} réparation{todayRepairsCount > 1 ? 's' : ''}</Typography>
                <Typography variant="caption" sx={{ color: '#22c55e', fontWeight: 600 }}>{formatFromEUR(todayRepairsRevenue, currency)}</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>

        <Card sx={CARD_STATIC}>
          <CardContent sx={{ p: '20px !important' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
              <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: `linear-gradient(135deg, #f59e0b, ${alpha('#f59e0b', 0.7)})`, color: '#fff' }}>
                <PieChartIcon sx={{ fontSize: 18 }} />
              </Box>
              <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>Répartition du mois</Typography>
            </Box>
            <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
              <Box sx={{ flex: 1, minWidth: 120 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 0.5 }}>
                  <ShoppingCartIcon sx={{ fontSize: 14, color: '#6366f1' }} />
                  <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500 }}>Ventes</Typography>
                </Box>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>{monthSalesCount} vente{monthSalesCount > 1 ? 's' : ''}</Typography>
                <Typography variant="caption" sx={{ color: '#6366f1', fontWeight: 600 }}>{formatFromEUR(monthSalesRevenue, currency)}</Typography>
              </Box>
              <Box sx={{ flex: 1, minWidth: 120 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 0.5 }}>
                  <BuildIcon sx={{ fontSize: 14, color: '#22c55e' }} />
                  <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500 }}>Réparations payées</Typography>
                </Box>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>{monthRepairsCount} réparation{monthRepairsCount > 1 ? 's' : ''}</Typography>
                <Typography variant="caption" sx={{ color: '#22c55e', fontWeight: 600 }}>{formatFromEUR(monthRepairsRevenue, currency)}</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* ─── search + filters ─── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
          <TextField
            size="small"
            placeholder="Rechercher par n° vente, client, méthode..."
            value={salesSearch}
            onChange={(e) => setSalesSearch(e.target.value)}
            sx={{ ...INPUT_SX, minWidth: 300, flex: 1 }}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" sx={{ color: 'text.disabled' }} /></InputAdornment> }}
          />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {SALE_FILTERS.map((f) => (
              <Chip
                key={f.key}
                label={f.label}
                size="small"
                onClick={() => setSalesFilter(f.key)}
                sx={{
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  borderRadius: '8px',
                  ...(salesFilter === f.key
                    ? { bgcolor: f.color, color: '#fff', boxShadow: `0 2px 8px ${alpha(f.color, 0.35)}` }
                    : { bgcolor: alpha(f.color, 0.08), color: f.color, '&:hover': { bgcolor: alpha(f.color, 0.16) } }),
                }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* ─── sales table ─── */}
      <Card sx={CARD_STATIC}>
        <CardContent sx={{ p: 0 }}>
          {filteredSales.length === 0 ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 8 }}>
              <Box sx={{ width: 64, height: 64, borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: `linear-gradient(135deg, ${alpha('#6366f1', 0.12)}, ${alpha('#6366f1', 0.04)})`, mb: 2 }}>
                <EmptyIcon sx={{ fontSize: 32, color: '#6366f1' }} />
              </Box>
              <Typography variant="body1" sx={{ fontWeight: 600, mb: 0.5 }}>
                {salesSearch || salesFilter !== 'all' ? 'Aucun résultat' : 'Aucune vente'}
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2 }}>
                {salesSearch || salesFilter !== 'all' ? 'Essayez de modifier vos critères de recherche' : 'Commencez par créer votre première vente'}
              </Typography>
              {!salesSearch && salesFilter === 'all' && (
                <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewSaleDialogOpen(true)} sx={BTN_DARK} size="small">
                  Créer une vente
                </Button>
              )}
            </Box>
          ) : (
            <>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow sx={TABLE_HEAD_SX}>
                      <TableCell>N° Vente</TableCell>
                      <TableCell>Client</TableCell>
                      <TableCell>Date</TableCell>
                      <TableCell>Montant</TableCell>
                      <TableCell>Paiement</TableCell>
                      <TableCell>Statut</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filteredSales.map((sale) => {
                      const client = sale.clientId ? getClientById(sale.clientId) : null;
                      const statusColor = getStatusColor(sale.status);
                      const pmColor = PAYMENT_COLORS[sale.paymentMethod] || '#6b7280';
                      return (
                        <TableRow key={sale.id} sx={{ '&:hover': { bgcolor: alpha('#6366f1', 0.03) }, transition: 'background .2s' }}>
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <ReceiptIcon sx={{ fontSize: 16, color: '#6366f1' }} />
                              <Typography variant="body2" sx={{ fontWeight: 600, fontFamily: 'monospace', fontSize: '0.8rem' }}>
                                {sale.id.slice(0, 8)}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                              <PersonIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                              <Typography variant="body2" sx={{ fontSize: '0.8rem' }}>
                                {client ? `${client.firstName} ${client.lastName}` : 'Client anonyme'}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                              <CalendarTodayIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                              <Typography variant="body2" sx={{ fontSize: '0.8rem', color: 'text.secondary' }}>
                                {safeFormatDate(sale.createdAt, 'dd/MM/yyyy HH:mm')}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Typography variant="body2" sx={{ fontWeight: 700, fontSize: '0.85rem', color: '#111827' }}>
                              {formatFromEUR(sale.total, currency)}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Chip
                              label={getPaymentMethodLabel(sale.paymentMethod)}
                              size="small"
                              sx={{ height: 22, fontSize: '0.7rem', fontWeight: 600, bgcolor: alpha(pmColor, 0.1), color: pmColor, borderRadius: '6px' }}
                            />
                          </TableCell>
                          <TableCell>
                            <Chip
                              label={getStatusLabel(sale.status)}
                              size="small"
                              sx={{ height: 22, fontSize: '0.7rem', fontWeight: 700, bgcolor: alpha(statusColor, 0.1), color: statusColor, borderRadius: '6px' }}
                            />
                          </TableCell>
                          <TableCell align="right">
                            <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'flex-end' }}>
                              <Tooltip title="Voir facture" arrow>
                                <IconButton size="small" onClick={() => openInvoice(sale)} sx={{ bgcolor: alpha('#6366f1', 0.08), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.18) }, width: 30, height: 30 }}>
                                  <ReceiptIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Télécharger facture" arrow>
                                <IconButton size="small" onClick={() => downloadInvoice(sale)} sx={{ bgcolor: alpha('#3b82f6', 0.08), color: '#3b82f6', '&:hover': { bgcolor: alpha('#3b82f6', 0.18) }, width: 30, height: 30 }}>
                                  <DownloadIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Reçu thermique" arrow>
                                <IconButton size="small" onClick={() => handleOpenThermalReceipt(sale)} sx={{ bgcolor: alpha('#8b5cf6', 0.08), color: '#8b5cf6', '&:hover': { bgcolor: alpha('#8b5cf6', 0.18) }, width: 30, height: 30 }}>
                                  <PrintIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title={sale.status === 'completed' ? 'Marquer non payée' : 'Marquer payée'} arrow>
                                <IconButton
                                  size="small"
                                  onClick={() => handleTogglePaymentStatus(sale)}
                                  sx={{
                                    bgcolor: alpha(sale.status === 'completed' ? '#f59e0b' : '#22c55e', 0.08),
                                    color: sale.status === 'completed' ? '#f59e0b' : '#22c55e',
                                    '&:hover': { bgcolor: alpha(sale.status === 'completed' ? '#f59e0b' : '#22c55e', 0.18) },
                                    width: 30,
                                    height: 30,
                                  }}
                                >
                                  <PaymentIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Tooltip>
                            </Box>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </TableContainer>

              {/* footer */}
              <Box sx={{ px: 2, py: 1.5, borderTop: '1px solid', borderColor: 'divider', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  {filteredSales.length} vente{filteredSales.length > 1 ? 's' : ''}
                  {filteredSales.length !== sales.length && ` sur ${sales.length}`}
                </Typography>
                {(salesSearch || salesFilter !== 'all') && (
                  <Chip
                    label="Effacer les filtres"
                    size="small"
                    onClick={() => { setSalesSearch(''); setSalesFilter('all'); }}
                    sx={{ fontSize: '0.7rem', height: 22, borderRadius: '6px' }}
                  />
                )}
              </Box>
            </>
          )}
        </CardContent>
      </Card>

      {/* ─── Dialog nouvelle vente ─── */}
      <Dialog
        open={newSaleDialogOpen}
        onClose={() => setNewSaleDialogOpen(false)}
        maxWidth="xl"
        fullWidth
        PaperProps={{ sx: { borderRadius: '16px', boxShadow: '0 24px 48px rgba(0,0,0,0.16)', minHeight: '90vh' } }}
      >
        <DialogTitle sx={{ background: 'linear-gradient(135deg, #111827 0%, #1f2937 100%)', color: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'center', py: 2.5, px: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box sx={{ width: 40, height: 40, borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: 'rgba(255,255,255,0.1)' }}>
              <ShoppingCartIcon />
            </Box>
            <Box>
              <Typography variant="h6" component="span" sx={{ fontWeight: 700 }}>Nouvelle vente</Typography>
              <Typography variant="caption" sx={{ display: 'block', opacity: 0.7 }}>Sélectionnez les articles et finalisez la vente</Typography>
            </Box>
          </Box>
          <IconButton onClick={() => { setNewSaleDialogOpen(false); resetForm(); }} sx={{ color: 'white', '&:hover': { bgcolor: 'rgba(255,255,255,0.1)' } }}>
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent sx={{ p: 3, bgcolor: '#f8f9fa' }}>
          <Grid container spacing={3} sx={{ mt: 0 }}>
            {/* Client + payment */}
            <Grid item xs={12}>
              <Paper elevation={0} sx={{ p: 3, borderRadius: '14px', bgcolor: 'white', border: '1px solid rgba(0,0,0,0.06)' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2.5 }}>
                  <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: `linear-gradient(135deg, #6366f1, ${alpha('#6366f1', 0.7)})`, color: '#fff' }}>
                    <PersonIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>Informations client</Typography>
                </Box>
                <Grid container spacing={2}>
                  <Grid item xs={12} md={6}>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <Autocomplete
                        fullWidth
                        options={[{ id: '', firstName: 'Client', lastName: 'anonyme', email: '', phone: '' } as any, ...clients]}
                        value={selectedClientId ? clients.find((c) => c.id === selectedClientId) || null : null}
                        onChange={(_, v) => setSelectedClientId(v?.id || '')}
                        getOptionLabel={(o) => (o.id === '' ? 'Client anonyme' : `${o.firstName} ${o.lastName}${o.email ? ` - ${o.email}` : ''}${o.phone ? ` - ${o.phone}` : ''}`)}
                        filterOptions={(options, { inputValue }) => {
                          if (!inputValue) return options;
                          const q = inputValue.toLowerCase();
                          return options.filter((o) => {
                            if (o.id === '') return 'client anonyme'.includes(q);
                            return [o.firstName, o.lastName, o.email, o.phone].some((f) => (f || '').toLowerCase().includes(q));
                          });
                        }}
                        renderInput={(params) => <TextField {...params} label="Client" placeholder="Rechercher par nom, email ou téléphone..." sx={INPUT_SX} />}
                        isOptionEqualToValue={(o, v) => o.id === v.id}
                      />
                      <Tooltip title="Créer un nouveau client">
                        <IconButton onClick={() => setClientFormOpen(true)} sx={{ bgcolor: '#111827', color: 'white', '&:hover': { bgcolor: '#1f2937' }, borderRadius: '10px', width: 42, height: 42 }}>
                          <AddIcon />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <FormControl fullWidth>
                      <InputLabel>Méthode de paiement</InputLabel>
                      <Select value={paymentMethod} onChange={(e) => setPaymentMethod(e.target.value as any)} label="Méthode de paiement" sx={{ borderRadius: '10px' }}>
                        <MenuItem value="cash">Espèces</MenuItem>
                        <MenuItem value="card">Carte</MenuItem>
                        <MenuItem value="transfer">Virement</MenuItem>
                        <MenuItem value="check">Chèque</MenuItem>
                        <MenuItem value="payment_link">Lien paiement</MenuItem>
                      </Select>
                    </FormControl>
                  </Grid>
                </Grid>
              </Paper>
            </Grid>

            {/* Articles selection */}
            <Grid item xs={12} md={6}>
              <Paper elevation={0} sx={{ p: 3, borderRadius: '14px', bgcolor: 'white', border: '1px solid rgba(0,0,0,0.06)', height: '100%' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2.5 }}>
                  <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: `linear-gradient(135deg, #3b82f6, ${alpha('#3b82f6', 0.7)})`, color: '#fff' }}>
                    <InventoryIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>Sélection d'articles</Typography>
                  <Chip label={filteredItems.length} size="small" sx={{ ml: 'auto', bgcolor: alpha('#3b82f6', 0.1), color: '#3b82f6', fontWeight: 700, fontSize: '0.75rem' }} />
                </Box>

                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Type d'article</InputLabel>
                  <Select
                    value={selectedItemType}
                    onChange={(e) => { setSelectedItemType(e.target.value as any); setSelectedCategory('all'); setSearchQuery(''); }}
                    label="Type d'article"
                    sx={{ borderRadius: '10px' }}
                  >
                    <MenuItem value="product">
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        Produits & Accessoires
                        <Chip label={products.filter((p) => p.isActive).length} size="small" sx={{ height: 20, fontSize: '0.7rem', fontWeight: 600, bgcolor: alpha('#6366f1', 0.1), color: '#6366f1' }} />
                      </Box>
                    </MenuItem>
                    <MenuItem value="service">
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        Services de Réparation
                        <Chip label={services.filter((s) => s.isActive).length} size="small" sx={{ height: 20, fontSize: '0.7rem', fontWeight: 600, bgcolor: alpha('#22c55e', 0.1), color: '#22c55e' }} />
                      </Box>
                    </MenuItem>
                    <MenuItem value="part">
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        Pièces Détachées
                        <Chip label={parts.filter((p) => p.isActive && p.stockQuantity > 0).length} size="small" sx={{ height: 20, fontSize: '0.7rem', fontWeight: 600, bgcolor: alpha('#f59e0b', 0.1), color: '#f59e0b' }} />
                      </Box>
                    </MenuItem>
                  </Select>
                </FormControl>

                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Catégorie</InputLabel>
                  <Select value={selectedCategory} onChange={(e) => setSelectedCategory(e.target.value)} label="Catégorie" sx={{ borderRadius: '10px' }}>
                    {availableCategories.map((cat) => (
                      <MenuItem key={cat} value={cat}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
                          <span>{cat === 'all' ? 'Toutes les catégories' : cat}</span>
                          <Chip label={getCategoryCount(cat)} size="small" sx={{ height: 18, fontSize: '0.65rem', fontWeight: 600, bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }} />
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <TextField
                  fullWidth
                  size="small"
                  placeholder={`Rechercher un ${selectedItemType === 'product' ? 'produit' : selectedItemType === 'service' ? 'service' : 'pièce'}...`}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  sx={{ ...INPUT_SX, mb: 2 }}
                  InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" sx={{ color: 'text.disabled' }} /></InputAdornment> }}
                />

                <Typography variant="caption" sx={{ color: 'text.secondary', mb: 1, display: 'block' }}>
                  {filteredItems.length} article{filteredItems.length > 1 ? 's' : ''} disponible{filteredItems.length > 1 ? 's' : ''}
                  {selectedItemType === 'part' && ' (en stock uniquement)'}
                </Typography>

                <Box sx={{ maxHeight: 400, overflow: 'auto', border: '1px solid rgba(0,0,0,0.06)', borderRadius: '12px' }}>
                  <List dense>
                    {filteredItems.map((item) => {
                      const details = getItemDetails(item);
                      return (
                        <ListItem
                          key={item.id}
                          button
                          onClick={() => addItemToSale(item)}
                          sx={{ cursor: 'pointer', transition: 'all 0.2s', '&:hover': { bgcolor: alpha('#3b82f6', 0.06) }, borderBottom: '1px solid rgba(0,0,0,0.04)' }}
                        >
                          <ListItemText
                            primary={
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                                <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>{item.name}</Typography>
                                {selectedItemType === 'part' && <Chip label="En stock" size="small" sx={{ height: 18, fontSize: '0.6rem', fontWeight: 600, bgcolor: alpha('#22c55e', 0.1), color: '#22c55e' }} />}
                              </Box>
                            }
                            secondary={
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.3 }}>
                                {details.description && (
                                  <Tooltip title={details.description}><InfoIcon sx={{ fontSize: 13, color: 'text.disabled' }} /></Tooltip>
                                )}
                                {item.category && item.category !== 'all' && (
                                  <Chip label={item.category} size="small" sx={{ height: 16, fontSize: '0.6rem', bgcolor: alpha('#6b7280', 0.08), color: '#6b7280' }} />
                                )}
                                <Typography variant="caption" sx={{ color: 'text.secondary', fontSize: '0.7rem' }}>
                                  {formatFromEUR(item.price, currency)} HT / {formatFromEUR(item.price * (1 + parseFloat(workshopSettings?.vatRate || '20') / 100), currency)} TTC
                                </Typography>
                                {selectedItemType === 'part' && 'stock' in details && <Typography variant="caption" sx={{ color: 'text.disabled' }}>Stock: {details.stock}</Typography>}
                              </Box>
                            }
                          />
                          <IconButton size="small" onClick={(e) => { e.stopPropagation(); addItemToSale(item); }} sx={{ color: '#3b82f6', '&:hover': { bgcolor: alpha('#3b82f6', 0.12) } }}>
                            <AddIcon fontSize="small" />
                          </IconButton>
                        </ListItem>
                      );
                    })}
                    {filteredItems.length === 0 && (
                      <Box sx={{ textAlign: 'center', py: 4 }}>
                        <Typography variant="body2" sx={{ color: 'text.disabled' }}>Aucun article trouvé</Typography>
                        <Typography variant="caption" sx={{ color: 'text.disabled' }}>Modifiez votre recherche ou catégorie</Typography>
                      </Box>
                    )}
                  </List>
                </Box>
              </Paper>
            </Grid>

            {/* Cart */}
            <Grid item xs={12} md={6}>
              <Paper elevation={0} sx={{ p: 3, borderRadius: '14px', bgcolor: 'white', border: '1px solid rgba(0,0,0,0.06)', height: '100%' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2.5 }}>
                  <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: `linear-gradient(135deg, #22c55e, ${alpha('#22c55e', 0.7)})`, color: '#fff' }}>
                    <ShoppingCartIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>Panier</Typography>
                  {saleItems.length > 0 && <Chip label={saleItems.length} size="small" sx={{ ml: 'auto', bgcolor: alpha('#22c55e', 0.1), color: '#22c55e', fontWeight: 700, fontSize: '0.75rem' }} />}
                </Box>

                <Box sx={{ maxHeight: 400, overflow: 'auto', border: '1px solid rgba(0,0,0,0.06)', borderRadius: '12px', p: saleItems.length > 0 ? 1.5 : 0 }}>
                  {saleItems.length === 0 ? (
                    <Box sx={{ textAlign: 'center', py: 5 }}>
                      <Box sx={{ width: 48, height: 48, borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: alpha('#6b7280', 0.06), mx: 'auto', mb: 1.5 }}>
                        <ShoppingCartIcon sx={{ fontSize: 24, color: 'text.disabled' }} />
                      </Box>
                      <Typography variant="body2" sx={{ color: 'text.disabled', fontWeight: 500 }}>Votre panier est vide</Typography>
                      <Typography variant="caption" sx={{ color: 'text.disabled' }}>Sélectionnez des articles à gauche</Typography>
                    </Box>
                  ) : (
                    <List dense>
                      {saleItems.map((item, index) => {
                        const typeColor = item.type === 'product' ? '#6366f1' : item.type === 'service' ? '#8b5cf6' : '#22c55e';
                        return (
                          <ListItem key={item.itemId} sx={{ borderBottom: index < saleItems.length - 1 ? '1px solid rgba(0,0,0,0.04)' : 'none', py: 1 }}>
                            <ListItemText
                              primary={
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>{item.name}</Typography>
                                  <Chip
                                    label={item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'}
                                    size="small"
                                    sx={{ height: 18, fontSize: '0.6rem', fontWeight: 700, bgcolor: alpha(typeColor, 0.1), color: typeColor }}
                                  />
                                </Box>
                              }
                              secondary={
                                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                                  {formatFromEUR(item.unitPrice, currency)} x {item.quantity}
                                </Typography>
                              }
                            />
                            <ListItemSecondaryAction>
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                                <TextField
                                  type="number"
                                  size="small"
                                  value={item.quantity}
                                  onChange={(e) => updateItemQuantity(item.itemId, parseInt(e.target.value) || 0)}
                                  sx={{ width: 60, '& .MuiOutlinedInput-root': { borderRadius: '8px' } }}
                                  inputProps={{ min: 1, style: { textAlign: 'center', fontSize: '0.8rem', padding: '4px' } }}
                                />
                                <Typography variant="body2" sx={{ fontWeight: 700, minWidth: 70, textAlign: 'right', fontSize: '0.8rem' }}>
                                  {formatFromEUR(item.totalPrice, currency)}
                                </Typography>
                                <IconButton size="small" onClick={() => removeItemFromSale(item.itemId)} sx={{ color: '#ef4444', '&:hover': { bgcolor: alpha('#ef4444', 0.08) }, width: 28, height: 28 }}>
                                  <DeleteIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Box>
                            </ListItemSecondaryAction>
                          </ListItem>
                        );
                      })}
                    </List>
                  )}
                </Box>

                {/* Discount */}
                {saleItems.length > 0 && (
                  <Box sx={{ mt: 2, p: 2, bgcolor: alpha('#f59e0b', 0.04), borderRadius: '12px', border: `1px solid ${alpha('#f59e0b', 0.15)}` }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 1.5 }}>
                      <DiscountIcon sx={{ fontSize: 18, color: '#f59e0b' }} />
                      <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: '0.8rem' }}>Réduction</Typography>
                    </Box>
                    <TextField
                      fullWidth
                      type="number"
                      label="Réduction (%)"
                      value={discountPercentage}
                      onChange={(e) => setDiscountPercentage(Math.max(0, Math.min(100, parseFloat(e.target.value) || 0)))}
                      inputProps={{ min: 0, max: 100, step: 0.1 }}
                      size="small"
                      sx={INPUT_SX}
                    />
                    {discountPercentage > 0 && (
                      <Typography variant="caption" sx={{ color: '#22c55e', fontWeight: 600, mt: 1, display: 'block' }}>
                        Réduction de {discountPercentage}% = -{formatFromEUR(totals.discountAmount, currency)}
                      </Typography>
                    )}
                  </Box>
                )}

                {/* Totals */}
                {saleItems.length > 0 && (
                  <Box sx={{ mt: 2, p: 2, borderRadius: '12px', border: '1px solid rgba(0,0,0,0.06)', background: 'linear-gradient(135deg, #fafafa 0%, #f5f5f5 100%)' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mb: 1.5 }}>
                      <AssessmentIcon sx={{ fontSize: 18, color: '#6366f1' }} />
                      <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: '0.8rem' }}>Récapitulatif</Typography>
                    </Box>

                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2" sx={{ color: 'text.secondary', fontSize: '0.8rem' }}>Prix HT :</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>{formatFromEUR(totals.subtotal, currency)}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2" sx={{ color: 'text.secondary', fontSize: '0.8rem' }}>TVA ({totals.vatRate}%) :</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>{formatFromEUR(totals.tax, currency)}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2" sx={{ color: 'text.secondary', fontSize: '0.8rem' }}>Total TTC :</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>{formatFromEUR(totals.totalBeforeDiscount, currency)}</Typography>
                    </Box>
                    {discountPercentage > 0 && (
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                        <Typography variant="body2" sx={{ color: '#22c55e', fontSize: '0.8rem' }}>Réduction ({discountPercentage}%) :</Typography>
                        <Typography variant="body2" sx={{ fontWeight: 600, color: '#22c55e', fontSize: '0.8rem' }}>-{formatFromEUR(totals.discountAmount, currency)}</Typography>
                      </Box>
                    )}

                    <Divider sx={{ my: 1.5 }} />

                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', p: 1.5, bgcolor: '#111827', borderRadius: '10px', color: '#fff' }}>
                      <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>TOTAL</Typography>
                      <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>{formatFromEUR(totals.total, currency)}</Typography>
                    </Box>
                  </Box>
                )}
              </Paper>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 3, bgcolor: '#f8f9fa', borderTop: '1px solid rgba(0,0,0,0.06)', gap: 1.5 }}>
          <Button onClick={() => { setNewSaleDialogOpen(false); resetForm(); }} variant="outlined" sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: '#e5e7eb', color: '#6b7280', minWidth: 120 }}>
            Annuler
          </Button>
          <Button
            variant="contained"
            onClick={createSale}
            disabled={saleItems.length === 0}
            startIcon={<ReceiptIcon />}
            sx={{
              borderRadius: '10px',
              textTransform: 'none',
              fontWeight: 700,
              minWidth: 220,
              py: 1.2,
              bgcolor: '#22c55e',
              '&:hover': { bgcolor: '#16a34a' },
              boxShadow: `0 4px 14px ${alpha('#22c55e', 0.35)}`,
              '&:disabled': { bgcolor: '#e5e7eb', color: '#9ca3af' },
            }}
          >
            Créer la vente ({formatFromEUR(totals.subtotal, currency)} HT / {formatFromEUR(totals.total, currency)} TTC)
          </Button>
        </DialogActions>
      </Dialog>

      {/* ─── Invoice ─── */}
      {selectedSaleForInvoice && (
        <Invoice sale={selectedSaleForInvoice} client={selectedSaleForInvoice.clientId ? getClientById(selectedSaleForInvoice.clientId) : undefined} open={invoiceOpen} onClose={closeInvoice} />
      )}

      {/* ─── Simplified sale ─── */}
      <SimplifiedSalesDialog open={simplifiedSaleDialogOpen} onClose={() => setSimplifiedSaleDialogOpen(false)} />

      {/* ─── Thermal receipt ─── */}
      {thermalReceiptSale && (
        <ThermalReceiptDialog
          open={thermalReceiptDialogOpen}
          onClose={() => { setThermalReceiptDialogOpen(false); setThermalReceiptSale(null); }}
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

      {/* ─── Client form ─── */}
      <ClientForm open={clientFormOpen} onClose={() => setClientFormOpen(false)} onSubmit={handleCreateNewClient} existingEmails={clients.map((c) => c.email?.toLowerCase() || '')} />

      {/* ─── Snackbar ─── */}
      <Snackbar open={snackbarOpen} autoHideDuration={4000} onClose={() => setSnackbarOpen(false)} message={snackbarMessage} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
};

export default Sales;

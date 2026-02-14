import React, { useState, useMemo, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  TextField,
  InputAdornment,
  Tooltip,
  Chip,
  Snackbar,
} from '@mui/material';
import { alpha } from '@mui/material/styles';
import {
  Add as AddIcon,
  Description as DescriptionIcon,
  Print as PrintIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  MonetizationOn as MonetizationOnIcon,
  CalendarToday as CalendarTodayIcon,
  Assessment as AssessmentIcon,
  Visibility as VisibilityIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
  Download as DownloadIcon,
  Send as SendIcon,
  Person as PersonIcon,
  SentimentDissatisfied as EmptyIcon,
  EditNote as DraftIcon,
} from '@mui/icons-material';
import { format, addDays } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Quote, QuoteItem } from '../../types';
import { generateQuoteNumber, formatQuoteNumber } from '../../utils/quoteUtils';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import QuoteForm from './QuoteForm';
import QuoteView from './QuoteView';
import RepairForm, { RepairFormData } from './RepairForm';

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
function KpiMini({ icon, iconColor, label, value }: { icon: React.ReactNode; iconColor: string; label: string; value: string | number }) {
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
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── filter types ─── */
type QuoteFilter = 'all' | 'draft' | 'sent' | 'accepted' | 'rejected' | 'expired';
const QUOTE_FILTERS: { key: QuoteFilter; label: string; color: string }[] = [
  { key: 'all', label: 'Tous', color: '#6366f1' },
  { key: 'draft', label: 'Brouillons', color: '#6b7280' },
  { key: 'sent', label: 'Envoyés', color: '#3b82f6' },
  { key: 'accepted', label: 'Acceptés', color: '#22c55e' },
  { key: 'rejected', label: 'Refusés', color: '#ef4444' },
  { key: 'expired', label: 'Expirés', color: '#f59e0b' },
];

const STATUS_COLORS: Record<string, string> = {
  draft: '#6b7280',
  sent: '#3b82f6',
  accepted: '#22c55e',
  rejected: '#ef4444',
  expired: '#f59e0b',
};

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
    loadQuotes,
    getClientById,
    getDeviceById,
    systemSettings,
    loadSystemSettings,
  } = useAppStore();

  const { workshopSettings } = useWorkshopSettings();

  const getSettingValue = (key: string, defaultValue: string = '') => {
    const setting = systemSettings.find((s) => s.key === key);
    return setting ? setting.value : defaultValue;
  };

  const invoiceQuoteConditions = getSettingValue('invoice_quote_conditions', '');
  const vatExempt = getSettingValue('vat_exempt', 'false') === 'true';
  const currency = workshopSettings?.currency || 'EUR';

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

  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');

  /* ─── list search/filter ─── */
  const [listSearch, setListSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<QuoteFilter>('all');

  useEffect(() => {
    loadSystemSettings();
  }, [loadSystemSettings]);

  useEffect(() => {
    loadQuotes();
  }, [loadQuotes]);

  /* ─── totals for form ─── */
  const totals = useMemo(() => {
    const subtotal = quoteItems.reduce((sum, item) => sum + item.totalPrice, 0);
    const tax = vatExempt ? 0 : subtotal * (parseFloat(workshopSettings.vatRate) / 100);
    const total = subtotal + tax;
    return { subtotal, tax, total };
  }, [quoteItems, workshopSettings.vatRate, vatExempt]);

  /* ─── dialog filtered items ─── */
  const filteredItems = useMemo(() => {
    let items: Array<{ id: string; name: string; price: number; type: string; category?: string; description?: string }> = [];

    switch (selectedItemType) {
      case 'product':
        items = products.filter((p) => p.isActive && p.id).map((p) => ({ id: p.id, name: p.name, price: p.price, type: 'product', category: p.category, description: p.description }));
        break;
      case 'service':
        items = services.filter((s) => s.isActive && s.id).map((s) => ({ id: s.id, name: s.name, price: s.price, type: 'service', category: s.category, description: s.description }));
        break;
      case 'part':
        items = parts.filter((p) => p.isActive && p.stockQuantity > 0 && p.id).map((p) => ({ id: p.id, name: p.name, price: p.price, type: 'part', category: p.brand, description: p.description }));
        break;
      case 'repair':
        items = [];
        break;
    }

    if (selectedCategory !== 'all') items = items.filter((i) => i.category === selectedCategory);
    if (searchQuery) items = items.filter((i) => i.name.toLowerCase().includes(searchQuery.toLowerCase()));
    return items;
  }, [selectedItemType, selectedCategory, searchQuery, products, services, parts]);

  const availableCategories = useMemo(() => {
    let categories: string[] = [];
    switch (selectedItemType) {
      case 'product':
        categories = Array.from(new Set(products.filter((p) => p.isActive).map((p) => p.category)));
        break;
      case 'service':
        categories = Array.from(new Set(services.filter((s) => s.isActive).map((s) => s.category)));
        break;
      case 'part':
        categories = Array.from(new Set(parts.filter((p) => p.isActive && p.stockQuantity > 0).map((p) => p.brand)));
        break;
      case 'repair':
        categories = [];
        break;
    }
    return ['all', ...categories];
  }, [selectedItemType, products, services, parts]);

  /* ─── helpers ─── */
  const getStatusLabel = (status: string) => {
    const labels: Record<string, string> = { draft: 'Brouillon', sent: 'Envoyé', accepted: 'Accepté', rejected: 'Refusé', expired: 'Expiré' };
    return labels[status] || status;
  };

  const addItemToQuote = (item: { id: string; name: string; price: number; type: string; description?: string }) => {
    const existing = quoteItems.find((qi) => qi.itemId === item.id);
    if (existing) {
      setQuoteItems((prev) => prev.map((qi) => (qi.itemId === item.id ? { ...qi, quantity: qi.quantity + 1, totalPrice: (qi.quantity + 1) * qi.unitPrice } : qi)));
    } else {
      setQuoteItems((prev) => [...prev, { type: item.type as any, itemId: item.id, name: item.name, description: item.description, quantity: 1, unitPrice: item.price, totalPrice: item.price }]);
    }
  };

  const removeItemFromQuote = (itemId: string) => setQuoteItems((prev) => prev.filter((i) => i.itemId !== itemId));

  const updateItemQuantity = (itemId: string, quantity: number) => {
    if (quantity <= 0) return removeItemFromQuote(itemId);
    setQuoteItems((prev) => prev.map((i) => (i.itemId === itemId ? { ...i, quantity, totalPrice: quantity * i.unitPrice } : i)));
  };

  const createQuote = async () => {
    if (quoteItems.length === 0) {
      setSnackbarMessage('Veuillez ajouter au moins un article au devis.');
      setSnackbarOpen(true);
      return;
    }

    const quoteItemsFormatted: QuoteItem[] = quoteItems.map((item) => ({
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
      id: `quote_${Date.now()}`,
      quoteNumber: generateQuoteNumber(),
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

    await addQuote(newQuote);
    setSelectedClientId('');
    setQuoteItems([]);
    setValidUntil(addDays(new Date(), 30));
    setNotes('');
    setTerms('');
    setNewQuoteDialogOpen(false);
    setSnackbarMessage('Devis créé avec succès !');
    setSnackbarOpen(true);
  };

  const handleDeleteQuote = async (quoteId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce devis ?')) {
      await deleteQuote(quoteId);
      setSnackbarMessage('Devis supprimé.');
      setSnackbarOpen(true);
    }
  };

  const updateQuoteStatus = async (quoteId: string, newStatus: Quote['status']) => {
    await updateQuote(quoteId, { status: newStatus });
  };

  const openQuoteView = (quote: Quote) => {
    setSelectedQuoteForView(quote);
    setQuoteViewOpen(true);
  };

  /* ─── html helpers ─── */
  const escapeHtml = (input: string) => input.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  const sanitizeString = (value?: string, fallback = '') => { const t = (value ?? '').trim(); return escapeHtml(t.length > 0 ? t : fallback); };
  const formatAddressForHtml = (address: string) => address ? address.split(/\r?\n/).map((l) => l.trim()).filter(Boolean).join('<br>') : '';
  const normalizeQuoteItems = (items: any): any[] => {
    if (!items) return [];
    if (Array.isArray(items)) return items;
    if (typeof items === 'string') { try { const p = JSON.parse(items); return Array.isArray(p) ? p : []; } catch { return []; } }
    return [];
  };

  const buildQuoteHtml = (quote: Quote) => {
    const client = quote.clientId ? getClientById(quote.clientId) : null;
    const clientName = client ? `${client.firstName} ${client.lastName}` : 'Client anonyme';
    const clientEmail = client?.email || '';
    const clientPhone = client?.phone || '';
    const wName = sanitizeString(workshopSettings?.name, 'Atelier de Réparation');
    const wAddress = formatAddressForHtml(sanitizeString(workshopSettings?.address, '123 Rue de la Paix\n75001 Paris, France'));
    const wPhone = sanitizeString(workshopSettings?.phone, '07 59 23 91 70');
    const wEmail = sanitizeString(workshopSettings?.email, 'contact.ateliergestion@gmail.com');
    const normalizedItems = normalizeQuoteItems(quote.items);
    const itemsHtml = normalizedItems.length > 0 ? normalizedItems.map((i: any) => `<tr><td>${sanitizeString(i.name, 'Article')}</td><td>${sanitizeString(i.description, '-')}</td><td>${i.quantity || 1}</td><td>${formatFromEUR(i.unitPrice || 0, currency)}</td><td>${formatFromEUR(i.totalPrice || 0, currency)}</td></tr>`).join('') : '<tr><td colspan="5" style="text-align:center;color:#666">Aucun article</td></tr>';

    return `<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><title>Devis ${quote.quoteNumber}</title><style>body{font-family:Arial,sans-serif;margin:0;padding:20px;background:#fff;color:#333;line-height:1.6}.quote-header{text-align:center;margin-bottom:30px;border-bottom:2px solid #6366f1;padding-bottom:20px}.quote-title{font-size:28px;font-weight:700;color:#6366f1;margin-bottom:10px}.quote-number{font-size:16px;color:#666}.quote-details{display:flex;justify-content:space-between;margin-bottom:30px}.workshop-info,.client-info{width:45%}.workshop-info h3,.client-info h3{margin:0 0 10px;color:#333;font-size:18px}.workshop-info p,.client-info p{margin:5px 0;color:#666;font-size:14px}.items-table{width:100%;border-collapse:collapse;margin-bottom:30px}.items-table th,.items-table td{border:1px solid #ddd;padding:12px;text-align:left}.items-table th{background:#f5f5f5;font-weight:700;color:#333}.items-table tr:nth-child(even){background:#f9f9f9}.totals{float:right;width:300px;margin-top:20px}.total-line{display:flex;justify-content:space-between;margin-bottom:10px;padding:5px 0}.total-line.final{font-weight:700;font-size:18px;border-top:2px solid #6366f1;padding-top:10px;color:#6366f1}.validity-info{background:#eef2ff;border:1px solid #6366f1;border-radius:8px;padding:15px;margin:20px 0;text-align:center}.notes-section{margin-top:30px;padding:15px;background:#f9f9f9;border-radius:8px}.quote-footer{margin-top:50px;text-align:center;color:#666;font-size:12px;border-top:1px solid #ddd;padding-top:20px}@media print{body{margin:0;padding:15px;font-size:12px}.no-print{display:none}}</style></head><body><div class="quote-header"><div class="quote-title">DEVIS</div><div class="quote-number">N&deg; ${formatQuoteNumber(quote.quoteNumber)}</div></div><div class="quote-details"><div class="workshop-info"><h3>${wName}</h3><p>${wAddress}</p><p>T&eacute;l: ${wPhone}</p><p>Email: ${wEmail}</p></div><div class="client-info"><h3>Devis pour</h3><p><strong>${clientName}</strong></p>${clientEmail ? `<p>Email: ${clientEmail}</p>` : ''}${clientPhone ? `<p>T&eacute;l: ${clientPhone}</p>` : ''}</div></div><div class="validity-info"><strong>Validit&eacute; du devis :</strong> ${format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}</div><table class="items-table"><thead><tr><th>Article</th><th>Description</th><th>Quantit&eacute;</th><th>Prix unitaire</th><th>Total</th></tr></thead><tbody>${itemsHtml}</tbody></table><div class="totals"><div class="total-line"><span>Sous-total HT:</span><span>${formatFromEUR(quote.subtotal || 0, currency)}</span></div>${vatExempt ? '<div class="total-line"><span>Exon&eacute;r&eacute; de TVA</span><span>-</span></div>' : `<div class="total-line"><span>TVA (${workshopSettings.vatRate || 20}%):</span><span>${formatFromEUR(quote.tax || 0, currency)}</span></div>`}<div class="total-line final"><span>TOTAL TTC:</span><span>${formatFromEUR(quote.total || 0, currency)}</span></div></div>${quote.notes ? `<div class="notes-section"><h4>Notes :</h4><p>${quote.notes}</p></div>` : ''}${invoiceQuoteConditions ? `<div class="notes-section"><h4>Conditions :</h4><p style="white-space:pre-line">${invoiceQuoteConditions}</p></div>` : quote.terms ? `<div class="notes-section"><h4>Conditions :</h4><p>${quote.terms}</p></div>` : ''}<div class="quote-footer"><p>Date d'&eacute;mission: ${format(new Date(quote.createdAt), 'dd/MM/yyyy', { locale: fr })}</p><p>Statut: ${getStatusLabel(quote.status)}</p><p>Merci de votre confiance !</p></div></body></html>`;
  };

  const downloadQuote = (quote: Quote) => {
    if (!quote?.id) { setSnackbarMessage('Devis invalide.'); setSnackbarOpen(true); return; }
    const blob = new Blob([buildQuoteHtml(quote)], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Devis_${formatQuoteNumber(quote.quoteNumber)}_${format(new Date(quote.createdAt), 'yyyy-MM-dd')}.html`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const printQuote = (quote: Quote) => {
    if (!quote?.id) { setSnackbarMessage('Devis invalide.'); setSnackbarOpen(true); return; }
    const w = window.open('', '_blank');
    if (!w) return;
    w.document.write(buildQuoteHtml(quote));
    w.document.close();
    w.onload = () => setTimeout(() => w.print(), 500);
  };

  const handleCreateRepair = (repairData: RepairFormData) => {
    const device = repairData.deviceId ? getDeviceById(repairData.deviceId) : null;
    setQuoteItems((prev) => [
      ...prev,
      {
        type: 'repair' as const,
        itemId: `repair_${Date.now()}`,
        name: `Réparation ${device ? `${device.brand} ${device.model}` : 'Appareil'}`,
        description: repairData.description,
        quantity: 1,
        unitPrice: repairData.estimatedPrice,
        totalPrice: repairData.estimatedPrice,
      },
    ]);
    if (!selectedClientId) setSelectedClientId(repairData.clientId);
  };

  /* ─── filtered quotes list ─── */
  const filteredQuotes = useMemo(() => {
    let list = [...quotes].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    if (statusFilter !== 'all') list = list.filter((q) => q.status === statusFilter);

    if (listSearch.trim()) {
      const q = listSearch.toLowerCase();
      list = list.filter((quote) => {
        const client = getClientById(quote.clientId || '');
        const clientName = client ? `${client.firstName} ${client.lastName}`.toLowerCase() : 'client anonyme';
        return clientName.includes(q) || quote.quoteNumber.toLowerCase().includes(q) || getStatusLabel(quote.status).toLowerCase().includes(q);
      });
    }

    return list;
  }, [quotes, statusFilter, listSearch, getClientById]);

  /* ─── KPI values ─── */
  const totalQuotes = quotes.length;
  const sentCount = quotes.filter((q) => q.status === 'sent').length;
  const acceptedCount = quotes.filter((q) => q.status === 'accepted').length;
  const acceptedRevenue = quotes.filter((q) => q.status === 'accepted').reduce((sum, q) => sum + q.total, 0);

  return (
    <Box>
      {/* ─── header ─── */}
      <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.01em' }}>
            Devis
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gestion des devis et estimations
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewQuoteDialogOpen(true)} sx={BTN_DARK}>
          Nouveau devis
        </Button>
      </Box>

      {/* ─── KPI ─── */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2, mb: 3 }}>
        <KpiMini icon={<DescriptionIcon fontSize="small" />} iconColor="#6366f1" label="Total devis" value={totalQuotes} />
        <KpiMini icon={<SendIcon fontSize="small" />} iconColor="#3b82f6" label="Envoyés" value={sentCount} />
        <KpiMini icon={<CheckCircleIcon fontSize="small" />} iconColor="#22c55e" label="Acceptés" value={acceptedCount} />
        <KpiMini icon={<MonetizationOnIcon fontSize="small" />} iconColor="#8b5cf6" label="CA potentiel" value={formatFromEUR(acceptedRevenue, currency)} />
      </Box>

      {/* ─── search + filters ─── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
          <TextField
            size="small"
            placeholder="Rechercher par n° devis, client, statut..."
            value={listSearch}
            onChange={(e) => setListSearch(e.target.value)}
            sx={{ ...INPUT_SX, minWidth: 300, flex: 1 }}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" sx={{ color: 'text.disabled' }} /></InputAdornment> }}
          />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {QUOTE_FILTERS.map((f) => (
              <Chip
                key={f.key}
                label={f.label}
                size="small"
                onClick={() => setStatusFilter(f.key)}
                sx={{
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  borderRadius: '8px',
                  ...(statusFilter === f.key
                    ? { bgcolor: f.color, color: '#fff', boxShadow: `0 2px 8px ${alpha(f.color, 0.35)}` }
                    : { bgcolor: alpha(f.color, 0.08), color: f.color, '&:hover': { bgcolor: alpha(f.color, 0.16) } }),
                }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* ─── table ─── */}
      <Card sx={CARD_STATIC}>
        <CardContent sx={{ p: 0 }}>
          {filteredQuotes.length === 0 ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 8 }}>
              <Box sx={{ width: 64, height: 64, borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: `linear-gradient(135deg, ${alpha('#6366f1', 0.12)}, ${alpha('#6366f1', 0.04)})`, mb: 2 }}>
                <EmptyIcon sx={{ fontSize: 32, color: '#6366f1' }} />
              </Box>
              <Typography variant="body1" sx={{ fontWeight: 600, mb: 0.5 }}>
                {listSearch || statusFilter !== 'all' ? 'Aucun résultat' : 'Aucun devis'}
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2 }}>
                {listSearch || statusFilter !== 'all' ? 'Essayez de modifier vos critères de recherche' : 'Commencez par créer votre premier devis'}
              </Typography>
              {!listSearch && statusFilter === 'all' && (
                <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewQuoteDialogOpen(true)} sx={BTN_DARK} size="small">
                  Créer un devis
                </Button>
              )}
            </Box>
          ) : (
            <>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow sx={TABLE_HEAD_SX}>
                      <TableCell>N° Devis</TableCell>
                      <TableCell>Client</TableCell>
                      <TableCell>Date</TableCell>
                      <TableCell>Montant</TableCell>
                      <TableCell>Validité</TableCell>
                      <TableCell>Statut</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filteredQuotes.map((quote) => {
                      const client = getClientById(quote.clientId || '');
                      const isExpired = new Date(quote.validUntil) < new Date();
                      const statusColor = STATUS_COLORS[quote.status] || '#6b7280';

                      return (
                        <TableRow key={quote.id} sx={{ '&:hover': { bgcolor: alpha('#6366f1', 0.03) }, transition: 'background .2s' }}>
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <DescriptionIcon sx={{ fontSize: 16, color: '#6366f1' }} />
                              <Typography variant="body2" sx={{ fontWeight: 600, fontFamily: 'monospace', fontSize: '0.8rem' }}>
                                {formatQuoteNumber(quote.quoteNumber)}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Box>
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                                <PersonIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                                <Typography variant="body2" sx={{ fontSize: '0.8rem', fontWeight: 500 }}>
                                  {client ? `${client.firstName} ${client.lastName}` : 'Client anonyme'}
                                </Typography>
                              </Box>
                              {client?.email && (
                                <Typography variant="caption" sx={{ color: 'text.secondary', fontSize: '0.7rem', ml: 2.75 }}>
                                  {client.email}
                                </Typography>
                              )}
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                              <CalendarTodayIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                              <Typography variant="body2" sx={{ fontSize: '0.8rem', color: 'text.secondary' }}>
                                {format(new Date(quote.createdAt), 'dd/MM/yyyy', { locale: fr })}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Typography variant="body2" sx={{ fontWeight: 700, fontSize: '0.85rem', color: '#111827' }}>
                              {formatFromEUR(quote.total, currency)}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                              <ScheduleIcon sx={{ fontSize: 14, color: isExpired ? '#f59e0b' : 'text.disabled' }} />
                              <Typography variant="body2" sx={{ fontSize: '0.8rem', color: isExpired ? '#f59e0b' : 'text.secondary', fontWeight: isExpired ? 600 : 400 }}>
                                {format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}
                              </Typography>
                              {isExpired && <WarningIcon sx={{ fontSize: 14, color: '#f59e0b' }} />}
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Chip
                              label={getStatusLabel(quote.status)}
                              size="small"
                              sx={{ height: 22, fontSize: '0.7rem', fontWeight: 700, bgcolor: alpha(statusColor, 0.1), color: statusColor, borderRadius: '6px' }}
                            />
                          </TableCell>
                          <TableCell align="right">
                            <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'flex-end' }}>
                              <Tooltip title="Voir le devis" arrow>
                                <IconButton size="small" onClick={() => openQuoteView(quote)} sx={{ bgcolor: alpha('#6366f1', 0.08), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.18) }, width: 30, height: 30 }}>
                                  <VisibilityIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Télécharger" arrow>
                                <IconButton size="small" onClick={() => downloadQuote(quote)} sx={{ bgcolor: alpha('#22c55e', 0.08), color: '#22c55e', '&:hover': { bgcolor: alpha('#22c55e', 0.18) }, width: 30, height: 30 }}>
                                  <DownloadIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Imprimer" arrow>
                                <IconButton size="small" onClick={() => printQuote(quote)} sx={{ bgcolor: alpha('#3b82f6', 0.08), color: '#3b82f6', '&:hover': { bgcolor: alpha('#3b82f6', 0.18) }, width: 30, height: 30 }}>
                                  <PrintIcon sx={{ fontSize: 15 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Supprimer" arrow>
                                <IconButton size="small" onClick={() => handleDeleteQuote(quote.id)} sx={{ bgcolor: alpha('#ef4444', 0.08), color: '#ef4444', '&:hover': { bgcolor: alpha('#ef4444', 0.18) }, width: 30, height: 30 }}>
                                  <DeleteIcon sx={{ fontSize: 15 }} />
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
                  {filteredQuotes.length} devis{filteredQuotes.length !== quotes.length ? ` sur ${quotes.length}` : ''}
                </Typography>
                {(listSearch || statusFilter !== 'all') && (
                  <Chip
                    label="Effacer les filtres"
                    size="small"
                    onClick={() => { setListSearch(''); setStatusFilter('all'); }}
                    sx={{ fontSize: '0.7rem', height: 22, borderRadius: '6px' }}
                  />
                )}
              </Box>
            </>
          )}
        </CardContent>
      </Card>

      {/* ─── QuoteForm dialog ─── */}
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

      {/* ─── QuoteView dialog ─── */}
      <QuoteView
        open={quoteViewOpen}
        onClose={() => setQuoteViewOpen(false)}
        quote={selectedQuoteForView}
        client={selectedQuoteForView?.clientId ? getClientById(selectedQuoteForView.clientId) || null : null}
        onStatusChange={updateQuoteStatus}
      />

      {/* ─── Snackbar ─── */}
      <Snackbar open={snackbarOpen} autoHideDuration={4000} onClose={() => setSnackbarOpen(false)} message={snackbarMessage} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
};

export default Quotes;

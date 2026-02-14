import React, { useState, useEffect, useMemo } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  IconButton,
  Dialog,
  DialogContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tooltip,
  Snackbar,
  Alert,
  InputAdornment,
  alpha,
  CircularProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  LocalShipping as ShippingIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Cancel as CancelIcon,
  Visibility as ViewIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Inventory as InventoryIcon,
  AttachMoney as MoneyIcon,
  FilterList as FilterIcon,
  Close as CloseIcon,
  BusinessCenter as SupplierIcon,
  CalendarMonth as CalendarIcon,
  Notes as NotesIcon,
  LocalOffer as TagIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  ContentPaste as PasteIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../../store';
import { useWorkshopSettings } from '../../../contexts/WorkshopSettingsContext';
import { formatFromEUR, getCurrencySymbol } from '../../../utils/currencyUtils';
import { Order } from '../../../types/order';
import orderService from '../../../services/orderService';

/* ─── design tokens ─── */
const CARD_BASE = {
  borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': { boxShadow: '0 8px 32px rgba(0,0,0,0.10)', transform: 'translateY(-2px)' },
} as const;
const CARD_STATIC = {
  borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
} as const;
const TABLE_HEAD_SX = {
  '& th': { borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase', letterSpacing: '0.05em' },
} as const;
const BTN_DARK = {
  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;
const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── status helpers ─── */
const STATUS_MAP: Record<string, { label: string; color: string; icon: React.ReactNode }> = {
  pending:   { label: 'En attente',  color: '#f59e0b', icon: <ScheduleIcon sx={{ fontSize: 16 }} /> },
  confirmed: { label: 'Confirmée',   color: '#3b82f6', icon: <CheckCircleIcon sx={{ fontSize: 16 }} /> },
  shipped:   { label: 'Expédiée',    color: '#8b5cf6', icon: <ShippingIcon sx={{ fontSize: 16 }} /> },
  delivered: { label: 'Livrée',      color: '#22c55e', icon: <CheckCircleIcon sx={{ fontSize: 16 }} /> },
  cancelled: { label: 'Annulée',     color: '#ef4444', icon: <CancelIcon sx={{ fontSize: 16 }} /> },
};

const FILTER_CHIPS: { key: string; label: string }[] = [
  { key: 'all', label: 'Toutes' },
  { key: 'pending', label: 'En attente' },
  { key: 'confirmed', label: 'Confirmées' },
  { key: 'shipped', label: 'Expédiées' },
  { key: 'delivered', label: 'Livrées' },
  { key: 'cancelled', label: 'Annulées' },
];

/* ─── KpiMini ─── */
function KpiMini({ icon, iconColor, label, value }: { icon: React.ReactNode; iconColor: string; label: string; value: string | number }) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{ width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0, boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}` }}>
            {icon}
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>{value}</Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>{label}</Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ═══════════════════════ main component ═══════════════════════ */
const OrderTracking: React.FC = () => {
  const { workshopSettings } = useWorkshopSettings();
  const { addExpense } = useAppStore();
  const currency = workshopSettings?.currency || 'EUR';
  const currencySymbol = getCurrencySymbol(currency);

  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [editMode, setEditMode] = useState(false);
  const [snack, setSnack] = useState<{ open: boolean; msg: string; sev: 'success' | 'error' | 'info' }>({ open: false, msg: '', sev: 'info' });

  const [stats, setStats] = useState({
    total: 0, pending: 0, confirmed: 0, shipped: 0, delivered: 0, cancelled: 0, totalAmount: 0,
  });

  /* ── load ── */
  useEffect(() => {
    const init = async () => {
      try {
        const compat = await orderService.checkDataCompatibility();
        if (compat.hasOldData) await orderService.cleanupOldData();
      } catch { /* ignore */ }
      loadOrders();
    };
    init();
  }, []);

  const loadOrders = async () => {
    setLoading(true);
    try {
      const [ordersData, statsData] = await Promise.all([
        orderService.getAllOrders(),
        orderService.getOrderStats(),
      ]);
      setOrders(ordersData);
      setStats(statsData);
    } catch {
      setSnack({ open: true, msg: 'Erreur lors du chargement des commandes', sev: 'error' });
    } finally {
      setLoading(false);
    }
  };

  /* ── filtered ── */
  const filteredOrders = useMemo(() => {
    let list = orders;
    if (searchTerm) {
      const q = searchTerm.toLowerCase();
      list = list.filter(o =>
        o.orderNumber.toLowerCase().includes(q) ||
        o.supplierName.toLowerCase().includes(q) ||
        o.trackingNumber?.toLowerCase().includes(q),
      );
    }
    if (statusFilter !== 'all') list = list.filter(o => o.status === statusFilter);
    return list;
  }, [orders, searchTerm, statusFilter]);

  /* ── actions ── */
  const handleViewOrder = (order: Order) => { setSelectedOrder(order); setEditMode(false); setOpenDialog(true); };
  const handleEditOrder = (order: Order) => { setSelectedOrder(order); setEditMode(true); setOpenDialog(true); };
  const handleAddOrder = () => { setSelectedOrder(null); setEditMode(true); setOpenDialog(true); };
  const handleCloseDialog = () => { setOpenDialog(false); setSelectedOrder(null); setEditMode(false); };

  const handleSaveOrder = async (updatedOrder: Order) => {
    try {
      const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(updatedOrder.id || '');

      if (updatedOrder.id && isUUID) {
        const result = await orderService.updateOrder(updatedOrder.id, updatedOrder);
        if (result) {
          setOrders(prev => prev.map(o => o.id === updatedOrder.id ? result : o));
          setSnack({ open: true, msg: 'Commande mise à jour', sev: 'success' });
        }
      } else {
        const { id, ...orderData } = updatedOrder;
        const newOrder = await orderService.createOrder(orderData);
        setOrders(prev => [newOrder, ...prev]);
        setSnack({ open: true, msg: 'Commande créée avec succès', sev: 'success' });

        try {
          const expenseTitle = newOrder.orderNumber
            ? `Commande ${newOrder.orderNumber} - ${newOrder.supplierName || 'Fournisseur'}`
            : `Commande - ${newOrder.supplierName || 'Fournisseur'}`;
          await addExpense({
            title: expenseTitle,
            description: newOrder.notes || `Commande auprès de ${newOrder.supplierName || 'fournisseur'}`,
            amount: newOrder.totalAmount || 0,
            supplier: newOrder.supplierName || undefined,
            invoiceNumber: newOrder.orderNumber || undefined,
            paymentMethod: 'card',
            status: 'paid',
            expenseDate: newOrder.orderDate ? new Date(newOrder.orderDate) : new Date(),
            dueDate: newOrder.expectedDeliveryDate ? new Date(newOrder.expectedDeliveryDate) : undefined,
            tags: ['commande', 'automatique'],
          });
        } catch { /* expense creation is non-blocking */ }
      }

      handleCloseDialog();
      try { const s = await orderService.getOrderStats(); setStats(s); } catch { /* ignore */ }
    } catch {
      setSnack({ open: true, msg: 'Erreur lors de la sauvegarde', sev: 'error' });
    }
  };

  const handleDeleteOrder = async (orderId: string) => {
    try {
      const ok = await orderService.deleteOrder(orderId);
      if (ok) {
        setOrders(prev => prev.filter(o => o.id !== orderId));
        setSnack({ open: true, msg: 'Commande supprimée', sev: 'success' });
        try { const s = await orderService.getOrderStats(); setStats(s); } catch { /* ignore */ }
      }
    } catch {
      setSnack({ open: true, msg: 'Erreur lors de la suppression', sev: 'error' });
    }
  };

  const clearFilters = () => { setSearchTerm(''); setStatusFilter('all'); };

  /* ════════════════════════ render ════════════════════════ */
  return (
    <Box sx={{ pb: 4 }}>
      {/* ── header ── */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.01em' }}>
            Suivi des Commandes
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gérez et suivez vos commandes fournisseurs
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleAddOrder}
          sx={{ ...BTN_DARK, px: 3, py: 1.2 }}>
          Nouvelle commande
        </Button>
      </Box>

      {/* ── KPIs ── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}><KpiMini icon={<InventoryIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total commandes" value={stats.total} /></Grid>
        <Grid item xs={6} md={3}><KpiMini icon={<ScheduleIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="En attente" value={stats.pending} /></Grid>
        <Grid item xs={6} md={3}><KpiMini icon={<ShippingIcon sx={{ fontSize: 20 }} />} iconColor="#8b5cf6" label="Expédiées" value={stats.shipped} /></Grid>
        <Grid item xs={6} md={3}><KpiMini icon={<MoneyIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Montant total" value={formatFromEUR(stats.totalAmount || 0, currency)} /></Grid>
      </Grid>

      {/* ── search + filter ── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap', p: '16px !important' }}>
          <TextField size="small" placeholder="Rechercher N°, fournisseur, suivi..."
            value={searchTerm} onChange={e => setSearchTerm(e.target.value)}
            sx={{ minWidth: 260, ...INPUT_SX }}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 20, color: 'text.disabled' }} /></InputAdornment> }} />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {FILTER_CHIPS.map(f => {
              const active = statusFilter === f.key;
              const col = f.key === 'all' ? '#6366f1' : (STATUS_MAP[f.key]?.color || '#6366f1');
              return (
                <Chip key={f.key} label={f.label} size="small"
                  onClick={() => setStatusFilter(f.key)}
                  sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                    bgcolor: active ? alpha(col, 0.12) : 'transparent',
                    color: active ? col : 'text.secondary',
                    border: `1px solid ${active ? col : 'rgba(0,0,0,0.08)'}`,
                    '&:hover': { bgcolor: alpha(col, 0.08) },
                  }} />
              );
            })}
          </Box>
        </CardContent>
      </Card>

      {/* ── table / empty / loading ── */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}><CircularProgress /></Box>
      ) : filteredOrders.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 10 }}>
          <Box sx={{ width: 80, height: 80, borderRadius: '20px', mx: 'auto', mb: 3, display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, #6366f1, ${alpha('#6366f1', 0.7)})`,
            boxShadow: `0 8px 24px ${alpha('#6366f1', 0.3)}` }}>
            <ShippingIcon sx={{ fontSize: 36, color: '#fff' }} />
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
            {searchTerm || statusFilter !== 'all' ? 'Aucune commande trouvée' : 'Aucune commande'}
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3, maxWidth: 400, mx: 'auto' }}>
            {searchTerm || statusFilter !== 'all'
              ? 'Essayez de modifier vos critères de recherche.'
              : 'Créez votre première commande fournisseur pour suivre vos achats.'}
          </Typography>
          {!searchTerm && statusFilter === 'all' ? (
            <Button variant="contained" startIcon={<AddIcon />} onClick={handleAddOrder} sx={{ ...BTN_DARK, px: 3 }}>
              Créer une commande
            </Button>
          ) : (
            <Chip label="Effacer les filtres" size="small" onClick={clearFilters}
              sx={{ fontWeight: 600, borderRadius: '8px', bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }} />
          )}
        </Box>
      ) : (
        <Card sx={CARD_STATIC}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow sx={TABLE_HEAD_SX}>
                  <TableCell>N° Commande</TableCell>
                  <TableCell>Fournisseur</TableCell>
                  <TableCell>Date commande</TableCell>
                  <TableCell>Livraison prévue</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell align="right">Montant</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredOrders.map(order => {
                  const st = STATUS_MAP[order.status] || STATUS_MAP.pending;
                  return (
                    <TableRow key={order.id} hover sx={{ '&:last-child td': { border: 0 } }}>
                      <TableCell>
                        <Typography variant="subtitle2" sx={{ fontWeight: 700, fontFamily: 'monospace', fontSize: '0.85rem' }}>
                          {order.orderNumber}
                        </Typography>
                        {order.trackingNumber && (
                          <Typography variant="caption" sx={{ color: 'text.disabled', display: 'block' }}>
                            Suivi : {order.trackingNumber}
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>{order.supplierName}</Typography>
                        {order.supplierEmail && (
                          <Typography variant="caption" sx={{ color: 'text.disabled', display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            <EmailIcon sx={{ fontSize: 12 }} />{order.supplierEmail}
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {new Date(order.orderDate).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {new Date(order.expectedDeliveryDate).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })}
                        </Typography>
                        {order.actualDeliveryDate && (
                          <Typography variant="caption" sx={{ color: '#22c55e', fontWeight: 600, display: 'block' }}>
                            Livrée le {new Date(order.actualDeliveryDate).toLocaleDateString('fr-FR')}
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Chip icon={st.icon as React.ReactElement} label={st.label} size="small"
                          sx={{ fontWeight: 600, fontSize: '0.72rem', borderRadius: '8px',
                            bgcolor: alpha(st.color, 0.10), color: st.color,
                            '& .MuiChip-icon': { color: st.color },
                          }} />
                      </TableCell>
                      <TableCell align="right">
                        <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
                          {formatFromEUR(order.totalAmount, currency)}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', justifyContent: 'center', gap: 0.5 }}>
                          <Tooltip title="Voir" arrow>
                            <IconButton size="small" onClick={() => handleViewOrder(order)}
                              sx={{ bgcolor: alpha('#3b82f6', 0.08), color: '#3b82f6', '&:hover': { bgcolor: alpha('#3b82f6', 0.16) } }}>
                              <ViewIcon sx={{ fontSize: 18 }} />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Modifier" arrow>
                            <IconButton size="small" onClick={() => handleEditOrder(order)}
                              sx={{ bgcolor: alpha('#f59e0b', 0.08), color: '#f59e0b', '&:hover': { bgcolor: alpha('#f59e0b', 0.16) } }}>
                              <EditIcon sx={{ fontSize: 18 }} />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Supprimer" arrow>
                            <IconButton size="small" onClick={() => handleDeleteOrder(order.id)}
                              sx={{ bgcolor: alpha('#ef4444', 0.08), color: '#ef4444', '&:hover': { bgcolor: alpha('#ef4444', 0.16) } }}>
                              <DeleteIcon sx={{ fontSize: 18 }} />
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
        </Card>
      )}

      {/* ── footer count ── */}
      {!loading && filteredOrders.length > 0 && (
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mt: 2, px: 1 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
            {filteredOrders.length} commande{filteredOrders.length > 1 ? 's' : ''}
            {(searchTerm || statusFilter !== 'all') && ` sur ${orders.length}`}
          </Typography>
          {(searchTerm || statusFilter !== 'all') && (
            <Chip label="Effacer les filtres" size="small" onClick={clearFilters}
              sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.7rem',
                bgcolor: alpha('#6366f1', 0.08), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }} />
          )}
        </Box>
      )}

      {/* ── dialog ── */}
      <OrderDialog open={openDialog} order={selectedOrder} editMode={editMode}
        onClose={handleCloseDialog} onSave={handleSaveOrder} currency={currency} currencySymbol={currencySymbol} />

      {/* ── snackbar ── */}
      <Snackbar open={snack.open} autoHideDuration={3000} onClose={() => setSnack(s => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        <Alert severity={snack.sev} variant="filled" sx={{ borderRadius: '10px', fontWeight: 600 }}
          onClose={() => setSnack(s => ({ ...s, open: false }))}>
          {snack.msg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

/* ═══════════════════════ order dialog ═══════════════════════ */
interface OrderDialogProps {
  open: boolean;
  order: Order | null;
  editMode: boolean;
  onClose: () => void;
  onSave: (order: Order) => void;
  currency: string;
  currencySymbol: string;
}

const OrderDialog: React.FC<OrderDialogProps> = ({ open, order, editMode, onClose, onSave, currency, currencySymbol }) => {
  const [formData, setFormData] = useState<Partial<Order>>({});

  useEffect(() => {
    if (order) {
      setFormData(order);
    } else {
      setFormData({
        orderNumber: '', supplierName: '', supplierEmail: '', supplierPhone: '',
        orderDate: new Date().toISOString().split('T')[0], expectedDeliveryDate: '',
        status: 'pending', totalAmount: 0, trackingNumber: '', items: [], notes: '',
      });
    }
  }, [order]);

  const handleSave = () => {
    if (formData.id) {
      onSave(formData as Order);
    } else {
      onSave({
        id: Date.now().toString(),
        orderNumber: formData.orderNumber || '',
        supplierName: formData.supplierName || '',
        supplierEmail: formData.supplierEmail || '',
        supplierPhone: formData.supplierPhone || '',
        orderDate: formData.orderDate || '',
        expectedDeliveryDate: formData.expectedDeliveryDate || '',
        status: formData.status || 'pending',
        totalAmount: formData.totalAmount || 0,
        trackingNumber: formData.trackingNumber || '',
        items: [],
        notes: formData.notes || '',
      });
    }
  };

  const set = (k: keyof Order, v: any) => setFormData(prev => ({ ...prev, [k]: v }));
  const title = editMode ? (order ? 'Modifier la commande' : 'Nouvelle commande') : 'Détails de la commande';

  /* ── section header helper ── */
  const SectionLabel = ({ icon, color, label }: { icon: React.ReactNode; color: string; label: string }) => (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
      <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: `linear-gradient(135deg, ${color}, ${alpha(color, 0.7)})`, color: '#fff', boxShadow: `0 4px 12px ${alpha(color, 0.3)}` }}>
        {icon}
      </Box>
      <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>{label}</Typography>
    </Box>
  );

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth
      PaperProps={{ sx: { borderRadius: '16px', overflow: 'hidden' } }}>
      {/* dark header */}
      <Box sx={{ background: 'linear-gradient(135deg, #111827 0%, #1e293b 100%)', px: 3, py: 2.5,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Box>
          <Typography variant="h6" sx={{ color: '#fff', fontWeight: 700 }}>{title}</Typography>
          {order?.orderNumber && (
            <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.6)' }}>{order.orderNumber}</Typography>
          )}
        </Box>
        <IconButton onClick={onClose} sx={{ color: 'rgba(255,255,255,0.7)', '&:hover': { color: '#fff' } }}>
          <CloseIcon />
        </IconButton>
      </Box>

      <DialogContent sx={{ p: 3 }}>
        {/* fournisseur */}
        <SectionLabel icon={<SupplierIcon sx={{ fontSize: 18 }} />} color="#6366f1" label="Fournisseur" />
        <Grid container spacing={2} sx={{ mb: 3 }}>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Fournisseur" value={formData.supplierName || ''}
              onChange={e => set('supplierName', e.target.value)} disabled={!editMode} sx={INPUT_SX} />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Email" value={formData.supplierEmail || ''}
              onChange={e => set('supplierEmail', e.target.value)} disabled={!editMode} sx={INPUT_SX}
              InputProps={{ startAdornment: <InputAdornment position="start"><EmailIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Téléphone" value={formData.supplierPhone || ''}
              onChange={e => set('supplierPhone', e.target.value)} disabled={!editMode} sx={INPUT_SX}
              InputProps={{ startAdornment: <InputAdornment position="start"><PhoneIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
          </Grid>
        </Grid>

        {/* commande */}
        <SectionLabel icon={<PasteIcon sx={{ fontSize: 18 }} />} color="#3b82f6" label="Détails commande" />
        <Grid container spacing={2} sx={{ mb: 3 }}>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="N° Commande" value={formData.orderNumber || ''}
              onChange={e => set('orderNumber', e.target.value)} disabled={!editMode} sx={INPUT_SX} />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Date commande" type="date"
              value={formData.orderDate || ''} onChange={e => set('orderDate', e.target.value)}
              disabled={!editMode} InputLabelProps={{ shrink: true }} sx={INPUT_SX} />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Livraison prévue" type="date"
              value={formData.expectedDeliveryDate || ''} onChange={e => set('expectedDeliveryDate', e.target.value)}
              disabled={!editMode} InputLabelProps={{ shrink: true }} sx={INPUT_SX} />
          </Grid>
          <Grid item xs={12} md={4}>
            <FormControl fullWidth size="small" sx={INPUT_SX}>
              <InputLabel>Statut</InputLabel>
              <Select value={formData.status || 'pending'} label="Statut"
                onChange={e => set('status', e.target.value)} disabled={!editMode}>
                <MenuItem value="pending">En attente</MenuItem>
                <MenuItem value="confirmed">Confirmée</MenuItem>
                <MenuItem value="shipped">Expédiée</MenuItem>
                <MenuItem value="delivered">Livrée</MenuItem>
                <MenuItem value="cancelled">Annulée</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="N° de suivi" value={formData.trackingNumber || ''}
              onChange={e => set('trackingNumber', e.target.value)} disabled={!editMode} sx={INPUT_SX}
              InputProps={{ startAdornment: <InputAdornment position="start"><ShippingIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label={`Montant total (${currencySymbol})`} type="number"
              value={formData.totalAmount || 0}
              onChange={e => set('totalAmount', parseFloat(e.target.value) || 0)}
              disabled={!editMode} sx={INPUT_SX}
              inputProps={{ min: 0, step: 0.01 }}
              InputProps={{ startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment> }} />
          </Grid>
        </Grid>

        {/* notes */}
        <SectionLabel icon={<NotesIcon sx={{ fontSize: 18 }} />} color="#8b5cf6" label="Notes" />
        <TextField fullWidth size="small" multiline rows={3} value={formData.notes || ''}
          onChange={e => set('notes', e.target.value)} disabled={!editMode} sx={INPUT_SX}
          placeholder="Ajoutez des notes ou commentaires..." />

        {/* actions */}
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1.5, mt: 3 }}>
          <Button onClick={onClose} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            {editMode ? 'Annuler' : 'Fermer'}
          </Button>
          {editMode && (
            <Button variant="contained" onClick={handleSave}
              sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, px: 4,
                bgcolor: '#22c55e', '&:hover': { bgcolor: '#16a34a' },
                boxShadow: `0 4px 14px ${alpha('#22c55e', 0.4)}` }}>
              {order ? 'Enregistrer' : 'Créer la commande'}
            </Button>
          )}
        </Box>
      </DialogContent>
    </Dialog>
  );
};

export default OrderTracking;

import React, { useState, useEffect, useMemo } from 'react';
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
  Chip,
  InputAdornment,
  Tooltip,
  alpha,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  MonetizationOn as MonetizationOnIcon,
  Assessment as AssessmentIcon,
  Receipt as ReceiptIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Expense } from '../../types';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import toast from 'react-hot-toast';

/* ─── Design tokens ─── */
const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': {
    boxShadow: '0 8px 32px rgba(0,0,0,0.10)',
    transform: 'translateY(-2px)',
  },
} as const;

const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;

const BTN_DARK = {
  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;

const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── KPI Mini Card ─── */
function KpiMini({ icon, iconColor, label, value }: {
  icon: React.ReactNode; iconColor: string; label: string; value: string;
}) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{
            width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0,
            boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
          }}>
            {icon}
          </Box>
          <Box>
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

/* ─── Filter options ─── */
const STATUS_OPTIONS = [
  { value: 'all', label: 'Tous' },
  { value: 'pending', label: 'En attente' },
  { value: 'paid', label: 'Payé' },
  { value: 'cancelled', label: 'Annulé' },
];

const PERIOD_OPTIONS = [
  { value: 'all', label: 'Toutes' },
  { value: 'today', label: "Aujourd'hui" },
  { value: 'week', label: 'Semaine' },
  { value: 'month', label: 'Mois' },
  { value: 'year', label: 'Année' },
];

/* ─── Main component ─── */
const Expenses: React.FC = () => {
  const { expenses, expenseStats, loadExpenses, loadExpenseStats, addExpense, updateExpense, deleteExpense } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  const [newExpenseDialogOpen, setNewExpenseDialogOpen] = useState(false);
  const [editExpenseDialogOpen, setEditExpenseDialogOpen] = useState(false);
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [dateRangeFilter, setDateRangeFilter] = useState<string>('all');

  const [expenseForm, setExpenseForm] = useState({
    title: '', description: '', amount: '', supplier: '', invoiceNumber: '',
    paymentMethod: 'card' as 'cash' | 'card' | 'transfer' | 'check',
    status: 'pending' as 'pending' | 'paid' | 'cancelled',
    expenseDate: format(new Date(), 'yyyy-MM-dd'), dueDate: '', tags: [] as string[],
  });

  useEffect(() => {
    const init = async () => { await loadExpenses(); await loadExpenseStats(); };
    init();
  }, [loadExpenses, loadExpenseStats]);

  const filteredExpenses = useMemo(() => {
    return expenses.filter(expense => {
      const matchesSearch = expense.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        expense.description?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        expense.supplier?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesStatus = statusFilter === 'all' || expense.status === statusFilter;
      let matchesDate = true;
      if (dateRangeFilter !== 'all') {
        const expenseDate = new Date(expense.expenseDate);
        const now = new Date();
        switch (dateRangeFilter) {
          case 'today': matchesDate = expenseDate.toDateString() === now.toDateString(); break;
          case 'week': matchesDate = expenseDate >= new Date(now.getTime() - 7 * 86400000); break;
          case 'month': matchesDate = expenseDate >= new Date(now.getFullYear(), now.getMonth() - 1, now.getDate()); break;
          case 'year': matchesDate = expenseDate >= new Date(now.getFullYear() - 1, now.getMonth(), now.getDate()); break;
        }
      }
      return matchesSearch && matchesStatus && matchesDate;
    });
  }, [expenses, searchQuery, statusFilter, dateRangeFilter]);

  const resetExpenseForm = () => {
    setExpenseForm({
      title: '', description: '', amount: '', supplier: '', invoiceNumber: '',
      paymentMethod: 'card', status: 'pending',
      expenseDate: format(new Date(), 'yyyy-MM-dd'), dueDate: '', tags: [],
    });
  };

  const handleCreateExpense = async () => {
    if (!expenseForm.title || !expenseForm.amount) {
      toast.error('Veuillez remplir tous les champs obligatoires');
      return;
    }
    try {
      await addExpense({
        title: expenseForm.title, description: expenseForm.description || undefined,
        amount: parseFloat(expenseForm.amount),
        category: { id: '', name: 'General', description: 'Catégorie par défaut', color: '#757575', isActive: true, createdAt: new Date(), updatedAt: new Date() },
        supplier: expenseForm.supplier || undefined, invoiceNumber: expenseForm.invoiceNumber || undefined,
        paymentMethod: expenseForm.paymentMethod, status: expenseForm.status,
        expenseDate: new Date(expenseForm.expenseDate),
        dueDate: expenseForm.dueDate ? new Date(expenseForm.dueDate) : undefined,
        tags: expenseForm.tags,
      });
      toast.success('Dépense créée avec succès');
      setNewExpenseDialogOpen(false);
      resetExpenseForm();
      loadExpenseStats();
    } catch (error) {
      if (error instanceof Error && error.message.includes('catégorie')) {
        toast.error("Aucune catégorie disponible. Créez-en une dans les paramètres.");
      } else {
        toast.error('Erreur lors de la création de la dépense');
      }
    }
  };

  const handleUpdateExpense = async () => {
    if (!selectedExpense || !expenseForm.title || !expenseForm.amount) {
      toast.error('Veuillez remplir tous les champs obligatoires');
      return;
    }
    try {
      await updateExpense(selectedExpense.id, {
        title: expenseForm.title, description: expenseForm.description || undefined,
        amount: parseFloat(expenseForm.amount),
        category: { id: '', name: 'General', description: 'Catégorie par défaut', color: '#757575', isActive: true, createdAt: new Date(), updatedAt: new Date() },
        supplier: expenseForm.supplier || undefined, invoiceNumber: expenseForm.invoiceNumber || undefined,
        paymentMethod: expenseForm.paymentMethod, status: expenseForm.status,
        expenseDate: new Date(expenseForm.expenseDate),
        dueDate: expenseForm.dueDate ? new Date(expenseForm.dueDate) : undefined,
        tags: expenseForm.tags,
      });
      toast.success('Dépense mise à jour avec succès');
      setEditExpenseDialogOpen(false);
      setSelectedExpense(null);
      resetExpenseForm();
      loadExpenseStats();
    } catch {
      toast.error('Erreur lors de la mise à jour');
    }
  };

  const handleDeleteExpense = async (expense: Expense) => {
    if (!window.confirm(`Supprimer la dépense "${expense.title}" ?`)) return;
    try {
      await deleteExpense(expense.id);
      toast.success('Dépense supprimée');
      loadExpenseStats();
    } catch {
      toast.error('Erreur lors de la suppression');
    }
  };

  const openEditExpenseDialog = (expense: Expense) => {
    setSelectedExpense(expense);
    setExpenseForm({
      title: expense.title, description: expense.description || '',
      amount: expense.amount.toString(), supplier: expense.supplier || '',
      invoiceNumber: expense.invoiceNumber || '', paymentMethod: expense.paymentMethod,
      status: expense.status, expenseDate: format(expense.expenseDate, 'yyyy-MM-dd'),
      dueDate: expense.dueDate ? format(expense.dueDate, 'yyyy-MM-dd') : '', tags: expense.tags || [],
    });
    setEditExpenseDialogOpen(true);
  };

  const getStatusChip = (status: string) => {
    const map: Record<string, { label: string; color: string }> = {
      paid: { label: 'Payé', color: '#22c55e' },
      pending: { label: 'En attente', color: '#f59e0b' },
      cancelled: { label: 'Annulé', color: '#ef4444' },
    };
    const c = map[status] || { label: status, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const getPaymentMethodLabel = (method: string) => {
    const map: Record<string, string> = { cash: 'Espèces', card: 'Carte bancaire', transfer: 'Virement', check: 'Chèque' };
    return map[method] || method;
  };

  /* ─── Expense form fields (shared between create & edit) ─── */
  const renderFormFields = () => (
    <Grid container spacing={2} sx={{ mt: 0.5 }}>
      <Grid item xs={12}>
        <TextField fullWidth label="Titre *" value={expenseForm.title}
          onChange={e => setExpenseForm({ ...expenseForm, title: e.target.value })} sx={INPUT_SX} />
      </Grid>
      <Grid item xs={12}>
        <TextField fullWidth label="Description" multiline rows={3} value={expenseForm.description}
          onChange={e => setExpenseForm({ ...expenseForm, description: e.target.value })} sx={INPUT_SX} />
      </Grid>
      <Grid item xs={12} sm={6}>
        <TextField fullWidth label="Montant *" type="number" value={expenseForm.amount}
          onChange={e => setExpenseForm({ ...expenseForm, amount: e.target.value })}
          InputProps={{ startAdornment: <InputAdornment position="start">{currency}</InputAdornment> }}
          sx={INPUT_SX} />
      </Grid>
      <Grid item xs={12} sm={6}>
        <TextField fullWidth label="Fournisseur" value={expenseForm.supplier}
          onChange={e => setExpenseForm({ ...expenseForm, supplier: e.target.value })} sx={INPUT_SX} />
      </Grid>
      <Grid item xs={12} sm={6}>
        <TextField fullWidth label="N° de facture" value={expenseForm.invoiceNumber}
          onChange={e => setExpenseForm({ ...expenseForm, invoiceNumber: e.target.value })} sx={INPUT_SX} />
      </Grid>
      <Grid item xs={12} sm={6}>
        <FormControl fullWidth>
          <InputLabel>Méthode de paiement</InputLabel>
          <Select value={expenseForm.paymentMethod} label="Méthode de paiement"
            onChange={e => setExpenseForm({ ...expenseForm, paymentMethod: e.target.value as any })}
            sx={{ borderRadius: '10px' }}>
            <MenuItem value="cash">Espèces</MenuItem>
            <MenuItem value="card">Carte bancaire</MenuItem>
            <MenuItem value="transfer">Virement</MenuItem>
            <MenuItem value="check">Chèque</MenuItem>
          </Select>
        </FormControl>
      </Grid>
      <Grid item xs={12} sm={6}>
        <FormControl fullWidth>
          <InputLabel>Statut</InputLabel>
          <Select value={expenseForm.status} label="Statut"
            onChange={e => setExpenseForm({ ...expenseForm, status: e.target.value as any })}
            sx={{ borderRadius: '10px' }}>
            <MenuItem value="pending">En attente</MenuItem>
            <MenuItem value="paid">Payé</MenuItem>
            <MenuItem value="cancelled">Annulé</MenuItem>
          </Select>
        </FormControl>
      </Grid>
      <Grid item xs={12} sm={6}>
        <TextField fullWidth label="Date de dépense" type="date" value={expenseForm.expenseDate}
          onChange={e => setExpenseForm({ ...expenseForm, expenseDate: e.target.value })}
          InputLabelProps={{ shrink: true }} sx={INPUT_SX} />
      </Grid>
      <Grid item xs={12} sm={6}>
        <TextField fullWidth label="Date d'échéance" type="date" value={expenseForm.dueDate}
          onChange={e => setExpenseForm({ ...expenseForm, dueDate: e.target.value })}
          InputLabelProps={{ shrink: true }} sx={INPUT_SX} />
      </Grid>
    </Grid>
  );

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>
            Gestion des dépenses
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Suivez et gérez toutes vos dépenses
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => { resetExpenseForm(); setNewExpenseDialogOpen(true); }}
          sx={BTN_DARK}
        >
          Nouvelle dépense
        </Button>
      </Box>

      {/* KPI Cards */}
      {expenseStats && (
        <Grid container spacing={2} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<MonetizationOnIcon sx={{ fontSize: 20 }} />}
              iconColor="#ef4444"
              label="Total des dépenses"
              value={formatFromEUR(expenseStats.total, currency)}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<TrendingUpIcon sx={{ fontSize: 20 }} />}
              iconColor="#6366f1"
              label="Ce mois"
              value={formatFromEUR(expenseStats.monthly, currency)}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<TrendingDownIcon sx={{ fontSize: 20 }} />}
              iconColor="#f59e0b"
              label="En attente"
              value={formatFromEUR(expenseStats.pending, currency)}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<AssessmentIcon sx={{ fontSize: 20 }} />}
              iconColor="#22c55e"
              label="Payé"
              value={formatFromEUR(expenseStats.paid, currency)}
            />
          </Grid>
        </Grid>
      )}

      {/* Filters */}
      <Card sx={{ ...CARD_BASE, mb: 3, '&:hover': {} }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <TextField
            placeholder="Rechercher..."
            size="small"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            sx={{ flex: 1, minWidth: 200, ...INPUT_SX }}
            InputProps={{
              startAdornment: <InputAdornment position="start"><SearchIcon sx={{ color: 'text.disabled', fontSize: 20 }} /></InputAdornment>,
            }}
          />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {STATUS_OPTIONS.map(opt => (
              <Chip
                key={opt.value}
                label={opt.label}
                onClick={() => setStatusFilter(opt.value)}
                size="small"
                sx={{
                  fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                  ...(statusFilter === opt.value
                    ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
                    : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
                }}
              />
            ))}
          </Box>
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {PERIOD_OPTIONS.map(opt => (
              <Chip
                key={opt.value}
                label={opt.label}
                onClick={() => setDateRangeFilter(opt.value)}
                size="small"
                sx={{
                  fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                  ...(dateRangeFilter === opt.value
                    ? { bgcolor: '#6366f1', color: '#fff', '&:hover': { bgcolor: '#4f46e5' } }
                    : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
                }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* Table */}
      <Card sx={CARD_BASE}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Titre</TableCell>
                <TableCell align="right">Montant</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Paiement</TableCell>
                <TableCell>Fournisseur</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredExpenses.map(expense => (
                <TableRow key={expense.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                  <TableCell>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{expense.title}</Typography>
                      {expense.description && (
                        <Typography variant="caption" color="text.disabled">{expense.description}</Typography>
                      )}
                    </Box>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body2" sx={{ fontWeight: 700, color: '#ef4444' }}>
                      {formatFromEUR(expense.amount, currency)}
                    </Typography>
                  </TableCell>
                  <TableCell>{getStatusChip(expense.status)}</TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {format(expense.expenseDate, 'dd/MM/yyyy', { locale: fr })}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">
                      {getPaymentMethodLabel(expense.paymentMethod)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">
                      {expense.supplier || '—'}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                      <Tooltip title="Modifier">
                        <IconButton size="small" onClick={() => openEditExpenseDialog(expense)}
                          sx={{ color: '#6366f1', bgcolor: alpha('#6366f1', 0.08), '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }}>
                          <EditIcon sx={{ fontSize: 18 }} />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Supprimer">
                        <IconButton size="small" onClick={() => handleDeleteExpense(expense)}
                          sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}>
                          <DeleteIcon sx={{ fontSize: 18 }} />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        {filteredExpenses.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 6 }}>
            <ReceiptIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
            <Typography variant="body2" color="text.disabled">Aucune dépense trouvée</Typography>
          </Box>
        )}
      </Card>

      {/* ─── Create dialog ─── */}
      <Dialog open={newExpenseDialogOpen} onClose={() => { setNewExpenseDialogOpen(false); resetExpenseForm(); }}
        maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Nouvelle dépense</DialogTitle>
        <DialogContent>{renderFormFields()}</DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => { setNewExpenseDialogOpen(false); resetExpenseForm(); }}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button onClick={handleCreateExpense} variant="contained" sx={BTN_DARK}>
            Créer
          </Button>
        </DialogActions>
      </Dialog>

      {/* ─── Edit dialog ─── */}
      <Dialog open={editExpenseDialogOpen} onClose={() => setEditExpenseDialogOpen(false)}
        maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Modifier la dépense</DialogTitle>
        <DialogContent>{renderFormFields()}</DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setEditExpenseDialogOpen(false)}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button onClick={handleUpdateExpense} variant="contained" sx={BTN_DARK}>
            Mettre à jour
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Expenses;

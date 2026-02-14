import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Card,
  CardContent,
  Chip,
  TextField,
  InputAdornment,
  Grid,
  Button,
  alpha,
} from '@mui/material';
import { Search, Add, Analytics as AnalyticsIcon } from '@mui/icons-material';
import {
  AttachMoney,
  CheckCircle as PaidIcon,
  Schedule as PendingIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

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

interface Expense {
  id: string;
  title: string;
  description: string;
  amount: number;
  expenseDate: string;
  category: string;
  paymentMethod: string;
  supplier: string;
  status: 'pending' | 'paid' | 'reimbursed';
}

const CATEGORY_OPTIONS = [
  { value: 'all', label: 'Toutes' },
  { value: 'Pièces détachées', label: 'Pièces' },
  { value: 'Formation', label: 'Formation' },
  { value: 'Outillage', label: 'Outillage' },
  { value: 'Marketing', label: 'Marketing' },
  { value: 'Assurance', label: 'Assurance' },
];

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

const ExpensesViewFixed: React.FC = () => {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [filteredExpenses, setFilteredExpenses] = useState<Expense[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>('all');

  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => { loadRealExpenses(); }, []);

  const loadRealExpenses = async () => {
    try {
      const { expenses } = useAppStore.getState();
      const realExpenses: Expense[] = expenses.map(expense => ({
        id: expense.id, title: expense.title, description: expense.description,
        amount: expense.amount,
        expenseDate: new Date(expense.expenseDate).toISOString().split('T')[0],
        category: expense.tags?.[0] || 'Général',
        paymentMethod: expense.paymentMethod || 'Espèces',
        supplier: expense.supplier || 'N/A', status: expense.status,
      }));
      realExpenses.sort((a, b) => new Date(b.expenseDate).getTime() - new Date(a.expenseDate).getTime());
      setExpenses(realExpenses);
      setFilteredExpenses(realExpenses);
    } catch {
      setExpenses([]);
      setFilteredExpenses([]);
    }
  };

  useEffect(() => {
    let filtered = expenses;
    if (searchTerm) {
      filtered = filtered.filter(e =>
        e.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        e.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
        e.supplier.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    if (filterCategory !== 'all') filtered = filtered.filter(e => e.category === filterCategory);
    setFilteredExpenses(filtered);
  }, [expenses, searchTerm, filterCategory]);

  const getStatusChip = (status: string) => {
    const map: Record<string, { label: string; color: string }> = {
      paid: { label: 'Payée', color: '#22c55e' },
      pending: { label: 'En attente', color: '#f59e0b' },
      reimbursed: { label: 'Remboursée', color: '#06b6d4' },
    };
    const c = map[status] || { label: status, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const totalExpenses = expenses.reduce((s, e) => s + e.amount, 0);
  const paidExpenses = expenses.filter(e => e.status === 'paid').reduce((s, e) => s + e.amount, 0);
  const pendingExpenses = expenses.filter(e => e.status === 'pending').reduce((s, e) => s + e.amount, 0);

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h6" sx={{ fontWeight: 600 }}>
          Gestion des dépenses
        </Typography>
        <Button
          variant="contained"
          startIcon={<Add />}
          sx={{
            borderRadius: '10px', textTransform: 'none', fontWeight: 600,
            bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
            boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
          }}
        >
          Nouvelle dépense
        </Button>
      </Box>

      {/* KPI cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <KpiMini
            icon={<AttachMoney sx={{ fontSize: 20 }} />}
            iconColor="#ef4444"
            label="Total des dépenses"
            value={formatFromEUR(totalExpenses, currency)}
          />
        </Grid>
        <Grid item xs={12} md={4}>
          <KpiMini
            icon={<PaidIcon sx={{ fontSize: 20 }} />}
            iconColor="#22c55e"
            label="Dépenses payées"
            value={formatFromEUR(paidExpenses, currency)}
          />
        </Grid>
        <Grid item xs={12} md={4}>
          <KpiMini
            icon={<PendingIcon sx={{ fontSize: 20 }} />}
            iconColor="#f59e0b"
            label="En attente"
            value={formatFromEUR(pendingExpenses, currency)}
          />
        </Grid>
      </Grid>

      {/* Filters */}
      <Card sx={{ borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)', mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <TextField
            placeholder="Rechercher..."
            size="small"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            sx={{ flex: 1, minWidth: 200, '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
            InputProps={{
              startAdornment: <InputAdornment position="start"><Search sx={{ color: 'text.disabled', fontSize: 20 }} /></InputAdornment>,
            }}
          />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {CATEGORY_OPTIONS.map(opt => (
              <Chip
                key={opt.value}
                label={opt.label}
                onClick={() => setFilterCategory(opt.value)}
                size="small"
                sx={{
                  fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                  ...(filterCategory === opt.value
                    ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
                    : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
                }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* Table */}
      <Card sx={{ borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Titre</TableCell>
                <TableCell>Catégorie</TableCell>
                <TableCell>Fournisseur</TableCell>
                <TableCell>Date</TableCell>
                <TableCell align="right">Montant</TableCell>
                <TableCell>Méthode</TableCell>
                <TableCell>Statut</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredExpenses.map((expense) => (
                <TableRow key={expense.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                  <TableCell>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{expense.title}</Typography>
                      <Typography variant="caption" color="text.disabled">{expense.description}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Chip label={expense.category} size="small" sx={{
                      fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                      bgcolor: alpha('#6366f1', 0.1), color: '#6366f1',
                    }} />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">{expense.supplier}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {new Date(expense.expenseDate).toLocaleDateString('fr-FR')}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body2" sx={{ fontWeight: 700, color: '#ef4444' }}>
                      {formatFromEUR(expense.amount, currency)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">{expense.paymentMethod}</Typography>
                  </TableCell>
                  <TableCell>{getStatusChip(expense.status)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        {filteredExpenses.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 6 }}>
            <AnalyticsIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
            <Typography variant="body2" color="text.disabled">Aucune dépense trouvée</Typography>
          </Box>
        )}
      </Card>
    </Box>
  );
};

export default ExpensesViewFixed;

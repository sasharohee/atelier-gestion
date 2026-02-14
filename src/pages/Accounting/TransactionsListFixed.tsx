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
  alpha,
} from '@mui/material';
import { Search, Analytics as AnalyticsIcon } from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import { repairService } from '../../services/supabaseService';

const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
} as const;

const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;

interface Transaction {
  id: string;
  type: 'sale' | 'repair' | 'expense' | 'deposit';
  date: string;
  description: string;
  amount: number;
  clientName?: string;
  status: string;
  account?: string;
}

const FILTER_OPTIONS = [
  { value: 'all', label: 'Tous' },
  { value: 'sale', label: 'Ventes' },
  { value: 'repair', label: 'Réparations' },
  { value: 'deposit', label: 'Acomptes' },
  { value: 'expense', label: 'Dépenses' },
];

const TransactionsListFixed: React.FC = () => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [filteredTransactions, setFilteredTransactions] = useState<Transaction[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('all');

  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => { loadRealTransactions(); }, []);

  const loadRealTransactions = async () => {
    try {
      const { sales, repairs, expenses, clients } = useAppStore.getState();
      const realTransactions: Transaction[] = [];

      sales.forEach(sale => {
        const client = clients.find(c => c.id === sale.clientId);
        realTransactions.push({
          id: sale.id, type: 'sale',
          date: new Date(sale.createdAt).toISOString().split('T')[0],
          description: `Vente #${sale.id.substring(0, 8)}`,
          amount: sale.total || 0,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          status: sale.status || 'completed',
        });
      });

      repairs.forEach(repair => {
        const client = clients.find(c => c.id === repair.clientId);
        realTransactions.push({
          id: repair.id, type: 'repair',
          date: new Date(repair.createdAt).toISOString().split('T')[0],
          description: `Réparation #${repair.id.substring(0, 8)}`,
          amount: repair.totalPrice || 0,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          status: repair.status || 'completed',
        });
      });

      for (const repair of repairs) {
        if (repair.deposit && repair.deposit > 0) {
          const client = clients.find(c => c.id === repair.clientId);
          let depositDate = new Date(repair.createdAt);
          let depositStatus = 'pending';
          try {
            const paymentsResult = await repairService.getPaymentsByRepairId(repair.id);
            if (paymentsResult.success && 'data' in paymentsResult && paymentsResult.data) {
              const depositPayment = paymentsResult.data.find((payment: any) => payment.paymentType === 'deposit');
              if (depositPayment) {
                depositDate = new Date(depositPayment.paymentDate || depositPayment.createdAt);
                depositStatus = 'paid';
              }
            }
          } catch { /* ignore */ }
          realTransactions.push({
            id: `${repair.id}-deposit`, type: 'deposit',
            date: depositDate.toISOString().split('T')[0],
            description: `Acompte - Réparation #${repair.repairNumber || repair.id.substring(0, 8)}`,
            amount: repair.deposit,
            clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
            status: depositStatus, account: 'Acompte',
          });
        }
      }

      expenses.forEach(expense => {
        realTransactions.push({
          id: expense.id, type: 'expense',
          date: new Date(expense.expenseDate).toISOString().split('T')[0],
          description: expense.title || 'Dépense',
          amount: -(expense.amount || 0),
          status: expense.status || 'paid',
        });
      });

      realTransactions.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
      setTransactions(realTransactions);
      setFilteredTransactions(realTransactions);
    } catch {
      setTransactions([]);
      setFilteredTransactions([]);
    }
  };

  useEffect(() => {
    let filtered = transactions;
    if (searchTerm) {
      filtered = filtered.filter(t =>
        t.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.clientName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    if (filterType !== 'all') filtered = filtered.filter(t => t.type === filterType);
    setFilteredTransactions(filtered);
  }, [transactions, searchTerm, filterType]);

  const getTypeChip = (type: string) => {
    const map: Record<string, { label: string; color: string }> = {
      sale: { label: 'Vente', color: '#6366f1' },
      repair: { label: 'Réparation', color: '#22c55e' },
      deposit: { label: 'Acompte', color: '#06b6d4' },
      expense: { label: 'Dépense', color: '#ef4444' },
    };
    const c = map[type] || { label: type, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const getStatusChip = (status: string) => {
    const map: Record<string, { label: string; color: string }> = {
      completed: { label: 'Terminé', color: '#22c55e' },
      pending: { label: 'En attente', color: '#f59e0b' },
      paid: { label: 'Payé', color: '#06b6d4' },
      cancelled: { label: 'Annulé', color: '#6b7280' },
      returned: { label: 'Restitué', color: '#8b5cf6' },
    };
    const c = map[status] || { label: status, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  return (
    <Box>
      <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
        Liste des transactions
      </Typography>

      {/* Filters */}
      <Card sx={{ ...CARD_BASE, mb: 3 }}>
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
          <Box sx={{ display: 'flex', gap: 0.75 }}>
            {FILTER_OPTIONS.map(opt => (
              <Chip
                key={opt.value}
                label={opt.label}
                onClick={() => setFilterType(opt.value)}
                size="small"
                sx={{
                  fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                  ...(filterType === opt.value
                    ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
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
                <TableCell>Date</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Description</TableCell>
                <TableCell>Client</TableCell>
                <TableCell>Compte</TableCell>
                <TableCell align="right">Montant</TableCell>
                <TableCell>Statut</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredTransactions.map((t) => (
                <TableRow key={t.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {new Date(t.date).toLocaleDateString('fr-FR')}
                    </Typography>
                  </TableCell>
                  <TableCell>{getTypeChip(t.type)}</TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>{t.description}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">{t.clientName || 'N/A'}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.disabled">{t.account || '—'}</Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body2" sx={{
                      fontWeight: 700,
                      color: t.amount < 0 ? '#ef4444' : '#22c55e',
                    }}>
                      {formatFromEUR(t.amount, currency)}
                    </Typography>
                  </TableCell>
                  <TableCell>{getStatusChip(t.status)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        {filteredTransactions.length === 0 && (
          <Box sx={{
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            justifyContent: 'center', py: 6,
          }}>
            <AnalyticsIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
            <Typography variant="body2" color="text.disabled">Aucune transaction trouvée</Typography>
          </Box>
        )}
      </Card>
    </Box>
  );
};

export default TransactionsListFixed;

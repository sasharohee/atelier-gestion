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
  Paper,
  Chip,
  TextField,
  InputAdornment,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Grid,
} from '@mui/material';
import { Search } from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import { repairService } from '../../services/supabaseService';

interface Transaction {
  id: string;
  type: 'sale' | 'repair' | 'expense' | 'deposit';
  date: string;
  description: string;
  amount: number;
  clientName?: string;
  status: string;
  account?: string; // Colonne "compte" pour identifier les acomptes
}

const TransactionsListFixed: React.FC = () => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [filteredTransactions, setFilteredTransactions] = useState<Transaction[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => {
    loadRealTransactions();
  }, []);

  const loadRealTransactions = async () => {
    try {
      // Utiliser les vraies données du store
      const { sales, repairs, expenses, clients } = useAppStore.getState();
      
      const realTransactions: Transaction[] = [];

      // Convertir les ventes en transactions
      sales.forEach(sale => {
        const client = clients.find(c => c.id === sale.clientId);
        realTransactions.push({
          id: sale.id,
          type: 'sale',
          date: new Date(sale.createdAt).toISOString().split('T')[0],
          description: `Vente #${sale.id.substring(0, 8)}`,
          amount: sale.total || 0,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          status: sale.status || 'completed'
        });
      });

      // Convertir les réparations en transactions
      repairs.forEach(repair => {
        const client = clients.find(c => c.id === repair.clientId);
        realTransactions.push({
          id: repair.id,
          type: 'repair',
          date: new Date(repair.createdAt).toISOString().split('T')[0],
          description: `Réparation #${repair.id.substring(0, 8)}`,
          amount: repair.totalPrice || 0,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          status: repair.status || 'completed'
        });
      });

      // Créer des transactions séparées pour les acomptes
      for (const repair of repairs) {
        if (repair.deposit && repair.deposit > 0) {
          const client = clients.find(c => c.id === repair.clientId);
          
          // Essayer de récupérer la date de validation de l'acompte via les paiements
          let depositDate = new Date(repair.createdAt);
          let depositStatus = 'pending';
          
          try {
            const paymentsResult = await repairService.getPaymentsByRepairId(repair.id);
            if (paymentsResult.success && 'data' in paymentsResult && paymentsResult.data) {
              const depositPayment = paymentsResult.data.find(
                (payment: any) => payment.paymentType === 'deposit'
              );
              if (depositPayment) {
                depositDate = new Date(depositPayment.paymentDate || depositPayment.createdAt);
                depositStatus = 'paid';
              }
            }
          } catch (error) {
            console.warn(`Erreur lors de la récupération des paiements pour la réparation ${repair.id}:`, error);
          }

          const repairNumber = repair.repairNumber || repair.id.substring(0, 8);
          realTransactions.push({
            id: `${repair.id}-deposit`,
            type: 'deposit',
            date: depositDate.toISOString().split('T')[0],
            description: `Acompte - Réparation #${repairNumber}`,
            amount: repair.deposit,
            clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
            status: depositStatus,
            account: 'Acompte'
          });
        }
      }

      // Convertir les dépenses en transactions
      expenses.forEach(expense => {
        realTransactions.push({
          id: expense.id,
          type: 'expense',
          date: new Date(expense.expenseDate).toISOString().split('T')[0],
          description: expense.title || 'Dépense',
          amount: -(expense.amount || 0), // Négatif pour les dépenses
          status: expense.status || 'paid'
        });
      });

      // Trier par date (plus récent en premier)
      realTransactions.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

      setTransactions(realTransactions);
      setFilteredTransactions(realTransactions);
    } catch (error) {
      console.error('Erreur lors du chargement des transactions:', error);
      // Fallback sur des données vides
      setTransactions([]);
      setFilteredTransactions([]);
    }
  };

  useEffect(() => {
    let filtered = transactions;

    // Filtrage par recherche
    if (searchTerm) {
      filtered = filtered.filter(t =>
        t.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.clientName?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Filtrage par type
    if (filterType !== 'all') {
      filtered = filtered.filter(t => t.type === filterType);
    }

    setFilteredTransactions(filtered);
  }, [transactions, searchTerm, filterType]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'success';
      case 'pending': return 'warning';
      case 'paid': return 'info';
      case 'returned': return 'secondary';
      default: return 'default';
    };
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'completed': return 'Terminé';
      case 'pending': return 'En attente';
      case 'paid': return 'Payé';
      case 'cancelled': return 'Annulé';
      case 'returned': return 'Restitué';
      default: return status;
    };
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'sale': return 'Vente';
      case 'repair': return 'Réparation';
      case 'expense': return 'Dépense';
      case 'deposit': return 'Acompte';
      default: return type;
    };
  };

  const formatCurrency = (amount: number) => {
    return formatFromEUR(amount, currency);
  };

  return (
    <Box>
      <Typography variant="h5" gutterBottom sx={{ mb: 3, fontWeight: 'medium' }}>
        Liste des Transactions
      </Typography>

      {/* Filtres */}
      <Paper elevation={1} sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={6}>
            <TextField
              label="Rechercher une transaction"
              variant="outlined"
              size="small"
              fullWidth
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} md={3}>
            <FormControl fullWidth size="small">
              <InputLabel>Type</InputLabel>
              <Select
                value={filterType}
                label="Type"
                onChange={(e) => setFilterType(e.target.value)}
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="sale">Vente</MenuItem>
                <MenuItem value="repair">Réparation</MenuItem>
                <MenuItem value="deposit">Acompte</MenuItem>
                <MenuItem value="expense">Dépense</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Paper>

      {/* Tableau des transactions */}
      <TableContainer component={Paper} elevation={1}>
        <Table sx={{ minWidth: 650 }} aria-label="transactions table">
          <TableHead>
            <TableRow>
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
            {filteredTransactions.map((transaction) => (
              <TableRow
                key={transaction.id}
                sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
              >
                <TableCell component="th" scope="row">
                  {new Date(transaction.date).toLocaleDateString('fr-FR')}
                </TableCell>
                <TableCell>
                  <Chip 
                    label={getTypeLabel(transaction.type)} 
                    color={
                      transaction.type === 'expense' 
                        ? 'error' 
                        : transaction.type === 'deposit'
                        ? 'info'
                        : 'primary'
                    }
                    size="small"
                  />
                </TableCell>
                <TableCell>{transaction.description}</TableCell>
                <TableCell>{transaction.clientName || 'N/A'}</TableCell>
                <TableCell>
                  {transaction.account || '-'}
                </TableCell>
                <TableCell 
                  align="right" 
                  sx={{ 
                    color: transaction.amount < 0 ? 'error.main' : 'success.main', 
                    fontWeight: 'bold' 
                  }}
                >
                  {formatCurrency(transaction.amount)}
                </TableCell>
                <TableCell>
                  <Chip 
                    label={getStatusLabel(transaction.status)} 
                    color={getStatusColor(transaction.status) as any}
                    size="small"
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {filteredTransactions.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="body1" color="text.secondary">
            Aucune transaction trouvée
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default TransactionsListFixed;

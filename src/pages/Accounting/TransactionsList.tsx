import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  TextField,
  Button,
  Chip,
  IconButton,
  Tooltip,
  Menu,
  MenuItem,
  FormControl,
  InputLabel,
  Select,
  Grid,
  Alert,
  CircularProgress,
  TablePagination,
  InputAdornment,
} from '@mui/material';
import {
  Search,
  FilterList,
  MoreVert,
  Visibility,
  Download,
  Refresh,
} from '@mui/icons-material';
import { theme } from '../../theme';
import { accountingDataService } from '../../services/accountingDataService';
import { AccountingTransaction, AccountingFilters } from '../../types/accounting';
import { useCurrencyFormatter } from '../../utils/currency';

const TransactionsList: React.FC = () => {
  const [transactions, setTransactions] = useState<AccountingTransaction[]>([]);
  const [filteredTransactions, setFilteredTransactions] = useState<AccountingTransaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedTransaction, setSelectedTransaction] = useState<AccountingTransaction | null>(null);

  useEffect(() => {
    loadTransactions();
  }, []);

  useEffect(() => {
    filterTransactions();
  }, [transactions, searchTerm, typeFilter, statusFilter]);

  const loadTransactions = async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      const result = await accountingDataService.getAllTransactions();
      
      if (result.success && result.data) {
        setTransactions(result.data);
      } else {
        setError(result.error || 'Erreur lors du chargement des transactions');
      }
    } catch (err) {
      console.error('Erreur lors du chargement des transactions:', err);
      setError('Erreur lors du chargement des transactions');
    } finally {
      setIsLoading(false);
    }
  };

  const filterTransactions = () => {
    let filtered = transactions;

    // Filtre par terme de recherche
    if (searchTerm) {
      filtered = filtered.filter(transaction =>
        transaction.clientName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        transaction.id.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Filtre par type
    if (typeFilter !== 'all') {
      filtered = filtered.filter(transaction => transaction.type === typeFilter);
    }

    // Filtre par statut
    if (statusFilter !== 'all') {
      if (statusFilter === 'paid') {
        filtered = filtered.filter(transaction => transaction.isPaid);
      } else if (statusFilter === 'pending') {
        filtered = filtered.filter(transaction => !transaction.isPaid);
      }
    }

    setFilteredTransactions(filtered);
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, transaction: AccountingTransaction) => {
    setAnchorEl(event.currentTarget);
    setSelectedTransaction(transaction);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedTransaction(null);
  };

  const handleViewDetails = () => {
    // Implémenter la vue des détails
    console.log('Voir détails:', selectedTransaction);
    handleMenuClose();
  };

  const handleExportTransaction = () => {
    // Implémenter l'export de la transaction
    console.log('Exporter transaction:', selectedTransaction);
    handleMenuClose();
  };

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  if (isLoading) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '50vh',
        flexDirection: 'column',
        gap: 2
      }}>
        <CircularProgress size={40} />
        <Typography variant="h6" color="text.secondary">
          Chargement des transactions...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        <Typography variant="h6" gutterBottom>
          Erreur de chargement
        </Typography>
        <Typography>
          {error}
        </Typography>
      </Alert>
    );
  }

  const paginatedTransactions = filteredTransactions.slice(
    page * rowsPerPage,
    page * rowsPerPage + rowsPerPage
  );

  return (
    <Box>
      {/* En-tête avec actions */}
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        mb: 3 
      }}>
        <Typography variant="h4" sx={{ fontWeight: 600 }}>
          Transactions
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadTransactions}
          >
            Actualiser
          </Button>
          <Button
            variant="contained"
            startIcon={<Download />}
            color="primary"
          >
            Exporter
          </Button>
        </Box>
      </Box>

      {/* Filtres */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Rechercher par client ou ID..."
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
              <FormControl fullWidth>
                <InputLabel>Type</InputLabel>
                <Select
                  value={typeFilter}
                  onChange={(e) => setTypeFilter(e.target.value)}
                  label="Type"
                >
                  <MenuItem value="all">Tous</MenuItem>
                  <MenuItem value="sale">Ventes</MenuItem>
                  <MenuItem value="repair">Réparations</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Statut</InputLabel>
                <Select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  label="Statut"
                >
                  <MenuItem value="all">Tous</MenuItem>
                  <MenuItem value="paid">Payé</MenuItem>
                  <MenuItem value="pending">En attente</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <Button
                fullWidth
                variant="outlined"
                startIcon={<FilterList />}
                onClick={() => {
                  setSearchTerm('');
                  setTypeFilter('all');
                  setStatusFilter('all');
                }}
              >
                Réinitialiser
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Tableau des transactions */}
      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Date</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Client</TableCell>
                <TableCell align="right">Montant</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Méthode de paiement</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginatedTransactions.map((transaction) => (
                <TableRow key={transaction.id} hover>
                  <TableCell>
                    {transaction.date.toLocaleDateString('fr-FR')}
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={transaction.type === 'sale' ? 'Vente' : 'Réparation'}
                      color={transaction.type === 'sale' ? 'success' : 'primary'}
                      variant="outlined"
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {transaction.clientName}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="subtitle1" sx={{ fontWeight: 600, color: 'primary.main' }}>
                      {formatCurrency(transaction.amount)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={transaction.isPaid ? 'Payé' : 'En attente'}
                      color={transaction.isPaid ? 'success' : 'warning'}
                      variant="filled"
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    {transaction.paymentMethod || 'N/A'}
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      onClick={(e) => handleMenuOpen(e, transaction)}
                      size="small"
                    >
                      <MoreVert />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          rowsPerPageOptions={[10, 25, 50, 100]}
          component="div"
          count={filteredTransactions.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Lignes par page:"
          labelDisplayedRows={({ from, to, count }) => 
            `${from}-${to} sur ${count !== -1 ? count : `plus de ${to}`}`
          }
        />
      </Card>

      {/* Menu contextuel */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
      >
        <MenuItem onClick={handleViewDetails}>
          <Visibility sx={{ mr: 1 }} />
          Voir les détails
        </MenuItem>
        <MenuItem onClick={handleExportTransaction}>
          <Download sx={{ mr: 1 }} />
          Exporter
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default TransactionsList;

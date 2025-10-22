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
  Avatar,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Divider,
} from '@mui/material';
import {
  Search,
  FilterList,
  MoreVert,
  Visibility,
  Download,
  Refresh,
  AttachMoney,
  TrendingUp,
  TrendingDown,
  Category,
} from '@mui/icons-material';
import { theme } from '../../theme';
import { accountingDataService } from '../../services/accountingDataService';
import { ExpenseSummary, AccountingFilters } from '../../types/accounting';
import { useCurrencyFormatter } from '../../utils/currency';

const ExpensesView: React.FC = () => {
  const [expenseSummary, setExpenseSummary] = useState<ExpenseSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [paymentMethodFilter, setPaymentMethodFilter] = useState<string>('all');

  useEffect(() => {
    loadExpenseSummary();
  }, []);

  const loadExpenseSummary = async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      const result = await accountingDataService.getExpenseSummary();
      
      if (result.success && result.data) {
        setExpenseSummary(result.data);
      } else {
        setError(result.error || 'Erreur lors du chargement des dépenses');
      }
    } catch (err) {
      console.error('Erreur lors du chargement des dépenses:', err);
      setError('Erreur lors du chargement des dépenses');
    } finally {
      setIsLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const formatPercentage = (value: number, total: number) => {
    return ((value / total) * 100).toFixed(1);
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
          Chargement des dépenses...
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

  if (!expenseSummary) {
    return (
      <Alert severity="info">
        Aucune donnée de dépenses disponible pour le moment.
      </Alert>
    );
  }

  const {
    totalExpenses,
    monthlyExpenses,
    expenseCount,
    averageExpense,
    byPaymentMethod,
    pendingExpenses,
    paidExpenses
  } = expenseSummary;

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
          Dépenses
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadExpenseSummary}
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

      {/* Statistiques principales */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <AttachMoney sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Total dépenses
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {formatCurrency(totalExpenses)}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                Toutes les dépenses
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
            color: 'white'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <TrendingUp sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Dépenses mensuelles
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {formatCurrency(monthlyExpenses)}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                Ce mois-ci
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
            color: 'white'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Category sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Nombre de dépenses
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {expenseCount}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                Dépenses enregistrées
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
            color: 'white'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <TrendingDown sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Moyenne
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {formatCurrency(averageExpense)}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                Par dépense
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        {/* Répartition par méthode de paiement */}
        <Grid item xs={12} md={6}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <AttachMoney sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Par méthode de paiement
                </Typography>
              </Box>
              
              {Object.keys(byPaymentMethod).length > 0 ? (
                <List>
                  {Object.entries(byPaymentMethod).map(([method, amount], index) => (
                    <React.Fragment key={method}>
                      <ListItem sx={{ px: 0 }}>
                        <ListItemAvatar>
                          <Avatar sx={{ 
                            bgcolor: 'primary.main',
                            width: 40,
                            height: 40
                          }}>
                            {method.charAt(0).toUpperCase()}
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="subtitle1" sx={{ fontWeight: 600, textTransform: 'capitalize' }}>
                                {method}
                              </Typography>
                              <Typography variant="h6" sx={{ fontWeight: 700, color: 'primary.main' }}>
                                {formatCurrency(amount)}
                              </Typography>
                            </Box>
                          }
                          secondary={
                            <Typography variant="body2" color="text.secondary">
                              {formatPercentage(amount, totalExpenses)}% du total
                            </Typography>
                          }
                        />
                      </ListItem>
                      {index < Object.keys(byPaymentMethod).length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              ) : (
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body1" color="text.secondary">
                    Aucune donnée de paiement disponible
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Statut des dépenses */}
        <Grid item xs={12} md={6}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <Category sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Statut des dépenses
                </Typography>
              </Box>
              
              <List>
                <ListItem sx={{ px: 0 }}>
                  <ListItemAvatar>
                    <Avatar sx={{ 
                      bgcolor: 'success.main',
                      width: 40,
                      height: 40
                    }}>
                      ✓
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary={
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                          Dépenses payées
                        </Typography>
                        <Typography variant="h6" sx={{ fontWeight: 700, color: 'success.main' }}>
                          {paidExpenses}
                        </Typography>
                      </Box>
                    }
                    secondary={
                      <Typography variant="body2" color="text.secondary">
                        {formatPercentage(paidExpenses, expenseCount)}% du total
                      </Typography>
                    }
                  />
                </ListItem>
                
                <Divider />
                
                <ListItem sx={{ px: 0 }}>
                  <ListItemAvatar>
                    <Avatar sx={{ 
                      bgcolor: 'warning.main',
                      width: 40,
                      height: 40
                    }}>
                      ⏳
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary={
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                          Dépenses en attente
                        </Typography>
                        <Typography variant="h6" sx={{ fontWeight: 700, color: 'warning.main' }}>
                          {pendingExpenses}
                        </Typography>
                      </Box>
                    }
                    secondary={
                      <Typography variant="body2" color="text.secondary">
                        {formatPercentage(pendingExpenses, expenseCount)}% du total
                      </Typography>
                    }
                  />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filtres et recherche */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
            Filtres et recherche
          </Typography>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Rechercher dans les dépenses..."
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
                <InputLabel>Statut</InputLabel>
                <Select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  label="Statut"
                >
                  <MenuItem value="all">Tous</MenuItem>
                  <MenuItem value="paid">Payées</MenuItem>
                  <MenuItem value="pending">En attente</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Méthode de paiement</InputLabel>
                <Select
                  value={paymentMethodFilter}
                  onChange={(e) => setPaymentMethodFilter(e.target.value)}
                  label="Méthode de paiement"
                >
                  <MenuItem value="all">Toutes</MenuItem>
                  <MenuItem value="cash">Espèces</MenuItem>
                  <MenuItem value="card">Carte</MenuItem>
                  <MenuItem value="transfer">Virement</MenuItem>
                  <MenuItem value="check">Chèque</MenuItem>
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
                  setStatusFilter('all');
                  setCategoryFilter('all');
                  setPaymentMethodFilter('all');
                }}
              >
                Réinitialiser
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
};

export default ExpensesView;

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
  Button,
  Card,
  CardContent,
} from '@mui/material';
import { Search, Add, AttachMoney } from '@mui/icons-material';
import { useAppStore } from '../../store';

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

const ExpensesViewFixed: React.FC = () => {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [filteredExpenses, setFilteredExpenses] = useState<Expense[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>('all');

  useEffect(() => {
    loadRealExpenses();
  }, []);

  const loadRealExpenses = async () => {
    try {
      // Utiliser les vraies données du store
      const { expenses } = useAppStore.getState();
      
      const realExpenses: Expense[] = expenses.map(expense => ({
        id: expense.id,
        title: expense.title,
        description: expense.description,
        amount: expense.amount,
        expenseDate: new Date(expense.expenseDate).toISOString().split('T')[0],
        category: expense.tags?.[0] || 'Général',
        paymentMethod: expense.paymentMethod || 'Espèces',
        supplier: expense.supplier || 'N/A',
        status: expense.status
      }));

      // Trier par date (plus récent en premier)
      realExpenses.sort((a, b) => new Date(b.expenseDate).getTime() - new Date(a.expenseDate).getTime());

      setExpenses(realExpenses);
      setFilteredExpenses(realExpenses);
    } catch (error) {
      console.error('Erreur lors du chargement des dépenses:', error);
      // Fallback sur des données vides
      setExpenses([]);
      setFilteredExpenses([]);
    }
  };

  useEffect(() => {
    let filtered = expenses;

    // Filtrage par recherche
    if (searchTerm) {
      filtered = filtered.filter(expense =>
        expense.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        expense.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
        expense.supplier.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Filtrage par catégorie
    if (filterCategory !== 'all') {
      filtered = filtered.filter(expense => expense.category === filterCategory);
    }

    setFilteredExpenses(filtered);
  }, [expenses, searchTerm, filterCategory]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return 'success';
      case 'pending': return 'warning';
      case 'reimbursed': return 'info';
      case 'returned': return 'secondary';
      default: return 'default';
    };
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'paid': return 'Payée';
      case 'pending': return 'En attente';
      case 'reimbursed': return 'Remboursée';
      case 'returned': return 'Restituée';
      default: return status;
    };
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const totalExpenses = expenses.reduce((sum, expense) => sum + expense.amount, 0);
  const paidExpenses = expenses.filter(e => e.status === 'paid').reduce((sum, expense) => sum + expense.amount, 0);
  const pendingExpenses = expenses.filter(e => e.status === 'pending').reduce((sum, expense) => sum + expense.amount, 0);

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 'medium' }}>
          Gestion des Dépenses
        </Typography>
        <Button variant="contained" color="primary" startIcon={<Add />}>
          Nouvelle Dépense
        </Button>
      </Box>

      {/* Statistiques rapides */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <AttachMoney sx={{ fontSize: 32, mr: 2, color: 'error.main' }} />
                <Box>
                  <Typography variant="h6" color="error.main">
                    {formatCurrency(totalExpenses)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total des dépenses
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <AttachMoney sx={{ fontSize: 32, mr: 2, color: 'success.main' }} />
                <Box>
                  <Typography variant="h6" color="success.main">
                    {formatCurrency(paidExpenses)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Dépenses payées
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <AttachMoney sx={{ fontSize: 32, mr: 2, color: 'warning.main' }} />
                <Box>
                  <Typography variant="h6" color="warning.main">
                    {formatCurrency(pendingExpenses)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    En attente de paiement
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filtres */}
      <Paper elevation={1} sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={6}>
            <TextField
              label="Rechercher une dépense"
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
              <InputLabel>Catégorie</InputLabel>
              <Select
                value={filterCategory}
                label="Catégorie"
                onChange={(e) => setFilterCategory(e.target.value)}
              >
                <MenuItem value="all">Toutes</MenuItem>
                <MenuItem value="Pièces détachées">Pièces détachées</MenuItem>
                <MenuItem value="Formation">Formation</MenuItem>
                <MenuItem value="Outillage">Outillage</MenuItem>
                <MenuItem value="Marketing">Marketing</MenuItem>
                <MenuItem value="Assurance">Assurance</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Paper>

      {/* Tableau des dépenses */}
      <TableContainer component={Paper} elevation={1}>
        <Table sx={{ minWidth: 650 }} aria-label="expenses table">
          <TableHead>
            <TableRow>
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
              <TableRow
                key={expense.id}
                sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
              >
                <TableCell component="th" scope="row">
                  <Box>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {expense.title}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {expense.description}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip label={expense.category} color="primary" size="small" />
                </TableCell>
                <TableCell>{expense.supplier}</TableCell>
                <TableCell>{new Date(expense.expenseDate).toLocaleDateString('fr-FR')}</TableCell>
                <TableCell align="right" sx={{ fontWeight: 600, color: 'error.main' }}>
                  {formatCurrency(expense.amount)}
                </TableCell>
                <TableCell>{expense.paymentMethod}</TableCell>
                <TableCell>
                  <Chip 
                    label={getStatusLabel(expense.status)} 
                    color={getStatusColor(expense.status) as any}
                    size="small"
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {filteredExpenses.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="body1" color="text.secondary">
            Aucune dépense trouvée
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default ExpensesViewFixed;

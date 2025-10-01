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
  Paper,
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
  Alert,
  InputAdornment,
  Tooltip,
  Badge,
  Avatar,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  MonetizationOn as MonetizationOnIcon,
  CalendarToday as CalendarTodayIcon,
  Assessment as AssessmentIcon,
  Receipt as ReceiptIcon,
  Payment as PaymentIcon,
  Euro as EuroIcon,
  AttachMoney as AttachMoneyIcon,
  Visibility as VisibilityIcon,
  Download as DownloadIcon,
  Print as PrintIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Expense } from '../../types';
import toast from 'react-hot-toast';


const Expenses: React.FC = () => {
  const {
    expenses,
    expenseStats,
    loadExpenses,
    loadExpenseStats,
    addExpense,
    updateExpense,
    deleteExpense,
  } = useAppStore();

  const [newExpenseDialogOpen, setNewExpenseDialogOpen] = useState(false);
  const [editExpenseDialogOpen, setEditExpenseDialogOpen] = useState(false);
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [dateRangeFilter, setDateRangeFilter] = useState<string>('all');

  // Formulaire de dépense
  const [expenseForm, setExpenseForm] = useState({
    title: '',
    description: '',
    amount: '',
    supplier: '',
    invoiceNumber: '',
    paymentMethod: 'card' as 'cash' | 'card' | 'transfer' | 'check',
    status: 'pending' as 'pending' | 'paid' | 'cancelled',
    expenseDate: format(new Date(), 'yyyy-MM-dd'),
    dueDate: '',
    tags: [] as string[],
  });

  useEffect(() => {
    const initializeExpenses = async () => {
      await loadExpenses();
      await loadExpenseStats();
    };
    
    initializeExpenses();
  }, [loadExpenses, loadExpenseStats]);

  // Filtrage des dépenses
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
          case 'today':
            matchesDate = expenseDate.toDateString() === now.toDateString();
            break;
          case 'week':
            const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            matchesDate = expenseDate >= weekAgo;
            break;
          case 'month':
            const monthAgo = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
            matchesDate = expenseDate >= monthAgo;
            break;
          case 'year':
            const yearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
            matchesDate = expenseDate >= yearAgo;
            break;
        }
      }
      
      return matchesSearch && matchesStatus && matchesDate;
    });
  }, [expenses, searchQuery, statusFilter, dateRangeFilter]);



  const resetExpenseForm = () => {
    setExpenseForm({
      title: '',
      description: '',
      amount: '',
      supplier: '',
      invoiceNumber: '',
      paymentMethod: 'card',
      status: 'pending',
      expenseDate: format(new Date(), 'yyyy-MM-dd'),
      dueDate: '',
      tags: [],
    });
  };

  const handleCreateExpense = async () => {
    if (!expenseForm.title || !expenseForm.amount) {
      toast.error('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      await addExpense({
        title: expenseForm.title,
        description: expenseForm.description || undefined,
        amount: parseFloat(expenseForm.amount),
        category: {
          id: '', // Sera généré automatiquement par le service
          name: 'General',
          description: 'Catégorie par défaut',
          color: '#757575',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        },
        supplier: expenseForm.supplier || undefined,
        invoiceNumber: expenseForm.invoiceNumber || undefined,
        paymentMethod: expenseForm.paymentMethod,
        status: expenseForm.status,
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
        toast.error('Aucune catégorie de dépense disponible. Veuillez d\'abord créer une catégorie dans les paramètres.');
      } else {
        toast.error('Erreur lors de la création de la dépense');
      }
      console.error(error);
    }
  };

  const handleUpdateExpense = async () => {
    if (!selectedExpense || !expenseForm.title || !expenseForm.amount) {
      toast.error('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      await updateExpense(selectedExpense.id, {
        title: expenseForm.title,
        description: expenseForm.description || undefined,
        amount: parseFloat(expenseForm.amount),
        category: {
          id: '', // Sera généré automatiquement par le service
          name: 'General',
          description: 'Catégorie par défaut',
          color: '#757575',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        },
        supplier: expenseForm.supplier || undefined,
        invoiceNumber: expenseForm.invoiceNumber || undefined,
        paymentMethod: expenseForm.paymentMethod,
        status: expenseForm.status,
        expenseDate: new Date(expenseForm.expenseDate),
        dueDate: expenseForm.dueDate ? new Date(expenseForm.dueDate) : undefined,
        tags: expenseForm.tags,
      });

      toast.success('Dépense mise à jour avec succès');
      setEditExpenseDialogOpen(false);
      setSelectedExpense(null);
      resetExpenseForm();
      loadExpenseStats();
    } catch (error) {
      toast.error('Erreur lors de la mise à jour de la dépense');
      console.error(error);
    }
  };

  const handleDeleteExpense = async (expense: Expense) => {
    if (window.confirm(`Êtes-vous sûr de vouloir supprimer la dépense "${expense.title}" ?`)) {
      try {
        await deleteExpense(expense.id);
        toast.success('Dépense supprimée avec succès');
        loadExpenseStats();
      } catch (error) {
        toast.error('Erreur lors de la suppression de la dépense');
        console.error(error);
      }
    }
  };

  const openEditExpenseDialog = (expense: Expense) => {
    setSelectedExpense(expense);
    setExpenseForm({
      title: expense.title,
      description: expense.description || '',
      amount: expense.amount.toString(),
      supplier: expense.supplier || '',
      invoiceNumber: expense.invoiceNumber || '',
      paymentMethod: expense.paymentMethod,
      status: expense.status,
      expenseDate: format(expense.expenseDate, 'yyyy-MM-dd'),
      dueDate: expense.dueDate ? format(expense.dueDate, 'yyyy-MM-dd') : '',
      tags: expense.tags || [],
    });
    setEditExpenseDialogOpen(true);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return 'success';
      case 'pending': return 'warning';
      case 'cancelled': return 'error';
      default: return 'default';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'paid': return 'Payé';
      case 'pending': return 'En attente';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  };

  const getPaymentMethodLabel = (method: string) => {
    switch (method) {
      case 'cash': return 'Espèces';
      case 'card': return 'Carte bancaire';
      case 'transfer': return 'Virement';
      case 'check': return 'Chèque';
      default: return method;
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" component="h1" gutterBottom>
            Gestion des Dépenses
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Gérez vos dépenses
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            resetExpenseForm();
            setNewExpenseDialogOpen(true);
          }}
          sx={{ mr: 1 }}
        >
          Nouvelle Dépense
        </Button>
      </Box>

      {/* Statistiques */}
      {expenseStats && (
        <Grid container spacing={3} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                    <MonetizationOnIcon />
                  </Avatar>
                  <Box>
                    <Typography color="text.secondary" gutterBottom>
                      Total Dépenses
                    </Typography>
                    <Typography variant="h5">
                      {expenseStats.total.toFixed(2)} €
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <Avatar sx={{ bgcolor: 'success.main', mr: 2 }}>
                    <TrendingUpIcon />
                  </Avatar>
                  <Box>
                    <Typography color="text.secondary" gutterBottom>
                      Ce Mois
                    </Typography>
                    <Typography variant="h5">
                      {expenseStats.monthly.toFixed(2)} €
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <Avatar sx={{ bgcolor: 'warning.main', mr: 2 }}>
                    <TrendingDownIcon />
                  </Avatar>
                  <Box>
                    <Typography color="text.secondary" gutterBottom>
                      En Attente
                    </Typography>
                    <Typography variant="h5">
                      {expenseStats.pending.toFixed(2)} €
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <Avatar sx={{ bgcolor: 'info.main', mr: 2 }}>
                    <AssessmentIcon />
                  </Avatar>
                  <Box>
                    <Typography color="text.secondary" gutterBottom>
                      Payé
                    </Typography>
                    <Typography variant="h5">
                      {expenseStats.paid.toFixed(2)} €
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}


        {/* Filtres */}
        <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
          <TextField
            placeholder="Rechercher..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
            sx={{ minWidth: 200 }}
          />
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Statut</InputLabel>
            <Select
              value={statusFilter}
              label="Statut"
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <MenuItem value="all">Tous</MenuItem>
              <MenuItem value="pending">En attente</MenuItem>
              <MenuItem value="paid">Payé</MenuItem>
              <MenuItem value="cancelled">Annulé</MenuItem>
            </Select>
          </FormControl>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Période</InputLabel>
            <Select
              value={dateRangeFilter}
              label="Période"
              onChange={(e) => setDateRangeFilter(e.target.value)}
            >
              <MenuItem value="all">Toutes</MenuItem>
              <MenuItem value="today">Aujourd'hui</MenuItem>
              <MenuItem value="week">Cette semaine</MenuItem>
              <MenuItem value="month">Ce mois</MenuItem>
              <MenuItem value="year">Cette année</MenuItem>
            </Select>
          </FormControl>
        </Box>

        {/* Liste des dépenses */}
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Titre</TableCell>
                <TableCell>Montant</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Méthode de paiement</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredExpenses.map((expense) => (
                <TableRow key={expense.id}>
                  <TableCell>
                    <Box>
                      <Typography variant="subtitle2">{expense.title}</Typography>
                      {expense.description && (
                        <Typography variant="body2" color="text.secondary">
                          {expense.description}
                        </Typography>
                      )}
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="subtitle2" fontWeight="bold">
                      {expense.amount.toFixed(2)} €
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(expense.status)}
                      color={getStatusColor(expense.status) as any}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {format(expense.expenseDate, 'dd/MM/yyyy', { locale: fr })}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {getPaymentMethodLabel(expense.paymentMethod)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <Tooltip title="Modifier">
                        <IconButton
                          size="small"
                          onClick={() => openEditExpenseDialog(expense)}
                        >
                          <EditIcon />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Supprimer">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => handleDeleteExpense(expense)}
                        >
                          <DeleteIcon />
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
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <Typography variant="h6" color="text.secondary">
              Aucune dépense trouvée
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Créez votre première dépense pour commencer
            </Typography>
          </Box>
        )}

      {/* Dialog Nouvelle Dépense */}
      <Dialog 
        open={newExpenseDialogOpen} 
        onClose={() => {
          setNewExpenseDialogOpen(false);
          resetExpenseForm();
        }} 
        maxWidth="md" 
        fullWidth
      >
        <DialogTitle>Nouvelle Dépense</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Titre *"
                value={expenseForm.title}
                onChange={(e) => setExpenseForm({ ...expenseForm, title: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={3}
                value={expenseForm.description}
                onChange={(e) => setExpenseForm({ ...expenseForm, description: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Montant *"
                type="number"
                value={expenseForm.amount}
                onChange={(e) => setExpenseForm({ ...expenseForm, amount: e.target.value })}
                InputProps={{
                  startAdornment: <InputAdornment position="start">€</InputAdornment>,
                }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Fournisseur"
                value={expenseForm.supplier}
                onChange={(e) => setExpenseForm({ ...expenseForm, supplier: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Numéro de facture"
                value={expenseForm.invoiceNumber}
                onChange={(e) => setExpenseForm({ ...expenseForm, invoiceNumber: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Méthode de paiement</InputLabel>
                <Select
                  value={expenseForm.paymentMethod}
                  label="Méthode de paiement"
                  onChange={(e) => setExpenseForm({ ...expenseForm, paymentMethod: e.target.value as any })}
                >
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
                <Select
                  value={expenseForm.status}
                  label="Statut"
                  onChange={(e) => setExpenseForm({ ...expenseForm, status: e.target.value as any })}
                >
                  <MenuItem value="pending">En attente</MenuItem>
                  <MenuItem value="paid">Payé</MenuItem>
                  <MenuItem value="cancelled">Annulé</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Date de dépense"
                type="date"
                value={expenseForm.expenseDate}
                onChange={(e) => setExpenseForm({ ...expenseForm, expenseDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Date d'échéance"
                type="date"
                value={expenseForm.dueDate}
                onChange={(e) => setExpenseForm({ ...expenseForm, dueDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {
            setNewExpenseDialogOpen(false);
            resetExpenseForm();
          }}>Annuler</Button>
          <Button onClick={handleCreateExpense} variant="contained">
            Créer
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog Modifier Dépense */}
      <Dialog open={editExpenseDialogOpen} onClose={() => setEditExpenseDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Modifier la Dépense</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Titre *"
                value={expenseForm.title}
                onChange={(e) => setExpenseForm({ ...expenseForm, title: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={3}
                value={expenseForm.description}
                onChange={(e) => setExpenseForm({ ...expenseForm, description: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Montant *"
                type="number"
                value={expenseForm.amount}
                onChange={(e) => setExpenseForm({ ...expenseForm, amount: e.target.value })}
                InputProps={{
                  startAdornment: <InputAdornment position="start">€</InputAdornment>,
                }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Fournisseur"
                value={expenseForm.supplier}
                onChange={(e) => setExpenseForm({ ...expenseForm, supplier: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Numéro de facture"
                value={expenseForm.invoiceNumber}
                onChange={(e) => setExpenseForm({ ...expenseForm, invoiceNumber: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Méthode de paiement</InputLabel>
                <Select
                  value={expenseForm.paymentMethod}
                  label="Méthode de paiement"
                  onChange={(e) => setExpenseForm({ ...expenseForm, paymentMethod: e.target.value as any })}
                >
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
                <Select
                  value={expenseForm.status}
                  label="Statut"
                  onChange={(e) => setExpenseForm({ ...expenseForm, status: e.target.value as any })}
                >
                  <MenuItem value="pending">En attente</MenuItem>
                  <MenuItem value="paid">Payé</MenuItem>
                  <MenuItem value="cancelled">Annulé</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Date de dépense"
                type="date"
                value={expenseForm.expenseDate}
                onChange={(e) => setExpenseForm({ ...expenseForm, expenseDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Date d'échéance"
                type="date"
                value={expenseForm.dueDate}
                onChange={(e) => setExpenseForm({ ...expenseForm, dueDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditExpenseDialogOpen(false)}>Annuler</Button>
          <Button onClick={handleUpdateExpense} variant="contained">
            Mettre à jour
          </Button>
        </DialogActions>
      </Dialog>

    </Box>
  );
};

export default Expenses;

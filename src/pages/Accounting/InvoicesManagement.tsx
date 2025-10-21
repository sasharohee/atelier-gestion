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
  Badge,
} from '@mui/material';
import {
  Search,
  FilterList,
  MoreVert,
  Visibility,
  Download,
  Refresh,
  Email,
  Print,
  Edit,
} from '@mui/icons-material';
import { theme } from '../../theme';
import { accountingDataService } from '../../services/accountingDataService';
import { Invoice, AccountingFilters } from '../../types/accounting';

const InvoicesManagement: React.FC = () => {
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [filteredInvoices, setFilteredInvoices] = useState<Invoice[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);

  useEffect(() => {
    loadInvoices();
  }, []);

  useEffect(() => {
    filterInvoices();
  }, [invoices, searchTerm, statusFilter, typeFilter]);

  const loadInvoices = async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      const result = await accountingDataService.getInvoices();
      
      if (result.success && result.data) {
        setInvoices(result.data);
      } else {
        setError(result.error || 'Erreur lors du chargement des factures');
      }
    } catch (err) {
      console.error('Erreur lors du chargement des factures:', err);
      setError('Erreur lors du chargement des factures');
    } finally {
      setIsLoading(false);
    }
  };

  const filterInvoices = () => {
    let filtered = invoices;

    // Filtre par terme de recherche
    if (searchTerm) {
      filtered = filtered.filter(invoice =>
        invoice.clientName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        invoice.invoiceNumber.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Filtre par statut
    if (statusFilter !== 'all') {
      filtered = filtered.filter(invoice => invoice.status === statusFilter);
    }

    // Filtre par type
    if (typeFilter !== 'all') {
      filtered = filtered.filter(invoice => invoice.type === typeFilter);
    }

    setFilteredInvoices(filtered);
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid':
        return 'success';
      case 'sent':
        return 'info';
      case 'overdue':
        return 'error';
      case 'draft':
        return 'default';
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'sent':
        return 'Envoyé';
      case 'overdue':
        return 'En retard';
      case 'draft':
        return 'Brouillon';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, invoice: Invoice) => {
    setAnchorEl(event.currentTarget);
    setSelectedInvoice(invoice);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedInvoice(null);
  };

  const handleViewInvoice = () => {
    console.log('Voir facture:', selectedInvoice);
    handleMenuClose();
  };

  const handleDownloadInvoice = () => {
    console.log('Télécharger facture:', selectedInvoice);
    handleMenuClose();
  };

  const handleEmailInvoice = () => {
    console.log('Envoyer par email:', selectedInvoice);
    handleMenuClose();
  };

  const handlePrintInvoice = () => {
    console.log('Imprimer facture:', selectedInvoice);
    handleMenuClose();
  };

  const handleEditInvoice = () => {
    console.log('Modifier facture:', selectedInvoice);
    handleMenuClose();
  };

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const getInvoiceStats = () => {
    const total = invoices.length;
    const paid = invoices.filter(i => i.status === 'paid').length;
    const pending = invoices.filter(i => i.status === 'sent').length;
    const overdue = invoices.filter(i => i.status === 'overdue').length;
    
    return { total, paid, pending, overdue };
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
          Chargement des factures...
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

  const stats = getInvoiceStats();
  const paginatedInvoices = filteredInvoices.slice(
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
          Gestion des factures
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadInvoices}
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

      {/* Statistiques */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ textAlign: 'center' }}>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 700, color: 'primary.main' }}>
                {stats.total}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total factures
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ textAlign: 'center' }}>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 700, color: 'success.main' }}>
                {stats.paid}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Payées
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ textAlign: 'center' }}>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 700, color: 'info.main' }}>
                {stats.pending}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                En attente
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ textAlign: 'center' }}>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 700, color: 'error.main' }}>
                {stats.overdue}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                En retard
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filtres */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Rechercher par client ou numéro..."
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
                  <MenuItem value="draft">Brouillon</MenuItem>
                  <MenuItem value="sent">Envoyé</MenuItem>
                  <MenuItem value="paid">Payé</MenuItem>
                  <MenuItem value="overdue">En retard</MenuItem>
                  <MenuItem value="cancelled">Annulé</MenuItem>
                </Select>
              </FormControl>
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
            <Grid item xs={12} md={2}>
              <Button
                fullWidth
                variant="outlined"
                startIcon={<FilterList />}
                onClick={() => {
                  setSearchTerm('');
                  setStatusFilter('all');
                  setTypeFilter('all');
                }}
              >
                Réinitialiser
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Tableau des factures */}
      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Numéro</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Client</TableCell>
                <TableCell align="right">Montant HT</TableCell>
                <TableCell align="right">TVA</TableCell>
                <TableCell align="right">Total TTC</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Date d'émission</TableCell>
                <TableCell>Date d'échéance</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginatedInvoices.map((invoice) => (
                <TableRow key={invoice.id} hover>
                  <TableCell>
                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {invoice.invoiceNumber}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={invoice.type === 'sale' ? 'Vente' : 'Réparation'}
                      color={invoice.type === 'sale' ? 'success' : 'primary'}
                      variant="outlined"
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {invoice.clientName}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    {formatCurrency(invoice.amount)}
                  </TableCell>
                  <TableCell align="right">
                    {formatCurrency(invoice.tax)}
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="subtitle1" sx={{ fontWeight: 600, color: 'primary.main' }}>
                      {formatCurrency(invoice.total)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(invoice.status)}
                      color={getStatusColor(invoice.status) as any}
                      variant="filled"
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    {invoice.issueDate.toLocaleDateString('fr-FR')}
                  </TableCell>
                  <TableCell>
                    <Typography 
                      variant="body2"
                      color={invoice.status === 'overdue' ? 'error.main' : 'text.primary'}
                    >
                      {invoice.dueDate.toLocaleDateString('fr-FR')}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      onClick={(e) => handleMenuOpen(e, invoice)}
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
          count={filteredInvoices.length}
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
        <MenuItem onClick={handleViewInvoice}>
          <Visibility sx={{ mr: 1 }} />
          Voir la facture
        </MenuItem>
        <MenuItem onClick={handleDownloadInvoice}>
          <Download sx={{ mr: 1 }} />
          Télécharger PDF
        </MenuItem>
        <MenuItem onClick={handleEmailInvoice}>
          <Email sx={{ mr: 1 }} />
          Envoyer par email
        </MenuItem>
        <MenuItem onClick={handlePrintInvoice}>
          <Print sx={{ mr: 1 }} />
          Imprimer
        </MenuItem>
        <MenuItem onClick={handleEditInvoice}>
          <Edit sx={{ mr: 1 }} />
          Modifier
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default InvoicesManagement;

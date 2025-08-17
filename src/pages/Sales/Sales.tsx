import React, { useState } from 'react';
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
  Chip,
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
} from '@mui/material';
import {
  Add as AddIcon,
  Receipt as ReceiptIcon,
  Print as PrintIcon,
  Email as EmailIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';

const Sales: React.FC = () => {
  const {
    sales,
    clients,
    products,
    services,
    parts,
    getClientById,
  } = useAppStore();

  const [newSaleDialogOpen, setNewSaleDialogOpen] = useState(false);

  const getStatusColor = (status: string) => {
    const colors = {
      pending: 'warning',
      completed: 'success',
      cancelled: 'error',
    };
    return colors[status as keyof typeof colors] || 'default';
  };

  const getStatusLabel = (status: string) => {
    const labels = {
      pending: 'En attente',
      completed: 'Terminée',
      cancelled: 'Annulée',
    };
    return labels[status as keyof typeof labels] || status;
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels = {
      cash: 'Espèces',
      card: 'Carte',
      transfer: 'Virement',
    };
    return labels[method as keyof typeof labels] || method;
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Ventes
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des ventes et facturation
        </Typography>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewSaleDialogOpen(true)}
        >
          Nouvelle vente
        </Button>
      </Box>

      {/* Statistiques rapides */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Ventes du jour
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales.filter(sale => 
                  format(new Date(sale.createdAt), 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd')
                ).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                CA du jour
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales
                  .filter(sale => 
                    format(new Date(sale.createdAt), 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd')
                  )
                  .reduce((sum, sale) => sum + sale.total, 0)
                  .toLocaleString('fr-FR')} €
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Ventes du mois
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales.filter(sale => 
                  format(new Date(sale.createdAt), 'yyyy-MM') === format(new Date(), 'yyyy-MM')
                ).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                CA du mois
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 600 }}>
                {sales
                  .filter(sale => 
                    format(new Date(sale.createdAt), 'yyyy-MM') === format(new Date(), 'yyyy-MM')
                  )
                  .reduce((sum, sale) => sum + sale.total, 0)
                  .toLocaleString('fr-FR')} €
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Liste des ventes */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Historique des ventes
          </Typography>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>N° Vente</TableCell>
                  <TableCell>Client</TableCell>
                  <TableCell>Date</TableCell>
                  <TableCell>Montant</TableCell>
                  <TableCell>Méthode</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {sales
                  .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
                  .map((sale) => {
                    const client = sale.clientId ? getClientById(sale.clientId) : null;
                    return (
                      <TableRow key={sale.id}>
                        <TableCell>{sale.id.slice(0, 8)}</TableCell>
                        <TableCell>
                          {client ? `${client.firstName} ${client.lastName}` : 'Client anonyme'}
                        </TableCell>
                        <TableCell>
                          {format(new Date(sale.createdAt), 'dd/MM/yyyy HH:mm', { locale: fr })}
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {sale.total.toLocaleString('fr-FR')} €
                          </Typography>
                        </TableCell>
                        <TableCell>
                          {getPaymentMethodLabel(sale.paymentMethod)}
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={getStatusLabel(sale.status)}
                            color={getStatusColor(sale.status) as any}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 1 }}>
                            <IconButton size="small" title="Voir facture">
                              <ReceiptIcon fontSize="small" />
                            </IconButton>
                            <IconButton size="small" title="Imprimer">
                              <PrintIcon fontSize="small" />
                            </IconButton>
                            <IconButton size="small" title="Envoyer par email">
                              <EmailIcon fontSize="small" />
                            </IconButton>
                          </Box>
                        </TableCell>
                      </TableRow>
                    );
                  })}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Dialog nouvelle vente */}
      <Dialog open={newSaleDialogOpen} onClose={() => setNewSaleDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nouvelle vente</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Client</InputLabel>
                <Select label="Client">
                  <MenuItem value="">Client anonyme</MenuItem>
                  {clients.map((client) => (
                    <MenuItem key={client.id} value={client.id}>
                      {client.firstName} {client.lastName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Méthode de paiement</InputLabel>
                <Select label="Méthode de paiement">
                  <MenuItem value="cash">Espèces</MenuItem>
                  <MenuItem value="card">Carte</MenuItem>
                  <MenuItem value="transfer">Virement</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Articles
              </Typography>
              <Box sx={{ border: '1px solid', borderColor: 'divider', borderRadius: 1, p: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Sélection des articles à venir...
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewSaleDialogOpen(false)}>Annuler</Button>
          <Button variant="contained">Créer la vente</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Sales;

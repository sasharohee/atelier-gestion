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
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Divider,
} from '@mui/material';
import { Search, Visibility, Download, Close as CloseIcon } from '@mui/icons-material';
import { useAppStore } from '../../store';

interface Invoice {
  id: string;
  invoiceNumber: string;
  clientName: string;
  issueDate: string;
  dueDate: string;
  totalAmount: number;
  status: 'pending' | 'paid' | 'overdue' | 'cancelled';
  paymentDate?: string;
  paymentMethod?: string;
}

const InvoicesManagementFixed: React.FC = () => {
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [filteredInvoices, setFilteredInvoices] = useState<Invoice[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);

  const { sales, repairs, clients, systemSettings, loadSales, loadRepairs, loadClients, loadSystemSettings } = useAppStore();

  useEffect(() => {
    loadRealInvoices();
    // Charger les paramètres système si nécessaire
    if (systemSettings.length === 0) {
      loadSystemSettings();
    }
  }, []);

  const loadRealInvoices = async () => {
    try {
      // Utiliser les vraies données du store
      const { sales, repairs, clients } = useAppStore.getState();
      
      const realInvoices: Invoice[] = [];

      // Convertir les ventes en factures
      sales.forEach(sale => {
        const client = clients.find(c => c.id === sale.clientId);
        const issueDate = new Date(sale.createdAt);
        const dueDate = new Date(issueDate);
        dueDate.setDate(dueDate.getDate() + 30); // 30 jours d'échéance

        realInvoices.push({
          id: sale.id,
          invoiceNumber: `SALE-${sale.id.substring(0, 8)}`,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          issueDate: issueDate.toISOString().split('T')[0],
          dueDate: dueDate.toISOString().split('T')[0],
          totalAmount: sale.total || 0,
          status: sale.status === 'completed' ? 'paid' : 'pending',
          paymentDate: sale.status === 'completed' ? sale.createdAt : undefined,
          paymentMethod: sale.paymentMethod || 'Espèces'
        });
      });

      // Convertir les réparations en factures
      repairs.forEach(repair => {
        const client = clients.find(c => c.id === repair.clientId);
        const issueDate = new Date(repair.createdAt);
        const dueDate = new Date(issueDate);
        dueDate.setDate(dueDate.getDate() + 30);

        realInvoices.push({
          id: repair.id,
          invoiceNumber: `REP-${repair.id.substring(0, 8)}`,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          issueDate: issueDate.toISOString().split('T')[0],
          dueDate: dueDate.toISOString().split('T')[0],
          totalAmount: repair.totalPrice || 0,
          status: repair.isPaid ? 'paid' : 'pending',
          paymentDate: repair.isPaid ? repair.createdAt : undefined,
          paymentMethod: 'Espèces'
        });
      });

      // Trier par date d'émission (plus récent en premier)
      realInvoices.sort((a, b) => new Date(b.issueDate).getTime() - new Date(a.issueDate).getTime());

      setInvoices(realInvoices);
      setFilteredInvoices(realInvoices);
    } catch (error) {
      console.error('Erreur lors du chargement des factures:', error);
      // Fallback sur des données vides
      setInvoices([]);
      setFilteredInvoices([]);
    }
  };

  useEffect(() => {
    let filtered = invoices;

    // Filtrage par recherche
    if (searchTerm) {
      filtered = filtered.filter(invoice =>
        invoice.invoiceNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
        invoice.clientName.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Filtrage par statut
    if (filterStatus !== 'all') {
      filtered = filtered.filter(invoice => invoice.status === filterStatus);
    }

    setFilteredInvoices(filtered);
  }, [invoices, searchTerm, filterStatus]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return 'success';
      case 'pending': return 'warning';
      case 'overdue': return 'error';
      case 'cancelled': return 'default';
      case 'returned': return 'secondary';
      default: return 'info';
    };
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'paid': return 'Payée';
      case 'pending': return 'En attente';
      case 'overdue': return 'En retard';
      case 'cancelled': return 'Annulée';
      case 'returned': return 'Restituée';
      default: return status;
    };
  };

  // Récupérer le taux de TVA depuis les paramètres système
  const getVatRate = () => {
    const vatSetting = systemSettings.find(s => s.key === 'vat_rate');
    return vatSetting ? parseFloat(vatSetting.value) : 20; // Valeur par défaut 20%
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const handleDownloadInvoice = (invoice: Invoice) => {
    try {
      // Générer le contenu HTML identique à la page Kanban
      const invoiceHTML = `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Facture ${invoice.invoiceNumber}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
            margin: 0; padding: 24px; background: white; color: #333; line-height: 1.6;
        }
        .invoice-container { max-width: 800px; margin: 0 auto; background: white; }
        .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 1px solid #eee; }
        .header h1 { font-size: 24px; font-weight: 600; margin: 0 0 8px 0; color: #333; }
        .header .subtitle { font-size: 14px; color: #666; margin-bottom: 16px; }
        .header .contact-info { font-size: 12px; color: #666; line-height: 1.8; }
        .invoice-details { display: flex; justify-content: space-between; margin-bottom: 40px; }
        .client-section, .invoice-section { flex: 1; }
        .section-title { font-weight: 600; margin-bottom: 12px; color: #333; font-size: 14px; }
        .client-info, .invoice-info { font-size: 14px; color: #666; line-height: 1.6; }
        .client-name { font-weight: 600; color: #333; margin-bottom: 8px; }
        .invoice-number { font-weight: 600; color: #1976d2; font-size: 16px; margin-bottom: 8px; }
        .repair-details { margin-bottom: 30px; }
        .repair-details h3 { margin-bottom: 12px; font-size: 16px; color: #333; }
        .repair-details p { margin-bottom: 8px; font-size: 14px; }
        .totals-section { margin-bottom: 30px; }
        .total-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
        .total-row:last-child { font-weight: 600; font-size: 16px; color: #1976d2; border-top: 1px solid #eee; padding-top: 8px; }
        .conditions { background-color: #f8f9fa; padding: 20px; border-radius: 4px; margin-bottom: 30px; }
        .conditions h3 { margin-bottom: 12px; font-size: 16px; color: #333; }
        .conditions ul { list-style: none; padding: 0; }
        .conditions li { margin-bottom: 6px; font-size: 14px; color: #666; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; }
        .footer h3 { margin-bottom: 8px; font-size: 18px; color: #333; }
        .footer p { font-size: 12px; color: #666; margin-bottom: 4px; }
        .thank-you { font-weight: 600; color: #1976d2; margin-top: 12px; }
    </style>
</head>
<body>
    <div class="invoice-container">
        <div class="header">
            <h1>Atelier de réparation</h1>
            <div class="contact-info">
                Tél: 07 59 23 91 70 • Email: contact.ateliergestion@gmail.com
            </div>
        </div>

        <div class="invoice-details">
            <div class="client-section">
                <div class="section-title">FACTURÉ À</div>
                <div class="client-info">
                    <div class="client-name">${invoice.clientName}</div>
                    <div>Client de l'atelier</div>
                </div>
            </div>
            
            <div class="invoice-section">
                <div class="section-title">DÉTAILS DE LA FACTURE</div>
                <div class="invoice-info">
                    <div class="invoice-number">#${invoice.invoiceNumber}</div>
                    <div><strong>Date :</strong> ${new Date(invoice.issueDate).toLocaleDateString('fr-FR')}</div>
                    <div><strong>Statut :</strong> ${getStatusLabel(invoice.status)}</div>
                    <div><strong>Paiement :</strong> ${invoice.paymentDate ? 'Payé' : 'Non payé'}</div>
                </div>
            </div>
        </div>

        <div class="repair-details">
            <h3>Détails de la prestation</h3>
            <p><strong>Prix de la prestation (TTC) :</strong> ${formatCurrency(invoice.totalAmount)}</p>
        </div>

        <div class="totals-section">
            <div class="total-row">
                <span>Sous-total HT :</span>
                <span>${(invoice.totalAmount / (1 + getVatRate() / 100)).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €</span>
            </div>
            <div class="total-row">
                <span>TVA (${getVatRate()}%) :</span>
                <span>${(invoice.totalAmount - (invoice.totalAmount / (1 + getVatRate() / 100))).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €</span>
            </div>
            <div class="total-row">
                <span>TOTAL TTC :</span>
                <span>${formatCurrency(invoice.totalAmount)}</span>
            </div>
        </div>

        <div class="conditions">
            <h3>CONDITIONS DE PAIEMENT</h3>
            <ul>
                <li>Facture valable 30 jours à compter de la date d'émission</li>
                <li>Aucun escompte en cas de paiement anticipé</li>
                <li>Pour toute question, contactez-nous au 07 59 23 91 70 ou par email à contact.ateliergestion@gmail.com</li>
            </ul>
        </div>

        <div class="footer">
            <h3>Atelier de réparation</h3>
            <p>Tél: 07 59 23 91 70 • Email: contact.ateliergestion@gmail.com</p>
            <div class="thank-you">Merci de votre confiance !</div>
        </div>
    </div>
</body>
</html>`;

      // Créer et télécharger le fichier HTML
      const blob = new Blob([invoiceHTML], { type: 'text/html;charset=utf-8;' });
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute('download', `Facture_${invoice.invoiceNumber}.html`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
    } catch (error) {
      console.error('Erreur lors du téléchargement:', error);
      alert('Erreur lors du téléchargement de la facture');
    }
  };

  const handleViewInvoice = (invoice: Invoice) => {
    setSelectedInvoice(invoice);
    setViewDialogOpen(true);
  };


  const handleCloseDialogs = () => {
    setViewDialogOpen(false);
    setSelectedInvoice(null);
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 'medium' }}>
          Gestion des Factures
        </Typography>
        <Button variant="contained" color="primary">
          Nouvelle Facture
        </Button>
      </Box>

      {/* Filtres */}
      <Paper elevation={1} sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={6}>
            <TextField
              label="Rechercher une facture"
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
              <InputLabel>Statut</InputLabel>
              <Select
                value={filterStatus}
                label="Statut"
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="pending">En attente</MenuItem>
                <MenuItem value="paid">Payée</MenuItem>
                <MenuItem value="overdue">En retard</MenuItem>
                <MenuItem value="cancelled">Annulée</MenuItem>
                <MenuItem value="returned">Restituée</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Paper>

      {/* Tableau des factures */}
      <TableContainer component={Paper} elevation={1}>
        <Table sx={{ minWidth: 650 }} aria-label="invoices table">
          <TableHead>
            <TableRow>
              <TableCell>Numéro Facture</TableCell>
              <TableCell>Client</TableCell>
              <TableCell>Date Émission</TableCell>
              <TableCell>Date Échéance</TableCell>
              <TableCell align="right">Montant Total</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredInvoices.map((invoice) => (
              <TableRow
                key={invoice.id}
                sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
              >
                <TableCell component="th" scope="row">
                  {invoice.invoiceNumber}
                </TableCell>
                <TableCell>{invoice.clientName}</TableCell>
                <TableCell>{new Date(invoice.issueDate).toLocaleDateString('fr-FR')}</TableCell>
                <TableCell>{new Date(invoice.dueDate).toLocaleDateString('fr-FR')}</TableCell>
                <TableCell align="right">{formatCurrency(invoice.totalAmount)}</TableCell>
                <TableCell>
                  <Chip 
                    label={getStatusLabel(invoice.status)} 
                    color={getStatusColor(invoice.status) as any}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <IconButton 
                      size="small" 
                      title="Voir"
                      onClick={() => handleViewInvoice(invoice)}
                    >
                      <Visibility />
                    </IconButton>
                    <IconButton 
                      size="small" 
                      title="Télécharger"
                      onClick={() => handleDownloadInvoice(invoice)}
                    >
                      <Download />
                    </IconButton>
                  </Box>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {filteredInvoices.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="body1" color="text.secondary">
            Aucune facture trouvée
          </Typography>
        </Box>
      )}

      {/* Dialogue de visualisation - Aperçu de facture identique au Kanban */}
      <Dialog open={viewDialogOpen} onClose={handleCloseDialogs} maxWidth="md" fullWidth>
        <DialogTitle>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6">
              Facture #{selectedInvoice?.invoiceNumber}
            </Typography>
            <Box>
              <IconButton onClick={() => selectedInvoice && handleDownloadInvoice(selectedInvoice)} title="Télécharger">
                <Download />
              </IconButton>
              <IconButton onClick={handleCloseDialogs} title="Fermer">
                <CloseIcon />
              </IconButton>
            </Box>
          </Box>
        </DialogTitle>
        <DialogContent>
          {selectedInvoice && (
            <Box 
              sx={{ 
                fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
                backgroundColor: 'white',
                p: 3
              }}
            >
              <Box sx={{ maxWidth: '800px', mx: 'auto' }}>
                
                {/* En-tête simple - identique au Kanban */}
                <Box sx={{ 
                  textAlign: 'center', 
                  mb: 5, 
                  pb: 2.5, 
                  borderBottom: '1px solid #eee' 
                }}>
                  <Typography variant="h4" sx={{ 
                    fontWeight: 600, 
                    mb: 1, 
                    color: '#333',
                    fontSize: '24px'
                  }}>
                    Atelier de réparation
                  </Typography>
                  <Box sx={{ fontSize: '12px', color: '#666', lineHeight: 1.8 }}>
                    <Typography sx={{ mb: 0.5 }}>
                      Tél: 07 59 23 91 70 • Email: contact.ateliergestion@gmail.com
                    </Typography>
                  </Box>
                </Box>
                
                {/* Détails client et facture - identique au Kanban */}
                <Box sx={{ 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  mb: 5, 
                  gap: 5 
                }}>
                  
                  {/* Informations client */}
                  <Box sx={{ flex: 1 }}>
                    <Typography variant="h6" sx={{ 
                      fontWeight: 600, 
                      color: '#333', 
                      mb: 1.5, 
                      pb: 0.5, 
                      borderBottom: '1px solid #eee',
                      fontSize: '16px'
                    }}>
                      FACTURÉ À
                    </Typography>
                    <Typography sx={{ 
                      fontWeight: 600, 
                      fontSize: '14px', 
                      mb: 1, 
                      color: '#333' 
                    }}>
                      {selectedInvoice.clientName}
                    </Typography>
                    <Typography sx={{ fontSize: '14px', color: '#666' }}>
                      Client de l'atelier
                    </Typography>
                  </Box>
                  
                  {/* Détails de la facture */}
                  <Box sx={{ flex: 1 }}>
                    <Typography variant="h6" sx={{ 
                      fontWeight: 600, 
                      color: '#333', 
                      mb: 1.5, 
                      pb: 0.5, 
                      borderBottom: '1px solid #eee',
                      fontSize: '16px'
                    }}>
                      DÉTAILS DE LA FACTURE
                    </Typography>
                    <Typography sx={{ 
                      fontSize: '18px', 
                      fontWeight: 600, 
                      color: '#1976d2', 
                      mb: 1 
                    }}>
                      #{selectedInvoice.invoiceNumber}
                    </Typography>
                    <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                      <strong>Date :</strong> {new Date(selectedInvoice.issueDate).toLocaleDateString('fr-FR')}
                    </Typography>
                    <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                      <strong>Statut :</strong> {getStatusLabel(selectedInvoice.status)}
                    </Typography>
                    <Typography sx={{ fontSize: '14px', color: '#666' }}>
                      <strong>Paiement :</strong> {selectedInvoice.paymentDate ? 'Payé' : 'Non payé'}
                    </Typography>
                  </Box>
                </Box>

                {/* Détails de la prestation - identique au Kanban */}
                <Box sx={{ mb: 5 }}>
                  <Typography variant="h6" sx={{ 
                    fontWeight: 600, 
                    color: '#333', 
                    mb: 2, 
                    pb: 0.5, 
                    borderBottom: '1px solid #eee',
                    fontSize: '16px'
                  }}>
                    Détails de la prestation
                  </Typography>
                  <Box sx={{ 
                    p: 2, 
                    backgroundColor: '#f8f9fa', 
                    borderRadius: 1,
                    border: '1px solid #e0e0e0'
                  }}>
                    <Typography sx={{ fontSize: '16px', mb: 1 }}>
                      <strong>Prix de la prestation (TTC) :</strong> {formatCurrency(selectedInvoice.totalAmount)}
                    </Typography>
                  </Box>
                  
                  {/* Totaux - identique au Kanban */}
                  <Box sx={{ 
                    display: 'flex', 
                    flexDirection: 'column', 
                    alignItems: 'flex-end', 
                    mb: 5 
                  }}>
                    <Box sx={{ 
                      width: '300px',
                      p: 2,
                      backgroundColor: '#f8f9fa',
                      borderRadius: 1,
                      border: '1px solid #e0e0e0'
                    }}>
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        mb: 1 
                      }}>
                        <Typography sx={{ fontWeight: 600, fontSize: '16px' }}>
                          Sous-total HT :
                        </Typography>
                        <Typography sx={{ fontWeight: 600, fontSize: '16px' }}>
                          {(selectedInvoice.totalAmount / (1 + getVatRate() / 100)).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €
                        </Typography>
                      </Box>
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        mb: 1 
                      }}>
                        <Typography sx={{ fontSize: '16px' }}>
                          TVA ({getVatRate()}%) :
                        </Typography>
                        <Typography sx={{ fontSize: '16px' }}>
                          {(selectedInvoice.totalAmount - (selectedInvoice.totalAmount / (1 + getVatRate() / 100))).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €
                        </Typography>
                      </Box>
                      <Divider sx={{ my: 1.5, borderColor: '#eee' }} />
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center' 
                      }}>
                        <Typography sx={{ 
                          fontWeight: 600, 
                          fontSize: '16px',
                          color: '#1976d2'
                        }}>
                          TOTAL TTC :
                        </Typography>
                        <Typography sx={{ 
                          fontWeight: 600, 
                          fontSize: '16px',
                          color: '#1976d2'
                        }}>
                          {formatCurrency(selectedInvoice.totalAmount)}
                        </Typography>
                      </Box>
                    </Box>
                  </Box>
                </Box>

                {/* Conditions de paiement - identique au Kanban */}
                <Box sx={{ 
                  mb: 5, 
                  p: 2.5, 
                  backgroundColor: '#f8f9fa', 
                  borderRadius: 1 
                }}>
                  <Typography variant="h6" sx={{ 
                    fontWeight: 600, 
                    mb: 1.5, 
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    CONDITIONS DE PAIEMENT
                  </Typography>
                  <Box component="ul" sx={{ 
                    listStyle: 'none', 
                    p: 0, 
                    m: 0 
                  }}>
                    <Box component="li" sx={{ 
                      color: '#666', 
                      fontSize: '13px', 
                      mb: 0.75, 
                      pl: 2, 
                      position: 'relative',
                      '&:before': {
                        content: '"•"',
                        position: 'absolute',
                        left: 0,
                        color: '#666'
                      }
                    }}>
                      Facture valable 30 jours à compter de la date d'émission
                    </Box>
                    <Box component="li" sx={{ 
                      color: '#666', 
                      fontSize: '13px', 
                      mb: 0.75, 
                      pl: 2, 
                      position: 'relative',
                      '&:before': {
                        content: '"•"',
                        position: 'absolute',
                        left: 0,
                        color: '#666'
                      }
                    }}>
                      Aucun escompte en cas de paiement anticipé
                    </Box>
                    <Box component="li" sx={{ 
                      color: '#666', 
                      fontSize: '13px', 
                      mb: 0.75, 
                      pl: 2, 
                      position: 'relative',
                      '&:before': {
                        content: '"•"',
                        position: 'absolute',
                        left: 0,
                        color: '#666'
                      }
                    }}>
                      Pour toute question, contactez-nous au 07 59 23 91 70 ou par email à contact.ateliergestion@gmail.com
                    </Box>
                  </Box>
                </Box>

                {/* Pied de page - identique au Kanban */}
                <Box sx={{ 
                  textAlign: 'center', 
                  mt: 5, 
                  pt: 2.5, 
                  borderTop: '1px solid #eee' 
                }}>
                  <Typography variant="h6" sx={{ 
                    mb: 1, 
                    fontSize: '18px', 
                    color: '#333' 
                  }}>
                    Atelier de réparation
                  </Typography>
                  <Typography sx={{ 
                    fontSize: '12px', 
                    color: '#666', 
                    mb: 1 
                  }}>
                    Tél: 07 59 23 91 70 • Email: contact.ateliergestion@gmail.com
                  </Typography>
                  <Typography sx={{ 
                    fontWeight: 600, 
                    color: '#1976d2', 
                    fontSize: '14px' 
                  }}>
                    Merci de votre confiance !
                  </Typography>
                </Box>
              </Box>
            </Box>
          )}
        </DialogContent>
      </Dialog>

    </Box>
  );
};

export default InvoicesManagementFixed;
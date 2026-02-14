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
  Button,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  Divider,
  alpha,
} from '@mui/material';
import { Search, Visibility, Download, Close as CloseIcon, Analytics as AnalyticsIcon } from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

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

const STATUS_OPTIONS = [
  { value: 'all', label: 'Tous' },
  { value: 'pending', label: 'En attente' },
  { value: 'paid', label: 'Payée' },
  { value: 'overdue', label: 'En retard' },
];

const InvoicesManagementFixed: React.FC = () => {
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [filteredInvoices, setFilteredInvoices] = useState<Invoice[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);

  const { sales, repairs, clients, systemSettings, loadSystemSettings } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => {
    loadRealInvoices();
    if (systemSettings.length === 0) loadSystemSettings();
  }, []);

  const loadRealInvoices = async () => {
    try {
      const { sales, repairs, clients } = useAppStore.getState();
      const realInvoices: Invoice[] = [];

      sales.forEach(sale => {
        const client = clients.find(c => c.id === sale.clientId);
        const issueDate = new Date(sale.createdAt);
        const dueDate = new Date(issueDate);
        dueDate.setDate(dueDate.getDate() + 30);
        realInvoices.push({
          id: sale.id, invoiceNumber: `SALE-${sale.id.substring(0, 8)}`,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          issueDate: issueDate.toISOString().split('T')[0],
          dueDate: dueDate.toISOString().split('T')[0],
          totalAmount: sale.total || 0,
          status: sale.status === 'completed' ? 'paid' : 'pending',
          paymentDate: sale.status === 'completed' ? sale.createdAt : undefined,
          paymentMethod: sale.paymentMethod || 'Espèces',
        });
      });

      repairs.forEach(repair => {
        const client = clients.find(c => c.id === repair.clientId);
        const issueDate = new Date(repair.createdAt);
        const dueDate = new Date(issueDate);
        dueDate.setDate(dueDate.getDate() + 30);
        realInvoices.push({
          id: repair.id, invoiceNumber: `REP-${repair.id.substring(0, 8)}`,
          clientName: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          issueDate: issueDate.toISOString().split('T')[0],
          dueDate: dueDate.toISOString().split('T')[0],
          totalAmount: repair.totalPrice || 0,
          status: repair.isPaid ? 'paid' : 'pending',
          paymentDate: repair.isPaid ? repair.createdAt : undefined,
          paymentMethod: 'Espèces',
        });
      });

      realInvoices.sort((a, b) => new Date(b.issueDate).getTime() - new Date(a.issueDate).getTime());
      setInvoices(realInvoices);
      setFilteredInvoices(realInvoices);
    } catch {
      setInvoices([]);
      setFilteredInvoices([]);
    }
  };

  useEffect(() => {
    let filtered = invoices;
    if (searchTerm) {
      filtered = filtered.filter(inv =>
        inv.invoiceNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
        inv.clientName.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    if (filterStatus !== 'all') filtered = filtered.filter(inv => inv.status === filterStatus);
    setFilteredInvoices(filtered);
  }, [invoices, searchTerm, filterStatus]);

  const getStatusChip = (status: string) => {
    const map: Record<string, { label: string; color: string }> = {
      paid: { label: 'Payée', color: '#22c55e' },
      pending: { label: 'En attente', color: '#f59e0b' },
      overdue: { label: 'En retard', color: '#ef4444' },
      cancelled: { label: 'Annulée', color: '#6b7280' },
    };
    const c = map[status] || { label: status, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const getStatusLabel = (status: string) => {
    const map: Record<string, string> = { paid: 'Payée', pending: 'En attente', overdue: 'En retard', cancelled: 'Annulée', returned: 'Restituée' };
    return map[status] || status;
  };

  const getVatRate = () => {
    const vatSetting = systemSettings.find(s => s.key === 'vat_rate');
    return vatSetting ? parseFloat(vatSetting.value) : 20;
  };

  const formatCurrency = (amount: number) => formatFromEUR(amount, currency);

  const handleDownloadInvoice = (invoice: Invoice) => {
    try {
      const invoiceHTML = `<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Facture ${invoice.invoiceNumber}</title><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;margin:0;padding:24px;background:white;color:#333;line-height:1.6}.invoice-container{max-width:800px;margin:0 auto}.header{text-align:center;margin-bottom:40px;padding-bottom:20px;border-bottom:1px solid #eee}.header h1{font-size:24px;font-weight:600;margin:0 0 8px 0;color:#333}.header .contact-info{font-size:12px;color:#666;line-height:1.8}.invoice-details{display:flex;justify-content:space-between;margin-bottom:40px}.section-title{font-weight:600;margin-bottom:12px;color:#333;font-size:14px}.client-name{font-weight:600;color:#333;margin-bottom:8px}.invoice-number{font-weight:600;color:#1976d2;font-size:16px;margin-bottom:8px}.totals-section{margin-bottom:30px}.total-row{display:flex;justify-content:space-between;margin-bottom:8px;font-size:14px}.total-row:last-child{font-weight:600;font-size:16px;color:#1976d2;border-top:1px solid #eee;padding-top:8px}.conditions{background-color:#f8f9fa;padding:20px;border-radius:4px;margin-bottom:30px}.conditions h3{margin-bottom:12px;font-size:16px;color:#333}.conditions li{margin-bottom:6px;font-size:14px;color:#666;list-style:none}.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #eee}.footer h3{margin-bottom:8px;font-size:18px;color:#333}.footer p{font-size:12px;color:#666;margin-bottom:4px}.thank-you{font-weight:600;color:#1976d2;margin-top:12px}</style></head><body><div class="invoice-container"><div class="header"><h1>Atelier de réparation</h1><div class="contact-info">Tél: 07 59 23 91 70 • Email: contact.ateliergestion@gmail.com</div></div><div class="invoice-details"><div><div class="section-title">FACTURÉ À</div><div class="client-name">${invoice.clientName}</div><div style="font-size:14px;color:#666">Client de l'atelier</div></div><div><div class="section-title">DÉTAILS DE LA FACTURE</div><div class="invoice-number">#${invoice.invoiceNumber}</div><div style="font-size:14px;color:#666"><strong>Date :</strong> ${new Date(invoice.issueDate).toLocaleDateString('fr-FR')}</div><div style="font-size:14px;color:#666"><strong>Statut :</strong> ${getStatusLabel(invoice.status)}</div></div></div><div class="totals-section"><div class="total-row"><span>Sous-total HT :</span><span>${formatFromEUR(invoice.totalAmount / (1 + getVatRate() / 100), currency)}</span></div><div class="total-row"><span>TVA (${getVatRate()}%) :</span><span>${formatFromEUR(invoice.totalAmount - (invoice.totalAmount / (1 + getVatRate() / 100)), currency)}</span></div><div class="total-row"><span>TOTAL TTC :</span><span>${formatCurrency(invoice.totalAmount)}</span></div></div><div class="conditions"><h3>CONDITIONS DE PAIEMENT</h3><ul><li>Facture valable 30 jours</li><li>Aucun escompte en cas de paiement anticipé</li></ul></div><div class="footer"><h3>Atelier de réparation</h3><p>Tél: 07 59 23 91 70 • Email: contact.ateliergestion@gmail.com</p><div class="thank-you">Merci de votre confiance !</div></div></div></body></html>`;
      const blob = new Blob([invoiceHTML], { type: 'text/html;charset=utf-8;' });
      const link = document.createElement('a');
      link.setAttribute('href', URL.createObjectURL(blob));
      link.setAttribute('download', `Facture_${invoice.invoiceNumber}.html`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    } catch { alert('Erreur lors du téléchargement'); }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h6" sx={{ fontWeight: 600 }}>
          Gestion des factures
        </Typography>
        <Button
          variant="contained"
          sx={{
            borderRadius: '10px', textTransform: 'none', fontWeight: 600,
            bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
            boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
          }}
        >
          Nouvelle facture
        </Button>
      </Box>

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
            {STATUS_OPTIONS.map(opt => (
              <Chip
                key={opt.value}
                label={opt.label}
                onClick={() => setFilterStatus(opt.value)}
                size="small"
                sx={{
                  fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                  ...(filterStatus === opt.value
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
                <TableCell>N° Facture</TableCell>
                <TableCell>Client</TableCell>
                <TableCell>Émission</TableCell>
                <TableCell>Échéance</TableCell>
                <TableCell align="right">Montant</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredInvoices.map((invoice) => (
                <TableRow key={invoice.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 600, color: '#6366f1' }}>
                      {invoice.invoiceNumber}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>{invoice.clientName}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">
                      {new Date(invoice.issueDate).toLocaleDateString('fr-FR')}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">
                      {new Date(invoice.dueDate).toLocaleDateString('fr-FR')}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body2" sx={{ fontWeight: 700 }}>
                      {formatCurrency(invoice.totalAmount)}
                    </Typography>
                  </TableCell>
                  <TableCell>{getStatusChip(invoice.status)}</TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', gap: 0.5 }}>
                      <IconButton size="small" onClick={() => { setSelectedInvoice(invoice); setViewDialogOpen(true); }}
                        sx={{ bgcolor: alpha('#6366f1', 0.08), borderRadius: '8px', '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }}>
                        <Visibility sx={{ fontSize: 18, color: '#6366f1' }} />
                      </IconButton>
                      <IconButton size="small" onClick={() => handleDownloadInvoice(invoice)}
                        sx={{ bgcolor: alpha('#22c55e', 0.08), borderRadius: '8px', '&:hover': { bgcolor: alpha('#22c55e', 0.15) } }}>
                        <Download sx={{ fontSize: 18, color: '#22c55e' }} />
                      </IconButton>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        {filteredInvoices.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 6 }}>
            <AnalyticsIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
            <Typography variant="body2" color="text.disabled">Aucune facture trouvée</Typography>
          </Box>
        )}
      </Card>

      {/* View Dialog */}
      <Dialog open={viewDialogOpen} onClose={() => { setViewDialogOpen(false); setSelectedInvoice(null); }} maxWidth="md" fullWidth
        PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            Facture #{selectedInvoice?.invoiceNumber}
          </Typography>
          <Box>
            <IconButton onClick={() => selectedInvoice && handleDownloadInvoice(selectedInvoice)} sx={{ mr: 0.5 }}>
              <Download />
            </IconButton>
            <IconButton onClick={() => { setViewDialogOpen(false); setSelectedInvoice(null); }}>
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          {selectedInvoice && (
            <Box sx={{ p: 2 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 4, gap: 4 }}>
                <Box>
                  <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', color: 'text.secondary', letterSpacing: '0.05em' }}>
                    Facturé à
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 600, mt: 1 }}>{selectedInvoice.clientName}</Typography>
                  <Typography variant="body2" color="text.secondary">Client de l'atelier</Typography>
                </Box>
                <Box sx={{ textAlign: 'right' }}>
                  <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', color: 'text.secondary', letterSpacing: '0.05em' }}>
                    Détails
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 600, color: '#6366f1', mt: 1 }}>#{selectedInvoice.invoiceNumber}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {new Date(selectedInvoice.issueDate).toLocaleDateString('fr-FR')} • {getStatusLabel(selectedInvoice.status)}
                  </Typography>
                </Box>
              </Box>
              <Divider sx={{ my: 3 }} />
              <Box sx={{ p: 2, bgcolor: 'grey.50', borderRadius: '12px', mb: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Sous-total HT</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {formatFromEUR(selectedInvoice.totalAmount / (1 + getVatRate() / 100), currency)}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">TVA ({getVatRate()}%)</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {formatFromEUR(selectedInvoice.totalAmount - (selectedInvoice.totalAmount / (1 + getVatRate() / 100)), currency)}
                  </Typography>
                </Box>
                <Divider sx={{ my: 1.5 }} />
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body1" sx={{ fontWeight: 700, color: '#6366f1' }}>TOTAL TTC</Typography>
                  <Typography variant="body1" sx={{ fontWeight: 700, color: '#6366f1' }}>
                    {formatCurrency(selectedInvoice.totalAmount)}
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

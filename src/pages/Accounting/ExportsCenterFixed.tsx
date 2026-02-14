import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  TextField,
  Chip,
  Divider,
  Alert,
  CircularProgress,
  alpha,
} from '@mui/material';
import {
  Download,
  PictureAsPdf,
  TableChart,
  Assessment,
  History as HistoryIcon,
  CalendarMonth,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { repairService } from '../../services/supabaseService';
import { jsPDF } from 'jspdf';

const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': {
    boxShadow: '0 8px 32px rgba(0,0,0,0.10)',
    transform: 'translateY(-2px)',
  },
} as const;

interface ExportHistory {
  id: string;
  name: string;
  type: string;
  format: string;
  date: string;
  size: string;
  downloadCount: number;
}

const FORMAT_OPTIONS = [
  { value: 'excel', label: 'Excel', icon: <TableChart sx={{ fontSize: 16 }} />, color: '#22c55e' },
  { value: 'pdf', label: 'PDF', icon: <PictureAsPdf sx={{ fontSize: 16 }} />, color: '#ef4444' },
];

const DATE_RANGE_OPTIONS = [
  { value: 'last7days', label: '7 jours' },
  { value: 'last30days', label: '30 jours' },
  { value: 'last3months', label: '3 mois' },
  { value: 'lastyear', label: '1 an' },
  { value: 'custom', label: 'Personnalisé' },
];

const ExportsCenterFixed: React.FC = () => {
  const [selectedFormat, setSelectedFormat] = useState<string>('excel');
  const [selectedData, setSelectedData] = useState<string>('transactions');
  const [dateRange, setDateRange] = useState<string>('last30days');
  const [customStartDate, setCustomStartDate] = useState<string>('');
  const [customEndDate, setCustomEndDate] = useState<string>('');
  const [isLoading, setIsLoading] = useState(false);
  const [exportHistory, setExportHistory] = useState<ExportHistory[]>([]);

  const { sales, repairs, expenses, clients, loadSales, loadRepairs, loadExpenses, loadClients } = useAppStore();

  useEffect(() => {
    if (sales.length === 0) loadSales();
    if (repairs.length === 0) loadRepairs();
    if (expenses.length === 0) loadExpenses();
    if (clients.length === 0) loadClients();
    loadExportHistory();
  }, [sales.length, repairs.length, expenses.length, clients.length, loadSales, loadRepairs, loadExpenses, loadClients]);

  const loadExportHistory = () => {
    try {
      const savedHistory = localStorage.getItem('atelier-export-history');
      if (savedHistory) setExportHistory(JSON.parse(savedHistory));
    } catch { /* ignore */ }
  };

  const saveExportHistory = (newHistory: ExportHistory[]) => {
    try {
      localStorage.setItem('atelier-export-history', JSON.stringify(newHistory.slice(0, 50)));
    } catch { /* ignore */ }
  };

  const addToHistory = (name: string, type: string, format: string, size: string) => {
    const newExport: ExportHistory = {
      id: Date.now().toString(), name, type, format,
      date: new Date().toLocaleString('fr-FR'), size, downloadCount: 0,
    };
    const updatedHistory = [newExport, ...exportHistory];
    setExportHistory(updatedHistory);
    saveExportHistory(updatedHistory);
  };

  const exportOptions = [
    {
      id: 'transactions', title: 'Transactions',
      description: 'Ventes, réparations et dépenses',
      icon: <TableChart sx={{ fontSize: 20 }} />, iconColor: '#6366f1',
      formats: ['excel', 'pdf'],
    },
    {
      id: 'invoices', title: 'Factures',
      description: 'Factures avec détails clients',
      icon: <Assessment sx={{ fontSize: 20 }} />, iconColor: '#22c55e',
      formats: ['excel', 'pdf'],
    },
    {
      id: 'expenses', title: 'Dépenses',
      description: 'Dépenses par catégorie et période',
      icon: <TableChart sx={{ fontSize: 20 }} />, iconColor: '#f59e0b',
      formats: ['excel', 'pdf'],
    },
    {
      id: 'financial_report', title: 'Rapport Financier',
      description: 'Rapport complet avec KPIs',
      icon: <Assessment sx={{ fontSize: 20 }} />, iconColor: '#8b5cf6',
      formats: ['pdf'],
    },
  ];

  const getDateRange = (): { startDate: Date | null; endDate: Date | null } => {
    const endDate = new Date();
    endDate.setHours(23, 59, 59, 999);
    let startDate: Date | null = null;

    switch (dateRange) {
      case 'last7days':
        startDate = new Date(); startDate.setDate(startDate.getDate() - 7); startDate.setHours(0, 0, 0, 0); break;
      case 'last30days':
        startDate = new Date(); startDate.setDate(startDate.getDate() - 30); startDate.setHours(0, 0, 0, 0); break;
      case 'last3months':
        startDate = new Date(); startDate.setMonth(startDate.getMonth() - 3); startDate.setHours(0, 0, 0, 0); break;
      case 'lastyear':
        startDate = new Date(); startDate.setFullYear(startDate.getFullYear() - 1); startDate.setHours(0, 0, 0, 0); break;
      case 'custom':
        if (customStartDate && customEndDate) {
          startDate = new Date(customStartDate); startDate.setHours(0, 0, 0, 0);
          const customEnd = new Date(customEndDate); customEnd.setHours(23, 59, 59, 999);
          return { startDate, endDate: customEnd };
        }
        return { startDate: null, endDate: null };
      default:
        return { startDate: null, endDate: null };
    }
    return { startDate, endDate };
  };

  const handleExport = async () => {
    try {
      setIsLoading(true);
      await loadSales(); await loadRepairs(); await loadExpenses(); await loadClients();
      await new Promise(resolve => setTimeout(resolve, 100));

      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();
      const { startDate, endDate } = getDateRange();

      let dataToExport: any[] = [];
      let fileName = '';

      switch (selectedData) {
        case 'transactions':
          dataToExport = await generateTransactionsData(updatedSales, updatedRepairs, updatedExpenses, updatedClients, startDate, endDate);
          fileName = 'transactions_comptables'; break;
        case 'invoices':
          dataToExport = generateInvoicesData(updatedSales, updatedRepairs, updatedClients, startDate, endDate);
          fileName = 'factures'; break;
        case 'expenses':
          dataToExport = generateExpensesData(updatedExpenses, startDate, endDate);
          fileName = 'depenses'; break;
        case 'financial_report':
          dataToExport = generateFinancialReportData(updatedSales, updatedRepairs, updatedExpenses, startDate, endDate);
          fileName = 'rapport_financier'; break;
        default:
          throw new Error('Type de données non supporté');
      }

      if (selectedFormat === 'excel') {
        exportToExcel(dataToExport, fileName);
        addToHistory(`Export ${selectedData} - ${dateRange}`, selectedData, 'Excel', `${dataToExport.length} lignes`);
      } else if (selectedFormat === 'pdf') {
        exportToPDF(dataToExport, fileName);
        addToHistory(`Export ${selectedData} - ${dateRange}`, selectedData, 'PDF', `${dataToExport.length} lignes`);
      }
    } catch {
      alert('Erreur lors de l\'export des données');
    } finally {
      setIsLoading(false);
    }
  };

  const filterByDate = (date: Date | string, startDate: Date | null, endDate: Date | null): boolean => {
    if (!startDate && !endDate) return true;
    const itemDate = typeof date === 'string' ? new Date(date) : date;
    if (startDate && itemDate < startDate) return false;
    if (endDate && itemDate > endDate) return false;
    return true;
  };

  const generateTransactionsData = async (salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[], startDate: Date | null, endDate: Date | null) => {
    const transactions: any[] = [];

    salesData.forEach(sale => {
      const saleDate = new Date(sale.createdAt);
      if (!filterByDate(saleDate, startDate, endDate)) return;
      const client = clientsData.find(c => c.id === sale.clientId);
      transactions.push({
        Date: saleDate.toLocaleDateString('fr-FR'), Type: 'Vente',
        Description: `Vente #${sale.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        Compte: '', Montant: sale.total || 0,
        Statut: sale.status === 'completed' ? 'Terminé' : 'En cours',
      });
    });

    repairsData.forEach(repair => {
      const repairDate = new Date(repair.createdAt);
      if (!filterByDate(repairDate, startDate, endDate)) return;
      const client = clientsData.find(c => c.id === repair.clientId);
      transactions.push({
        Date: repairDate.toLocaleDateString('fr-FR'), Type: 'Réparation',
        Description: `Réparation #${repair.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        Compte: '', Montant: repair.totalPrice || 0,
        Statut: repair.status === 'completed' ? 'Terminé' : 'En cours',
      });
    });

    for (const repair of repairsData) {
      if (repair.deposit && repair.deposit > 0) {
        const client = clientsData.find(c => c.id === repair.clientId);
        let depositDate = new Date(repair.createdAt);
        let depositStatus = 'En attente';
        try {
          const paymentsResult = await repairService.getPaymentsByRepairId(repair.id);
          if (paymentsResult.success && 'data' in paymentsResult && paymentsResult.data) {
            const depositPayment = paymentsResult.data.find((payment: any) => payment.paymentType === 'deposit');
            if (depositPayment) {
              depositDate = new Date(depositPayment.paymentDate || depositPayment.createdAt);
              depositStatus = 'Payé';
            }
          }
        } catch { /* ignore */ }
        if (!filterByDate(depositDate, startDate, endDate)) continue;
        const repairNumber = repair.repairNumber || repair.id.substring(0, 8);
        transactions.push({
          Date: depositDate.toLocaleDateString('fr-FR'), Type: 'Acompte',
          Description: `Acompte - Réparation #${repairNumber}`,
          Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
          Compte: 'Acompte', Montant: repair.deposit, Statut: depositStatus,
        });
      }
    }

    expensesData.forEach(expense => {
      const expenseDate = new Date(expense.expenseDate);
      if (!filterByDate(expenseDate, startDate, endDate)) return;
      transactions.push({
        Date: expenseDate.toLocaleDateString('fr-FR'), Type: 'Dépense',
        Description: expense.title || 'Dépense', Client: '', Compte: '',
        Montant: -(expense.amount || 0),
        Statut: expense.status === 'paid' ? 'Payé' : 'En attente',
      });
    });

    return transactions.sort((a, b) => {
      const dateA = new Date(a.Date.split('/').reverse().join('-'));
      const dateB = new Date(b.Date.split('/').reverse().join('-'));
      return dateB.getTime() - dateA.getTime();
    });
  };

  const generateInvoicesData = (salesData: any[], repairsData: any[], clientsData: any[], startDate: Date | null, endDate: Date | null) => {
    const invoices: any[] = [];
    salesData.forEach(sale => {
      const saleDate = new Date(sale.createdAt);
      if (!filterByDate(saleDate, startDate, endDate)) return;
      const client = clientsData.find(c => c.id === sale.clientId);
      invoices.push({
        'Numéro': `FAC-${sale.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        'Date Émission': saleDate.toLocaleDateString('fr-FR'),
        'Date Échéance': new Date(new Date(sale.createdAt).getTime() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString('fr-FR'),
        Montant: sale.total || 0,
        Statut: sale.status === 'completed' ? 'Payée' : 'En attente',
      });
    });
    repairsData.forEach(repair => {
      const repairDate = new Date(repair.createdAt);
      if (!filterByDate(repairDate, startDate, endDate)) return;
      const client = clientsData.find(c => c.id === repair.clientId);
      invoices.push({
        'Numéro': `FAC-${repair.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        'Date Émission': repairDate.toLocaleDateString('fr-FR'),
        'Date Échéance': new Date(new Date(repair.createdAt).getTime() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString('fr-FR'),
        Montant: repair.totalPrice || 0,
        Statut: repair.isPaid ? 'Payée' : 'En attente',
      });
    });
    return invoices.sort((a, b) => new Date(b['Date Émission'].split('/').reverse().join('-')).getTime() - new Date(a['Date Émission'].split('/').reverse().join('-')).getTime());
  };

  const generateExpensesData = (expensesData: any[], startDate: Date | null, endDate: Date | null) => {
    return expensesData
      .filter(expense => filterByDate(new Date(expense.expenseDate), startDate, endDate))
      .map(expense => ({
        Titre: expense.title || 'Dépense',
        Catégorie: expense.tags?.[0] || 'Général',
        Fournisseur: expense.supplier || 'N/A',
        Date: new Date(expense.expenseDate).toLocaleDateString('fr-FR'),
        Montant: expense.amount || 0,
        Statut: expense.status === 'paid' ? 'Payé' : 'En attente',
      }))
      .sort((a, b) => new Date(b.Date.split('/').reverse().join('-')).getTime() - new Date(a.Date.split('/').reverse().join('-')).getTime());
  };

  const generateFinancialReportData = (salesData: any[], repairsData: any[], expensesData: any[], startDate: Date | null, endDate: Date | null) => {
    const monthlyData = new Map<string, { revenus: number; depenses: number }>();
    [...salesData, ...repairsData].forEach(item => {
      const date = new Date(item.createdAt);
      if (!filterByDate(date, startDate, endDate)) return;
      const month = date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      const amount = item.total || item.totalPrice || 0;
      if (!monthlyData.has(month)) monthlyData.set(month, { revenus: 0, depenses: 0 });
      monthlyData.get(month)!.revenus += amount;
    });
    expensesData.forEach(expense => {
      const date = new Date(expense.expenseDate);
      if (!filterByDate(date, startDate, endDate)) return;
      const month = date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      if (!monthlyData.has(month)) monthlyData.set(month, { revenus: 0, depenses: 0 });
      monthlyData.get(month)!.depenses += (expense.amount || 0);
    });
    return Array.from(monthlyData.entries()).map(([periode, data]) => {
      const beneficeNet = data.revenus - data.depenses;
      const marge = data.revenus > 0 ? ((beneficeNet / data.revenus) * 100).toFixed(1) : '0';
      return { Période: periode, Revenus: data.revenus, Dépenses: data.depenses, 'Bénéfice Net': beneficeNet, Marge: `${marge}%` };
    }).sort((a, b) => new Date(b.Période.split(' ')[1] + '-' + (new Date(b.Période.split(' ')[0] + ' 1, ' + b.Période.split(' ')[1]).getMonth() + 1)).getTime() - new Date(a.Période.split(' ')[1] + '-' + (new Date(a.Période.split(' ')[0] + ' 1, ' + a.Période.split(' ')[1]).getMonth() + 1)).getTime());
  };

  const exportToExcel = (data: any[], fileName: string) => {
    const headers = Object.keys(data[0]);
    const csvContent = [
      headers.join(','),
      ...data.map(row => headers.map(header => `"${row[header] || ''}"`).join(',')),
    ].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `${fileName}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const exportToPDF = (data: any[], fileName: string) => {
    try {
      if (!data || data.length === 0) { alert('Aucune donnée à exporter'); return; }
      const doc = new jsPDF('landscape', 'mm', 'a4');
      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();
      const margin = 10;
      let yPosition = margin;
      const lineHeight = 6;
      const maxY = pageHeight - margin - 15;

      doc.setFontSize(16); doc.setFont('helvetica', 'bold'); doc.setTextColor(0, 0, 0);
      doc.text(fileName.toUpperCase(), pageWidth / 2, yPosition, { align: 'center' });
      yPosition += 8;
      doc.setFontSize(9); doc.setFont('helvetica', 'normal');
      doc.text(`Généré le: ${new Date().toLocaleDateString('fr-FR')} à ${new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}`, pageWidth / 2, yPosition, { align: 'center' });
      yPosition += 8;

      const headers = Object.keys(data[0]);
      const availableWidth = pageWidth - 2 * margin;
      const columnWidth = availableWidth / headers.length;

      const truncateText = (text: string, maxWidth: number): string => {
        if (doc.getTextWidth(text) <= maxWidth) return text;
        let truncated = text;
        while (doc.getTextWidth(truncated + '...') > maxWidth && truncated.length > 0) truncated = truncated.slice(0, -1);
        return truncated + '...';
      };

      const drawHeaders = () => {
        doc.setFontSize(8); doc.setFont('helvetica', 'bold');
        doc.setFillColor(240, 240, 240);
        doc.rect(margin, yPosition - 4, availableWidth, lineHeight, 'F');
        headers.forEach((header, index) => {
          doc.text(truncateText(header, columnWidth - 4), margin + (index * columnWidth) + 2, yPosition, { maxWidth: columnWidth - 4 });
        });
        yPosition += lineHeight;
        doc.setDrawColor(200, 200, 200); doc.setLineWidth(0.3);
        doc.line(margin, yPosition, pageWidth - margin, yPosition);
        yPosition += 2;
      };

      drawHeaders();
      doc.setFontSize(7); doc.setFont('helvetica', 'normal');

      data.forEach((row, rowIndex) => {
        if (yPosition + lineHeight > maxY) {
          doc.addPage(); yPosition = margin; drawHeaders();
          doc.setFontSize(7); doc.setFont('helvetica', 'normal');
        }
        if (rowIndex % 2 === 0) {
          doc.setFillColor(250, 250, 250);
          doc.rect(margin, yPosition - 4, availableWidth, lineHeight, 'F');
        }
        headers.forEach((header, index) => {
          doc.text(truncateText(String(row[header] || ''), columnWidth - 4), margin + (index * columnWidth) + 2, yPosition, { maxWidth: columnWidth - 4 });
        });
        yPosition += lineHeight;
      });

      const totalPages = doc.internal.pages.length - 1;
      for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i); doc.setFontSize(7); doc.setFont('helvetica', 'normal'); doc.setTextColor(128, 128, 128);
        doc.text(`Page ${i} sur ${totalPages}`, pageWidth / 2, pageHeight - 8, { align: 'center' });
      }
      doc.save(`${fileName}.pdf`);
    } catch {
      alert('Erreur lors de la génération du PDF. Veuillez réessayer.');
    }
  };

  const dataCount = sales.length + repairs.length + expenses.length;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h6" sx={{ fontWeight: 600 }}>
          Centre d'exports
        </Typography>
        {dataCount > 0 && (
          <Chip
            label={`${sales.length} ventes • ${repairs.length} réparations • ${expenses.length} dépenses`}
            size="small"
            sx={{ fontWeight: 500, borderRadius: '8px', fontSize: '0.72rem', bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }}
          />
        )}
      </Box>

      {dataCount === 0 && (
        <Alert severity="info" sx={{ mb: 3, borderRadius: '12px', border: '1px solid', borderColor: alpha('#6366f1', 0.2), bgcolor: alpha('#6366f1', 0.04) }}>
          Aucune donnée disponible pour le moment.
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Data type selection */}
        <Grid item xs={12} md={8}>
          <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.secondary', textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.05em', mb: 1.5 }}>
            Données à exporter
          </Typography>
          <Grid container spacing={2}>
            {exportOptions.map((option) => (
              <Grid item xs={12} sm={6} key={option.id}>
                <Card
                  sx={{
                    ...CARD_BASE,
                    cursor: 'pointer',
                    border: selectedData === option.id ? '2px solid' : '1px solid rgba(0,0,0,0.04)',
                    borderColor: selectedData === option.id ? option.iconColor : 'rgba(0,0,0,0.04)',
                    bgcolor: selectedData === option.id ? alpha(option.iconColor, 0.02) : 'background.paper',
                  }}
                  onClick={() => setSelectedData(option.id)}
                >
                  <CardContent sx={{ p: '16px !important' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
                      <Box sx={{
                        width: 36, height: 36, borderRadius: '10px', display: 'flex',
                        alignItems: 'center', justifyContent: 'center',
                        background: `linear-gradient(135deg, ${option.iconColor}, ${alpha(option.iconColor, 0.7)})`,
                        color: '#fff', flexShrink: 0,
                        boxShadow: `0 4px 14px ${alpha(option.iconColor, 0.3)}`,
                      }}>
                        {option.icon}
                      </Box>
                      <Typography variant="body1" sx={{ fontWeight: 700 }}>{option.title}</Typography>
                    </Box>
                    <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.72rem' }}>
                      {option.description}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 0.5, mt: 1.5 }}>
                      {option.formats.map((format) => (
                        <Chip
                          key={format}
                          label={format.toUpperCase()}
                          size="small"
                          sx={{
                            fontWeight: 600, borderRadius: '6px', fontSize: '0.65rem', height: 22,
                            bgcolor: alpha(format === 'pdf' ? '#ef4444' : '#22c55e', 0.1),
                            color: format === 'pdf' ? '#ef4444' : '#22c55e',
                          }}
                        />
                      ))}
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Grid>

        {/* Configuration panel */}
        <Grid item xs={12} md={4}>
          <Card sx={CARD_BASE}>
            <CardContent sx={{ p: '20px !important' }}>
              <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.secondary', textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.05em', mb: 2 }}>
                Configuration
              </Typography>

              {/* Format selection */}
              <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', mb: 0.75, display: 'block' }}>
                Format
              </Typography>
              <Box sx={{ display: 'flex', gap: 0.75, mb: 2.5 }}>
                {FORMAT_OPTIONS.map(opt => (
                  <Chip
                    key={opt.value}
                    icon={opt.icon}
                    label={opt.label}
                    onClick={() => setSelectedFormat(opt.value)}
                    size="small"
                    sx={{
                      fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                      '& .MuiChip-icon': { ml: '6px' },
                      ...(selectedFormat === opt.value
                        ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' }, '& .MuiChip-icon': { color: '#fff', ml: '6px' } }
                        : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
                    }}
                  />
                ))}
              </Box>

              {/* Period selection */}
              <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', mb: 0.75, display: 'block' }}>
                Période
              </Typography>
              <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 2 }}>
                {DATE_RANGE_OPTIONS.map(opt => (
                  <Chip
                    key={opt.value}
                    label={opt.label}
                    onClick={() => setDateRange(opt.value)}
                    size="small"
                    sx={{
                      fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                      ...(dateRange === opt.value
                        ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
                        : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
                    }}
                  />
                ))}
              </Box>

              {dateRange === 'custom' && (
                <Box sx={{ display: 'flex', gap: 1, mb: 2 }}>
                  <TextField
                    label="Début" type="date" fullWidth size="small"
                    value={customStartDate} onChange={(e) => setCustomStartDate(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                  />
                  <TextField
                    label="Fin" type="date" fullWidth size="small"
                    value={customEndDate} onChange={(e) => setCustomEndDate(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                  />
                </Box>
              )}

              <Divider sx={{ my: 2 }} />

              <Button
                variant="contained"
                fullWidth
                startIcon={isLoading ? <CircularProgress size={18} sx={{ color: '#fff' }} /> : <Download sx={{ fontSize: 18 }} />}
                onClick={handleExport}
                disabled={isLoading}
                sx={{
                  borderRadius: '10px', textTransform: 'none', fontWeight: 600, py: 1.25,
                  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
                  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
                  '&.Mui-disabled': { bgcolor: '#6b7280', color: '#fff' },
                }}
              >
                {isLoading ? 'Export en cours...' : 'Exporter les données'}
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Export history */}
      <Box sx={{ mt: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <HistoryIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
          <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.secondary', textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.05em' }}>
            Historique ({exportHistory.length})
          </Typography>
        </Box>

        <Card sx={{ borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
          {exportHistory.length === 0 ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 5 }}>
              <CalendarMonth sx={{ fontSize: 36, color: 'grey.300', mb: 1 }} />
              <Typography variant="body2" color="text.disabled">Aucun export effectué</Typography>
            </Box>
          ) : (
            <CardContent sx={{ p: '16px !important' }}>
              {exportHistory.map((exportItem, index) => (
                <Box key={exportItem.id}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', py: 1 }}>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{exportItem.name}</Typography>
                      <Typography variant="caption" color="text.disabled" sx={{ fontSize: '0.7rem' }}>
                        {exportItem.date} • {exportItem.size}
                      </Typography>
                    </Box>
                    <Chip
                      label={exportItem.format}
                      size="small"
                      sx={{
                        fontWeight: 600, borderRadius: '8px', fontSize: '0.7rem',
                        bgcolor: alpha(exportItem.format === 'Excel' ? '#22c55e' : '#ef4444', 0.1),
                        color: exportItem.format === 'Excel' ? '#22c55e' : '#ef4444',
                      }}
                    />
                  </Box>
                  {index < exportHistory.length - 1 && <Divider sx={{ my: 0.5 }} />}
                </Box>
              ))}
            </CardContent>
          )}
        </Card>
      </Box>
    </Box>
  );
};

export default ExportsCenterFixed;

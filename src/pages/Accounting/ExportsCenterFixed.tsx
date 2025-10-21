import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Chip,
  Divider,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  Download,
  PictureAsPdf,
  TableChart,
  Assessment,
  DateRange,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

interface ExportHistory {
  id: string;
  name: string;
  type: string;
  format: string;
  date: string;
  size: string;
  downloadCount: number;
}

const ExportsCenterFixed: React.FC = () => {
  const [selectedFormat, setSelectedFormat] = useState<string>('excel');
  const [selectedData, setSelectedData] = useState<string>('transactions');
  const [dateRange, setDateRange] = useState<string>('last30days');
  const [isLoading, setIsLoading] = useState(false);
  const [exportHistory, setExportHistory] = useState<ExportHistory[]>([]);

  // Accès aux vraies données de l'atelier
  const { sales, repairs, expenses, clients, loadSales, loadRepairs, loadExpenses, loadClients } = useAppStore();

  useEffect(() => {
    // Charger les données si elles ne sont pas disponibles
    if (sales.length === 0) {
      loadSales();
    }
    if (repairs.length === 0) {
      loadRepairs();
    }
    if (expenses.length === 0) {
      loadExpenses();
    }
    if (clients.length === 0) {
      loadClients();
    }
    
    // Charger l'historique des exports
    loadExportHistory();
  }, [sales.length, repairs.length, expenses.length, clients.length, loadSales, loadRepairs, loadExpenses, loadClients]);

  // Charger l'historique des exports depuis localStorage
  const loadExportHistory = () => {
    try {
      const savedHistory = localStorage.getItem('atelier-export-history');
      if (savedHistory) {
        const parsedHistory = JSON.parse(savedHistory);
        setExportHistory(parsedHistory);
      }
    } catch (error) {
      console.error('Erreur lors du chargement de l\'historique des exports:', error);
    }
  };

  // Sauvegarder l'historique des exports
  const saveExportHistory = (newHistory: ExportHistory[]) => {
    try {
      // Limiter à 50 exports maximum
      const limitedHistory = newHistory.slice(0, 50);
      localStorage.setItem('atelier-export-history', JSON.stringify(limitedHistory));
    } catch (error) {
      console.error('Erreur lors de la sauvegarde de l\'historique des exports:', error);
    }
  };

  // Ajouter un export à l'historique
  const addToHistory = (name: string, type: string, format: string, size: string) => {
    const newExport: ExportHistory = {
      id: Date.now().toString(),
      name,
      type,
      format,
      date: new Date().toLocaleString('fr-FR'),
      size,
      downloadCount: 0
    };
    
    const updatedHistory = [newExport, ...exportHistory];
    setExportHistory(updatedHistory);
    saveExportHistory(updatedHistory);
  };

  const exportOptions = [
    {
      id: 'transactions',
      title: 'Transactions',
      description: 'Export de toutes les transactions (ventes, réparations, dépenses)',
      icon: <TableChart />,
      formats: ['excel', 'pdf']
    },
    {
      id: 'invoices',
      title: 'Factures',
      description: 'Export des factures avec détails clients et paiements',
      icon: <Assessment />,
      formats: ['excel', 'pdf']
    },
    {
      id: 'expenses',
      title: 'Dépenses',
      description: 'Export des dépenses par catégorie et période',
      icon: <TableChart />,
      formats: ['excel', 'pdf']
    },
    {
      id: 'financial_report',
      title: 'Rapport Financier',
      description: 'Rapport complet avec KPIs et analyses',
      icon: <Assessment />,
      formats: ['pdf']
    }
  ];

  const dateRangeOptions = [
    { value: 'last7days', label: '7 derniers jours' },
    { value: 'last30days', label: '30 derniers jours' },
    { value: 'last3months', label: '3 derniers mois' },
    { value: 'lastyear', label: 'Dernière année' },
    { value: 'custom', label: 'Période personnalisée' }
  ];

  const handleExport = async () => {
    try {
      setIsLoading(true);
      
      // Recharger les données pour s'assurer qu'elles sont à jour
      await loadSales();
      await loadRepairs();
      await loadExpenses();
      await loadClients();

      // Attendre un peu pour que les données soient mises à jour
      await new Promise(resolve => setTimeout(resolve, 100));

      // Récupérer les données mises à jour
      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();

      console.log('Export avec vraies données:', { 
        sales: updatedSales.length, 
        repairs: updatedRepairs.length, 
        expenses: updatedExpenses.length,
        clients: updatedClients.length 
      });

      // Générer les données selon le type sélectionné avec les vraies données
      let dataToExport: any[] = [];
      let fileName = '';
      
      switch (selectedData) {
        case 'transactions':
          dataToExport = generateTransactionsData(updatedSales, updatedRepairs, updatedExpenses, updatedClients);
          fileName = 'transactions_comptables';
          break;
          
        case 'invoices':
          dataToExport = generateInvoicesData(updatedSales, updatedRepairs, updatedClients);
          fileName = 'factures';
          break;
          
        case 'expenses':
          dataToExport = generateExpensesData(updatedExpenses);
          fileName = 'depenses';
          break;
          
        case 'financial_report':
          dataToExport = generateFinancialReportData(updatedSales, updatedRepairs, updatedExpenses);
          fileName = 'rapport_financier';
          break;
          
        default:
          throw new Error('Type de données non supporté');
      }
      
      if (selectedFormat === 'excel') {
        // Export Excel
        exportToExcel(dataToExport, fileName);
        // Ajouter à l'historique
        addToHistory(
          `Export ${selectedData} - ${dateRange}`,
          selectedData,
          'Excel',
          `${dataToExport.length} lignes`
        );
      } else if (selectedFormat === 'pdf') {
        // Export PDF
        exportToPDF(dataToExport, fileName);
        // Ajouter à l'historique
        addToHistory(
          `Export ${selectedData} - ${dateRange}`,
          selectedData,
          'PDF',
          `${dataToExport.length} lignes`
        );
      }
      
    } catch (error) {
      console.error('Erreur lors de l\'export:', error);
      alert('Erreur lors de l\'export des données');
    } finally {
      setIsLoading(false);
    }
  };

  // Fonctions de génération de données avec les vraies données
  const generateTransactionsData = (salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    const transactions: any[] = [];

    // Ajouter les ventes
    salesData.forEach(sale => {
      const client = clientsData.find(c => c.id === sale.clientId);
      transactions.push({
        Date: new Date(sale.createdAt).toLocaleDateString('fr-FR'),
        Type: 'Vente',
        Description: `Vente #${sale.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        Montant: sale.total || 0,
        Statut: sale.status === 'completed' ? 'Terminé' : 'En cours'
      });
    });

    // Ajouter les réparations
    repairsData.forEach(repair => {
      const client = clientsData.find(c => c.id === repair.clientId);
      transactions.push({
        Date: new Date(repair.createdAt).toLocaleDateString('fr-FR'),
        Type: 'Réparation',
        Description: `Réparation #${repair.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        Montant: repair.totalPrice || 0,
        Statut: repair.status === 'completed' ? 'Terminé' : 'En cours'
      });
    });

    // Ajouter les dépenses
    expensesData.forEach(expense => {
      transactions.push({
        Date: new Date(expense.expenseDate).toLocaleDateString('fr-FR'),
        Type: 'Dépense',
        Description: expense.title || 'Dépense',
        Client: '',
        Montant: -(expense.amount || 0),
        Statut: expense.status === 'paid' ? 'Payé' : 'En attente'
      });
    });

    // Trier par date (plus récent en premier)
    return transactions.sort((a, b) => new Date(b.Date.split('/').reverse().join('-')).getTime() - new Date(a.Date.split('/').reverse().join('-')).getTime());
  };

  const generateInvoicesData = (salesData: any[], repairsData: any[], clientsData: any[]) => {
    const invoices: any[] = [];

    // Ajouter les ventes comme factures
    salesData.forEach(sale => {
      const client = clientsData.find(c => c.id === sale.clientId);
      invoices.push({
        'Numéro': `FAC-${sale.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        'Date Émission': new Date(sale.createdAt).toLocaleDateString('fr-FR'),
        'Date Échéance': new Date(new Date(sale.createdAt).getTime() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString('fr-FR'),
        Montant: sale.total || 0,
        Statut: sale.status === 'completed' ? 'Payée' : 'En attente'
      });
    });

    // Ajouter les réparations comme factures
    repairsData.forEach(repair => {
      const client = clientsData.find(c => c.id === repair.clientId);
      invoices.push({
        'Numéro': `FAC-${repair.id.substring(0, 8)}`,
        Client: client ? `${client.firstName} ${client.lastName}` : 'N/A',
        'Date Émission': new Date(repair.createdAt).toLocaleDateString('fr-FR'),
        'Date Échéance': new Date(new Date(repair.createdAt).getTime() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString('fr-FR'),
        Montant: repair.totalPrice || 0,
        Statut: repair.isPaid ? 'Payée' : 'En attente'
      });
    });

    return invoices.sort((a, b) => new Date(b['Date Émission'].split('/').reverse().join('-')).getTime() - new Date(a['Date Émission'].split('/').reverse().join('-')).getTime());
  };

  const generateExpensesData = (expensesData: any[]) => {
    return expensesData.map(expense => ({
      Titre: expense.title || 'Dépense',
      Catégorie: expense.tags?.[0] || 'Général',
      Fournisseur: expense.supplier || 'N/A',
      Date: new Date(expense.expenseDate).toLocaleDateString('fr-FR'),
      Montant: expense.amount || 0,
      Statut: expense.status === 'paid' ? 'Payé' : 'En attente'
    })).sort((a, b) => new Date(b.Date.split('/').reverse().join('-')).getTime() - new Date(a.Date.split('/').reverse().join('-')).getTime());
  };

  const generateFinancialReportData = (salesData: any[], repairsData: any[], expensesData: any[]) => {
    // Calculer les revenus et dépenses par mois
    const monthlyData = new Map<string, { revenus: number, depenses: number }>();
    
    // Revenus par mois
    [...salesData, ...repairsData].forEach(item => {
      const date = new Date(item.createdAt);
      const month = date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      const amount = item.total || item.totalPrice || 0;
      
      if (!monthlyData.has(month)) {
        monthlyData.set(month, { revenus: 0, depenses: 0 });
      }
      monthlyData.get(month)!.revenus += amount;
    });

    // Dépenses par mois
    expensesData.forEach(expense => {
      const date = new Date(expense.expenseDate);
      const month = date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      const amount = expense.amount || 0;
      
      if (!monthlyData.has(month)) {
        monthlyData.set(month, { revenus: 0, depenses: 0 });
      }
      monthlyData.get(month)!.depenses += amount;
    });

    // Convertir en tableau
    return Array.from(monthlyData.entries()).map(([periode, data]) => {
      const beneficeNet = data.revenus - data.depenses;
      const marge = data.revenus > 0 ? ((beneficeNet / data.revenus) * 100).toFixed(1) : '0';
      
      return {
        Période: periode,
        Revenus: data.revenus,
        Dépenses: data.depenses,
        'Bénéfice Net': beneficeNet,
        Marge: `${marge}%`
      };
    }).sort((a, b) => new Date(b.Période.split(' ')[1] + '-' + (new Date(b.Période.split(' ')[0] + ' 1, ' + b.Période.split(' ')[1]).getMonth() + 1)).getTime() - new Date(a.Période.split(' ')[1] + '-' + (new Date(a.Période.split(' ')[0] + ' 1, ' + a.Période.split(' ')[1]).getMonth() + 1)).getTime());
  };

  // Fonction d'export Excel
  const exportToExcel = (data: any[], fileName: string) => {
    // Créer un CSV simple (format compatible Excel)
    const headers = Object.keys(data[0]);
    const csvContent = [
      headers.join(','),
      ...data.map(row => headers.map(header => `"${row[header] || ''}"`).join(','))
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

  // Fonction d'export PDF
  const exportToPDF = (data: any[], fileName: string) => {
    // Créer un PDF simple avec les données
    const headers = Object.keys(data[0]);
    let pdfContent = `RAPPORT: ${fileName.toUpperCase()}\n`;
    pdfContent += `Généré le: ${new Date().toLocaleDateString('fr-FR')}\n\n`;
    
    // En-têtes
    pdfContent += headers.join('\t') + '\n';
    pdfContent += '-'.repeat(headers.join('\t').length) + '\n';
    
    // Données
    data.forEach(row => {
      pdfContent += headers.map(header => row[header] || '').join('\t') + '\n';
    });
    
    const blob = new Blob([pdfContent], { type: 'text/plain;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `${fileName}.txt`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const getFormatIcon = (format: string) => {
    return format === 'pdf' ? <PictureAsPdf /> : <TableChart />;
  };

  const getFormatColor = (format: string) => {
    return format === 'pdf' ? 'error' : 'success';
  };

  return (
    <Box>
      <Typography variant="h5" gutterBottom sx={{ mb: 3, fontWeight: 'medium' }}>
        Centre d'Exports
      </Typography>

      {/* Message d'information sur les vraies données */}
      <Alert severity="info" sx={{ mb: 3 }}>
        <Typography variant="body2">
          <strong>Export des vraies données :</strong> Les exports utilisent maintenant les vraies données de votre atelier.
          {sales.length > 0 || repairs.length > 0 || expenses.length > 0 ? (
            <span> Données disponibles : {sales.length} ventes, {repairs.length} réparations, {expenses.length} dépenses.</span>
          ) : (
            <span> Aucune donnée disponible pour le moment.</span>
          )}
        </Typography>
      </Alert>

      <Grid container spacing={3}>
        {/* Options d'export */}
        <Grid item xs={12} md={8}>
          <Typography variant="h6" gutterBottom>
            Choisir les données à exporter
          </Typography>
          
          <Grid container spacing={2}>
            {exportOptions.map((option) => (
              <Grid item xs={12} sm={6} key={option.id}>
                <Card 
                  sx={{ 
                    cursor: 'pointer',
                    border: selectedData === option.id ? '2px solid' : '1px solid',
                    borderColor: selectedData === option.id ? 'primary.main' : 'divider',
                    '&:hover': { borderColor: 'primary.main' }
                  }}
                  onClick={() => setSelectedData(option.id)}
                >
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      {option.icon}
                      <Typography variant="h6" sx={{ ml: 1 }}>
                        {option.title}
                      </Typography>
                    </Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      {option.description}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                      {option.formats.map((format) => (
                        <Chip
                          key={format}
                          icon={getFormatIcon(format)}
                          label={format.toUpperCase()}
                          color={getFormatColor(format) as any}
                          size="small"
                        />
                      ))}
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Grid>

        {/* Configuration */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Configuration
              </Typography>
              
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Format d'export</InputLabel>
                <Select
                  value={selectedFormat}
                  label="Format d'export"
                  onChange={(e) => setSelectedFormat(e.target.value)}
                >
                  <MenuItem value="excel">
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <TableChart sx={{ mr: 1 }} />
                      Excel (.xlsx)
                    </Box>
                  </MenuItem>
                  <MenuItem value="pdf">
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <PictureAsPdf sx={{ mr: 1 }} />
                      PDF
                    </Box>
                  </MenuItem>
                </Select>
              </FormControl>

              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Période</InputLabel>
                <Select
                  value={dateRange}
                  label="Période"
                  onChange={(e) => setDateRange(e.target.value)}
                >
                  {dateRangeOptions.map((option) => (
                    <MenuItem key={option.value} value={option.value}>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <DateRange sx={{ mr: 1 }} />
                        {option.label}
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {dateRange === 'custom' && (
                <Box sx={{ mb: 2 }}>
                  <TextField
                    label="Date de début"
                    type="date"
                    fullWidth
                    size="small"
                    sx={{ mb: 1 }}
                    InputLabelProps={{ shrink: true }}
                  />
                  <TextField
                    label="Date de fin"
                    type="date"
                    fullWidth
                    size="small"
                    InputLabelProps={{ shrink: true }}
                  />
                </Box>
              )}

              <Divider sx={{ my: 2 }} />

              <Button
                variant="contained"
                fullWidth
                startIcon={isLoading ? <CircularProgress size={20} /> : <Download />}
                onClick={handleExport}
                size="large"
                disabled={isLoading}
              >
                {isLoading ? 'Export en cours...' : 'Exporter les données'}
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Historique des exports */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          Historique des exports ({exportHistory.length})
        </Typography>
        
        {exportHistory.length === 0 ? (
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 2 }}>
                Aucun export effectué pour le moment
              </Typography>
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardContent>
              {exportHistory.map((exportItem, index) => (
                <Box key={exportItem.id}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', py: 1 }}>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {exportItem.name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        Exporté le {exportItem.date} • {exportItem.size}
                      </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                      <Chip 
                        label={exportItem.format} 
                        color={exportItem.format === 'Excel' ? 'success' : 'error'} 
                        size="small" 
                      />
                      <Typography variant="caption" color="text.secondary">
                        {exportItem.downloadCount} téléchargement{exportItem.downloadCount > 1 ? 's' : ''}
                      </Typography>
                    </Box>
                  </Box>
                  {index < exportHistory.length - 1 && <Divider sx={{ my: 1 }} />}
                </Box>
              ))}
            </CardContent>
          </Card>
        )}
      </Box>
    </Box>
  );
};

export default ExportsCenterFixed;

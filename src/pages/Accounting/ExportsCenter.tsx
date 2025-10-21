import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Switch,
  FormControlLabel,
  Alert,
  CircularProgress,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  Paper,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  Chip,
} from '@mui/material';
import {
  FileDownload,
  Description,
  TableChart,
  Assessment,
  DateRange,
  CheckCircle,
  Download,
  Refresh,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { fr } from 'date-fns/locale';
import { theme } from '../../theme';
import { exportService } from '../../services/exportService';
import { accountingDataService } from '../../services/accountingDataService';
import { ExportOptions } from '../../types/accounting';

const ExportsCenter: React.FC = () => {
  const [activeStep, setActiveStep] = useState(0);
  const [exportOptions, setExportOptions] = useState<ExportOptions>({
    format: 'excel',
    dataType: 'all',
    includeCharts: true,
    groupBy: 'month'
  });
  const [startDate, setStartDate] = useState<Date | null>(null);
  const [endDate, setEndDate] = useState<Date | null>(null);
  const [isExporting, setIsExporting] = useState(false);
  const [exportProgress, setExportProgress] = useState(0);
  const [exportStatus, setExportStatus] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  const steps = [
    'Sélectionner le type de données',
    'Choisir le format d\'export',
    'Définir la période',
    'Options avancées',
    'Générer l\'export'
  ];

  const dataTypes = [
    { value: 'all', label: 'Toutes les données', description: 'Transactions, factures et dépenses' },
    { value: 'transactions', label: 'Transactions uniquement', description: 'Ventes et réparations' },
    { value: 'invoices', label: 'Factures uniquement', description: 'Toutes les factures' },
    { value: 'expenses', label: 'Dépenses uniquement', description: 'Toutes les dépenses' },
    { value: 'financial_report', label: 'Rapport financier', description: 'Rapport complet avec analyses' },
  ];

  const formats = [
    { value: 'excel', label: 'Excel (.xlsx)', description: 'Format tableur avec plusieurs feuilles' },
    { value: 'pdf', label: 'PDF (.pdf)', description: 'Document formaté pour impression' },
  ];

  const groupByOptions = [
    { value: 'day', label: 'Par jour' },
    { value: 'week', label: 'Par semaine' },
    { value: 'month', label: 'Par mois' },
    { value: 'year', label: 'Par année' },
  ];

  const handleNext = () => {
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleReset = () => {
    setActiveStep(0);
    setExportOptions({
      format: 'excel',
      dataType: 'all',
      includeCharts: true,
      groupBy: 'month'
    });
    setStartDate(null);
    setEndDate(null);
    setError(null);
  };

  const handleExport = async () => {
    try {
      setIsExporting(true);
      setError(null);
      setExportProgress(0);
      setExportStatus('Préparation des données...');

      // Simuler le progrès
      const progressInterval = setInterval(() => {
        setExportProgress(prev => {
          if (prev >= 90) {
            clearInterval(progressInterval);
            return prev;
          }
          return prev + 10;
        });
      }, 200);

      // Récupérer les données selon le type sélectionné
      let data: any = null;
      let filename = '';

      switch (exportOptions.dataType) {
        case 'transactions':
          setExportStatus('Récupération des transactions...');
          const transactionsResult = await accountingDataService.getAllTransactions({
            startDate: startDate || undefined,
            endDate: endDate || undefined
          });
          if (transactionsResult.success && transactionsResult.data) {
            data = transactionsResult.data;
            filename = `transactions_${getDateString(startDate)}_${getDateString(endDate)}`;
          }
          break;

        case 'invoices':
          setExportStatus('Récupération des factures...');
          const invoicesResult = await accountingDataService.getInvoices({
            startDate: startDate || undefined,
            endDate: endDate || undefined
          });
          if (invoicesResult.success && invoicesResult.data) {
            data = invoicesResult.data;
            filename = `factures_${getDateString(startDate)}_${getDateString(endDate)}`;
          }
          break;

        case 'expenses':
          setExportStatus('Récupération des dépenses...');
          const expensesResult = await accountingDataService.getExpenseSummary({
            startDate: startDate || undefined,
            endDate: endDate || undefined
          });
          if (expensesResult.success && expensesResult.data) {
            data = [expensesResult.data];
            filename = `depenses_${getDateString(startDate)}_${getDateString(endDate)}`;
          }
          break;

        case 'financial_report':
          setExportStatus('Génération du rapport financier...');
          const summaryResult = await accountingDataService.getFinancialSummary({
            startDate: startDate || undefined,
            endDate: endDate || undefined
          });
          if (summaryResult.success && summaryResult.data) {
            data = summaryResult.data;
            filename = `rapport_financier_${getDateString(startDate)}_${getDateString(endDate)}`;
          }
          break;

        default:
          setExportStatus('Récupération de toutes les données...');
          const allTransactionsResult = await accountingDataService.getAllTransactions({
            startDate: startDate || undefined,
            endDate: endDate || undefined
          });
          if (allTransactionsResult.success && allTransactionsResult.data) {
            data = allTransactionsResult.data;
            filename = `donnees_completes_${getDateString(startDate)}_${getDateString(endDate)}`;
          }
          break;
      }

      if (!data) {
        throw new Error('Aucune donnée à exporter');
      }

      setExportStatus('Génération du fichier...');

      // Générer l'export
      if (exportOptions.format === 'excel') {
        await exportService.exportToExcel(data, filename);
      } else {
        await exportService.exportToPDF(data, filename, `Export ${exportOptions.dataType}`, {
          headers: getHeadersForDataType(exportOptions.dataType)
        });
      }

      clearInterval(progressInterval);
      setExportProgress(100);
      setExportStatus('Export terminé avec succès !');
      
      setTimeout(() => {
        setIsExporting(false);
        setExportProgress(0);
        setExportStatus('');
      }, 2000);

    } catch (err) {
      console.error('Erreur lors de l\'export:', err);
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'export');
      setIsExporting(false);
      setExportProgress(0);
      setExportStatus('');
    }
  };

  const getDateString = (date: Date | null): string => {
    if (!date) return 'all';
    return date.toISOString().split('T')[0];
  };

  const getHeadersForDataType = (dataType: string): string[] => {
    switch (dataType) {
      case 'transactions':
        return ['Date', 'Type', 'Client', 'Montant', 'Statut', 'Méthode de paiement'];
      case 'invoices':
        return ['Numéro', 'Type', 'Client', 'Montant HT', 'TVA', 'Total TTC', 'Statut', 'Date d\'émission'];
      case 'expenses':
        return ['Total dépenses', 'Dépenses mensuelles', 'Nombre de dépenses', 'Moyenne'];
      default:
        return [];
    }
  };

  const getStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Box>
            <Typography variant="h6" gutterBottom>
              Sélectionnez le type de données à exporter
            </Typography>
            <Grid container spacing={2}>
              {dataTypes.map((type) => (
                <Grid item xs={12} md={6} key={type.value}>
                  <Card 
                    sx={{ 
                      cursor: 'pointer',
                      border: exportOptions.dataType === type.value ? 2 : 1,
                      borderColor: exportOptions.dataType === type.value ? 'primary.main' : 'divider',
                      '&:hover': { borderColor: 'primary.main' }
                    }}
                    onClick={() => setExportOptions(prev => ({ ...prev, dataType: type.value as any }))}
                  >
                    <CardContent>
                      <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>
                        {type.label}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {type.description}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        );

      case 1:
        return (
          <Box>
            <Typography variant="h6" gutterBottom>
              Choisissez le format d'export
            </Typography>
            <Grid container spacing={2}>
              {formats.map((format) => (
                <Grid item xs={12} md={6} key={format.value}>
                  <Card 
                    sx={{ 
                      cursor: 'pointer',
                      border: exportOptions.format === format.value ? 2 : 1,
                      borderColor: exportOptions.format === format.value ? 'primary.main' : 'divider',
                      '&:hover': { borderColor: 'primary.main' }
                    }}
                    onClick={() => setExportOptions(prev => ({ ...prev, format: format.value as any }))}
                  >
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                        {format.value === 'excel' ? <TableChart sx={{ mr: 1 }} /> : <Description sx={{ mr: 1 }} />}
                        <Typography variant="h6" sx={{ fontWeight: 600 }}>
                          {format.label}
                        </Typography>
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        {format.description}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        );

      case 2:
        return (
          <Box>
            <Typography variant="h6" gutterBottom>
              Définissez la période d'export
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <DatePicker
                  label="Date de début"
                  value={startDate}
                  onChange={(newValue) => setStartDate(newValue)}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                      helperText: 'Laissez vide pour inclure toutes les données'
                    }
                  }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <DatePicker
                  label="Date de fin"
                  value={endDate}
                  onChange={(newValue) => setEndDate(newValue)}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                      helperText: 'Laissez vide pour inclure toutes les données'
                    }
                  }}
                />
              </Grid>
            </Grid>
            <Alert severity="info" sx={{ mt: 2 }}>
              Si aucune date n'est sélectionnée, toutes les données disponibles seront exportées.
            </Alert>
          </Box>
        );

      case 3:
        return (
          <Box>
            <Typography variant="h6" gutterBottom>
              Options avancées
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Grouper par</InputLabel>
                  <Select
                    value={exportOptions.groupBy}
                    onChange={(e) => setExportOptions(prev => ({ ...prev, groupBy: e.target.value as any }))}
                    label="Grouper par"
                  >
                    {groupByOptions.map((option) => (
                      <MenuItem key={option.value} value={option.value}>
                        {option.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={exportOptions.includeCharts}
                      onChange={(e) => setExportOptions(prev => ({ ...prev, includeCharts: e.target.checked }))}
                    />
                  }
                  label="Inclure les graphiques"
                />
              </Grid>
            </Grid>
          </Box>
        );

      case 4:
        return (
          <Box>
            <Typography variant="h6" gutterBottom>
              Résumé de l'export
            </Typography>
            <Paper sx={{ p: 2, mb: 3 }}>
              <List>
                <ListItem>
                  <ListItemIcon>
                    <Description />
                  </ListItemIcon>
                  <ListItemText
                    primary="Type de données"
                    secondary={dataTypes.find(t => t.value === exportOptions.dataType)?.label}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <FileDownload />
                  </ListItemIcon>
                  <ListItemText
                    primary="Format"
                    secondary={formats.find(f => f.value === exportOptions.format)?.label}
                  />
                </ListItem>
                <ListItem>
                  <ListItemIcon>
                    <DateRange />
                  </ListItemIcon>
                  <ListItemText
                    primary="Période"
                    secondary={
                      startDate && endDate 
                        ? `${startDate.toLocaleDateString('fr-FR')} - ${endDate.toLocaleDateString('fr-FR')}`
                        : 'Toutes les données'
                    }
                  />
                </ListItem>
              </List>
            </Paper>

            {isExporting && (
              <Box sx={{ mb: 3 }}>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  {exportStatus}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Box sx={{ width: '100%' }}>
                    <Box
                      sx={{
                        width: '100%',
                        height: 8,
                        backgroundColor: 'rgba(0,0,0,0.1)',
                        borderRadius: 4,
                        overflow: 'hidden'
                      }}
                    >
                      <Box
                        sx={{
                          width: `${exportProgress}%`,
                          height: '100%',
                          backgroundColor: 'primary.main',
                          transition: 'width 0.3s ease'
                        }}
                      />
                    </Box>
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    {exportProgress}%
                  </Typography>
                </Box>
              </Box>
            )}

            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            <Box sx={{ display: 'flex', gap: 2 }}>
              <Button
                variant="contained"
                onClick={handleExport}
                disabled={isExporting}
                startIcon={isExporting ? <CircularProgress size={20} /> : <Download />}
                size="large"
              >
                {isExporting ? 'Export en cours...' : 'Générer l\'export'}
              </Button>
              <Button
                variant="outlined"
                onClick={handleReset}
                disabled={isExporting}
                startIcon={<Refresh />}
              >
                Recommencer
              </Button>
            </Box>
          </Box>
        );

      default:
        return 'Étape inconnue';
    }
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={fr}>
      <Box>
        {/* En-tête */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
            Centre d'exports
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Exportez vos données financières dans différents formats
          </Typography>
        </Box>

        {/* Assistant d'export */}
        <Card>
          <CardContent>
            <Stepper activeStep={activeStep} orientation="vertical">
              {steps.map((label, index) => (
                <Step key={label}>
                  <StepLabel>{label}</StepLabel>
                  <StepContent>
                    {getStepContent(index)}
                    <Box sx={{ mb: 2, mt: 2 }}>
                      <div>
                        <Button
                          variant="contained"
                          onClick={index === steps.length - 1 ? handleExport : handleNext}
                          sx={{ mt: 1, mr: 1 }}
                          disabled={isExporting}
                        >
                          {index === steps.length - 1 ? 'Générer l\'export' : 'Continuer'}
                        </Button>
                        <Button
                          disabled={index === 0 || isExporting}
                          onClick={handleBack}
                          sx={{ mt: 1, mr: 1 }}
                        >
                          Retour
                        </Button>
                      </div>
                    </Box>
                  </StepContent>
                </Step>
              ))}
            </Stepper>
          </CardContent>
        </Card>

        {/* Exports rapides */}
        <Card sx={{ mt: 3 }}>
          <CardContent>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
              Exports rapides
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6} md={3}>
                <Button
                  fullWidth
                  variant="outlined"
                  startIcon={<TableChart />}
                  onClick={() => {
                    setExportOptions(prev => ({ ...prev, dataType: 'transactions', format: 'excel' }));
                    setActiveStep(4);
                  }}
                >
                  Transactions Excel
                </Button>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Button
                  fullWidth
                  variant="outlined"
                  startIcon={<Description />}
                  onClick={() => {
                    setExportOptions(prev => ({ ...prev, dataType: 'invoices', format: 'pdf' }));
                    setActiveStep(4);
                  }}
                >
                  Factures PDF
                </Button>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Button
                  fullWidth
                  variant="outlined"
                  startIcon={<Assessment />}
                  onClick={() => {
                    setExportOptions(prev => ({ ...prev, dataType: 'financial_report', format: 'pdf' }));
                    setActiveStep(4);
                  }}
                >
                  Rapport PDF
                </Button>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Button
                  fullWidth
                  variant="outlined"
                  startIcon={<FileDownload />}
                  onClick={() => {
                    setExportOptions(prev => ({ ...prev, dataType: 'all', format: 'excel' }));
                    setActiveStep(4);
                  }}
                >
                  Tout Excel
                </Button>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Box>
    </LocalizationProvider>
  );
};

export default ExportsCenter;

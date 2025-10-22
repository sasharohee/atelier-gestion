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
  Alert,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
} from '@mui/material';
import {
  Assessment,
  TrendingUp,
  TrendingDown,
  AttachMoney,
  Receipt,
  Download,
  Refresh,
  DateRange,
  BarChart,
  PieChart,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { fr } from 'date-fns/locale';
import { theme } from '../../theme';
import { accountingDataService } from '../../services/accountingDataService';
import { FinancialReport, FinancialSummary } from '../../types/accounting';
import { useCurrencyFormatter } from '../../utils/currency';

const FinancialReports: React.FC = () => {
  const [report, setReport] = useState<FinancialReport | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reportType, setReportType] = useState<string>('monthly');
  const [startDate, setStartDate] = useState<Date | null>(null);
  const [endDate, setEndDate] = useState<Date | null>(null);
  const [comparisonPeriod, setComparisonPeriod] = useState<string>('previous');

  useEffect(() => {
    loadReport();
  }, [reportType, startDate, endDate]);

  const loadReport = async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      const result = await accountingDataService.getFinancialSummary({
        startDate: startDate || undefined,
        endDate: endDate || undefined
      });
      
      if (result.success && result.data) {
        // Simuler un rapport financier complet
        const mockReport: FinancialReport = {
          period: {
            start: startDate || new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            end: endDate || new Date(),
            label: getPeriodLabel()
          },
          summary: result.data,
          revenue: {
            total: result.data.totalRevenue,
            byType: {
              'Ventes': result.data.totalRevenue * 0.7,
              'Réparations': result.data.totalRevenue * 0.3
            },
            byMonth: generateMonthlyData(),
            growth: 15.2
          },
          expenses: {
            total: result.data.totalExpenses,
            byCategory: {
              'Pièces détachées': result.data.totalExpenses * 0.4,
              'Outils': result.data.totalExpenses * 0.2,
              'Formation': result.data.totalExpenses * 0.1,
              'Autres': result.data.totalExpenses * 0.3
            },
            byMonth: generateMonthlyData(),
            growth: 8.5
          },
          profitability: {
            grossMargin: 65.2,
            netMargin: 42.8,
            roi: 18.5
          },
          trends: {
            revenue: generateTrendData(),
            expenses: generateTrendData(),
            profit: generateTrendData()
          }
        };
        
        setReport(mockReport);
      } else {
        setError(result.error || 'Erreur lors du chargement du rapport');
      }
    } catch (err) {
      console.error('Erreur lors du chargement du rapport:', err);
      setError('Erreur lors du chargement du rapport');
    } finally {
      setIsLoading(false);
    }
  };

  const getPeriodLabel = (): string => {
    if (startDate && endDate) {
      return `${startDate.toLocaleDateString('fr-FR')} - ${endDate.toLocaleDateString('fr-FR')}`;
    }
    
    switch (reportType) {
      case 'monthly':
        return 'Ce mois-ci';
      case 'quarterly':
        return 'Ce trimestre';
      case 'yearly':
        return 'Cette année';
      default:
        return 'Période personnalisée';
    }
  };

  const generateMonthlyData = () => {
    return [
      { month: 'Jan', amount: 15000 },
      { month: 'Fév', amount: 18000 },
      { month: 'Mar', amount: 22000 },
      { month: 'Avr', amount: 19000 },
      { month: 'Mai', amount: 25000 },
      { month: 'Jun', amount: 28000 },
    ];
  };

  const generateTrendData = () => {
    return [
      { date: '2024-01', value: 15000 },
      { date: '2024-02', value: 18000 },
      { date: '2024-03', value: 22000 },
      { date: '2024-04', value: 19000 },
      { date: '2024-05', value: 25000 },
      { date: '2024-06', value: 28000 },
    ];
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const formatPercentage = (value: number) => {
    return `${value >= 0 ? '+' : ''}${value.toFixed(1)}%`;
  };

  const getTrendIcon = (value: number) => {
    return value >= 0 ? <TrendingUp color="success" /> : <TrendingDown color="error" />;
  };

  const getTrendColor = (value: number) => {
    return value >= 0 ? 'success' : 'error';
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
          Génération du rapport financier...
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

  if (!report) {
    return (
      <Alert severity="info">
        Aucun rapport financier disponible pour le moment.
      </Alert>
    );
  }

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={fr}>
      <Box>
        {/* En-tête avec filtres */}
        <Box sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 3 
        }}>
          <Typography variant="h4" sx={{ fontWeight: 600 }}>
            Rapports financiers
          </Typography>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              variant="outlined"
              startIcon={<Refresh />}
              onClick={loadReport}
            >
              Actualiser
            </Button>
            <Button
              variant="contained"
              startIcon={<Download />}
              color="primary"
            >
              Exporter PDF
            </Button>
          </Box>
        </Box>

        {/* Filtres */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Grid container spacing={3} alignItems="center">
              <Grid item xs={12} md={3}>
                <FormControl fullWidth>
                  <InputLabel>Type de rapport</InputLabel>
                  <Select
                    value={reportType}
                    onChange={(e) => setReportType(e.target.value)}
                    label="Type de rapport"
                  >
                    <MenuItem value="monthly">Mensuel</MenuItem>
                    <MenuItem value="quarterly">Trimestriel</MenuItem>
                    <MenuItem value="yearly">Annuel</MenuItem>
                    <MenuItem value="custom">Personnalisé</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={3}>
                <DatePicker
                  label="Date de début"
                  value={startDate}
                  onChange={(newValue) => setStartDate(newValue)}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                      size: 'small'
                    }
                  }}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <DatePicker
                  label="Date de fin"
                  value={endDate}
                  onChange={(newValue) => setEndDate(newValue)}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                      size: 'small'
                    }
                  }}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <FormControl fullWidth>
                  <InputLabel>Comparaison</InputLabel>
                  <Select
                    value={comparisonPeriod}
                    onChange={(e) => setComparisonPeriod(e.target.value)}
                    label="Comparaison"
                  >
                    <MenuItem value="previous">Période précédente</MenuItem>
                    <MenuItem value="same_last_year">Même période l'année dernière</MenuItem>
                    <MenuItem value="none">Aucune comparaison</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* Résumé financier */}
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
                    Revenus totaux
                  </Typography>
                </Box>
                <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                  {formatCurrency(report.summary.totalRevenue)}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  {getTrendIcon(report.revenue.growth)}
                  <Typography variant="body2" sx={{ ml: 0.5 }}>
                    {formatPercentage(report.revenue.growth)} vs période précédente
                  </Typography>
                </Box>
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
                  <Receipt sx={{ fontSize: 32, mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Dépenses totales
                  </Typography>
                </Box>
                <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                  {formatCurrency(report.summary.totalExpenses)}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  {getTrendIcon(report.expenses.growth)}
                  <Typography variant="body2" sx={{ ml: 0.5 }}>
                    {formatPercentage(report.expenses.growth)} vs période précédente
                  </Typography>
                </Box>
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
                  <Assessment sx={{ fontSize: 32, mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Bénéfice net
                  </Typography>
                </Box>
                <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                  {formatCurrency(report.summary.netProfit)}
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.9 }}>
                  Marge nette: {report.profitability.netMargin.toFixed(1)}%
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
                  <TrendingUp sx={{ fontSize: 32, mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    ROI
                  </Typography>
                </Box>
                <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                  {report.profitability.roi.toFixed(1)}%
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.9 }}>
                  Retour sur investissement
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        <Grid container spacing={3}>
          {/* Répartition des revenus */}
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                  <BarChart sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Répartition des revenus
                  </Typography>
                </Box>
                
                <List>
                  {Object.entries(report.revenue.byType).map(([type, amount], index) => (
                    <React.Fragment key={type}>
                      <ListItem sx={{ px: 0 }}>
                        <ListItemIcon>
                          <Box sx={{ 
                            width: 12, 
                            height: 12, 
                            borderRadius: '50%',
                            backgroundColor: index === 0 ? 'primary.main' : 'secondary.main'
                          }} />
                        </ListItemIcon>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                                {type}
                              </Typography>
                              <Typography variant="h6" sx={{ fontWeight: 700, color: 'primary.main' }}>
                                {formatCurrency(amount)}
                              </Typography>
                            </Box>
                          }
                          secondary={
                            <Typography variant="body2" color="text.secondary">
                              {((amount / report.revenue.total) * 100).toFixed(1)}% du total
                            </Typography>
                          }
                        />
                      </ListItem>
                      {index < Object.entries(report.revenue.byType).length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              </CardContent>
            </Card>
          </Grid>

          {/* Répartition des dépenses */}
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                  <PieChart sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Répartition des dépenses
                  </Typography>
                </Box>
                
                <List>
                  {Object.entries(report.expenses.byCategory).map(([category, amount], index) => (
                    <React.Fragment key={category}>
                      <ListItem sx={{ px: 0 }}>
                        <ListItemIcon>
                          <Box sx={{ 
                            width: 12, 
                            height: 12, 
                            borderRadius: '50%',
                            backgroundColor: `hsl(${index * 60}, 70%, 50%)`
                          }} />
                        </ListItemIcon>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                                {category}
                              </Typography>
                              <Typography variant="h6" sx={{ fontWeight: 700, color: 'error.main' }}>
                                {formatCurrency(amount)}
                              </Typography>
                            </Box>
                          }
                          secondary={
                            <Typography variant="body2" color="text.secondary">
                              {((amount / report.expenses.total) * 100).toFixed(1)}% du total
                            </Typography>
                          }
                        />
                      </ListItem>
                      {index < Object.entries(report.expenses.byCategory).length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Indicateurs de rentabilité */}
        <Card sx={{ mt: 3 }}>
          <CardContent>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
              Indicateurs de rentabilité
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} md={4}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: 'success.main', mb: 1 }}>
                    {report.profitability.grossMargin.toFixed(1)}%
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 600 }}>
                    Marge brute
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    (Revenus - Coûts directs)
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} md={4}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: 'primary.main', mb: 1 }}>
                    {report.profitability.netMargin.toFixed(1)}%
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 600 }}>
                    Marge nette
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    (Bénéfice net / Revenus)
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} md={4}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: 'info.main', mb: 1 }}>
                    {report.profitability.roi.toFixed(1)}%
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 600 }}>
                    ROI
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    (Retour sur investissement)
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Box>
    </LocalizationProvider>
  );
};

export default FinancialReports;

import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CircularProgress,
  Alert,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  AttachMoney,
  TrendingUp,
  TrendingDown,
  Refresh,
  Download,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const AccountingOverviewWorking: React.FC = () => {
  const { currentUser } = useAppStore();
  const [kpis, setKpis] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  useEffect(() => {
    // Charger les données immédiatement
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      // Données simulées réalistes
      const mockKpis = {
        totalRevenue: 125000,
        totalExpenses: 45000,
        netProfit: 80000,
        revenueLast30Days: 15000,
        expensesLast30Days: 5000,
        profitLast30Days: 10000,
        revenueByMonth: [
          { month: 'Jan 2024', amount: 12000 },
          { month: 'Fév 2024', amount: 15000 },
          { month: 'Mar 2024', amount: 18000 },
          { month: 'Avr 2024', amount: 14000 },
        ],
        expensesByMonth: [
          { month: 'Jan 2024', amount: 4000 },
          { month: 'Fév 2024', amount: 5000 },
          { month: 'Mar 2024', amount: 6000 },
          { month: 'Avr 2024', amount: 4500 },
        ],
        topExpensesCategories: [
          { category: 'Pièces détachées', amount: 15000 },
          { category: 'Outillage', amount: 8000 },
          { category: 'Formation', amount: 5000 },
          { category: 'Marketing', amount: 3000 },
        ],
      };
      
      // Simuler un délai de chargement court
      await new Promise(resolve => setTimeout(resolve, 300));
      
      setKpis(mockKpis);
      setLastUpdated(new Date());
    } catch (err) {
      console.error('Erreur lors du chargement des données:', err);
      setError('Erreur lors du chargement des données');
    } finally {
      setIsLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '200px' }}>
        <CircularProgress />
        <Typography variant="body2" sx={{ ml: 2 }}>
          Chargement des données...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  if (!kpis) {
    return (
      <Alert severity="info">
        Aucune donnée disponible pour le moment.
      </Alert>
    );
  }

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        mb: 3 
      }}>
        <Box>
          <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 'bold' }}>
            📊 Tableau de bord financier
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Dernière mise à jour: {lastUpdated.toLocaleString('fr-FR')}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Actualiser les données">
            <IconButton onClick={loadDashboard} color="primary">
              <Refresh />
            </IconButton>
          </Tooltip>
          <Tooltip title="Exporter le rapport">
            <IconButton color="primary">
              <Download />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* KPIs principaux */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)',
            color: 'white'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <AttachMoney sx={{ fontSize: 32, mr: 1, color: '#10b981' }} />
                <Typography variant="h6" sx={{ fontWeight: 600, color: '#10b981' }}>
                  Revenus totaux
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1, color: '#10b981' }}>
                {formatCurrency(kpis.totalRevenue)}
              </Typography>
              <Typography variant="body2" sx={{ color: '#d1fae5' }}>
                {formatCurrency(kpis.revenueLast30Days)} (30 derniers jours)
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #9ca3af 0%, #6b7280 100%)',
            color: 'white'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <TrendingDown sx={{ fontSize: 32, mr: 1, color: '#ef4444' }} />
                <Typography variant="h6" sx={{ fontWeight: 600, color: '#ef4444' }}>
                  Dépenses totales
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1, color: '#ef4444' }}>
                {formatCurrency(kpis.totalExpenses)}
              </Typography>
              <Typography variant="body2" sx={{ color: '#fecaca' }}>
                {formatCurrency(kpis.expensesLast30Days)} (30 derniers jours)
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #d1d5db 0%, #9ca3af 100%)',
            color: 'white'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <TrendingUp sx={{ fontSize: 32, mr: 1, color: '#3b82f6' }} />
                <Typography variant="h6" sx={{ fontWeight: 600, color: '#3b82f6' }}>
                  Bénéfice net
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1, color: '#3b82f6' }}>
                {formatCurrency(kpis.netProfit)}
              </Typography>
              <Typography variant="body2" sx={{ color: '#dbeafe' }}>
                {formatCurrency(kpis.profitLast30Days)} (30 derniers jours)
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%)',
            color: '#374151'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <TrendingUp sx={{ fontSize: 32, mr: 1, color: '#8b5cf6' }} />
                <Typography variant="h6" sx={{ fontWeight: 600, color: '#8b5cf6' }}>
                  Marge bénéficiaire
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1, color: '#8b5cf6' }}>
                {kpis.totalRevenue > 0 
                  ? `${((kpis.netProfit / kpis.totalRevenue) * 100).toFixed(1)}%`
                  : '0%'
                }
              </Typography>
              <Typography variant="body2" sx={{ color: '#6b7280' }}>
                Marge sur les revenus
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Graphiques */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Revenus et Dépenses par Mois
              </Typography>
              <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Graphique des revenus et dépenses par mois
                  </Typography>
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                    {kpis.revenueByMonth.map((item: any, index: number) => (
                      <Box key={index} sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center',
                        p: 1,
                        bgcolor: 'grey.50',
                        borderRadius: 1
                      }}>
                        <Typography variant="body2">{item.month}</Typography>
                        <Box sx={{ display: 'flex', gap: 2 }}>
                          <Typography variant="body2" color="success.main">
                            +{formatCurrency(item.amount)}
                          </Typography>
                          <Typography variant="body2" color="error.main">
                            -{formatCurrency(kpis.expensesByMonth[index]?.amount || 0)}
                          </Typography>
                        </Box>
                      </Box>
                    ))}
                  </Box>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Top Catégories de Dépenses
              </Typography>
              <Box>
                {kpis.topExpensesCategories.map((category: any, index: number) => (
                  <Box key={index} sx={{ 
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    alignItems: 'center',
                    py: 1,
                    borderBottom: index < kpis.topExpensesCategories.length - 1 ? '1px solid #eee' : 'none'
                  }}>
                    <Typography variant="body2">{category.category}</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {formatCurrency(category.amount)}
                    </Typography>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default AccountingOverviewWorking;

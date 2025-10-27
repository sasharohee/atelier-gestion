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
  Button,
} from '@mui/material';
import {
  AttachMoney,
  TrendingUp,
  TrendingDown,
  Refresh,
  Download,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useCurrencyFormatter } from '../../utils/currency';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

const AccountingOverviewSimple: React.FC = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [kpis, setKpis] = useState<any>(null);

  // Récupérer les fonctions du store
  const store = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => {
    loadAllData();
  }, []);

  const loadAllData = async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      console.log('🚀 SIMPLE: Début du chargement des données...');
      
      // Charger toutes les données en parallèle
      const promises = [
        store.loadSales(),
        store.loadRepairs(),
        store.loadExpenses(),
        store.loadClients(),
      ];
      
      await Promise.all(promises);
      
      // Attendre un peu pour que les données soient mises à jour
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Récupérer les données fraîches du store
      const currentState = useAppStore.getState();
      const { sales, repairs, expenses, clients } = currentState;
      
      console.log('📊 SIMPLE: Données récupérées:', {
        sales: sales.length,
        repairs: repairs.length,
        expenses: expenses.length,
        clients: clients.length
      });

      // Afficher les détails des données
      if (sales.length > 0) {
        console.log('💰 SIMPLE: Première vente:', sales[0]);
        console.log('💰 SIMPLE: Total première vente:', sales[0].total);
      }
      if (repairs.length > 0) {
        console.log('🔧 SIMPLE: Première réparation:', repairs[0]);
        console.log('🔧 SIMPLE: Prix première réparation:', repairs[0].totalPrice);
      }
      if (expenses.length > 0) {
        console.log('💸 SIMPLE: Première dépense:', expenses[0]);
        console.log('💸 SIMPLE: Montant première dépense:', expenses[0].amount);
      }

      // Calculer les KPIs
      const calculatedKpis = calculateKPIs(sales, repairs, expenses);
      console.log('📈 SIMPLE: KPIs calculés:', calculatedKpis);
      
      setKpis(calculatedKpis);
      setLastUpdated(new Date());
      
    } catch (err) {
      console.error('❌ SIMPLE: Erreur lors du chargement:', err);
      setError('Erreur lors du chargement des données');
    } finally {
      setIsLoading(false);
    }
  };

  const calculateKPIs = (salesData: any[], repairsData: any[], expensesData: any[]) => {
    console.log('🧮 SIMPLE: Calcul des KPIs...');
    
    // Calculer les revenus totaux
    let totalSales = 0;
    let totalRepairs = 0;
    
    salesData.forEach((sale, index) => {
      const amount = sale.total || 0;
      totalSales += amount;
      console.log(`💰 SIMPLE: Vente ${index + 1} (${sale.id}): ${amount}€`);
    });
    
    repairsData.forEach((repair, index) => {
      const amount = repair.totalPrice || 0;
      totalRepairs += amount;
      console.log(`🔧 SIMPLE: Réparation ${index + 1} (${repair.id}): ${amount}€`);
    });
    
    const totalRevenue = totalSales + totalRepairs;
    
    // Calculer les dépenses totales
    let totalExpenses = 0;
    expensesData.forEach((expense, index) => {
      const amount = expense.amount || 0;
      totalExpenses += amount;
      console.log(`💸 SIMPLE: Dépense ${index + 1} (${expense.id}): ${amount}€`);
    });
    
    const netProfit = totalRevenue - totalExpenses;
    
    console.log('📊 SIMPLE: Totaux:', {
      totalSales,
      totalRepairs,
      totalRevenue,
      totalExpenses,
      netProfit
    });
    
    // Calculer les 30 derniers jours
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const revenueLast30Days = [
      ...salesData.filter(sale => new Date(sale.createdAt) >= thirtyDaysAgo),
      ...repairsData.filter(repair => new Date(repair.createdAt) >= thirtyDaysAgo)
    ].reduce((sum, item) => sum + (item.total || item.totalPrice || 0), 0);
    
    const expensesLast30Days = expensesData
      .filter(expense => new Date(expense.expenseDate) >= thirtyDaysAgo)
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);
    
    const profitLast30Days = revenueLast30Days - expensesLast30Days;
    
    return {
      totalRevenue,
      totalExpenses,
      netProfit,
      revenueLast30Days,
      expensesLast30Days,
      profitLast30Days,
      totalSales: salesData.length,
      totalRepairs: repairsData.length,
      totalExpensesCount: expensesData.length,
      paidRepairs: repairsData.filter(r => r.isPaid).length,
      completedSales: salesData.length,
    };
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
          Chargement des données réelles...
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

  const hasData = kpis && (kpis.completedSales > 0 || kpis.completedRepairs > 0 || kpis.totalExpenses > 0);
  
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
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadAllData}
            disabled={isLoading}
          >
            Recharger
          </Button>
          <Tooltip title="Exporter le rapport">
            <IconButton color="primary">
              <Download />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* Message d'information si pas de données */}
      {!hasData && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            Aucune donnée financière disponible pour le moment. 
            Commencez par ajouter des ventes, réparations ou dépenses dans votre atelier.
          </Typography>
        </Alert>
      )}


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
                {kpis ? formatFromEUR(kpis.totalRevenue, currency) : formatFromEUR(0, currency)}
              </Typography>
              <Typography variant="body2" sx={{ color: '#d1fae5' }}>
                {kpis ? formatFromEUR(kpis.revenueLast30Days, currency) + ' (30 derniers jours)' : 'Aucune donnée disponible'}
              </Typography>
              {kpis && (
                <Typography variant="caption" sx={{ color: '#d1fae5', display: 'block', mt: 1 }}>
                  {kpis.completedSales || 0} ventes • {kpis.paidRepairs || 0} réparations payées
                </Typography>
              )}
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
                {kpis ? formatFromEUR(kpis.totalExpenses, currency) : formatFromEUR(0, currency)}
              </Typography>
              <Typography variant="body2" sx={{ color: '#fecaca' }}>
                {kpis ? formatFromEUR(kpis.expensesLast30Days, currency) + ' (30 derniers jours)' : 'Aucune donnée disponible'}
              </Typography>
              {kpis && (
                <Typography variant="caption" sx={{ color: '#fecaca', display: 'block', mt: 1 }}>
                  {kpis.totalExpensesCount || 0} dépenses enregistrées
                </Typography>
              )}
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
                {kpis ? formatFromEUR(kpis.netProfit, currency) : formatFromEUR(0, currency)}
              </Typography>
              <Typography variant="body2" sx={{ color: '#dbeafe' }}>
                {kpis ? formatFromEUR(kpis.profitLast30Days, currency) + ' (30 derniers jours)' : 'Aucune donnée disponible'}
              </Typography>
              {kpis && (
                <Typography variant="caption" sx={{ color: '#dbeafe', display: 'block', mt: 1 }}>
                  Marge: {kpis.totalRevenue > 0 ? `${((kpis.netProfit / kpis.totalRevenue) * 100).toFixed(1)}%` : '0%'}
                </Typography>
              )}
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
                {kpis && kpis.totalRevenue > 0 
                  ? `${((kpis.netProfit / kpis.totalRevenue) * 100).toFixed(1)}%`
                  : '0%'
                }
              </Typography>
              <Typography variant="body2" sx={{ color: '#6b7280' }}>
                Marge sur les revenus
              </Typography>
              {kpis && (
                <Typography variant="caption" sx={{ color: '#6b7280', display: 'block', mt: 1 }}>
                  {(kpis.totalSales || 0) + (kpis.totalRepairs || 0)} transactions totales
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

    </Box>
  );
};

export default AccountingOverviewSimple;
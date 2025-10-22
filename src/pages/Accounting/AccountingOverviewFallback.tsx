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
import { useCurrencyFormatter } from '../../utils/currency';

const AccountingOverviewFallback: React.FC = () => {
  const { 
    currentUser, 
    sales, 
    repairs, 
    expenses,
    loadSales,
    loadRepairs,
    loadExpenses,
    loadClients,
  } = useAppStore();
  
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [kpis, setKpis] = useState<any>(null);

  useEffect(() => {
    loadDashboard();
  }, [currentUser?.id, sales, repairs, expenses]);

  const loadDashboard = async () => {
    if (!currentUser?.id) {
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setError(null);
      
      console.log('🔄 Chargement des données comptables...');
      
      // Charger les données si elles ne sont pas disponibles
      if (sales.length === 0) {
        console.log('📊 Chargement des ventes...');
        await loadSales();
      }
      if (repairs.length === 0) {
        console.log('🔧 Chargement des réparations...');
        await loadRepairs();
      }
      if (expenses.length === 0) {
        console.log('💰 Chargement des dépenses...');
        await loadExpenses();
      }
      
      // Attendre un peu pour que les données soient mises à jour
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Récupérer les données mises à jour
      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses } = useAppStore.getState();
      
      console.log('Données disponibles après chargement:', { 
        sales: updatedSales.length, 
        repairs: updatedRepairs.length, 
        expenses: updatedExpenses.length,
        currentUser: currentUser?.id 
      });

      // Vérifier le contenu des données
      if (updatedSales.length > 0) {
        console.log('Première vente:', updatedSales[0]);
        console.log('Total première vente:', updatedSales[0].total);
      }
      if (updatedRepairs.length > 0) {
        console.log('Première réparation:', updatedRepairs[0]);
        console.log('Prix première réparation:', updatedRepairs[0].totalPrice);
      }
      if (updatedExpenses.length > 0) {
        console.log('Première dépense:', updatedExpenses[0]);
        console.log('Montant première dépense:', updatedExpenses[0].amount);
      }

      // Calculer les KPIs à partir des vraies données disponibles
      const calculatedKpis = calculateKPIs();
      console.log('KPIs calculés:', calculatedKpis);
      
      setKpis(calculatedKpis);
      setLastUpdated(new Date());
    } catch (err) {
      console.error('Erreur lors du chargement des données:', err);
      setError('Erreur lors du chargement des données');
    } finally {
      setIsLoading(false);
    }
  };

  const calculateKPIs = () => {
    // Récupérer les données les plus récentes du store
    const { sales: currentSales, repairs: currentRepairs, expenses: currentExpenses } = useAppStore.getState();
    
    console.log('=== DÉTAILS DES DONNÉES POUR CALCUL ===');
    console.log('Ventes:', currentSales.map(s => ({ id: s.id, status: s.status, total: s.total })));
    console.log('Réparations:', currentRepairs.map(r => ({ id: r.id, status: r.status, isPaid: r.isPaid, totalPrice: r.totalPrice })));
    console.log('Dépenses:', currentExpenses.map(e => ({ id: e.id, status: e.status, amount: e.amount })));

    // TEMPORAIRE : Inclure TOUTES les ventes et réparations pour tester
    const totalSales = currentSales
      .reduce((sum, sale) => sum + (sale.total || 0), 0);

    const totalRepairs = currentRepairs
      .reduce((sum, repair) => sum + (repair.totalPrice || 0), 0);

    const totalRevenue = totalSales + totalRepairs;

    console.log('Calculs (TOUTES les données):', { totalSales, totalRepairs, totalRevenue });

    // Calculer les dépenses totales - inclure TOUTES les dépenses
    const totalExpenses = currentExpenses
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);

    const netProfit = totalRevenue - totalExpenses;

    // Calculer les 30 derniers jours
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    // TEMPORAIRE : Inclure TOUTES les données des 30 derniers jours
    const revenueLast30Days = [
      ...currentSales.filter(sale => new Date(sale.createdAt) >= thirtyDaysAgo),
      ...currentRepairs.filter(repair => new Date(repair.createdAt) >= thirtyDaysAgo)
    ].reduce((sum, item) => sum + (item.total || item.totalPrice || 0), 0);

    const expensesLast30Days = currentExpenses
      .filter(expense => new Date(expense.expenseDate) >= thirtyDaysAgo)
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);

    const profitLast30Days = revenueLast30Days - expensesLast30Days;

    // Agrégation par mois
    const revenueByMonthMap = new Map<string, number>();
    const expensesByMonthMap = new Map<string, number>();

    // TEMPORAIRE : Inclure TOUTES les données par mois
    currentSales.forEach(sale => {
      const date = new Date(sale.createdAt);
      const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
      const amount = sale.total || 0;
      revenueByMonthMap.set(month, (revenueByMonthMap.get(month) || 0) + amount);
    });

    currentRepairs.forEach(repair => {
      const date = new Date(repair.createdAt);
      const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
      const amount = repair.totalPrice || 0;
      revenueByMonthMap.set(month, (revenueByMonthMap.get(month) || 0) + amount);
    });

    // Dépenses par mois - inclure TOUTES les dépenses
    currentExpenses.forEach(expense => {
      const date = new Date(expense.expenseDate);
      const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
      expensesByMonthMap.set(month, (expensesByMonthMap.get(month) || 0) + (expense.amount || 0));
    });

    const revenueByMonth = Array.from(revenueByMonthMap.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());

    const expensesByMonth = Array.from(expensesByMonthMap.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());

    // TEMPORAIRE : Inclure TOUTES les catégories de dépenses
    const expensesCategoriesMap = new Map<string, number>();
    currentExpenses.forEach(expense => {
      const category = expense.tags?.[0] || 'Général';
      expensesCategoriesMap.set(category, (expensesCategoriesMap.get(category) || 0) + (expense.amount || 0));
    });

    const topExpensesCategories = Array.from(expensesCategoriesMap.entries())
      .map(([category, amount]) => ({ category, amount }))
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 5);

    const result = {
      totalRevenue,
      totalExpenses,
      netProfit,
      revenueLast30Days,
      expensesLast30Days,
      profitLast30Days,
      revenueByMonth,
      expensesByMonth,
      topExpensesCategories,
      // Statistiques supplémentaires
      totalSales: currentSales.length,
      totalRepairs: currentRepairs.length,
      totalExpensesCount: currentExpenses.length,
      paidRepairs: currentRepairs.filter(r => r.isPaid).length,
      completedSales: currentSales.length, // TEMPORAIRE : compter toutes les ventes
    };

    console.log('=== RÉSULTATS FINAUX ===');
    console.log('KPIs calculés:', result);
    console.log('Revenus totaux:', totalRevenue);
    console.log('Dépenses totales:', totalExpenses);
    console.log('Bénéfice net:', netProfit);

    return result;
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

  // Toujours afficher quelque chose, même avec des données vides
  const hasData = sales.length > 0 || repairs.length > 0 || expenses.length > 0;
  
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
          {hasData ? (
            <Typography variant="caption" color="text.secondary">
              Données réelles de l'atelier • {sales.length} ventes • {repairs.length} réparations • {expenses.length} dépenses
            </Typography>
          ) : (
            <Typography variant="caption" color="text.secondary">
              Aucune donnée disponible - Commencez par ajouter des transactions
            </Typography>
          )}
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
                {hasData ? formatCurrency(kpis?.totalRevenue || 0) : '0,00 €'}
              </Typography>
              <Typography variant="body2" sx={{ color: '#d1fae5' }}>
                {hasData ? formatCurrency(kpis?.revenueLast30Days || 0) + ' (30 derniers jours)' : 'Aucune donnée disponible'}
              </Typography>
              {hasData && (
                <Typography variant="caption" sx={{ color: '#d1fae5', display: 'block', mt: 1 }}>
                  {kpis?.completedSales || 0} ventes • {kpis?.paidRepairs || 0} réparations payées
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
                {hasData ? formatCurrency(kpis?.totalExpenses || 0) : '0,00 €'}
              </Typography>
              <Typography variant="body2" sx={{ color: '#fecaca' }}>
                {hasData ? formatCurrency(kpis?.expensesLast30Days || 0) + ' (30 derniers jours)' : 'Aucune donnée disponible'}
              </Typography>
              {hasData && (
                <Typography variant="caption" sx={{ color: '#fecaca', display: 'block', mt: 1 }}>
                  {kpis?.totalExpensesCount || 0} dépenses enregistrées
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
                {hasData ? formatCurrency(kpis?.netProfit || 0) : '0,00 €'}
              </Typography>
              <Typography variant="body2" sx={{ color: '#dbeafe' }}>
                {hasData ? formatCurrency(kpis?.profitLast30Days || 0) + ' (30 derniers jours)' : 'Aucune donnée disponible'}
              </Typography>
              {hasData && (
                <Typography variant="caption" sx={{ color: '#dbeafe', display: 'block', mt: 1 }}>
                  Marge: {kpis?.totalRevenue > 0 ? `${((kpis.netProfit / kpis.totalRevenue) * 100).toFixed(1)}%` : '0%'}
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
                {hasData && kpis?.totalRevenue > 0 
                  ? `${((kpis.netProfit / kpis.totalRevenue) * 100).toFixed(1)}%`
                  : '0%'
                }
              </Typography>
              <Typography variant="body2" sx={{ color: '#6b7280' }}>
                Marge sur les revenus
              </Typography>
              {hasData && (
                <Typography variant="caption" sx={{ color: '#6b7280', display: 'block', mt: 1 }}>
                  {(kpis?.totalSales || 0) + (kpis?.totalRepairs || 0)} transactions totales
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Graphiques */}
      {hasData && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Revenus et Dépenses par Mois
                </Typography>
                {kpis?.revenueByMonth && kpis.revenueByMonth.length > 0 ? (
                  <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Box sx={{ textAlign: 'center', width: '100%' }}>
                      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        Évolution mensuelle des revenus et dépenses
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
                ) : (
                  <Typography variant="body2" color="text.secondary">
                    Aucune donnée de revenus par mois disponible
                  </Typography>
                )}
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Top Catégories de Dépenses
                </Typography>
                {kpis?.topExpensesCategories && kpis.topExpensesCategories.length > 0 ? (
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
                ) : (
                  <Typography variant="body2" color="text.secondary">
                    Aucune donnée de dépenses par catégorie disponible
                  </Typography>
                )}
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}
    </Box>
  );
};

export default AccountingOverviewFallback;

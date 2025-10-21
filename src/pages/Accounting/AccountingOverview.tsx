import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  Alert,
  Chip,
  Paper,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Divider,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  TrendingUp,
  TrendingDown,
  AttachMoney,
  Receipt,
  People,
  Assessment,
  Refresh,
  Download,
  Visibility,
} from '@mui/icons-material';
import { theme } from '../../theme';
import { accountingDataServiceSimple as accountingDataService } from '../../services/accountingDataServiceSimple';
import { AccountingKPIs } from '../../types/accounting';

const AccountingOverview: React.FC = () => {
  const [kpis, setKpis] = useState<AccountingKPIs | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    if (!currentUser?.id) return;

    try {
      setIsLoading(true);
      setError(null);
      
      const result = await accountingDataService.getAccountingKPIs(currentUser.id);
      
      if (result.success && result.data) {
        setKpis(result.data);
        setLastUpdated(new Date());
      } else {
        setError(result.error?.message || 'Erreur lors du chargement des données');
      }
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
          Chargement du tableau de bord...
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

  if (!kpis) {
    return (
      <Alert severity="info">
        Aucune donnée disponible pour le moment.
      </Alert>
    );
  }

  // Utiliser directement les KPIs

  return (
    <Box>
      {/* En-tête avec actions */}
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        mb: 3 
      }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
            Tableau de bord financier
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
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <AttachMoney sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Revenus totaux
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {formatCurrency(kpis.totalRevenue)}
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                {getTrendIcon(monthlyComparison.growth)}
                <Typography variant="body2" sx={{ ml: 0.5 }}>
                  {formatPercentage(monthlyComparison.growth)} ce mois
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
            color: 'white',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Receipt sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Dépenses totales
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {formatCurrency(kpis.totalExpenses)}
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Typography variant="body2">
                  {kpis.expenseGrowth.toFixed(1)}% ce mois
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
            color: 'white',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Assessment sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Bénéfice net
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {formatCurrency(kpis.netProfit)}
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Typography variant="body2">
                  Marge: {kpis.profitMargin.toFixed(1)}%
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ 
            height: '100%',
            background: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
            color: 'white',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <People sx={{ fontSize: 32, mr: 1 }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Transactions
                </Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
                {kpis.totalTransactions}
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Typography variant="body2">
                  Moyenne: {formatCurrency(kpis.averageTransactionValue)}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        {/* Transactions récentes */}
        <Grid item xs={12} md={8}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <Receipt sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Transactions récentes
                </Typography>
              </Box>
              
              {recentTransactions.length > 0 ? (
                <List>
                  {recentTransactions.slice(0, 5).map((transaction, index) => (
                    <React.Fragment key={transaction.id}>
                      <ListItem sx={{ px: 0 }}>
                        <ListItemAvatar>
                          <Avatar sx={{ 
                            bgcolor: transaction.type === 'sale' ? 'success.main' : 'primary.main',
                            width: 40,
                            height: 40
                          }}>
                            {transaction.type === 'sale' ? 'V' : 'R'}
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                                {transaction.clientName}
                              </Typography>
                              <Typography variant="h6" sx={{ fontWeight: 700, color: 'primary.main' }}>
                                {formatCurrency(transaction.amount)}
                              </Typography>
                            </Box>
                          }
                          secondary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 1 }}>
                              <Box sx={{ display: 'flex', gap: 1 }}>
                                <Chip 
                                  label={transaction.type === 'sale' ? 'Vente' : 'Réparation'} 
                                  size="small" 
                                  color={transaction.type === 'sale' ? 'success' : 'primary'}
                                  variant="outlined"
                                />
                                <Chip 
                                  label={transaction.isPaid ? 'Payé' : 'En attente'} 
                                  size="small" 
                                  color={transaction.isPaid ? 'success' : 'warning'}
                                  variant="outlined"
                                />
                              </Box>
                              <Typography variant="caption" color="text.secondary">
                                {transaction.date.toLocaleDateString('fr-FR')}
                              </Typography>
                            </Box>
                          }
                        />
                      </ListItem>
                      {index < recentTransactions.slice(0, 5).length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              ) : (
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body1" color="text.secondary">
                    Aucune transaction récente
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Top clients */}
        <Grid item xs={12} md={4}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <People sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Top clients
                </Typography>
              </Box>
              
              {topClients.length > 0 ? (
                <List>
                  {topClients.map((client, index) => (
                    <React.Fragment key={client.clientId}>
                      <ListItem sx={{ px: 0 }}>
                        <ListItemAvatar>
                          <Avatar sx={{ 
                            bgcolor: 'primary.main',
                            width: 32,
                            height: 32,
                            fontSize: '0.875rem'
                          }}>
                            {index + 1}
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={
                            <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                              {client.clientName}
                            </Typography>
                          }
                          secondary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="body2" color="text.secondary">
                                {client.count} transaction{client.count > 1 ? 's' : ''}
                              </Typography>
                              <Typography variant="subtitle2" sx={{ fontWeight: 600, color: 'primary.main' }}>
                                {formatCurrency(client.totalAmount)}
                              </Typography>
                            </Box>
                          }
                        />
                      </ListItem>
                      {index < topClients.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              ) : (
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body1" color="text.secondary">
                    Aucun client trouvé
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Graphiques (placeholder pour l'instant) */}
      <Grid container spacing={3} sx={{ mt: 2 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
                Évolution des revenus
              </Typography>
              <Box sx={{ 
                height: 200, 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                backgroundColor: 'rgba(102, 126, 234, 0.05)',
                borderRadius: 2
              }}>
                <Typography variant="body1" color="text.secondary">
                  Graphique des revenus (à implémenter)
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
                Répartition des dépenses
              </Typography>
              <Box sx={{ 
                height: 200, 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                backgroundColor: 'rgba(240, 147, 251, 0.05)',
                borderRadius: 2
              }}>
                <Typography variant="body1" color="text.secondary">
                  Graphique des dépenses (à implémenter)
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default AccountingOverview;

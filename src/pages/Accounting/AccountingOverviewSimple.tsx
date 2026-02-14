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
  alpha,
} from '@mui/material';
import {
  AttachMoney,
  TrendingUp,
  TrendingDown,
  Refresh,
  Download,
  Percent as PercentIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

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

function KpiCard({ icon, iconColor, label, value, subtitle, detail }: {
  icon: React.ReactNode;
  iconColor: string;
  label: string;
  value: React.ReactNode;
  subtitle?: string;
  detail?: string;
}) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '20px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
          <Box sx={{
            width: 48, height: 48, borderRadius: '14px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0,
            boxShadow: `0 4px 14px ${alpha(iconColor, 0.35)}`,
          }}>
            {icon}
          </Box>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="caption" sx={{
              color: 'text.secondary', fontWeight: 500, letterSpacing: '0.03em',
              textTransform: 'uppercase', fontSize: '0.7rem',
            }}>
              {label}
            </Typography>
            <Typography variant="h5" sx={{ fontWeight: 700, lineHeight: 1.2, mt: 0.25 }}>
              {value}
            </Typography>
            {subtitle && (
              <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.72rem' }}>
                {subtitle}
              </Typography>
            )}
            {detail && (
              <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.7rem', display: 'block', mt: 0.25 }}>
                {detail}
              </Typography>
            )}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

const AccountingOverviewSimple: React.FC = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [kpis, setKpis] = useState<any>(null);

  const store = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => {
    loadAllData();
  }, []);

  const loadAllData = async () => {
    try {
      setIsLoading(true);
      setError(null);
      await Promise.all([
        store.loadSales(),
        store.loadRepairs(),
        store.loadExpenses(),
        store.loadClients(),
      ]);
      await new Promise(resolve => setTimeout(resolve, 1000));
      const { sales, repairs, expenses } = useAppStore.getState();
      const calculatedKpis = calculateKPIs(sales, repairs, expenses);
      setKpis(calculatedKpis);
      setLastUpdated(new Date());
    } catch (err) {
      setError('Erreur lors du chargement des données');
    } finally {
      setIsLoading(false);
    }
  };

  const calculateKPIs = (salesData: any[], repairsData: any[], expensesData: any[]) => {
    let totalSales = 0;
    let totalRepairs = 0;
    salesData.forEach(sale => { totalSales += sale.total || 0; });
    repairsData.forEach(repair => { totalRepairs += repair.totalPrice || 0; });
    const totalRevenue = totalSales + totalRepairs;
    let totalExpenses = 0;
    expensesData.forEach(expense => { totalExpenses += expense.amount || 0; });
    const netProfit = totalRevenue - totalExpenses;

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const revenueLast30Days = [
      ...salesData.filter(sale => new Date(sale.createdAt) >= thirtyDaysAgo),
      ...repairsData.filter(repair => new Date(repair.createdAt) >= thirtyDaysAgo),
    ].reduce((sum, item) => sum + (item.total || item.totalPrice || 0), 0);
    const expensesLast30Days = expensesData
      .filter(expense => new Date(expense.expenseDate) >= thirtyDaysAgo)
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);

    return {
      totalRevenue,
      totalExpenses,
      netProfit,
      revenueLast30Days,
      expensesLast30Days,
      profitLast30Days: revenueLast30Days - expensesLast30Days,
      totalSales: salesData.length,
      totalRepairs: repairsData.length,
      totalExpensesCount: expensesData.length,
      paidRepairs: repairsData.filter(r => r.isPaid).length,
      completedSales: salesData.length,
    };
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 200 }}>
        <CircularProgress size={32} sx={{ color: '#6366f1' }} />
        <Typography variant="body2" sx={{ ml: 2, color: 'text.secondary' }}>
          Chargement des données...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return <Alert severity="error" sx={{ borderRadius: '12px' }}>{error}</Alert>;
  }

  const hasData = kpis && (kpis.completedSales > 0 || kpis.totalRepairs > 0 || kpis.totalExpenses > 0);

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            Tableau de bord financier
          </Typography>
          <Typography variant="caption" sx={{ color: 'text.disabled' }}>
            Dernière mise à jour : {lastUpdated.toLocaleString('fr-FR')}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Actualiser">
            <IconButton onClick={loadAllData} disabled={isLoading} sx={{ bgcolor: 'grey.100', borderRadius: '12px' }}>
              <Refresh fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Exporter">
            <IconButton sx={{ bgcolor: 'grey.100', borderRadius: '12px' }}>
              <Download fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {!hasData && (
        <Alert severity="info" sx={{ mb: 3, borderRadius: '12px' }}>
          Aucune donnée financière disponible. Commencez par ajouter des ventes, réparations ou dépenses.
        </Alert>
      )}

      {/* KPI Cards */}
      <Grid container spacing={2.5}>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<AttachMoney sx={{ fontSize: 22 }} />}
            iconColor="#22c55e"
            label="Revenus totaux"
            value={kpis ? formatFromEUR(kpis.totalRevenue, currency) : formatFromEUR(0, currency)}
            subtitle={kpis ? `${formatFromEUR(kpis.revenueLast30Days, currency)} (30j)` : undefined}
            detail={kpis ? `${kpis.completedSales || 0} ventes • ${kpis.paidRepairs || 0} répar.` : undefined}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<TrendingDown sx={{ fontSize: 22 }} />}
            iconColor="#ef4444"
            label="Dépenses totales"
            value={kpis ? formatFromEUR(kpis.totalExpenses, currency) : formatFromEUR(0, currency)}
            subtitle={kpis ? `${formatFromEUR(kpis.expensesLast30Days, currency)} (30j)` : undefined}
            detail={kpis ? `${kpis.totalExpensesCount || 0} dépenses` : undefined}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<TrendingUp sx={{ fontSize: 22 }} />}
            iconColor="#6366f1"
            label="Bénéfice net"
            value={kpis ? formatFromEUR(kpis.netProfit, currency) : formatFromEUR(0, currency)}
            subtitle={kpis ? `${formatFromEUR(kpis.profitLast30Days, currency)} (30j)` : undefined}
            detail={kpis ? `Marge : ${kpis.totalRevenue > 0 ? ((kpis.netProfit / kpis.totalRevenue) * 100).toFixed(1) : '0'}%` : undefined}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<PercentIcon sx={{ fontSize: 22 }} />}
            iconColor="#8b5cf6"
            label="Marge bénéficiaire"
            value={kpis && kpis.totalRevenue > 0 ? `${((kpis.netProfit / kpis.totalRevenue) * 100).toFixed(1)}%` : '0%'}
            subtitle="Marge sur les revenus"
            detail={kpis ? `${(kpis.totalSales || 0) + (kpis.totalRepairs || 0)} transactions` : undefined}
          />
        </Grid>
      </Grid>
    </Box>
  );
};

export default AccountingOverviewSimple;

import React, { useState, useMemo } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Chip,
  Avatar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  LinearProgress,
  Tooltip,
  IconButton,
  alpha,
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Speed as SpeedIcon,
  AttachMoney as MoneyIcon,
  Build as BuildIcon,
  CheckCircle as CheckCircleIcon,
  Download as DownloadIcon,
  Refresh as RefreshIcon,
  ShoppingCart as ShoppingCartIcon,
  Analytics as AnalyticsIcon,
  Timer as TimerIcon,
  Warning as WarningIcon,
  Groups as GroupsIcon,
  DevicesOther as DevicesIcon,
  EmojiEvents as TrophyIcon,
} from '@mui/icons-material';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Area,
  AreaChart,
  ComposedChart,
  Line,
} from 'recharts';
import { useAppStore } from '../../store';
import { format, subDays, subMonths, eachDayOfInterval } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

// --- Design tokens ---
const CHART_COLORS = ['#6366f1', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#14b8a6'];

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

const PERIOD_OPTIONS = [
  { value: 'week', label: '7 jours' },
  { value: 'month', label: '30 jours' },
  { value: 'quarter', label: '90 jours' },
  { value: 'year', label: '12 mois' },
];

const TAB_OPTIONS = [
  { label: 'Vue d\'ensemble', icon: <AnalyticsIcon sx={{ fontSize: 18 }} /> },
  { label: 'Appareils', icon: <DevicesIcon sx={{ fontSize: 18 }} /> },
  { label: 'Ventes', icon: <ShoppingCartIcon sx={{ fontSize: 18 }} /> },
  { label: 'Clients', icon: <GroupsIcon sx={{ fontSize: 18 }} /> },
  { label: 'Techniciens', icon: <BuildIcon sx={{ fontSize: 18 }} /> },
];

// --- Reusable sub-components ---

function KpiCard({ icon, iconColor, label, value, subtitle }: {
  icon: React.ReactNode;
  iconColor: string;
  label: string;
  value: React.ReactNode;
  subtitle?: string;
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
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, letterSpacing: '0.03em', textTransform: 'uppercase', fontSize: '0.7rem' }}>
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
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: 'text.primary' }}>
      {children}
    </Typography>
  );
}

function EmptyState({ message }: { message: string }) {
  return (
    <Box sx={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      height: 260, borderRadius: '12px', bgcolor: 'grey.50',
    }}>
      <AnalyticsIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
      <Typography variant="body2" color="text.disabled">{message}</Typography>
    </Box>
  );
}

function RankBadge({ rank }: { rank: number }) {
  const colors = ['#f59e0b', '#94a3b8', '#d97706'];
  const bg = rank <= 3 ? colors[rank - 1] : 'grey.200';
  const fg = rank <= 3 ? '#fff' : 'text.secondary';
  return (
    <Avatar sx={{
      width: 26, height: 26, fontSize: '0.72rem', fontWeight: 700,
      bgcolor: bg, color: fg, mr: 1.5,
    }}>
      {rank}
    </Avatar>
  );
}

// --- Custom Recharts tooltip ---
function ChartTooltip({ active, payload, label, currency }: any) {
  if (!active || !payload?.length) return null;
  return (
    <Box sx={{
      bgcolor: 'rgba(17,24,39,0.92)', color: '#fff', borderRadius: '10px',
      px: 2, py: 1.5, boxShadow: '0 8px 24px rgba(0,0,0,0.25)', minWidth: 140,
    }}>
      <Typography variant="caption" sx={{ color: 'grey.400', display: 'block', mb: 0.5 }}>{label}</Typography>
      {payload.map((entry: any, i: number) => (
        <Box key={i} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: entry.color, flexShrink: 0 }} />
          <Typography variant="caption" sx={{ fontWeight: 600 }}>
            {entry.name}: {typeof entry.value === 'number' && entry.name?.toLowerCase().includes('revenu')
              ? formatFromEUR(entry.value, currency)
              : entry.value}
          </Typography>
        </Box>
      ))}
    </Box>
  );
}

// ========== MAIN COMPONENT ==========

const Statistics: React.FC = () => {
  const {
    repairs, sales, devices, clients, repairStatuses, users,
    getClientById, getDeviceById,
    loadRepairs, loadSales, loadClients, loadDevices,
  } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  const [period, setPeriod] = useState('month');
  const [deviceType] = useState('all');
  const [activeTab, setActiveTab] = useState(0);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await Promise.all([loadRepairs(), loadSales(), loadClients(), loadDevices()]);
    } catch (e) { /* silently fail */ }
    finally { setIsRefreshing(false); }
  };

  // --- Data computations (unchanged logic, cleaned console logs) ---

  const getPeriodData = useMemo(() => {
    const now = new Date();
    let startDate: Date;
    switch (period) {
      case 'week': startDate = subDays(now, 7); break;
      case 'quarter': startDate = subMonths(now, 3); break;
      case 'year': startDate = subMonths(now, 12); break;
      default: startDate = subMonths(now, 1);
    }
    return { startDate, endDate: now };
  }, [period]);

  const filterRepairsByPeriod = (reps: typeof repairs) => {
    const { startDate, endDate } = getPeriodData;
    return reps.filter(repair => {
      const d = new Date(repair.createdAt);
      const inPeriod = d >= startDate && d <= endDate;
      if (deviceType !== 'all') {
        const rd = devices.find(dev => dev.id === repair.deviceId);
        return inPeriod && rd && rd.type === deviceType;
      }
      return inPeriod;
    });
  };

  const generalStats = useMemo(() => {
    const periodRepairs = filterRepairsByPeriod(repairs);
    const { startDate, endDate } = getPeriodData;
    const periodSales = sales.filter(s => { const d = new Date(s.createdAt); return d >= startDate && d <= endDate; });
    const salesRevenue = periodSales.reduce((s, sale) => s + sale.total, 0);
    const repairsRevenue = periodRepairs.filter(r => r.isPaid).reduce((s, r) => s + r.totalPrice, 0);
    const avgRepairTime = periodRepairs.length > 0
      ? periodRepairs.reduce((s, r) => s + (new Date(r.updatedAt).getTime() - new Date(r.createdAt).getTime()) / 864e5, 0) / periodRepairs.length
      : 0;
    return {
      totalRepairs: periodRepairs.length,
      totalSales: periodSales.length,
      totalRevenue: salesRevenue + repairsRevenue,
      avgRepairTime: Math.round(avgRepairTime * 10) / 10,
      totalClients: clients.length,
      totalDevices: devices.length,
      successRate: periodRepairs.length > 0
        ? Math.round((periodRepairs.filter(r => r.status === 'completed' || r.status === 'returned').length / periodRepairs.length) * 100)
        : 0,
    };
  }, [repairs, sales, clients, devices, getPeriodData, deviceType]);

  const repairsByStatus = useMemo(() => {
    const periodRepairs = filterRepairsByPeriod(repairs);
    return repairStatuses.map(status => ({
      name: status.name,
      count: periodRepairs.filter(r => r.status === status.id).length,
      color: status.color,
      percentage: periodRepairs.length > 0
        ? Math.round((periodRepairs.filter(r => r.status === status.id).length / periodRepairs.length) * 100)
        : 0,
    })).filter(i => i.count > 0);
  }, [repairs, repairStatuses, getPeriodData, deviceType, devices]);

  const repairsByDeviceType = useMemo(() => {
    const periodRepairs = filterRepairsByPeriod(repairs);
    const map = new Map<string, number>();
    periodRepairs.forEach(r => {
      const d = devices.find(dev => dev.id === r.deviceId);
      if (d) map.set(d.type, (map.get(d.type) || 0) + 1);
    });
    return Array.from(map.entries()).map(([type, count], i) => ({
      name: type.charAt(0).toUpperCase() + type.slice(1),
      count,
      color: CHART_COLORS[i % CHART_COLORS.length],
      percentage: periodRepairs.length > 0 ? Math.round((count / periodRepairs.length) * 100) : 0,
    }));
  }, [repairs, devices, getPeriodData, deviceType]);

  const revenueEvolution = useMemo(() => {
    const { startDate, endDate } = getPeriodData;
    const days = eachDayOfInterval({ start: startDate, end: endDate });
    return days.map(day => {
      const daySales = sales.filter(s => new Date(s.createdAt).toDateString() === day.toDateString());
      const dayRepairs = repairs.filter(r => {
        const same = new Date(r.createdAt).toDateString() === day.toDateString();
        if (deviceType !== 'all') { const rd = devices.find(d => d.id === r.deviceId); return same && rd && rd.type === deviceType; }
        return same;
      });
      return {
        date: format(day, 'dd MMM', { locale: fr }),
        revenue: daySales.reduce((s, sale) => s + sale.total, 0),
        repairs: dayRepairs.length,
      };
    });
  }, [sales, repairs, getPeriodData, deviceType, devices]);

  const topClients = useMemo(() => {
    const map = new Map<string, { client: any; repairs: number; revenue: number }>();
    repairs.forEach(r => {
      if (deviceType !== 'all') { const rd = devices.find(d => d.id === r.deviceId); if (!rd || rd.type !== deviceType) return; }
      const c = getClientById(r.clientId);
      if (c) {
        const ex = map.get(c.id);
        if (ex) { ex.repairs += 1; ex.revenue += r.totalPrice; }
        else map.set(c.id, { client: c, repairs: 1, revenue: r.totalPrice });
      }
    });
    return Array.from(map.values()).sort((a, b) => b.repairs - a.repairs).slice(0, 10);
  }, [repairs, getClientById, deviceType, devices, clients]);

  const topDevices = useMemo(() => {
    const map = new Map<string, { device: any; repairs: number; revenue: number }>();
    repairs.forEach(r => {
      const d = r.deviceId ? getDeviceById(r.deviceId) : null;
      if (d) {
        if (deviceType !== 'all' && d.type !== deviceType) return;
        const ex = map.get(d.id);
        if (ex) { ex.repairs += 1; ex.revenue += r.totalPrice; }
        else map.set(d.id, { device: d, repairs: 1, revenue: r.totalPrice });
      }
    });
    return Array.from(map.values()).sort((a, b) => b.repairs - a.repairs).slice(0, 10);
  }, [repairs, getDeviceById, deviceType]);

  const technicianPerformance = useMemo(() => {
    const map = new Map<string, { technician: any; repairs: number; completed: number; revenue: number; avgTime: number }>();
    repairs.forEach(r => {
      if (deviceType !== 'all') { const rd = devices.find(d => d.id === r.deviceId); if (!rd || rd.type !== deviceType) return; }
      if (r.assignedTechnicianId) {
        const t = users.find(u => u.id === r.assignedTechnicianId);
        if (t) {
          const dur = (new Date(r.updatedAt).getTime() - new Date(r.createdAt).getTime()) / 864e5;
          const ex = map.get(t.id);
          if (ex) {
            ex.repairs += 1; ex.revenue += r.totalPrice; ex.avgTime = (ex.avgTime + dur) / 2;
            if (r.status === 'completed' || r.status === 'returned') ex.completed += 1;
          } else {
            map.set(t.id, { technician: t, repairs: 1, completed: (r.status === 'completed' || r.status === 'returned') ? 1 : 0, revenue: r.totalPrice, avgTime: dur });
          }
        }
      }
    });
    return Array.from(map.values()).sort((a, b) => b.repairs - a.repairs);
  }, [repairs, users, deviceType, devices]);

  const performanceMetrics = useMemo(() => {
    const periodRepairs = filterRepairsByPeriod(repairs);
    const urgentRepairs = periodRepairs.filter(r => r.isUrgent).length;
    const overdueRepairs = periodRepairs.filter(r => {
      const due = new Date(r.dueDate);
      return due < new Date() && r.status !== 'completed' && r.status !== 'returned';
    }).length;
    return {
      urgentRepairs,
      overdueRepairs,
      urgentPercentage: periodRepairs.length > 0 ? Math.round((urgentRepairs / periodRepairs.length) * 100) : 0,
      overduePercentage: periodRepairs.length > 0 ? Math.round((overdueRepairs / periodRepairs.length) * 100) : 0,
    };
  }, [repairs, getPeriodData, deviceType, devices]);

  // ========== RENDER ==========

  return (
    <Box sx={{ maxWidth: 1400, mx: 'auto' }}>
      {/* ---- Header ---- */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, letterSpacing: '-0.02em' }}>
            Statistiques
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Vue d'ensemble de votre activité
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Tooltip title="Actualiser">
            <IconButton
              onClick={handleRefresh}
              disabled={isRefreshing}
              sx={{
                bgcolor: 'grey.100', borderRadius: '12px',
                '@keyframes spin': { to: { transform: 'rotate(360deg)' } },
                animation: isRefreshing ? 'spin 1s linear infinite' : 'none',
              }}
            >
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Exporter">
            <IconButton sx={{ bgcolor: 'grey.100', borderRadius: '12px' }}>
              <DownloadIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* ---- Period selector (pill chips) ---- */}
      <Box sx={{ display: 'flex', gap: 1, mb: 4, flexWrap: 'wrap' }}>
        {PERIOD_OPTIONS.map(opt => (
          <Chip
            key={opt.value}
            label={opt.label}
            onClick={() => setPeriod(opt.value)}
            sx={{
              fontWeight: 600, fontSize: '0.82rem', borderRadius: '10px', px: 0.5,
              height: 36,
              ...(period === opt.value
                ? {
                    bgcolor: '#111827', color: '#fff',
                    '&:hover': { bgcolor: '#1f2937' },
                    boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
                  }
                : {
                    bgcolor: 'grey.100', color: 'text.primary',
                    '&:hover': { bgcolor: 'grey.200' },
                  }),
            }}
          />
        ))}
      </Box>

      {/* ---- KPI Cards ---- */}
      <Grid container spacing={2.5} sx={{ mb: 4 }}>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<BuildIcon sx={{ fontSize: 22 }} />}
            iconColor="#6366f1"
            label="Réparations"
            value={generalStats.totalRepairs}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<MoneyIcon sx={{ fontSize: 22 }} />}
            iconColor="#22c55e"
            label="Chiffre d'affaires"
            value={formatFromEUR(generalStats.totalRevenue, currency)}
            subtitle="Ventes + réparations"
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<TimerIcon sx={{ fontSize: 22 }} />}
            iconColor="#f59e0b"
            label="Délai moyen"
            value={`${generalStats.avgRepairTime}j`}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiCard
            icon={<CheckCircleIcon sx={{ fontSize: 22 }} />}
            iconColor="#06b6d4"
            label="Taux de réussite"
            value={`${generalStats.successRate}%`}
          />
        </Grid>
      </Grid>

      {/* ---- Alert metrics (urgent / overdue) ---- */}
      {(performanceMetrics.urgentRepairs > 0 || performanceMetrics.overdueRepairs > 0) && (
        <Grid container spacing={2.5} sx={{ mb: 4 }}>
          {performanceMetrics.urgentRepairs > 0 && (
            <Grid item xs={12} md={6}>
              <Card sx={{ ...CARD_BASE, borderLeft: '4px solid #f59e0b' }}>
                <CardContent sx={{ p: '16px 20px !important', display: 'flex', alignItems: 'center', gap: 2 }}>
                  <WarningIcon sx={{ color: '#f59e0b' }} />
                  <Box sx={{ flex: 1 }}>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {performanceMetrics.urgentRepairs} réparation{performanceMetrics.urgentRepairs > 1 ? 's' : ''} urgente{performanceMetrics.urgentRepairs > 1 ? 's' : ''}
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={performanceMetrics.urgentPercentage}
                      sx={{ mt: 1, height: 6, borderRadius: 3, bgcolor: alpha('#f59e0b', 0.12), '& .MuiLinearProgress-bar': { bgcolor: '#f59e0b', borderRadius: 3 } }}
                    />
                  </Box>
                  <Typography variant="h6" sx={{ fontWeight: 700, color: '#f59e0b' }}>
                    {performanceMetrics.urgentPercentage}%
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          )}
          {performanceMetrics.overdueRepairs > 0 && (
            <Grid item xs={12} md={6}>
              <Card sx={{ ...CARD_BASE, borderLeft: '4px solid #ef4444' }}>
                <CardContent sx={{ p: '16px 20px !important', display: 'flex', alignItems: 'center', gap: 2 }}>
                  <TrendingDownIcon sx={{ color: '#ef4444' }} />
                  <Box sx={{ flex: 1 }}>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {performanceMetrics.overdueRepairs} réparation{performanceMetrics.overdueRepairs > 1 ? 's' : ''} en retard
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={performanceMetrics.overduePercentage}
                      sx={{ mt: 1, height: 6, borderRadius: 3, bgcolor: alpha('#ef4444', 0.12), '& .MuiLinearProgress-bar': { bgcolor: '#ef4444', borderRadius: 3 } }}
                    />
                  </Box>
                  <Typography variant="h6" sx={{ fontWeight: 700, color: '#ef4444' }}>
                    {performanceMetrics.overduePercentage}%
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          )}
        </Grid>
      )}

      {/* ---- Tab navigation ---- */}
      <Box sx={{ display: 'flex', gap: 1, mb: 3, flexWrap: 'wrap' }}>
        {TAB_OPTIONS.map((tab, i) => (
          <Chip
            key={i}
            icon={tab.icon}
            label={tab.label}
            onClick={() => setActiveTab(i)}
            sx={{
              fontWeight: 600, fontSize: '0.8rem', borderRadius: '10px', px: 0.5,
              height: 36,
              '& .MuiChip-icon': { ml: '8px' },
              ...(activeTab === i
                ? {
                    bgcolor: '#111827', color: '#fff',
                    '&:hover': { bgcolor: '#1f2937' },
                    boxShadow: '0 2px 8px rgba(17,24,39,0.18)',
                    '& .MuiChip-icon': { color: '#fff' },
                  }
                : {
                    bgcolor: 'transparent', color: 'text.secondary',
                    border: '1px solid', borderColor: 'divider',
                    '&:hover': { bgcolor: 'grey.50' },
                    '& .MuiChip-icon': { color: 'text.secondary' },
                  }),
            }}
          />
        ))}
      </Box>

      {/* ========== TAB PANELS ========== */}

      {/* ---- Tab 0: Vue d'ensemble ---- */}
      {activeTab === 0 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={5}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Réparations par statut</SectionTitle>
                {repairsByStatus.length > 0 ? (
                  <Box>
                    <ResponsiveContainer width="100%" height={240}>
                      <PieChart>
                        <Pie
                          data={repairsByStatus}
                          cx="50%"
                          cy="50%"
                          innerRadius={55}
                          outerRadius={90}
                          paddingAngle={3}
                          dataKey="count"
                          stroke="none"
                        >
                          {repairsByStatus.map((entry, index) => (
                            <Cell key={index} fill={entry.color} />
                          ))}
                        </Pie>
                        <RechartsTooltip content={<ChartTooltip currency={currency} />} />
                      </PieChart>
                    </ResponsiveContainer>
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1.5, mt: 2, justifyContent: 'center' }}>
                      {repairsByStatus.map((entry, i) => (
                        <Box key={i} sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                          <Box sx={{ width: 10, height: 10, borderRadius: '3px', bgcolor: entry.color }} />
                          <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500 }}>
                            {entry.name} ({entry.count})
                          </Typography>
                        </Box>
                      ))}
                    </Box>
                  </Box>
                ) : (
                  <EmptyState message="Aucune réparation enregistrée" />
                )}
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={7}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Évolution du chiffre d'affaires</SectionTitle>
                {revenueEvolution.some(d => d.revenue > 0) ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <ComposedChart data={revenueEvolution}>
                      <defs>
                        <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#6366f1" stopOpacity={0.15} />
                          <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.06)" vertical={false} />
                      <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                      <YAxis yAxisId="left" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                      <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                      <RechartsTooltip content={<ChartTooltip currency={currency} />} />
                      <Area yAxisId="left" type="monotone" dataKey="revenue" fill="url(#revenueGrad)" stroke="#6366f1" strokeWidth={2.5} name={`Revenus (${currency})`} />
                      <Line yAxisId="right" type="monotone" dataKey="repairs" stroke="#22c55e" strokeWidth={2} dot={false} name="Réparations" />
                    </ComposedChart>
                  </ResponsiveContainer>
                ) : (
                  <EmptyState message="Aucune donnée disponible" />
                )}
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* ---- Tab 1: Appareils ---- */}
      {activeTab === 1 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Répartition par type d'appareil</SectionTitle>
                {repairsByDeviceType.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={repairsByDeviceType} barSize={36}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.06)" vertical={false} />
                      <XAxis dataKey="name" tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                      <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                      <RechartsTooltip content={<ChartTooltip currency={currency} />} />
                      <Bar dataKey="count" name="Réparations" radius={[6, 6, 0, 0]}>
                        {repairsByDeviceType.map((entry, i) => (
                          <Cell key={i} fill={entry.color} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <EmptyState message="Aucun appareil enregistré" />
                )}
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Top appareils réparés</SectionTitle>
                {topDevices.length > 0 ? (
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow sx={{ '& th': { borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600, fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase', letterSpacing: '0.05em' } }}>
                          <TableCell>Appareil</TableCell>
                          <TableCell align="right">Nb</TableCell>
                          <TableCell align="right">CA</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {topDevices.map((item, index) => (
                          <TableRow key={item.device.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                            <TableCell>
                              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                <RankBadge rank={index + 1} />
                                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                  {item.device.brand} {item.device.model}
                                </Typography>
                              </Box>
                            </TableCell>
                            <TableCell align="right">
                              <Typography variant="body2" sx={{ fontWeight: 600 }}>{item.repairs}</Typography>
                            </TableCell>
                            <TableCell align="right">
                              <Typography variant="body2" sx={{ fontWeight: 600, color: '#22c55e' }}>
                                {formatFromEUR(item.revenue, currency)}
                              </Typography>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                ) : (
                  <EmptyState message="Aucun appareil" />
                )}
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* ---- Tab 2: Ventes ---- */}
      {activeTab === 2 && (
        <Card sx={CARD_BASE}>
          <CardContent sx={{ p: '24px !important' }}>
            <SectionTitle>Évolution des ventes</SectionTitle>
            {revenueEvolution.some(d => d.revenue > 0) ? (
              <ResponsiveContainer width="100%" height={380}>
                <AreaChart data={revenueEvolution}>
                  <defs>
                    <linearGradient id="salesGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.06)" vertical={false} />
                  <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                  <RechartsTooltip content={<ChartTooltip currency={currency} />} />
                  <Area
                    type="monotone"
                    dataKey="revenue"
                    stroke="#8b5cf6"
                    strokeWidth={2.5}
                    fill="url(#salesGrad)"
                    name={`Revenus (${currency})`}
                  />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <EmptyState message="Aucune vente enregistrée" />
            )}
          </CardContent>
        </Card>
      )}

      {/* ---- Tab 3: Clients ---- */}
      {activeTab === 3 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={7}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Top 10 clients</SectionTitle>
                {topClients.length > 0 ? (
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow sx={{ '& th': { borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600, fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase', letterSpacing: '0.05em' } }}>
                          <TableCell>Client</TableCell>
                          <TableCell align="right">Réparations</TableCell>
                          <TableCell align="right">CA</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {topClients.map((item, index) => (
                          <TableRow key={item.client.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                            <TableCell>
                              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                <RankBadge rank={index + 1} />
                                <Box>
                                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                    {item.client.firstName} {item.client.lastName}
                                  </Typography>
                                </Box>
                              </Box>
                            </TableCell>
                            <TableCell align="right">
                              <Chip label={item.repairs} size="small" sx={{ fontWeight: 700, borderRadius: '8px', minWidth: 36, bgcolor: alpha('#6366f1', 0.1), color: '#6366f1' }} />
                            </TableCell>
                            <TableCell align="right">
                              <Typography variant="body2" sx={{ fontWeight: 600, color: '#22c55e' }}>
                                {formatFromEUR(item.revenue, currency)}
                              </Typography>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                ) : (
                  <EmptyState message="Aucun client" />
                )}
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={5}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Résumé clients</SectionTitle>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
                  {[
                    { label: 'Total clients', value: generalStats.totalClients, color: '#6366f1' },
                    { label: 'Clients actifs', value: topClients.length, color: '#22c55e' },
                    { label: 'Total appareils', value: generalStats.totalDevices, color: '#06b6d4' },
                  ].map((item, i) => (
                    <Box key={i} sx={{
                      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      p: 2, borderRadius: '12px', bgcolor: alpha(item.color, 0.05),
                      border: `1px solid ${alpha(item.color, 0.1)}`,
                    }}>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>{item.label}</Typography>
                      <Typography variant="h6" sx={{ fontWeight: 700, color: item.color }}>{item.value}</Typography>
                    </Box>
                  ))}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* ---- Tab 4: Techniciens ---- */}
      {activeTab === 4 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={7}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Performance des techniciens</SectionTitle>
                {technicianPerformance.length > 0 ? (
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow sx={{ '& th': { borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600, fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase', letterSpacing: '0.05em' } }}>
                          <TableCell>Technicien</TableCell>
                          <TableCell align="right">Répar.</TableCell>
                          <TableCell align="right">Succès</TableCell>
                          <TableCell align="right">Délai</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {technicianPerformance.map((tech) => {
                          const rate = Math.round((tech.completed / tech.repairs) * 100);
                          return (
                            <TableRow key={tech.technician.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                              <TableCell>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                                  <Avatar sx={{
                                    width: 32, height: 32, fontSize: '0.82rem', fontWeight: 600,
                                    bgcolor: alpha('#6366f1', 0.12), color: '#6366f1',
                                  }}>
                                    {tech.technician.firstName.charAt(0)}
                                  </Avatar>
                                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                    {tech.technician.firstName} {tech.technician.lastName}
                                  </Typography>
                                </Box>
                              </TableCell>
                              <TableCell align="right">
                                <Typography variant="body2" sx={{ fontWeight: 600 }}>{tech.repairs}</Typography>
                              </TableCell>
                              <TableCell align="right">
                                <Chip
                                  label={`${rate}%`}
                                  size="small"
                                  sx={{
                                    fontWeight: 700, borderRadius: '8px', minWidth: 48,
                                    bgcolor: rate >= 80 ? alpha('#22c55e', 0.1) : alpha('#f59e0b', 0.1),
                                    color: rate >= 80 ? '#16a34a' : '#d97706',
                                  }}
                                />
                              </TableCell>
                              <TableCell align="right">
                                <Typography variant="body2" sx={{ fontWeight: 500, color: 'text.secondary' }}>
                                  {Math.round(tech.avgTime)}j
                                </Typography>
                              </TableCell>
                            </TableRow>
                          );
                        })}
                      </TableBody>
                    </Table>
                  </TableContainer>
                ) : (
                  <EmptyState message="Aucun technicien" />
                )}
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={5}>
            <Card sx={CARD_BASE}>
              <CardContent sx={{ p: '24px !important' }}>
                <SectionTitle>Métriques globales</SectionTitle>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                  {[
                    { label: 'Délai moyen', value: `${generalStats.avgRepairTime} jours`, pct: Math.min(generalStats.avgRepairTime * 10, 100), color: '#6366f1' },
                    { label: 'Taux de réussite', value: `${generalStats.successRate}%`, pct: generalStats.successRate, color: '#22c55e' },
                    { label: 'Réparations urgentes', value: `${performanceMetrics.urgentPercentage}%`, pct: performanceMetrics.urgentPercentage, color: '#f59e0b' },
                  ].map((item, i) => (
                    <Box key={i}>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                        <Typography variant="body2" sx={{ color: 'text.secondary' }}>{item.label}</Typography>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: item.color }}>{item.value}</Typography>
                      </Box>
                      <LinearProgress
                        variant="determinate"
                        value={item.pct}
                        sx={{
                          height: 8, borderRadius: 4,
                          bgcolor: alpha(item.color, 0.1),
                          '& .MuiLinearProgress-bar': { bgcolor: item.color, borderRadius: 4 },
                        }}
                      />
                    </Box>
                  ))}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}
    </Box>
  );
};

export default Statistics;

import React, { useState, useEffect, useMemo } from 'react';
import {
  Box, Typography, Card, CardContent, Grid, Chip, Button, Avatar,
  LinearProgress, IconButton, Tooltip, alpha,
} from '@mui/material';
import {
  Build as BuildIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
  Schedule as ScheduleIcon,
  TrendingUp as TrendingUpIcon,
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
  Add as AddIcon,
  Refresh as RefreshIcon,
  PointOfSale as CashRegisterIcon,
  Description as QuoteIcon,
  People as PeopleIcon,
  Receipt as SalesIcon,
  ErrorOutline as OverdueIcon,
  ArrowForward as ArrowIcon,
  CalendarToday as CalendarIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useNavigate } from 'react-router-dom';
import { useAppStore } from '../../store';
import { deviceTypeColors } from '../../theme';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
import SimplifiedSalesDialog from '../../components/SimplifiedSalesDialog';

/* ─── design tokens ─── */
const CARD_BASE = {
  borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': { boxShadow: '0 8px 32px rgba(0,0,0,0.10)', transform: 'translateY(-2px)' },
} as const;
const CARD_STATIC = {
  borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
} as const;
const BTN_DARK = {
  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;

/* ─── KpiMini ─── */
function KpiMini({ icon, iconColor, label, value }: { icon: React.ReactNode; iconColor: string; label: string; value: string | number }) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{ width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0, boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}` }}>
            {icon}
          </Box>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>{value}</Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>{label}</Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── helpers ─── */
const safeDate = (date: any, fmt: string) => {
  try {
    if (!date) return '—';
    const d = new Date(date);
    return isNaN(d.getTime()) ? '—' : format(d, fmt, { locale: fr });
  } catch { return '—'; }
};

const DEVICE_ICONS: Record<string, React.ReactNode> = {
  smartphone: <PhoneIcon sx={{ fontSize: 18 }} />,
  tablet: <TabletIcon sx={{ fontSize: 18 }} />,
  laptop: <LaptopIcon sx={{ fontSize: 18 }} />,
  desktop: <ComputerIcon sx={{ fontSize: 18 }} />,
};

/* ═══════════════════════ main component ═══════════════════════ */
const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const [saleOpen, setSaleOpen] = useState(false);

  const {
    repairs, appointments, repairStatuses, sales,
    getClientById, getDeviceById,
    loadRepairs,
  } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => { loadRepairs(); }, [loadRepairs]);

  const safeRepairs = repairs || [];
  const safeAppointments = appointments || [];
  const safeSales = sales || [];

  /* ── computed stats ── */
  const stats = useMemo(() => {
    const now = new Date();
    const active = safeRepairs.filter(r => !['completed', 'returned'].includes(r.status));
    const overdue = safeRepairs.filter(r => {
      if (r.status === 'completed' || r.status === 'returned') return false;
      if (!r.dueDate) return false;
      try { const d = new Date(r.dueDate); return !isNaN(d.getTime()) && d < now; } catch { return false; }
    });
    const urgent = safeRepairs.filter(r => r.isUrgent && !['completed', 'returned'].includes(r.status));
    const completed = safeRepairs.filter(r => r.status === 'completed' || r.status === 'returned');
    const todayAppts = safeAppointments.filter(a => {
      try {
        if (!a.startDate) return false;
        const d = new Date(a.startDate);
        return !isNaN(d.getTime()) && format(d, 'yyyy-MM-dd') === format(now, 'yyyy-MM-dd');
      } catch { return false; }
    });

    // Monthly revenue from sales
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthRevenue = safeSales
      .filter(s => { try { return new Date(s.createdAt) >= monthStart; } catch { return false; } })
      .reduce((sum, s) => sum + (s.totalAmount || 0), 0);

    return {
      active: active.length, total: safeRepairs.length,
      overdue: overdue.length, overdueList: overdue,
      urgent: urgent.length, urgentList: urgent,
      completed: completed.length,
      todayAppts: todayAppts.length, todayApptsList: todayAppts,
      inProgress: safeRepairs.filter(r => r.status === 'in_progress').length,
      monthRevenue,
    };
  }, [safeRepairs, safeAppointments, safeSales]);

  /* ── recent repairs ── */
  const recentRepairs = useMemo(() =>
    safeRepairs
      .filter(r => r.createdAt && !isNaN(new Date(r.createdAt).getTime()))
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 6),
  [safeRepairs]);

  /* ── pipeline ── */
  const pipeline = useMemo(() =>
    (repairStatuses || []).sort((a, b) => a.order - b.order).map(s => ({
      ...s,
      count: safeRepairs.filter(r => r.status === s.id).length,
      overdueCount: safeRepairs.filter(r => {
        if (r.status !== s.id || r.status === 'completed' || r.status === 'returned') return false;
        if (!r.dueDate) return false;
        try { const d = new Date(r.dueDate); return !isNaN(d.getTime()) && d < new Date(); } catch { return false; }
      }).length,
    })),
  [repairStatuses, safeRepairs]);

  const completionPct = stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0;

  const QUICK_ACTIONS = [
    { label: 'Ventes', icon: <SalesIcon sx={{ fontSize: 20 }} />, color: '#3b82f6', onClick: () => navigate('/app/transaction/sales') },
    { label: 'Caisse rapide', icon: <CashRegisterIcon sx={{ fontSize: 20 }} />, color: '#22c55e', onClick: () => setSaleOpen(true) },
    { label: 'Devis', icon: <QuoteIcon sx={{ fontSize: 20 }} />, color: '#f59e0b', onClick: () => navigate('/app/transaction/quotes') },
    { label: 'Clients', icon: <PeopleIcon sx={{ fontSize: 20 }} />, color: '#8b5cf6', onClick: () => navigate('/app/transaction/clients') },
  ];

  /* ════════════════════════ render ════════════════════════ */
  return (
    <Box sx={{ pb: 4 }}>
      {/* ── header ── */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.01em' }}>
            Tableau de bord
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5, textTransform: 'capitalize' }}>
            {safeDate(new Date(), 'EEEE d MMMM yyyy')}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center' }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => navigate('/app/sav')}
            sx={{ ...BTN_DARK, px: 3, py: 1.2 }}>
            Nouvelle réparation
          </Button>
          <Tooltip title="Actualiser" arrow>
            <IconButton onClick={() => loadRepairs()}
              sx={{ bgcolor: alpha('#6366f1', 0.08), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.16) } }}>
              <RefreshIcon sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* ── KPIs ── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {[
          { icon: <BuildIcon sx={{ fontSize: 20 }} />, color: '#6366f1', label: 'Actives', value: stats.active },
          { icon: <TrendingUpIcon sx={{ fontSize: 20 }} />, color: '#3b82f6', label: 'En cours', value: stats.inProgress },
          { icon: <WarningIcon sx={{ fontSize: 20 }} />, color: '#ef4444', label: 'Urgentes', value: stats.urgent },
          { icon: <OverdueIcon sx={{ fontSize: 20 }} />, color: '#f59e0b', label: 'En retard', value: stats.overdue },
          { icon: <CheckCircleIcon sx={{ fontSize: 20 }} />, color: '#22c55e', label: 'Terminées', value: stats.completed },
        ].map(k => (
          <Grid item xs={6} sm={4} md key={k.label}>
            <KpiMini icon={k.icon} iconColor={k.color} label={k.label} value={k.value} />
          </Grid>
        ))}
      </Grid>

      {/* ── quick access ── */}
      <Box sx={{ display: 'flex', gap: 1.5, mb: 3, flexWrap: 'wrap' }}>
        {QUICK_ACTIONS.map(a => (
          <Card key={a.label} onClick={a.onClick}
            sx={{ ...CARD_BASE, cursor: 'pointer', flex: '1 1 0', minWidth: 140 }}>
            <CardContent sx={{ p: '14px 16px !important', display: 'flex', alignItems: 'center', gap: 1.5 }}>
              <Box sx={{ width: 36, height: 36, borderRadius: '10px', display: 'flex',
                alignItems: 'center', justifyContent: 'center',
                bgcolor: alpha(a.color, 0.10), color: a.color, flexShrink: 0 }}>
                {a.icon}
              </Box>
              <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.85rem' }}>{a.label}</Typography>
              <ArrowIcon sx={{ fontSize: 16, color: 'text.disabled', ml: 'auto' }} />
            </CardContent>
          </Card>
        ))}
      </Box>

      {/* ── pipeline ── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '20px !important' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2.5 }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 700, fontSize: '0.95rem' }}>
              Pipeline des réparations
            </Typography>
            <Button size="small" onClick={() => navigate('/app/kanban')}
              sx={{ textTransform: 'none', fontWeight: 600, color: '#6366f1', fontSize: '0.8rem' }}>
              Voir le Kanban
            </Button>
          </Box>

          <Box sx={{ display: 'flex', gap: 1.5, overflowX: 'auto', pb: 1,
            '&::-webkit-scrollbar': { height: 4 },
            '&::-webkit-scrollbar-thumb': { background: '#cbd5e1', borderRadius: 2 },
          }}>
            {pipeline.map(s => (
              <Box key={s.id} sx={{ flex: '1 1 0', minWidth: 110 }}>
                <Box sx={{
                  p: 1.5, borderRadius: '12px',
                  border: '1px solid', borderColor: alpha(s.color, 0.2),
                  bgcolor: alpha(s.color, 0.04),
                  textAlign: 'center', position: 'relative', cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  '&:hover': { bgcolor: alpha(s.color, 0.08), transform: 'translateY(-1px)' },
                }} onClick={() => navigate('/app/kanban')}>
                  {s.overdueCount > 0 && (
                    <Box sx={{ position: 'absolute', top: -6, right: -6,
                      width: 18, height: 18, borderRadius: '50%', bgcolor: '#ef4444', color: '#fff',
                      fontSize: '0.65rem', fontWeight: 700,
                      display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {s.overdueCount}
                    </Box>
                  )}
                  <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: s.color,
                    boxShadow: `0 0 6px ${alpha(s.color, 0.5)}`, mx: 'auto', mb: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 700, fontSize: '1.1rem', color: s.color }}>
                    {s.count}
                  </Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.68rem', display: 'block' }}>
                    {s.name}
                  </Typography>
                </Box>
              </Box>
            ))}
          </Box>

          {/* progress */}
          <Box sx={{ mt: 2.5, display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box sx={{ flexGrow: 1 }}>
              <LinearProgress variant="determinate" value={completionPct}
                sx={{ height: 6, borderRadius: 3, bgcolor: alpha('#22c55e', 0.1),
                  '& .MuiLinearProgress-bar': { bgcolor: '#22c55e', borderRadius: 3 } }} />
            </Box>
            <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', whiteSpace: 'nowrap' }}>
              {completionPct}% terminées
            </Typography>
          </Box>
        </CardContent>
      </Card>

      {/* ── main: 2 columns ── */}
      <Grid container spacing={3}>
        {/* ─ left ─ */}
        <Grid item xs={12} lg={8}>
          {/* alerts */}
          {(stats.urgent > 0 || stats.overdue > 0) && (
            <Grid container spacing={2} sx={{ mb: 3 }}>
              {stats.urgent > 0 && (
                <Grid item xs={12} sm={6}>
                  <Card sx={{ ...CARD_STATIC, bgcolor: alpha('#ef4444', 0.04), borderColor: alpha('#ef4444', 0.15) }}>
                    <CardContent sx={{ p: '16px !important' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1.5 }}>
                        <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex',
                          alignItems: 'center', justifyContent: 'center',
                          bgcolor: alpha('#ef4444', 0.10), color: '#ef4444', flexShrink: 0 }}>
                          <WarningIcon sx={{ fontSize: 18 }} />
                        </Box>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: '#ef4444', fontSize: '0.85rem' }}>
                          {stats.urgent} urgente{stats.urgent > 1 ? 's' : ''}
                        </Typography>
                      </Box>
                      {stats.urgentList.slice(0, 3).map(r => {
                        const c = getClientById(r.clientId);
                        const d = r.deviceId ? getDeviceById(r.deviceId) : null;
                        return (
                          <Box key={r.id} sx={{ py: 0.75, borderBottom: '1px solid', borderColor: alpha('#ef4444', 0.08),
                            '&:last-child': { borderBottom: 0 } }}>
                            <Typography variant="caption" sx={{ fontWeight: 600, display: 'block' }}>
                              {c?.firstName} {c?.lastName}
                            </Typography>
                            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                              {d?.brand} {d?.model}
                            </Typography>
                          </Box>
                        );
                      })}
                      {stats.urgent > 3 && (
                        <Typography variant="caption" sx={{ color: '#ef4444', fontWeight: 600, mt: 0.5, display: 'block' }}>
                          +{stats.urgent - 3} autres
                        </Typography>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
              )}
              {stats.overdue > 0 && (
                <Grid item xs={12} sm={6}>
                  <Card sx={{ ...CARD_STATIC, bgcolor: alpha('#f59e0b', 0.04), borderColor: alpha('#f59e0b', 0.15) }}>
                    <CardContent sx={{ p: '16px !important' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1.5 }}>
                        <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex',
                          alignItems: 'center', justifyContent: 'center',
                          bgcolor: alpha('#f59e0b', 0.10), color: '#f59e0b', flexShrink: 0 }}>
                          <OverdueIcon sx={{ fontSize: 18 }} />
                        </Box>
                        <Typography variant="body2" sx={{ fontWeight: 700, color: '#f59e0b', fontSize: '0.85rem' }}>
                          {stats.overdue} en retard
                        </Typography>
                      </Box>
                      {stats.overdueList.slice(0, 3).map(r => {
                        const c = getClientById(r.clientId);
                        const d = r.deviceId ? getDeviceById(r.deviceId) : null;
                        const daysLate = Math.floor((Date.now() - new Date(r.dueDate).getTime()) / 86400000);
                        return (
                          <Box key={r.id} sx={{ py: 0.75, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                            borderBottom: '1px solid', borderColor: alpha('#f59e0b', 0.08),
                            '&:last-child': { borderBottom: 0 } }}>
                            <Box>
                              <Typography variant="caption" sx={{ fontWeight: 600, display: 'block' }}>
                                {c?.firstName} {c?.lastName}
                              </Typography>
                              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                                {d?.brand} {d?.model}
                              </Typography>
                            </Box>
                            <Chip label={`${daysLate}j`} size="small"
                              sx={{ height: 20, fontSize: '0.65rem', fontWeight: 700,
                                bgcolor: alpha('#f59e0b', 0.12), color: '#f59e0b' }} />
                          </Box>
                        );
                      })}
                      {stats.overdue > 3 && (
                        <Typography variant="caption" sx={{ color: '#f59e0b', fontWeight: 600, mt: 0.5, display: 'block' }}>
                          +{stats.overdue - 3} autres
                        </Typography>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
              )}
            </Grid>
          )}

          {/* recent repairs */}
          <Card sx={CARD_STATIC}>
            <CardContent sx={{ p: '20px !important' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="subtitle1" sx={{ fontWeight: 700, fontSize: '0.95rem' }}>
                  Réparations récentes
                </Typography>
                <Button size="small" onClick={() => navigate('/app/sav')}
                  sx={{ textTransform: 'none', fontWeight: 600, color: '#6366f1', fontSize: '0.8rem' }}>
                  Tout voir
                </Button>
              </Box>

              {recentRepairs.length === 0 ? (
                <Box sx={{ textAlign: 'center', py: 6, opacity: 0.4 }}>
                  <BuildIcon sx={{ fontSize: 32, color: 'text.disabled', mb: 1 }} />
                  <Typography variant="body2" sx={{ color: 'text.disabled' }}>Aucune réparation</Typography>
                </Box>
              ) : (
                recentRepairs.map((repair, i) => {
                  const client = getClientById(repair.clientId);
                  const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                  const statusInfo = (repairStatuses || []).find(s => s.id === repair.status);
                  const devType = (device?.type || 'other') as string;
                  return (
                    <Box key={repair.id}
                      sx={{ display: 'flex', alignItems: 'center', gap: 2, py: 1.5,
                        borderBottom: i < recentRepairs.length - 1 ? '1px solid' : 'none', borderColor: 'divider',
                        cursor: 'pointer', borderRadius: '8px', mx: -1, px: 1,
                        transition: 'background 0.15s',
                        '&:hover': { bgcolor: 'rgba(0,0,0,0.02)' },
                      }}
                      onClick={() => navigate('/app/sav')}>
                      <Avatar sx={{ width: 36, height: 36,
                        bgcolor: alpha((deviceTypeColors as any)[devType] || '#6366f1', 0.12),
                        color: (deviceTypeColors as any)[devType] || '#6366f1' }}>
                        {DEVICE_ICONS[devType] || <ComputerIcon sx={{ fontSize: 18 }} />}
                      </Avatar>
                      <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.85rem' }} noWrap>
                            {client?.firstName} {client?.lastName}
                          </Typography>
                          {repair.isUrgent && (
                            <Chip label="Urgent" size="small"
                              sx={{ height: 18, fontSize: '0.6rem', fontWeight: 700,
                                bgcolor: alpha('#ef4444', 0.10), color: '#ef4444' }} />
                          )}
                        </Box>
                        <Typography variant="caption" sx={{ color: 'text.secondary' }} noWrap>
                          {device?.brand} {device?.model} — {repair.description}
                        </Typography>
                      </Box>
                      <Box sx={{ textAlign: 'right', flexShrink: 0 }}>
                        {statusInfo && (
                          <Chip label={statusInfo.name} size="small"
                            sx={{ height: 20, fontSize: '0.65rem', fontWeight: 600,
                              bgcolor: alpha(statusInfo.color, 0.12), color: statusInfo.color, mb: 0.5, display: 'flex' }} />
                        )}
                        <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', fontSize: '0.68rem' }}>
                          {safeDate(repair.createdAt, 'dd/MM HH:mm')}
                        </Typography>
                      </Box>
                    </Box>
                  );
                })
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* ─ right ─ */}
        <Grid item xs={12} lg={4}>
          {/* revenue */}
          <Card sx={{ ...CARD_STATIC, mb: 3,
            background: 'linear-gradient(135deg, #111827, #1e293b)',
            color: '#fff', position: 'relative', overflow: 'hidden' }}>
            <Box sx={{ position: 'absolute', top: -20, right: -20, width: 100, height: 100,
              borderRadius: '50%', bgcolor: 'rgba(255,255,255,0.04)' }} />
            <Box sx={{ position: 'absolute', bottom: -30, left: -30, width: 80, height: 80,
              borderRadius: '50%', bgcolor: 'rgba(255,255,255,0.03)' }} />
            <CardContent sx={{ p: '20px !important', position: 'relative' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1.5 }}>
                <Box sx={{ width: 36, height: 36, borderRadius: '10px', display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                  bgcolor: 'rgba(255,255,255,0.10)' }}>
                  <TrendingUpIcon sx={{ fontSize: 18, color: '#22c55e' }} />
                </Box>
                <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.6)', fontWeight: 500, fontSize: '0.75rem' }}>
                  CA du mois
                </Typography>
              </Box>
              <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
                {formatFromEUR(stats.monthRevenue, currency)}
              </Typography>
              <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)', fontSize: '0.7rem' }}>
                {stats.completed} réparation{stats.completed > 1 ? 's' : ''} terminée{stats.completed > 1 ? 's' : ''}
              </Typography>
            </CardContent>
          </Card>

          {/* appointments */}
          <Card sx={{ ...CARD_STATIC, mb: 3 }}>
            <CardContent sx={{ p: '20px !important' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
                <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex',
                  alignItems: 'center', justifyContent: 'center',
                  background: `linear-gradient(135deg, #3b82f6, ${alpha('#3b82f6', 0.7)})`,
                  color: '#fff', boxShadow: `0 4px 14px ${alpha('#3b82f6', 0.3)}` }}>
                  <CalendarIcon sx={{ fontSize: 16 }} />
                </Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 700, fontSize: '0.95rem' }}>
                  Rendez-vous du jour
                </Typography>
                <Chip label={stats.todayAppts} size="small"
                  sx={{ height: 22, fontSize: '0.72rem', fontWeight: 700,
                    bgcolor: alpha('#3b82f6', 0.10), color: '#3b82f6', ml: 'auto' }} />
              </Box>

              {stats.todayApptsList.length === 0 ? (
                <Box sx={{ textAlign: 'center', py: 4, opacity: 0.4 }}>
                  <ScheduleIcon sx={{ fontSize: 32, color: 'text.disabled', mb: 1 }} />
                  <Typography variant="caption" sx={{ color: 'text.disabled', display: 'block' }}>
                    Aucun rendez-vous
                  </Typography>
                </Box>
              ) : (
                stats.todayApptsList.map((apt, i) => {
                  const client = apt.clientId ? getClientById(apt.clientId) : null;
                  return (
                    <Box key={apt.id} sx={{ display: 'flex', alignItems: 'center', gap: 1.5, py: 1.25,
                      borderBottom: i < stats.todayApptsList.length - 1 ? '1px solid' : 'none', borderColor: 'divider' }}>
                      <Box sx={{ width: 32, height: 32, borderRadius: '8px',
                        bgcolor: alpha('#3b82f6', 0.08),
                        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                        <ScheduleIcon sx={{ fontSize: 16, color: '#3b82f6' }} />
                      </Box>
                      <Box sx={{ minWidth: 0, flexGrow: 1 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.82rem' }} noWrap>
                          {apt.title || (client ? `${client.firstName} ${client.lastName}` : 'Rendez-vous')}
                        </Typography>
                        {client && apt.title && (
                          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                            {client.firstName} {client.lastName}
                          </Typography>
                        )}
                      </Box>
                      <Chip label={safeDate(apt.startDate, 'HH:mm')} size="small"
                        sx={{ height: 22, fontSize: '0.7rem', fontWeight: 600,
                          bgcolor: alpha('#3b82f6', 0.08), color: '#3b82f6' }} />
                    </Box>
                  );
                })
              )}
            </CardContent>
          </Card>

          {/* actions du jour */}
          <Card sx={CARD_STATIC}>
            <CardContent sx={{ p: '20px !important' }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 700, fontSize: '0.95rem', mb: 2 }}>
                Actions du jour
              </Typography>

              {[
                { key: 'new', label: 'Nouvelles prises en charge', color: '#3b82f6', items: safeRepairs.filter(r => r.status === 'new') },
                { key: 'waiting_parts', label: 'Attente de pièces', color: '#f59e0b', items: safeRepairs.filter(r => r.status === 'waiting_parts') },
                { key: 'waiting_delivery', label: 'Prêtes à restituer', color: '#8b5cf6', items: safeRepairs.filter(r => r.status === 'waiting_delivery') },
                { key: 'in_progress', label: 'En cours de réparation', color: '#22c55e', items: safeRepairs.filter(r => r.status === 'in_progress') },
              ].filter(g => g.items.length > 0).map(group => (
                <Box key={group.key} sx={{ mb: 2, '&:last-child': { mb: 0 } }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: group.color }} />
                    <Typography variant="caption" sx={{ fontWeight: 700, color: group.color, fontSize: '0.72rem',
                      textTransform: 'uppercase', letterSpacing: '0.03em' }}>
                      {group.label}
                    </Typography>
                    <Chip label={group.items.length} size="small"
                      sx={{ height: 18, fontSize: '0.62rem', fontWeight: 700,
                        bgcolor: alpha(group.color, 0.10), color: group.color, ml: 'auto' }} />
                  </Box>
                  {group.items.slice(0, 2).map(r => {
                    const c = getClientById(r.clientId);
                    return (
                      <Box key={r.id} sx={{ pl: 2, py: 0.5 }}>
                        <Typography variant="caption" sx={{ fontWeight: 500 }}>
                          {c?.firstName} {c?.lastName}
                        </Typography>
                      </Box>
                    );
                  })}
                  {group.items.length > 2 && (
                    <Typography variant="caption" sx={{ pl: 2, color: 'text.secondary', fontSize: '0.68rem' }}>
                      +{group.items.length - 2} autres
                    </Typography>
                  )}
                </Box>
              ))}

              {safeRepairs.filter(r => ['new', 'waiting_parts', 'waiting_delivery', 'in_progress'].includes(r.status)).length === 0 && (
                <Box sx={{ textAlign: 'center', py: 4, opacity: 0.4 }}>
                  <CheckCircleIcon sx={{ fontSize: 32, color: 'text.disabled', mb: 1 }} />
                  <Typography variant="caption" sx={{ color: 'text.disabled', display: 'block' }}>
                    Tout est à jour
                  </Typography>
                </Box>
              )}

              <Button fullWidth size="small" onClick={() => navigate('/app/kanban')}
                sx={{ mt: 2, textTransform: 'none', fontWeight: 600, color: '#6366f1',
                  bgcolor: alpha('#6366f1', 0.06), borderRadius: '10px', py: 1,
                  '&:hover': { bgcolor: alpha('#6366f1', 0.12) } }}>
                Voir toutes les tâches
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* ── dialog ── */}
      <SimplifiedSalesDialog open={saleOpen} onClose={() => setSaleOpen(false)} />
    </Box>
  );
};

export default Dashboard;

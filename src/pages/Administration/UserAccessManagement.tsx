import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Chip,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  IconButton,
  Tooltip,
  CircularProgress,
  Divider,
  Grid,
  Avatar,
  LinearProgress,
  InputAdornment,
  alpha,
  Snackbar,
  Fade,
  Skeleton
} from '@mui/material';
import {
  CheckCircle as CheckIcon,
  Refresh as RefreshIcon,
  People as PeopleIcon,
  Lock as LockIcon,
  LockOpen as LockOpenIcon,
  Search as SearchIcon,
  Timer as TimerIcon,
  Visibility as VisibilityIcon,
  Sync as SyncIcon,
  AccessTime as AccessTimeIcon,
  CalendarToday as CalendarIcon,
  Close as CloseIcon,
  Block as BlockIcon
} from '@mui/icons-material';
import { subscriptionService } from '../../services/supabaseService';
import { useAuth } from '../../hooks/useAuth';
import { SubscriptionStatus } from '../../types';
import { supabase } from '../../lib/supabase';
import { isAdminEmail } from '../../config/adminEmails';

// --- Helpers ---
const hasActiveTrial = (sub: SubscriptionStatus): boolean => {
  return sub.subscription_type === 'trial' && !!sub.trial_ends_at && sub.is_active && new Date(sub.trial_ends_at) > new Date();
};

const getTrialProgress = (sub: SubscriptionStatus): number => {
  if (!sub.trial_ends_at || !sub.activated_at) return 0;
  const start = new Date(sub.activated_at).getTime();
  const end = new Date(sub.trial_ends_at).getTime();
  const now = Date.now();
  const total = end - start;
  const elapsed = now - start;
  return Math.min(100, Math.max(0, (elapsed / total) * 100));
};

const getTrialRemainingText = (trialEndsAt: string): { text: string; expired: boolean; urgent: boolean } => {
  const diff = new Date(trialEndsAt).getTime() - Date.now();
  if (diff <= 0) return { text: 'Expiré', expired: true, urgent: false };
  const d = Math.floor(diff / 86400000);
  const h = Math.floor((diff % 86400000) / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  const urgent = diff < 86400000;
  const text = d > 0 ? `${d}j ${h}h` : h > 0 ? `${h}h ${m}min` : `${m}min`;
  return { text, expired: false, urgent };
};

const getAvatarColor = (name: string): string => {
  const colors = [
    '#1976d2', '#388e3c', '#d32f2f', '#f57c00', '#7b1fa2',
    '#0097a7', '#5d4037', '#455a64', '#c2185b', '#303f9f'
  ];
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return colors[Math.abs(hash) % colors.length];
};

// --- Composant TrialProgressBar ---
const TrialProgressBar: React.FC<{ sub: SubscriptionStatus }> = ({ sub }) => {
  const [remaining, setRemaining] = useState(getTrialRemainingText(sub.trial_ends_at!));
  const progress = getTrialProgress(sub);

  useEffect(() => {
    const id = setInterval(() => setRemaining(getTrialRemainingText(sub.trial_ends_at!)), 60000);
    return () => clearInterval(id);
  }, [sub.trial_ends_at]);

  return (
    <Box sx={{ mt: 1.5 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          <TimerIcon sx={{ fontSize: 14, color: remaining.urgent ? 'error.main' : 'warning.main' }} />
          <Typography variant="caption" sx={{ fontWeight: 600, color: remaining.urgent ? 'error.main' : 'warning.main' }}>
            {remaining.text} restants
          </Typography>
        </Box>
        <Typography variant="caption" color="text.secondary">
          {Math.round(progress)}%
        </Typography>
      </Box>
      <LinearProgress
        variant="determinate"
        value={progress}
        sx={{
          height: 6,
          borderRadius: 3,
          bgcolor: alpha(remaining.urgent ? '#d32f2f' : '#ed6c02', 0.15),
          '& .MuiLinearProgress-bar': {
            borderRadius: 3,
            bgcolor: remaining.urgent ? 'error.main' : 'warning.main',
          }
        }}
      />
      {sub.trial_ends_at && (
        <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
          Expire le {new Date(sub.trial_ends_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })}
        </Typography>
      )}
    </Box>
  );
};

// --- Composant StatCard ---
const StatCard: React.FC<{
  icon: React.ReactNode;
  label: string;
  value: number;
  gradient: string;
  iconColor: string;
}> = ({ icon, label, value, gradient, iconColor }) => (
  <Card
    sx={{
      position: 'relative',
      overflow: 'hidden',
      borderRadius: 3,
      boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
      transition: 'transform 0.2s, box-shadow 0.2s',
      '&:hover': {
        transform: 'translateY(-2px)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.12)',
      }
    }}
  >
    <Box
      sx={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: 4,
        background: gradient,
      }}
    />
    <CardContent sx={{ p: 2.5 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Box
          sx={{
            width: 48,
            height: 48,
            borderRadius: 2,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: alpha(iconColor, 0.1),
            color: iconColor,
          }}
        >
          {icon}
        </Box>
        <Box>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 0.25 }}>
            {label}
          </Typography>
          <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1.2 }}>
            {value}
          </Typography>
        </Box>
      </Box>
    </CardContent>
  </Card>
);

// --- Composant UserCard ---
const UserCard: React.FC<{
  sub: SubscriptionStatus;
  onActivate: (sub: SubscriptionStatus) => void;
  onDeactivate: (sub: SubscriptionStatus) => void;
  onTrial: (sub: SubscriptionStatus, days: 7 | 30) => void;
  onViewDetails: (sub: SubscriptionStatus) => void;
}> = ({ sub, onActivate, onDeactivate, onTrial, onViewDetails }) => {
  const fullName = `${sub.first_name} ${sub.last_name}`.trim();
  const initials = `${sub.first_name.charAt(0)}${sub.last_name.charAt(0)}`.toUpperCase();
  const avatarColor = getAvatarColor(fullName);
  const trialActive = hasActiveTrial(sub);
  const canStartTrial = !sub.is_active && !trialActive;

  const statusConfig = trialActive
    ? { label: 'Essai actif', color: '#ed6c02', bgcolor: alpha('#ed6c02', 0.1), icon: <TimerIcon sx={{ fontSize: 14 }} /> }
    : sub.is_active
    ? { label: 'Actif', color: '#2e7d32', bgcolor: alpha('#2e7d32', 0.1), icon: <LockOpenIcon sx={{ fontSize: 14 }} /> }
    : { label: 'Verrouillé', color: '#d32f2f', bgcolor: alpha('#d32f2f', 0.1), icon: <LockIcon sx={{ fontSize: 14 }} /> };

  return (
    <Card
      sx={{
        borderRadius: 3,
        boxShadow: '0 2px 12px rgba(0,0,0,0.06)',
        transition: 'all 0.2s ease',
        border: '1px solid',
        borderColor: trialActive ? alpha('#ed6c02', 0.3) : sub.is_active ? alpha('#2e7d32', 0.2) : alpha('#d32f2f', 0.2),
        '&:hover': {
          boxShadow: '0 4px 24px rgba(0,0,0,0.1)',
          transform: 'translateY(-2px)',
        },
      }}
    >
      <CardContent sx={{ p: 2.5 }}>
        {/* Header: Avatar + Nom + Status badge */}
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2, mb: 2 }}>
          <Avatar
            sx={{
              width: 48,
              height: 48,
              bgcolor: avatarColor,
              fontWeight: 700,
              fontSize: '1rem',
            }}
          >
            {initials}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography
              variant="subtitle1"
              sx={{ fontWeight: 600, lineHeight: 1.3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
            >
              {fullName}
            </Typography>
            <Typography
              variant="body2"
              color="text.secondary"
              sx={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
            >
              {sub.email}
            </Typography>
          </Box>
          <Chip
            icon={statusConfig.icon}
            label={statusConfig.label}
            size="small"
            sx={{
              bgcolor: statusConfig.bgcolor,
              color: statusConfig.color,
              fontWeight: 600,
              fontSize: '0.7rem',
              height: 26,
              flexShrink: 0,
              '& .MuiChip-icon': { color: statusConfig.color },
            }}
          />
        </Box>

        {/* Trial progress bar */}
        {trialActive && sub.trial_ends_at && <TrialProgressBar sub={sub} />}

        {/* Dernière action */}
        <Box sx={{ mt: trialActive ? 1.5 : 0, mb: 2 }}>
          {sub.activated_at ? (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <CalendarIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
              <Typography variant="caption" color="text.secondary">
                Activé le {new Date(sub.activated_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })}
              </Typography>
            </Box>
          ) : (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <AccessTimeIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
              <Typography variant="caption" color="text.secondary">
                Jamais activé
              </Typography>
            </Box>
          )}
        </Box>

        <Divider sx={{ mb: 2 }} />

        {/* Actions */}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
          {/* Boutons principaux pour les utilisateurs verrouillés */}
          {canStartTrial && (
            <Box sx={{ display: 'flex', gap: 1 }}>
              <Button
                fullWidth
                size="small"
                variant="outlined"
                startIcon={<TimerIcon />}
                onClick={() => onTrial(sub, 7)}
                sx={{
                  borderColor: alpha('#ed6c02', 0.5),
                  color: '#ed6c02',
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  borderRadius: 2,
                  textTransform: 'none',
                  '&:hover': { bgcolor: alpha('#ed6c02', 0.08), borderColor: '#ed6c02' },
                }}
              >
                Essai 7j
              </Button>
              <Button
                fullWidth
                size="small"
                variant="outlined"
                startIcon={<TimerIcon />}
                onClick={() => onTrial(sub, 30)}
                sx={{
                  borderColor: alpha('#f57c00', 0.5),
                  color: '#f57c00',
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  borderRadius: 2,
                  textTransform: 'none',
                  '&:hover': { bgcolor: alpha('#f57c00', 0.08), borderColor: '#f57c00' },
                }}
              >
                Essai 30j
              </Button>
            </Box>
          )}

          {/* Boutons d'action */}
          <Box sx={{ display: 'flex', gap: 1 }}>
            {sub.is_active ? (
              <Button
                fullWidth
                size="small"
                variant="contained"
                startIcon={<BlockIcon />}
                onClick={() => onDeactivate(sub)}
                sx={{
                  bgcolor: '#d32f2f',
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  borderRadius: 2,
                  textTransform: 'none',
                  boxShadow: 'none',
                  '&:hover': { bgcolor: '#b71c1c', boxShadow: 'none' },
                }}
              >
                Désactiver
              </Button>
            ) : (
              <Button
                fullWidth
                size="small"
                variant="contained"
                startIcon={<CheckIcon />}
                onClick={() => onActivate(sub)}
                sx={{
                  bgcolor: '#2e7d32',
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  borderRadius: 2,
                  textTransform: 'none',
                  boxShadow: 'none',
                  '&:hover': { bgcolor: '#1b5e20', boxShadow: 'none' },
                }}
              >
                Activer
              </Button>
            )}
            <Tooltip title="Voir les détails">
              <IconButton
                size="small"
                onClick={() => onViewDetails(sub)}
                sx={{
                  border: '1px solid',
                  borderColor: 'divider',
                  borderRadius: 2,
                  width: 36,
                  height: 36,
                }}
              >
                <VisibilityIcon sx={{ fontSize: 18 }} />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
};

// --- Composant principal ---
const UserAccessManagement: React.FC = () => {
  const { user: authUser, loading: authLoading } = useAuth();
  const [subscriptions, setSubscriptions] = useState<SubscriptionStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'inactive' | 'trial'>('all');
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  // Dialog states
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    subscription: SubscriptionStatus | null;
    action: 'activate' | 'deactivate' | 'trial7' | 'trial30';
    notes: string;
  }>({ open: false, subscription: null, action: 'activate', notes: '' });

  const [detailsDialog, setDetailsDialog] = useState<{
    open: boolean;
    subscription: SubscriptionStatus | null;
  }>({ open: false, subscription: null });

  const isAdmin = isAdminEmail(authUser?.email);

  const loadSubscriptions = useCallback(async () => {
    if (!isAdmin) return;
    try {
      setLoading(true);
      setError(null);

      try { await subscriptionService.deactivateExpiredTrials(); } catch (e) { console.warn('Sweep essais:', e); }
      try { await supabase.rpc('sync_missing_users_to_subscription'); } catch (e) { console.warn('Sync:', e); }

      const result = await subscriptionService.getAllSubscriptionStatuses();
      if (result.success && 'data' in result) {
        setSubscriptions(result.data || []);
        setLastRefresh(new Date());
      } else if ('error' in result) {
        setError(result.error);
      }
    } catch {
      setError('Erreur lors du chargement des utilisateurs');
    } finally {
      setLoading(false);
    }
  }, [isAdmin]);

  useEffect(() => {
    if (!isAdmin) return;
    loadSubscriptions();
    const interval = setInterval(loadSubscriptions, 30000);
    return () => clearInterval(interval);
  }, [isAdmin, loadSubscriptions]);

  // --- Handlers ---
  const openConfirmDialog = (sub: SubscriptionStatus, action: 'activate' | 'deactivate' | 'trial7' | 'trial30') => {
    setConfirmDialog({ open: true, subscription: sub, action, notes: '' });
  };

  const closeConfirmDialog = () => {
    setConfirmDialog({ open: false, subscription: null, action: 'activate', notes: '' });
  };

  const handleConfirmAction = async () => {
    if (!confirmDialog.subscription) return;
    const { subscription, action, notes } = confirmDialog;
    try {
      setActionLoading(true);
      setError(null);
      let result;

      if (action === 'activate') {
        result = await subscriptionService.activateSubscription(subscription.user_id, authUser?.id || 'admin', notes || 'Activé manuellement');
      } else if (action === 'deactivate') {
        result = await subscriptionService.deactivateSubscription(subscription.user_id, notes || 'Désactivé manuellement');
      } else if (action === 'trial7') {
        result = await subscriptionService.activateTrial(subscription.user_id, 7, authUser?.id || 'admin', notes || 'Essai 7 jours activé par admin');
      } else if (action === 'trial30') {
        result = await subscriptionService.activateTrial(subscription.user_id, 30, authUser?.id || 'admin', notes || 'Essai 30 jours activé par admin');
      }

      if (result?.success) {
        const messages: Record<string, string> = {
          activate: `Accès activé pour ${subscription.first_name} ${subscription.last_name}`,
          deactivate: `Accès désactivé pour ${subscription.first_name} ${subscription.last_name}`,
          trial7: `Essai 7 jours activé pour ${subscription.first_name} ${subscription.last_name}`,
          trial30: `Essai 30 jours activé pour ${subscription.first_name} ${subscription.last_name}`,
        };
        setSuccess(messages[action]);
        closeConfirmDialog();
        setTimeout(loadSubscriptions, 500);
      } else if (result && 'error' in result) {
        setError(result.error);
      }
    } catch {
      setError("Erreur lors de l'exécution de l'action");
    } finally {
      setActionLoading(false);
    }
  };

  const handleSync = async () => {
    try {
      setError(null);
      const { data: syncResult, error: syncError } = await supabase.rpc('sync_missing_users_to_subscription');
      if (syncError) {
        setError('Erreur de synchronisation: ' + syncError.message);
      } else if (syncResult?.length > 0) {
        setSuccess(`${syncResult[0].synchronized_count} utilisateurs synchronisés`);
        loadSubscriptions();
      } else {
        setSuccess('Tous les utilisateurs sont déjà synchronisés');
      }
    } catch {
      setError('Erreur lors de la synchronisation');
    }
  };

  // --- Filtrage ---
  const filteredSubscriptions = subscriptions.filter(sub => {
    const q = searchTerm.toLowerCase();
    const matchSearch = !q || sub.first_name.toLowerCase().includes(q) || sub.last_name.toLowerCase().includes(q) || sub.email.toLowerCase().includes(q);
    if (!matchSearch) return false;
    if (filterStatus === 'active') return sub.is_active && !hasActiveTrial(sub);
    if (filterStatus === 'inactive') return !sub.is_active;
    if (filterStatus === 'trial') return hasActiveTrial(sub);
    return true;
  });

  const stats = {
    total: subscriptions.length,
    active: subscriptions.filter(s => s.is_active).length,
    inactive: subscriptions.filter(s => !s.is_active).length,
    trial: subscriptions.filter(hasActiveTrial).length,
  };

  // --- Dialog helpers ---
  const getDialogTitle = () => {
    switch (confirmDialog.action) {
      case 'activate': return "Activer l'accès";
      case 'deactivate': return "Désactiver l'accès";
      case 'trial7': return 'Activer un essai de 7 jours';
      case 'trial30': return 'Activer un essai de 30 jours';
    }
  };

  const getDialogDescription = () => {
    if (!confirmDialog.subscription) return '';
    const name = `${confirmDialog.subscription.first_name} ${confirmDialog.subscription.last_name}`;
    switch (confirmDialog.action) {
      case 'activate': return `Vous allez activer l'accès complet pour ${name}. L'utilisateur pourra accéder à toutes les fonctionnalités.`;
      case 'deactivate': return `Vous allez désactiver l'accès pour ${name}. L'utilisateur ne pourra plus accéder à l'application.`;
      case 'trial7': {
        const end = new Date();
        end.setDate(end.getDate() + 7);
        return `Vous allez activer un essai de 7 jours pour ${name}. L'accès expirera automatiquement le ${end.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}.`;
      }
      case 'trial30': {
        const end = new Date();
        end.setDate(end.getDate() + 30);
        return `Vous allez activer un essai de 30 jours pour ${name}. L'accès expirera automatiquement le ${end.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}.`;
      }
    }
  };

  const getDialogColor = () => {
    switch (confirmDialog.action) {
      case 'activate': return '#2e7d32';
      case 'deactivate': return '#d32f2f';
      case 'trial7':
      case 'trial30': return '#ed6c02';
    }
  };

  // ======= RENDU =======

  if (authLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!isAdmin) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh', flexDirection: 'column', gap: 2 }}>
        <LockIcon sx={{ fontSize: 64, color: 'error.main' }} />
        <Typography variant="h5" color="error.main" fontWeight={600}>Accès Refusé</Typography>
        <Typography variant="body1" color="text.secondary">Vous n'avez pas les droits d'accès à cette page.</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1400, mx: 'auto' }}>
      {/* ===== HEADER ===== */}
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', md: 'center' }, mb: 4, gap: 2 }}>
        <Box>
          <Typography variant="h4" component="h1" sx={{ fontWeight: 700, mb: 0.5 }}>
            Gestion des Accès
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Activez, désactivez ou accordez des périodes d'essai aux utilisateurs
          </Typography>
          {lastRefresh && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 1 }}>
              <AccessTimeIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
              <Typography variant="caption" color="text.disabled">
                Dernière actualisation : {lastRefresh.toLocaleTimeString('fr-FR')}
              </Typography>
            </Box>
          )}
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5 }}>
          <Button
            variant="outlined"
            startIcon={<SyncIcon />}
            onClick={handleSync}
            disabled={loading}
            sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600 }}
          >
            Synchroniser
          </Button>
          <Button
            variant="contained"
            startIcon={loading ? <CircularProgress size={18} color="inherit" /> : <RefreshIcon />}
            onClick={loadSubscriptions}
            disabled={loading}
            sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600, minWidth: 130 }}
          >
            {loading ? 'Chargement...' : 'Actualiser'}
          </Button>
        </Box>
      </Box>

      {/* ===== ALERTES ===== */}
      {error && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* ===== STATS ===== */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        <Grid item xs={6} sm={3}>
          <StatCard
            icon={<PeopleIcon />}
            label="Total utilisateurs"
            value={stats.total}
            gradient="linear-gradient(135deg, #1976d2, #42a5f5)"
            iconColor="#1976d2"
          />
        </Grid>
        <Grid item xs={6} sm={3}>
          <StatCard
            icon={<LockOpenIcon />}
            label="Accès actifs"
            value={stats.active}
            gradient="linear-gradient(135deg, #2e7d32, #66bb6a)"
            iconColor="#2e7d32"
          />
        </Grid>
        <Grid item xs={6} sm={3}>
          <StatCard
            icon={<LockIcon />}
            label="Accès verrouillés"
            value={stats.inactive}
            gradient="linear-gradient(135deg, #d32f2f, #ef5350)"
            iconColor="#d32f2f"
          />
        </Grid>
        <Grid item xs={6} sm={3}>
          <StatCard
            icon={<TimerIcon />}
            label="Essais actifs"
            value={stats.trial}
            gradient="linear-gradient(135deg, #ed6c02, #ff9800)"
            iconColor="#ed6c02"
          />
        </Grid>
      </Grid>

      {/* ===== RECHERCHE & FILTRES ===== */}
      <Box sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Rechercher par nom ou email..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon sx={{ color: 'text.disabled' }} />
              </InputAdornment>
            ),
          }}
          sx={{
            mb: 2,
            '& .MuiOutlinedInput-root': {
              borderRadius: 2.5,
              bgcolor: 'background.paper',
            },
          }}
        />
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
          {([
            { key: 'all', label: 'Tous', count: stats.total },
            { key: 'active', label: 'Actifs', count: stats.active },
            { key: 'inactive', label: 'Verrouillés', count: stats.inactive },
            { key: 'trial', label: 'En essai', count: stats.trial },
          ] as const).map((filter) => (
            <Chip
              key={filter.key}
              label={`${filter.label} (${filter.count})`}
              onClick={() => setFilterStatus(filter.key)}
              variant={filterStatus === filter.key ? 'filled' : 'outlined'}
              color={filterStatus === filter.key ? 'primary' : 'default'}
              sx={{
                fontWeight: 600,
                borderRadius: 2,
                transition: 'all 0.2s',
              }}
            />
          ))}
          <Typography variant="body2" color="text.secondary" sx={{ ml: 'auto' }}>
            {filteredSubscriptions.length} résultat{filteredSubscriptions.length !== 1 ? 's' : ''}
          </Typography>
        </Box>
      </Box>

      {/* ===== GRILLE UTILISATEURS ===== */}
      {loading && subscriptions.length === 0 ? (
        <Grid container spacing={2}>
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Grid item xs={12} sm={6} md={4} key={i}>
              <Card sx={{ borderRadius: 3, p: 2.5 }}>
                <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
                  <Skeleton variant="circular" width={48} height={48} />
                  <Box sx={{ flex: 1 }}>
                    <Skeleton variant="text" width="60%" />
                    <Skeleton variant="text" width="80%" />
                  </Box>
                </Box>
                <Skeleton variant="rectangular" height={36} sx={{ borderRadius: 2 }} />
              </Card>
            </Grid>
          ))}
        </Grid>
      ) : filteredSubscriptions.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <PeopleIcon sx={{ fontSize: 64, color: 'text.disabled', mb: 2 }} />
          <Typography variant="h6" color="text.secondary" gutterBottom>
            Aucun utilisateur trouvé
          </Typography>
          <Typography variant="body2" color="text.disabled">
            {searchTerm ? 'Essayez de modifier votre recherche' : 'Aucun utilisateur ne correspond aux filtres sélectionnés'}
          </Typography>
        </Box>
      ) : (
        <Fade in>
          <Grid container spacing={2}>
            {filteredSubscriptions.map((sub) => (
              <Grid item xs={12} sm={6} md={4} key={sub.id}>
                <UserCard
                  sub={sub}
                  onActivate={(s) => openConfirmDialog(s, 'activate')}
                  onDeactivate={(s) => openConfirmDialog(s, 'deactivate')}
                  onTrial={(s, days) => openConfirmDialog(s, days === 7 ? 'trial7' : 'trial30')}
                  onViewDetails={(s) => setDetailsDialog({ open: true, subscription: s })}
                />
              </Grid>
            ))}
          </Grid>
        </Fade>
      )}

      {/* ===== DIALOG DE CONFIRMATION ===== */}
      <Dialog
        open={confirmDialog.open}
        onClose={closeConfirmDialog}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3, overflow: 'hidden' } }}
      >
        {/* Bande de couleur en haut */}
        <Box sx={{ height: 4, bgcolor: getDialogColor() }} />
        <DialogTitle sx={{ pb: 1, pt: 2.5, fontWeight: 700 }}>
          {getDialogTitle()}
        </DialogTitle>
        <DialogContent>
          {confirmDialog.subscription && (
            <Box sx={{ mt: 1 }}>
              {/* Résumé utilisateur */}
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2.5, p: 2, bgcolor: alpha('#000', 0.03), borderRadius: 2 }}>
                <Avatar
                  sx={{
                    width: 48,
                    height: 48,
                    bgcolor: getAvatarColor(`${confirmDialog.subscription.first_name} ${confirmDialog.subscription.last_name}`),
                    fontWeight: 700,
                  }}
                >
                  {confirmDialog.subscription.first_name.charAt(0)}{confirmDialog.subscription.last_name.charAt(0)}
                </Avatar>
                <Box>
                  <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                    {confirmDialog.subscription.first_name} {confirmDialog.subscription.last_name}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {confirmDialog.subscription.email}
                  </Typography>
                </Box>
              </Box>

              {/* Description */}
              <Alert
                severity={confirmDialog.action === 'deactivate' ? 'warning' : 'info'}
                sx={{ mb: 2.5, borderRadius: 2 }}
              >
                {getDialogDescription()}
              </Alert>

              {/* Notes */}
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Notes (optionnel)"
                value={confirmDialog.notes}
                onChange={(e) => setConfirmDialog(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Raison de l'action, commentaires..."
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
          <Button
            onClick={closeConfirmDialog}
            disabled={actionLoading}
            sx={{ borderRadius: 2, textTransform: 'none' }}
          >
            Annuler
          </Button>
          <Button
            onClick={handleConfirmAction}
            variant="contained"
            disabled={actionLoading}
            startIcon={actionLoading ? <CircularProgress size={18} color="inherit" /> : undefined}
            sx={{
              borderRadius: 2,
              textTransform: 'none',
              fontWeight: 600,
              bgcolor: getDialogColor(),
              boxShadow: 'none',
              '&:hover': { bgcolor: getDialogColor(), filter: 'brightness(0.9)', boxShadow: 'none' },
            }}
          >
            {actionLoading ? 'En cours...' : 'Confirmer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* ===== DIALOG DE DÉTAILS ===== */}
      <Dialog
        open={detailsDialog.open}
        onClose={() => setDetailsDialog({ open: false, subscription: null })}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3, overflow: 'hidden' } }}
      >
        {detailsDialog.subscription && (() => {
          const sub = detailsDialog.subscription!;
          const trialActive = hasActiveTrial(sub);
          return (
            <>
              <Box sx={{ height: 4, bgcolor: trialActive ? '#ed6c02' : sub.is_active ? '#2e7d32' : '#d32f2f' }} />
              <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', pb: 1 }}>
                <Typography variant="h6" sx={{ fontWeight: 700 }}>Détails de l'utilisateur</Typography>
                <IconButton size="small" onClick={() => setDetailsDialog({ open: false, subscription: null })}>
                  <CloseIcon />
                </IconButton>
              </DialogTitle>
              <DialogContent>
                {/* En-tête utilisateur */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3, p: 2, bgcolor: alpha('#000', 0.03), borderRadius: 2 }}>
                  <Avatar
                    sx={{
                      width: 56,
                      height: 56,
                      bgcolor: getAvatarColor(`${sub.first_name} ${sub.last_name}`),
                      fontWeight: 700,
                      fontSize: '1.25rem',
                    }}
                  >
                    {sub.first_name.charAt(0)}{sub.last_name.charAt(0)}
                  </Avatar>
                  <Box sx={{ flex: 1 }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      {sub.first_name} {sub.last_name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {sub.email}
                    </Typography>
                  </Box>
                  <Chip
                    label={trialActive ? 'Essai' : sub.is_active ? 'Actif' : 'Verrouillé'}
                    size="small"
                    sx={{
                      bgcolor: alpha(trialActive ? '#ed6c02' : sub.is_active ? '#2e7d32' : '#d32f2f', 0.1),
                      color: trialActive ? '#ed6c02' : sub.is_active ? '#2e7d32' : '#d32f2f',
                      fontWeight: 600,
                    }}
                  />
                </Box>

                {/* Informations détaillées */}
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <Box>
                    <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                      Identifiant utilisateur
                    </Typography>
                    <Typography variant="body2" sx={{ fontFamily: 'monospace', mt: 0.25 }}>
                      {sub.user_id}
                    </Typography>
                  </Box>

                  <Divider />

                  <Box>
                    <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                      Type d'abonnement
                    </Typography>
                    <Box sx={{ mt: 0.5 }}>
                      <Chip label={sub.subscription_type} size="small" variant="outlined" />
                    </Box>
                  </Box>

                  {trialActive && sub.trial_ends_at && (
                    <>
                      <Divider />
                      <Box>
                        <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                          Essai en cours
                        </Typography>
                        <TrialProgressBar sub={sub} />
                      </Box>
                    </>
                  )}

                  <Divider />

                  <Box>
                    <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                      Historique
                    </Typography>
                    <Box sx={{ mt: 0.5, display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                      <Typography variant="body2">
                        Créé le {new Date(sub.created_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}
                      </Typography>
                      {sub.activated_at && (
                        <Typography variant="body2">
                          Activé le {new Date(sub.activated_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}
                        </Typography>
                      )}
                      <Typography variant="body2">
                        Mis à jour le {new Date(sub.updated_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}
                      </Typography>
                    </Box>
                  </Box>

                  {sub.notes && (
                    <>
                      <Divider />
                      <Box>
                        <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                          Notes
                        </Typography>
                        <Typography variant="body2" sx={{ mt: 0.5 }}>
                          {sub.notes}
                        </Typography>
                      </Box>
                    </>
                  )}

                  {(sub.stripe_customer_id || sub.stripe_subscription_id) && (
                    <>
                      <Divider />
                      <Box>
                        <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                          Stripe
                        </Typography>
                        <Box sx={{ mt: 0.5, display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                          {sub.stripe_customer_id && (
                            <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                              Client: {sub.stripe_customer_id}
                            </Typography>
                          )}
                          {sub.stripe_subscription_id && (
                            <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                              Abo: {sub.stripe_subscription_id}
                            </Typography>
                          )}
                          {sub.stripe_current_period_end && (
                            <Typography variant="body2">
                              Fin période: {new Date(sub.stripe_current_period_end).toLocaleDateString('fr-FR')}
                            </Typography>
                          )}
                        </Box>
                      </Box>
                    </>
                  )}
                </Box>
              </DialogContent>
              <DialogActions sx={{ px: 3, pb: 2.5, gap: 1, flexWrap: 'wrap', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  {!sub.is_active && (
                    <>
                      <Button
                        size="small"
                        variant="outlined"
                        startIcon={<TimerIcon />}
                        onClick={() => {
                          setDetailsDialog({ open: false, subscription: null });
                          openConfirmDialog(sub, 'trial7');
                        }}
                        sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600, borderColor: alpha('#ed6c02', 0.5), color: '#ed6c02' }}
                      >
                        Essai 7j
                      </Button>
                      <Button
                        size="small"
                        variant="outlined"
                        startIcon={<TimerIcon />}
                        onClick={() => {
                          setDetailsDialog({ open: false, subscription: null });
                          openConfirmDialog(sub, 'trial30');
                        }}
                        sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600, borderColor: alpha('#f57c00', 0.5), color: '#f57c00' }}
                      >
                        Essai 30j
                      </Button>
                    </>
                  )}
                </Box>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  {sub.is_active ? (
                    <Button
                      variant="contained"
                      startIcon={<BlockIcon />}
                      onClick={() => {
                        setDetailsDialog({ open: false, subscription: null });
                        openConfirmDialog(sub, 'deactivate');
                      }}
                      sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600, bgcolor: '#d32f2f', boxShadow: 'none', '&:hover': { bgcolor: '#b71c1c', boxShadow: 'none' } }}
                    >
                      Désactiver
                    </Button>
                  ) : (
                    <Button
                      variant="contained"
                      startIcon={<CheckIcon />}
                      onClick={() => {
                        setDetailsDialog({ open: false, subscription: null });
                        openConfirmDialog(sub, 'activate');
                      }}
                      sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600, bgcolor: '#2e7d32', boxShadow: 'none', '&:hover': { bgcolor: '#1b5e20', boxShadow: 'none' } }}
                    >
                      Activer
                    </Button>
                  )}
                </Box>
              </DialogActions>
            </>
          );
        })()}
      </Dialog>

      {/* ===== SNACKBAR SUCCESS ===== */}
      <Snackbar
        open={!!success}
        autoHideDuration={4000}
        onClose={() => setSuccess(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          onClose={() => setSuccess(null)}
          severity="success"
          variant="filled"
          sx={{ borderRadius: 2, fontWeight: 600 }}
        >
          {success}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default UserAccessManagement;

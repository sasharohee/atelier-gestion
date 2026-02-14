import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Alert,
  CircularProgress,
  Avatar,
  LinearProgress,
  Tooltip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  alpha,
  InputAdornment,
} from '@mui/material';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  CheckCircle as CheckIcon,
  Cancel as CancelIcon,
  Star as StarIcon,
  People as PeopleIcon,
  TrendingUp as TrendingUpIcon,
  History as HistoryIcon,
  Settings as SettingsIcon,
  Refresh as RefreshIcon,
  Visibility as ViewIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search,
  CardGiftcard,
  EmojiEvents,
} from '@mui/icons-material';
import { supabase } from '../../lib/supabase';
import { toast } from 'react-hot-toast';
import LoyaltyHistory from '../../components/LoyaltyHistory/LoyaltyHistory';
import ClientForm from '../../components/ClientForm';
import LoyaltySettingsSimple from '../../components/LoyaltyManagement/LoyaltySettingsSimple';
import LoyaltyTiersDisplay from '../../components/LoyaltyManagement/LoyaltyTiersDisplay';

/* ─── Design tokens ─── */
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

const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;

const BTN_DARK = {
  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;

/* ─── Types ─── */
interface LoyaltyTier {
  id: string;
  name: string;
  description: string;
  min_points: number;
  points_required: number;
  discount_percentage: number;
  color: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface ClientLoyalty {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  loyalty_points: number;
  current_tier_id: string;
  created_at: string;
  updated_at: string;
  used_points?: number;
  tier?: LoyaltyTier;
}

interface Referral {
  id: string;
  referrer_client_id: string;
  referred_client_id: string;
  status: 'pending' | 'confirmed' | 'rejected' | 'completed';
  points_awarded: number;
  created_at: string;
  referrer_client?: { first_name: string; last_name: string; email: string };
  referred_client?: { first_name: string; last_name: string; email: string };
}

interface LoyaltyStatistics {
  total_clients_with_points: number;
  total_points_distributed: number;
  total_points_used: number;
  total_referrals_pending: number;
  total_referrals_confirmed: number;
  total_discounts_applied: number;
  total_discount_amount: number;
  tier_distribution: Record<string, number>;
}

/* ─── KPI Mini Card ─── */
function KpiMini({ icon, iconColor, label, value }: {
  icon: React.ReactNode; iconColor: string; label: string; value: string | number;
}) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{
            width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0,
            boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
          }}>
            {icon}
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>
              {value}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>
              {label}
            </Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── Tab options ─── */
const TAB_OPTIONS = [
  { value: 0, label: 'Clients fidèles' },
  { value: 1, label: 'Parrainages' },
  { value: 2, label: 'Niveaux de fidélité' },
];

/* ─── Main component ─── */
const Loyalty: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(true);
  const [statistics, setStatistics] = useState<LoyaltyStatistics | null>(null);
  const [clients, setClients] = useState<ClientLoyalty[]>([]);
  const [allClients, setAllClients] = useState<any[]>([]);
  const [referrals, setReferrals] = useState<Referral[]>([]);
  const [loyaltyTiers, setLoyaltyTiers] = useState<LoyaltyTier[]>([]);
  const [refreshTrigger, setRefreshTrigger] = useState(0);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  const [referralDialog, setReferralDialog] = useState(false);
  const [pointsDialog, setPointsDialog] = useState(false);
  const [usePointsDialog, setUsePointsDialog] = useState(false);
  const [settingsDialog, setSettingsDialog] = useState(false);
  const [historyDialog, setHistoryDialog] = useState(false);
  const [selectedClient, setSelectedClient] = useState<ClientLoyalty | null>(null);

  const [referralForm, setReferralForm] = useState({ referrer_client_id: '', referred_client_id: '', notes: '' });
  const [pointsForm, setPointsForm] = useState({ client_id: '', points: 0, description: '' });
  const [usePointsForm, setUsePointsForm] = useState({ client_id: '', points: 0, description: '' });
  const [showNewClientForm, setShowNewClientForm] = useState(false);

  useEffect(() => { loadData(); }, []);

  const handleSettingsDataChanged = () => {
    if (isRefreshing) return;
    setIsRefreshing(true);
    loadData();
    setTimeout(() => {
      setRefreshTrigger(prev => prev + 1);
      setIsRefreshing(false);
    }, 2000);
  };

  const loadData = async () => {
    try {
      setLoading(true);

      const { data: statsData } = await supabase.rpc('get_loyalty_statistics');
      if (statsData?.success) setStatistics(statsData.data);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { toast.error("Erreur d'authentification"); return; }

      const { data: allClientsData } = await supabase
        .from('clients')
        .select('id, first_name, last_name, email')
        .eq('user_id', user.id)
        .order('first_name');
      setAllClients(allClientsData || []);

      const { data: clientsData } = await supabase
        .from('clients')
        .select('id, first_name, last_name, email, phone, loyalty_points, current_tier_id, user_id, created_at, updated_at')
        .eq('user_id', user.id)
        .order('loyalty_points', { ascending: false });

      const { data: tiersData } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .order('points_required', { ascending: true });

      const uniqueTiers = tiersData?.reduce((acc: any[], tier: any) => {
        if (!acc.find((t: any) => t.name === tier.name)) acc.push(tier);
        return acc;
      }, [] as LoyaltyTier[]) || [];
      setLoyaltyTiers(uniqueTiers);

      const { data: historyData } = await supabase
        .from('loyalty_points_history')
        .select('client_id, points_change')
        .lt('points_change', 0);

      const usedPointsByClient: Record<string, number> = {};
      (historyData || []).forEach(record => {
        usedPointsByClient[record.client_id] = (usedPointsByClient[record.client_id] || 0) + Math.abs(record.points_change);
      });

      const clientsWithTiers = (clientsData || []).map(client => {
        let tier = (tiersData || []).find(t => t.id === client.current_tier_id);
        if (!tier && client.current_tier_id) {
          tier = (tiersData || []).find(t => String(t.id) === String(client.current_tier_id));
        }
        if (!tier) {
          const pts = client.loyalty_points;
          if (pts >= 2000) tier = (tiersData || []).find(t => t.name === 'Diamant');
          else if (pts >= 1000) tier = (tiersData || []).find(t => t.name === 'Platine');
          else if (pts >= 500) tier = (tiersData || []).find(t => t.name === 'Or');
          else if (pts >= 100) tier = (tiersData || []).find(t => t.name === 'Argent');
          else tier = (tiersData || []).find(t => t.name === 'Bronze');
        }
        let finalTier = tier;
        if (!finalTier) {
          const pts = client.loyalty_points;
          if (pts >= 2000) finalTier = { name: 'Diamant', color: '#B9F2FF', discount_percentage: 20 };
          else if (pts >= 1000) finalTier = { name: 'Platine', color: '#E5E4E2', discount_percentage: 15 };
          else if (pts >= 500) finalTier = { name: 'Or', color: '#FFD700', discount_percentage: 10 };
          else if (pts >= 100) finalTier = { name: 'Argent', color: '#C0C0C0', discount_percentage: 5 };
          else finalTier = { name: 'Bronze', color: '#CD7F32', discount_percentage: 0 };
        }
        return { ...client, tier: finalTier, used_points: usedPointsByClient[client.id] || 0 };
      });
      setClients(clientsWithTiers);

      let referralsData: any[] = [];
      try {
        const { data: referralsResult, error: referralsError } = await supabase
          .from('referrals')
          .select(`*, referrer_client:clients!referrals_referrer_client_id_fkey(first_name, last_name, email), referred_client:clients!referrals_referred_client_id_fkey(first_name, last_name, email)`)
          .order('created_at', { ascending: false });
        if (!referralsError) referralsData = referralsResult || [];
      } catch { /* ignore */ }
      setReferrals(referralsData);
    } catch {
      toast.error('Erreur lors du chargement des données');
    } finally {
      setLoading(false);
    }
  };

  /* ─── Actions ─── */
  const createReferral = async () => {
    try {
      const { data, error } = await supabase.rpc('create_referral', {
        p_referrer_client_id: referralForm.referrer_client_id,
        p_referred_client_id: referralForm.referred_client_id,
        p_notes: referralForm.notes,
      });
      if (error) throw error;
      if (data?.success) {
        toast.success('Parrainage créé avec succès');
        setReferralDialog(false);
        setReferralForm({ referrer_client_id: '', referred_client_id: '', notes: '' });
        loadData();
      } else toast.error(data?.error || 'Erreur lors de la création du parrainage');
    } catch { toast.error('Erreur lors de la création du parrainage'); }
  };

  const confirmReferral = async (id: string) => {
    try {
      const { data, error } = await supabase.rpc('confirm_referral', { p_referral_id: id });
      if (error) throw error;
      if (data?.success) { toast.success('Parrainage confirmé'); loadData(); }
      else toast.error(data?.error || 'Erreur lors de la confirmation');
    } catch { toast.error('Erreur lors de la confirmation'); }
  };

  const rejectReferral = async (id: string) => {
    try {
      const { data, error } = await supabase.rpc('reject_referral', { p_referral_id: id });
      if (error) throw error;
      if (data?.success) { toast.success('Parrainage rejeté'); loadData(); }
      else toast.error(data?.error || 'Erreur lors du rejet');
    } catch { toast.error('Erreur lors du rejet'); }
  };

  const handleDeleteReferral = async (id: string) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer ce parrainage ? Cette action est irréversible.')) return;
    try {
      const { error } = await supabase.from('referrals').delete().eq('id', id);
      if (error) { toast.error('Erreur lors de la suppression'); return; }
      toast.success('Parrainage supprimé'); loadData();
    } catch { toast.error('Erreur lors de la suppression'); }
  };

  const handleCreateNewClient = async (clientData: any) => {
    try {
      const clientToInsert = {
        first_name: clientData.firstName, last_name: clientData.lastName,
        email: clientData.email, phone: clientData.mobile,
        address: clientData.address, city: clientData.city,
        postal_code: clientData.postalCode, region: clientData.region,
        company_name: clientData.companyName, vat_number: clientData.vatNumber,
        siren_number: clientData.sirenNumber, country_code: clientData.countryCode,
        address_complement: clientData.addressComplement,
        billing_address: clientData.billingAddress,
        billing_address_complement: clientData.billingAddressComplement,
        billing_region: clientData.billingRegion,
        billing_postal_code: clientData.billingPostalCode,
        billing_city: clientData.billingCity,
        accounting_code: clientData.accountingCode,
        cni_identifier: clientData.cniIdentifier,
        internal_note: clientData.internalNote,
        status: clientData.status,
        sms_notification: clientData.smsNotification,
        email_notification: clientData.emailNotification,
        sms_marketing: clientData.smsMarketing,
        email_marketing: clientData.emailMarketing,
        category: clientData.category, title: clientData.title,
      };
      const { data, error } = await supabase.from('clients').insert([clientToInsert]).select().single();
      if (error) throw error;
      if (data) {
        toast.success('Client créé avec succès');
        setShowNewClientForm(false);
        await loadData();
        setReferralForm({ ...referralForm, referred_client_id: data.id });
      }
    } catch (error: any) {
      let msg = 'Erreur lors de la création du client';
      if (error?.message) {
        const t = error.message.toLowerCase();
        if (t.includes('duplicate key') && t.includes('email')) msg = 'Un client avec cet email existe déjà.';
        else if (t.includes('unique constraint')) msg = 'Cette information existe déjà dans le système.';
        else msg = error.message;
      }
      toast.error(msg);
    }
  };

  const addPoints = async () => {
    try {
      const { data, error } = await supabase.rpc('add_loyalty_points', {
        p_client_id: pointsForm.client_id,
        p_points: pointsForm.points,
        p_description: pointsForm.description,
      });
      if (error) throw error;
      if (data?.success) {
        try { await supabase.rpc('update_client_tiers'); } catch { /* ignore */ }
        toast.success('Points ajoutés avec succès');
        setPointsDialog(false);
        setPointsForm({ client_id: '', points: 0, description: '' });
        loadData();
      } else toast.error(data?.error || "Erreur lors de l'ajout des points");
    } catch { toast.error("Erreur lors de l'ajout des points"); }
  };

  const usePoints = async () => {
    try {
      const { data, error } = await supabase.rpc('use_loyalty_points', {
        p_client_id: usePointsForm.client_id,
        p_points: usePointsForm.points,
        p_description: usePointsForm.description,
      });
      if (error) throw error;
      if (data?.success) {
        toast.success('Points utilisés avec succès');
        setUsePointsDialog(false);
        setUsePointsForm({ client_id: '', points: 0, description: '' });
        loadData();
      } else toast.error(data?.error || "Erreur lors de l'utilisation des points");
    } catch { toast.error("Erreur lors de l'utilisation des points"); }
  };

  const handleDeleteClient = async (clientId: string) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer ce client ? Cette action supprimera également tous ses points.')) return;
    try {
      const { error } = await supabase.from('clients').delete().eq('id', clientId);
      if (error) { toast.error('Erreur lors de la suppression'); return; }
      toast.success('Client supprimé'); loadData();
    } catch { toast.error('Erreur lors de la suppression'); }
  };

  const handleDeleteLoyaltyPoints = async (clientId: string) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer tous les points de ce client ?')) return;
    try {
      const { error } = await supabase.from('client_loyalty_points').delete().eq('client_id', clientId);
      if (error) { toast.error('Erreur lors de la suppression des points'); return; }
      toast.success('Points supprimés'); loadData();
    } catch { toast.error('Erreur lors de la suppression des points'); }
  };

  const getStatusChip = (status: string) => {
    const map: Record<string, { label: string; color: string }> = {
      pending: { label: 'En attente', color: '#f59e0b' },
      confirmed: { label: 'Confirmé', color: '#22c55e' },
      rejected: { label: 'Rejeté', color: '#ef4444' },
      completed: { label: 'Terminé', color: '#06b6d4' },
    };
    const c = map[status] || { label: status, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const getTierColor = (name: string) => {
    const map: Record<string, string> = {
      Bronze: '#CD7F32', Argent: '#9CA3AF', Or: '#F59E0B',
      Platine: '#8B5CF6', Diamant: '#06B6D4',
    };
    return map[name] || '#6b7280';
  };

  /* ─── Filter clients by search ─── */
  const filteredClients = searchTerm
    ? clients.filter(c =>
        `${c.first_name} ${c.last_name}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.email.toLowerCase().includes(searchTerm.toLowerCase())
      )
    : clients;

  /* ─── Loading ─── */
  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress sx={{ color: '#111827' }} />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>
            Programme de fidélité
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gérez les points de fidélité, parrainages et niveaux
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={loadData}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.primary' }}
          >
            Actualiser
          </Button>
          <Button
            variant="contained"
            startIcon={<SettingsIcon />}
            onClick={() => setSettingsDialog(true)}
            sx={BTN_DARK}
          >
            Paramètres
          </Button>
        </Box>
      </Box>

      {/* KPI Cards */}
      {statistics && (
        <Grid container spacing={2} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<PeopleIcon sx={{ fontSize: 20 }} />}
              iconColor="#6366f1"
              label="Clients avec points"
              value={statistics.total_clients_with_points}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<TrendingUpIcon sx={{ fontSize: 20 }} />}
              iconColor="#22c55e"
              label="Points distribués"
              value={statistics.total_points_distributed}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<CardGiftcard sx={{ fontSize: 20 }} />}
              iconColor="#f59e0b"
              label="Parrainages en attente"
              value={statistics.total_referrals_pending}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KpiMini
              icon={<EmojiEvents sx={{ fontSize: 20 }} />}
              iconColor="#8b5cf6"
              label="Réductions appliquées"
              value={statistics.total_discounts_applied}
            />
          </Grid>
        </Grid>
      )}

      {/* Tab chips */}
      <Box sx={{ display: 'flex', gap: 0.75, mb: 3, flexWrap: 'wrap' }}>
        {TAB_OPTIONS.map(opt => (
          <Chip
            key={opt.value}
            label={opt.label}
            onClick={() => {
              setActiveTab(opt.value);
              if (opt.value === 0) loadData();
            }}
            sx={{
              fontWeight: 600, borderRadius: '10px', fontSize: '0.8rem', px: 1, py: 2.2,
              ...(activeTab === opt.value
                ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
                : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
            }}
          />
        ))}
      </Box>

      {/* ───────── TAB 0 : Clients ───────── */}
      {activeTab === 0 && (
        <Box>
          {/* Search + actions bar */}
          <Card sx={{ ...CARD_BASE, mb: 3, '&:hover': {} }}>
            <CardContent sx={{ p: '16px !important', display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
              <TextField
                placeholder="Rechercher un client..."
                size="small"
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                sx={{ flex: 1, minWidth: 200, '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                InputProps={{
                  startAdornment: <InputAdornment position="start"><Search sx={{ color: 'text.disabled', fontSize: 20 }} /></InputAdornment>,
                }}
              />
              <Box sx={{ display: 'flex', gap: 1 }}>
                <Button
                  variant="contained"
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={() => setPointsDialog(true)}
                  disabled={allClients.length === 0}
                  sx={{ ...BTN_DARK, fontSize: '0.8rem' }}
                >
                  Ajouter des points
                </Button>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<RemoveIcon />}
                  onClick={() => setUsePointsDialog(true)}
                  disabled={allClients.length === 0}
                  sx={{
                    borderRadius: '10px', textTransform: 'none', fontWeight: 600, fontSize: '0.8rem',
                    borderColor: '#f59e0b', color: '#f59e0b',
                    '&:hover': { borderColor: '#d97706', bgcolor: alpha('#f59e0b', 0.04) },
                  }}
                >
                  Utiliser des points
                </Button>
              </Box>
            </CardContent>
          </Card>

          {allClients.length === 0 && (
            <Alert severity="info" sx={{ mb: 2, borderRadius: '12px' }}>
              Aucun client trouvé. Créez des clients dans la section Transactions.
            </Alert>
          )}

          {/* Clients table */}
          <Card sx={CARD_BASE}>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow sx={TABLE_HEAD_SX}>
                    <TableCell>Client</TableCell>
                    <TableCell align="right">Points totaux</TableCell>
                    <TableCell align="right">Utilisés</TableCell>
                    <TableCell align="right">Disponibles</TableCell>
                    <TableCell>Niveau</TableCell>
                    <TableCell>Progression</TableCell>
                    <TableCell align="center">Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredClients.map(client => {
                    const availablePoints = (client.loyalty_points || 0) - (client.used_points || 0);
                    const currentTier = client.tier;
                    const nextTier = loyaltyTiers.find(t => t.points_required > availablePoints);

                    let progress = 0;
                    if (nextTier && currentTier) {
                      const curPts = (currentTier as any).points_required || 0;
                      const needed = nextTier.points_required - curPts;
                      progress = needed > 0 ? Math.max(0, Math.min(100, ((availablePoints - curPts) / needed) * 100)) : 100;
                    } else if (nextTier && !currentTier) {
                      progress = Math.max(0, Math.min(100, (availablePoints / nextTier.points_required) * 100));
                    } else {
                      progress = 100;
                    }

                    const tierName = currentTier?.name || 'Sans niveau';
                    const tierColor = getTierColor(tierName);

                    return (
                      <TableRow key={client.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                            <Avatar sx={{
                              width: 36, height: 36, fontSize: '0.8rem', fontWeight: 700,
                              background: `linear-gradient(135deg, ${tierColor}, ${alpha(tierColor, 0.6)})`,
                              color: '#fff',
                            }}>
                              {client.first_name?.[0]}{client.last_name?.[0]}
                            </Avatar>
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                {client.first_name} {client.last_name}
                              </Typography>
                              <Typography variant="caption" color="text.disabled">{client.email}</Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>{client.loyalty_points || 0}</Typography>
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" color="text.secondary">{client.used_points || 0}</Typography>
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" sx={{ fontWeight: 700, color: '#6366f1' }}>
                            {availablePoints}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={tierName}
                            size="small"
                            sx={{
                              fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
                              bgcolor: alpha(tierColor, 0.12), color: tierColor,
                            }}
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ width: '100%', maxWidth: 180 }}>
                            <LinearProgress
                              variant="determinate"
                              value={Math.min(progress, 100)}
                              sx={{
                                height: 6, borderRadius: 3,
                                bgcolor: 'grey.100',
                                '& .MuiLinearProgress-bar': {
                                  borderRadius: 3,
                                  background: progress >= 100
                                    ? 'linear-gradient(135deg, #22c55e, #16a34a)'
                                    : `linear-gradient(135deg, ${tierColor}, ${alpha(tierColor, 0.6)})`,
                                },
                              }}
                            />
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.3 }}>
                              <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.65rem' }}>
                                {Math.round(progress)}%
                              </Typography>
                              {nextTier && progress < 100 ? (
                                <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.65rem' }}>
                                  {nextTier.points_required - availablePoints} pts vers {nextTier.name}
                                </Typography>
                              ) : progress >= 100 ? (
                                <Typography variant="caption" sx={{ color: '#22c55e', fontWeight: 600, fontSize: '0.65rem' }}>
                                  Niveau max
                                </Typography>
                              ) : null}
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell align="center">
                          <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                            <Tooltip title="Historique">
                              <IconButton size="small" onClick={() => { setSelectedClient(client); setHistoryDialog(true); }}
                                sx={{ color: '#6366f1', bgcolor: alpha('#6366f1', 0.08), '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }}>
                                <ViewIcon sx={{ fontSize: 18 }} />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="Modifier les points">
                              <IconButton size="small" onClick={() => {
                                setSelectedClient(client);
                                setPointsForm({ client_id: client.id, points: 0, description: '' });
                                setPointsDialog(true);
                              }}
                                sx={{ color: '#f59e0b', bgcolor: alpha('#f59e0b', 0.08), '&:hover': { bgcolor: alpha('#f59e0b', 0.15) } }}>
                                <EditIcon sx={{ fontSize: 18 }} />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="Supprimer les points">
                              <IconButton size="small" onClick={() => handleDeleteLoyaltyPoints(client.id)}
                                sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}>
                                <CancelIcon sx={{ fontSize: 18 }} />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="Supprimer le client">
                              <IconButton size="small" onClick={() => handleDeleteClient(client.id)}
                                sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}>
                                <DeleteIcon sx={{ fontSize: 18 }} />
                              </IconButton>
                            </Tooltip>
                          </Box>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>

            {filteredClients.length === 0 && (
              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 6 }}>
                <PeopleIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
                <Typography variant="body2" color="text.disabled">Aucun client trouvé</Typography>
              </Box>
            )}
          </Card>
        </Box>
      )}

      {/* ───────── TAB 1 : Referrals ───────── */}
      {activeTab === 1 && (
        <Box>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 600 }}>Parrainages</Typography>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => setReferralDialog(true)}
              disabled={allClients.length === 0}
              sx={BTN_DARK}
            >
              Nouveau parrainage
            </Button>
          </Box>

          {allClients.length === 0 && (
            <Alert severity="info" sx={{ mb: 2, borderRadius: '12px' }}>
              Aucun client trouvé. Créez des clients dans la section Transactions.
            </Alert>
          )}

          <Card sx={CARD_BASE}>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow sx={TABLE_HEAD_SX}>
                    <TableCell>Parrain</TableCell>
                    <TableCell>Parrainé</TableCell>
                    <TableCell>Statut</TableCell>
                    <TableCell align="right">Points</TableCell>
                    <TableCell>Date</TableCell>
                    <TableCell align="center">Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {referrals.map(referral => (
                    <TableRow key={referral.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                      <TableCell>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {referral.referrer_client?.first_name} {referral.referrer_client?.last_name}
                          </Typography>
                          <Typography variant="caption" color="text.disabled">{referral.referrer_client?.email}</Typography>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {referral.referred_client?.first_name} {referral.referred_client?.last_name}
                          </Typography>
                          <Typography variant="caption" color="text.disabled">{referral.referred_client?.email}</Typography>
                        </Box>
                      </TableCell>
                      <TableCell>{getStatusChip(referral.status)}</TableCell>
                      <TableCell align="right">
                        {referral.points_awarded > 0 ? (
                          <Typography variant="body2" sx={{ fontWeight: 700, color: '#22c55e' }}>
                            +{referral.points_awarded}
                          </Typography>
                        ) : (
                          <Typography variant="body2" color="text.disabled">—</Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" sx={{ fontWeight: 500 }}>
                          {new Date(referral.created_at).toLocaleDateString('fr-FR')}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                          {referral.status === 'pending' && (
                            <>
                              <Tooltip title="Confirmer">
                                <IconButton size="small" onClick={() => confirmReferral(referral.id)}
                                  sx={{ color: '#22c55e', bgcolor: alpha('#22c55e', 0.08), '&:hover': { bgcolor: alpha('#22c55e', 0.15) } }}>
                                  <CheckIcon sx={{ fontSize: 18 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Rejeter">
                                <IconButton size="small" onClick={() => rejectReferral(referral.id)}
                                  sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}>
                                  <CancelIcon sx={{ fontSize: 18 }} />
                                </IconButton>
                              </Tooltip>
                            </>
                          )}
                          <Tooltip title="Supprimer">
                            <IconButton size="small" onClick={() => handleDeleteReferral(referral.id)}
                              sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}>
                              <DeleteIcon sx={{ fontSize: 18 }} />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            {referrals.length === 0 && (
              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 6 }}>
                <CardGiftcard sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
                <Typography variant="body2" color="text.disabled">Aucun parrainage</Typography>
              </Box>
            )}
          </Card>
        </Box>
      )}

      {/* ───────── TAB 2 : Tiers ───────── */}
      {activeTab === 2 && (
        <Box>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 600 }}>Niveaux de fidélité</Typography>
            <Button
              variant="contained"
              startIcon={<RefreshIcon />}
              onClick={() => {
                if (isRefreshing) return;
                setIsRefreshing(true);
                loadData();
                setRefreshTrigger(prev => prev + 1);
                setTimeout(() => setIsRefreshing(false), 1000);
              }}
              disabled={isRefreshing}
              sx={BTN_DARK}
            >
              {isRefreshing ? 'Rafraîchissement...' : 'Rafraîchir'}
            </Button>
          </Box>

          <LoyaltyTiersDisplay
            onTierUpdate={() => loadData()}
            refreshTrigger={refreshTrigger}
          />
        </Box>
      )}

      {/* ───────── DIALOGS ───────── */}

      {/* Referral dialog */}
      <Dialog open={referralDialog} onClose={() => setReferralDialog(false)} maxWidth="sm" fullWidth
        PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Créer un parrainage</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            {allClients.length === 0 ? (
              <Alert severity="warning" sx={{ mb: 2, borderRadius: '12px' }}>
                Aucun client trouvé. Créez d'abord des clients.
              </Alert>
            ) : (
              <>
                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Client parrain</InputLabel>
                  <Select
                    value={referralForm.referrer_client_id}
                    onChange={e => setReferralForm({ ...referralForm, referrer_client_id: e.target.value })}
                    label="Client parrain"
                    sx={{ borderRadius: '10px' }}
                  >
                    {allClients.map(c => (
                      <MenuItem key={c.id} value={c.id}>{c.first_name} {c.last_name} ({c.email})</MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Client parrainé</InputLabel>
                  <Select
                    value={referralForm.referred_client_id}
                    onChange={e => setReferralForm({ ...referralForm, referred_client_id: e.target.value })}
                    label="Client parrainé"
                    sx={{ borderRadius: '10px' }}
                  >
                    {allClients.map(c => (
                      <MenuItem key={c.id} value={c.id}>{c.first_name} {c.last_name} ({c.email})</MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <Box sx={{ display: 'flex', justifyContent: 'center', mb: 2 }}>
                  <Button
                    variant="outlined"
                    startIcon={<AddIcon />}
                    onClick={() => setShowNewClientForm(true)}
                    sx={{ borderStyle: 'dashed', borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}
                  >
                    Nouveau client
                  </Button>
                </Box>

                <TextField
                  fullWidth multiline rows={3} label="Notes"
                  value={referralForm.notes}
                  onChange={e => setReferralForm({ ...referralForm, notes: e.target.value })}
                  sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                />
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setReferralDialog(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button onClick={createReferral} variant="contained" sx={BTN_DARK}>
            Créer le parrainage
          </Button>
        </DialogActions>
      </Dialog>

      {/* New client form */}
      <ClientForm
        open={showNewClientForm}
        onClose={() => setShowNewClientForm(false)}
        onSubmit={handleCreateNewClient}
        existingEmails={allClients.map(c => c.email)}
      />

      {/* Add points dialog */}
      <Dialog open={pointsDialog} onClose={() => setPointsDialog(false)} maxWidth="sm" fullWidth
        PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Ajouter des points</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            {allClients.length === 0 ? (
              <Alert severity="warning" sx={{ mb: 2, borderRadius: '12px' }}>
                Aucun client trouvé.
              </Alert>
            ) : (
              <>
                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Client</InputLabel>
                  <Select
                    value={pointsForm.client_id}
                    onChange={e => setPointsForm({ ...pointsForm, client_id: e.target.value })}
                    label="Client"
                    sx={{ borderRadius: '10px' }}
                  >
                    {allClients.map(c => (
                      <MenuItem key={c.id} value={c.id}>{c.first_name} {c.last_name} ({c.email})</MenuItem>
                    ))}
                  </Select>
                </FormControl>
                <TextField
                  fullWidth type="number" label="Points à ajouter"
                  value={pointsForm.points}
                  onChange={e => setPointsForm({ ...pointsForm, points: parseInt(e.target.value) || 0 })}
                  sx={{ mb: 2, '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                />
                <TextField
                  fullWidth multiline rows={3} label="Description"
                  value={pointsForm.description}
                  onChange={e => setPointsForm({ ...pointsForm, description: e.target.value })}
                  sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                />
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setPointsDialog(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button onClick={addPoints} variant="contained" sx={BTN_DARK}>
            Ajouter les points
          </Button>
        </DialogActions>
      </Dialog>

      {/* Use points dialog */}
      <Dialog open={usePointsDialog} onClose={() => setUsePointsDialog(false)} maxWidth="sm" fullWidth
        PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Utiliser des points</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            {allClients.length === 0 ? (
              <Alert severity="warning" sx={{ mb: 2, borderRadius: '12px' }}>
                Aucun client trouvé.
              </Alert>
            ) : (
              <>
                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Client</InputLabel>
                  <Select
                    value={usePointsForm.client_id}
                    onChange={e => setUsePointsForm({ ...usePointsForm, client_id: e.target.value })}
                    label="Client"
                    sx={{ borderRadius: '10px' }}
                  >
                    {allClients.map(c => (
                      <MenuItem key={c.id} value={c.id}>{c.first_name} {c.last_name} ({c.email})</MenuItem>
                    ))}
                  </Select>
                </FormControl>
                <TextField
                  fullWidth type="number" label="Points à utiliser"
                  value={usePointsForm.points}
                  onChange={e => setUsePointsForm({ ...usePointsForm, points: parseInt(e.target.value) || 0 })}
                  sx={{ mb: 2, '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                />
                <TextField
                  fullWidth multiline rows={3} label="Description"
                  value={usePointsForm.description}
                  onChange={e => setUsePointsForm({ ...usePointsForm, description: e.target.value })}
                  sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                />
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setUsePointsDialog(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button onClick={usePoints} variant="contained"
            sx={{ ...BTN_DARK, bgcolor: '#f59e0b', '&:hover': { bgcolor: '#d97706' }, boxShadow: '0 2px 8px rgba(245,158,11,0.25)' }}>
            Utiliser les points
          </Button>
        </DialogActions>
      </Dialog>

      {/* Settings dialog */}
      <Dialog open={settingsDialog} onClose={() => setSettingsDialog(false)} maxWidth="xl" fullWidth
        PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Paramètres de fidélité</DialogTitle>
        <DialogContent>
          <LoyaltySettingsSimple onDataChanged={handleSettingsDataChanged} />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setSettingsDialog(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Fermer
          </Button>
        </DialogActions>
      </Dialog>

      {/* History dialog */}
      <LoyaltyHistory
        open={historyDialog}
        onClose={() => setHistoryDialog(false)}
        clientId={selectedClient?.id || ''}
        clientName={selectedClient ? `${selectedClient.first_name} ${selectedClient.last_name}` : ''}
      />
    </Box>
  );
};

export default Loyalty;

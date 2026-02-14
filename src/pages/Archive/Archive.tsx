import React, { useState, useMemo } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Avatar,
  Button,
  IconButton,
  Grid,
  Tooltip,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Pagination,
  Snackbar,
  Alert,
  InputAdornment,
  alpha,
} from '@mui/material';
import {
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
  Search as SearchIcon,
  Receipt as ReceiptIcon,
  Archive as ArchiveIcon,
  RestoreFromTrash as RestoreIcon,
  CalendarToday as CalendarIcon,
  Person as PersonIcon,
  CheckCircle as CheckCircleIcon,
  CheckCircleOutline as CheckCircleOutlineIcon,
  Inventory as InventoryIcon,
  AttachMoney as MoneyIcon,
  CreditScore as PaidIcon,
  MoneyOff as UnpaidIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { deviceTypeColors } from '../../theme';
import { Repair } from '../../types';
import Invoice from '../../components/Invoice';
import { repairService } from '../../services/supabaseService';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

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
const TABLE_HEAD_SX = {
  '& th': { borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase', letterSpacing: '0.05em' },
} as const;
const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── filter chips ─── */
const DEVICE_CHIPS: { key: string; label: string }[] = [
  { key: 'all', label: 'Tous' },
  { key: 'smartphone', label: 'Smartphone' },
  { key: 'tablet', label: 'Tablette' },
  { key: 'laptop', label: 'PC Portable' },
  { key: 'desktop', label: 'PC Fixe' },
  { key: 'other', label: 'Autre' },
];

const DATE_CHIPS: { key: string; label: string }[] = [
  { key: 'all', label: 'Toutes' },
  { key: '30days', label: '30 jours' },
  { key: '90days', label: '90 jours' },
  { key: '1year', label: '1 an' },
];

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
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>{value}</Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>{label}</Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── helpers ─── */
const getDeviceTypeIcon = (type: string) => {
  const icons: Record<string, React.ReactNode> = {
    smartphone: <PhoneIcon sx={{ fontSize: 16 }} />,
    tablet: <TabletIcon sx={{ fontSize: 16 }} />,
    laptop: <LaptopIcon sx={{ fontSize: 16 }} />,
    desktop: <ComputerIcon sx={{ fontSize: 16 }} />,
  };
  return icons[type] || <ComputerIcon sx={{ fontSize: 16 }} />;
};

const safeFormatDate = (date: any, fmt: string) => {
  try {
    if (!date) return 'Date inconnue';
    const d = new Date(date);
    if (isNaN(d.getTime())) return 'Date invalide';
    return format(d, fmt, { locale: fr });
  } catch {
    return 'Date invalide';
  }
};

/* ═══════════════════════ main component ═══════════════════════ */
const Archive: React.FC = () => {
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  const { repairs, getClientById, getDeviceById, updateRepair } = useAppStore();

  const archivedRepairs = useMemo(() => repairs.filter(r => r.status === 'returned'), [repairs]);

  const [searchQuery, setSearchQuery] = useState('');
  const [deviceTypeFilter, setDeviceTypeFilter] = useState('all');
  const [dateFilter, setDateFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  const [invoiceOpen, setInvoiceOpen] = useState(false);
  const [selectedRepairForInvoice, setSelectedRepairForInvoice] = useState<Repair | null>(null);
  const [snack, setSnack] = useState<{ open: boolean; msg: string; sev: 'success' | 'error' | 'info' }>({ open: false, msg: '', sev: 'info' });

  /* ── filtered ── */
  const filteredRepairs = useMemo(() => {
    let list = archivedRepairs;

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      list = list.filter(r => {
        const client = getClientById(r.clientId);
        const device = r.deviceId ? getDeviceById(r.deviceId) : null;
        return (
          client?.firstName?.toLowerCase().includes(q) ||
          client?.lastName?.toLowerCase().includes(q) ||
          client?.email?.toLowerCase().includes(q) ||
          device?.brand?.toLowerCase().includes(q) ||
          device?.model?.toLowerCase().includes(q) ||
          r.description?.toLowerCase().includes(q) ||
          r.issue?.toLowerCase().includes(q)
        );
      });
    }

    if (deviceTypeFilter !== 'all') {
      list = list.filter(r => {
        const device = r.deviceId ? getDeviceById(r.deviceId) : null;
        return device?.type === deviceTypeFilter;
      });
    }

    if (dateFilter !== 'all') {
      const now = Date.now();
      const ms: Record<string, number> = { '30days': 30 * 864e5, '90days': 90 * 864e5, '1year': 365 * 864e5 };
      const cutoff = now - (ms[dateFilter] || 0);
      list = list.filter(r => new Date(r.updatedAt || r.createdAt).getTime() >= cutoff);
    }

    return list;
  }, [archivedRepairs, searchQuery, deviceTypeFilter, dateFilter, getClientById, getDeviceById]);

  /* ── stats ── */
  const totalAmount = useMemo(() => archivedRepairs.reduce((s, r) => s + (r.totalPrice || 0), 0), [archivedRepairs]);
  const paidCount = useMemo(() => archivedRepairs.filter(r => r.isPaid).length, [archivedRepairs]);
  const unpaidCount = archivedRepairs.length - paidCount;

  /* ── pagination ── */
  const totalPages = Math.ceil(filteredRepairs.length / itemsPerPage);
  const paginatedRepairs = filteredRepairs.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  /* ── actions ── */
  const handleOpenInvoice = async (repair: Repair) => {
    try {
      const result = await repairService.getById(repair.id);
      if (result.success && 'data' in result && result.data) {
        setSelectedRepairForInvoice(result.data);
      } else {
        setSelectedRepairForInvoice(repair);
      }
    } catch {
      setSelectedRepairForInvoice(repair);
    }
    setInvoiceOpen(true);
  };

  const handleRestoreRepair = async (repair: Repair) => {
    await updateRepair(repair.id, { status: 'completed' });
    setSnack({ open: true, msg: 'Réparation restaurée dans le suivi', sev: 'success' });
  };

  const handleTogglePayment = async (repair: Repair, e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      const newStatus = !repair.isPaid;
      const result = await repairService.updatePaymentStatus(repair.id, newStatus);
      if (result.success) {
        await updateRepair(repair.id, { isPaid: newStatus });
        setSnack({ open: true, msg: newStatus ? 'Paiement validé' : 'Validation du paiement annulée', sev: 'success' });
      } else {
        setSnack({ open: true, msg: 'Erreur lors de la mise à jour du paiement', sev: 'error' });
      }
    } catch {
      setSnack({ open: true, msg: 'Erreur lors de la mise à jour du paiement', sev: 'error' });
    }
  };

  const clearFilters = () => { setSearchQuery(''); setDeviceTypeFilter('all'); setDateFilter('all'); setCurrentPage(1); };
  const hasFilters = searchQuery || deviceTypeFilter !== 'all' || dateFilter !== 'all';

  /* ════════════════════════ render ════════════════════════ */
  return (
    <Box sx={{ pb: 4 }}>
      {/* ── header ── */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.01em' }}>
          Archives des Réparations
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
          Historique des réparations restituées
        </Typography>
      </Box>

      {/* ── KPIs ── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<InventoryIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total archivées" value={archivedRepairs.length} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<MoneyIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Montant total" value={formatFromEUR(totalAmount, currency)} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<PaidIcon sx={{ fontSize: 20 }} />} iconColor="#3b82f6" label="Payées" value={paidCount} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<UnpaidIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="Non payées" value={unpaidCount} />
        </Grid>
      </Grid>

      {/* ── search + filters ── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 1.5, p: '16px !important' }}>
          {/* row 1: search + device chips */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
            <TextField size="small" placeholder="Rechercher client, appareil, description..."
              value={searchQuery} onChange={e => { setSearchQuery(e.target.value); setCurrentPage(1); }}
              sx={{ minWidth: 280, ...INPUT_SX }}
              InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 20, color: 'text.disabled' }} /></InputAdornment> }} />
            <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
              {DEVICE_CHIPS.map(f => {
                const active = deviceTypeFilter === f.key;
                return (
                  <Chip key={f.key} label={f.label} size="small"
                    onClick={() => { setDeviceTypeFilter(f.key); setCurrentPage(1); }}
                    sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                      bgcolor: active ? alpha('#6366f1', 0.12) : 'transparent',
                      color: active ? '#6366f1' : 'text.secondary',
                      border: `1px solid ${active ? '#6366f1' : 'rgba(0,0,0,0.08)'}`,
                      '&:hover': { bgcolor: alpha('#6366f1', 0.08) },
                    }} />
                );
              })}
            </Box>
          </Box>
          {/* row 2: date chips */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600, mr: 0.5 }}>Période :</Typography>
            {DATE_CHIPS.map(f => {
              const active = dateFilter === f.key;
              return (
                <Chip key={f.key} label={f.label} size="small"
                  onClick={() => { setDateFilter(f.key); setCurrentPage(1); }}
                  sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                    bgcolor: active ? alpha('#8b5cf6', 0.12) : 'transparent',
                    color: active ? '#8b5cf6' : 'text.secondary',
                    border: `1px solid ${active ? '#8b5cf6' : 'rgba(0,0,0,0.08)'}`,
                    '&:hover': { bgcolor: alpha('#8b5cf6', 0.08) },
                  }} />
              );
            })}
          </Box>
        </CardContent>
      </Card>

      {/* ── table / empty ── */}
      {filteredRepairs.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 10 }}>
          <Box sx={{ width: 80, height: 80, borderRadius: '20px', mx: 'auto', mb: 3, display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, #6366f1, ${alpha('#6366f1', 0.7)})`,
            boxShadow: `0 8px 24px ${alpha('#6366f1', 0.3)}` }}>
            <ArchiveIcon sx={{ fontSize: 36, color: '#fff' }} />
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
            {hasFilters ? 'Aucune réparation trouvée' : 'Aucune réparation archivée'}
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3, maxWidth: 420, mx: 'auto' }}>
            {hasFilters
              ? 'Essayez de modifier vos critères de recherche.'
              : 'Les réparations apparaîtront ici automatiquement quand elles seront restituées.'}
          </Typography>
          {hasFilters && (
            <Chip label="Effacer les filtres" size="small" onClick={clearFilters}
              sx={{ fontWeight: 600, borderRadius: '8px', bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }} />
          )}
        </Box>
      ) : (
        <Card sx={CARD_STATIC}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow sx={TABLE_HEAD_SX}>
                  <TableCell>Client</TableCell>
                  <TableCell>Appareil</TableCell>
                  <TableCell>Description</TableCell>
                  <TableCell>Date restitution</TableCell>
                  <TableCell align="right">Prix</TableCell>
                  <TableCell>Paiement</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedRepairs.map(repair => {
                  const client = getClientById(repair.clientId);
                  const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                  const devColor = deviceTypeColors[device?.type as keyof typeof deviceTypeColors] || '#6b7280';

                  return (
                    <TableRow key={repair.id} hover sx={{ '&:last-child td': { border: 0 } }}>
                      {/* client */}
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                          <Avatar sx={{ width: 34, height: 34, bgcolor: alpha('#6366f1', 0.10), color: '#6366f1', fontSize: '0.85rem', fontWeight: 700 }}>
                            {client ? `${(client.firstName?.[0] || '').toUpperCase()}${(client.lastName?.[0] || '').toUpperCase()}` : '?'}
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle2" sx={{ fontWeight: 600, lineHeight: 1.3 }}>
                              {client ? `${client.firstName} ${client.lastName}` : 'Client inconnu'}
                            </Typography>
                            {client?.email && (
                              <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.7rem' }}>
                                {client.email}
                              </Typography>
                            )}
                          </Box>
                        </Box>
                      </TableCell>

                      {/* device */}
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Box sx={{ width: 30, height: 30, borderRadius: '8px', display: 'flex',
                            alignItems: 'center', justifyContent: 'center',
                            bgcolor: alpha(devColor, 0.10), color: devColor }}>
                            {getDeviceTypeIcon(device?.type || 'other')}
                          </Box>
                          <Box>
                            <Typography variant="subtitle2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>
                              {device ? `${device.brand} ${device.model}` : 'Inconnu'}
                            </Typography>
                            <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: '0.68rem' }}>
                              {device?.type || 'Type inconnu'}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>

                      {/* description */}
                      <TableCell>
                        <Typography variant="body2" noWrap sx={{ maxWidth: 200, fontSize: '0.82rem' }}>
                          {repair.description || 'Aucune description'}
                        </Typography>
                        {repair.issue && (
                          <Typography variant="caption" sx={{ color: 'text.disabled', display: 'block' }} noWrap>
                            {repair.issue}
                          </Typography>
                        )}
                      </TableCell>

                      {/* date */}
                      <TableCell>
                        <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>
                          {safeFormatDate(repair.updatedAt || repair.createdAt, 'dd MMM yyyy')}
                        </Typography>
                      </TableCell>

                      {/* price */}
                      <TableCell align="right">
                        <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
                          {formatFromEUR(repair.totalPrice || 0, currency)}
                        </Typography>
                      </TableCell>

                      {/* payment status */}
                      <TableCell>
                        <Chip
                          icon={repair.isPaid ? <CheckCircleIcon sx={{ fontSize: 14 }} /> : <CheckCircleOutlineIcon sx={{ fontSize: 14 }} />}
                          label={repair.isPaid ? 'Payé' : 'Non payé'}
                          size="small"
                          sx={{ fontWeight: 600, fontSize: '0.72rem', borderRadius: '8px',
                            bgcolor: alpha(repair.isPaid ? '#22c55e' : '#f59e0b', 0.10),
                            color: repair.isPaid ? '#22c55e' : '#f59e0b',
                            '& .MuiChip-icon': { color: repair.isPaid ? '#22c55e' : '#f59e0b' },
                          }}
                        />
                      </TableCell>

                      {/* actions */}
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', justifyContent: 'center', gap: 0.5 }}>
                          <Tooltip title="Voir la facture" arrow>
                            <IconButton size="small" onClick={() => handleOpenInvoice(repair)}
                              sx={{ bgcolor: alpha('#3b82f6', 0.08), color: '#3b82f6', '&:hover': { bgcolor: alpha('#3b82f6', 0.16) } }}>
                              <ReceiptIcon sx={{ fontSize: 18 }} />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title={repair.isPaid ? 'Annuler le paiement' : 'Valider le paiement'} arrow>
                            <IconButton size="small" onClick={e => handleTogglePayment(repair, e)}
                              onMouseDown={e => e.stopPropagation()} onTouchStart={e => e.stopPropagation()}
                              sx={{ bgcolor: alpha(repair.isPaid ? '#22c55e' : '#f59e0b', 0.08),
                                color: repair.isPaid ? '#22c55e' : '#f59e0b',
                                '&:hover': { bgcolor: alpha(repair.isPaid ? '#22c55e' : '#f59e0b', 0.16) } }}>
                              {repair.isPaid ? <CheckCircleIcon sx={{ fontSize: 18 }} /> : <CheckCircleOutlineIcon sx={{ fontSize: 18 }} />}
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Restaurer" arrow>
                            <IconButton size="small" onClick={() => handleRestoreRepair(repair)}
                              sx={{ bgcolor: alpha('#8b5cf6', 0.08), color: '#8b5cf6', '&:hover': { bgcolor: alpha('#8b5cf6', 0.16) } }}>
                              <RestoreIcon sx={{ fontSize: 18 }} />
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
        </Card>
      )}

      {/* ── pagination ── */}
      {totalPages > 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 3 }}>
          <Pagination count={totalPages} page={currentPage} onChange={(_, p) => setCurrentPage(p)}
            sx={{ '& .MuiPaginationItem-root': { borderRadius: '10px', fontWeight: 600 },
              '& .Mui-selected': { bgcolor: '#6366f1 !important', color: '#fff' } }} />
        </Box>
      )}

      {/* ── footer count ── */}
      {filteredRepairs.length > 0 && (
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mt: 2, px: 1 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
            {filteredRepairs.length} réparation{filteredRepairs.length > 1 ? 's' : ''}
            {hasFilters && ` sur ${archivedRepairs.length}`}
          </Typography>
          {hasFilters && (
            <Chip label="Effacer les filtres" size="small" onClick={clearFilters}
              sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.7rem',
                bgcolor: alpha('#6366f1', 0.08), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }} />
          )}
        </Box>
      )}

      {/* ── invoice modal ── */}
      {selectedRepairForInvoice && (
        <Invoice open={invoiceOpen}
          onClose={() => { setInvoiceOpen(false); setSelectedRepairForInvoice(null); }}
          repair={selectedRepairForInvoice}
          client={getClientById(selectedRepairForInvoice.clientId)} />
      )}

      {/* ── snackbar ── */}
      <Snackbar open={snack.open} autoHideDuration={3000} onClose={() => setSnack(s => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        <Alert severity={snack.sev} variant="filled" sx={{ borderRadius: '10px', fontWeight: 600 }}
          onClose={() => setSnack(s => ({ ...s, open: false }))}>
          {snack.msg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Archive;

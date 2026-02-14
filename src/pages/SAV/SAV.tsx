import React, { useState, useEffect, useMemo } from 'react';
import {
  Box,
  Typography,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Grid,
  Card,
  CardContent,
  ToggleButtonGroup,
  ToggleButton,
  IconButton,
  Tooltip,
  Button,
  alpha,
} from '@mui/material';
import {
  Search as SearchIcon,
  ViewKanban as KanbanIcon,
  ViewList as ListIcon,
  Refresh as RefreshIcon,
  Timer as TimerIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Build as BuildIcon,
  Add as AddIcon,
  ErrorOutline as OverdueIcon,
} from '@mui/icons-material';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';
import { useAppStore } from '../../store';
import { savService } from '../../services/savService';
import { Repair } from '../../types';
import RepairCard from '../../components/SAV/RepairCard';
import RepairDetailsDialog from '../../components/SAV/RepairDetailsDialog';
import QuickActions from '../../components/SAV/QuickActions';
import NewRepairDialog from '../../components/SAV/NewRepairDialog';
import { printTemplatesService } from '../../components/SAV/PrintTemplates';
import { repairService } from '../../services/supabaseService';
import toast from 'react-hot-toast';
import ThermalReceiptDialog from '../../components/ThermalReceiptDialog';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';

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
const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

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
const getDisplayStatusName = (statusName: string): string => {
  const name = statusName.toLowerCase();
  if (name.includes('new') || name.includes('nouvelle')) return 'Prise en charge';
  return statusName;
};

const URGENCY_CHIPS: { key: string; label: string }[] = [
  { key: 'all', label: 'Toutes' },
  { key: 'urgent', label: 'Urgentes' },
  { key: 'normal', label: 'Normales' },
];

/* ═══════════════════════ main component ═══════════════════════ */
const SAV: React.FC = () => {
  const {
    repairs, repairStatuses, clients, devices, users, parts, services,
    getClientById, getDeviceById, getUserById,
    updateRepair, updateRepairPaymentStatus, loadRepairs, systemSettings,
  } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();

  const [searchQuery, setSearchQuery] = useState('');
  const [filterTechnician, setFilterTechnician] = useState<string>('all');
  const [filterUrgent, setFilterUrgent] = useState<string>('all');
  const [viewMode, setViewMode] = useState<'kanban' | 'list'>('kanban');
  const [selectedRepair, setSelectedRepair] = useState<Repair | null>(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [newRepairDialogOpen, setNewRepairDialogOpen] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);
  const [thermalReceiptDialogOpen, setThermalReceiptDialogOpen] = useState(false);
  const [thermalReceiptRepair, setThermalReceiptRepair] = useState<Repair | null>(null);

  /* ── stats ── */
  const stats = useMemo(() => savService.calculateStats(repairs, repairStatuses), [repairs, repairStatuses, refreshKey]);

  useEffect(() => {
    const id = setInterval(() => setRefreshKey(p => p + 1), 30000);
    return () => clearInterval(id);
  }, []);

  /* ── filtered repairs ── */
  const filteredRepairs = useMemo(() => {
    return repairs.filter(repair => {
      if (repair.source !== 'sav') return false;
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        const client = getClientById(repair.clientId);
        const device = getDeviceById(repair.deviceId);
        const match =
          (repair.repairNumber?.toLowerCase() || '').includes(q) ||
          (client ? `${client.firstName} ${client.lastName}`.toLowerCase() : '').includes(q) ||
          (device ? `${device.brand} ${device.model}`.toLowerCase() : '').includes(q) ||
          repair.description.toLowerCase().includes(q);
        if (!match) return false;
      }
      if (filterTechnician !== 'all' && repair.assignedTechnicianId !== filterTechnician) return false;
      if (filterUrgent === 'urgent' && !repair.isUrgent) return false;
      if (filterUrgent === 'normal' && repair.isUrgent) return false;
      return true;
    });
  }, [repairs, searchQuery, filterTechnician, filterUrgent, getClientById, getDeviceById, refreshKey]);

  /* ── grouped by status ── */
  const repairsByStatus = useMemo(() => {
    const grouped: Record<string, Repair[]> = {};
    repairStatuses.forEach(s => { grouped[s.id] = filteredRepairs.filter(r => r.status === s.id); });
    return grouped;
  }, [filteredRepairs, repairStatuses]);

  /* ── drag & drop ── */
  const handleDragEnd = async (result: DropResult) => {
    const { source, destination, draggableId } = result;
    if (!destination || (source.droppableId === destination.droppableId && source.index === destination.index)) return;
    const repair = repairs.find(r => r.id === draggableId);
    if (!repair) return;
    try {
      await updateRepair(repair.id, { status: destination.droppableId });
      toast.success('Statut mis à jour');
      await loadRepairs();
      const user = users.find(u => u.id === repair.assignedTechnicianId);
      savService.createLog(repair.id, 'status_change', user?.id || 'system',
        user ? `${user.firstName} ${user.lastName}` : 'Système',
        `Statut changé vers: ${repairStatuses.find(s => s.id === destination.droppableId)?.name}`);
    } catch {
      toast.error('Erreur lors de la mise à jour du statut');
    }
  };

  /* ── actions ── */
  const handleAddNote = async (repair: Repair, note: string) => {
    const updatedNotes = repair.notes ? `${repair.notes}\n\n[${new Date().toLocaleString('fr-FR')}] ${note}` : note;
    try {
      await updateRepair(repair.id, { notes: updatedNotes });
      toast.success('Note ajoutée');
      await loadRepairs();
    } catch {
      toast.error("Erreur lors de l'ajout de la note");
    }
  };

  const handlePrint = (repair: Repair, type: 'label' | 'work_order' | 'deposit_receipt' | 'invoice' | 'complete_ticket') => {
    const client = getClientById(repair.clientId);
    const device = getDeviceById(repair.deviceId);
    const technician = repair.assignedTechnicianId ? getUserById(repair.assignedTechnicianId) : null;
    if (!client) { toast.error('Client introuvable'); return; }
    const workshopInfo = {
      name: systemSettings.find(s => s.key === 'workshop.name')?.value || 'Mon Atelier',
      address: systemSettings.find(s => s.key === 'workshop.address')?.value || '',
      phone: systemSettings.find(s => s.key === 'workshop.phone')?.value || '',
      email: systemSettings.find(s => s.key === 'workshop.email')?.value || '',
    };
    printTemplatesService.print({ type, data: { repair, client, device, technician: technician || undefined, workshopInfo } });
    toast.success('Document généré');
  };

  const handleOpenThermalReceipt = (repair: Repair) => { setThermalReceiptRepair(repair); setThermalReceiptDialogOpen(true); };
  const handleViewDetails = (repair: Repair) => { setSelectedRepair(repair); setDetailsOpen(true); };

  const handleRefresh = async () => {
    try { await loadRepairs(); toast.success('Données actualisées'); } catch { toast.error("Erreur lors de l'actualisation"); }
  };

  const handlePaymentStatusChange = async (repair: Repair, isPaid: boolean) => {
    try {
      await updateRepairPaymentStatus(repair.id, isPaid);
      toast.success(`Paiement : ${isPaid ? 'Payé' : 'Non payé'}`);
    } catch {
      toast.success(`Paiement mis à jour localement : ${isPaid ? 'Payé' : 'Non payé'}`);
    }
  };

  const handleCreateRepair = async (repair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'>) => {
    try {
      await repairService.create(repair, 'sav');
      toast.success(`Prise en charge ${repair.repairNumber} créée`);
      await loadRepairs();
      setNewRepairDialogOpen(false);
    } catch (error: any) {
      toast.error(error.message || 'Erreur lors de la création');
      throw error;
    }
  };

  const clearFilters = () => { setSearchQuery(''); setFilterTechnician('all'); setFilterUrgent('all'); };
  const hasFilters = searchQuery || filterTechnician !== 'all' || filterUrgent !== 'all';

  /* ════════════════════════ render ════════════════════════ */
  return (
    <Box sx={{ pb: 4 }}>
      {/* ── header ── */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.01em' }}>
            SAV Réparateur
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gestion des réparations et service après-vente
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center' }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewRepairDialogOpen(true)}
            sx={{ ...BTN_DARK, px: 3, py: 1.2, bgcolor: '#22c55e', '&:hover': { bgcolor: '#16a34a' },
              boxShadow: `0 2px 8px ${alpha('#22c55e', 0.35)}` }}>
            Nouvelle prise en charge
          </Button>
          <ToggleButtonGroup value={viewMode} exclusive onChange={(_, v) => v && setViewMode(v)} size="small"
            sx={{ '& .MuiToggleButton-root': { borderRadius: '10px !important', textTransform: 'none', fontWeight: 600,
              px: 2, border: '1px solid rgba(0,0,0,0.08) !important' },
              '& .Mui-selected': { bgcolor: alpha('#6366f1', 0.10) + ' !important', color: '#6366f1 !important' },
              gap: 0.5, '& .MuiToggleButtonGroup-grouped:not(:first-of-type)': { borderLeft: '1px solid rgba(0,0,0,0.08) !important' },
            }}>
            <ToggleButton value="kanban"><KanbanIcon sx={{ mr: 0.75, fontSize: 18 }} /> Kanban</ToggleButton>
            <ToggleButton value="list"><ListIcon sx={{ mr: 0.75, fontSize: 18 }} /> Liste</ToggleButton>
          </ToggleButtonGroup>
          <Tooltip title="Rafraîchir" arrow>
            <IconButton onClick={handleRefresh}
              sx={{ bgcolor: alpha('#6366f1', 0.08), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.16) } }}>
              <RefreshIcon sx={{ fontSize: 20 }} />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* ── KPIs ── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<BuildIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total réparations" value={stats.totalRepairs} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<TimerIcon sx={{ fontSize: 20 }} />} iconColor="#3b82f6" label="En cours" value={stats.inProgressRepairs} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<WarningIcon sx={{ fontSize: 20 }} />} iconColor="#ef4444" label="Urgentes" value={stats.urgentRepairs} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<CheckCircleIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Terminées" value={stats.completedRepairs} />
        </Grid>
      </Grid>

      {/* ── overdue alert ── */}
      {stats.overdueRepairs > 0 && (
        <Card sx={{ ...CARD_STATIC, mb: 3, bgcolor: alpha('#ef4444', 0.04), borderColor: alpha('#ef4444', 0.15) }}>
          <CardContent sx={{ p: '12px 16px !important', display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
              bgcolor: alpha('#ef4444', 0.10), color: '#ef4444', flexShrink: 0 }}>
              <OverdueIcon sx={{ fontSize: 18 }} />
            </Box>
            <Typography variant="body2" sx={{ fontWeight: 600, color: '#ef4444' }}>
              <strong>{stats.overdueRepairs}</strong> réparation{stats.overdueRepairs > 1 ? 's' : ''} en retard
            </Typography>
          </CardContent>
        </Card>
      )}

      {/* ── search + filters ── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap', p: '16px !important' }}>
          <TextField size="small" placeholder="Rechercher client, appareil, numéro..."
            value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
            sx={{ minWidth: 260, ...INPUT_SX }}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 20, color: 'text.disabled' }} /></InputAdornment> }} />

          <FormControl size="small" sx={{ minWidth: 180, ...INPUT_SX }}>
            <InputLabel>Technicien</InputLabel>
            <Select value={filterTechnician} label="Technicien" onChange={e => setFilterTechnician(e.target.value)}>
              <MenuItem value="all">Tous les techniciens</MenuItem>
              {users.map(u => (
                <MenuItem key={u.id} value={u.id}>{u.firstName} {u.lastName}</MenuItem>
              ))}
            </Select>
          </FormControl>

          <Box sx={{ display: 'flex', gap: 0.75 }}>
            {URGENCY_CHIPS.map(f => {
              const active = filterUrgent === f.key;
              const col = f.key === 'urgent' ? '#ef4444' : f.key === 'normal' ? '#3b82f6' : '#6366f1';
              return (
                <Chip key={f.key} label={f.label} size="small"
                  onClick={() => setFilterUrgent(f.key)}
                  sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem',
                    bgcolor: active ? alpha(col, 0.12) : 'transparent',
                    color: active ? col : 'text.secondary',
                    border: `1px solid ${active ? col : 'rgba(0,0,0,0.08)'}`,
                    '&:hover': { bgcolor: alpha(col, 0.08) },
                  }} />
              );
            })}
          </Box>

          <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600, ml: 'auto' }}>
            {filteredRepairs.length} résultat{filteredRepairs.length > 1 ? 's' : ''}
          </Typography>
        </CardContent>
      </Card>

      {/* ═══ Kanban view ═══ */}
      {viewMode === 'kanban' && (
        <DragDropContext onDragEnd={handleDragEnd}>
          <Box sx={{
            display: 'flex', gap: 2, overflowX: 'auto', pb: 2,
            '&::-webkit-scrollbar': { height: 6 },
            '&::-webkit-scrollbar-track': { background: 'transparent' },
            '&::-webkit-scrollbar-thumb': { background: '#cbd5e1', borderRadius: 3 },
            '&::-webkit-scrollbar-thumb:hover': { background: '#94a3b8' },
          }}>
            {repairStatuses.map(status => {
              const columnRepairs = repairsByStatus[status.id] || [];
              const overdueCount = columnRepairs.filter(r => {
                if (r.status === 'completed' || r.status === 'returned') return false;
                if (!r.dueDate) return false;
                try { const d = new Date(r.dueDate); return !isNaN(d.getTime()) && d < new Date(); } catch { return false; }
              }).length;

              return (
                <Box key={status.id} sx={{ minWidth: 320, maxWidth: 320, flexShrink: 0 }}>
                  <Box sx={{
                    height: '100%', backgroundColor: '#f8fafc', borderRadius: 3,
                    border: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column',
                    overflow: 'hidden', transition: 'box-shadow 0.2s ease',
                    '&:hover': { boxShadow: '0 4px 20px rgba(0,0,0,0.06)' },
                  }}>
                    {/* column header */}
                    <Box sx={{
                      p: 2, pb: 1.5,
                      background: `linear-gradient(135deg, ${status.color}0A, ${status.color}05)`,
                      borderBottom: '1px solid #e2e8f0',
                    }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                          <Box sx={{
                            width: 10, height: 10, borderRadius: '50%',
                            backgroundColor: status.color,
                            boxShadow: `0 0 8px ${status.color}60`,
                          }} />
                          <Typography variant="subtitle1" sx={{ fontWeight: 700, color: '#1e293b', fontSize: '0.9rem' }}>
                            {getDisplayStatusName(status.name)}
                          </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {overdueCount > 0 && (
                            <Chip label={overdueCount} size="small"
                              sx={{
                                height: 22, minWidth: 22,
                                backgroundColor: '#fef2f2', color: '#dc2626',
                                fontWeight: 700, fontSize: '0.72rem',
                                '& .MuiChip-label': { px: 0.75 },
                              }} />
                          )}
                          <Box sx={{
                            backgroundColor: `${status.color}18`, color: status.color,
                            fontWeight: 700, fontSize: '0.78rem',
                            borderRadius: 1.5, px: 1, py: 0.25,
                            minWidth: 24, textAlign: 'center',
                          }}>
                            {columnRepairs.length}
                          </Box>
                        </Box>
                      </Box>
                    </Box>

                    {/* droppable area */}
                    <Droppable droppableId={status.id}>
                      {(provided, snapshot) => (
                        <Box ref={provided.innerRef} {...provided.droppableProps}
                          sx={{
                            flexGrow: 1, minHeight: 200, p: 1.5,
                            overflowY: 'auto',
                            transition: 'background-color 0.2s ease',
                            backgroundColor: snapshot.isDraggingOver ? `${status.color}08` : 'transparent',
                            '&::-webkit-scrollbar': { width: 4 },
                            '&::-webkit-scrollbar-track': { background: 'transparent' },
                            '&::-webkit-scrollbar-thumb': { background: '#cbd5e1', borderRadius: 2 },
                            '&::-webkit-scrollbar-thumb:hover': { background: '#94a3b8' },
                          }}>
                          {columnRepairs.map((repair, index) => {
                            const client = getClientById(repair.clientId);
                            const device = getDeviceById(repair.deviceId);
                            const technician = repair.assignedTechnicianId ? getUserById(repair.assignedTechnicianId) : null;
                            if (!client) return null;
                            return (
                              <Draggable key={repair.id} draggableId={repair.id} index={index}>
                                {(provided, snapshot) => (
                                  <Box ref={provided.innerRef} {...provided.draggableProps} {...provided.dragHandleProps}
                                    sx={{
                                      opacity: snapshot.isDragging ? 0.85 : 1,
                                      transform: snapshot.isDragging ? 'rotate(1.5deg)' : 'none',
                                    }}>
                                    <RepairCard
                                      repair={repair} client={client} device={device}
                                      technician={technician} repairStatus={status}
                                      onViewDetails={handleViewDetails}
                                      onPrint={(r, t) => handlePrint(r, t)}
                                      onPrintCompleteTicket={r => handlePrint(r, 'complete_ticket')}
                                      onPaymentStatusChange={handlePaymentStatusChange}
                                      onThermalReceipt={handleOpenThermalReceipt}
                                    />
                                  </Box>
                                )}
                              </Draggable>
                            );
                          })}
                          {provided.placeholder}

                          {/* empty column state */}
                          {columnRepairs.length === 0 && (
                            <Box sx={{ textAlign: 'center', py: 6, opacity: 0.4 }}>
                              <BuildIcon sx={{ fontSize: 32, color: 'text.disabled', mb: 1 }} />
                              <Typography variant="caption" sx={{ color: 'text.disabled', display: 'block' }}>
                                Aucune réparation
                              </Typography>
                            </Box>
                          )}
                        </Box>
                      )}
                    </Droppable>

                    {/* dashed add button */}
                    <Box sx={{ p: 1.5, pt: 0 }}>
                      <Button startIcon={<AddIcon />} size="small" fullWidth
                        onClick={() => setNewRepairDialogOpen(true)}
                        sx={{
                          color: '#64748b', borderRadius: 2,
                          border: '1.5px dashed #cbd5e1',
                          backgroundColor: 'transparent',
                          fontSize: '0.8rem', fontWeight: 600, py: 0.75,
                          textTransform: 'none',
                          '&:hover': { backgroundColor: '#f1f5f9', borderColor: '#94a3b8', color: '#475569' },
                        }}>
                        Nouvelle prise en charge
                      </Button>
                    </Box>
                  </Box>
                </Box>
              );
            })}
          </Box>
        </DragDropContext>
      )}

      {/* ═══ List view ═══ */}
      {viewMode === 'list' && (
        <Box>
          {filteredRepairs.length === 0 ? (
            <Box sx={{ textAlign: 'center', py: 10 }}>
              <Box sx={{ width: 80, height: 80, borderRadius: '20px', mx: 'auto', mb: 3, display: 'flex',
                alignItems: 'center', justifyContent: 'center',
                background: `linear-gradient(135deg, #6366f1, ${alpha('#6366f1', 0.7)})`,
                boxShadow: `0 8px 24px ${alpha('#6366f1', 0.3)}` }}>
                <BuildIcon sx={{ fontSize: 36, color: '#fff' }} />
              </Box>
              <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
                {hasFilters ? 'Aucune réparation trouvée' : 'Aucune réparation'}
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3, maxWidth: 400, mx: 'auto' }}>
                {hasFilters
                  ? 'Essayez de modifier vos critères de recherche.'
                  : 'Créez votre première prise en charge pour commencer.'}
              </Typography>
              {hasFilters ? (
                <Chip label="Effacer les filtres" size="small" onClick={clearFilters}
                  sx={{ fontWeight: 600, borderRadius: '8px', bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }} />
              ) : (
                <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewRepairDialogOpen(true)}
                  sx={{ ...BTN_DARK, px: 3, bgcolor: '#22c55e', '&:hover': { bgcolor: '#16a34a' },
                    boxShadow: `0 2px 8px ${alpha('#22c55e', 0.35)}` }}>
                  Nouvelle prise en charge
                </Button>
              )}
            </Box>
          ) : (
            filteredRepairs.map(repair => {
              const client = getClientById(repair.clientId);
              const device = getDeviceById(repair.deviceId);
              const technician = repair.assignedTechnicianId ? getUserById(repair.assignedTechnicianId) : null;
              const status = repairStatuses.find(s => s.id === repair.status);
              if (!client || !status) return null;
              return (
                <RepairCard key={repair.id} repair={repair} client={client} device={device}
                  technician={technician} repairStatus={status}
                  onViewDetails={handleViewDetails}
                  onPrint={(r, t) => handlePrint(r, t)}
                  onPrintCompleteTicket={r => handlePrint(r, 'complete_ticket')}
                  onPaymentStatusChange={handlePaymentStatusChange}
                  onThermalReceipt={handleOpenThermalReceipt}
                  onClick={() => handleViewDetails(repair)}
                />
              );
            })
          )}
        </Box>
      )}

      {/* ── footer count ── */}
      {filteredRepairs.length > 0 && (
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mt: 2, px: 1 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
            {filteredRepairs.length} réparation{filteredRepairs.length > 1 ? 's' : ''}
          </Typography>
          {hasFilters && (
            <Chip label="Effacer les filtres" size="small" onClick={clearFilters}
              sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.7rem',
                bgcolor: alpha('#6366f1', 0.08), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }} />
          )}
        </Box>
      )}

      {/* ── dialogs ── */}
      {selectedRepair && (
        <RepairDetailsDialog open={detailsOpen}
          onClose={() => { setDetailsOpen(false); setSelectedRepair(null); }}
          repair={selectedRepair}
          client={getClientById(selectedRepair.clientId)!}
          device={getDeviceById(selectedRepair.deviceId)}
          technician={selectedRepair.assignedTechnicianId ? getUserById(selectedRepair.assignedTechnicianId) || null : null}
          parts={parts} services={services} />
      )}

      {selectedRepair && (
        <QuickActions repair={selectedRepair}
          onStatusChange={async (repair, newStatus) => {
            try { await updateRepair(repair.id, { status: newStatus }); toast.success('Statut mis à jour'); await loadRepairs(); }
            catch { toast.error('Erreur lors de la mise à jour du statut'); }
          }}
          onAddNote={handleAddNote}
          onPrintWorkOrder={r => handlePrint(r, 'work_order')}
          onPrintReceipt={r => handlePrint(r, 'deposit_receipt')}
          onGenerateInvoice={r => handlePrint(r, 'invoice')}
          onPrintCompleteTicket={r => handlePrint(r, 'complete_ticket')}
          onPaymentStatusChange={handlePaymentStatusChange} />
      )}

      <NewRepairDialog open={newRepairDialogOpen} onClose={() => setNewRepairDialogOpen(false)}
        clients={clients} devices={devices} users={users} repairStatuses={repairStatuses}
        onSubmit={handleCreateRepair} />

      {thermalReceiptRepair && (
        <ThermalReceiptDialog open={thermalReceiptDialogOpen}
          onClose={() => { setThermalReceiptDialogOpen(false); setThermalReceiptRepair(null); }}
          repair={thermalReceiptRepair}
          client={getClientById(thermalReceiptRepair.clientId)}
          device={thermalReceiptRepair.deviceId ? getDeviceById(thermalReceiptRepair.deviceId) : undefined}
          technician={thermalReceiptRepair.assignedTechnicianId ? getUserById(thermalReceiptRepair.assignedTechnicianId) : undefined}
          workshopInfo={{
            name: workshopSettings?.name || 'Atelier',
            address: workshopSettings?.address, phone: workshopSettings?.phone,
            email: workshopSettings?.email, siret: workshopSettings?.siret, vatNumber: workshopSettings?.vatNumber,
          }} />
      )}
    </Box>
  );
};

export default SAV;

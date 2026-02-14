import React, { useState, useMemo, useRef, useCallback } from 'react';
import {
  Box, Typography, Button, Dialog, DialogContent, DialogActions,
  TextField, FormControl, InputLabel, Select, MenuItem,
  Chip, Grid, Card, CardContent, IconButton, Tooltip,
  ToggleButtonGroup, ToggleButton, alpha, Snackbar, Alert,
} from '@mui/material';
import {
  Add as AddIcon,
  Event as EventIcon,
  CalendarMonth as MonthIcon,
  ViewWeek as WeekIcon,
  Today as DayIcon,
  ViewList as ListIcon,
  Schedule as ScheduleIcon,
  Build as BuildIcon,
  Close as CloseIcon,
  Delete as DeleteIcon,
  Person as PersonIcon,
  Apple as AppleIcon,
  Google as GoogleIcon,
  Download as DownloadIcon,
  CloudSync as CloudSyncIcon,
} from '@mui/icons-material';
import FullCalendar from '@fullcalendar/react';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import listPlugin from '@fullcalendar/list';
import { DateSelectArg, EventClickArg, EventContentArg } from '@fullcalendar/core';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Appointment, Repair } from '../../types';
import { getRepairEligibleUsers, getRepairUserDisplayName } from '../../utils/userUtils';
import { RepairDetailsDialog } from '../../components/SAV/RepairDetailsDialog';
import {
  exportAllToICS,
  exportSingleEventToICS,
  openGoogleCalendarForAppointment,
  openGoogleCalendarForRepair,
} from '../../services/calendarSyncService';

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

const APPOINTMENT_COLOR = '#6366f1';

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

/* ─── SectionLabel ─── */
function SectionLabel({ icon, color, label }: { icon: React.ReactNode; color: string; label: string }) {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2.5 }}>
      <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: `linear-gradient(135deg, ${color}, ${alpha(color, 0.7)})`,
        color: '#fff', boxShadow: `0 4px 14px ${alpha(color, 0.3)}` }}>
        {icon}
      </Box>
      <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: '0.85rem' }}>{label}</Typography>
    </Box>
  );
}

/* ─── FullCalendar premium CSS overrides ─── */
const FC_OVERRIDES = {
  '& .fc': { fontFamily: 'inherit' },
  '& .fc-toolbar': { mb: 2 },
  '& .fc-toolbar-title': { fontSize: '1.1rem !important', fontWeight: '700 !important' },
  '& .fc-button': {
    borderRadius: '8px !important', textTransform: 'capitalize !important',
    fontWeight: '600 !important', fontSize: '0.8rem !important',
    padding: '6px 14px !important', border: 'none !important',
    bgcolor: '#f1f5f9 !important', color: '#475569 !important',
    boxShadow: 'none !important',
    '&:hover': { bgcolor: '#e2e8f0 !important' },
  },
  '& .fc-button-active': {
    bgcolor: '#6366f1 !important', color: '#fff !important',
    '&:hover': { bgcolor: '#4f46e5 !important' },
  },
  '& .fc-button-group': { gap: '4px', '& .fc-button': { borderRadius: '8px !important' } },
  '& .fc-daygrid-day': {
    transition: 'background 0.15s',
    '&:hover': { bgcolor: 'rgba(99,102,241,0.04)' },
  },
  '& .fc-day-today': {
    bgcolor: 'rgba(99,102,241,0.06) !important',
  },
  '& .fc-daygrid-day-number': {
    fontWeight: 600, fontSize: '0.82rem', color: '#334155',
    padding: '8px !important',
  },
  '& .fc-day-today .fc-daygrid-day-number': {
    color: '#6366f1', fontWeight: 700,
  },
  '& .fc-event': {
    borderRadius: '6px !important', border: 'none !important',
    fontSize: '0.72rem !important', fontWeight: '600 !important',
    padding: '2px 6px !important', cursor: 'pointer !important',
    transition: 'transform 0.15s, box-shadow 0.15s',
    '&:hover': { transform: 'translateY(-1px)', boxShadow: '0 4px 12px rgba(0,0,0,0.15)' },
  },
  '& .fc-event-urgent': {
    animation: 'urgentPulse 2s ease-in-out infinite',
  },
  '@keyframes urgentPulse': {
    '0%, 100%': { boxShadow: '0 0 0 0 rgba(239,68,68,0.4)' },
    '50%': { boxShadow: '0 0 0 4px rgba(239,68,68,0)' },
  },
  '& .fc-timegrid-slot': { height: '48px !important' },
  '& .fc-timegrid-slot-label-cushion': { fontSize: '0.72rem', fontWeight: 500, color: '#94a3b8' },
  '& .fc-col-header-cell-cushion': {
    fontWeight: '700 !important', fontSize: '0.78rem !important',
    color: '#475569 !important', textTransform: 'uppercase',
    letterSpacing: '0.03em',
  },
  '& .fc-scrollgrid': { border: 'none !important' },
  '& .fc-scrollgrid td, & .fc-scrollgrid th': { borderColor: '#f1f5f9 !important' },
  '& .fc-list-event:hover td': { bgcolor: 'rgba(99,102,241,0.04) !important' },
  '& .fc-list-day-cushion': { bgcolor: '#f8fafc !important', fontWeight: '700 !important', fontSize: '0.82rem !important' },
} as const;

/* ─── helpers ─── */
const safeDate = (date: any, fmt: string) => {
  try {
    if (!date) return '—';
    const d = new Date(date);
    return isNaN(d.getTime()) ? '—' : format(d, fmt, { locale: fr });
  } catch { return '—'; }
};

/* ═══════════════════════ main component ═══════════════════════ */
const Calendar: React.FC = () => {
  const {
    appointments, repairs, devices, clients, users,
    repairStatuses, parts, services,
    addAppointment, updateAppointment, deleteAppointment,
    getClientById, getUserById,
  } = useAppStore();

  const [openDialog, setOpenDialog] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Appointment | null>(null);
  const [selectedRepair, setSelectedRepair] = useState<Repair | null>(null);
  const [view, setView] = useState<'dayGridMonth' | 'timeGridWeek' | 'timeGridDay' | 'listWeek'>('dayGridMonth');
  const [snack, setSnack] = useState<{ open: boolean; msg: string; sev: 'success' | 'error' }>({ open: false, msg: '', sev: 'success' });
  const calendarRef = useRef<any>(null);

  const emptyForm = {
    title: '', description: '',
    startDate: format(new Date(), "yyyy-MM-dd'T'HH:mm"),
    endDate: format(new Date(Date.now() + 3600000), "yyyy-MM-dd'T'HH:mm"),
    clientId: '', repairId: '', assignedUserId: '',
  };
  const [formData, setFormData] = useState(emptyForm);
  const set = (key: string, val: string) => setFormData(p => ({ ...p, [key]: val }));

  /* ── dynamic repair color map from store ── */
  const repairColorMap = useMemo(() => {
    const map: Record<string, string> = {};
    repairStatuses.forEach(s => { map[s.id] = s.color; });
    return map;
  }, [repairStatuses]);

  /* ── dynamic legend ── */
  const legend = useMemo(() => [
    { label: 'Rendez-vous', color: APPOINTMENT_COLOR },
    ...repairStatuses
      .filter(s => s.id !== 'returned')
      .map(s => ({ label: s.name, color: s.color })),
  ], [repairStatuses]);

  /* ── calendar events ── */
  const calendarEvents = useMemo(() => {
    const events: any[] = [];

    appointments.forEach(a => {
      events.push({
        id: `appointment-${a.id}`, title: a.title,
        start: a.startDate, end: a.endDate,
        backgroundColor: APPOINTMENT_COLOR, borderColor: APPOINTMENT_COLOR, textColor: '#fff',
        extendedProps: { type: 'appointment', appointment: a },
      });
    });

    repairs.forEach(repair => {
      if (repair.status === 'returned') return;
      const device = devices.find(d => d.id === repair.deviceId);
      const client = clients.find(c => c.id === repair.clientId);
      const tech = repair.assignedTechnicianId ? users.find(u => u.id === repair.assignedTechnicianId) : null;
      const getD = (v: any) => v ? (v instanceof Date ? v : new Date(v)) : null;
      const start = getD(repair.estimatedStartDate) || getD(repair.startDate) || getD(repair.createdAt);
      const end = getD(repair.dueDate) || getD(repair.estimatedEndDate) || getD(repair.endDate)
        || (start ? new Date(start.getTime() + 86400000) : new Date());
      const color = repairColorMap[repair.status] || '#9e9e9e';

      const clientName = client ? `${client.firstName} ${client.lastName}` : '';
      const deviceName = device ? `${device.brand} ${device.model}` : '';
      const title = `🔧 ${repair.repairNumber || 'REP'} — ${clientName} — ${deviceName}${repair.isUrgent ? ' 🔴' : ''}`;

      events.push({
        id: `repair-${repair.id}`,
        title,
        start, end, backgroundColor: color, borderColor: color, textColor: '#fff',
        classNames: repair.isUrgent ? ['fc-event-urgent'] : [],
        extendedProps: {
          type: 'repair', repair,
          technicianName: tech ? `${tech.firstName} ${tech.lastName}` : '',
          isUrgent: repair.isUrgent,
        },
      });
    });

    return events;
  }, [appointments, repairs, devices, clients, users, repairColorMap]);

  /* ── stats ── */
  const stats = useMemo(() => {
    const now = new Date();
    const todayStr = format(now, 'yyyy-MM-dd');
    const todayAppts = appointments.filter(a => {
      try { return format(new Date(a.startDate), 'yyyy-MM-dd') === todayStr; } catch { return false; }
    });
    const weekStart = new Date(now); weekStart.setDate(now.getDate() - now.getDay() + 1);
    const weekEnd = new Date(weekStart); weekEnd.setDate(weekStart.getDate() + 7);
    const weekAppts = appointments.filter(a => {
      try { const d = new Date(a.startDate); return d >= weekStart && d < weekEnd; } catch { return false; }
    });
    const repairEvents = repairs.filter(r => r.status !== 'returned').length;
    return { total: appointments.length, today: todayAppts.length, todayList: todayAppts, week: weekAppts.length, repairEvents };
  }, [appointments, repairs]);

  /* ── custom event content ── */
  const renderEventContent = useCallback((eventInfo: EventContentArg) => {
    const ext = eventInfo.event.extendedProps;
    const isRepair = ext.type === 'repair';
    const timeText = eventInfo.timeText;

    return (
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, overflow: 'hidden', width: '100%', py: 0.25 }}>
        {isRepair
          ? <BuildIcon sx={{ fontSize: 12, flexShrink: 0, opacity: 0.9 }} />
          : <EventIcon sx={{ fontSize: 12, flexShrink: 0, opacity: 0.9 }} />
        }
        <Box sx={{ minWidth: 0, flex: 1 }}>
          <Typography component="span" sx={{
            fontSize: '0.68rem', fontWeight: 700, display: 'block',
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            lineHeight: 1.3, color: 'inherit',
          }}>
            {eventInfo.event.title}
          </Typography>
          {timeText && (
            <Typography component="span" sx={{
              fontSize: '0.62rem', opacity: 0.8, display: 'block',
              lineHeight: 1.2, color: 'inherit',
            }}>
              {timeText}
            </Typography>
          )}
        </Box>
        {ext.isUrgent && (
          <Box sx={{
            width: 6, height: 6, borderRadius: '50%', bgcolor: '#fff',
            flexShrink: 0, boxShadow: '0 0 4px rgba(255,255,255,0.8)',
          }} />
        )}
      </Box>
    );
  }, []);

  /* ── handlers ── */
  const handleDateSelect = (info: DateSelectArg) => {
    setSelectedEvent(null);
    setFormData({
      ...emptyForm,
      startDate: format(info.start, "yyyy-MM-dd'T'HH:mm"),
      endDate: format(info.end, "yyyy-MM-dd'T'HH:mm"),
    });
    setOpenDialog(true);
  };

  const handleEventClick = (info: EventClickArg) => {
    const ext = info.event.extendedProps;
    if (ext.type === 'appointment') {
      const a = ext.appointment;
      setSelectedEvent(a);
      setFormData({
        title: a.title, description: a.description || '',
        startDate: format(new Date(a.startDate), "yyyy-MM-dd'T'HH:mm"),
        endDate: format(new Date(a.endDate), "yyyy-MM-dd'T'HH:mm"),
        clientId: a.clientId || '', repairId: a.repairId || '', assignedUserId: a.assignedUserId || '',
      });
      setOpenDialog(true);
    } else if (ext.type === 'repair') {
      setSelectedRepair(ext.repair);
    }
  };

  const handleSubmit = async () => {
    const toNull = (v: string) => v.trim() === '' ? undefined : v;
    try {
      if (selectedEvent) {
        await updateAppointment(selectedEvent.id, {
          ...selectedEvent,
          title: formData.title, description: formData.description,
          startDate: new Date(formData.startDate), endDate: new Date(formData.endDate),
          clientId: toNull(formData.clientId), repairId: toNull(formData.repairId),
          assignedUserId: toNull(formData.assignedUserId),
        });
        setSnack({ open: true, msg: 'Rendez-vous modifié', sev: 'success' });
      } else {
        await addAppointment({
          title: formData.title, description: formData.description,
          startDate: new Date(formData.startDate), endDate: new Date(formData.endDate),
          clientId: toNull(formData.clientId), repairId: toNull(formData.repairId),
          assignedUserId: toNull(formData.assignedUserId),
          status: 'scheduled', createdAt: new Date(), updatedAt: new Date(),
        });
        setSnack({ open: true, msg: 'Rendez-vous créé', sev: 'success' });
      }
      setOpenDialog(false); setSelectedEvent(null); setFormData(emptyForm);
    } catch {
      setSnack({ open: true, msg: 'Erreur lors de la sauvegarde', sev: 'error' });
    }
  };

  const handleDelete = () => {
    if (!selectedEvent) return;
    deleteAppointment(selectedEvent.id);
    setOpenDialog(false); setSelectedEvent(null);
    setSnack({ open: true, msg: 'Rendez-vous supprimé', sev: 'success' });
  };

  const handleViewChange = (_: any, v: string | null) => {
    if (!v) return;
    const newView = v as typeof view;
    setView(newView);
    setTimeout(() => {
      try { calendarRef.current?.getApi()?.changeView(newView); } catch { /* noop */ }
    }, 50);
  };

  const openNewDialog = () => {
    setSelectedEvent(null);
    setFormData(emptyForm);
    setOpenDialog(true);
  };

  /* ── sync handlers ── */
  const handleExportAllICS = () => {
    exportAllToICS(appointments, repairs, clients, devices);
    setSnack({ open: true, msg: 'Fichier .ics téléchargé', sev: 'success' });
  };

  const handleGoogleCalendarSync = () => {
    // Find the next upcoming appointment to open in Google Calendar
    const now = new Date();
    const upcoming = [...appointments]
      .filter(a => new Date(a.startDate) >= now)
      .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime());
    if (upcoming.length > 0) {
      const apt = upcoming[0];
      const client = apt.clientId ? getClientById(apt.clientId) : null;
      openGoogleCalendarForAppointment(apt, client);
    } else {
      setSnack({ open: true, msg: 'Aucun rendez-vous à venir', sev: 'error' });
    }
  };

  const handleExportAppointmentICS = () => {
    if (!selectedEvent) return;
    const client = selectedEvent.clientId ? getClientById(selectedEvent.clientId) : null;
    exportSingleEventToICS({ type: 'appointment', data: selectedEvent, client });
    setSnack({ open: true, msg: 'Fichier .ics téléchargé', sev: 'success' });
  };

  const handleGoogleCalendarAppointment = () => {
    if (!selectedEvent) return;
    const client = selectedEvent.clientId ? getClientById(selectedEvent.clientId) : null;
    openGoogleCalendarForAppointment(selectedEvent, client);
  };

  /* ── RepairDetailsDialog data ── */
  const repairDialogData = useMemo(() => {
    if (!selectedRepair) return null;
    const client = clients.find(c => c.id === selectedRepair.clientId);
    const device = selectedRepair.deviceId ? devices.find(d => d.id === selectedRepair.deviceId) : null;
    const technician = selectedRepair.assignedTechnicianId
      ? users.find(u => u.id === selectedRepair.assignedTechnicianId) : null;
    return {
      client: client || { id: '', firstName: 'Inconnu', lastName: '', email: '', createdAt: new Date(), updatedAt: new Date() },
      device: device || null,
      technician: technician || null,
    };
  }, [selectedRepair, clients, devices, users]);

  /* ════════════════════════ render ════════════════════════ */
  return (
    <Box sx={{ pb: 4 }}>
      {/* ── header ── */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.01em' }}>
            Calendrier
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5, textTransform: 'capitalize' }}>
            {safeDate(new Date(), 'EEEE d MMMM yyyy')}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center' }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={openNewDialog}
            sx={{ ...BTN_DARK, px: 3, py: 1.2, bgcolor: '#6366f1', '&:hover': { bgcolor: '#4f46e5' },
              boxShadow: `0 2px 8px ${alpha('#6366f1', 0.35)}` }}>
            Nouveau rendez-vous
          </Button>
        </Box>
      </Box>

      {/* ── KPIs ── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<EventIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total rendez-vous" value={stats.total} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<ScheduleIcon sx={{ fontSize: 20 }} />} iconColor="#3b82f6" label="Aujourd'hui" value={stats.today} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<EventIcon sx={{ fontSize: 20 }} />} iconColor="#8b5cf6" label="Cette semaine" value={stats.week} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<BuildIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="Réparations" value={stats.repairEvents} />
        </Grid>
      </Grid>

      {/* ── main grid ── */}
      <Grid container spacing={3}>
        {/* ─ calendar ─ */}
        <Grid item xs={12} lg={8}>
          <Card sx={CARD_STATIC}>
            <CardContent sx={{ p: '20px !important' }}>
              {/* view toggle */}
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2.5, flexWrap: 'wrap', gap: 1.5 }}>
                <ToggleButtonGroup value={view} exclusive onChange={handleViewChange} size="small"
                  sx={{
                    '& .MuiToggleButton-root': {
                      borderRadius: '10px !important', textTransform: 'none', fontWeight: 600,
                      px: 2, py: 0.75, fontSize: '0.8rem',
                      border: '1px solid rgba(0,0,0,0.08) !important',
                    },
                    '& .Mui-selected': { bgcolor: alpha('#6366f1', 0.10) + ' !important', color: '#6366f1 !important' },
                    gap: 0.5,
                    '& .MuiToggleButtonGroup-grouped:not(:first-of-type)': { borderLeft: '1px solid rgba(0,0,0,0.08) !important' },
                  }}>
                  <ToggleButton value="dayGridMonth"><MonthIcon sx={{ mr: 0.75, fontSize: 18 }} />Mois</ToggleButton>
                  <ToggleButton value="timeGridWeek"><WeekIcon sx={{ mr: 0.75, fontSize: 18 }} />Semaine</ToggleButton>
                  <ToggleButton value="timeGridDay"><DayIcon sx={{ mr: 0.75, fontSize: 18 }} />Jour</ToggleButton>
                  <ToggleButton value="listWeek"><ListIcon sx={{ mr: 0.75, fontSize: 18 }} />Liste</ToggleButton>
                </ToggleButtonGroup>
              </Box>

              {/* FullCalendar */}
              <Box sx={FC_OVERRIDES}>
                <FullCalendar
                  ref={calendarRef}
                  plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin, listPlugin]}
                  headerToolbar={{ left: 'prev,next today', center: 'title', right: '' }}
                  initialView={view}
                  editable selectable selectMirror dayMaxEvents weekends
                  events={calendarEvents}
                  select={handleDateSelect}
                  eventClick={handleEventClick}
                  eventContent={renderEventContent}
                  height="auto"
                  locale="fr"
                  firstDay={1}
                  slotMinTime="08:00:00"
                  slotMaxTime="20:00:00"
                  allDaySlot={false}
                  buttonText={{ today: "Aujourd'hui", prev: '', next: '' }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* ─ sidebar ─ */}
        <Grid item xs={12} lg={4}>
          {/* today's appointments */}
          <Card sx={{ ...CARD_STATIC, mb: 3 }}>
            <CardContent sx={{ p: '20px !important' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
                <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  background: `linear-gradient(135deg, #3b82f6, ${alpha('#3b82f6', 0.7)})`,
                  color: '#fff', boxShadow: `0 4px 14px ${alpha('#3b82f6', 0.3)}` }}>
                  <ScheduleIcon sx={{ fontSize: 16 }} />
                </Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 700, fontSize: '0.95rem' }}>
                  Aujourd'hui
                </Typography>
                <Chip label={stats.today} size="small"
                  sx={{ height: 22, fontSize: '0.72rem', fontWeight: 700,
                    bgcolor: alpha('#3b82f6', 0.10), color: '#3b82f6', ml: 'auto' }} />
              </Box>

              {stats.todayList.length === 0 ? (
                <Box sx={{ textAlign: 'center', py: 4, opacity: 0.4 }}>
                  <EventIcon sx={{ fontSize: 32, color: 'text.disabled', mb: 1 }} />
                  <Typography variant="caption" sx={{ color: 'text.disabled', display: 'block' }}>
                    Aucun rendez-vous
                  </Typography>
                </Box>
              ) : (
                stats.todayList.map((apt, i) => {
                  const client = apt.clientId ? getClientById(apt.clientId) : null;
                  const user = apt.assignedUserId ? getUserById(apt.assignedUserId) : null;
                  return (
                    <Box key={apt.id}
                      sx={{ display: 'flex', alignItems: 'flex-start', gap: 1.5, py: 1.5,
                        borderBottom: i < stats.todayList.length - 1 ? '1px solid' : 'none', borderColor: 'divider',
                        cursor: 'pointer', borderRadius: '8px', mx: -1, px: 1,
                        transition: 'background 0.15s', '&:hover': { bgcolor: 'rgba(0,0,0,0.02)' },
                      }}
                      onClick={() => {
                        setSelectedEvent(apt);
                        setFormData({
                          title: apt.title, description: apt.description || '',
                          startDate: format(new Date(apt.startDate), "yyyy-MM-dd'T'HH:mm"),
                          endDate: format(new Date(apt.endDate), "yyyy-MM-dd'T'HH:mm"),
                          clientId: apt.clientId || '', repairId: apt.repairId || '', assignedUserId: apt.assignedUserId || '',
                        });
                        setOpenDialog(true);
                      }}>
                      <Box sx={{ width: 4, height: 36, borderRadius: 2, bgcolor: '#6366f1', flexShrink: 0, mt: 0.5 }} />
                      <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.85rem' }} noWrap>
                          {apt.title}
                        </Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mt: 0.25 }}>
                          <Chip label={`${safeDate(apt.startDate, 'HH:mm')} — ${safeDate(apt.endDate, 'HH:mm')}`} size="small"
                            sx={{ height: 20, fontSize: '0.68rem', fontWeight: 600,
                              bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }} />
                        </Box>
                        {client && (
                          <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mt: 0.5 }}>
                            {client.firstName} {client.lastName}
                          </Typography>
                        )}
                        {user && (
                          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                            {user.firstName} {user.lastName}
                          </Typography>
                        )}
                      </Box>
                    </Box>
                  );
                })
              )}
            </CardContent>
          </Card>

          {/* ── sync card ── */}
          <Card sx={{ ...CARD_STATIC, mb: 3 }}>
            <CardContent sx={{ p: '20px !important' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
                <Box sx={{ width: 32, height: 32, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  background: `linear-gradient(135deg, #8b5cf6, ${alpha('#8b5cf6', 0.7)})`,
                  color: '#fff', boxShadow: `0 4px 14px ${alpha('#8b5cf6', 0.3)}` }}>
                  <CloudSyncIcon sx={{ fontSize: 16 }} />
                </Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 700, fontSize: '0.95rem' }}>
                  Synchroniser
                </Typography>
              </Box>

              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Button
                  variant="outlined"
                  startIcon={<GoogleIcon sx={{ fontSize: 18 }} />}
                  onClick={handleGoogleCalendarSync}
                  sx={{
                    borderRadius: '10px', textTransform: 'none', fontWeight: 600,
                    fontSize: '0.8rem', borderColor: 'rgba(0,0,0,0.12)',
                    color: '#334155', justifyContent: 'flex-start', px: 2, py: 1,
                    '&:hover': { borderColor: '#4285f4', color: '#4285f4', bgcolor: alpha('#4285f4', 0.04) },
                  }}>
                  Google Calendar
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<AppleIcon sx={{ fontSize: 18 }} />}
                  onClick={handleExportAllICS}
                  sx={{
                    borderRadius: '10px', textTransform: 'none', fontWeight: 600,
                    fontSize: '0.8rem', borderColor: 'rgba(0,0,0,0.12)',
                    color: '#334155', justifyContent: 'flex-start', px: 2, py: 1,
                    '&:hover': { borderColor: '#111827', color: '#111827', bgcolor: alpha('#111827', 0.04) },
                  }}>
                  Apple Calendar
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<DownloadIcon sx={{ fontSize: 18 }} />}
                  onClick={handleExportAllICS}
                  sx={{
                    borderRadius: '10px', textTransform: 'none', fontWeight: 600,
                    fontSize: '0.8rem', borderColor: 'rgba(0,0,0,0.12)',
                    color: '#334155', justifyContent: 'flex-start', px: 2, py: 1,
                    '&:hover': { borderColor: '#6366f1', color: '#6366f1', bgcolor: alpha('#6366f1', 0.04) },
                  }}>
                  Exporter tout (.ics)
                </Button>
              </Box>
            </CardContent>
          </Card>

          {/* legend */}
          <Card sx={CARD_STATIC}>
            <CardContent sx={{ p: '20px !important' }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 700, fontSize: '0.95rem', mb: 2 }}>
                Légende
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.25 }}>
                {legend.map(l => (
                  <Box key={l.label} sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: l.color,
                      boxShadow: `0 0 6px ${alpha(l.color, 0.5)}`, flexShrink: 0 }} />
                    <Typography variant="body2" sx={{ fontSize: '0.82rem', fontWeight: 500 }}>{l.label}</Typography>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* ═══ appointment dialog ═══ */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth
        PaperProps={{ sx: { borderRadius: '16px', overflow: 'hidden' } }}>
        {/* dark header */}
        <Box sx={{
          background: 'linear-gradient(135deg, #111827, #1e293b)',
          color: '#fff', px: 3, py: 2.5, position: 'relative', overflow: 'hidden',
        }}>
          <Box sx={{ position: 'absolute', top: -20, right: -20, width: 80, height: 80,
            borderRadius: '50%', bgcolor: 'rgba(255,255,255,0.04)' }} />
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box>
              <Typography variant="h6" sx={{ fontWeight: 700, fontSize: '1.05rem' }}>
                {selectedEvent ? 'Modifier le rendez-vous' : 'Nouveau rendez-vous'}
              </Typography>
              <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.6)' }}>
                {selectedEvent ? 'Mettre à jour les informations' : 'Planifier un nouveau créneau'}
              </Typography>
            </Box>
            <IconButton onClick={() => setOpenDialog(false)} sx={{ color: 'rgba(255,255,255,0.6)', '&:hover': { color: '#fff' } }}>
              <CloseIcon sx={{ fontSize: 20 }} />
            </IconButton>
          </Box>
        </Box>

        <DialogContent sx={{ p: 3, pt: 3 }}>
          <SectionLabel icon={<EventIcon sx={{ fontSize: 16 }} />} color="#6366f1" label="Informations" />
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField fullWidth label="Titre" size="small" value={formData.title}
                onChange={e => set('title', e.target.value)} sx={INPUT_SX} />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth multiline rows={2} label="Description" size="small" value={formData.description}
                onChange={e => set('description', e.target.value)} sx={INPUT_SX} />
            </Grid>
            <Grid item xs={6}>
              <TextField fullWidth type="datetime-local" label="Début" size="small" value={formData.startDate}
                onChange={e => set('startDate', e.target.value)} InputLabelProps={{ shrink: true }} sx={INPUT_SX} />
            </Grid>
            <Grid item xs={6}>
              <TextField fullWidth type="datetime-local" label="Fin" size="small" value={formData.endDate}
                onChange={e => set('endDate', e.target.value)} InputLabelProps={{ shrink: true }} sx={INPUT_SX} />
            </Grid>
          </Grid>

          <SectionLabel icon={<PersonIcon sx={{ fontSize: 16 }} />} color="#3b82f6" label="Association" />
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <FormControl fullWidth size="small" sx={INPUT_SX}>
                <InputLabel>Client</InputLabel>
                <Select value={formData.clientId} onChange={e => set('clientId', e.target.value)} label="Client">
                  <MenuItem value=""><em>Aucun client</em></MenuItem>
                  {clients.map(c => <MenuItem key={c.id} value={c.id}>{c.firstName} {c.lastName}</MenuItem>)}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth size="small" sx={INPUT_SX}>
                <InputLabel>Réparation associée</InputLabel>
                <Select value={formData.repairId} onChange={e => set('repairId', e.target.value)} label="Réparation associée">
                  <MenuItem value=""><em>Aucune</em></MenuItem>
                  {repairs.map(r => {
                    const dev = devices.find(d => d.id === r.deviceId);
                    return <MenuItem key={r.id} value={r.id}>{dev?.brand} {dev?.model} — {r.description?.slice(0, 40)}</MenuItem>;
                  })}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth size="small" sx={INPUT_SX}>
                <InputLabel>Assigné à</InputLabel>
                <Select value={formData.assignedUserId} onChange={e => set('assignedUserId', e.target.value)} label="Assigné à">
                  <MenuItem value=""><em>Non assigné</em></MenuItem>
                  {getRepairEligibleUsers(users).map(u =>
                    <MenuItem key={u.id} value={u.id}>{getRepairUserDisplayName(u)}</MenuItem>
                  )}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>

        <DialogActions sx={{ px: 3, py: 2, borderTop: '1px solid', borderColor: 'divider', gap: 1 }}>
          {selectedEvent && (
            <Tooltip title="Supprimer" arrow>
              <IconButton onClick={handleDelete} sx={{ color: '#ef4444', mr: 'auto' }}>
                <DeleteIcon sx={{ fontSize: 20 }} />
              </IconButton>
            </Tooltip>
          )}
          {selectedEvent && (
            <>
              <Tooltip title="Ajouter à Google Calendar" arrow>
                <IconButton onClick={handleGoogleCalendarAppointment} sx={{ color: '#4285f4' }}>
                  <GoogleIcon sx={{ fontSize: 20 }} />
                </IconButton>
              </Tooltip>
              <Tooltip title="Télécharger .ics" arrow>
                <IconButton onClick={handleExportAppointmentICS} sx={{ color: '#111827' }}>
                  <DownloadIcon sx={{ fontSize: 20 }} />
                </IconButton>
              </Tooltip>
            </>
          )}
          <Button onClick={() => setOpenDialog(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button variant="contained" onClick={handleSubmit} disabled={!formData.title.trim()}
            sx={{ ...BTN_DARK, px: 3 }}>
            {selectedEvent ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* ═══ repair details dialog ═══ */}
      {selectedRepair && repairDialogData && (
        <RepairDetailsDialog
          open={!!selectedRepair}
          onClose={() => setSelectedRepair(null)}
          repair={selectedRepair}
          client={repairDialogData.client}
          device={repairDialogData.device}
          technician={repairDialogData.technician}
          parts={parts}
          services={services}
        />
      )}

      {/* ── snackbar ── */}
      <Snackbar open={snack.open} autoHideDuration={3000} onClose={() => setSnack(p => ({ ...p, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        <Alert severity={snack.sev} variant="filled" onClose={() => setSnack(p => ({ ...p, open: false }))}
          sx={{ borderRadius: '12px', fontWeight: 600 }}>
          {snack.msg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Calendar;

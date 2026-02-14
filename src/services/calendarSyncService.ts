import { Appointment, Repair, Client, Device } from '../types';

/* ── ICS date formatting ── */
export function formatICSDate(date: Date): string {
  const d = new Date(date);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}T${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}Z`;
}

/* ── escape text for ICS fields ── */
export function escapeICSText(text: string): string {
  return text
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\n/g, '\\n');
}

/* ── VEVENT interface ── */
export interface VEVENTParams {
  uid: string;
  summary: string;
  description?: string;
  dtstart: Date;
  dtend: Date;
  location?: string;
}

/* ── generate a single VEVENT block ── */
export function generateVEVENT({ uid, summary, description, dtstart, dtend, location }: VEVENTParams): string {
  const lines = [
    'BEGIN:VEVENT',
    `UID:${uid}`,
    `DTSTAMP:${formatICSDate(new Date())}`,
    `DTSTART:${formatICSDate(dtstart)}`,
    `DTEND:${formatICSDate(dtend)}`,
    `SUMMARY:${escapeICSText(summary)}`,
  ];
  if (description) lines.push(`DESCRIPTION:${escapeICSText(description)}`);
  if (location) lines.push(`LOCATION:${escapeICSText(location)}`);
  lines.push('END:VEVENT');
  return lines.join('\r\n');
}

/* ── wrap events in a VCALENDAR ── */
export function generateVCALENDAR(events: string[]): string {
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Atelier//Calendar//FR',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    ...events,
    'END:VCALENDAR',
  ];
  return lines.join('\r\n');
}

/* ── convert an Appointment to a VEVENT ── */
export function appointmentToVEVENT(appointment: Appointment, client?: Client | null): string {
  const clientName = client ? `${client.firstName} ${client.lastName}` : '';
  const description = [
    appointment.description,
    clientName ? `Client : ${clientName}` : '',
  ].filter(Boolean).join('\\n');

  return generateVEVENT({
    uid: `appointment-${appointment.id}@atelier`,
    summary: appointment.title,
    description,
    dtstart: new Date(appointment.startDate),
    dtend: new Date(appointment.endDate),
  });
}

/* ── convert a Repair to a VEVENT ── */
export function repairToVEVENT(repair: Repair, client?: Client | null, device?: Device | null): string {
  const clientName = client ? `${client.firstName} ${client.lastName}` : '';
  const deviceName = device ? `${device.brand} ${device.model}` : '';
  const summary = `🔧 ${repair.repairNumber || 'REP'} — ${deviceName || 'Appareil'}`;

  const getD = (v: any) => v ? new Date(v) : null;
  const start = getD(repair.estimatedStartDate) || getD(repair.startDate) || getD(repair.createdAt) || new Date();
  const end = getD(repair.dueDate) || getD(repair.estimatedEndDate) || getD(repair.endDate)
    || new Date(start.getTime() + 86400000);

  const description = [
    repair.description,
    clientName ? `Client : ${clientName}` : '',
    deviceName ? `Appareil : ${deviceName}` : '',
    repair.isUrgent ? '⚠️ URGENT' : '',
    `Statut : ${repair.status}`,
  ].filter(Boolean).join('\\n');

  return generateVEVENT({
    uid: `repair-${repair.id}@atelier`,
    summary,
    description,
    dtstart: start,
    dtend: end,
  });
}

/* ── download an ICS file (same pattern as exportService) ── */
export function downloadICSFile(content: string, filename: string): void {
  const blob = new Blob([content], { type: 'text/calendar;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename.endsWith('.ics') ? filename : `${filename}.ics`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/* ── export all appointments + repairs to a single .ics ── */
export function exportAllToICS(
  appointments: Appointment[],
  repairs: Repair[],
  clients: Client[],
  devices: Device[],
): void {
  const clientMap = new Map(clients.map(c => [c.id, c]));
  const deviceMap = new Map(devices.map(d => [d.id, d]));

  const events: string[] = [];

  appointments.forEach(a => {
    const client = a.clientId ? clientMap.get(a.clientId) : null;
    events.push(appointmentToVEVENT(a, client));
  });

  repairs.forEach(r => {
    if (r.status === 'returned') return;
    const client = clientMap.get(r.clientId);
    const device = r.deviceId ? deviceMap.get(r.deviceId) : null;
    events.push(repairToVEVENT(r, client, device));
  });

  const ics = generateVCALENDAR(events);
  downloadICSFile(ics, `calendrier-atelier-${new Date().toISOString().slice(0, 10)}.ics`);
}

/* ── export a single event to ICS ── */
export function exportSingleEventToICS(
  event: { type: 'appointment'; data: Appointment; client?: Client | null }
    | { type: 'repair'; data: Repair; client?: Client | null; device?: Device | null },
): void {
  let vevent: string;
  if (event.type === 'appointment') {
    vevent = appointmentToVEVENT(event.data, event.client);
  } else {
    vevent = repairToVEVENT(event.data, event.client, event.device);
  }
  const ics = generateVCALENDAR([vevent]);
  const name = event.type === 'appointment'
    ? `rdv-${event.data.id.slice(0, 8)}`
    : `reparation-${event.data.id.slice(0, 8)}`;
  downloadICSFile(ics, `${name}.ics`);
}

/* ── Google Calendar URL generator ── */
export function generateGoogleCalendarURL(params: {
  title: string;
  description?: string;
  start: Date;
  end: Date;
  location?: string;
}): string {
  const fmt = (d: Date) => formatICSDate(d).replace(/[-:]/g, '');
  const searchParams = new URLSearchParams({
    action: 'TEMPLATE',
    text: params.title,
    dates: `${fmt(params.start)}/${fmt(params.end)}`,
  });
  if (params.description) searchParams.set('details', params.description);
  if (params.location) searchParams.set('location', params.location);
  return `https://calendar.google.com/calendar/render?${searchParams.toString()}`;
}

/* ── open Google Calendar for an appointment ── */
export function openGoogleCalendarForAppointment(appointment: Appointment, client?: Client | null): void {
  const clientName = client ? `${client.firstName} ${client.lastName}` : '';
  const description = [appointment.description, clientName ? `Client : ${clientName}` : ''].filter(Boolean).join('\n');
  const url = generateGoogleCalendarURL({
    title: appointment.title,
    description,
    start: new Date(appointment.startDate),
    end: new Date(appointment.endDate),
  });
  window.open(url, '_blank', 'noopener,noreferrer');
}

/* ── open Google Calendar for a repair ── */
export function openGoogleCalendarForRepair(repair: Repair, client?: Client | null, device?: Device | null): void {
  const clientName = client ? `${client.firstName} ${client.lastName}` : '';
  const deviceName = device ? `${device.brand} ${device.model}` : '';
  const summary = `🔧 ${repair.repairNumber || 'REP'} — ${deviceName || 'Appareil'}`;

  const getD = (v: any) => v ? new Date(v) : null;
  const start = getD(repair.estimatedStartDate) || getD(repair.startDate) || getD(repair.createdAt) || new Date();
  const end = getD(repair.dueDate) || getD(repair.estimatedEndDate) || getD(repair.endDate)
    || new Date(start.getTime() + 86400000);

  const description = [
    repair.description,
    clientName ? `Client : ${clientName}` : '',
    deviceName ? `Appareil : ${deviceName}` : '',
    repair.isUrgent ? '⚠️ URGENT' : '',
  ].filter(Boolean).join('\n');

  const url = generateGoogleCalendarURL({ title: summary, description, start, end });
  window.open(url, '_blank', 'noopener,noreferrer');
}

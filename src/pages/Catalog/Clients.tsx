import React, { useEffect, useState, useMemo } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Avatar,
  Alert,
  CircularProgress,
  Snackbar,
  TextField,
  Chip,
  Tooltip,
  InputAdornment,
} from '@mui/material';
import { alpha } from '@mui/material/styles';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Refresh as RefreshIcon,
  Upload as UploadIcon,
  Download as DownloadIcon,
  Person as PersonIcon,
  Business as BusinessIcon,
  Search as SearchIcon,
  People as PeopleIcon,
  LocationOn as LocationIcon,
  Badge as BadgeIcon,
  CalendarToday as CalendarIcon,
  ContactMail as ContactMailIcon,
  SentimentDissatisfied as EmptyIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import ClientForm from '../../components/ClientForm';
import CSVImport from '../../components/CSVImport';
import { clientService } from '../../services/supabaseService';

/* ─── design tokens ─── */
const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': { boxShadow: '0 8px 32px rgba(0,0,0,0.10)', transform: 'translateY(-2px)' },
} as const;
const CARD_STATIC = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
} as const;
const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid',
    borderColor: 'divider',
    fontWeight: 600,
    fontSize: '0.75rem',
    color: 'text.secondary',
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;
const BTN_DARK = {
  borderRadius: '10px',
  textTransform: 'none',
  fontWeight: 600,
  bgcolor: '#111827',
  '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;
const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── KPI mini card ─── */
function KpiMini({ icon, iconColor, label, value }: { icon: React.ReactNode; iconColor: string; label: string; value: string | number }) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box
            sx={{
              width: 40,
              height: 40,
              borderRadius: '12px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
              color: '#fff',
              flexShrink: 0,
              boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
            }}
          >
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

/* ─── filter types ─── */
type FilterType = 'all' | 'particulier' | 'entreprise' | 'with_email' | 'with_phone';
const FILTER_OPTIONS: { key: FilterType; label: string; color: string }[] = [
  { key: 'all', label: 'Tous', color: '#6366f1' },
  { key: 'particulier', label: 'Particuliers', color: '#22c55e' },
  { key: 'entreprise', label: 'Entreprises', color: '#3b82f6' },
  { key: 'with_email', label: 'Avec email', color: '#8b5cf6' },
  { key: 'with_phone', label: 'Avec téléphone', color: '#f59e0b' },
];

const Clients: React.FC = () => {
  const { clients, loadClients, addClient, updateClient } = useAppStore();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [clientFormOpen, setClientFormOpen] = useState(false);
  const [editClientFormOpen, setEditClientFormOpen] = useState(false);
  const [editingClient, setEditingClient] = useState<any>(null);
  const [csvImportOpen, setCsvImportOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<FilterType>('all');

  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');

  useEffect(() => {
    const loadClientsData = async () => {
      setIsLoading(true);
      setError(null);
      try {
        await loadClients();
      } catch (err) {
        setError('Erreur lors du chargement des clients');
      } finally {
        setIsLoading(false);
      }
    };
    loadClientsData();
  }, []);

  /* ─── filtered data ─── */
  const filteredClients = useMemo(() => {
    let list = [...clients];
    // search
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (c) =>
          (c.firstName || '').toLowerCase().includes(q) ||
          (c.lastName || '').toLowerCase().includes(q) ||
          (c.email || '').toLowerCase().includes(q) ||
          (c.phone || '').toLowerCase().includes(q) ||
          (c.companyName || '').toLowerCase().includes(q) ||
          (c.city || '').toLowerCase().includes(q),
      );
    }
    // filter
    switch (filter) {
      case 'particulier':
        list = list.filter((c) => !c.companyName || c.companyName.trim() === '');
        break;
      case 'entreprise':
        list = list.filter((c) => c.companyName && c.companyName.trim() !== '');
        break;
      case 'with_email':
        list = list.filter((c) => c.email && c.email.trim() !== '' && !c.email.includes('@atelier.local'));
        break;
      case 'with_phone':
        list = list.filter((c) => c.phone && c.phone.trim() !== '');
        break;
    }
    return list;
  }, [clients, search, filter]);

  /* ─── KPI values ─── */
  const totalClients = clients.length;
  const totalEntreprises = clients.filter((c) => c.companyName && c.companyName.trim() !== '').length;
  const totalWithEmail = clients.filter((c) => c.email && c.email.trim() !== '' && !c.email.includes('@atelier.local')).length;
  const totalWithPhone = clients.filter((c) => c.phone && c.phone.trim() !== '').length;

  /* ─── handlers ─── */
  const handleOpenDialog = () => {
    setClientFormOpen(true);
    setError(null);
  };

  const handleCloseDialog = () => {
    setClientFormOpen(false);
    setError(null);
  };

  const handleOpenCsvImport = () => {
    setCsvImportOpen(true);
    setError(null);
  };

  const handleCloseCsvImport = () => {
    setCsvImportOpen(false);
    setError(null);
  };

  const handleEditClient = async (client: any) => {
    try {
      const result = await clientService.getById(client.id);

      if (result.success && 'data' in result && result.data) {
        setEditingClient(result.data);
        setEditClientFormOpen(true);
      } else {
        setSnackbarMessage('Erreur lors de la récupération des données du client');
        setSnackbarOpen(true);
      }
    } catch {
      setSnackbarMessage('Erreur lors de la récupération des données du client');
      setSnackbarOpen(true);
    }
  };

  const handleCreateNewClient = async (clientFormData: any, skipDuplicateCheck = true) => {
    setIsSubmitting(true);
    setError(null);

    try {
      const firstName = clientFormData.firstName || '';
      const lastName = clientFormData.lastName || '';

      const clientData = {
        firstName: firstName || 'Client',
        lastName: lastName || 'Sans nom',
        email: clientFormData.email || '',
        phone: (clientFormData.countryCode || '33') + (clientFormData.mobile || ''),
        address: clientFormData.address || '',
        notes: clientFormData.internalNote || '',
        category: clientFormData.category || 'particulier',
        title: clientFormData.title || 'mr',
        companyName: clientFormData.companyName || '',
        vatNumber: clientFormData.vatNumber || '',
        sirenNumber: clientFormData.sirenNumber || '',
        countryCode: clientFormData.countryCode || '33',
        addressComplement: clientFormData.addressComplement || '',
        region: clientFormData.region || '',
        postalCode: clientFormData.postalCode || '',
        city: clientFormData.city || '',
        billingAddressSame: clientFormData.billingAddressSame !== undefined ? clientFormData.billingAddressSame : true,
        billingAddress: clientFormData.billingAddress || '',
        billingAddressComplement: clientFormData.billingAddressComplement || '',
        billingRegion: clientFormData.billingRegion || '',
        billingPostalCode: clientFormData.billingPostalCode || '',
        billingCity: clientFormData.billingCity || '',
        accountingCode: clientFormData.accountingCode || '',
        cniIdentifier: clientFormData.cniIdentifier || '',
        attachedFilePath: clientFormData.attachedFile ? clientFormData.attachedFile.name : '',
        internalNote: clientFormData.internalNote || '',
        status: clientFormData.status || 'displayed',
        smsNotification: clientFormData.smsNotification !== undefined ? clientFormData.smsNotification : true,
        emailNotification: clientFormData.emailNotification !== undefined ? clientFormData.emailNotification : true,
        smsMarketing: clientFormData.smsMarketing !== undefined ? clientFormData.smsMarketing : true,
        emailMarketing: clientFormData.emailMarketing !== undefined ? clientFormData.emailMarketing : true,
      };

      await addClient(clientData, true);

      setClientFormOpen(false);
      setSnackbarMessage(`Client ${firstName} ${lastName} créé avec succès !`);
      setSnackbarOpen(true);
    } catch (err: any) {
      const errorMessage = err?.message || 'Erreur lors de la création du client. Veuillez réessayer.';
      setError(errorMessage);
      setSnackbarMessage(errorMessage);
      setSnackbarOpen(true);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUpdateClient = async (clientFormData: any) => {
    setIsSubmitting(true);
    setError(null);

    try {
      const existingClient = clients.find(
        (c) => c.email.toLowerCase() === clientFormData.email.toLowerCase() && c.id !== editingClient.id,
      );
      if (existingClient) {
        setError(`Un client avec l'email "${clientFormData.email}" existe déjà.`);
        return;
      }

      const clientData = {
        firstName: clientFormData.firstName,
        lastName: clientFormData.lastName,
        email: clientFormData.email,
        phone: clientFormData.countryCode + clientFormData.mobile,
        address: clientFormData.address,
        notes: clientFormData.internalNote || '',
        category: clientFormData.category,
        title: clientFormData.title,
        companyName: clientFormData.companyName,
        vatNumber: clientFormData.vatNumber,
        sirenNumber: clientFormData.sirenNumber,
        countryCode: clientFormData.countryCode,
        addressComplement: clientFormData.addressComplement,
        region: clientFormData.region,
        postalCode: clientFormData.postalCode,
        city: clientFormData.city,
        billingAddressSame: clientFormData.billingAddressSame,
        billingAddress: clientFormData.billingAddress,
        billingAddressComplement: clientFormData.billingAddressComplement,
        billingRegion: clientFormData.billingRegion,
        billingPostalCode: clientFormData.billingPostalCode,
        billingCity: clientFormData.billingCity,
        accountingCode: clientFormData.accountingCode,
        cniIdentifier: clientFormData.cniIdentifier,
        attachedFilePath: clientFormData.attachedFile ? clientFormData.attachedFile.name : null,
        internalNote: clientFormData.internalNote,
        status: clientFormData.status,
        smsNotification: clientFormData.smsNotification,
        emailNotification: clientFormData.emailNotification,
        smsMarketing: clientFormData.smsMarketing,
        emailMarketing: clientFormData.emailMarketing,
      };

      await updateClient(editingClient.id, clientData);

      setEditClientFormOpen(false);
      setEditingClient(null);
      await loadClients();

      setSnackbarMessage('Client modifié avec succès !');
      setSnackbarOpen(true);
    } catch (err) {
      setError('Erreur lors de la modification du client. Veuillez réessayer.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCsvImport = async (clientsToImport: any[]) => {
    setIsSubmitting(true);
    setError(null);

    try {
      let importedCount = 0;
      let skippedCount = 0;

      for (const clientData of clientsToImport) {
        if (clientData.email && clientData.email.trim()) {
          const existingClient = clients.find((c) => c.email && c.email.toLowerCase() === clientData.email.toLowerCase());
          if (existingClient) {
            skippedCount++;
            continue;
          }
        }

        try {
          const result = await addClient(clientData, true);
          if (result && result.success) {
            importedCount++;
          }
        } catch (error: any) {
          if (error.message && error.message.includes('existe déjà')) {
            skippedCount++;
          } else {
            throw error;
          }
        }
      }

      await loadClients();

      if (importedCount > 0 || skippedCount > 0) {
        const msg = `Import terminé : ${importedCount} client(s) importé(s)${skippedCount > 0 ? `, ${skippedCount} ignoré(s)` : ''}`;
        setSnackbarMessage(msg);
        setSnackbarOpen(true);
      }
    } catch (err: any) {
      const errorMessage = err?.message || "Erreur lors de l'import CSV. Veuillez réessayer.";
      setError(errorMessage);
      setSnackbarMessage(errorMessage);
      setSnackbarOpen(true);
    } finally {
      setIsSubmitting(false);
      setCsvImportOpen(false);
    }
  };

  const handleExportClients = () => {
    if (clients.length === 0) {
      setSnackbarMessage('Aucun client à exporter.');
      setSnackbarOpen(true);
      return;
    }

    const headers = [
      'Prénom', 'Nom', 'Email', 'Indicatif', 'Téléphone mobile', 'Adresse',
      'Complément adresse', 'Code postal', 'Ville', 'Etat', 'Pays', 'Société',
      'N° TVA', 'N° SIREN', 'Code Comptable', 'Titre (M. / Mme)', 'Identifiant CNI',
    ];

    const csvData = clients.map((client) => {
      const phoneWithoutCode = client.phone ? client.phone.replace(client.countryCode || '33', '') : '';
      return [
        client.firstName || '', client.lastName || '', client.email || '',
        client.countryCode || '33', phoneWithoutCode, client.address || '',
        client.addressComplement || '', client.postalCode || '', client.city || '',
        client.region || '', 'France', client.companyName || '', client.vatNumber || '',
        client.sirenNumber || '', client.accountingCode || '',
        client.title === 'mrs' ? 'Mme' : 'M.', client.cniIdentifier || '',
      ];
    });

    const csvContent = [headers.join(','), ...csvData.map((row) => row.map((field) => `"${field}"`).join(','))].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `clients_export_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setSnackbarMessage(`${clients.length} clients exportés avec succès !`);
    setSnackbarOpen(true);
  };

  const handleRefresh = async () => {
    setIsLoading(true);
    setError(null);
    try {
      await loadClients();
    } catch {
      setError('Erreur lors du rechargement des clients');
    } finally {
      setIsLoading(false);
    }
  };

  /* ─── helpers ─── */
  const getInitials = (c: any) => {
    const f = (c.firstName || '').charAt(0).toUpperCase();
    const l = (c.lastName || '').charAt(0).toUpperCase();
    return f + l || '?';
  };

  const getAvatarColor = (c: any) => {
    const name = `${c.firstName || ''}${c.lastName || ''}`;
    const colors = ['#6366f1', '#3b82f6', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#14b8a6'];
    let hash = 0;
    for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
  };

  const displayName = (c: any) =>
    c.firstName && c.lastName ? `${c.firstName} ${c.lastName}` : c.firstName || c.lastName || 'Client sans nom';

  const displayEmail = (c: any) => (c.email && !c.email.includes('@atelier.local') ? c.email : null);

  return (
    <Box>
      {/* ─── header ─── */}
      <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '-0.01em' }}>
            Clients
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Gérez votre base de données clients
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Tooltip title="Importer des clients depuis un fichier CSV">
            <Button
              variant="outlined"
              startIcon={<UploadIcon />}
              onClick={handleOpenCsvImport}
              sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: '#e5e7eb', color: '#6b7280', '&:hover': { borderColor: '#6366f1', color: '#6366f1', bgcolor: alpha('#6366f1', 0.04) } }}
            >
              Importer
            </Button>
          </Tooltip>
          <Tooltip title="Exporter tous les clients au format CSV">
            <span>
              <Button
                variant="outlined"
                startIcon={<DownloadIcon />}
                onClick={handleExportClients}
                disabled={clients.length === 0}
                sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: '#e5e7eb', color: '#6b7280', '&:hover': { borderColor: '#22c55e', color: '#22c55e', bgcolor: alpha('#22c55e', 0.04) } }}
              >
                Exporter
              </Button>
            </span>
          </Tooltip>
          <Tooltip title="Actualiser la liste">
            <IconButton onClick={handleRefresh} disabled={isLoading} sx={{ border: '1px solid #e5e7eb', borderRadius: '10px', width: 40, height: 40 }}>
              {isLoading ? <CircularProgress size={18} /> : <RefreshIcon fontSize="small" />}
            </IconButton>
          </Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={handleOpenDialog} sx={BTN_DARK}>
            Nouveau client
          </Button>
        </Box>
      </Box>

      {/* ─── KPI ─── */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2, mb: 3 }}>
        <KpiMini icon={<PeopleIcon fontSize="small" />} iconColor="#6366f1" label="Total clients" value={totalClients} />
        <KpiMini icon={<BusinessIcon fontSize="small" />} iconColor="#3b82f6" label="Entreprises" value={totalEntreprises} />
        <KpiMini icon={<EmailIcon fontSize="small" />} iconColor="#8b5cf6" label="Avec email" value={totalWithEmail} />
        <KpiMini icon={<PhoneIcon fontSize="small" />} iconColor="#f59e0b" label="Avec téléphone" value={totalWithPhone} />
      </Box>

      {/* ─── search + filters ─── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <CardContent sx={{ p: '16px !important', display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
          <TextField
            size="small"
            placeholder="Rechercher par nom, email, téléphone, société, ville..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            sx={{ ...INPUT_SX, minWidth: 320, flex: 1 }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon fontSize="small" sx={{ color: 'text.disabled' }} />
                </InputAdornment>
              ),
            }}
          />
          <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
            {FILTER_OPTIONS.map((f) => (
              <Chip
                key={f.key}
                label={f.label}
                size="small"
                onClick={() => setFilter(f.key)}
                sx={{
                  fontWeight: 600,
                  fontSize: '0.75rem',
                  borderRadius: '8px',
                  ...(filter === f.key
                    ? { bgcolor: f.color, color: '#fff', boxShadow: `0 2px 8px ${alpha(f.color, 0.35)}` }
                    : { bgcolor: alpha(f.color, 0.08), color: f.color, '&:hover': { bgcolor: alpha(f.color, 0.16) } }),
                }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* ─── error ─── */}
      {error && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: '12px' }}>
          {error}
        </Alert>
      )}

      {/* ─── table ─── */}
      <Card sx={CARD_STATIC}>
        <CardContent sx={{ p: 0 }}>
          {isLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
              <CircularProgress />
            </Box>
          ) : filteredClients.length === 0 ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 8 }}>
              <Box
                sx={{
                  width: 64,
                  height: 64,
                  borderRadius: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  background: `linear-gradient(135deg, ${alpha('#6366f1', 0.12)}, ${alpha('#6366f1', 0.04)})`,
                  mb: 2,
                }}
              >
                <EmptyIcon sx={{ fontSize: 32, color: '#6366f1' }} />
              </Box>
              <Typography variant="body1" sx={{ fontWeight: 600, mb: 0.5 }}>
                {search || filter !== 'all' ? 'Aucun résultat' : 'Aucun client'}
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2 }}>
                {search || filter !== 'all'
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Commencez par ajouter votre premier client'}
              </Typography>
              {!search && filter === 'all' && (
                <Button variant="contained" startIcon={<AddIcon />} onClick={handleOpenDialog} sx={BTN_DARK} size="small">
                  Ajouter un client
                </Button>
              )}
            </Box>
          ) : (
            <>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow sx={TABLE_HEAD_SX}>
                      <TableCell>Client</TableCell>
                      <TableCell>Contact</TableCell>
                      <TableCell>Société</TableCell>
                      <TableCell>Localisation</TableCell>
                      <TableCell>Inscription</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filteredClients.map((client) => {
                      const color = getAvatarColor(client);
                      const email = displayEmail(client);
                      return (
                        <TableRow
                          key={client.id}
                          sx={{ '&:hover': { bgcolor: alpha('#6366f1', 0.03) }, transition: 'background .2s' }}
                        >
                          {/* Client */}
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                              <Avatar
                                sx={{
                                  width: 38,
                                  height: 38,
                                  fontSize: '0.85rem',
                                  fontWeight: 700,
                                  bgcolor: alpha(color, 0.12),
                                  color,
                                }}
                              >
                                {getInitials(client)}
                              </Avatar>
                              <Box>
                                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                  {displayName(client)}
                                </Typography>
                                {client.category === 'professionnel' || (client.companyName && client.companyName.trim()) ? (
                                  <Chip
                                    label="Pro"
                                    size="small"
                                    sx={{
                                      height: 18,
                                      fontSize: '0.65rem',
                                      fontWeight: 700,
                                      bgcolor: alpha('#3b82f6', 0.1),
                                      color: '#3b82f6',
                                      mt: 0.3,
                                    }}
                                  />
                                ) : (
                                  <Chip
                                    label="Particulier"
                                    size="small"
                                    sx={{
                                      height: 18,
                                      fontSize: '0.65rem',
                                      fontWeight: 700,
                                      bgcolor: alpha('#22c55e', 0.1),
                                      color: '#22c55e',
                                      mt: 0.3,
                                    }}
                                  />
                                )}
                              </Box>
                            </Box>
                          </TableCell>

                          {/* Contact */}
                          <TableCell>
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.4 }}>
                              {email ? (
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                                  <EmailIcon sx={{ fontSize: 14, color: '#8b5cf6' }} />
                                  <Typography variant="body2" sx={{ fontSize: '0.8rem' }}>
                                    {email}
                                  </Typography>
                                </Box>
                              ) : (
                                <Typography variant="body2" sx={{ fontSize: '0.8rem', color: 'text.disabled', fontStyle: 'italic' }}>
                                  Pas d'email
                                </Typography>
                              )}
                              {client.phone ? (
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                                  <PhoneIcon sx={{ fontSize: 14, color: '#f59e0b' }} />
                                  <Typography variant="body2" sx={{ fontSize: '0.8rem' }}>
                                    {client.phone}
                                  </Typography>
                                </Box>
                              ) : (
                                <Typography variant="body2" sx={{ fontSize: '0.8rem', color: 'text.disabled', fontStyle: 'italic' }}>
                                  Pas de tél.
                                </Typography>
                              )}
                            </Box>
                          </TableCell>

                          {/* Société */}
                          <TableCell>
                            {client.companyName && client.companyName.trim() ? (
                              <Box>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                                  <BusinessIcon sx={{ fontSize: 14, color: '#3b82f6' }} />
                                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.8rem' }}>
                                    {client.companyName}
                                  </Typography>
                                </Box>
                                {client.vatNumber && (
                                  <Typography variant="caption" sx={{ color: 'text.secondary', fontSize: '0.7rem' }}>
                                    TVA : {client.vatNumber}
                                  </Typography>
                                )}
                                {client.sirenNumber && (
                                  <Typography variant="caption" sx={{ color: 'text.secondary', fontSize: '0.7rem', display: 'block' }}>
                                    SIREN : {client.sirenNumber}
                                  </Typography>
                                )}
                              </Box>
                            ) : (
                              <Typography variant="body2" sx={{ color: 'text.disabled', fontSize: '0.8rem' }}>
                                —
                              </Typography>
                            )}
                          </TableCell>

                          {/* Localisation */}
                          <TableCell>
                            {client.city || client.postalCode || client.address ? (
                              <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 0.75 }}>
                                <LocationIcon sx={{ fontSize: 14, color: '#ef4444', mt: 0.2 }} />
                                <Box>
                                  {client.address && (
                                    <Typography variant="body2" sx={{ fontSize: '0.8rem' }}>
                                      {client.address}
                                    </Typography>
                                  )}
                                  {(client.postalCode || client.city) && (
                                    <Typography variant="caption" sx={{ color: 'text.secondary', fontSize: '0.7rem' }}>
                                      {[client.postalCode, client.city].filter(Boolean).join(' ')}
                                    </Typography>
                                  )}
                                </Box>
                              </Box>
                            ) : (
                              <Typography variant="body2" sx={{ color: 'text.disabled', fontSize: '0.8rem' }}>
                                —
                              </Typography>
                            )}
                          </TableCell>

                          {/* Date */}
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
                              <CalendarIcon sx={{ fontSize: 14, color: 'text.disabled' }} />
                              <Typography variant="body2" sx={{ fontSize: '0.8rem', color: 'text.secondary' }}>
                                {new Date(client.createdAt).toLocaleDateString('fr-FR')}
                              </Typography>
                            </Box>
                          </TableCell>

                          {/* Actions */}
                          <TableCell align="right">
                            <Tooltip title="Modifier le client" arrow>
                              <IconButton
                                size="small"
                                onClick={() => handleEditClient(client)}
                                sx={{
                                  bgcolor: alpha('#6366f1', 0.08),
                                  color: '#6366f1',
                                  '&:hover': { bgcolor: alpha('#6366f1', 0.18) },
                                  width: 32,
                                  height: 32,
                                }}
                              >
                                <EditIcon sx={{ fontSize: 16 }} />
                              </IconButton>
                            </Tooltip>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </TableContainer>

              {/* ─── footer count ─── */}
              <Box sx={{ px: 2, py: 1.5, borderTop: '1px solid', borderColor: 'divider', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  {filteredClients.length} client{filteredClients.length > 1 ? 's' : ''}
                  {filteredClients.length !== clients.length && ` sur ${clients.length}`}
                </Typography>
                {(search || filter !== 'all') && (
                  <Chip
                    label="Effacer les filtres"
                    size="small"
                    onClick={() => {
                      setSearch('');
                      setFilter('all');
                    }}
                    sx={{ fontSize: '0.7rem', height: 22, borderRadius: '6px' }}
                  />
                )}
              </Box>
            </>
          )}
        </CardContent>
      </Card>

      {/* ─── forms / dialogs ─── */}
      <ClientForm
        open={clientFormOpen}
        onClose={handleCloseDialog}
        onSubmit={handleCreateNewClient}
        existingEmails={clients.map((c) => c.email).filter(Boolean)}
      />

      <ClientForm
        open={editClientFormOpen}
        onClose={() => {
          setEditClientFormOpen(false);
          setEditingClient(null);
        }}
        onSubmit={handleUpdateClient}
        existingEmails={clients
          .filter((c) => c.id !== editingClient?.id)
          .map((c) => c.email)
          .filter(Boolean)}
        initialData={
          editingClient
            ? {
                category: editingClient.category || 'particulier',
                title: editingClient.title || 'mr',
                firstName: editingClient.firstName,
                lastName: editingClient.lastName,
                companyName: editingClient.companyName || '',
                vatNumber: editingClient.vatNumber || '',
                sirenNumber: editingClient.sirenNumber || '',
                email: editingClient.email,
                countryCode: editingClient.countryCode || '33',
                mobile: editingClient.phone ? editingClient.phone.replace(editingClient.countryCode || '33', '') : '',
                address: editingClient.address || '',
                addressComplement: editingClient.addressComplement || '',
                region: editingClient.region || '',
                postalCode: editingClient.postalCode || '',
                city: editingClient.city || '',
                billingAddressSame: editingClient.billingAddressSame !== false,
                billingAddress: editingClient.billingAddress || '',
                billingAddressComplement: editingClient.billingAddressComplement || '',
                billingRegion: editingClient.billingRegion || '',
                billingPostalCode: editingClient.billingPostalCode || '',
                billingCity: editingClient.billingCity || '',
                accountingCode: editingClient.accountingCode || '',
                cniIdentifier: editingClient.cniIdentifier || '',
                internalNote: editingClient.internalNote || editingClient.notes || '',
                status: editingClient.status || 'displayed',
                smsNotification: editingClient.smsNotification !== false,
                emailNotification: editingClient.emailNotification !== false,
                smsMarketing: editingClient.smsMarketing !== false,
                emailMarketing: editingClient.emailMarketing !== false,
              }
            : undefined
        }
        isEditing={true}
      />

      <CSVImport open={csvImportOpen} onClose={handleCloseCsvImport} onImport={handleCsvImport} />

      <Snackbar
        open={snackbarOpen}
        autoHideDuration={4000}
        onClose={() => setSnackbarOpen(false)}
        message={snackbarMessage}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      />
    </Box>
  );
};

export default Clients;

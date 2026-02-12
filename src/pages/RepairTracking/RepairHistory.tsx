import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  TextField,
  Button,
  Card,
  CardContent,
  Grid,
  Chip,
  Alert,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Search as SearchIcon,
  Visibility as VisibilityIcon,
  Email as EmailIcon,
  Build as BuildIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  Receipt as ReceiptIcon,
  Assignment as AssignmentIcon,
  Home as HomeIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { repairTrackingService, RepairHistoryItem, RepairTrackingData } from '../../services/repairTrackingService';
import { useNavigate } from 'react-router-dom';

// --- Dark Premium Theme Constants ---
const NAVY = '#0f172a';
const NAVY_DARK = '#0b1120';
const NAVY_CARD = 'rgba(30, 41, 59, 0.5)';
const GOLD = '#f59e0b';
const GOLD_DARK = '#d97706';
const GOLD_SUBTLE = 'rgba(245, 158, 11, 0.15)';
const GOLD_GLOW = 'rgba(245, 158, 11, 0.3)';
const GLASS_BORDER = 'rgba(148, 163, 184, 0.1)';
const TEXT_WHITE = '#ffffff';
const TEXT_LIGHT = '#e2e8f0';
const TEXT_MUTED = '#94a3b8';
const TEXT_DIM = '#64748b';

const repairStatuses: Record<string, { label: string; color: string; icon: React.ElementType }> = {
  'new': { label: 'Nouvelle', color: '#3b82f6', icon: InfoIcon },
  'in_progress': { label: 'En cours', color: GOLD, icon: BuildIcon },
  'waiting_parts': { label: 'En attente de pièces', color: '#f59e0b', icon: ScheduleIcon },
  'waiting_delivery': { label: 'Livraison attendue', color: '#8b5cf6', icon: ScheduleIcon },
  'completed': { label: 'Terminée', color: '#22c55e', icon: CheckCircleIcon },
  'cancelled': { label: 'Annulée', color: '#ef4444', icon: WarningIcon },
  'returned': { label: 'Restituée', color: '#22c55e', icon: CheckCircleIcon },
};

const statusFallbacks: Record<string, string> = {
  'pending': 'En attente',
  'delivered': 'Livrée',
  'shipped': 'Expédiée',
  'diagnosed': 'Diagnostiquée',
  'quoted': 'Devisé',
  'approved': 'Approuvée',
  'rejected': 'Rejetée',
  'on_hold': 'En pause',
  'scheduled': 'Programmée',
  'in_diagnosis': 'En diagnostic',
  'parts_ordered': 'Pièces commandées',
  'quality_check': 'Contrôle qualité',
  'ready_for_pickup': 'Prête à récupérer',
  'picked_up': 'Récupérée',
};

const RepairHistory: React.FC = () => {
  const [email, setEmail] = useState('');
  const [repairHistory, setRepairHistory] = useState<RepairHistoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedRepair, setSelectedRepair] = useState<RepairTrackingData | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const navigate = useNavigate();

  const searchHistory = async () => {
    if (!email) {
      setError('Veuillez saisir votre email');
      return;
    }
    setLoading(true);
    setError(null);
    setRepairHistory([]);
    try {
      const data = await repairTrackingService.getClientRepairHistory(email);
      setRepairHistory(data);
      if (data.length === 0) setError('Aucune réparation trouvée pour cet email');
    } catch {
      setError('Erreur lors de la recherche de votre historique');
    } finally {
      setLoading(false);
    }
  };

  const viewRepairDetails = async (repairId: string) => {
    try {
      const data = await repairTrackingService.getRepairTracking(repairId, email);
      if (data) {
        setSelectedRepair(data);
        setDialogOpen(true);
      }
    } catch {
      setError('Erreur lors du chargement des détails');
    }
  };

  const getStatusLabel = (status: string) => repairStatuses[status]?.label || statusFallbacks[status] || status;
  const getStatusColor = (status: string) => repairStatuses[status]?.color || TEXT_DIM;

  const formatDate = (dateString: string) => format(new Date(dateString), 'dd/MM/yyyy à HH:mm', { locale: fr });
  const formatPrice = (price: number) => new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }).format(price);

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: `
          radial-gradient(ellipse at 20% 0%, rgba(245, 158, 11, 0.06) 0%, transparent 50%),
          radial-gradient(ellipse at 80% 100%, rgba(59, 130, 246, 0.04) 0%, transparent 50%),
          linear-gradient(180deg, ${NAVY} 0%, ${NAVY_DARK} 100%)
        `,
        py: 4,
        px: 2,
      }}
    >
      <Container maxWidth="lg">
        {/* Header */}
        <Box sx={{ mb: 4 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3, flexWrap: 'wrap', gap: 2 }}>
            <Button
              variant="outlined"
              onClick={() => navigate('/')}
              startIcon={<HomeIcon />}
              sx={{
                borderColor: GLASS_BORDER,
                color: TEXT_MUTED,
                borderRadius: '12px',
                fontFamily: '"Inter", sans-serif',
                textTransform: 'none',
                '&:hover': { borderColor: GOLD, color: GOLD, backgroundColor: GOLD_SUBTLE },
              }}
            >
              Accueil
            </Button>
          </Box>
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <Typography
              variant="h3"
              component="h1"
              sx={{
                fontFamily: '"Outfit", sans-serif',
                fontWeight: 700,
                color: TEXT_WHITE,
                mb: 1,
              }}
            >
              Historique des{' '}
              <Box component="span" sx={{ color: GOLD }}>Réparations</Box>
            </Typography>
            <Typography
              variant="h6"
              sx={{ color: TEXT_DIM, fontFamily: '"Inter", sans-serif', fontWeight: 400, fontSize: '1.1rem' }}
            >
              Consultez l'historique complet de vos réparations
            </Typography>
          </Box>
        </Box>

        {/* Search Card */}
        <Card
          sx={{
            mb: 4,
            background: NAVY_CARD,
            backdropFilter: 'blur(12px)',
            borderRadius: '16px',
            border: `1px solid ${GLASS_BORDER}`,
            boxShadow: '0 4px 30px rgba(0,0,0,0.2)',
          }}
        >
          <CardContent sx={{ p: 4 }}>
            <Typography
              variant="h5"
              sx={{
                color: TEXT_WHITE,
                fontFamily: '"Outfit", sans-serif',
                fontWeight: 600,
                mb: 3,
              }}
            >
              Rechercher votre historique
            </Typography>
            <Grid container spacing={2} alignItems="center">
              <Grid item xs={12} md={8}>
                <TextField
                  fullWidth
                  label="Email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="votre@email.com"
                  onKeyDown={(e) => { if (e.key === 'Enter' && email) searchHistory(); }}
                  InputProps={{
                    startAdornment: <EmailIcon sx={{ mr: 1, color: GOLD }} />,
                  }}
                  sx={{
                    '& .MuiOutlinedInput-root': {
                      backgroundColor: 'rgba(15, 23, 42, 0.5)',
                      borderRadius: '12px',
                      color: TEXT_WHITE,
                      '& fieldset': { borderColor: GLASS_BORDER },
                      '&:hover fieldset': { borderColor: TEXT_DIM },
                      '&.Mui-focused fieldset': { borderColor: GOLD, boxShadow: `0 0 0 3px ${GOLD_SUBTLE}` },
                    },
                    '& .MuiInputLabel-root': { color: TEXT_DIM },
                    '& .MuiInputLabel-root.Mui-focused': { color: GOLD },
                    '& input': { color: TEXT_WHITE },
                  }}
                />
              </Grid>
              <Grid item xs={12} md={4}>
                <Button
                  fullWidth
                  variant="contained"
                  onClick={searchHistory}
                  disabled={loading || !email}
                  startIcon={loading ? <CircularProgress size={20} sx={{ color: NAVY }} /> : <SearchIcon />}
                  sx={{
                    height: 56,
                    background: `linear-gradient(135deg, ${GOLD}, ${GOLD_DARK})`,
                    color: NAVY,
                    fontWeight: 700,
                    fontFamily: '"Inter", sans-serif',
                    textTransform: 'none',
                    borderRadius: '12px',
                    boxShadow: `0 4px 20px ${GOLD_GLOW}`,
                    '&:hover': {
                      background: `linear-gradient(135deg, #fbbf24, ${GOLD})`,
                      boxShadow: `0 6px 24px ${GOLD_GLOW}`,
                    },
                    '&:disabled': {
                      background: 'rgba(30, 41, 59, 0.6)',
                      color: TEXT_DIM,
                      boxShadow: 'none',
                    },
                  }}
                >
                  {loading ? 'Recherche...' : 'Rechercher'}
                </Button>
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* Error */}
        {error && (
          <Alert
            severity="error"
            sx={{
              mb: 4,
              backgroundColor: 'rgba(239, 68, 68, 0.1)',
              color: '#fca5a5',
              border: '1px solid rgba(239, 68, 68, 0.2)',
              borderRadius: '12px',
              '& .MuiAlert-icon': { color: '#ef4444' },
            }}
          >
            {error}
          </Alert>
        )}

        {/* Results Table */}
        {repairHistory.length > 0 && (
          <Card
            sx={{
              background: NAVY_CARD,
              backdropFilter: 'blur(12px)',
              borderRadius: '16px',
              border: `1px solid ${GLASS_BORDER}`,
              boxShadow: '0 4px 30px rgba(0,0,0,0.2)',
            }}
          >
            <CardContent sx={{ p: { xs: 2, md: 4 } }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3, flexWrap: 'wrap', gap: 2 }}>
                <Typography
                  variant="h6"
                  sx={{ color: TEXT_WHITE, fontFamily: '"Outfit", sans-serif', fontWeight: 600 }}
                >
                  Vos réparations ({repairHistory.length})
                </Typography>
                <Button
                  variant="outlined"
                  onClick={() => navigate('/repair-tracking')}
                  startIcon={<AssignmentIcon />}
                  sx={{
                    borderColor: GLASS_BORDER,
                    color: TEXT_MUTED,
                    borderRadius: '12px',
                    fontFamily: '"Inter", sans-serif',
                    textTransform: 'none',
                    '&:hover': { borderColor: GOLD, color: GOLD, backgroundColor: GOLD_SUBTLE },
                  }}
                >
                  Suivre une réparation
                </Button>
              </Box>

              <TableContainer
                sx={{
                  borderRadius: '12px',
                  border: `1px solid ${GLASS_BORDER}`,
                  background: 'rgba(15, 23, 42, 0.4)',
                }}
              >
                <Table>
                  <TableHead>
                    <TableRow>
                      {['Réparation', 'Appareil', 'Statut', 'Prix', 'Date', 'Actions'].map((h) => (
                        <TableCell
                          key={h}
                          sx={{
                            color: TEXT_DIM,
                            fontFamily: '"Inter", sans-serif',
                            fontWeight: 600,
                            fontSize: '0.8rem',
                            textTransform: 'uppercase',
                            letterSpacing: '0.05em',
                            borderBottom: `1px solid ${GLASS_BORDER}`,
                            background: 'rgba(15, 23, 42, 0.3)',
                          }}
                        >
                          {h}
                        </TableCell>
                      ))}
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {repairHistory.map((repair) => (
                      <TableRow
                        key={repair.id}
                        sx={{
                          '&:hover': { background: 'rgba(245, 158, 11, 0.04)' },
                          '& td': { borderBottom: `1px solid ${GLASS_BORDER}` },
                        }}
                      >
                        <TableCell>
                          <Box>
                            <Typography sx={{ color: TEXT_WHITE, fontWeight: 500, fontSize: '0.9rem', fontFamily: '"JetBrains Mono", monospace' }}>
                              {repair.repairNumber || `#${repair.id.slice(0, 8)}`}
                            </Typography>
                            <Typography sx={{ color: TEXT_DIM, fontSize: '0.75rem' }}>
                              {repair.description}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          {repair.device ? (
                            <Typography sx={{ color: TEXT_LIGHT, fontSize: '0.9rem' }}>
                              {repair.device.brand} {repair.device.model}
                            </Typography>
                          ) : (
                            <Typography sx={{ color: TEXT_DIM, fontSize: '0.85rem' }}>Non spécifié</Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={getStatusLabel(repair.status)}
                            size="small"
                            sx={{
                              backgroundColor: `${getStatusColor(repair.status)}20`,
                              color: getStatusColor(repair.status),
                              fontWeight: 600,
                              fontSize: '0.75rem',
                              border: `1px solid ${getStatusColor(repair.status)}30`,
                            }}
                          />
                        </TableCell>
                        <TableCell>
                          <Box>
                            <Typography sx={{ color: TEXT_WHITE, fontWeight: 500, fontFamily: '"JetBrains Mono", monospace', fontSize: '0.9rem' }}>
                              {formatPrice(repair.totalPrice)}
                            </Typography>
                            <Chip
                              label={repair.isPaid ? 'Payé' : 'En attente'}
                              size="small"
                              sx={{
                                mt: 0.5,
                                height: 20,
                                fontSize: '0.65rem',
                                backgroundColor: repair.isPaid ? 'rgba(34, 197, 94, 0.15)' : 'rgba(245, 158, 11, 0.15)',
                                color: repair.isPaid ? '#22c55e' : '#f59e0b',
                                border: `1px solid ${repair.isPaid ? 'rgba(34, 197, 94, 0.25)' : 'rgba(245, 158, 11, 0.25)'}`,
                              }}
                            />
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography sx={{ color: TEXT_MUTED, fontSize: '0.85rem' }}>
                            {formatDate(repair.createdAt)}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Tooltip title="Voir les détails">
                            <IconButton
                              size="small"
                              onClick={() => viewRepairDetails(repair.id)}
                              sx={{
                                color: GOLD,
                                '&:hover': { backgroundColor: GOLD_SUBTLE },
                              }}
                            >
                              <VisibilityIcon />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        )}

        {/* Detail Dialog */}
        <Dialog
          open={dialogOpen}
          onClose={() => setDialogOpen(false)}
          maxWidth="md"
          fullWidth
          PaperProps={{
            sx: {
              background: NAVY,
              border: `1px solid ${GLASS_BORDER}`,
              borderRadius: '16px',
              color: TEXT_WHITE,
            },
          }}
        >
          <DialogTitle
            sx={{
              fontFamily: '"Outfit", sans-serif',
              fontWeight: 600,
              borderBottom: `1px solid ${GLASS_BORDER}`,
              pb: 2,
            }}
          >
            Détails de la réparation
            {selectedRepair && (
              <Typography variant="subtitle2" sx={{ color: TEXT_DIM, fontFamily: '"JetBrains Mono", monospace' }}>
                {selectedRepair.repairNumber || `#${selectedRepair.id.slice(0, 8)}`}
              </Typography>
            )}
          </DialogTitle>
          <DialogContent sx={{ pt: 3 }}>
            {selectedRepair && (
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <Chip
                    label={getStatusLabel(selectedRepair.status)}
                    sx={{
                      backgroundColor: `${getStatusColor(selectedRepair.status)}20`,
                      color: getStatusColor(selectedRepair.status),
                      fontWeight: 600,
                      border: `1px solid ${getStatusColor(selectedRepair.status)}30`,
                    }}
                  />
                </Grid>

                <Grid item xs={12} md={6}>
                  <Typography sx={{ color: GOLD, fontFamily: '"Outfit", sans-serif', fontWeight: 600, mb: 1 }}>
                    Description
                  </Typography>
                  <Typography sx={{ color: TEXT_LIGHT, fontSize: '0.95rem' }}>
                    {selectedRepair.description}
                  </Typography>
                </Grid>

                <Grid item xs={12} md={6}>
                  <Typography sx={{ color: GOLD, fontFamily: '"Outfit", sans-serif', fontWeight: 600, mb: 1 }}>
                    Problème identifié
                  </Typography>
                  <Typography sx={{ color: TEXT_LIGHT, fontSize: '0.95rem' }}>
                    {selectedRepair.issue}
                  </Typography>
                </Grid>

                {selectedRepair.device && (
                  <Grid item xs={12}>
                    <Typography sx={{ color: GOLD, fontFamily: '"Outfit", sans-serif', fontWeight: 600, mb: 1 }}>
                      Appareil
                    </Typography>
                    <Typography sx={{ color: TEXT_LIGHT }}>
                      {selectedRepair.device.brand} {selectedRepair.device.model} ({selectedRepair.device.type})
                    </Typography>
                  </Grid>
                )}

                <Grid item xs={12} md={6}>
                  <Typography sx={{ color: GOLD, fontFamily: '"Outfit", sans-serif', fontWeight: 600, mb: 1 }}>
                    Prix
                  </Typography>
                  <Typography
                    sx={{
                      color: TEXT_WHITE,
                      fontFamily: '"JetBrains Mono", monospace',
                      fontWeight: 700,
                      fontSize: '1.5rem',
                      mb: 1,
                    }}
                  >
                    {formatPrice(selectedRepair.totalPrice)}
                  </Typography>
                  <Chip
                    label={selectedRepair.isPaid ? 'Payé' : 'En attente de paiement'}
                    icon={selectedRepair.isPaid ? <CheckCircleIcon /> : <ReceiptIcon />}
                    sx={{
                      backgroundColor: selectedRepair.isPaid ? 'rgba(34, 197, 94, 0.15)' : 'rgba(245, 158, 11, 0.15)',
                      color: selectedRepair.isPaid ? '#22c55e' : '#f59e0b',
                      border: `1px solid ${selectedRepair.isPaid ? 'rgba(34, 197, 94, 0.25)' : 'rgba(245, 158, 11, 0.25)'}`,
                      '& .MuiChip-icon': { color: 'inherit' },
                    }}
                  />
                </Grid>

                <Grid item xs={12} md={6}>
                  <Typography sx={{ color: GOLD, fontFamily: '"Outfit", sans-serif', fontWeight: 600, mb: 1 }}>
                    Dates importantes
                  </Typography>
                  <Typography sx={{ color: TEXT_LIGHT, fontSize: '0.9rem', mb: 0.5 }}>
                    Créée le : {formatDate(selectedRepair.createdAt)}
                  </Typography>
                  {selectedRepair.startDate && (
                    <Typography sx={{ color: TEXT_LIGHT, fontSize: '0.9rem', mb: 0.5 }}>
                      Début : {formatDate(selectedRepair.startDate)}
                    </Typography>
                  )}
                  {selectedRepair.endDate && (
                    <Typography sx={{ color: TEXT_LIGHT, fontSize: '0.9rem' }}>
                      Fin : {formatDate(selectedRepair.endDate)}
                    </Typography>
                  )}
                </Grid>

                {selectedRepair.notes && (
                  <Grid item xs={12}>
                    <Typography sx={{ color: GOLD, fontFamily: '"Outfit", sans-serif', fontWeight: 600, mb: 1 }}>
                      Notes du technicien
                    </Typography>
                    <Box
                      sx={{
                        p: 2,
                        borderRadius: '12px',
                        background: 'rgba(15, 23, 42, 0.5)',
                        border: `1px solid ${GLASS_BORDER}`,
                      }}
                    >
                      <Typography sx={{ color: TEXT_LIGHT, fontSize: '0.9rem', fontStyle: 'italic' }}>
                        {selectedRepair.notes}
                      </Typography>
                    </Box>
                  </Grid>
                )}
              </Grid>
            )}
          </DialogContent>
          <DialogActions sx={{ borderTop: `1px solid ${GLASS_BORDER}`, p: 2 }}>
            <Button
              onClick={() => setDialogOpen(false)}
              sx={{
                color: TEXT_MUTED,
                fontFamily: '"Inter", sans-serif',
                textTransform: 'none',
                borderRadius: '10px',
                px: 3,
                '&:hover': { color: GOLD, backgroundColor: GOLD_SUBTLE },
              }}
            >
              Fermer
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </Box>
  );
};

export default RepairHistory;

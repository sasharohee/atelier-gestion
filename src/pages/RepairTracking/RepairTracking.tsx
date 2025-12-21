import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Alert,
  Chip,
  Grid,
  CircularProgress,
  InputAdornment,
  Fade,
  Grow,
  Zoom,
} from '@mui/material';
import {
  Search as SearchIcon,
  Home as HomeIcon,
  Build as BuildIcon,
  Email as EmailIcon,
  Refresh as RefreshIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  LocalShipping as ShippingIcon,
  Settings as SettingsIcon,
  NewReleases as NewIcon,
  Cancel as CancelIcon,
  Undo as UndoIcon,
  Inventory as InventoryIcon,
  Smartphone as SmartphoneIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  CalendarToday as CalendarIcon,
  Engineering as TechnicianIcon,
  Euro as EuroIcon,
  Description as DescriptionIcon,
  ReportProblem as IssueIcon,
} from '@mui/icons-material';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { repairTrackingService } from '../../services/repairTrackingService';

interface RepairData {
  id: string;
  repairNumber: string;
  status: string;
  description: string;
  issue: string;
  totalPrice: number;
  dueDate: string;
  createdAt: string;
  client: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
  };
  device: {
    brand: string;
    model: string;
    serialNumber?: string | null;
    type: string;
  } | null;
  technician?: {
    firstName: string;
    lastName: string;
  } | null;
}

// Styles CSS personnalisés - Thème clair
const styles = {
  pageContainer: {
    minHeight: '100vh',
    background: `
      radial-gradient(ellipse at 20% 0%, rgba(99, 102, 241, 0.08) 0%, transparent 50%),
      radial-gradient(ellipse at 80% 100%, rgba(236, 72, 153, 0.06) 0%, transparent 50%),
      radial-gradient(ellipse at 50% 50%, rgba(59, 130, 246, 0.04) 0%, transparent 70%),
      linear-gradient(180deg, #f8fafc 0%, #f1f5f9 50%, #e2e8f0 100%)
    `,
    py: 4,
    px: 2,
  },
  glassCard: {
    background: 'rgba(255, 255, 255, 0.85)',
    backdropFilter: 'blur(20px)',
    borderRadius: 4,
    border: '1px solid rgba(255, 255, 255, 0.9)',
    boxShadow: '0 4px 30px rgba(0, 0, 0, 0.08), 0 1px 3px rgba(0, 0, 0, 0.05)',
    overflow: 'hidden',
    position: 'relative' as const,
    '&::before': {
      content: '""',
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      height: '1px',
      background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.8), transparent)',
    },
  },
  inputField: {
    '& .MuiOutlinedInput-root': {
      backgroundColor: '#fff',
      borderRadius: 3,
      transition: 'all 0.3s ease',
      '& fieldset': {
        borderColor: '#e2e8f0',
        transition: 'all 0.3s ease',
      },
      '&:hover fieldset': {
        borderColor: '#a5b4fc',
      },
      '&.Mui-focused fieldset': {
        borderColor: '#6366f1',
        boxShadow: '0 0 0 3px rgba(99, 102, 241, 0.1)',
      },
    },
    '& .MuiInputLabel-root': {
      color: '#64748b',
    },
    '& .MuiInputLabel-root.Mui-focused': {
      color: '#6366f1',
    },
    '& input': {
      color: '#1e293b',
    },
    '& .MuiInputAdornment-root svg': {
      color: '#6366f1',
    },
  },
  searchButton: {
    background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
    borderRadius: 3,
    px: 4,
    py: 1.5,
    fontWeight: 600,
    textTransform: 'none' as const,
    letterSpacing: 0.5,
    color: '#fff',
    boxShadow: '0 4px 14px rgba(99, 102, 241, 0.35)',
    transition: 'all 0.3s ease',
    '&:hover': {
      transform: 'translateY(-2px)',
      boxShadow: '0 6px 20px rgba(99, 102, 241, 0.45)',
      background: 'linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)',
    },
    '&:disabled': {
      background: '#e2e8f0',
      color: '#94a3b8',
      boxShadow: 'none',
    },
  },
  resetButton: {
    borderColor: '#e2e8f0',
    color: '#64748b',
    borderRadius: 3,
    px: 3,
    py: 1.5,
    textTransform: 'none' as const,
    transition: 'all 0.3s ease',
    '&:hover': {
      borderColor: '#f43f5e',
      backgroundColor: 'rgba(244, 63, 94, 0.05)',
      color: '#f43f5e',
    },
  },
  homeButton: {
    borderColor: '#e2e8f0',
    color: '#64748b',
    borderRadius: 3,
    px: 2.5,
    py: 1,
    textTransform: 'none' as const,
    background: 'rgba(255, 255, 255, 0.8)',
    transition: 'all 0.3s ease',
    '&:hover': {
      borderColor: '#6366f1',
      backgroundColor: 'rgba(99, 102, 241, 0.05)',
      color: '#6366f1',
    },
  },
  infoCard: {
    background: '#fff',
    borderRadius: 3,
    p: 2.5,
    border: '1px solid #f1f5f9',
    height: '100%',
    transition: 'all 0.3s ease',
    '&:hover': {
      boxShadow: '0 4px 20px rgba(0, 0, 0, 0.06)',
      border: '1px solid #e0e7ff',
      transform: 'translateY(-2px)',
    },
  },
  infoRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 1.5,
    py: 1.25,
    borderBottom: '1px solid #f1f5f9',
    '&:last-child': {
      borderBottom: 'none',
    },
  },
  infoIcon: {
    width: 36,
    height: 36,
    borderRadius: 2.5,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  statusTimeline: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 1,
    flexWrap: 'wrap' as const,
    py: 2,
  },
  timelineStep: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    gap: 1,
    position: 'relative' as const,
    flex: 1,
    minWidth: 80,
  },
};

// Configuration des statuts avec icônes et couleurs
const statusConfig = {
  new: { 
    icon: NewIcon, 
    color: '#3b82f6', 
    bgColor: 'rgba(59, 130, 246, 0.1)',
    label: 'Nouvelle',
    order: 0
  },
  in_progress: { 
    icon: SettingsIcon, 
    color: '#6366f1', 
    bgColor: 'rgba(99, 102, 241, 0.1)',
    label: 'En cours',
    order: 1
  },
  waiting_parts: { 
    icon: InventoryIcon, 
    color: '#f59e0b', 
    bgColor: 'rgba(245, 158, 11, 0.1)',
    label: 'En attente de pièces',
    order: 2
  },
  waiting_delivery: { 
    icon: ShippingIcon, 
    color: '#8b5cf6', 
    bgColor: 'rgba(139, 92, 246, 0.1)',
    label: 'Prêt à livrer',
    order: 3
  },
  completed: { 
    icon: CheckCircleIcon, 
    color: '#10b981', 
    bgColor: 'rgba(16, 185, 129, 0.1)',
    label: 'Terminée',
    order: 4
  },
  delivered: { 
    icon: CheckCircleIcon, 
    color: '#059669', 
    bgColor: 'rgba(5, 150, 105, 0.1)',
    label: 'Livrée',
    order: 5
  },
  cancelled: { 
    icon: CancelIcon, 
    color: '#ef4444', 
    bgColor: 'rgba(239, 68, 68, 0.1)',
    label: 'Annulée',
    order: -1
  },
  returned: { 
    icon: UndoIcon, 
    color: '#64748b', 
    bgColor: 'rgba(100, 116, 139, 0.1)',
    label: 'Retournée',
    order: -1
  },
};

// Timeline simplifiée pour l'affichage
const timelineSteps = ['new', 'in_progress', 'waiting_parts', 'waiting_delivery', 'completed'];

const RepairTracking: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [email, setEmail] = useState('');
  const [repairNumber, setRepairNumber] = useState('');
  const [repair, setRepair] = useState<RepairData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [autoSearchDone, setAutoSearchDone] = useState(false);

  const getStatusConfig = (status: string) => {
    return statusConfig[status as keyof typeof statusConfig] || statusConfig.new;
  };

  const getStatusOrder = (status: string): number => {
    return getStatusConfig(status).order;
  };

  const handleSearch = async (searchEmail?: string, searchRepairNumber?: string) => {
    const currentEmail = searchEmail || email || searchParams.get('email') || '';
    const currentRepairNumber = searchRepairNumber || repairNumber || searchParams.get('repairNumber') || '';

    if (!currentEmail || !currentRepairNumber) {
      setError('Veuillez remplir tous les champs');
      return;
    }

    setLoading(true);
    setError('');
    setRepair(null);

    try {
      const result = await repairTrackingService.getRepairTracking(currentRepairNumber, currentEmail);
      if (result) {
        setRepair(result);
      } else {
        setError('Aucune réparation trouvée avec ces informations');
      }
    } catch (err: any) {
      setError(err.message || 'Erreur lors de la recherche');
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setEmail('');
    setRepairNumber('');
    setRepair(null);
    setError('');
    setAutoSearchDone(false);
  };

  // Lire les paramètres URL au chargement et lancer la recherche automatique
  useEffect(() => {
    const urlEmail = searchParams.get('email');
    const urlRepairNumber = searchParams.get('repairNumber');

    if (urlEmail && urlRepairNumber && !autoSearchDone) {
      setEmail(urlEmail);
      setRepairNumber(urlRepairNumber);
      setAutoSearchDone(true);
      // Lancer directement la recherche avec les paramètres URL
      handleSearch(urlEmail, urlRepairNumber);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams]);

  const currentStatusOrder = repair ? getStatusOrder(repair.status) : -1;
  const config = repair ? getStatusConfig(repair.status) : null;
  const StatusIcon = config?.icon || NewIcon;

  return (
    <Box sx={styles.pageContainer}>
      <Box sx={{ maxWidth: 900, mx: 'auto' }}>
        {/* Header */}
        <Fade in timeout={600}>
          <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
            <Box>
              <Typography 
                variant="h3" 
                component="h1" 
                sx={{ 
                  fontFamily: '"Outfit", "Poppins", sans-serif',
                  fontWeight: 700,
                  color: '#1e293b',
                  letterSpacing: '-0.5px',
                  mb: 0.5,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1.5
                }}
              >
                <Box
                  sx={{
                    width: 52,
                    height: 52,
                    borderRadius: 3,
                    background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 14px rgba(99, 102, 241, 0.35)',
                    color: '#fff',
                  }}
                >
                  <SearchIcon sx={{ fontSize: 28 }} />
                </Box>
                Suivi de Réparation
              </Typography>
              <Typography 
                variant="body1" 
                sx={{ 
                  color: '#64748b',
                  fontFamily: '"Inter", sans-serif',
                  pl: 8.5
                }}
              >
                Suivez l'avancement de votre réparation en temps réel
              </Typography>
            </Box>
            <Button
              variant="outlined"
              startIcon={<HomeIcon />}
              onClick={() => navigate('/')}
              sx={styles.homeButton}
            >
              Accueil
            </Button>
          </Box>
        </Fade>

        {/* Search Card */}
        <Grow in timeout={800}>
          <Card sx={styles.glassCard}>
            <CardContent sx={{ p: 4 }}>
              <Typography 
                variant="h5" 
                sx={{ 
                  color: '#1e293b',
                  fontFamily: '"Outfit", sans-serif',
                  fontWeight: 600,
                  mb: 3,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1.5
                }}
              >
                <Box
                  sx={{
                    width: 40,
                    height: 40,
                    borderRadius: 2.5,
                    background: 'rgba(99, 102, 241, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <BuildIcon sx={{ color: '#6366f1', fontSize: 22 }} />
                </Box>
                Rechercher votre réparation
              </Typography>
              
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Adresse email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="votre@email.com"
                    sx={styles.inputField}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <EmailIcon />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Numéro de réparation"
                    value={repairNumber}
                    onChange={(e) => setRepairNumber(e.target.value)}
                    placeholder="REP-YYYYMMDD-XXXX"
                    sx={styles.inputField}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <BuildIcon />
                        </InputAdornment>
                      ),
                    }}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && email && repairNumber) {
                        handleSearch();
                      }
                    }}
                  />
                </Grid>
              </Grid>

              <Box sx={{ mt: 4, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                <Button
                  variant="contained"
                  startIcon={loading ? <CircularProgress size={20} sx={{ color: '#fff' }} /> : <SearchIcon />}
                  onClick={handleSearch}
                  disabled={loading || !email || !repairNumber}
                  sx={styles.searchButton}
                >
                  {loading ? 'Recherche...' : 'Rechercher'}
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<RefreshIcon />}
                  onClick={handleReset}
                  disabled={loading}
                  sx={styles.resetButton}
                >
                  Réinitialiser
                </Button>
              </Box>

              {error && (
                <Fade in>
                  <Alert 
                    severity="error" 
                    sx={{ 
                      mt: 3,
                      backgroundColor: 'rgba(239, 68, 68, 0.08)',
                      color: '#dc2626',
                      border: '1px solid rgba(239, 68, 68, 0.2)',
                      borderRadius: 2.5,
                      '& .MuiAlert-icon': {
                        color: '#ef4444'
                      }
                    }}
                  >
                    {error}
                  </Alert>
                </Fade>
              )}
            </CardContent>
          </Card>
        </Grow>

        {/* Results */}
        {repair && (
          <Fade in timeout={600}>
            <Box sx={{ mt: 4 }}>
              {/* Status Card */}
              <Card sx={{ ...styles.glassCard, mb: 3 }}>
                <CardContent sx={{ p: 4 }}>
                  {/* Repair Number & Status Badge */}
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4, flexWrap: 'wrap', gap: 2 }}>
                    <Box>
                      <Typography 
                        variant="overline" 
                        sx={{ 
                          color: '#94a3b8', 
                          letterSpacing: 2,
                          fontSize: '0.75rem'
                        }}
                      >
                        Numéro de réparation
                      </Typography>
                      <Typography 
                        variant="h4" 
                        sx={{ 
                          color: '#1e293b',
                          fontFamily: '"JetBrains Mono", monospace',
                          fontWeight: 600,
                          letterSpacing: 1
                        }}
                      >
                        {repair.repairNumber}
                      </Typography>
                    </Box>
                    <Zoom in timeout={500}>
                      <Chip
                        icon={<StatusIcon sx={{ color: config?.color + ' !important' }} />}
                        label={config?.label}
                        sx={{
                          backgroundColor: config?.bgColor,
                          color: config?.color,
                          fontWeight: 600,
                          fontSize: '0.95rem',
                          px: 2,
                          py: 3,
                          borderRadius: 3,
                          border: `1px solid ${config?.color}25`,
                          '& .MuiChip-icon': {
                            fontSize: 22,
                          },
                        }}
                      />
                    </Zoom>
                  </Box>

                  {/* Status Timeline */}
                  {currentStatusOrder >= 0 && (
                    <Box sx={{ 
                      background: '#f8fafc', 
                      borderRadius: 3, 
                      p: 3,
                      mb: 2,
                      border: '1px solid #f1f5f9'
                    }}>
                      <Typography 
                        variant="subtitle2" 
                        sx={{ 
                          color: '#94a3b8', 
                          mb: 3,
                          textAlign: 'center',
                          textTransform: 'uppercase',
                          letterSpacing: 2,
                          fontSize: '0.7rem'
                        }}
                      >
                        Progression de la réparation
                      </Typography>
                      <Box sx={styles.statusTimeline}>
                        {timelineSteps.map((step, index) => {
                          const stepConfig = statusConfig[step as keyof typeof statusConfig];
                          const StepIcon = stepConfig.icon;
                          const isActive = currentStatusOrder >= stepConfig.order;
                          const isCurrent = repair.status === step;
                          
                          return (
                            <React.Fragment key={step}>
                              <Box sx={styles.timelineStep}>
                                <Box
                                  sx={{
                                    width: isCurrent ? 56 : 48,
                                    height: isCurrent ? 56 : 48,
                                    borderRadius: '50%',
                                    backgroundColor: isActive ? stepConfig.bgColor : '#f1f5f9',
                                    border: `2px solid ${isActive ? stepConfig.color : '#e2e8f0'}`,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    transition: 'all 0.3s ease',
                                    boxShadow: isCurrent ? `0 0 0 4px ${stepConfig.color}20, 0 4px 12px ${stepConfig.color}30` : 'none',
                                    animation: isCurrent ? 'pulse 2s infinite' : 'none',
                                    '@keyframes pulse': {
                                      '0%': { boxShadow: `0 0 0 0 ${stepConfig.color}30` },
                                      '70%': { boxShadow: `0 0 0 8px ${stepConfig.color}00` },
                                      '100%': { boxShadow: `0 0 0 0 ${stepConfig.color}00` },
                                    },
                                  }}
                                >
                                  <StepIcon 
                                    sx={{ 
                                      color: isActive ? stepConfig.color : '#cbd5e1',
                                      fontSize: isCurrent ? 28 : 24,
                                      transition: 'all 0.3s ease',
                                    }} 
                                  />
                                </Box>
                                <Typography
                                  variant="caption"
                                  sx={{
                                    color: isActive ? stepConfig.color : '#94a3b8',
                                    textAlign: 'center',
                                    fontWeight: isCurrent ? 600 : 400,
                                    fontSize: '0.7rem',
                                    maxWidth: 70,
                                    lineHeight: 1.2,
                                  }}
                                >
                                  {stepConfig.label}
                                </Typography>
                              </Box>
                              {index < timelineSteps.length - 1 && (
                                <Box
                                  sx={{
                                    flex: 1,
                                    height: 4,
                                    backgroundColor: '#e2e8f0',
                                    borderRadius: 2,
                                    position: 'relative',
                                    minWidth: 20,
                                    maxWidth: 60,
                                    overflow: 'hidden',
                                    mt: -3,
                                  }}
                                >
                                  <Box
                                    sx={{
                                      position: 'absolute',
                                      left: 0,
                                      top: 0,
                                      height: '100%',
                                      width: currentStatusOrder > statusConfig[step as keyof typeof statusConfig].order ? '100%' : '0%',
                                      background: `linear-gradient(90deg, ${stepConfig.color}, ${statusConfig[timelineSteps[index + 1] as keyof typeof statusConfig].color})`,
                                      borderRadius: 2,
                                      transition: 'width 0.5s ease',
                                    }}
                                  />
                                </Box>
                              )}
                            </React.Fragment>
                          );
                        })}
                      </Box>
                    </Box>
                  )}
                </CardContent>
              </Card>

              {/* Details Grid */}
              <Grid container spacing={3}>
                {/* General Info */}
                <Grid item xs={12} md={6}>
                  <Card sx={styles.glassCard}>
                    <CardContent sx={{ p: 3 }}>
                      <Typography 
                        variant="h6" 
                        sx={{ 
                          color: '#1e293b',
                          fontFamily: '"Outfit", sans-serif',
                          fontWeight: 600,
                          mb: 2.5,
                          display: 'flex',
                          alignItems: 'center',
                          gap: 1.5
                        }}
                      >
                        <Box sx={{ ...styles.infoIcon, background: 'rgba(99, 102, 241, 0.1)' }}>
                          <DescriptionIcon sx={{ color: '#6366f1', fontSize: 20 }} />
                        </Box>
                        Informations générales
                      </Typography>
                      <Box sx={styles.infoCard}>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(16, 185, 129, 0.1)' }}>
                            <EuroIcon sx={{ color: '#10b981', fontSize: 20 }} />
                          </Box>
                          <Box>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Prix estimé</Typography>
                            <Typography sx={{ color: '#10b981', fontWeight: 600, fontFamily: '"JetBrains Mono", monospace', fontSize: '1.1rem' }}>
                              {repair.totalPrice.toFixed(2)} €
                            </Typography>
                          </Box>
                        </Box>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(99, 102, 241, 0.1)' }}>
                            <DescriptionIcon sx={{ color: '#6366f1', fontSize: 20 }} />
                          </Box>
                          <Box sx={{ flex: 1 }}>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Description</Typography>
                            <Typography sx={{ color: '#334155', fontSize: '0.9rem' }}>
                              {repair.description || 'Non spécifiée'}
                            </Typography>
                          </Box>
                        </Box>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(245, 158, 11, 0.1)' }}>
                            <IssueIcon sx={{ color: '#f59e0b', fontSize: 20 }} />
                          </Box>
                          <Box sx={{ flex: 1 }}>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Problème signalé</Typography>
                            <Typography sx={{ color: '#334155', fontSize: '0.9rem' }}>
                              {repair.issue || 'Non spécifié'}
                            </Typography>
                          </Box>
                        </Box>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                {/* Device Info */}
                <Grid item xs={12} md={6}>
                  <Card sx={styles.glassCard}>
                    <CardContent sx={{ p: 3 }}>
                      <Typography 
                        variant="h6" 
                        sx={{ 
                          color: '#1e293b',
                          fontFamily: '"Outfit", sans-serif',
                          fontWeight: 600,
                          mb: 2.5,
                          display: 'flex',
                          alignItems: 'center',
                          gap: 1.5
                        }}
                      >
                        <Box sx={{ ...styles.infoIcon, background: 'rgba(59, 130, 246, 0.1)' }}>
                          <SmartphoneIcon sx={{ color: '#3b82f6', fontSize: 20 }} />
                        </Box>
                        Appareil
                      </Typography>
                      <Box sx={styles.infoCard}>
                        {repair.device ? (
                          <>
                            <Box sx={styles.infoRow}>
                              <Typography variant="caption" sx={{ color: '#94a3b8', width: 80 }}>Marque</Typography>
                              <Typography sx={{ color: '#1e293b', fontWeight: 500 }}>
                                {repair.device.brand}
                              </Typography>
                            </Box>
                            <Box sx={styles.infoRow}>
                              <Typography variant="caption" sx={{ color: '#94a3b8', width: 80 }}>Modèle</Typography>
                              <Typography sx={{ color: '#1e293b', fontWeight: 500 }}>
                                {repair.device.model}
                              </Typography>
                            </Box>
                            <Box sx={styles.infoRow}>
                              <Typography variant="caption" sx={{ color: '#94a3b8', width: 80 }}>Type</Typography>
                              <Chip
                                label={repair.device.type}
                                size="small"
                                sx={{
                                  backgroundColor: 'rgba(59, 130, 246, 0.1)',
                                  color: '#3b82f6',
                                  fontWeight: 500,
                                  fontSize: '0.75rem',
                                }}
                              />
                            </Box>
                            {repair.device.serialNumber && (
                              <Box sx={styles.infoRow}>
                                <Typography variant="caption" sx={{ color: '#94a3b8', width: 80 }}>N° Série</Typography>
                                <Typography sx={{ 
                                  color: '#64748b', 
                                  fontFamily: '"JetBrains Mono", monospace',
                                  fontSize: '0.85rem'
                                }}>
                                  {repair.device.serialNumber}
                                </Typography>
                              </Box>
                            )}
                          </>
                        ) : (
                          <Box sx={{ py: 3, textAlign: 'center' }}>
                            <SmartphoneIcon sx={{ color: '#cbd5e1', fontSize: 44, mb: 1 }} />
                            <Typography sx={{ color: '#94a3b8' }}>
                              Aucune information d'appareil disponible
                            </Typography>
                          </Box>
                        )}
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                {/* Client Info */}
                <Grid item xs={12} md={6}>
                  <Card sx={styles.glassCard}>
                    <CardContent sx={{ p: 3 }}>
                      <Typography 
                        variant="h6" 
                        sx={{ 
                          color: '#1e293b',
                          fontFamily: '"Outfit", sans-serif',
                          fontWeight: 600,
                          mb: 2.5,
                          display: 'flex',
                          alignItems: 'center',
                          gap: 1.5
                        }}
                      >
                        <Box sx={{ ...styles.infoIcon, background: 'rgba(139, 92, 246, 0.1)' }}>
                          <PersonIcon sx={{ color: '#8b5cf6', fontSize: 20 }} />
                        </Box>
                        Vos informations
                      </Typography>
                      <Box sx={styles.infoCard}>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(139, 92, 246, 0.1)' }}>
                            <PersonIcon sx={{ color: '#8b5cf6', fontSize: 20 }} />
                          </Box>
                          <Box>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Nom complet</Typography>
                            <Typography sx={{ color: '#1e293b', fontWeight: 500 }}>
                              {repair.client.firstName} {repair.client.lastName}
                            </Typography>
                          </Box>
                        </Box>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(99, 102, 241, 0.1)' }}>
                            <EmailIcon sx={{ color: '#6366f1', fontSize: 20 }} />
                          </Box>
                          <Box>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Email</Typography>
                            <Typography sx={{ color: '#334155', fontSize: '0.9rem' }}>
                              {repair.client.email}
                            </Typography>
                          </Box>
                        </Box>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(59, 130, 246, 0.1)' }}>
                            <PhoneIcon sx={{ color: '#3b82f6', fontSize: 20 }} />
                          </Box>
                          <Box>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Téléphone</Typography>
                            <Typography sx={{ color: '#334155' }}>
                              {repair.client.phone || 'Non renseigné'}
                            </Typography>
                          </Box>
                        </Box>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                {/* Dates & Technician */}
                <Grid item xs={12} md={6}>
                  <Card sx={styles.glassCard}>
                    <CardContent sx={{ p: 3 }}>
                      <Typography 
                        variant="h6" 
                        sx={{ 
                          color: '#1e293b',
                          fontFamily: '"Outfit", sans-serif',
                          fontWeight: 600,
                          mb: 2.5,
                          display: 'flex',
                          alignItems: 'center',
                          gap: 1.5
                        }}
                      >
                        <Box sx={{ ...styles.infoIcon, background: 'rgba(16, 185, 129, 0.1)' }}>
                          <CalendarIcon sx={{ color: '#10b981', fontSize: 20 }} />
                        </Box>
                        Dates & Technicien
                      </Typography>
                      <Box sx={styles.infoCard}>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(99, 102, 241, 0.1)' }}>
                            <CalendarIcon sx={{ color: '#6366f1', fontSize: 20 }} />
                          </Box>
                          <Box>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Date de dépôt</Typography>
                            <Typography sx={{ color: '#1e293b', fontWeight: 500 }}>
                              {format(new Date(repair.createdAt), 'dd MMMM yyyy', { locale: fr })}
                            </Typography>
                          </Box>
                        </Box>
                        <Box sx={styles.infoRow}>
                          <Box sx={{ ...styles.infoIcon, background: 'rgba(245, 158, 11, 0.1)' }}>
                            <ScheduleIcon sx={{ color: '#f59e0b', fontSize: 20 }} />
                          </Box>
                          <Box>
                            <Typography variant="caption" sx={{ color: '#94a3b8' }}>Date limite estimée</Typography>
                            <Typography sx={{ color: '#f59e0b', fontWeight: 600 }}>
                              {format(new Date(repair.dueDate), 'dd MMMM yyyy', { locale: fr })}
                            </Typography>
                          </Box>
                        </Box>
                        {repair.technician && (
                          <Box sx={styles.infoRow}>
                            <Box sx={{ ...styles.infoIcon, background: 'rgba(16, 185, 129, 0.1)' }}>
                              <TechnicianIcon sx={{ color: '#10b981', fontSize: 20 }} />
                            </Box>
                            <Box>
                              <Typography variant="caption" sx={{ color: '#94a3b8' }}>Technicien assigné</Typography>
                              <Typography sx={{ color: '#10b981', fontWeight: 500 }}>
                                {repair.technician.firstName} {repair.technician.lastName}
                              </Typography>
                            </Box>
                          </Box>
                        )}
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>

              {/* Footer message */}
              <Box 
                sx={{ 
                  mt: 4, 
                  p: 3, 
                  borderRadius: 3,
                  background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.08) 0%, rgba(139, 92, 246, 0.08) 100%)',
                  border: '1px solid rgba(99, 102, 241, 0.15)',
                  textAlign: 'center'
                }}
              >
                <Typography sx={{ color: '#6366f1', fontSize: '0.95rem', fontWeight: 500 }}>
                  💡 Vous recevrez un email à chaque mise à jour du statut de votre réparation.
                </Typography>
              </Box>
            </Box>
          </Fade>
        )}

        {/* Empty state when no search */}
        {!repair && !loading && !error && (
          <Fade in timeout={1000}>
            <Box 
              sx={{ 
                mt: 6, 
                textAlign: 'center',
                py: 6,
              }}
            >
              <Box
                sx={{
                  width: 100,
                  height: 100,
                  borderRadius: '50%',
                  background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.1) 0%, rgba(139, 92, 246, 0.1) 100%)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mx: 'auto',
                  mb: 3,
                  border: '1px solid rgba(99, 102, 241, 0.15)',
                }}
              >
                <SearchIcon sx={{ fontSize: 50, color: '#6366f1' }} />
              </Box>
              <Typography 
                variant="h6" 
                sx={{ 
                  color: '#475569',
                  fontFamily: '"Outfit", sans-serif',
                  mb: 1
                }}
              >
                Entrez vos informations ci-dessus
              </Typography>
              <Typography 
                sx={{ 
                  color: '#94a3b8',
                  maxWidth: 400,
                  mx: 'auto'
                }}
              >
                Utilisez l'email et le numéro de réparation reçus lors du dépôt de votre appareil
              </Typography>
            </Box>
          </Fade>
        )}
      </Box>
    </Box>
  );
};

export default RepairTracking;

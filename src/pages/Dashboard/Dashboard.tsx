import React, { useState, useEffect, useMemo } from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Button,
  LinearProgress,
  Divider,
  Alert,
  Badge,
} from '@mui/material';

import {
  Build as BuildIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
  Schedule as ScheduleIcon,
  TrendingUp as TrendingUpIcon,
  Inventory as InventoryIcon,
  Message as MessageIcon,
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
  NewReleases as NewReleasesIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { deviceTypeColors, repairStatusColors } from '../../theme';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';
// import AppStatus from '../../components/AppStatus'; // MASQUÉ
// import SupabaseTest from '../../components/SupabaseTest'; // MASQUÉ
import { demoDataService } from '../../services/demoDataService';
import WhatsNewButton from '../../components/WhatsNewButton';
import { whatsNewItems } from '../../config/whatsNew';

// Styles CSS pour les animations
const pulseAnimation = `
  @keyframes pulse {
    0% {
      opacity: 1;
      transform: scale(1);
    }
    50% {
      opacity: 0.5;
      transform: scale(1.1);
    }
    100% {
      opacity: 1;
      transform: scale(1);
    }
  }
`;

const Dashboard: React.FC = () => {
  const [hasError, setHasError] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [unreadNewsCount, setUnreadNewsCount] = useState(0);
  
  // Ajouter les styles CSS pour l'animation
  useEffect(() => {
    const style = document.createElement('style');
    style.textContent = pulseAnimation;
    document.head.appendChild(style);
    
    return () => {
      document.head.removeChild(style);
    };
  }, []);

  // Calculer le nombre de nouveautés non lues
  useEffect(() => {
    const calculateUnreadCount = () => {
      try {
        const lastReadDate = localStorage.getItem('app-atelier-last-read-news');
        if (!lastReadDate) {
          setUnreadNewsCount(whatsNewItems.length);
          return;
        }

        const lastRead = new Date(lastReadDate);
        const unreadItems = whatsNewItems.filter(item => 
          new Date(item.date) > lastRead
        );
        setUnreadNewsCount(unreadItems.length);
      } catch (error) {
        console.error('Erreur lors du calcul des nouveautés non lues:', error);
        setUnreadNewsCount(0);
      }
    };

    calculateUnreadCount();
  }, []);

  const {
    dashboardStats,
    repairs,
    appointments,
    clients,
    devices,
    repairStatuses,
    getRepairsByStatus,
    getClientById,
    getDeviceById,
    loadClients,
    loadDevices,
    loadServices,
    loadParts,
    loadProducts,
    loadRepairs,
    loadSales,
    loadAppointments,
  } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';

  // Charger les données au montage du composant
  useEffect(() => {
    const loadDashboardData = async () => {
      try {
        console.log('🔄 Chargement des données du dashboard...');
        await loadRepairs();
        console.log('✅ Données des réparations chargées dans le dashboard');
      } catch (error) {
        console.error('❌ Erreur lors du chargement des données du dashboard:', error);
      }
    };
    
    loadDashboardData();
  }, [loadRepairs]);

  // Gestion d'erreur pour éviter les crashes
  useEffect(() => {
    const handleError = (event: ErrorEvent) => {
      console.error('Dashboard error:', event.error);
      setHasError(true);
      setErrorMessage(event.error?.message || 'Erreur inconnue');
    };

    window.addEventListener('error', handleError);
    return () => window.removeEventListener('error', handleError);
  }, []);

  // Données sécurisées avec fallback
  const safeRepairs = repairs || [];
  const safeAppointments = appointments || [];
  const safeClients = clients || [];
  const safeDevices = devices || [];
  const safeRepairStatuses = repairStatuses || [];

  // Surveiller les changements dans les réparations
  useEffect(() => {
    console.log('📊 Dashboard - État des réparations mis à jour:', {
      totalRepairs: safeRepairs.length,
      repairsStatuses: safeRepairs.map(r => ({ id: r.id, status: r.status, dueDate: r.dueDate }))
    });
  }, [safeRepairs]);

  const recentRepairs = safeRepairs
    .filter((repair) => {
      try {
        if (!repair.createdAt) return false;
        const date = new Date(repair.createdAt);
        return !isNaN(date.getTime());
      } catch (error) {
        console.error('Erreur de date dans la réparation:', error);
        return false;
      }
    })
    .sort((a, b) => {
      try {
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      } catch (error) {
        console.error('Erreur de tri des réparations:', error);
        return 0;
      }
    })
    .slice(0, 5);

  const todayAppointments = safeAppointments.filter((appointment) => {
    try {
      if (!appointment.startDate) return false;
      const appointmentDate = new Date(appointment.startDate);
      if (isNaN(appointmentDate.getTime())) return false;
      return format(appointmentDate, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd');
    } catch (error) {
      console.error('Erreur de date dans le rendez-vous:', error);
      return false;
    }
  });

  const getStatusColor = (status: string) => {
    return repairStatusColors[status as keyof typeof repairStatusColors] || '#757575';
  };

  const getDeviceTypeIcon = (type: string) => {
    const icons = {
      smartphone: <PhoneIcon />,
      tablet: <TabletIcon />,
      laptop: <LaptopIcon />,
      desktop: <ComputerIcon />,
      other: <ComputerIcon />,
    };
    return icons[type as keyof typeof icons] || <ComputerIcon />;
  };

  const getDeviceTypeColor = (type: string) => {
    return deviceTypeColors[type as keyof typeof deviceTypeColors] || '#757575';
  };

  // Fonction utilitaire pour sécuriser les dates
  const safeFormatDate = (date: any, formatString: string) => {
    try {
      if (!date) return 'Date inconnue';
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) return 'Date invalide';
      return format(dateObj, formatString);
    } catch (error) {
      console.error('Erreur de formatage de date:', error);
      return 'Date invalide';
    }
  };

  const StatCard: React.FC<{
    title: string;
    value: string | number;
    icon: React.ReactNode;
    color: string;
    subtitle?: string;
  }> = ({ title, value, icon, color, subtitle }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box>
            <Typography color="text.secondary" gutterBottom variant="body2">
              {title}
            </Typography>
            <Typography variant="h4" component="div" sx={{ fontWeight: 600 }}>
              {value}
            </Typography>
            {subtitle && (
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                {subtitle}
              </Typography>
            )}
          </Box>
          <Avatar
            sx={{
              backgroundColor: color,
              width: 56,
              height: 56,
            }}
          >
            {icon}
          </Avatar>
        </Box>
      </CardContent>
    </Card>
  );

  const ProgressCard: React.FC<{
    title: string;
    value: number;
    total: number;
    color: string;
  }> = ({ title, value, total, color }) => {
    const percentage = total > 0 ? (value / total) * 100 : 0;
    return (
      <Card sx={{ height: '100%' }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            {title}
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <Typography variant="h4" sx={{ fontWeight: 600, mr: 1 }}>
              {value}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              / {total}
            </Typography>
          </Box>
          <LinearProgress
            variant="determinate"
            value={percentage}
            sx={{
              height: 8,
              borderRadius: 4,
              backgroundColor: 'grey.200',
              '& .MuiLinearProgress-bar': {
                backgroundColor: color,
              },
            }}
          />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            {percentage.toFixed(1)}% complété
          </Typography>
        </CardContent>
      </Card>
    );
  };

  // Statistiques par défaut pour un atelier vide - recalculées à chaque changement
  const defaultStats = useMemo(() => {
    // Analyser chaque réparation individuellement
    const repairsAnalysis = safeRepairs.map(repair => {
      const isCompleted = repair.status === 'completed' || repair.status === 'returned';
      const hasDueDate = repair.dueDate && !isNaN(new Date(repair.dueDate).getTime());
      const isOverdue = !isCompleted && hasDueDate && new Date(repair.dueDate) < new Date();
      
      return {
        id: repair.id,
        status: repair.status,
        dueDate: repair.dueDate,
        isCompleted,
        hasDueDate,
        isOverdue,
        shouldBeCounted: isOverdue
      };
    });

    const overdueCount = repairsAnalysis.filter(repair => repair.shouldBeCounted).length;

    // Log de débogage détaillé
    console.log('🔍 Dashboard - Analyse détaillée des réparations:', {
      totalRepairs: safeRepairs.length,
      completedRepairs: repairsAnalysis.filter(r => r.isCompleted).length,
      overdueCount,
      repairsAnalysis,
      summary: {
        completed: repairsAnalysis.filter(r => r.isCompleted).length,
        overdue: overdueCount,
        noDueDate: repairsAnalysis.filter(r => !r.hasDueDate).length,
        futureDueDate: repairsAnalysis.filter(r => r.hasDueDate && !r.isCompleted && new Date(r.dueDate) >= new Date()).length
      }
    });

    // Log spécifique pour les réparations archivées
    const archivedRepairs = repairsAnalysis.filter(r => r.status === 'returned');
    if (archivedRepairs.length > 0) {
      console.log('📦 Réparations archivées (ne doivent pas être en retard):', archivedRepairs.map(r => ({
        id: r.id,
        status: r.status,
        dueDate: r.dueDate,
        isOverdue: r.isOverdue,
        shouldBeCounted: r.shouldBeCounted
      })));
    }

    // Log de vérification de cohérence
    console.log('🔍 Vérification cohérence - defaultStats.overdueRepairs:', overdueCount);
    console.log('🔍 Vérification cohérence - Toutes les réparations:', safeRepairs.map(r => ({
      id: r.id,
      status: r.status,
      dueDate: r.dueDate,
      isCompleted: r.status === 'completed' || r.status === 'returned',
      isOverdue: (r.status !== 'completed' && r.status !== 'returned') && r.dueDate && new Date(r.dueDate) < new Date()
    })));

    return {
      totalRepairs: safeRepairs.length,
      activeRepairs: safeRepairs.filter(r => r.status === 'in_progress').length,
      completedRepairs: safeRepairs.filter(r => r.status === 'completed' || r.status === 'returned').length,
      overdueRepairs: overdueCount,
      todayAppointments: todayAppointments.length,
      monthlyRevenue: 0,
      lowStockItems: 0,
      pendingMessages: 0,
    };
  }, [safeRepairs, todayAppointments]);

  if (hasError) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error" sx={{ mb: 3 }}>
          <strong>Erreur de chargement du dashboard :</strong> {errorMessage}
        </Alert>
        <Button 
          variant="contained" 
          onClick={() => window.location.reload()}
          sx={{ mr: 2 }}
        >
          Recharger la page
        </Button>
        <Button 
          variant="outlined" 
          onClick={() => setHasError(false)}
        >
          Continuer sans données
        </Button>
      </Box>
    );
  }

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Tableau de bord
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Vue d'ensemble de votre atelier - {format(new Date(), 'EEEE d MMMM yyyy', { locale: fr })}
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 1 }}>
          <Button 
            variant="outlined" 
            size="small"
            onClick={async () => {
              console.log('🔄 Rechargement forcé des données...');
              await loadRepairs();
              console.log('✅ Données rechargées');
            }}
          >
            🔄 Recharger les données
          </Button>
          <Badge
            badgeContent={unreadNewsCount}
            color="error"
            sx={{
              '& .MuiBadge-badge': {
                backgroundColor: '#ff4757',
                color: 'white',
                fontWeight: 600,
                fontSize: '0.7rem',
                minWidth: 18,
                height: 18,
                borderRadius: '50%',
                boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
              },
            }}
          >
            <Button
              variant="contained"
              size="small"
              startIcon={<NewReleasesIcon />}
              onClick={() => {
                // Ouvrir la modal des nouveautés
                const event = new CustomEvent('openWhatsNew');
                window.dispatchEvent(event);
              }}
              sx={{
                backgroundColor: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                color: 'white',
                fontWeight: 600,
                '&:hover': {
                  backgroundColor: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
                  transform: 'translateY(-1px)',
                  boxShadow: '0 4px 12px rgba(102, 126, 234, 0.4)',
                },
                transition: 'all 0.2s ease-in-out',
              }}
            >
              Nouveautés
            </Button>
          </Badge>
        </Box>
      </Box>

      {/* Statistiques principales */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Réparations actives"
            value={defaultStats.activeRepairs}
            icon={<BuildIcon />}
            color="#ff9800"
            subtitle={`${defaultStats.totalRepairs} total`}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Réparations terminées"
            value={defaultStats.completedRepairs}
            icon={<CheckCircleIcon />}
            color="#4caf50"
            subtitle="Ce mois"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Rendez-vous aujourd'hui"
            value={defaultStats.todayAppointments}
            icon={<ScheduleIcon />}
            color="#2196f3"
            subtitle="Planifiés"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Chiffre d'affaires"
            value={formatFromEUR(defaultStats.monthlyRevenue, currency)}
            icon={<TrendingUpIcon />}
            color="#9c27b0"
            subtitle="Ce mois"
          />
        </Grid>
      </Grid>

              {/* Statistiques de suivi des réparations rapides */}
      {safeRepairStatuses.length > 0 ? (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={2}>
            <StatCard
              title="Nouvelles"
              value={repairs.filter(r => r.status === 'new').length}
              icon={<BuildIcon />}
              color="#2196f3"
              subtitle="En attente"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <StatCard
              title="En cours"
              value={repairs.filter(r => r.status === 'in_progress').length}
              icon={<BuildIcon />}
              color="#ff9800"
              subtitle="En traitement"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <StatCard
              title="En attente"
              value={repairs.filter(r => r.status === 'waiting_parts').length}
              icon={<InventoryIcon />}
              color="#f44336"
              subtitle="Pièces manquantes"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <StatCard
              title="Livraison"
              value={repairs.filter(r => r.status === 'waiting_delivery').length}
              icon={<ScheduleIcon />}
              color="#9c27b0"
              subtitle="À livrer"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <StatCard
              title="Terminées"
              value={repairs.filter(r => r.status === 'completed' || r.status === 'returned').length}
              icon={<CheckCircleIcon />}
              color="#4caf50"
              subtitle="Ce mois"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <StatCard
              title="Urgentes"
              value={repairs.filter(r => r.isUrgent).length}
              icon={<WarningIcon />}
              color="#f44336"
              subtitle="Priorité haute"
            />
          </Grid>
        </Grid>
      ) : (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body2" color="text.secondary">
                    Chargement des statistiques de suivi des réparations...
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Progression et alertes */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={6}>
          <ProgressCard
            title="Progression des réparations"
            value={defaultStats.completedRepairs}
            total={defaultStats.totalRepairs}
            color="#4caf50"
          />
        </Grid>
        <Grid item xs={12} md={6}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Alertes
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <WarningIcon color="error" sx={{ mr: 1 }} />
                    <Typography variant="body2" component="span">Réparations en retard</Typography>
                  </Box>
                  <Chip label={defaultStats.overdueRepairs} color="error" size="small" />
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <InventoryIcon color="warning" sx={{ mr: 1 }} />
                    <Typography variant="body2" component="span">Stock faible</Typography>
                  </Box>
                  <Chip label={defaultStats.lowStockItems} color="warning" size="small" />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

              {/* État du suivi des réparations - Vue d'ensemble des étapes */}
      {safeRepairStatuses.length > 0 ? (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    État du suivi des réparations - Vue d'ensemble
                  </Typography>
                  <Button 
                    variant="outlined" 
                    size="small"
                    onClick={() => window.location.href = '/kanban'}
                  >
                                          Voir le suivi des réparations
                  </Button>
                </Box>
              
              <Grid container spacing={2}>
                {safeRepairStatuses
                  .sort((a, b) => a.order - b.order)
                  .map((status) => {
                    const statusRepairs = repairs.filter(repair => repair.status === status.id);
                    // Utiliser la même logique que dans defaultStats pour la cohérence
                    const overdueRepairs = statusRepairs.filter(repair => {
                      const isCompleted = repair.status === 'completed' || repair.status === 'returned';
                      const hasDueDate = repair.dueDate && !isNaN(new Date(repair.dueDate).getTime());
                      const isOverdue = !isCompleted && hasDueDate && new Date(repair.dueDate) < new Date();
                      return isOverdue;
                    }).length;
                    
                    return (
                      <Grid item xs={12} sm={6} md={4} lg={2} key={status.id}>
                        <Box
                          sx={{
                            p: 2,
                            border: '1px solid',
                            borderColor: 'divider',
                            borderRadius: 2,
                            backgroundColor: statusRepairs.length > 0 ? 'background.paper' : 'grey.50',
                            position: 'relative',
                            '&:hover': {
                              boxShadow: 2,
                              cursor: 'pointer',
                            },
                          }}
                          onClick={() => window.location.href = '/app/kanban'}
                        >
                          {/* Indicateur de retard */}
                          {overdueRepairs > 0 && (
                            <Box
                              sx={{
                                position: 'absolute',
                                top: -8,
                                right: -8,
                                backgroundColor: 'error.main',
                                color: 'white',
                                borderRadius: '50%',
                                width: 24,
                                height: 24,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                fontSize: '0.75rem',
                                fontWeight: 'bold',
                              }}
                            >
                              {overdueRepairs}
                            </Box>
                          )}
                          
                          <Box sx={{ textAlign: 'center' }}>
                            <Box
                              sx={{
                                width: 40,
                                height: 40,
                                borderRadius: '50%',
                                backgroundColor: status.color,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                margin: '0 auto 8px',
                                color: 'white',
                                fontWeight: 'bold',
                              }}
                            >
                              {statusRepairs.length}
                            </Box>
                            <Typography variant="body2" sx={{ fontWeight: 600, mb: 1 }}>
                              {status.name}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {statusRepairs.length === 0 
                                ? 'Aucune réparation' 
                                : statusRepairs.length === 1 
                                  ? '1 réparation' 
                                  : `${statusRepairs.length} réparations`
                              }
                            </Typography>
                          </Box>
                        </Box>
                      </Grid>
                    );
                  })}
              </Grid>
              
              {/* Résumé des priorités */}
              <Box sx={{ mt: 3, p: 2, backgroundColor: 'grey.50', borderRadius: 1 }}>
                <Typography variant="body2" sx={{ fontWeight: 600, mb: 1 }}>
                  Priorités à traiter :
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {safeRepairStatuses
                    .filter(status => {
                      const statusRepairs = repairs.filter(repair => repair.status === status.id);
                      return statusRepairs.length > 0;
                    })
                    .sort((a, b) => {
                      const aRepairs = repairs.filter(repair => repair.status === a.id);
                      const bRepairs = repairs.filter(repair => repair.status === b.id);
                      const aUrgent = aRepairs.filter(r => r.isUrgent).length;
                      const bUrgent = bRepairs.filter(r => r.isUrgent).length;
                      return bUrgent - aUrgent || bRepairs.length - aRepairs.length;
                    })
                    .slice(0, 3)
                    .map((status) => {
                      const statusRepairs = repairs.filter(repair => repair.status === status.id);
                      const urgentCount = statusRepairs.filter(r => r.isUrgent).length;
                      
                      return (
                        <Chip
                          key={status.id}
                          label={`${status.name}: ${statusRepairs.length}${urgentCount > 0 ? ` (${urgentCount} urgent)` : ''}`}
                          size="small"
                          sx={{
                            backgroundColor: status.color,
                            color: 'white',
                            fontWeight: 'bold',
                          }}
                        />
                      );
                    })}
                </Box>
              </Box>
              
              {/* Réparations urgentes et en retard - Section améliorée */}
              <Box sx={{ mt: 4 }}>
                <Typography variant="h6" sx={{ fontWeight: 700, mb: 3, color: 'error.main', display: 'flex', alignItems: 'center', gap: 1 }}>
                  <WarningIcon sx={{ fontSize: 28 }} />
                  Priorités critiques
                </Typography>
                
                <Grid container spacing={3}>
                  {/* Réparations urgentes - Design amélioré */}
                  <Grid item xs={12} lg={6}>
                    <Card 
                      sx={{ 
                        background: 'linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%)',
                        color: 'white',
                        position: 'relative',
                        overflow: 'hidden',
                        '&::before': {
                          content: '""',
                          position: 'absolute',
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          background: 'url("data:image/svg+xml,%3Csvg width="60" height="60" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg"%3E%3Cg fill="none" fill-rule="evenodd"%3E%3Cg fill="%23ffffff" fill-opacity="0.1"%3E%3Ccircle cx="30" cy="30" r="2"/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")',
                          opacity: 0.3,
                        },
                        boxShadow: '0 8px 32px rgba(255, 107, 107, 0.3)',
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          transform: 'translateY(-4px)',
                          boxShadow: '0 12px 40px rgba(255, 107, 107, 0.4)',
                        }
                      }}
                    >
                      <CardContent sx={{ p: 3, position: 'relative', zIndex: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box sx={{ 
                              width: 48, 
                              height: 48, 
                              borderRadius: '50%', 
                              backgroundColor: 'rgba(255, 255, 255, 0.2)',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center'
                            }}>
                              <WarningIcon sx={{ fontSize: 24, color: 'white' }} />
                            </Box>
                            <Box>
                              <Typography variant="h6" sx={{ fontWeight: 700, color: 'white' }}>
                                🔥 Réparations urgentes
                              </Typography>
                              <Typography variant="body2" sx={{ color: 'rgba(255, 255, 255, 0.8)' }}>
                                Priorité maximale
                              </Typography>
                            </Box>
                          </Box>
                          <Chip 
                            label={repairs.filter(r => r.isUrgent).length} 
                            sx={{ 
                              backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                              color: 'white', 
                              fontWeight: 700,
                              fontSize: '1.1rem',
                              height: 32
                            }} 
                          />
                        </Box>
                        
                        {(() => {
                          const urgentRepairs = repairs.filter(r => r.isUrgent);
                          if (urgentRepairs.length === 0) {
                            return (
                              <Box sx={{ 
                                p: 2, 
                                backgroundColor: 'rgba(255, 255, 255, 0.1)', 
                                borderRadius: 2,
                                textAlign: 'center'
                              }}>
                                <Box sx={{ color: 'rgba(255, 255, 255, 0.8)', fontSize: '0.875rem' }}>
                                  ✅ Aucune réparation urgente
                                </Box>
                              </Box>
                            );
                          }
                          return (
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                              {urgentRepairs.slice(0, 3).map((repair) => {
                                const client = getClientById(repair.clientId);
                                const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                                return (
                                  <Box 
                                    key={repair.id} 
                                    sx={{ 
                                      p: 2, 
                                      backgroundColor: 'rgba(255, 255, 255, 0.15)', 
                                      borderRadius: 2,
                                      border: '1px solid rgba(255, 255, 255, 0.2)',
                                      backdropFilter: 'blur(10px)',
                                      transition: 'all 0.2s ease',
                                      '&:hover': {
                                        backgroundColor: 'rgba(255, 255, 255, 0.25)',
                                        transform: 'scale(1.02)',
                                      }
                                    }}
                                  >
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                                      <Box sx={{ 
                                        width: 8, 
                                        height: 8, 
                                        borderRadius: '50%', 
                                        backgroundColor: 'rgba(255, 255, 255, 0.8)',
                                        animation: 'pulse 2s infinite'
                                      }} />
                                      <Box sx={{ fontWeight: 600, color: 'white', fontSize: '0.875rem' }}>
                                        {client?.firstName} {client?.lastName}
                                      </Box>
                                    </Box>
                                    <Box sx={{ color: 'rgba(255, 255, 255, 0.9)', mb: 0.5, fontSize: '0.875rem' }}>
                                      {device?.brand} {device?.model}
                                    </Box>
                                    <Box sx={{ color: 'rgba(255, 255, 255, 0.7)', fontSize: '0.75rem' }}>
                                      {repair.description}
                                    </Box>
                                  </Box>
                                );
                              })}
                              {urgentRepairs.length > 3 && (
                                                              <Box sx={{ 
                                p: 1.5, 
                                backgroundColor: 'rgba(255, 255, 255, 0.1)', 
                                borderRadius: 2,
                                textAlign: 'center'
                              }}>
                                <Box sx={{ color: 'rgba(255, 255, 255, 0.8)', fontWeight: 600, fontSize: '0.875rem' }}>
                                  +{urgentRepairs.length - 3} autres réparations urgentes
                                </Box>
                              </Box>
                              )}
                            </Box>
                          );
                        })()}
                      </CardContent>
                    </Card>
                  </Grid>
                  
                  {/* Réparations en retard - Design amélioré */}
                  <Grid item xs={12} lg={6}>
                    <Card 
                      sx={{ 
                        background: 'linear-gradient(135deg, #ffa726 0%, #ff9800 100%)',
                        color: 'white',
                        position: 'relative',
                        overflow: 'hidden',
                        '&::before': {
                          content: '""',
                          position: 'absolute',
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          background: 'url("data:image/svg+xml,%3Csvg width="60" height="60" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg"%3E%3Cg fill="none" fill-rule="evenodd"%3E%3Cg fill="%23ffffff" fill-opacity="0.1"%3E%3Ccircle cx="30" cy="30" r="2"/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")',
                          opacity: 0.3,
                        },
                        boxShadow: '0 8px 32px rgba(255, 167, 38, 0.3)',
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          transform: 'translateY(-4px)',
                          boxShadow: '0 12px 40px rgba(255, 167, 38, 0.4)',
                        }
                      }}
                    >
                      <CardContent sx={{ p: 3, position: 'relative', zIndex: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box sx={{ 
                              width: 48, 
                              height: 48, 
                              borderRadius: '50%', 
                              backgroundColor: 'rgba(255, 255, 255, 0.2)',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center'
                            }}>
                              <ScheduleIcon sx={{ fontSize: 24, color: 'white' }} />
                            </Box>
                            <Box>
                              <Typography variant="h6" sx={{ fontWeight: 700, color: 'white' }}>
                                ⏰ Réparations en retard
                              </Typography>
                              <Typography variant="body2" sx={{ color: 'rgba(255, 255, 255, 0.8)' }}>
                                Délais dépassés
                              </Typography>
                            </Box>
                          </Box>
                          <Chip 
                            label={repairs.filter(repair => {
                              const isCompleted = repair.status === 'completed' || repair.status === 'returned';
                              const hasDueDate = repair.dueDate && !isNaN(new Date(repair.dueDate).getTime());
                              const isOverdue = !isCompleted && hasDueDate && new Date(repair.dueDate) < new Date();
                              return isOverdue;
                            }).length} 
                            sx={{ 
                              backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                              color: 'white', 
                              fontWeight: 700,
                              fontSize: '1.1rem',
                              height: 32
                            }} 
                          />
                        </Box>
                        
                        {(() => {
                          // Utiliser la même logique que dans defaultStats pour la cohérence
                          const overdueRepairs = repairs.filter(repair => {
                            const isCompleted = repair.status === 'completed' || repair.status === 'returned';
                            const hasDueDate = repair.dueDate && !isNaN(new Date(repair.dueDate).getTime());
                            const isOverdue = !isCompleted && hasDueDate && new Date(repair.dueDate) < new Date();
                            return isOverdue;
                          });
                          
                          if (overdueRepairs.length === 0) {
                            return (
                              <Box sx={{ 
                                p: 2, 
                                backgroundColor: 'rgba(255, 255, 255, 0.1)', 
                                borderRadius: 2,
                                textAlign: 'center'
                              }}>
                                <Box sx={{ color: 'rgba(255, 255, 255, 0.8)', fontSize: '0.875rem' }}>
                                  ✅ Aucune réparation en retard
                                </Box>
                              </Box>
                            );
                          }
                          
                          return (
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                              {overdueRepairs.slice(0, 3).map((repair) => {
                                const client = getClientById(repair.clientId);
                                const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                                const daysLate = Math.floor((new Date().getTime() - new Date(repair.dueDate).getTime()) / (1000 * 60 * 60 * 24));
                                return (
                                  <Box 
                                    key={repair.id} 
                                    sx={{ 
                                      p: 2, 
                                      backgroundColor: 'rgba(255, 255, 255, 0.15)', 
                                      borderRadius: 2,
                                      border: '1px solid rgba(255, 255, 255, 0.2)',
                                      backdropFilter: 'blur(10px)',
                                      transition: 'all 0.2s ease',
                                      '&:hover': {
                                        backgroundColor: 'rgba(255, 255, 255, 0.25)',
                                        transform: 'scale(1.02)',
                                      }
                                    }}
                                  >
                                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 0.5 }}>
                                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                        <Box sx={{ 
                                          width: 8, 
                                          height: 8, 
                                          borderRadius: '50%', 
                                          backgroundColor: 'rgba(255, 255, 255, 0.8)',
                                          animation: 'pulse 2s infinite'
                                        }} />
                                        <Box sx={{ fontWeight: 600, color: 'white', fontSize: '0.875rem' }}>
                                          {client?.firstName} {client?.lastName}
                                        </Box>
                                      </Box>
                                      <Chip 
                                        label={`${daysLate}j`} 
                                        size="small"
                                        sx={{ 
                                          backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                                          color: 'white', 
                                          fontWeight: 700,
                                          fontSize: '0.7rem',
                                          height: 20
                                        }} 
                                      />
                                    </Box>
                                    <Box sx={{ color: 'rgba(255, 255, 255, 0.9)', mb: 0.5, fontSize: '0.875rem' }}>
                                      {device?.brand} {device?.model}
                                    </Box>
                                    <Box sx={{ color: 'rgba(255, 255, 255, 0.7)', fontSize: '0.75rem' }}>
                                      {repair.description}
                                    </Box>
                                  </Box>
                                );
                              })}
                              {overdueRepairs.length > 3 && (
                                                              <Box sx={{ 
                                p: 1.5, 
                                backgroundColor: 'rgba(255, 255, 255, 0.1)', 
                                borderRadius: 2,
                                textAlign: 'center'
                              }}>
                                <Box sx={{ color: 'rgba(255, 255, 255, 0.8)', fontWeight: 600, fontSize: '0.875rem' }}>
                                  +{overdueRepairs.length - 3} autres réparations en retard
                                </Box>
                              </Box>
                              )}
                            </Box>
                          );
                        })()}
                      </CardContent>
                    </Card>
                  </Grid>
                </Grid>
                
                {/* Bouton d'action rapide */}
                <Box sx={{ mt: 3, textAlign: 'center' }}>
                  <Button
                    variant="contained"
                    size="large"
                    startIcon={<BuildIcon />}
                    onClick={() => window.location.href = '/app/kanban'}
                    sx={{
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                      color: 'white',
                      fontWeight: 700,
                      px: 4,
                      py: 1.5,
                      borderRadius: 3,
                      boxShadow: '0 8px 25px rgba(102, 126, 234, 0.3)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: '0 12px 35px rgba(102, 126, 234, 0.4)',
                      }
                    }}
                  >
                    Gérer toutes les priorités
                  </Button>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      ) : (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body2" color="text.secondary">
                    Chargement des données de suivi des réparations...
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

              {/* Tâches à faire - Basé sur le suivi des réparations */}
      {safeRepairStatuses.length > 0 ? (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  📋 Tâches à faire aujourd'hui
                </Typography>
                <Button 
                  variant="outlined" 
                  size="small"
                  onClick={() => window.location.href = '/app/kanban'}
                >
                  Voir toutes les tâches
                </Button>
              </Box>
              
              <Grid container spacing={2}>
                {/* Nouvelles réparations à traiter */}
                {(() => {
                  const newRepairs = repairs.filter(r => r.status === 'new');
                  if (newRepairs.length === 0) return null;
                  
                  return (
                    <Grid item xs={12} md={6}>
                      <Box sx={{ p: 2, backgroundColor: 'info.light', borderRadius: 1 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600, mb: 1, color: 'info.dark' }}>
                          🆕 Nouvelles réparations à traiter ({newRepairs.length})
                        </Typography>
                        {newRepairs.slice(0, 3).map((repair) => {
                          const client = getClientById(repair.clientId);
                          const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                          return (
                            <Box key={repair.id} sx={{ mb: 1, p: 1, backgroundColor: 'white', borderRadius: 0.5 }}>
                              <Typography variant="caption" sx={{ fontWeight: 600 }}>
                                {client?.firstName} {client?.lastName} - {device?.brand} {device?.model}
                              </Typography>
                              <Typography variant="caption" display="block" color="text.secondary">
                                {repair.description}
                              </Typography>
                            </Box>
                          );
                        })}
                        {newRepairs.length > 3 && (
                          <Typography variant="caption" color="text.secondary">
                            +{newRepairs.length - 3} autres à traiter
                          </Typography>
                        )}
                      </Box>
                    </Grid>
                  );
                })()}
                
                {/* Réparations en attente de pièces */}
                {(() => {
                  const waitingParts = repairs.filter(r => r.status === 'waiting_parts');
                  if (waitingParts.length === 0) return null;
                  
                  return (
                    <Grid item xs={12} md={6}>
                      <Box sx={{ p: 2, backgroundColor: 'warning.light', borderRadius: 1 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600, mb: 1, color: 'warning.dark' }}>
                          🔧 Réparations en attente de pièces ({waitingParts.length})
                        </Typography>
                        {waitingParts.slice(0, 3).map((repair) => {
                          const client = getClientById(repair.clientId);
                          const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                          return (
                            <Box key={repair.id} sx={{ mb: 1, p: 1, backgroundColor: 'white', borderRadius: 0.5 }}>
                              <Typography variant="caption" sx={{ fontWeight: 600 }}>
                                {client?.firstName} {client?.lastName} - {device?.brand} {device?.model}
                              </Typography>
                              <Typography variant="caption" display="block" color="text.secondary">
                                {repair.description}
                              </Typography>
                            </Box>
                          );
                        })}
                        {waitingParts.length > 3 && (
                          <Typography variant="caption" color="text.secondary">
                            +{waitingParts.length - 3} autres en attente
                          </Typography>
                        )}
                      </Box>
                    </Grid>
                  );
                })()}
                
                {/* Réparations prêtes à livrer */}
                {(() => {
                  const readyToDeliver = repairs.filter(r => r.status === 'waiting_delivery');
                  if (readyToDeliver.length === 0) return null;
                  
                  return (
                    <Grid item xs={12} md={6}>
                      <Box sx={{ p: 2, backgroundColor: 'success.light', borderRadius: 1 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600, mb: 1, color: 'success.dark' }}>
                          📦 Réparations prêtes à livrer ({readyToDeliver.length})
                        </Typography>
                        {readyToDeliver.slice(0, 3).map((repair) => {
                          const client = getClientById(repair.clientId);
                          const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                          return (
                            <Box key={repair.id} sx={{ mb: 1, p: 1, backgroundColor: 'white', borderRadius: 0.5 }}>
                              <Typography variant="caption" sx={{ fontWeight: 600 }}>
                                {client?.firstName} {client?.lastName} - {device?.brand} {device?.model}
                              </Typography>
                              <Typography variant="caption" display="block" color="text.secondary">
                                {repair.description}
                              </Typography>
                            </Box>
                          );
                        })}
                        {readyToDeliver.length > 3 && (
                          <Typography variant="caption" color="text.secondary">
                            +{readyToDeliver.length - 3} autres prêtes
                          </Typography>
                        )}
                      </Box>
                    </Grid>
                  );
                })()}
                
                {/* Réparations en cours */}
                {(() => {
                  const inProgress = repairs.filter(r => r.status === 'in_progress');
                  if (inProgress.length === 0) return null;
                  
                  return (
                    <Grid item xs={12} md={6}>
                      <Box sx={{ p: 2, backgroundColor: 'primary.light', borderRadius: 1 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600, mb: 1, color: 'primary.dark' }}>
                          ⚡ Réparations en cours ({inProgress.length})
                        </Typography>
                        {inProgress.slice(0, 3).map((repair) => {
                          const client = getClientById(repair.clientId);
                          const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                          return (
                            <Box key={repair.id} sx={{ mb: 1, p: 1, backgroundColor: 'white', borderRadius: 0.5 }}>
                              <Typography variant="caption" sx={{ fontWeight: 600 }}>
                                {client?.firstName} {client?.lastName} - {device?.brand} {device?.model}
                              </Typography>
                              <Typography variant="caption" display="block" color="text.secondary">
                                {repair.description}
                              </Typography>
                            </Box>
                          );
                        })}
                        {inProgress.length > 3 && (
                          <Typography variant="caption" color="text.secondary">
                            +{inProgress.length - 3} autres en cours
                          </Typography>
                        )}
                      </Box>
                    </Grid>
                  );
                })()}
              </Grid>
              
              {/* Message si aucune tâche */}
              {repairs.filter(r => ['new', 'waiting_parts', 'waiting_delivery', 'in_progress'].includes(r.status)).length === 0 && (
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body2" color="text.secondary">
                    🎉 Aucune tâche en attente ! Toutes les réparations sont à jour.
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      ) : (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body2" color="text.secondary">
                    Chargement des tâches...
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Réparations récentes et rendez-vous */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="h6">Réparations récentes</Typography>
                <Button variant="outlined" size="small">
                  Voir tout
                </Button>
              </Box>
              {recentRepairs.length === 0 ? (
                <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 4 }}>
                  Aucune réparation récente
                </Typography>
              ) : (
                <List>
                  {recentRepairs.map((repair, index) => {
                    const client = getClientById(repair.clientId);
                    const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
                    return (
                      <React.Fragment key={repair.id}>
                        <ListItem alignItems="flex-start">
                          <ListItemAvatar>
                            <Avatar
                              sx={{
                                backgroundColor: getDeviceTypeColor(device?.type || 'other'),
                              }}
                            >
                              {getDeviceTypeIcon(device?.type || 'other')}
                            </Avatar>
                          </ListItemAvatar>
                          <ListItemText
                            primary={
                              <React.Fragment>
                                <Typography variant="subtitle2" component="span" sx={{ mr: 1 }}>
                                  {client?.firstName} {client?.lastName}
                                </Typography>
                                <Chip
                                  label={repair.isUrgent ? 'Urgent' : 'Normal'}
                                  size="small"
                                  color={repair.isUrgent ? 'error' : 'default'}
                                />
                              </React.Fragment>
                            }
                            secondary={
                              <Box>
                                <Typography variant="body2" color="text.secondary">
                                  {device?.brand} {device?.model} - {repair.description}
                                </Typography>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 1 }}>
                                  <Chip
                                    label={repairStatuses.find(s => s.id === repair.status)?.name || repair.status}
                                    size="small"
                                    sx={{
                                      backgroundColor: getStatusColor(repair.status),
                                      color: 'white',
                                    }}
                                  />
                                  <Typography variant="caption" color="text.secondary">
                                    {safeFormatDate(repair.createdAt, 'dd/MM/yyyy HH:mm')}
                                  </Typography>
                                </Box>
                              </Box>
                            }
                          />
                          <Typography variant="h6" color="primary">
                            {formatFromEUR(repair.totalPrice, currency)} TTC
                          </Typography>
                        </ListItem>
                        {index < recentRepairs.length - 1 && <Divider variant="inset" component="li" />}
                      </React.Fragment>
                    );
                  })}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Rendez-vous aujourd'hui
              </Typography>
              {todayAppointments.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  Aucun rendez-vous aujourd'hui
                </Typography>
              ) : (
                <List>
                  {todayAppointments.map((appointment) => {
                    const client = appointment.clientId ? getClientById(appointment.clientId) : null;
                    return (
                      <ListItem key={appointment.id} alignItems="flex-start">
                        <ListItemAvatar>
                          <Avatar sx={{ backgroundColor: 'primary.main' }}>
                            <ScheduleIcon />
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={appointment.title}
                          secondary={
                            <React.Fragment>
                              <Typography variant="body2" color="text.secondary">
                                {client?.firstName} {client?.lastName}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {safeFormatDate(appointment.startDate, 'HH:mm')} - {safeFormatDate(appointment.endDate, 'HH:mm')}
                              </Typography>
                            </React.Fragment>
                          }
                        />
                      </ListItem>
                    );
                  })}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Test de connexion Supabase - MASQUÉ */}
      {/* <Box sx={{ mt: 4 }}>
        <SupabaseTest />
      </Box> */}

      {/* Statut de l'application - MASQUÉ */}
      {/* <Box sx={{ mt: 4 }}>
        <AppStatus />
      </Box> */}

      {/* Outils d'administration - MASQUÉ */}
      {/* <Box sx={{ mt: 4 }}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Outils d'administration
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Outils pour gérer la base de données et nettoyer les données.
            </Typography>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Button
                variant="contained"
                color="warning"
                onClick={async () => {
                  if (window.confirm('⚠️ Êtes-vous sûr de vouloir supprimer TOUTES les données ? Cette action est irréversible !')) {
                    try {
                      await demoDataService.clearAllData();
                      // Recharger les données vides
                      await Promise.all([
                        loadClients(),
                        loadDevices(),
                        loadServices(),
                        loadParts(),
                        loadProducts(),
                        loadRepairs(),
                        loadSales(),
                        loadAppointments(),
                      ]);
                      alert('✅ Toutes les données ont été supprimées. Site vierge prêt à l\'emploi !');
                    } catch (error) {
                      console.error('Erreur lors du nettoyage des données:', error);
                      alert('❌ Erreur lors du nettoyage des données');
                    }
                  }
                }}
              >
                🧹 Nettoyer toutes les données
              </Button>
              <Button
                variant="outlined"
                onClick={async () => {
                  try {
                    // Recharger toutes les données
                    await Promise.all([
                      loadClients(),
                      loadDevices(),
                      loadServices(),
                      loadParts(),
                      loadProducts(),
                      loadRepairs(),
                      loadSales(),
                      loadAppointments(),
                    ]);
                    alert(`✅ Données rechargées : ${clients.length} clients, ${devices.length} appareils, ${repairs.length} réparations`);
                  } catch (error) {
                    console.error('Erreur lors du rechargement des données:', error);
                    alert('❌ Erreur lors du rechargement des données');
                  }
                }}
              >
                🔄 Recharger les données
              </Button>
            </Box>
          </CardContent>
        </Card>
      </Box> */}
    </Box>
  );
};

export default Dashboard;

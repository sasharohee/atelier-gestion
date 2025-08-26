import React, { useState, useEffect } from 'react';
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
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { deviceTypeColors, repairStatusColors } from '../../theme';
// import AppStatus from '../../components/AppStatus'; // MASQUÉ
// import SupabaseTest from '../../components/SupabaseTest'; // MASQUÉ
import { demoDataService } from '../../services/demoDataService';

const Dashboard: React.FC = () => {
  const [hasError, setHasError] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  
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

  // Statistiques par défaut pour un atelier vide
  const defaultStats = {
    totalRepairs: safeRepairs.length,
    activeRepairs: safeRepairs.filter(r => r.status === 'in_progress').length,
    completedRepairs: safeRepairs.filter(r => r.status === 'completed' || r.status === 'returned').length,
    overdueRepairs: 0,
    todayAppointments: todayAppointments.length,
    monthlyRevenue: 0,
    lowStockItems: 0,
    pendingMessages: 0,
  };

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
            value={`${defaultStats.monthlyRevenue.toLocaleString('fr-FR')} €`}
            icon={<TrendingUpIcon />}
            color="#9c27b0"
            subtitle="Ce mois"
          />
        </Grid>
      </Grid>

      {/* Statistiques Kanban rapides */}
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
                    Chargement des statistiques Kanban...
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
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <MessageIcon color="info" sx={{ mr: 1 }} />
                    <Typography variant="body2" component="span">Messages en attente</Typography>
                  </Box>
                  <Chip label={defaultStats.pendingMessages} color="info" size="small" />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* État du Kanban - Vue d'ensemble des étapes */}
      {safeRepairStatuses.length > 0 ? (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    État du Kanban - Vue d'ensemble
                  </Typography>
                  <Button 
                    variant="outlined" 
                    size="small"
                    onClick={() => window.location.href = '/kanban'}
                  >
                    Voir le Kanban
                  </Button>
                </Box>
              
              <Grid container spacing={2}>
                {safeRepairStatuses
                  .sort((a, b) => a.order - b.order)
                  .map((status) => {
                    const statusRepairs = repairs.filter(repair => repair.status === status.id);
                    const overdueRepairs = statusRepairs.filter(repair => {
                      try {
                        if (!repair.dueDate) return false;
                        const dueDate = new Date(repair.dueDate);
                        if (isNaN(dueDate.getTime())) return false;
                        return dueDate < new Date();
                      } catch (error) {
                        return false;
                      }
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
                          onClick={() => window.location.href = '/kanban'}
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
              
              {/* Réparations urgentes et en retard */}
              <Box sx={{ mt: 2 }}>
                <Grid container spacing={2}>
                  {/* Réparations urgentes */}
                  <Grid item xs={12} md={6}>
                    <Box sx={{ p: 2, backgroundColor: 'error.light', borderRadius: 1 }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, mb: 1, color: 'error.dark' }}>
                        🔥 Réparations urgentes
                      </Typography>
                      {(() => {
                        const urgentRepairs = repairs.filter(r => r.isUrgent);
                        if (urgentRepairs.length === 0) {
                          return (
                            <Typography variant="caption" color="text.secondary">
                              Aucune réparation urgente
                            </Typography>
                          );
                        }
                        return (
                          <Box>
                            {urgentRepairs.slice(0, 3).map((repair) => {
                              const client = getClientById(repair.clientId);
                              const device = getDeviceById(repair.deviceId);
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
                            {urgentRepairs.length > 3 && (
                              <Typography variant="caption" color="text.secondary">
                                +{urgentRepairs.length - 3} autres urgentes
                              </Typography>
                            )}
                          </Box>
                        );
                      })()}
                    </Box>
                  </Grid>
                  
                  {/* Réparations en retard */}
                  <Grid item xs={12} md={6}>
                    <Box sx={{ p: 2, backgroundColor: 'warning.light', borderRadius: 1 }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, mb: 1, color: 'warning.dark' }}>
                        ⏰ Réparations en retard
                      </Typography>
                      {(() => {
                        const overdueRepairs = repairs.filter(repair => {
                          try {
                            if (!repair.dueDate) return false;
                            const dueDate = new Date(repair.dueDate);
                            if (isNaN(dueDate.getTime())) return false;
                            return dueDate < new Date();
                          } catch (error) {
                            return false;
                          }
                        });
                        
                        if (overdueRepairs.length === 0) {
                          return (
                            <Typography variant="caption" color="text.secondary">
                              Aucune réparation en retard
                            </Typography>
                          );
                        }
                        
                        return (
                          <Box>
                            {overdueRepairs.slice(0, 3).map((repair) => {
                              const client = getClientById(repair.clientId);
                              const device = getDeviceById(repair.deviceId);
                              const daysLate = Math.floor((new Date().getTime() - new Date(repair.dueDate).getTime()) / (1000 * 60 * 60 * 24));
                              return (
                                <Box key={repair.id} sx={{ mb: 1, p: 1, backgroundColor: 'white', borderRadius: 0.5 }}>
                                  <Typography variant="caption" sx={{ fontWeight: 600 }}>
                                    {client?.firstName} {client?.lastName} - {device?.brand} {device?.model}
                                  </Typography>
                                  <Typography variant="caption" display="block" color="text.secondary">
                                    {repair.description} ({daysLate} jour{daysLate > 1 ? 's' : ''} de retard)
                                  </Typography>
                                </Box>
                              );
                            })}
                            {overdueRepairs.length > 3 && (
                              <Typography variant="caption" color="text.secondary">
                                +{overdueRepairs.length - 3} autres en retard
                              </Typography>
                            )}
                          </Box>
                        );
                      })()}
                    </Box>
                  </Grid>
                </Grid>
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
                    Chargement des données Kanban...
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Tâches à faire - Basé sur le Kanban */}
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
                  onClick={() => window.location.href = '/kanban'}
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
                          const device = getDeviceById(repair.deviceId);
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
                          const device = getDeviceById(repair.deviceId);
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
                          const device = getDeviceById(repair.deviceId);
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
                          const device = getDeviceById(repair.deviceId);
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
                    const device = getDeviceById(repair.deviceId);
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
                              <React.Fragment>
                                <Typography variant="body2" color="text.secondary" component="div">
                                  {device?.brand} {device?.model} - {repair.description}
                                </Typography>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                                  <Chip
                                    label={repairStatuses.find(s => s.id === repair.status)?.name || repair.status}
                                    size="small"
                                    sx={{
                                      backgroundColor: getStatusColor(repair.status),
                                      color: 'white',
                                    }}
                                  />
                                  <Typography variant="caption" color="text.secondary" component="span">
                                    {safeFormatDate(repair.createdAt, 'dd/MM/yyyy HH:mm')}
                                  </Typography>
                                </div>
                              </React.Fragment>
                            }
                          />
                          <Typography variant="h6" color="primary">
                            {repair.totalPrice} €
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

import React from 'react';
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

const Dashboard: React.FC = () => {
  const {
    dashboardStats,
    repairs,
    appointments,
    clients,
    devices,
    getRepairsByStatus,
    getClientById,
    getDeviceById,
  } = useAppStore();

  const recentRepairs = repairs
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    .slice(0, 5);

  const todayAppointments = appointments.filter(
    (appointment) => format(new Date(appointment.startDate), 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd')
  );

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

  if (!dashboardStats) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
        <Typography>Chargement...</Typography>
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
            value={dashboardStats.activeRepairs}
            icon={<BuildIcon />}
            color="#ff9800"
            subtitle={`${dashboardStats.totalRepairs} total`}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Réparations terminées"
            value={dashboardStats.completedRepairs}
            icon={<CheckCircleIcon />}
            color="#4caf50"
            subtitle="Ce mois"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Rendez-vous aujourd'hui"
            value={dashboardStats.todayAppointments}
            icon={<ScheduleIcon />}
            color="#2196f3"
            subtitle="Planifiés"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Chiffre d'affaires"
            value={`${dashboardStats.monthlyRevenue.toLocaleString('fr-FR')} €`}
            icon={<TrendingUpIcon />}
            color="#9c27b0"
            subtitle="Ce mois"
          />
        </Grid>
      </Grid>

      {/* Progression et alertes */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={6}>
          <ProgressCard
            title="Progression des réparations"
            value={dashboardStats.completedRepairs}
            total={dashboardStats.totalRepairs}
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
                    <Typography variant="body2">Réparations en retard</Typography>
                  </Box>
                  <Chip label={dashboardStats.overdueRepairs} color="error" size="small" />
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <InventoryIcon color="warning" sx={{ mr: 1 }} />
                    <Typography variant="body2">Stock faible</Typography>
                  </Box>
                  <Chip label={dashboardStats.lowStockItems} color="warning" size="small" />
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <MessageIcon color="info" sx={{ mr: 1 }} />
                    <Typography variant="body2">Messages en attente</Typography>
                  </Box>
                  <Chip label={dashboardStats.pendingMessages} color="info" size="small" />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

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
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Typography variant="subtitle2">
                                {client?.firstName} {client?.lastName}
                              </Typography>
                              <Chip
                                label={repair.isUrgent ? 'Urgent' : 'Normal'}
                                size="small"
                                color={repair.isUrgent ? 'error' : 'default'}
                              />
                            </Box>
                          }
                          secondary={
                            <Box>
                              <Typography variant="body2" color="text.secondary">
                                {device?.brand} {device?.model} - {repair.description}
                              </Typography>
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 1 }}>
                                <Chip
                                  label={repair.status}
                                  size="small"
                                  sx={{
                                    backgroundColor: getStatusColor(repair.status),
                                    color: 'white',
                                  }}
                                />
                                <Typography variant="caption" color="text.secondary">
                                  {format(new Date(repair.createdAt), 'dd/MM/yyyy HH:mm')}
                                </Typography>
                              </Box>
                            </Box>
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
                    const client = getClientById(appointment.clientId);
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
                            <Box>
                              <Typography variant="body2" color="text.secondary">
                                {client?.firstName} {client?.lastName}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {format(new Date(appointment.startDate), 'HH:mm')} - {format(new Date(appointment.endDate), 'HH:mm')}
                              </Typography>
                            </Box>
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
    </Box>
  );
};

export default Dashboard;

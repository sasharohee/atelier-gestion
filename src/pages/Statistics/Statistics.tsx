import React, { useState, useMemo } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Avatar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Tabs,
  Tab,
  Divider,
  Alert,
  LinearProgress,
  Tooltip,
  IconButton,
  Badge,
} from '@mui/material';
import {
  BarChart as BarChartIcon,
  PieChart as PieChartIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Speed as SpeedIcon,
  AttachMoney as MoneyIcon,
  People as PeopleIcon,
  Phone as PhoneIcon,
  Build as BuildIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Star as StarIcon,
  Download as DownloadIcon,
  Refresh as RefreshIcon,
  CalendarToday as CalendarIcon,
  Inventory as InventoryIcon,
  ShoppingCart as ShoppingCartIcon,
  Assessment as AssessmentIcon,
  Analytics as AnalyticsIcon,
} from '@mui/icons-material';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  Area,
  AreaChart,
  ComposedChart,
  Scatter,
  ScatterChart,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
} from 'recharts';
import { useAppStore } from '../../store';
import { format, subDays, subMonths, startOfMonth, endOfMonth, eachDayOfInterval } from 'date-fns';
import { fr } from 'date-fns/locale';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82CA9D', '#FF6B6B', '#4ECDC4'];

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`stats-tabpanel-${index}`}
      aria-labelledby={`stats-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  );
}

const Statistics: React.FC = () => {
  const {
    repairs,
    sales,
    devices,
    clients,
    repairStatuses,
    users,
    getClientById,
    getDeviceById,
    loadRepairs,
    loadSales,
    loadClients,
    loadDevices,
  } = useAppStore();

  const [period, setPeriod] = useState('month');
  const [deviceType, setDeviceType] = useState('all');
  const [activeTab, setActiveTab] = useState(0);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Fonction de rechargement des données
  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      console.log('🔄 STATISTIQUES - Rechargement des données...');
      await Promise.all([
        loadRepairs(),
        loadSales(),
        loadClients(),
        loadDevices(),
      ]);
      console.log('✅ STATISTIQUES - Données rechargées avec succès');
    } catch (error) {
      console.error('❌ STATISTIQUES - Erreur lors du rechargement des données:', error);
    } finally {
      setIsRefreshing(false);
    }
  };

  // Fonction de diagnostic
  const handleDiagnostic = () => {
    console.log('🔍 DIAGNOSTIC STATISTIQUES - État actuel:');
    console.log('📊 Données dans le store:');
    console.log('  - Réparations:', repairs.length);
    console.log('  - Clients:', clients.length);
    console.log('  - Appareils:', devices.length);
    console.log('  - Ventes:', sales.length);
    
    console.log('🔗 Vérification des liens:');
    const repairsWithClients = repairs.filter(repair => {
      const client = getClientById(repair.clientId);
      return client !== undefined;
    });
    console.log(`  - Réparations avec clients valides: ${repairsWithClients.length}/${repairs.length}`);
    
    const repairsWithDevices = repairs.filter(repair => {
      if (!repair.deviceId) return false;
      const device = getDeviceById(repair.deviceId);
      return device !== undefined;
    });
    console.log(`  - Réparations avec appareils valides: ${repairsWithDevices.length}/${repairs.length}`);
    
    console.log('💡 Pour voir le calcul détaillé, changez d\'onglet ou modifiez un filtre');
  };

  // Calcul de la période sélectionnée
  const getPeriodData = useMemo(() => {
    const now = new Date();
    let startDate: Date;
    
    switch (period) {
      case 'week':
        startDate = subDays(now, 7);
        break;
      case 'month':
        startDate = subMonths(now, 1);
        break;
      case 'quarter':
        startDate = subMonths(now, 3);
        break;
      case 'year':
        startDate = subMonths(now, 12);
        break;
      default:
        startDate = subMonths(now, 1);
    }
    
    return { startDate, endDate: now };
  }, [period]);

  // Statistiques générales
  const generalStats = useMemo(() => {
    const { startDate, endDate } = getPeriodData;
    
    // Filtrer les réparations par période et type d'appareil
    const periodRepairs = repairs.filter(repair => {
      const repairDate = new Date(repair.createdAt);
      const isInPeriod = repairDate >= startDate && repairDate <= endDate;
      
      // Si un type d'appareil spécifique est sélectionné, filtrer par type
      if (deviceType !== 'all') {
        const repairDevice = devices.find(d => d.id === repair.deviceId);
        return isInPeriod && repairDevice && repairDevice.type === deviceType;
      }
      
      return isInPeriod;
    });
    
    const periodSales = sales.filter(sale => {
      const saleDate = new Date(sale.createdAt);
      return saleDate >= startDate && saleDate <= endDate;
    });

    const salesRevenue = periodSales.reduce((sum, sale) => sum + sale.total, 0);
    const repairsRevenue = periodRepairs
      .filter(repair => repair.isPaid)
      .reduce((sum, repair) => sum + repair.totalPrice, 0);
    const totalRevenue = salesRevenue + repairsRevenue;
    const avgRepairTime = periodRepairs.length > 0 
      ? periodRepairs.reduce((sum, repair) => {
          const created = new Date(repair.createdAt);
          const updated = new Date(repair.updatedAt);
          return sum + (updated.getTime() - created.getTime()) / (1000 * 60 * 60 * 24);
        }, 0) / periodRepairs.length
      : 0;

    return {
      totalRepairs: periodRepairs.length,
      totalSales: periodSales.length,
      totalRevenue,
      avgRepairTime: Math.round(avgRepairTime * 10) / 10,
      totalClients: clients.length,
      totalDevices: devices.length,
      successRate: periodRepairs.length > 0 
        ? Math.round((periodRepairs.filter(r => r.status === 'completed' || r.status === 'returned').length / periodRepairs.length) * 100)
        : 0,
    };
  }, [repairs, sales, clients, devices, getPeriodData, deviceType]);

  // Réparations par statut
  const repairsByStatus = useMemo(() => {
    const { startDate, endDate } = getPeriodData;
    const periodRepairs = repairs.filter(repair => {
      const repairDate = new Date(repair.createdAt);
      const isInPeriod = repairDate >= startDate && repairDate <= endDate;
      
      // Si un type d'appareil spécifique est sélectionné, filtrer par type
      if (deviceType !== 'all') {
        const repairDevice = devices.find(d => d.id === repair.deviceId);
        return isInPeriod && repairDevice && repairDevice.type === deviceType;
      }
      
      return isInPeriod;
    });

    return repairStatuses.map(status => ({
      name: status.name,
      count: periodRepairs.filter(repair => repair.status === status.id).length,
      color: status.color,
      percentage: periodRepairs.length > 0 
        ? Math.round((periodRepairs.filter(repair => repair.status === status.id).length / periodRepairs.length) * 100)
        : 0,
    })).filter(item => item.count > 0);
  }, [repairs, repairStatuses, getPeriodData, deviceType, devices]);

  // Réparations par type d'appareil
  const repairsByDeviceType = useMemo(() => {
    const { startDate, endDate } = getPeriodData;
    const periodRepairs = repairs.filter(repair => {
      const repairDate = new Date(repair.createdAt);
      const isInPeriod = repairDate >= startDate && repairDate <= endDate;
      
      // Si un type d'appareil spécifique est sélectionné, filtrer par type
      if (deviceType !== 'all') {
        const repairDevice = devices.find(d => d.id === repair.deviceId);
        return isInPeriod && repairDevice && repairDevice.type === deviceType;
      }
      
      return isInPeriod;
    });

    const deviceTypeMap = new Map<string, number>();
    
    periodRepairs.forEach(repair => {
      const repairDevice = devices.find(d => d.id === repair.deviceId);
      if (repairDevice) {
        const deviceType = repairDevice.type;
        deviceTypeMap.set(deviceType, (deviceTypeMap.get(deviceType) || 0) + 1);
      }
    });
    
    return Array.from(deviceTypeMap.entries()).map(([type, count], index) => ({
      name: type.charAt(0).toUpperCase() + type.slice(1),
      count,
      color: COLORS[index % COLORS.length],
      percentage: periodRepairs.length > 0 ? Math.round((count / periodRepairs.length) * 100) : 0,
    }));
  }, [repairs, devices, getPeriodData, deviceType]);

  // Évolution du chiffre d'affaires
  const revenueEvolution = useMemo(() => {
    const { startDate, endDate } = getPeriodData;
    const days = eachDayOfInterval({ start: startDate, end: endDate });
    
    return days.map(day => {
      const daySales = sales.filter(sale => {
        const saleDate = new Date(sale.createdAt);
        return saleDate.toDateString() === day.toDateString();
      });
      
      const dayRepairs = repairs.filter(repair => {
        const repairDate = new Date(repair.createdAt);
        const isSameDay = repairDate.toDateString() === day.toDateString();
        
        // Si un type d'appareil spécifique est sélectionné, filtrer par type
        if (deviceType !== 'all') {
          const repairDevice = devices.find(d => d.id === repair.deviceId);
          return isSameDay && repairDevice && repairDevice.type === deviceType;
        }
        
        return isSameDay;
      });
      
      return {
        date: format(day, 'dd/MM', { locale: fr }),
        revenue: daySales.reduce((sum, sale) => sum + sale.total, 0),
        repairs: dayRepairs.length,
      };
    });
  }, [sales, repairs, getPeriodData, deviceType, devices]);

  // Top clients
  const topClients = useMemo(() => {
    console.log('🔍 STATISTIQUES - Calcul du top 10 des clients');
    console.log('📊 Données disponibles:');
    console.log('  - Réparations:', repairs.length);
    console.log('  - Clients:', clients.length);
    console.log('  - Appareils:', devices.length);
    console.log('  - Type d\'appareil sélectionné:', deviceType);
    
    const clientRepairs = new Map<string, { client: any; repairs: number; revenue: number }>();
    let repairsProcessed = 0;
    let repairsWithValidClients = 0;
    let repairsWithInvalidClients = 0;
    
    repairs.forEach(repair => {
      repairsProcessed++;
      
      // Si un type d'appareil spécifique est sélectionné, filtrer par type
      if (deviceType !== 'all') {
        const repairDevice = devices.find(d => d.id === repair.deviceId);
        if (!repairDevice || repairDevice.type !== deviceType) {
          console.log(`⚠️ Réparation #${repair.repairNumber} filtrée par type d'appareil`);
          return;
        }
      }
      
      const client = getClientById(repair.clientId);
      if (client) {
        repairsWithValidClients++;
        const existing = clientRepairs.get(client.id);
        if (existing) {
          existing.repairs += 1;
          existing.revenue += repair.totalPrice;
        } else {
          clientRepairs.set(client.id, { client, repairs: 1, revenue: repair.totalPrice });
        }
      } else {
        repairsWithInvalidClients++;
        console.log(`⚠️ Réparation #${repair.repairNumber} - Client ID ${repair.clientId} non trouvé`);
      }
    });
    
    console.log('📈 Résultats du calcul:');
    console.log(`  - Réparations traitées: ${repairsProcessed}`);
    console.log(`  - Réparations avec clients valides: ${repairsWithValidClients}`);
    console.log(`  - Réparations avec clients invalides: ${repairsWithInvalidClients}`);
    console.log(`  - Clients uniques avec réparations: ${clientRepairs.size}`);
    
    const result = Array.from(clientRepairs.values())
      .sort((a, b) => b.repairs - a.repairs)
      .slice(0, 10);
    
    console.log(`✅ Top ${result.length} clients calculé:`);
    result.forEach((item, index) => {
      console.log(`  ${index + 1}. ${item.client.firstName} ${item.client.lastName} (${item.repairs} réparations, ${item.revenue.toFixed(2)}€)`);
    });
    
    return result;
  }, [repairs, getClientById, deviceType, devices, clients]);

  // Top appareils
  const topDevices = useMemo(() => {
    const deviceRepairs = new Map<string, { device: any; repairs: number; revenue: number }>();
    
    repairs.forEach(repair => {
      const device = repair.deviceId ? getDeviceById(repair.deviceId) : null;
      if (device) {
        // Si un type d'appareil spécifique est sélectionné, filtrer par type
        if (deviceType !== 'all' && device.type !== deviceType) {
          return;
        }
        
        const existing = deviceRepairs.get(device.id);
        if (existing) {
          existing.repairs += 1;
          existing.revenue += repair.totalPrice;
        } else {
          deviceRepairs.set(device.id, { device, repairs: 1, revenue: repair.totalPrice });
        }
      }
    });
    
    return Array.from(deviceRepairs.values())
      .sort((a, b) => b.repairs - a.repairs)
      .slice(0, 10);
  }, [repairs, getDeviceById, deviceType]);

  // Performance des techniciens
  const technicianPerformance = useMemo(() => {
    const techStats = new Map<string, { 
      technician: any; 
      repairs: number; 
      completed: number; 
      revenue: number; 
      avgTime: number;
    }>();
    
    repairs.forEach(repair => {
      // Si un type d'appareil spécifique est sélectionné, filtrer par type
      if (deviceType !== 'all') {
        const repairDevice = devices.find(d => d.id === repair.deviceId);
        if (!repairDevice || repairDevice.type !== deviceType) {
          return;
        }
      }
      
      if (repair.assignedTechnicianId) {
        const technician = users.find(u => u.id === repair.assignedTechnicianId);
        if (technician) {
          const existing = techStats.get(technician.id);
          const created = new Date(repair.createdAt);
          const updated = new Date(repair.updatedAt);
          const duration = (updated.getTime() - created.getTime()) / (1000 * 60 * 60 * 24);
          
          if (existing) {
            existing.repairs += 1;
            existing.revenue += repair.totalPrice;
            existing.avgTime = (existing.avgTime + duration) / 2;
            if (repair.status === 'completed' || repair.status === 'returned') existing.completed += 1;
          } else {
            techStats.set(technician.id, {
              technician,
              repairs: 1,
              completed: (repair.status === 'completed' || repair.status === 'returned') ? 1 : 0,
              revenue: repair.totalPrice,
              avgTime: duration,
            });
          }
        }
      }
    });
    
    return Array.from(techStats.values())
      .sort((a, b) => b.repairs - a.repairs);
  }, [repairs, users, deviceType, devices]);

  // Métriques de performance
  const performanceMetrics = useMemo(() => {
    const { startDate, endDate } = getPeriodData;
    const periodRepairs = repairs.filter(repair => {
      const repairDate = new Date(repair.createdAt);
      const isInPeriod = repairDate >= startDate && repairDate <= endDate;
      
      // Si un type d'appareil spécifique est sélectionné, filtrer par type
      if (deviceType !== 'all') {
        const repairDevice = devices.find(d => d.id === repair.deviceId);
        return isInPeriod && repairDevice && repairDevice.type === deviceType;
      }
      
      return isInPeriod;
    });

    const urgentRepairs = periodRepairs.filter(r => r.isUrgent).length;
    const overdueRepairs = periodRepairs.filter(r => {
      const dueDate = new Date(r.dueDate);
      return dueDate < new Date() && r.status !== 'completed' && r.status !== 'returned';
    }).length;

    return {
      urgentRepairs,
      overdueRepairs,
      urgentPercentage: periodRepairs.length > 0 ? Math.round((urgentRepairs / periodRepairs.length) * 100) : 0,
      overduePercentage: periodRepairs.length > 0 ? Math.round((overdueRepairs / periodRepairs.length) * 100) : 0,
    };
  }, [repairs, getPeriodData, deviceType, devices]);

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Box>
            <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
              Tableau de Bord Analytique
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Analyses détaillées et métriques de performance
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Tooltip title="Diagnostic des données">
              <IconButton onClick={handleDiagnostic}>
                <AnalyticsIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Actualiser les données">
              <IconButton 
                onClick={handleRefresh}
                disabled={isRefreshing}
                sx={{
                  transform: isRefreshing ? 'rotate(360deg)' : 'none',
                  transition: 'transform 1s linear',
                }}
              >
                <RefreshIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Exporter le rapport">
              <IconButton>
                <DownloadIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>
        
        {/* Filtres */}
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>Période</InputLabel>
              <Select 
                value={period} 
                onChange={(e) => setPeriod(e.target.value)}
                label="Période"
              >
                <MenuItem value="week">Cette semaine</MenuItem>
                <MenuItem value="month">Ce mois</MenuItem>
                <MenuItem value="quarter">Ce trimestre</MenuItem>
                <MenuItem value="year">Cette année</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>Type d'appareil</InputLabel>
              <Select 
                value={deviceType} 
                onChange={(e) => setDeviceType(e.target.value)}
                label="Type d'appareil"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="smartphone">Smartphones</MenuItem>
                <MenuItem value="tablet">Tablettes</MenuItem>
                <MenuItem value="laptop">Ordinateurs portables</MenuItem>
                <MenuItem value="desktop">Ordinateurs fixes</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Box>

      {/* Statistiques principales */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                  <BuildIcon />
                </Avatar>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {generalStats.totalRepairs}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Réparations
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'success.main', mr: 2 }}>
                  <MoneyIcon />
                </Avatar>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {generalStats.totalRevenue.toLocaleString('fr-FR')}€
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Chiffre d'affaires
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Ventes + Réparations payées
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'warning.main', mr: 2 }}>
                  <SpeedIcon />
                </Avatar>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {generalStats.avgRepairTime}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Jours moyens
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'info.main', mr: 2 }}>
                  <CheckCircleIcon />
                </Avatar>
                <Box>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {generalStats.successRate}%
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Taux de réussite
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Métriques de performance */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Réparations urgentes
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 600, mr: 2 }}>
                  {performanceMetrics.urgentRepairs}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  ({performanceMetrics.urgentPercentage}% du total)
                </Typography>
              </Box>
              <LinearProgress 
                variant="determinate" 
                value={performanceMetrics.urgentPercentage} 
                color="warning"
                sx={{ height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Réparations en retard
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Typography variant="h4" sx={{ fontWeight: 600, mr: 2 }}>
                  {performanceMetrics.overdueRepairs}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  ({performanceMetrics.overduePercentage}% du total)
                </Typography>
              </Box>
              <LinearProgress 
                variant="determinate" 
                value={performanceMetrics.overduePercentage} 
                color="error"
                sx={{ height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Onglets pour les analyses détaillées */}
      <Card sx={{ mb: 4 }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
            <Tab label="Vue d'ensemble" icon={<AssessmentIcon />} />
            <Tab label="Réparations" icon={<BuildIcon />} />
            <Tab label="Ventes" icon={<ShoppingCartIcon />} />
            <Tab label="Clients" icon={<PeopleIcon />} />
            <Tab label="Performance" icon={<AnalyticsIcon />} />
          </Tabs>
        </Box>

        <TabPanel value={activeTab} index={0}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Réparations par statut
              </Typography>
              {repairsByStatus.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={repairsByStatus}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percentage }) => `${name} ${percentage}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="count"
                    >
                      {repairsByStatus.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <RechartsTooltip />
                  </PieChart>
                </ResponsiveContainer>
              ) : (
                <Box sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  height: 300,
                  backgroundColor: 'grey.50',
                  borderRadius: 1
                }}>
                  <Typography variant="body2" color="text.secondary">
                    Aucune réparation enregistrée
                  </Typography>
                </Box>
              )}
            </Grid>

            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Évolution du chiffre d'affaires
              </Typography>
              {revenueEvolution.some(day => day.revenue > 0) ? (
                <ResponsiveContainer width="100%" height={300}>
                  <ComposedChart data={revenueEvolution}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis yAxisId="left" />
                    <YAxis yAxisId="right" orientation="right" />
                    <RechartsTooltip />
                    <Legend />
                    <Bar yAxisId="left" dataKey="revenue" fill="#8884d8" name="Revenus (€)" />
                    <Line yAxisId="right" type="monotone" dataKey="repairs" stroke="#82ca9d" name="Réparations" />
                  </ComposedChart>
                </ResponsiveContainer>
              ) : (
                <Box sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  height: 300,
                  backgroundColor: 'grey.50',
                  borderRadius: 1
                }}>
                  <Typography variant="body2" color="text.secondary">
                    Aucune donnée disponible
                  </Typography>
                </Box>
              )}
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={activeTab} index={1}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Répartition par type d'appareil
              </Typography>
              {repairsByDeviceType.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={repairsByDeviceType}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <RechartsTooltip />
                    <Legend />
                    <Bar dataKey="count" fill="#8884d8" />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <Box sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  height: 300,
                  backgroundColor: 'grey.50',
                  borderRadius: 1
                }}>
                  <Typography variant="body2" color="text.secondary">
                    Aucun appareil enregistré
                  </Typography>
                </Box>
              )}
            </Grid>

            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Top 10 des appareils les plus réparés
              </Typography>
              <TableContainer component={Paper} variant="outlined">
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Appareil</TableCell>
                      <TableCell align="right">Réparations</TableCell>
                      <TableCell align="right">CA (€)</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {topDevices.map((item, index) => (
                      <TableRow key={item.device.id}>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Avatar sx={{ width: 24, height: 24, mr: 1, fontSize: '0.75rem' }}>
                              {index + 1}
                            </Avatar>
                            {item.device.brand} {item.device.model}
                          </Box>
                        </TableCell>
                        <TableCell align="right">{item.repairs}</TableCell>
                        <TableCell align="right">{item.revenue.toLocaleString('fr-FR')}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={activeTab} index={2}>
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Évolution des ventes
              </Typography>
              {revenueEvolution.some(day => day.revenue > 0) ? (
                <ResponsiveContainer width="100%" height={400}>
                  <AreaChart data={revenueEvolution}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <RechartsTooltip formatter={(value: any) => [`${value} €`, 'Revenus']} />
                    <Legend />
                    <Area 
                      type="monotone" 
                      dataKey="revenue" 
                      stroke="#8884d8" 
                      fill="#8884d8" 
                      fillOpacity={0.3}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              ) : (
                <Box sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  height: 400,
                  backgroundColor: 'grey.50',
                  borderRadius: 1
                }}>
                  <Typography variant="body2" color="text.secondary">
                    Aucune vente enregistrée
                  </Typography>
                </Box>
              )}
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={activeTab} index={3}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Top 10 des clients
              </Typography>
              <TableContainer component={Paper} variant="outlined">
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Client</TableCell>
                      <TableCell align="right">Réparations</TableCell>
                      <TableCell align="right">CA (€)</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {topClients.map((item, index) => (
                      <TableRow key={item.client.id}>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Avatar sx={{ width: 24, height: 24, mr: 1, fontSize: '0.75rem' }}>
                              {index + 1}
                            </Avatar>
                            {item.client.firstName} {item.client.lastName}
                          </Box>
                        </TableCell>
                        <TableCell align="right">{item.repairs}</TableCell>
                        <TableCell align="right">{item.revenue.toLocaleString('fr-FR')}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </Grid>

            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Répartition des clients
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2">Total clients</Typography>
                  <Chip label={generalStats.totalClients} color="primary" />
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2">Clients actifs</Typography>
                  <Chip label={topClients.length} color="success" />
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2">Nouveaux clients</Typography>
                  <Chip label="0" color="info" />
                </Box>
              </Box>
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={activeTab} index={4}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Performance des techniciens
              </Typography>
              <TableContainer component={Paper} variant="outlined">
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Technicien</TableCell>
                      <TableCell align="right">Réparations</TableCell>
                      <TableCell align="right">Taux de réussite</TableCell>
                      <TableCell align="right">Temps moyen</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {technicianPerformance.map((tech) => (
                      <TableRow key={tech.technician.id}>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Avatar sx={{ width: 24, height: 24, mr: 1, fontSize: '0.75rem' }}>
                              {tech.technician.firstName.charAt(0)}
                            </Avatar>
                            {tech.technician.firstName} {tech.technician.lastName}
                          </Box>
                        </TableCell>
                        <TableCell align="right">{tech.repairs}</TableCell>
                        <TableCell align="right">
                          <Chip 
                            label={`${Math.round((tech.completed / tech.repairs) * 100)}%`}
                            color={tech.completed / tech.repairs >= 0.8 ? 'success' : 'warning'}
                            size="small"
                          />
                        </TableCell>
                        <TableCell align="right">{Math.round(tech.avgTime)}j</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </Grid>

            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                Métriques de performance
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                <Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2">Temps de réparation moyen</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {generalStats.avgRepairTime} jours
                    </Typography>
                  </Box>
                  <LinearProgress 
                    variant="determinate" 
                    value={Math.min(generalStats.avgRepairTime * 10, 100)} 
                    color="primary"
                  />
                </Box>
                
                <Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2">Taux de réussite</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {generalStats.successRate}%
                    </Typography>
                  </Box>
                  <LinearProgress 
                    variant="determinate" 
                    value={generalStats.successRate} 
                    color="success"
                  />
                </Box>
                
                <Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2">Réparations urgentes</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {performanceMetrics.urgentPercentage}%
                    </Typography>
                  </Box>
                  <LinearProgress 
                    variant="determinate" 
                    value={performanceMetrics.urgentPercentage} 
                    color="warning"
                  />
                </Box>
              </Box>
            </Grid>
          </Grid>
        </TabPanel>
      </Card>
    </Box>
  );
};

export default Statistics;

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
} from '@mui/material';
import {
  BarChart as BarChartIcon,
  PieChart as PieChartIcon,
  TrendingUp as TrendingUpIcon,
} from '@mui/icons-material';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  Area,
  AreaChart,
} from 'recharts';
import { useAppStore } from '../../store';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82CA9D'];

const Statistics: React.FC = () => {
  const {
    repairs,
    sales,
    devices,
    repairStatuses,
  } = useAppStore();

  const [period, setPeriod] = useState('month');
  const [deviceType, setDeviceType] = useState('all');

  // Calcul des statistiques des réparations par statut
  const repairsByStatus = useMemo(() => {
    const statusCounts = repairStatuses.map(status => ({
      name: status.name,
      count: repairs.filter(repair => repair.status === status.id).length,
      color: status.color,
    }));
    const filteredStatusCounts = statusCounts.filter(item => item.count > 0);
    
    // Si pas de données, retourner un tableau vide pour afficher l'état vierge
    return filteredStatusCounts;
  }, [repairs, repairStatuses]);

  // Calcul des réparations par type d'appareil
  const repairsByDeviceType = useMemo(() => {
    // Créer un Map pour éviter les doublons
    const deviceTypeMap = new Map<string, number>();
    
    repairs.forEach(repair => {
      const repairDevice = devices.find(d => d.id === repair.deviceId);
      if (repairDevice) {
        const deviceType = repairDevice.type;
        deviceTypeMap.set(deviceType, (deviceTypeMap.get(deviceType) || 0) + 1);
      }
    });
    
    // Convertir le Map en tableau pour le graphique
    const deviceTypeCounts = Array.from(deviceTypeMap.entries()).map(([type, count], index) => ({
      name: type.charAt(0).toUpperCase() + type.slice(1),
      count,
      color: COLORS[index % COLORS.length],
    }));
    
    // Si pas de données, retourner un tableau vide pour afficher l'état vierge
    return deviceTypeCounts;
  }, [repairs, devices]);

  // Calcul de l'évolution du chiffre d'affaires (simulation sur les 12 derniers mois)
  const revenueEvolution = useMemo(() => {
    const months = [];
    const currentDate = new Date();
    
    for (let i = 11; i >= 0; i--) {
      const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const monthName = date.toLocaleDateString('fr-FR', { month: 'short' });
      
      // Calculer le revenu pour ce mois (basé sur les ventes existantes)
      const monthRevenue = sales
        .filter(sale => {
          const saleDate = new Date(sale.createdAt);
          return saleDate.getMonth() === date.getMonth() && 
                 saleDate.getFullYear() === date.getFullYear();
        })
        .reduce((sum, sale) => sum + sale.total, 0);
      
      months.push({
        month: monthName,
        revenue: monthRevenue,
      });
    }
    
    // Retourner les vraies données (même si vides)
    return months;
  }, [sales]);

  // Calcul des statistiques détaillées
  const repairStats = useMemo(() => {
    const totalRepairs = repairs.length;
    const completedRepairs = repairs.filter(r => r.status === 'completed').length;
    const inProgressRepairs = repairs.filter(r => r.status === 'in_progress').length;
    const successRate = totalRepairs > 0 ? Math.round((completedRepairs / totalRepairs) * 100) : 0;
    
    return {
      total: totalRepairs,
      completed: completedRepairs,
      inProgress: inProgressRepairs,
      successRate,
    };
  }, [repairs]);

  const salesStats = useMemo(() => {
    const totalSales = sales.length;
    const totalRevenue = sales.reduce((sum, sale) => sum + sale.total, 0);
    const averageSale = totalSales > 0 ? totalRevenue / totalSales : 0;
    const completedSales = sales.filter(s => s.status === 'completed').length;
    
    return {
      total: totalSales,
      revenue: totalRevenue,
      average: averageSale,
      completed: completedSales,
    };
  }, [sales]);

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Statistiques
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Analyses et rapports de l'atelier
        </Typography>
        
        {/* Message d'état vierge */}
        {repairs.length === 0 && sales.length === 0 && (
          <Box sx={{ 
            mt: 2, 
            p: 2, 
            backgroundColor: 'info.light', 
            borderRadius: 1,
            border: '1px solid',
            borderColor: 'info.main'
          }}>
            <Typography variant="body2" color="info.dark">
              📊 <strong>Site vierge :</strong> Aucune donnée disponible. Les statistiques s'afficheront automatiquement 
              lorsque vous ajouterez des clients, appareils, réparations et ventes.
            </Typography>
          </Box>
        )}
      </Box>

      {/* Filtres */}
      <Box sx={{ mb: 3 }}>
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
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <BarChartIcon sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Réparations par statut</Typography>
              </Box>
              {repairsByStatus.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={repairsByStatus}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip />
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
                    Aucune réparation enregistrée
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <PieChartIcon sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Répartition par type d'appareil</Typography>
              </Box>
              {repairsByDeviceType.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={repairsByDeviceType}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="count"
                    >
                      {repairsByDeviceType.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
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
                    Aucun appareil enregistré
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <TrendingUpIcon sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Évolution du chiffre d'affaires</Typography>
              </Box>
              {revenueEvolution.some(month => month.revenue > 0) ? (
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={revenueEvolution}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="month" />
                    <YAxis />
                    <Tooltip formatter={(value) => [`${value} €`, 'Revenus']} />
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
                  height: 300,
                  backgroundColor: 'grey.50',
                  borderRadius: 1
                }}>
                  <Typography variant="body2" color="text.secondary">
                    Aucune vente enregistrée
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Statistiques détaillées */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Statistiques des réparations
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Total des réparations</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {repairStats.total}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Réparations terminées</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {repairStats.completed}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Réparations en cours</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {repairStats.inProgress}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Taux de réussite</Typography>
                  <Chip 
                    label={`${repairStats.successRate}%`}
                    color={repairStats.successRate >= 80 ? 'success' : repairStats.successRate >= 60 ? 'warning' : 'error'}
                    size="small"
                  />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Statistiques des ventes
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Total des ventes</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {salesStats.total}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Chiffre d'affaires total</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {salesStats.revenue.toLocaleString('fr-FR')} €
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Vente moyenne</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {salesStats.average.toFixed(2)} €
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Ventes complétées</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {salesStats.completed}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Statistics;

import React from 'react';
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
} from '@mui/material';
import {
  BarChart as BarChartIcon,
  PieChart as PieChartIcon,
  TrendingUp as TrendingUpIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const Statistics: React.FC = () => {
  const {
    repairs,
    sales,
    dashboardStats,
  } = useAppStore();

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
      </Box>

      {/* Filtres */}
      <Box sx={{ mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>Période</InputLabel>
              <Select defaultValue="month" label="Période">
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
              <Select defaultValue="all" label="Type d'appareil">
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
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 300 }}>
                <Box sx={{ textAlign: 'center' }}>
                  <BarChartIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
                  <Typography variant="h6" color="text.secondary" gutterBottom>
                    Graphique en cours de développement
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Intégration de Recharts prévue
                  </Typography>
                </Box>
              </Box>
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
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 300 }}>
                <Box sx={{ textAlign: 'center' }}>
                  <PieChartIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
                  <Typography variant="h6" color="text.secondary" gutterBottom>
                    Graphique en cours de développement
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Intégration de Recharts prévue
                  </Typography>
                </Box>
              </Box>
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
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 300 }}>
                <Box sx={{ textAlign: 'center' }}>
                  <TrendingUpIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
                  <Typography variant="h6" color="text.secondary" gutterBottom>
                    Graphique en cours de développement
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Intégration de Recharts prévue
                  </Typography>
                </Box>
              </Box>
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
                    {repairs.length}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Réparations terminées</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {repairs.filter(r => r.status === 'completed').length}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Réparations en cours</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {repairs.filter(r => r.status === 'in_progress').length}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Taux de réussite</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {repairs.length > 0 
                      ? Math.round((repairs.filter(r => r.status === 'completed').length / repairs.length) * 100)
                      : 0}%
                  </Typography>
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
                    {sales.length}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Chiffre d'affaires total</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {sales.reduce((sum, sale) => sum + sale.total, 0).toLocaleString('fr-FR')} €
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Vente moyenne</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {sales.length > 0 
                      ? (sales.reduce((sum, sale) => sum + sale.total, 0) / sales.length).toFixed(2)
                      : 0} €
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Ventes complétées</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {sales.filter(s => s.status === 'completed').length}
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

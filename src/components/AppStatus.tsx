import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Grid,
  Alert,
  Button,
} from '@mui/material';
import {
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { useAppStore } from '../store';

const AppStatus: React.FC = () => {
  const {
    clients,
    devices,
    services,
    parts,
    products,
    repairs,
    sales,
    appointments,
    messages,
    loadClients,
    loadDevices,
    loadServices,
    loadParts,
    loadProducts,
    loadRepairs,
    loadSales,
    loadAppointments,
  } = useAppStore();

  const dataStatus = [
    {
      name: 'Clients',
      count: clients.length,
      status: clients.length > 0 ? 'success' : 'error',
      icon: clients.length > 0 ? <CheckCircleIcon /> : <ErrorIcon />,
    },
    {
      name: 'Appareils',
      count: devices.length,
      status: devices.length > 0 ? 'success' : 'error',
      icon: devices.length > 0 ? <CheckCircleIcon /> : <ErrorIcon />,
    },
    {
      name: 'Services',
      count: services.length,
      status: services.length > 0 ? 'success' : 'error',
      icon: services.length > 0 ? <CheckCircleIcon /> : <ErrorIcon />,
    },
    {
      name: 'Pièces détachées',
      count: parts.length,
      status: parts.length > 0 ? 'success' : 'error',
      icon: parts.length > 0 ? <CheckCircleIcon /> : <ErrorIcon />,
    },
    {
      name: 'Produits',
      count: products.length,
      status: products.length > 0 ? 'success' : 'error',
      icon: products.length > 0 ? <CheckCircleIcon /> : <ErrorIcon />,
    },
    {
      name: 'Réparations',
      count: repairs.length,
      status: repairs.length > 0 ? 'success' : 'warning',
      icon: repairs.length > 0 ? <CheckCircleIcon /> : <WarningIcon />,
    },
    {
      name: 'Ventes',
      count: sales.length,
      status: sales.length > 0 ? 'success' : 'warning',
      icon: sales.length > 0 ? <CheckCircleIcon /> : <WarningIcon />,
    },
    {
      name: 'Rendez-vous',
      count: appointments.length,
      status: appointments.length > 0 ? 'success' : 'warning',
      icon: appointments.length > 0 ? <CheckCircleIcon /> : <WarningIcon />,
    },
    {
      name: 'Messages',
      count: messages.length,
      status: messages.length > 0 ? 'success' : 'warning',
      icon: messages.length > 0 ? <CheckCircleIcon /> : <WarningIcon />,
    },
  ];

  const handleRefreshData = async () => {
    try {
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
    } catch (error) {
      console.error('Erreur lors du rechargement des données:', error);
    }
  };

  const totalDataCount = dataStatus.reduce((sum, item) => sum + item.count, 0);
  const successCount = dataStatus.filter(item => item.status === 'success').length;
  const errorCount = dataStatus.filter(item => item.status === 'error').length;
  const warningCount = dataStatus.filter(item => item.status === 'warning').length;

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            État des données
          </Typography>
          <Button
            startIcon={<RefreshIcon />}
            onClick={handleRefreshData}
            size="small"
          >
            Actualiser
          </Button>
        </Box>

        {/* Résumé global */}
        <Box sx={{ mb: 3 }}>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h4" color="success.main" sx={{ fontWeight: 600 }}>
                  {successCount}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Pages avec données
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h4" color="warning.main" sx={{ fontWeight: 600 }}>
                  {warningCount}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Pages vides (normales)
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h4" color="error.main" sx={{ fontWeight: 600 }}>
                  {errorCount}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Pages sans données
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </Box>

        {/* Détail par page */}
        <Grid container spacing={2}>
          {dataStatus.map((item) => (
            <Grid item xs={12} sm={6} md={4} key={item.name}>
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  p: 2,
                  border: '1px solid',
                  borderColor: 'divider',
                  borderRadius: 1,
                  backgroundColor: item.status === 'success' ? 'success.light' : 
                                 item.status === 'warning' ? 'warning.light' : 'error.light',
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Box sx={{ color: item.status === 'success' ? 'success.main' : 
                                   item.status === 'warning' ? 'warning.main' : 'error.main' }}>
                    {item.icon}
                  </Box>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {item.name}
                  </Typography>
                </Box>
                <Chip
                  label={item.count}
                  size="small"
                  color={item.status === 'success' ? 'success' : 
                         item.status === 'warning' ? 'warning' : 'error'}
                />
              </Box>
            </Grid>
          ))}
        </Grid>

        {/* Messages d'information */}
        {errorCount > 0 && (
          <Alert severity="error" sx={{ mt: 2 }}>
            {errorCount} page(s) n'ont pas de données. Les données de démonstration devraient être chargées automatiquement.
          </Alert>
        )}

        {successCount === dataStatus.length && (
          <Alert severity="success" sx={{ mt: 2 }}>
            ✅ Toutes les pages ont des données fonctionnelles !
          </Alert>
        )}

        <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
          Total : {totalDataCount} éléments de données chargés
        </Typography>
      </CardContent>
    </Card>
  );
};

export default AppStatus;

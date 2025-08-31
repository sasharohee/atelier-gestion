import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  Alert,
} from '@mui/material';
import {
  LocalShipping as ShippingIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
  Cancel as CancelIcon,
  Euro as EuroIcon,
} from '@mui/icons-material';

interface OrderStatsProps {
  stats: {
    total: number;
    pending: number;
    confirmed: number;
    shipped: number;
    delivered: number;
    cancelled: number;
    totalAmount: number;
  };
}

const OrderStats: React.FC<OrderStatsProps> = ({ stats }) => {
  const statCards = [
    {
      title: 'Total Commandes',
      value: stats.total,
      icon: <ShippingIcon />,
      color: '#2196f3',
      description: 'Toutes les commandes'
    },
    {
      title: 'En Attente',
      value: stats.pending,
      icon: <ScheduleIcon />,
      color: '#ff9800',
      description: 'Commandes en attente'
    },
    {
      title: 'Confirmées',
      value: stats.confirmed,
      icon: <CheckCircleIcon />,
      color: '#2196f3',
      description: 'Commandes confirmées'
    },
    {
      title: 'Expédiées',
      value: stats.shipped,
      icon: <ShippingIcon />,
      color: '#9c27b0',
      description: 'Commandes expédiées'
    },
    {
      title: 'Livrées',
      value: stats.delivered,
      icon: <CheckCircleIcon />,
      color: '#4caf50',
      description: 'Commandes livrées'
    },
    {
      title: 'Annulées',
      value: stats.cancelled,
      icon: <CancelIcon />,
      color: '#f44336',
      description: 'Commandes annulées'
    }
  ];

  return (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
        Statistiques des Commandes
      </Typography>
      
      {stats.total === 0 ? (
        <Alert severity="info" sx={{ mb: 2 }}>
          Aucune commande enregistrée. Les statistiques apparaîtront ici une fois que vous aurez créé vos premières commandes.
        </Alert>
      ) : null}
      
      <Grid container spacing={2}>
        {statCards.map((card) => (
          <Grid item xs={12} sm={6} md={4} lg={2} key={card.title}>
            <Card>
              <CardContent sx={{ textAlign: 'center', p: 2 }}>
                <Box
                  sx={{
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    width: 48,
                    height: 48,
                    borderRadius: '50%',
                    backgroundColor: `${card.color}20`,
                    color: card.color,
                    mx: 'auto',
                    mb: 1,
                  }}
                >
                  {card.icon}
                </Box>
                <Typography variant="h4" sx={{ fontWeight: 700, mb: 0.5 }}>
                  {card.value || 0}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                  {card.title}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {card.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Montant total */}
      <Card sx={{ mt: 2, backgroundColor: '#f8f9fa' }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Box
                sx={{
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                  width: 48,
                  height: 48,
                  borderRadius: '50%',
                  backgroundColor: '#4caf5020',
                  color: '#4caf50',
                  mr: 2,
                }}
              >
                <EuroIcon />
              </Box>
              <Box>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Montant Total
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Valeur totale des commandes
                </Typography>
              </Box>
            </Box>
            <Typography variant="h4" sx={{ fontWeight: 700, color: '#4caf50' }}>
              {(stats.totalAmount || 0).toLocaleString('fr-FR', {
                style: 'currency',
                currency: 'EUR'
              })}
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default OrderStats;

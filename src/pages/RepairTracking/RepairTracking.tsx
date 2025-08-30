import React, { useState } from 'react';
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
  Divider,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Search as SearchIcon,
  Home as HomeIcon,
  Build as BuildIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Schedule as ScheduleIcon,
  Euro as EuroIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
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
    type: string;
  };
  technician?: {
    firstName: string;
    lastName: string;
  };
}

const RepairTracking: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [repairNumber, setRepairNumber] = useState('');
  const [repair, setRepair] = useState<RepairData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [detailsOpen, setDetailsOpen] = useState(false);

  // Statuts de réparation en français
  const repairStatuses = {
    new: 'Nouvelle',
    in_progress: 'En cours',
    waiting_parts: 'En attente de pièces',
    completed: 'Terminée',
    delivered: 'Livrée',
    cancelled: 'Annulée',
    waiting_delivery: 'En attente de livraison',
    returned: 'Retournée'
  };

  const getStatusLabel = (status: string) => {
    return repairStatuses[status as keyof typeof repairStatuses] || status;
  };

  const getStatusColor = (status: string) => {
    const colors: { [key: string]: 'default' | 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning' } = {
      new: 'info',
      in_progress: 'primary',
      waiting_parts: 'warning',
      completed: 'success',
      delivered: 'success',
      cancelled: 'error',
      waiting_delivery: 'secondary',
      returned: 'default'
    };
    return colors[status] || 'default';
  };

  const handleSearch = async () => {
    if (!email || !repairNumber) {
      setError('Veuillez remplir tous les champs');
      return;
    }

    setLoading(true);
    setError('');
    setRepair(null);

    try {
      const result = await repairTrackingService.getRepairTracking(repairNumber, email);
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
  };

  return (
    <Box sx={{ p: 3, maxWidth: 800, mx: 'auto' }}>
      {/* Bouton retour à l'accueil */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h4" component="h1" sx={{ fontWeight: 600, color: '#1976d2' }}>
          🔍 Suivi de Réparation
        </Typography>
        <Button
          variant="outlined"
          startIcon={<HomeIcon />}
          onClick={() => navigate('/')}
          sx={{ borderRadius: 2 }}
        >
          Accueil
        </Button>
      </Box>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom sx={{ color: '#1976d2', mb: 3 }}>
            Rechercher votre réparation
          </Typography>
          
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Adresse email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="votre@email.com"
                InputProps={{
                  startAdornment: <EmailIcon sx={{ mr: 1, color: 'text.secondary' }} />,
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
                InputProps={{
                  startAdornment: <BuildIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                }}
              />
            </Grid>
          </Grid>

          <Box sx={{ mt: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
            <Button
              variant="contained"
              startIcon={loading ? <CircularProgress size={20} /> : <SearchIcon />}
              onClick={handleSearch}
              disabled={loading || !email || !repairNumber}
              sx={{ borderRadius: 2 }}
            >
              {loading ? 'Recherche...' : 'Rechercher'}
            </Button>
            <Button
              variant="outlined"
              onClick={handleReset}
              disabled={loading}
              sx={{ borderRadius: 2 }}
            >
              Réinitialiser
            </Button>
          </Box>

          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Résultat de la recherche */}
      {repair && (
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6" sx={{ color: '#1976d2' }}>
                📋 Détails de la réparation
              </Typography>
              <Chip
                label={getStatusLabel(repair.status)}
                color={getStatusColor(repair.status)}
                variant="filled"
                sx={{ fontWeight: 'bold' }}
              />
            </Box>

            <Grid container spacing={3}>
              {/* Informations de base */}
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: '#1976d2' }}>
                  📝 Informations générales
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Typography variant="body2">
                    <strong>Numéro:</strong> {repair.repairNumber}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Description:</strong> {repair.description}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Problème:</strong> {repair.issue || 'Non spécifié'}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Prix:</strong> {repair.totalPrice} €
                  </Typography>
                </Box>
              </Grid>

              {/* Informations client */}
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: '#1976d2' }}>
                  👤 Informations client
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Typography variant="body2">
                    <strong>Nom:</strong> {repair.client.firstName} {repair.client.lastName}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Email:</strong> {repair.client.email}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Téléphone:</strong> {repair.client.phone || 'Non renseigné'}
                  </Typography>
                </Box>
              </Grid>

              {/* Informations appareil */}
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: '#1976d2' }}>
                  📱 Appareil
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Typography variant="body2">
                    <strong>Marque:</strong> {repair.device.brand}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Modèle:</strong> {repair.device.model}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Type:</strong> {repair.device.type}
                  </Typography>
                </Box>
              </Grid>

              {/* Dates et technicien */}
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: '#1976d2' }}>
                  📅 Dates et technicien
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Typography variant="body2">
                    <strong>Date de création:</strong> {format(new Date(repair.createdAt), 'dd/MM/yyyy', { locale: fr })}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Date limite:</strong> {format(new Date(repair.dueDate), 'dd/MM/yyyy', { locale: fr })}
                  </Typography>
                  {repair.technician && (
                    <Typography variant="body2">
                      <strong>Technicien:</strong> {repair.technician.firstName} {repair.technician.lastName}
                    </Typography>
                  )}
                </Box>
              </Grid>
            </Grid>

            <Divider sx={{ my: 3 }} />

            {/* Statut détaillé */}
            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="h6" sx={{ mb: 2, color: '#1976d2' }}>
                📊 Statut actuel
              </Typography>
              <Chip
                label={getStatusLabel(repair.status)}
                color={getStatusColor(repair.status)}
                size="large"
                sx={{ 
                  fontSize: '1.1rem', 
                  fontWeight: 'bold',
                  px: 3,
                  py: 1
                }}
              />
            </Box>
          </CardContent>
        </Card>
      )}

      {/* Dialog de détails */}
      <Dialog open={detailsOpen} onClose={() => setDetailsOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6">Détails complets de la réparation</Typography>
            <IconButton onClick={() => setDetailsOpen(false)}>
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          {repair && (
            <Box>
              {/* Contenu détaillé ici */}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailsOpen(false)}>Fermer</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default RepairTracking;

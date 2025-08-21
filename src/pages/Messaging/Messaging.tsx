import React from 'react';
import {
  Box,
  Paper,
  Typography,
  Container,
  Chip,
  LinearProgress,
  Alert,
} from '@mui/material';
import {
  Construction as ConstructionIcon,
  DeveloperMode as DeveloperIcon,
  Schedule as ScheduleIcon,
  Code as CodeIcon,
} from '@mui/icons-material';

const Messaging: React.FC = () => {
  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ textAlign: 'center', mb: 4 }}>
        <ConstructionIcon sx={{ fontSize: 80, color: 'warning.main', mb: 2 }} />
        <Typography variant="h3" component="h1" gutterBottom sx={{ fontWeight: 'bold' }}>
          Page en Construction
        </Typography>
        <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
          La messagerie est actuellement en cours de développement
        </Typography>
      </Box>

      <Paper elevation={3} sx={{ p: 4, mb: 4, borderRadius: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
          <DeveloperIcon sx={{ fontSize: 40, color: 'primary.main', mr: 2 }} />
          <Box>
            <Typography variant="h5" component="h2" gutterBottom>
              Développement en cours
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Notre équipe de développement travaille activement sur cette fonctionnalité
            </Typography>
          </Box>
        </Box>

        <Box sx={{ mb: 3 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
            <ScheduleIcon sx={{ mr: 1 }} />
            Fonctionnalités prévues
          </Typography>
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 2 }}>
            <Chip label="Messages en temps réel" color="primary" variant="outlined" />
            <Chip label="Notifications push" color="primary" variant="outlined" />
            <Chip label="Pièces jointes" color="primary" variant="outlined" />
            <Chip label="Historique des conversations" color="primary" variant="outlined" />
            <Chip label="Recherche avancée" color="primary" variant="outlined" />
            <Chip label="Statuts de lecture" color="primary" variant="outlined" />
          </Box>
        </Box>

        <Box sx={{ mb: 3 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
            <CodeIcon sx={{ mr: 1 }} />
            Progression du développement
          </Typography>
          <Box sx={{ mb: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Interface utilisateur
            </Typography>
            <LinearProgress variant="determinate" value={85} sx={{ height: 8, borderRadius: 4 }} />
          </Box>
          <Box sx={{ mb: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Logique métier
            </Typography>
            <LinearProgress variant="determinate" value={60} sx={{ height: 8, borderRadius: 4 }} />
          </Box>
          <Box sx={{ mb: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Intégration base de données
            </Typography>
            <LinearProgress variant="determinate" value={45} sx={{ height: 8, borderRadius: 4 }} />
          </Box>
          <Box>
            <Typography variant="body2" color="text.secondary">
              Tests et optimisation
            </Typography>
            <LinearProgress variant="determinate" value={25} sx={{ height: 8, borderRadius: 4 }} />
          </Box>
        </Box>

        <Alert severity="info" sx={{ borderRadius: 2 }}>
          <Typography variant="body2">
            <strong>Estimation de disponibilité :</strong> La date de disponibilité n'est pas encore fixée, 
            mais cette fonctionnalité sera disponible ultérieurement. Nous vous tiendrons informés des avancées du développement.
          </Typography>
        </Alert>
      </Paper>

      <Paper elevation={2} sx={{ p: 3, borderRadius: 3, bgcolor: 'grey.50' }}>
        <Typography variant="h6" gutterBottom>
          En attendant...
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Vous pouvez utiliser les autres fonctionnalités de l'application comme le catalogue, 
          les rendez-vous, ou la gestion des réparations. La messagerie sera bientôt disponible 
          pour améliorer votre expérience de communication avec vos clients.
        </Typography>
      </Paper>
    </Container>
  );
};

export default Messaging;

import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Container,
  Alert,
  Divider,
  Chip,
  Grid,
  Paper
} from '@mui/material';
import {
  Lock as LockIcon,
  Email as EmailIcon,
  Support as SupportIcon,
  Refresh as RefreshIcon,
  Logout as LogoutIcon,
  CheckCircle as CheckIcon,
  Euro as EuroIcon
} from '@mui/icons-material';
import { useAuth } from '../../hooks/useAuth';
import { useSubscription } from '../../hooks/useSubscription';
import { supabase } from '../../lib/supabase';
import { useNavigate } from 'react-router-dom';

const SubscriptionBlocked: React.FC = () => {
  const { user } = useAuth();
  const { subscriptionStatus, refreshStatus, loading } = useSubscription();
  const navigate = useNavigate();

  const handleRefresh = async () => {
    await refreshStatus();
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/auth');
  };

  const handleContactSupport = () => {
    window.open('mailto:support@exemple.com?subject=Activation de mon abonnement', '_blank');
  };

  if (loading) {
    return (
      <Container maxWidth="sm">
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            minHeight: '100vh',
            gap: 2
          }}
        >
          <Typography variant="h6" color="text.secondary">
            Vérification du statut d'abonnement...
          </Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: 'background.default',
        py: 6
      }}
    >
      <Container maxWidth="lg">
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 4
          }}
        >
          {/* En-tête */}
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 3,
              textAlign: 'center'
            }}
          >
            <Paper
              elevation={2}
              sx={{
                p: 3,
                borderRadius: '50%',
                backgroundColor: 'error.main',
                color: 'white',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              <LockIcon sx={{ fontSize: 40 }} />
            </Paper>
            <Box>
              <Typography variant="h3" component="h1" color="text.primary" fontWeight="bold" gutterBottom>
                Accès Verrouillé
              </Typography>
              <Typography variant="h6" color="text.secondary">
                Votre compte nécessite une activation
              </Typography>
            </Box>
          </Box>

          <Grid container spacing={4} justifyContent="center">
            {/* Carte principale - Informations */}
            <Grid item xs={12} md={6}>
              <Card elevation={2}>
                <CardContent sx={{ p: 4 }}>
                  <Typography variant="h5" component="h2" gutterBottom fontWeight="bold" color="primary.main">
                    Statut du compte
                  </Typography>
                  
                  <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
                    Pour accéder à l'atelier de gestion, votre abonnement doit être activé par un administrateur.
                  </Typography>

                  {/* Informations utilisateur */}
                  {subscriptionStatus && (
                    <Alert 
                      severity="info" 
                      sx={{ mb: 4 }}
                      icon={<SupportIcon />}
                    >
                      <Typography variant="body2" fontWeight="medium">
                        {subscriptionStatus.first_name} {subscriptionStatus.last_name}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {subscriptionStatus.email}
                      </Typography>
                    </Alert>
                  )}

                  <Divider sx={{ my: 3 }} />

                  {/* Instructions */}
                  <Box sx={{ mb: 4 }}>
                    <Typography variant="h6" gutterBottom fontWeight="bold" color="primary.main">
                      Procédure d'activation
                    </Typography>
                    <Box sx={{ mt: 2 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                        <CheckIcon sx={{ color: 'success.main', mr: 2, fontSize: 20 }} />
                        <Typography variant="body1">Contactez notre équipe support</Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                        <CheckIcon sx={{ color: 'success.main', mr: 2, fontSize: 20 }} />
                        <Typography variant="body1">Précisez votre demande d'activation</Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                        <CheckIcon sx={{ color: 'success.main', mr: 2, fontSize: 20 }} />
                        <Typography variant="body1">Activation sous 24h par un administrateur</Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <CheckIcon sx={{ color: 'success.main', mr: 2, fontSize: 20 }} />
                        <Typography variant="body1">Confirmation par email</Typography>
                      </Box>
                    </Box>
                  </Box>

                  {/* Actions */}
                  <Box
                    sx={{
                      display: 'flex',
                      flexDirection: { xs: 'column', sm: 'row' },
                      gap: 2
                    }}
                  >
                    <Button
                      variant="contained"
                      size="large"
                      startIcon={<EmailIcon />}
                      onClick={handleContactSupport}
                      sx={{ flex: 1 }}
                    >
                      Contacter le Support
                    </Button>

                    <Button
                      variant="outlined"
                      size="large"
                      startIcon={<RefreshIcon />}
                      onClick={handleRefresh}
                      sx={{ flex: 1 }}
                    >
                      Vérifier le Statut
                    </Button>
                  </Box>

                  <Box sx={{ mt: 2 }}>
                    <Button
                      variant="text"
                      size="large"
                      startIcon={<LogoutIcon />}
                      onClick={handleLogout}
                      sx={{ color: 'text.secondary' }}
                    >
                      Se Déconnecter
                    </Button>
                  </Box>
                </CardContent>
              </Card>
            </Grid>

            {/* Carte des tarifs */}
            <Grid item xs={12} md={6}>
              <Card elevation={2}>
                <CardContent sx={{ p: 4 }}>
                  <Box sx={{ textAlign: 'center', mb: 4 }}>
                    <Typography variant="h5" component="h2" gutterBottom fontWeight="bold" color="primary.main">
                      Abonnement Premium
                    </Typography>
                    <Typography variant="body1" color="text.secondary">
                      Accès complet à l'atelier de gestion
                    </Typography>
                  </Box>

                  {/* Prix */}
                  <Box sx={{ textAlign: 'center', mb: 4 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 1 }}>
                      <Typography variant="h2" component="span" fontWeight="bold" color="primary.main">
                        19,99
                      </Typography>
                      <EuroIcon sx={{ fontSize: 32, ml: 1, color: 'primary.main' }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" gutterBottom>
                      par mois
                    </Typography>
                    <Chip 
                      label="Prix réduit" 
                      color="success"
                      size="small"
                      sx={{ fontWeight: 'bold' }} 
                    />
                  </Box>

                  <Divider sx={{ my: 3 }} />

                  {/* Fonctionnalités */}
                  <Box sx={{ mb: 4 }}>
                    <Typography variant="h6" gutterBottom fontWeight="bold" color="primary.main">
                      Fonctionnalités incluses
                    </Typography>
                    <Grid container spacing={2}>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <CheckIcon sx={{ color: 'success.main', mr: 1, fontSize: 18 }} />
                          <Typography variant="body2">Gestion clients</Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <CheckIcon sx={{ color: 'success.main', mr: 1, fontSize: 18 }} />
                          <Typography variant="body2">Suivi réparations</Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <CheckIcon sx={{ color: 'success.main', mr: 1, fontSize: 18 }} />
                          <Typography variant="body2">Rendez-vous</Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <CheckIcon sx={{ color: 'success.main', mr: 1, fontSize: 18 }} />
                          <Typography variant="body2">Catalogue produits</Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <CheckIcon sx={{ color: 'success.main', mr: 1, fontSize: 18 }} />
                          <Typography variant="body2">Statistiques</Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <CheckIcon sx={{ color: 'success.main', mr: 1, fontSize: 18 }} />
                          <Typography variant="body2">Support prioritaire</Typography>
                        </Box>
                      </Grid>
                    </Grid>
                  </Box>

                  {/* Bouton d'action */}
                  <Button
                    variant="contained"
                    size="large"
                    fullWidth
                    startIcon={<EmailIcon />}
                    onClick={handleContactSupport}
                    sx={{ py: 1.5 }}
                  >
                    Activer mon abonnement
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          {/* Informations supplémentaires */}
          <Box sx={{ textAlign: 'center', mt: 4 }}>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              Support disponible : support@exemple.com
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Délai de traitement : 24h maximum
            </Typography>
          </Box>
        </Box>
      </Container>
    </Box>
  );
};

export default SubscriptionBlocked;

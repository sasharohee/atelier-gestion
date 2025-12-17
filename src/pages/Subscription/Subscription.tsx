import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  Button,
  Chip,
  Divider,
  Grid,
  Alert,
  CircularProgress,
  Paper,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  useTheme,
  alpha,
} from '@mui/material';
import {
  CheckCircle as CheckIcon,
  Cancel as CancelIcon,
  CreditCard as CreditCardIcon,
  CalendarToday as CalendarIcon,
  Euro as EuroIcon,
  Settings as SettingsIcon,
  Refresh as RefreshIcon,
  Receipt as ReceiptIcon,
  Info as InfoIcon,
  Star as StarIcon,
} from '@mui/icons-material';
import { useSubscription } from '../../hooks/useSubscription';
import { useAuth } from '../../hooks/useAuth';
import { supabase } from '../../lib/supabase';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const Subscription: React.FC = () => {
  const { user } = useAuth();
  const { subscriptionStatus, loading, refreshStatus } = useSubscription();
  const theme = useTheme();
  const [isLoadingPortal, setIsLoadingPortal] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Debug: Afficher les informations de débogage en développement
  // DOIT être avant tous les returns conditionnels
  useEffect(() => {
    if (import.meta.env.DEV && subscriptionStatus) {
      console.log('Subscription Status:', {
        isActive: subscriptionStatus.is_active,
        hasCustomerId: !!subscriptionStatus.stripe_customer_id,
        hasSubscriptionId: !!subscriptionStatus.stripe_subscription_id,
        subscriptionType: subscriptionStatus.subscription_type,
        fullStatus: subscriptionStatus,
      });
    }
  }, [subscriptionStatus]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refreshStatus();
      toast.success('Statut mis à jour');
    } catch (error) {
      toast.error('Erreur lors de la mise à jour');
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleManageSubscription = async () => {
    if (!subscriptionStatus?.stripe_customer_id) {
      toast.error('Aucun abonnement Stripe trouvé');
      return;
    }

    setIsLoadingPortal(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session) {
        toast.error('Vous devez être connecté');
        return;
      }

      const { data, error } = await supabase.functions.invoke('stripe-portal', {
        body: {
          returnUrl: `${window.location.origin}/app/subscription`,
        },
        headers: {
          Authorization: `Bearer ${session.access_token}`,
        },
      });

      if (error) {
        throw error;
      }

      if (data?.url) {
        window.location.href = data.url;
      } else {
        throw new Error('URL du portail non disponible');
      }
    } catch (error) {
      console.error('Erreur lors de l\'accès au portail:', error);
      toast.error(error instanceof Error ? error.message : 'Erreur lors de l\'accès au portail client');
      setIsLoadingPortal(false);
    }
  };

  const getSubscriptionTypeLabel = (type?: string) => {
    switch (type) {
      case 'premium_monthly':
        return 'Premium Mensuel';
      case 'premium_yearly':
        return 'Premium Annuel';
      case 'premium':
        return 'Premium';
      case 'enterprise':
        return 'Enterprise';
      default:
        return 'Gratuit';
    }
  };

  const getSubscriptionPrice = (type?: string) => {
    switch (type) {
      case 'premium_monthly':
        return '20€/mois';
      case 'premium_yearly':
        return '200€/an';
      default:
        return 'Gratuit';
    }
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  const isActive = subscriptionStatus?.is_active || false;
  const periodEnd = subscriptionStatus?.stripe_current_period_end 
    ? new Date(subscriptionStatus.stripe_current_period_end)
    : null;

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* Message Bêta */}
      <Alert 
        severity="info" 
        icon={<InfoIcon />}
        sx={{ 
          mb: 3,
          borderRadius: 2,
          '& .MuiAlert-icon': {
            fontSize: '1.5rem'
          }
        }}
      >
        <Typography variant="body2" sx={{ fontWeight: 600, mb: 0.5 }}>
          Version Bêta
        </Typography>
        <Typography variant="body2">
          Cette page est actuellement en version bêta. Certaines fonctionnalités peuvent être en cours de développement.
          N'hésitez pas à nous faire part de vos retours.
        </Typography>
      </Alert>

      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 700 }}>
          Gestion de l'Abonnement
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gérez votre abonnement, consultez vos factures et modifiez votre plan
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Carte principale - Statut de l'abonnement */}
        <Grid item xs={12} md={8}>
          <Card elevation={0} sx={{ border: `1px solid ${alpha(theme.palette.divider, 0.1)}` }}>
            <CardContent sx={{ p: 4 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
                <Box>
                  <Typography variant="h5" gutterBottom sx={{ fontWeight: 600 }}>
                    Statut de l'Abonnement
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 2 }}>
                    <Chip
                      icon={isActive ? <CheckIcon /> : <CancelIcon />}
                      label={isActive ? 'Actif' : 'Inactif'}
                      color={isActive ? 'success' : 'error'}
                      sx={{ fontWeight: 600 }}
                    />
                    <Chip
                      label={getSubscriptionTypeLabel(subscriptionStatus?.subscription_type)}
                      color="primary"
                      variant="outlined"
                    />
                  </Box>
                </Box>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<RefreshIcon />}
                  onClick={handleRefresh}
                  disabled={isRefreshing}
                >
                  Actualiser
                </Button>
              </Box>

              <Divider sx={{ my: 3 }} />

              {/* Informations détaillées */}
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Type d'abonnement
                    </Typography>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      {getSubscriptionTypeLabel(subscriptionStatus?.subscription_type)}
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Prix
                    </Typography>
                    <Typography variant="h6" sx={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: 0.5 }}>
                      <EuroIcon fontSize="small" />
                      {getSubscriptionPrice(subscriptionStatus?.subscription_type)}
                    </Typography>
                  </Box>
                </Grid>
                {periodEnd && (
                  <Grid item xs={12} sm={6}>
                    <Box sx={{ mb: 2 }}>
                      <Typography variant="body2" color="text.secondary" gutterBottom>
                        Prochain renouvellement
                      </Typography>
                      <Typography variant="h6" sx={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <CalendarIcon fontSize="small" />
                        {format(periodEnd, 'dd MMMM yyyy', { locale: fr })}
                      </Typography>
                    </Box>
                  </Grid>
                )}
                {subscriptionStatus?.email && (
                  <Grid item xs={12} sm={6}>
                    <Box sx={{ mb: 2 }}>
                      <Typography variant="body2" color="text.secondary" gutterBottom>
                        Email de facturation
                      </Typography>
                      <Typography variant="body1" sx={{ fontWeight: 500 }}>
                        {subscriptionStatus.email}
                      </Typography>
                    </Box>
                  </Grid>
                )}
              </Grid>

              {!isActive && !subscriptionStatus?.stripe_customer_id && (
                <Alert severity="warning" sx={{ mt: 3 }}>
                  Votre abonnement n'est pas actif. Veuillez souscrire à un abonnement pour accéder à toutes les fonctionnalités.
                </Alert>
              )}

              {/* Bouton pour gérer l'abonnement si l'utilisateur a un customer_id Stripe */}
              {subscriptionStatus?.stripe_customer_id && (
                <Box sx={{ mt: 4 }}>
                  <Button
                    variant="contained"
                    size="large"
                    fullWidth
                    startIcon={<SettingsIcon />}
                    onClick={handleManageSubscription}
                    disabled={isLoadingPortal}
                    sx={{
                      py: 1.5,
                      background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
                      '&:hover': {
                        background: `linear-gradient(135deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.main} 100%)`,
                      },
                    }}
                  >
                    {isLoadingPortal ? 'Chargement...' : 'Gérer mon abonnement'}
                  </Button>
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 2, textAlign: 'center' }}>
                    {isActive 
                      ? 'Accédez au portail client Stripe pour modifier votre plan, consulter vos factures ou annuler votre abonnement'
                      : 'Accédez au portail client Stripe pour consulter vos factures ou réactiver votre abonnement'
                    }
                  </Typography>
                </Box>
              )}

              {/* Bouton pour s'abonner si l'utilisateur n'a pas de customer_id */}
              {!subscriptionStatus?.stripe_customer_id && (
                <Box sx={{ mt: 4 }}>
                  <Alert severity="info" sx={{ mb: 2 }}>
                    Vous n'avez pas encore d'abonnement. Cliquez sur le bouton ci-dessous pour souscrire.
                  </Alert>
                  <Button
                    variant="contained"
                    size="large"
                    fullWidth
                    startIcon={<StarIcon />}
                    onClick={() => window.location.href = '/app/subscription-blocked'}
                    sx={{
                      py: 1.5,
                      background: `linear-gradient(135deg, ${theme.palette.success.main} 0%, ${theme.palette.success.dark} 100%)`,
                      '&:hover': {
                        background: `linear-gradient(135deg, ${theme.palette.success.dark} 0%, ${theme.palette.success.main} 100%)`,
                      },
                    }}
                  >
                    Souscrire à un abonnement
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Carte latérale - Informations */}
        <Grid item xs={12} md={4}>
          <Card elevation={0} sx={{ border: `1px solid ${alpha(theme.palette.divider, 0.1)}` }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom sx={{ fontWeight: 600, mb: 3 }}>
                Informations
              </Typography>
              
              <List>
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <InfoIcon color="primary" />
                  </ListItemIcon>
                  <ListItemText
                    primary="Gestion complète"
                    secondary="Modifiez votre plan, consultez vos factures et gérez votre méthode de paiement"
                  />
                </ListItem>
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <ReceiptIcon color="primary" />
                  </ListItemIcon>
                  <ListItemText
                    primary="Historique des factures"
                    secondary="Accédez à toutes vos factures précédentes"
                  />
                </ListItem>
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <CreditCardIcon color="primary" />
                  </ListItemIcon>
                  <ListItemText
                    primary="Méthode de paiement"
                    secondary="Mettez à jour votre carte bancaire"
                  />
                </ListItem>
              </List>

              <Divider sx={{ my: 3 }} />

              <Box sx={{ p: 2, bgcolor: alpha(theme.palette.info.main, 0.1), borderRadius: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Besoin d'aide ?</strong>
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                  Contactez notre support à{' '}
                  <a href="mailto:contact.ateliergestion@gmail.com" style={{ color: theme.palette.primary.main }}>
                    contact.ateliergestion@gmail.com
                  </a>
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Container>
  );
};

export default Subscription;


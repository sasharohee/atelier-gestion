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
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  LinearProgress,
  Avatar,
  Fade,
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
  Speed as SpeedIcon,
  Shield as ShieldIcon,
  Bolt as BoltIcon,
  SupportAgent as SupportIcon,
  Email as EmailIcon,
  Verified as VerifiedIcon,
  WorkspacePremium as PremiumIcon,
  ArrowForward as ArrowForwardIcon,
} from '@mui/icons-material';
import { useSubscription } from '../../hooks/useSubscription';
import { useAuth } from '../../hooks/useAuth';
import { useUltraFastAccess } from '../../hooks/useUltraFastAccess';
import { supabase } from '../../lib/supabase';
import { useNavigate } from 'react-router-dom';
import { redirectToCheckout, checkPaymentSuccess, checkPaymentCancelled } from '../../services/stripeService';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const Subscription: React.FC = () => {
  const { user } = useAuth();
  const { subscriptionStatus, loading, refreshStatus } = useSubscription();
  const { refreshAccess } = useUltraFastAccess();
  const navigate = useNavigate();
  const theme = useTheme();
  const [isLoadingPortal, setIsLoadingPortal] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isLoadingCheckout, setIsLoadingCheckout] = useState(false);
  const [checkoutPriceId, setCheckoutPriceId] = useState<string | null>(null);
  const [isCheckingAccess, setIsCheckingAccess] = useState(false);
  const [activationMessage, setActivationMessage] = useState<string | null>(null);

  const stripePriceIdMonthly = import.meta.env.VITE_STRIPE_PRICE_ID_MONTHLY;
  const stripePriceIdYearly = import.meta.env.VITE_STRIPE_PRICE_ID_YEARLY;

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

  // Polling post-paiement
  useEffect(() => {
    if (checkPaymentSuccess()) {
      toast.success('Paiement reussi ! Verification de votre abonnement...');
      setIsCheckingAccess(true);
      setActivationMessage('Paiement reussi ! Activation de votre acces en cours...');

      const checkAccessPeriodically = async (attempt: number = 0) => {
        const maxAttempts = 10;
        if (attempt >= maxAttempts) {
          setIsCheckingAccess(false);
          setActivationMessage('Verification terminee. Si votre acces n\'est pas encore active, veuillez rafraichir la page.');
          return;
        }

        await new Promise(resolve => setTimeout(resolve, 2000));
        await refreshAccess();
        await refreshStatus();

        try {
          const { data: { user: currentUser } } = await supabase.auth.getUser();
          if (currentUser) {
            const { data: status } = await supabase
              .from('subscription_status')
              .select('is_active, stripe_current_period_end')
              .eq('user_id', currentUser.id)
              .single();

            if (status?.is_active) {
              let isPeriodValid = true;
              if (status.stripe_current_period_end) {
                const periodEnd = new Date(status.stripe_current_period_end);
                isPeriodValid = periodEnd > new Date();
              }
              if (isPeriodValid) {
                setIsCheckingAccess(false);
                setActivationMessage('Acces active ! Redirection en cours...');
                toast.success('Votre abonnement est maintenant actif !');
                setTimeout(() => { navigate('/app/dashboard'); }, 1500);
                return;
              }
            }
          }
        } catch (error) {
          console.error('Erreur lors de la verification de l\'acces:', error);
        }

        if (attempt < maxAttempts - 1) {
          checkAccessPeriodically(attempt + 1);
        } else {
          setIsCheckingAccess(false);
          setActivationMessage('Verification terminee. Si votre acces n\'est pas encore active, veuillez rafraichir la page.');
        }
      };
      checkAccessPeriodically();
    } else if (checkPaymentCancelled()) {
      toast.error('Paiement annule');
    }
  }, [refreshStatus, refreshAccess, navigate]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refreshAccess();
      await refreshStatus();
      toast.success('Statut mis a jour');
    } catch (error) {
      toast.error('Erreur lors de la mise a jour');
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleManageSubscription = async () => {
    if (!subscriptionStatus?.stripe_customer_id) {
      toast.error('Aucun abonnement Stripe trouve');
      return;
    }
    setIsLoadingPortal(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { toast.error('Vous devez etre connecte'); return; }

      const { data, error } = await supabase.functions.invoke('stripe-portal', {
        body: { returnUrl: `${window.location.origin}/app/subscription` },
        headers: { Authorization: `Bearer ${session.access_token}` },
      });
      if (error) throw error;
      if (data?.url) { window.location.href = data.url; }
      else { throw new Error('URL du portail non disponible'); }
    } catch (error) {
      console.error('Erreur lors de l\'acces au portail:', error);
      toast.error(error instanceof Error ? error.message : 'Erreur lors de l\'acces au portail client');
      setIsLoadingPortal(false);
    }
  };

  const handleCheckout = async (priceId: string) => {
    if (!priceId) { toast.error('Configuration Stripe manquante.'); return; }
    setIsLoadingCheckout(true);
    setCheckoutPriceId(priceId);
    try {
      const successUrl = `${window.location.origin}/app/subscription?checkout=success`;
      const cancelUrl = `${window.location.origin}/app/subscription?checkout=cancelled`;
      await redirectToCheckout(priceId, successUrl, cancelUrl);
    } catch (error) {
      console.error('Erreur checkout:', error);
      toast.error(error instanceof Error ? error.message : 'Erreur lors de la creation de la session de paiement');
      setIsLoadingCheckout(false);
      setCheckoutPriceId(null);
    }
  };

  const getSubscriptionTypeLabel = (type?: string) => {
    switch (type) {
      case 'premium_monthly': return 'Premium Mensuel';
      case 'premium_yearly': return 'Premium Annuel';
      case 'premium': return 'Premium';
      case 'enterprise': return 'Enterprise';
      default: return 'Premium';
    }
  };

  const getSubscriptionPrice = (type?: string) => {
    switch (type) {
      case 'premium_monthly': return '20\u20AC/mois';
      case 'premium_yearly': return '200\u20AC/an';
      default: return '-';
    }
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ py: 6 }}>
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

  const features = [
    { icon: <BoltIcon />, label: 'Tableau de bord complet', color: '#f59e0b' },
    { icon: <ShieldIcon />, label: 'Suivi des reparations', color: '#3b82f6' },
    { icon: <StarIcon />, label: 'Gestion clients & devis', color: '#8b5cf6' },
    { icon: <SupportIcon />, label: 'Support prioritaire', color: '#10b981' },
  ];

  return (
    <Box sx={{ minHeight: '100%', pb: 6 }}>
      <Container maxWidth="lg" sx={{ pt: 4 }}>
        {/* Banniere d'activation post-paiement */}
        {activationMessage && (
          <Fade in>
            <Alert
              severity={activationMessage.includes('Redirection') ? 'success' : 'info'}
              icon={isCheckingAccess ? <CircularProgress size={20} /> : <CheckIcon />}
              sx={{
                mb: 3,
                borderRadius: 3,
                border: '1px solid',
                borderColor: activationMessage.includes('Redirection') ? 'success.light' : 'info.light',
              }}
            >
              <Typography variant="body2" sx={{ fontWeight: 600 }}>
                {activationMessage}
              </Typography>
              {isCheckingAccess && <LinearProgress sx={{ mt: 1, borderRadius: 1 }} />}
            </Alert>
          </Fade>
        )}

        {/* En-tete */}
        <Fade in timeout={600}>
          <Box sx={{ mb: 5 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
              <Avatar
                sx={{
                  width: 48,
                  height: 48,
                  background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                  boxShadow: '0 4px 14px rgba(245, 158, 11, 0.3)',
                }}
              >
                <PremiumIcon sx={{ fontSize: 26 }} />
              </Avatar>
              <Box>
                <Typography variant="h4" component="h1" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
                  Abonnement
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Gerez votre plan et votre facturation
                </Typography>
              </Box>
            </Box>
          </Box>
        </Fade>

        {/* Statut actif - bandeau de confirmation */}
        {isActive && (
          <Fade in timeout={800}>
            <Card
              elevation={0}
              sx={{
                mb: 4,
                borderRadius: 4,
                background: 'linear-gradient(135deg, #059669 0%, #10b981 50%, #34d399 100%)',
                color: 'white',
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              {/* Motif decoratif */}
              <Box sx={{
                position: 'absolute', top: -30, right: -30,
                width: 120, height: 120, borderRadius: '50%',
                background: 'rgba(255,255,255,0.1)',
              }} />
              <Box sx={{
                position: 'absolute', bottom: -20, right: 60,
                width: 80, height: 80, borderRadius: '50%',
                background: 'rgba(255,255,255,0.07)',
              }} />
              <CardContent sx={{ p: 4, position: 'relative', zIndex: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Avatar sx={{ bgcolor: 'rgba(255,255,255,0.2)', width: 52, height: 52 }}>
                      <VerifiedIcon sx={{ fontSize: 28 }} />
                    </Avatar>
                    <Box>
                      <Typography variant="h6" sx={{ fontWeight: 700 }}>
                        Abonnement {getSubscriptionTypeLabel(subscriptionStatus?.subscription_type)}
                      </Typography>
                      <Typography variant="body2" sx={{ opacity: 0.9 }}>
                        {periodEnd
                          ? `Prochain renouvellement le ${format(periodEnd, 'dd MMMM yyyy', { locale: fr })}`
                          : 'Abonnement actif'}
                      </Typography>
                    </Box>
                  </Box>
                  <Box sx={{ display: 'flex', gap: 1.5 }}>
                    <Button
                      variant="contained"
                      size="small"
                      startIcon={<RefreshIcon />}
                      onClick={handleRefresh}
                      disabled={isRefreshing}
                      sx={{
                        bgcolor: 'rgba(255,255,255,0.2)',
                        color: 'white',
                        '&:hover': { bgcolor: 'rgba(255,255,255,0.3)' },
                        textTransform: 'none',
                        fontWeight: 600,
                        borderRadius: 2,
                      }}
                    >
                      {isRefreshing ? 'Actualisation...' : 'Actualiser'}
                    </Button>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Fade>
        )}

        <Grid container spacing={3}>
          {/* Colonne principale */}
          <Grid item xs={12} md={8}>
            {/* Carte de details (abonnement actif) */}
            {isActive && (
              <Fade in timeout={1000}>
                <Card
                  elevation={0}
                  sx={{
                    borderRadius: 4,
                    border: `1px solid ${alpha(theme.palette.divider, 0.08)}`,
                    mb: 3,
                  }}
                >
                  <CardContent sx={{ p: 4 }}>
                    <Typography variant="h6" sx={{ fontWeight: 700, mb: 3 }}>
                      Details de l'abonnement
                    </Typography>

                    <Grid container spacing={3}>
                      {[
                        {
                          icon: <CreditCardIcon sx={{ color: '#f59e0b' }} />,
                          label: 'Plan',
                          value: getSubscriptionTypeLabel(subscriptionStatus?.subscription_type),
                          bg: 'rgba(245, 158, 11, 0.08)',
                        },
                        {
                          icon: <EuroIcon sx={{ color: '#3b82f6' }} />,
                          label: 'Tarif',
                          value: getSubscriptionPrice(subscriptionStatus?.subscription_type),
                          bg: 'rgba(59, 130, 246, 0.08)',
                        },
                        ...(periodEnd ? [{
                          icon: <CalendarIcon sx={{ color: '#8b5cf6' }} />,
                          label: 'Renouvellement',
                          value: format(periodEnd, 'dd MMMM yyyy', { locale: fr }),
                          bg: 'rgba(139, 92, 246, 0.08)',
                        }] : []),
                        ...(subscriptionStatus?.email ? [{
                          icon: <EmailIcon sx={{ color: '#10b981' }} />,
                          label: 'Email',
                          value: subscriptionStatus.email,
                          bg: 'rgba(16, 185, 129, 0.08)',
                        }] : []),
                      ].map((item, index) => (
                        <Grid item xs={12} sm={6} key={index}>
                          <Box
                            sx={{
                              display: 'flex',
                              alignItems: 'center',
                              gap: 2,
                              p: 2.5,
                              borderRadius: 3,
                              bgcolor: item.bg,
                              transition: 'all 0.2s ease',
                            }}
                          >
                            <Avatar sx={{ bgcolor: 'white', width: 42, height: 42, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
                              {item.icon}
                            </Avatar>
                            <Box>
                              <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 500, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                                {item.label}
                              </Typography>
                              <Typography variant="body1" sx={{ fontWeight: 600 }}>
                                {item.value}
                              </Typography>
                            </Box>
                          </Box>
                        </Grid>
                      ))}
                    </Grid>

                    {/* Bouton portail Stripe */}
                    {subscriptionStatus?.stripe_customer_id && (
                      <Box sx={{ mt: 4 }}>
                        <Button
                          variant="contained"
                          size="large"
                          fullWidth
                          endIcon={<ArrowForwardIcon />}
                          onClick={handleManageSubscription}
                          disabled={isLoadingPortal}
                          sx={{
                            py: 1.8,
                            borderRadius: 3,
                            background: 'linear-gradient(135deg, #1f2937 0%, #374151 100%)',
                            fontSize: '0.95rem',
                            fontWeight: 700,
                            textTransform: 'none',
                            boxShadow: '0 4px 14px rgba(31, 41, 55, 0.25)',
                            '&:hover': {
                              background: 'linear-gradient(135deg, #374151 0%, #1f2937 100%)',
                              boxShadow: '0 6px 20px rgba(31, 41, 55, 0.35)',
                              transform: 'translateY(-1px)',
                            },
                            transition: 'all 0.3s ease',
                          }}
                        >
                          {isLoadingPortal ? 'Chargement...' : 'Gerer mon abonnement sur Stripe'}
                        </Button>
                        <Typography variant="caption" color="text.secondary" sx={{ mt: 1.5, display: 'block', textAlign: 'center' }}>
                          Modifier votre plan, consulter vos factures ou mettre a jour votre moyen de paiement
                        </Typography>
                      </Box>
                    )}
                  </CardContent>
                </Card>
              </Fade>
            )}

            {/* Statut inactif - pas de customer_id : afficher les offres */}
            {!isActive && !subscriptionStatus?.stripe_customer_id && (
              <Fade in timeout={800}>
                <Box>
                  {/* Alerte config manquante */}
                  {(!stripePriceIdMonthly || !stripePriceIdYearly) && (
                    <Alert severity="warning" sx={{ mb: 3, borderRadius: 3 }}>
                      <Typography variant="subtitle2" fontWeight="bold" gutterBottom>
                        {!stripePriceIdYearly && stripePriceIdMonthly
                          ? 'Abonnement annuel non configure'
                          : !stripePriceIdMonthly && stripePriceIdYearly
                            ? 'Abonnement mensuel non configure'
                            : 'Liens d\'abonnement non configures'}
                      </Typography>
                      <Typography variant="body2">
                        Ajoutez les variables d'environnement VITE_STRIPE_PRICE_ID_MONTHLY et VITE_STRIPE_PRICE_ID_YEARLY.
                      </Typography>
                    </Alert>
                  )}

                  {/* Header section pricing */}
                  <Box sx={{ textAlign: 'center', mb: 4 }}>
                    <Chip
                      label="Choisissez votre plan"
                      sx={{
                        mb: 2,
                        fontWeight: 600,
                        bgcolor: 'rgba(245, 158, 11, 0.1)',
                        color: '#d97706',
                        border: '1px solid rgba(245, 158, 11, 0.2)',
                      }}
                    />
                    <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
                      Debloquez toutes les fonctionnalites
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1, maxWidth: 480, mx: 'auto' }}>
                      Acces complet a l'atelier de gestion : reparations, clients, devis, facturation et bien plus.
                    </Typography>
                  </Box>

                  <Grid container spacing={3}>
                    {/* Plan Mensuel */}
                    <Grid item xs={12} sm={6}>
                      <Card
                        elevation={0}
                        sx={{
                          borderRadius: 4,
                          border: `2px solid ${alpha(theme.palette.divider, 0.1)}`,
                          height: '100%',
                          display: 'flex',
                          flexDirection: 'column',
                          transition: 'all 0.3s ease',
                          '&:hover': {
                            borderColor: alpha('#3b82f6', 0.3),
                            boxShadow: '0 8px 30px rgba(59, 130, 246, 0.1)',
                            transform: 'translateY(-4px)',
                          },
                        }}
                      >
                        <CardContent sx={{ p: 4, flex: 1, display: 'flex', flexDirection: 'column' }}>
                          <Typography variant="overline" sx={{ fontWeight: 700, color: '#3b82f6', letterSpacing: '0.1em' }}>
                            Mensuel
                          </Typography>
                          <Box sx={{ display: 'flex', alignItems: 'baseline', mt: 1, mb: 3 }}>
                            <Typography variant="h2" component="span" sx={{ fontWeight: 800, letterSpacing: '-0.03em' }}>
                              20
                            </Typography>
                            <Typography variant="h6" component="span" color="text.secondary" sx={{ ml: 0.5, fontWeight: 500 }}>
                              {'\u20AC'}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ ml: 0.5 }}>
                              / mois
                            </Typography>
                          </Box>

                          <Divider sx={{ mb: 3 }} />

                          <List dense sx={{ mb: 3, flex: 1 }}>
                            {features.map((f, i) => (
                              <ListItem key={i} sx={{ px: 0, py: 0.5 }}>
                                <ListItemIcon sx={{ minWidth: 36 }}>
                                  <Avatar sx={{ width: 28, height: 28, bgcolor: alpha(f.color, 0.1) }}>
                                    {React.cloneElement(f.icon, { sx: { fontSize: 16, color: f.color } })}
                                  </Avatar>
                                </ListItemIcon>
                                <ListItemText
                                  primary={f.label}
                                  primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
                                />
                              </ListItem>
                            ))}
                          </List>

                          <Button
                            variant="outlined"
                            size="large"
                            fullWidth
                            onClick={() => handleCheckout(stripePriceIdMonthly || '')}
                            disabled={isLoadingCheckout || !stripePriceIdMonthly}
                            sx={{
                              py: 1.5,
                              borderRadius: 3,
                              borderColor: alpha('#3b82f6', 0.3),
                              color: '#3b82f6',
                              fontWeight: 700,
                              fontSize: '0.95rem',
                              textTransform: 'none',
                              '&:hover': {
                                borderColor: '#3b82f6',
                                bgcolor: alpha('#3b82f6', 0.04),
                                transform: 'translateY(-1px)',
                              },
                              transition: 'all 0.3s ease',
                            }}
                          >
                            {isLoadingCheckout && checkoutPriceId === stripePriceIdMonthly
                              ? 'Redirection...'
                              : 'S\'abonner'}
                          </Button>
                        </CardContent>
                      </Card>
                    </Grid>

                    {/* Plan Annuel - Recommande */}
                    <Grid item xs={12} sm={6}>
                      <Card
                        elevation={0}
                        sx={{
                          borderRadius: 4,
                          border: '2px solid #f59e0b',
                          height: '100%',
                          display: 'flex',
                          flexDirection: 'column',
                          position: 'relative',
                          overflow: 'visible',
                          boxShadow: '0 8px 30px rgba(245, 158, 11, 0.12)',
                          transition: 'all 0.3s ease',
                          '&:hover': {
                            boxShadow: '0 12px 40px rgba(245, 158, 11, 0.2)',
                            transform: 'translateY(-4px)',
                          },
                        }}
                      >
                        {/* Badge flottant */}
                        <Box
                          sx={{
                            position: 'absolute',
                            top: -14,
                            left: '50%',
                            transform: 'translateX(-50%)',
                            background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                            color: 'white',
                            px: 2.5,
                            py: 0.7,
                            borderRadius: 10,
                            fontSize: '0.7rem',
                            fontWeight: 800,
                            letterSpacing: '0.08em',
                            textTransform: 'uppercase',
                            boxShadow: '0 4px 12px rgba(245, 158, 11, 0.35)',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          Recommande - Economie 40{'\u20AC'}
                        </Box>

                        <CardContent sx={{ p: 4, pt: 5, flex: 1, display: 'flex', flexDirection: 'column' }}>
                          <Typography variant="overline" sx={{ fontWeight: 700, color: '#d97706', letterSpacing: '0.1em' }}>
                            Annuel
                          </Typography>
                          <Box sx={{ display: 'flex', alignItems: 'baseline', mt: 1, mb: 1 }}>
                            <Typography variant="h2" component="span" sx={{ fontWeight: 800, letterSpacing: '-0.03em' }}>
                              200
                            </Typography>
                            <Typography variant="h6" component="span" color="text.secondary" sx={{ ml: 0.5, fontWeight: 500 }}>
                              {'\u20AC'}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ ml: 0.5 }}>
                              / an
                            </Typography>
                          </Box>
                          <Typography variant="body2" sx={{ color: '#059669', fontWeight: 600, mb: 3 }}>
                            soit 16,67{'\u20AC'}/mois au lieu de 20{'\u20AC'}
                          </Typography>

                          <Divider sx={{ mb: 3 }} />

                          <List dense sx={{ mb: 3, flex: 1 }}>
                            {features.map((f, i) => (
                              <ListItem key={i} sx={{ px: 0, py: 0.5 }}>
                                <ListItemIcon sx={{ minWidth: 36 }}>
                                  <Avatar sx={{ width: 28, height: 28, bgcolor: alpha(f.color, 0.1) }}>
                                    {React.cloneElement(f.icon, { sx: { fontSize: 16, color: f.color } })}
                                  </Avatar>
                                </ListItemIcon>
                                <ListItemText
                                  primary={f.label}
                                  primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
                                />
                              </ListItem>
                            ))}
                          </List>

                          {!stripePriceIdYearly && (
                            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
                              Variable VITE_STRIPE_PRICE_ID_YEARLY requise.
                            </Typography>
                          )}

                          <Button
                            variant="contained"
                            size="large"
                            fullWidth
                            onClick={() => handleCheckout(stripePriceIdYearly || '')}
                            disabled={isLoadingCheckout || !stripePriceIdYearly}
                            sx={{
                              py: 1.5,
                              borderRadius: 3,
                              background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                              fontWeight: 700,
                              fontSize: '0.95rem',
                              textTransform: 'none',
                              boxShadow: '0 4px 14px rgba(245, 158, 11, 0.35)',
                              '&:hover': {
                                background: 'linear-gradient(135deg, #d97706 0%, #f59e0b 100%)',
                                boxShadow: '0 6px 20px rgba(245, 158, 11, 0.45)',
                                transform: 'translateY(-1px)',
                              },
                              transition: 'all 0.3s ease',
                            }}
                          >
                            {isLoadingCheckout && checkoutPriceId === stripePriceIdYearly
                              ? 'Redirection...'
                              : 'S\'abonner'}
                          </Button>
                        </CardContent>
                      </Card>
                    </Grid>
                  </Grid>
                </Box>
              </Fade>
            )}

            {/* Inactif mais avec customer_id (ex-abonne) */}
            {!isActive && subscriptionStatus?.stripe_customer_id && (
              <Fade in timeout={800}>
                <Card
                  elevation={0}
                  sx={{
                    borderRadius: 4,
                    border: `1px solid ${alpha(theme.palette.error.main, 0.15)}`,
                    bgcolor: alpha(theme.palette.error.main, 0.02),
                  }}
                >
                  <CardContent sx={{ p: 4 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                      <Avatar sx={{ bgcolor: alpha(theme.palette.error.main, 0.1), width: 48, height: 48 }}>
                        <CancelIcon sx={{ color: theme.palette.error.main }} />
                      </Avatar>
                      <Box>
                        <Typography variant="h6" sx={{ fontWeight: 700 }}>
                          Abonnement inactif
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Votre abonnement n'est plus actif. Reactivez-le pour retrouver l'acces complet.
                        </Typography>
                      </Box>
                    </Box>
                    <Button
                      variant="contained"
                      size="large"
                      fullWidth
                      endIcon={<ArrowForwardIcon />}
                      onClick={handleManageSubscription}
                      disabled={isLoadingPortal}
                      sx={{
                        py: 1.8,
                        borderRadius: 3,
                        background: 'linear-gradient(135deg, #1f2937 0%, #374151 100%)',
                        fontSize: '0.95rem',
                        fontWeight: 700,
                        textTransform: 'none',
                        boxShadow: '0 4px 14px rgba(31, 41, 55, 0.25)',
                        '&:hover': {
                          background: 'linear-gradient(135deg, #374151 0%, #1f2937 100%)',
                          transform: 'translateY(-1px)',
                        },
                        transition: 'all 0.3s ease',
                      }}
                    >
                      {isLoadingPortal ? 'Chargement...' : 'Reactiver mon abonnement'}
                    </Button>
                  </CardContent>
                </Card>
              </Fade>
            )}
          </Grid>

          {/* Colonne laterale */}
          <Grid item xs={12} md={4}>
            <Fade in timeout={1200}>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                {/* Carte FAQ / aide */}
                <Card
                  elevation={0}
                  sx={{
                    borderRadius: 4,
                    border: `1px solid ${alpha(theme.palette.divider, 0.08)}`,
                  }}
                >
                  <CardContent sx={{ p: 3 }}>
                    <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 2.5 }}>
                      Questions frequentes
                    </Typography>

                    {[
                      {
                        icon: <CreditCardIcon />,
                        title: 'Paiement securise',
                        desc: 'Vos paiements sont geres par Stripe, leader mondial du paiement en ligne.',
                        color: '#3b82f6',
                      },
                      {
                        icon: <ReceiptIcon />,
                        title: 'Factures disponibles',
                        desc: 'Retrouvez toutes vos factures dans le portail de gestion Stripe.',
                        color: '#8b5cf6',
                      },
                      {
                        icon: <SettingsIcon />,
                        title: 'Annulation flexible',
                        desc: 'Annulez a tout moment, sans engagement ni frais supplementaires.',
                        color: '#10b981',
                      },
                    ].map((item, index) => (
                      <Box
                        key={index}
                        sx={{
                          display: 'flex',
                          gap: 2,
                          mb: index < 2 ? 2.5 : 0,
                          p: 2,
                          borderRadius: 2.5,
                          bgcolor: alpha(item.color, 0.04),
                          transition: 'all 0.2s ease',
                          '&:hover': { bgcolor: alpha(item.color, 0.08) },
                        }}
                      >
                        <Avatar sx={{ width: 36, height: 36, bgcolor: alpha(item.color, 0.1) }}>
                          {React.cloneElement(item.icon, { sx: { fontSize: 18, color: item.color } })}
                        </Avatar>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600, mb: 0.3 }}>
                            {item.title}
                          </Typography>
                          <Typography variant="caption" color="text.secondary" sx={{ lineHeight: 1.4 }}>
                            {item.desc}
                          </Typography>
                        </Box>
                      </Box>
                    ))}
                  </CardContent>
                </Card>

                {/* Carte support */}
                <Card
                  elevation={0}
                  sx={{
                    borderRadius: 4,
                    background: 'linear-gradient(135deg, #1f2937 0%, #374151 100%)',
                    color: 'white',
                    position: 'relative',
                    overflow: 'hidden',
                  }}
                >
                  <Box sx={{
                    position: 'absolute', top: -20, right: -20,
                    width: 80, height: 80, borderRadius: '50%',
                    background: 'rgba(245, 158, 11, 0.15)',
                  }} />
                  <CardContent sx={{ p: 3, position: 'relative', zIndex: 1 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
                      <SupportIcon sx={{ color: '#fbbf24' }} />
                      <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                        Besoin d'aide ?
                      </Typography>
                    </Box>
                    <Typography variant="body2" sx={{ opacity: 0.8, mb: 2.5, lineHeight: 1.6 }}>
                      Notre equipe repond sous 24h pour toute question sur votre abonnement.
                    </Typography>
                    <Button
                      variant="contained"
                      fullWidth
                      startIcon={<EmailIcon />}
                      href="mailto:contact.ateliergestion@gmail.com?subject=Question abonnement"
                      sx={{
                        bgcolor: 'rgba(255,255,255,0.15)',
                        color: 'white',
                        borderRadius: 2.5,
                        textTransform: 'none',
                        fontWeight: 600,
                        '&:hover': { bgcolor: 'rgba(255,255,255,0.25)' },
                      }}
                    >
                      Contacter le support
                    </Button>
                  </CardContent>
                </Card>
              </Box>
            </Fade>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default Subscription;

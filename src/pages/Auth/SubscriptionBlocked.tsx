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
  Paper,
  Avatar,
  LinearProgress,
  Fade,
  Slide,
  useTheme,
  alpha
} from '@mui/material';
import {
  Lock as LockIcon,
  Email as EmailIcon,
  Support as SupportIcon,
  Refresh as RefreshIcon,
  Logout as LogoutIcon,
  CheckCircle as CheckIcon,
  Euro as EuroIcon,
  Security as SecurityIcon,
  Speed as SpeedIcon,
  Star as StarIcon,
  TrendingUp as TrendingUpIcon,
  VerifiedUser as VerifiedUserIcon,
  Schedule as ScheduleIcon,
  Phone as PhoneIcon,
  Business as BusinessIcon,
  Dashboard as DashboardIcon,
  ViewKanban as KanbanIcon,
  CalendarToday as CalendarIcon,
  Inventory as InventoryIcon,
  Build as BuildIcon,
  Memory as MemoryIcon,
  Inventory2 as Inventory2Icon,
  Warning as WarningIcon,
  Receipt as ReceiptIcon,
  People as PeopleIcon,
  PointOfSale as SalesIcon,
  Description as DescriptionIcon,
  LocalShipping as ShippingIcon,
  Assessment as StatisticsIcon,
  Archive as ArchiveIcon,
  Loyalty as LoyaltyIcon,
  AccountBalanceWallet as ExpensesIcon,
  RequestQuote as RequestQuoteIcon,
  AdminPanelSettings as AdminIcon,
  DeviceHub as DeviceHubIcon,
  Settings as SettingsIcon
} from '@mui/icons-material';
import { useAuth } from '../../hooks/useAuth';
import { useSubscription } from '../../hooks/useSubscription';
import { supabase } from '../../lib/supabase';
import { useNavigate } from 'react-router-dom';

const SubscriptionBlocked: React.FC = () => {
  const { user } = useAuth();
  const { subscriptionStatus, refreshStatus, loading } = useSubscription();
  const navigate = useNavigate();
  const theme = useTheme(); // Déplacer useTheme() avant tous les returns conditionnels
  const [isRefreshing, setIsRefreshing] = React.useState(false);
  const [refreshMessage, setRefreshMessage] = React.useState<string | null>(null);


  const handleRefresh = async () => {
    setIsRefreshing(true);
    setRefreshMessage('Vérification en cours...');
    
    try {
      await refreshStatus();
      setRefreshMessage('Statut vérifié ! Rechargement de la page...');
      
      // Recharger la page après un court délai
      setTimeout(() => {
        window.location.reload();
      }, 1500);
    } catch (error) {
      setRefreshMessage('Erreur lors de la vérification du statut');
      setTimeout(() => {
        setIsRefreshing(false);
        setRefreshMessage(null);
      }, 2000);
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/auth');
  };

  const handleContactSupport = () => {
    window.open('mailto:contact.ateliergestion@gmail.com?subject=Activation de mon abonnement', '_blank');
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
        background: `linear-gradient(135deg, ${alpha(theme.palette.primary.main, 0.1)} 0%, ${alpha(theme.palette.secondary.main, 0.1)} 100%)`,
        position: 'relative',
        overflow: 'hidden'
      }}
    >
      {/* Background Pattern */}
      <Box
        sx={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: `radial-gradient(circle at 25% 25%, ${alpha(theme.palette.primary.main, 0.1)} 0%, transparent 50%),
                           radial-gradient(circle at 75% 75%, ${alpha(theme.palette.secondary.main, 0.1)} 0%, transparent 50%)`,
          zIndex: 0
        }}
      />
      
      <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 1, py: 6 }}>
        <Fade in timeout={800}>
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 6
            }}
          >
            {/* En-tête moderne */}
            <Slide direction="down" in timeout={1000}>
              <Box
                sx={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: 4,
                  textAlign: 'center'
                }}
              >
                {/* Icône animée */}
                <Box
                  sx={{
                    position: 'relative',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}
                >
                  <Box
                    sx={{
                      width: 120,
                      height: 120,
                      borderRadius: '50%',
                      background: `linear-gradient(135deg, ${theme.palette.error.main} 0%, ${theme.palette.error.dark} 100%)`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      boxShadow: `0 20px 40px ${alpha(theme.palette.error.main, 0.3)}`,
                      animation: 'pulse 2s infinite',
                      '@keyframes pulse': {
                        '0%': {
                          transform: 'scale(1)',
                          boxShadow: `0 20px 40px ${alpha(theme.palette.error.main, 0.3)}`
                        },
                        '50%': {
                          transform: 'scale(1.05)',
                          boxShadow: `0 25px 50px ${alpha(theme.palette.error.main, 0.4)}`
                        },
                        '100%': {
                          transform: 'scale(1)',
                          boxShadow: `0 20px 40px ${alpha(theme.palette.error.main, 0.3)}`
                        }
                      }
                    }}
                  >
                    <LockIcon sx={{ fontSize: 50, color: 'white' }} />
                  </Box>
                  
                  {/* Cercle décoratif */}
                  <Box
                    sx={{
                      position: 'absolute',
                      top: -10,
                      right: -10,
                      width: 30,
                      height: 30,
                      borderRadius: '50%',
                      backgroundColor: theme.palette.warning.main,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      animation: 'rotate 3s linear infinite',
                      '@keyframes rotate': {
                        '0%': { transform: 'rotate(0deg)' },
                        '100%': { transform: 'rotate(360deg)' }
                      }
                    }}
                  >
                    <SecurityIcon sx={{ fontSize: 16, color: 'white' }} />
                  </Box>
                </Box>

                {/* Titre et sous-titre */}
                <Box>
                  <Typography 
                    variant="h2" 
                    component="h1" 
                    sx={{
                      fontWeight: 800,
                      background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                      backgroundClip: 'text',
                      WebkitBackgroundClip: 'text',
                      WebkitTextFillColor: 'transparent',
                      mb: 2
                    }}
                  >
                    Accès Verrouillé
                  </Typography>
                  <Typography 
                    variant="h5" 
                    color="text.secondary"
                    sx={{ fontWeight: 400, maxWidth: 600 }}
                  >
                    Votre compte nécessite une activation par un administrateur
                  </Typography>
                </Box>
              </Box>
            </Slide>

            {/* Contenu principal */}
            <Grid container spacing={4} justifyContent="center">
              {/* Carte principale - Informations utilisateur */}
              <Grid item xs={12} md={6}>
                <Slide direction="right" in timeout={1200}>
                  <Card 
                    elevation={0}
                    sx={{
                      background: `linear-gradient(135deg, ${alpha(theme.palette.background.paper, 0.9)} 0%, ${alpha(theme.palette.background.paper, 0.7)} 100%)`,
                      backdropFilter: 'blur(20px)',
                      border: `1px solid ${alpha(theme.palette.primary.main, 0.1)}`,
                      borderRadius: 4,
                      overflow: 'hidden',
                      position: 'relative'
                    }}
                  >
                    {/* Header de la carte */}
                    <Box
                      sx={{
                        background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                        p: 3,
                        color: 'white'
                      }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Avatar
                          sx={{
                            width: 50,
                            height: 50,
                            background: alpha('#fff', 0.2),
                            border: `2px solid ${alpha('#fff', 0.3)}`
                          }}
                        >
                          <VerifiedUserIcon />
                        </Avatar>
                        <Box>
                          <Typography variant="h6" fontWeight="bold">
                            Statut du Compte
                          </Typography>
                          <Typography variant="body2" sx={{ opacity: 0.9 }}>
                            Activation requise
                          </Typography>
                        </Box>
                      </Box>
                    </Box>

                    <CardContent sx={{ p: 4 }}>
                      {/* Informations utilisateur */}
                      {subscriptionStatus && (
                        <Box
                          sx={{
                            p: 3,
                            borderRadius: 2,
                            background: alpha(theme.palette.info.main, 0.1),
                            border: `1px solid ${alpha(theme.palette.info.main, 0.2)}`,
                            mb: 4
                          }}
                        >
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                            <Avatar
                              sx={{
                                width: 40,
                                height: 40,
                                background: theme.palette.info.main
                              }}
                            >
                              {subscriptionStatus.first_name?.[0]}{subscriptionStatus.last_name?.[0]}
                            </Avatar>
                            <Box>
                              <Typography variant="h6" fontWeight="bold">
                                {subscriptionStatus.first_name} {subscriptionStatus.last_name}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                {subscriptionStatus.email}
                              </Typography>
                            </Box>
                          </Box>
                          
                          <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                            <Chip
                              icon={<ScheduleIcon />}
                              label="En attente d'activation"
                              color="warning"
                              size="small"
                            />
                            <Chip
                              icon={<BusinessIcon />}
                              label="Abonnement Free"
                              color="default"
                              size="small"
                            />
                          </Box>
                        </Box>
                      )}

                      {/* Message de rafraîchissement */}
                      {refreshMessage && (
                        <Fade in>
                          <Alert 
                            severity={
                              refreshMessage.includes('Rechargement') ? 'info' : 
                              refreshMessage.includes('succès') ? 'success' : 'error'
                            } 
                            sx={{ mb: 3 }}
                            icon={
                              refreshMessage.includes('Rechargement') ? <RefreshIcon /> :
                              refreshMessage.includes('succès') ? <CheckIcon /> : <LockIcon />
                            }
                          >
                            {refreshMessage}
                          </Alert>
                        </Fade>
                      )}

                      {/* Instructions modernes */}
                      <Box sx={{ mb: 4 }}>
                        <Typography variant="h6" gutterBottom fontWeight="bold" color="primary.main">
                          Procédure d'Activation
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                          Suivez ces étapes pour activer votre compte
                        </Typography>
                        
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                          {[
                            { icon: <ScheduleIcon />, text: "Activation sous 24h par un administrateur", color: theme.palette.success.main },
                            { icon: <CheckIcon />, text: "Confirmation par email", color: theme.palette.info.main }
                          ].map((step, index) => (
                            <Box
                              key={index}
                              sx={{
                                display: 'flex',
                                alignItems: 'center',
                                p: 2,
                                borderRadius: 2,
                                background: alpha(step.color, 0.1),
                                border: `1px solid ${alpha(step.color, 0.2)}`,
                                transition: 'all 0.3s ease',
                                '&:hover': {
                                  background: alpha(step.color, 0.15),
                                  transform: 'translateX(5px)'
                                }
                              }}
                            >
                              <Box
                                sx={{
                                  width: 40,
                                  height: 40,
                                  borderRadius: '50%',
                                  background: step.color,
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  mr: 2,
                                  color: 'white'
                                }}
                              >
                                {step.icon}
                              </Box>
                              <Typography variant="body1" fontWeight="medium">
                                {step.text}
                              </Typography>
                            </Box>
                          ))}
                        </Box>
                      </Box>

                      {/* Actions modernes */}
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <Button
                          variant="contained"
                          size="large"
                          startIcon={<EmailIcon />}
                          onClick={handleContactSupport}
                          sx={{
                            py: 1.5,
                            background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                            '&:hover': {
                              background: `linear-gradient(135deg, ${theme.palette.primary.dark} 0%, ${theme.palette.secondary.dark} 100%)`,
                              transform: 'translateY(-2px)',
                              boxShadow: `0 10px 20px ${alpha(theme.palette.primary.main, 0.3)}`
                            },
                            transition: 'all 0.3s ease'
                          }}
                        >
                          Contacter le Support
                        </Button>

                        <Button
                          variant="outlined"
                          size="large"
                          startIcon={<RefreshIcon />}
                          onClick={handleRefresh}
                          disabled={isRefreshing}
                          sx={{
                            py: 1.5,
                            borderColor: theme.palette.primary.main,
                            color: theme.palette.primary.main,
                            '&:hover': {
                              background: alpha(theme.palette.primary.main, 0.1),
                              transform: 'translateY(-2px)'
                            },
                            transition: 'all 0.3s ease'
                          }}
                        >
                          {isRefreshing ? (
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <LinearProgress sx={{ width: 20, height: 2 }} />
                              Vérification...
                            </Box>
                          ) : (
                            'Vérifier le Statut'
                          )}
                        </Button>

                        <Button
                          variant="text"
                          size="large"
                          startIcon={<LogoutIcon />}
                          onClick={handleLogout}
                          sx={{
                            color: 'text.secondary',
                            '&:hover': {
                              background: alpha(theme.palette.error.main, 0.1),
                              color: theme.palette.error.main
                            },
                            transition: 'all 0.3s ease'
                          }}
                        >
                          Se Déconnecter
                        </Button>
                      </Box>
                    </CardContent>
                  </Card>
                </Slide>
              </Grid>

              {/* Carte des tarifs moderne */}
              <Grid item xs={12} md={6}>
                <Slide direction="left" in timeout={1400}>
                  <Card 
                    elevation={0}
                    sx={{
                      background: `linear-gradient(135deg, ${alpha(theme.palette.background.paper, 0.9)} 0%, ${alpha(theme.palette.background.paper, 0.7)} 100%)`,
                      backdropFilter: 'blur(20px)',
                      border: `1px solid ${alpha(theme.palette.secondary.main, 0.1)}`,
                      borderRadius: 4,
                      overflow: 'hidden',
                      position: 'relative'
                    }}
                  >
                    {/* Header Premium */}
                    <Box
                      sx={{
                        background: `linear-gradient(135deg, ${theme.palette.secondary.main} 0%, ${theme.palette.primary.main} 100%)`,
                        p: 3,
                        color: 'white',
                        position: 'relative',
                        overflow: 'hidden'
                      }}
                    >
                      {/* Effet de brillance */}
                      <Box
                        sx={{
                          position: 'absolute',
                          top: -50,
                          right: -50,
                          width: 100,
                          height: 100,
                          borderRadius: '50%',
                          background: alpha('#fff', 0.1),
                          animation: 'float 6s ease-in-out infinite',
                          '@keyframes float': {
                            '0%, 100%': { transform: 'translateY(0px)' },
                            '50%': { transform: 'translateY(-20px)' }
                          }
                        }}
                      />
                      
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, position: 'relative', zIndex: 1 }}>
                        <Avatar
                          sx={{
                            width: 50,
                            height: 50,
                            background: alpha('#fff', 0.2),
                            border: `2px solid ${alpha('#fff', 0.3)}`
                          }}
                        >
                          <StarIcon />
                        </Avatar>
                        <Box>
                          <Typography variant="h6" fontWeight="bold">
                            Abonnement Premium
                          </Typography>
                          <Typography variant="body2" sx={{ opacity: 0.9 }}>
                            Accès complet à l'atelier
                          </Typography>
                        </Box>
                      </Box>
                    </Box>

                    <CardContent sx={{ p: 4 }}>
                      {/* Prix principal */}
                      <Box sx={{ textAlign: 'center', mb: 4 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 2 }}>
                          <Typography 
                            variant="h1" 
                            component="span" 
                            sx={{
                              fontWeight: 800,
                              background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                              backgroundClip: 'text',
                              WebkitBackgroundClip: 'text',
                              WebkitTextFillColor: 'transparent'
                            }}
                          >
                            20
                          </Typography>
                          <EuroIcon sx={{ fontSize: 40, ml: 1, color: theme.palette.primary.main }} />
                        </Box>
                        <Typography variant="h6" color="text.secondary" gutterBottom>
                          par mois
                        </Typography>
                        <Chip 
                          icon={<TrendingUpIcon />}
                          label="Prix réduit" 
                          color="success"
                          sx={{ fontWeight: 'bold', mb: 3 }} 
                        />
                        
                        {/* Bouton paiement mensuel */}
                        <Button
                          variant="contained"
                          size="large"
                          fullWidth
                          startIcon={<EuroIcon />}
                          onClick={() => window.open('https://buy.stripe.com/7sYcN43Vw4cna0S3ii7g400', '_blank')}
                          sx={{
                            py: 2,
                            background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
                            '&:hover': {
                              background: `linear-gradient(135deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.main} 100%)`,
                              transform: 'translateY(-3px)',
                              boxShadow: `0 15px 30px ${alpha(theme.palette.primary.main, 0.4)}`
                            },
                            transition: 'all 0.3s ease',
                            fontSize: '1.1rem',
                            fontWeight: 'bold'
                          }}
                        >
                          S'abonner - 20€/mois
                        </Button>
                      </Box>

                      {/* Option Annuelle avec design amélioré */}
                      <Box 
                        sx={{ 
                          textAlign: 'center', 
                          mb: 4, 
                          p: 3, 
                          background: `linear-gradient(135deg, ${alpha(theme.palette.success.main, 0.1)} 0%, ${alpha(theme.palette.success.main, 0.05)} 100%)`,
                          border: `2px solid ${alpha(theme.palette.success.main, 0.2)}`,
                          borderRadius: 3,
                          position: 'relative',
                          overflow: 'hidden'
                        }}
                      >
                        {/* Badge "Recommandé" */}
                        <Box
                          sx={{
                            position: 'absolute',
                            top: -1,
                            right: 20,
                            background: theme.palette.success.main,
                            color: 'white',
                            px: 2,
                            py: 0.5,
                            borderRadius: '0 0 8px 8px',
                            fontSize: '0.75rem',
                            fontWeight: 'bold'
                          }}
                        >
                          RECOMMANDÉ
                        </Box>
                        
                        <Typography variant="h6" color="text.secondary" gutterBottom sx={{ mt: 1 }}>
                          Abonnement annuel
                        </Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 1 }}>
                          <Typography 
                            variant="h2" 
                            component="span" 
                            sx={{
                              fontWeight: 800,
                              color: theme.palette.success.main
                            }}
                          >
                            200
                          </Typography>
                          <EuroIcon sx={{ fontSize: 32, ml: 1, color: theme.palette.success.main }} />
                        </Box>
                        <Typography variant="body1" color="text.secondary" gutterBottom>
                          par an
                        </Typography>
                        <Chip 
                          icon={<SpeedIcon />}
                          label="Économie 40€" 
                          color="success"
                          sx={{ fontWeight: 'bold', mb: 3 }} 
                        />
                        
                        {/* Bouton paiement annuel */}
                        <Button
                          variant="contained"
                          size="large"
                          fullWidth
                          startIcon={<StarIcon />}
                          onClick={() => window.open('https://buy.stripe.com/7sYaEWeAabEPgpgbOO7g403', '_blank')}
                          sx={{
                            py: 2,
                            background: `linear-gradient(135deg, ${theme.palette.success.main} 0%, ${theme.palette.success.dark} 100%)`,
                            '&:hover': {
                              background: `linear-gradient(135deg, ${theme.palette.success.dark} 0%, ${theme.palette.success.main} 100%)`,
                              transform: 'translateY(-3px)',
                              boxShadow: `0 15px 30px ${alpha(theme.palette.success.main, 0.4)}`
                            },
                            transition: 'all 0.3s ease',
                            fontSize: '1.1rem',
                            fontWeight: 'bold'
                          }}
                        >
                          S'abonner - 200€/an (Économie 40€)
                        </Button>
                      </Box>

                      {/* Fonctionnalités complètes avec design moderne */}
                      <Box sx={{ mb: 4 }}>
                        <Typography variant="h6" gutterBottom fontWeight="bold" color="primary.main">
                          Fonctionnalités Incluses
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                          Découvrez toutes les fonctionnalités disponibles dans votre atelier de gestion
                        </Typography>
                        
                        {/* Fonctionnalités principales */}
                        <Box sx={{ mb: 3 }}>
                          <Typography variant="subtitle1" fontWeight="bold" color="primary.main" sx={{ mb: 2 }}>
                            🎯 Fonctionnalités Principales
                          </Typography>
                          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 2 }}>
                            {[
                              { icon: <DashboardIcon />, text: "Tableau de bord", color: '#6366f1' },
                              { icon: <KanbanIcon />, text: "Suivi des réparations", color: '#06b6d4' },
                              { icon: <CalendarIcon />, text: "Calendrier & Rendez-vous", color: '#10b981' },
                              { icon: <PeopleIcon />, text: "Gestion des clients", color: '#f59e0b' }
                            ].map((feature, index) => (
                              <Box
                                key={index}
                                sx={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  p: 2,
                                  borderRadius: 2,
                                  background: alpha(feature.color, 0.1),
                                  border: `1px solid ${alpha(feature.color, 0.2)}`,
                                  transition: 'all 0.3s ease',
                                  '&:hover': {
                                    background: alpha(feature.color, 0.15),
                                    transform: 'scale(1.02)'
                                  }
                                }}
                              >
                                <Box
                                  sx={{
                                    width: 36,
                                    height: 36,
                                    borderRadius: '50%',
                                    background: feature.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    mr: 2,
                                    color: 'white'
                                  }}
                                >
                                  {feature.icon}
                                </Box>
                                <Typography variant="body2" fontWeight="medium">
                                  {feature.text}
                                </Typography>
                              </Box>
                            ))}
                          </Box>
                        </Box>

                        {/* Catalogue et inventaire */}
                        <Box sx={{ mb: 3 }}>
                          <Typography variant="subtitle1" fontWeight="bold" color="primary.main" sx={{ mb: 2 }}>
                            📦 Catalogue & Inventaire
                          </Typography>
                          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2 }}>
                            {[
                              { icon: <DeviceHubIcon />, text: "Gestion des appareils", color: '#8b5cf6' },
                              { icon: <BuildIcon />, text: "Services de réparation", color: '#ef4444' },
                              { icon: <MemoryIcon />, text: "Pièces détachées", color: '#06b6d4' },
                              { icon: <Inventory2Icon />, text: "Produits en vente", color: '#10b981' },
                              { icon: <WarningIcon />, text: "Gestion des ruptures", color: '#f59e0b' }
                            ].map((feature, index) => (
                              <Box
                                key={index}
                                sx={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  p: 2,
                                  borderRadius: 2,
                                  background: alpha(feature.color, 0.1),
                                  border: `1px solid ${alpha(feature.color, 0.2)}`,
                                  transition: 'all 0.3s ease',
                                  '&:hover': {
                                    background: alpha(feature.color, 0.15),
                                    transform: 'scale(1.02)'
                                  }
                                }}
                              >
                                <Box
                                  sx={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: '50%',
                                    background: feature.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    mr: 2,
                                    color: 'white'
                                  }}
                                >
                                  {feature.icon}
                                </Box>
                                <Typography variant="body2" fontWeight="medium">
                                  {feature.text}
                                </Typography>
                              </Box>
                            ))}
                          </Box>
                        </Box>

                        {/* Transactions et ventes */}
                        <Box sx={{ mb: 3 }}>
                          <Typography variant="subtitle1" fontWeight="bold" color="primary.main" sx={{ mb: 2 }}>
                            💰 Transactions & Ventes
                          </Typography>
                          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2 }}>
                            {[
                              { icon: <ReceiptIcon />, text: "Gestion des transactions", color: '#f59e0b' },
                              { icon: <SalesIcon />, text: "Suivi des ventes", color: '#10b981' },
                              { icon: <DescriptionIcon />, text: "Création de devis", color: '#3b82f6' },
                              { icon: <ShippingIcon />, text: "Suivi des commandes", color: '#8b5cf6' }
                            ].map((feature, index) => (
                              <Box
                                key={index}
                                sx={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  p: 2,
                                  borderRadius: 2,
                                  background: alpha(feature.color, 0.1),
                                  border: `1px solid ${alpha(feature.color, 0.2)}`,
                                  transition: 'all 0.3s ease',
                                  '&:hover': {
                                    background: alpha(feature.color, 0.15),
                                    transform: 'scale(1.02)'
                                  }
                                }}
                              >
                                <Box
                                  sx={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: '50%',
                                    background: feature.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    mr: 2,
                                    color: 'white'
                                  }}
                                >
                                  {feature.icon}
                                </Box>
                                <Typography variant="body2" fontWeight="medium">
                                  {feature.text}
                                </Typography>
                              </Box>
                            ))}
                          </Box>
                        </Box>

                        {/* Fonctionnalités avancées */}
                        <Box sx={{ mb: 3 }}>
                          <Typography variant="subtitle1" fontWeight="bold" color="primary.main" sx={{ mb: 2 }}>
                            ⚡ Fonctionnalités Avancées
                          </Typography>
                          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2 }}>
                            {[
                              { icon: <StatisticsIcon />, text: "Statistiques & rapports", color: '#ef4444' },
                              { icon: <ArchiveIcon />, text: "Archives & historique", color: '#3b82f6' },
                              { icon: <LoyaltyIcon />, text: "Points de fidélité", color: '#f59e0b' },
                              { icon: <ExpensesIcon />, text: "Gestion des dépenses", color: '#dc2626' },
                              { icon: <RequestQuoteIcon />, text: "Demandes de devis", color: '#7c3aed' },
                              { icon: <AdminIcon />, text: "Administration", color: '#6b7280' }
                            ].map((feature, index) => (
                              <Box
                                key={index}
                                sx={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  p: 2,
                                  borderRadius: 2,
                                  background: alpha(feature.color, 0.1),
                                  border: `1px solid ${alpha(feature.color, 0.2)}`,
                                  transition: 'all 0.3s ease',
                                  '&:hover': {
                                    background: alpha(feature.color, 0.15),
                                    transform: 'scale(1.02)'
                                  }
                                }}
                              >
                                <Box
                                  sx={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: '50%',
                                    background: feature.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    mr: 2,
                                    color: 'white'
                                  }}
                                >
                                  {feature.icon}
                                </Box>
                                <Typography variant="body2" fontWeight="medium">
                                  {feature.text}
                                </Typography>
                              </Box>
                            ))}
                          </Box>
                        </Box>

                        {/* Support et assistance */}
                        <Box>
                          <Typography variant="subtitle1" fontWeight="bold" color="primary.main" sx={{ mb: 2 }}>
                            🛠️ Support & Assistance
                          </Typography>
                          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2 }}>
                            {[
                              { icon: <SupportIcon />, text: "Support prioritaire", color: '#10b981' },
                              { icon: <SettingsIcon />, text: "Configuration avancée", color: '#6b7280' },
                              { icon: <SecurityIcon />, text: "Sécurité des données", color: '#ef4444' },
                              { icon: <SpeedIcon />, text: "Performance optimisée", color: '#06b6d4' }
                            ].map((feature, index) => (
                              <Box
                                key={index}
                                sx={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  p: 2,
                                  borderRadius: 2,
                                  background: alpha(feature.color, 0.1),
                                  border: `1px solid ${alpha(feature.color, 0.2)}`,
                                  transition: 'all 0.3s ease',
                                  '&:hover': {
                                    background: alpha(feature.color, 0.15),
                                    transform: 'scale(1.02)'
                                  }
                                }}
                              >
                                <Box
                                  sx={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: '50%',
                                    background: feature.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    mr: 2,
                                    color: 'white'
                                  }}
                                >
                                  {feature.icon}
                                </Box>
                                <Typography variant="body2" fontWeight="medium">
                                  {feature.text}
                                </Typography>
                              </Box>
                            ))}
                          </Box>
                        </Box>
                      </Box>

                      {/* Bouton contact support */}
                      <Button
                        variant="outlined"
                        size="medium"
                        fullWidth
                        startIcon={<EmailIcon />}
                        onClick={handleContactSupport}
                        sx={{
                          py: 1.5,
                          borderColor: theme.palette.secondary.main,
                          color: theme.palette.secondary.main,
                          '&:hover': {
                            background: alpha(theme.palette.secondary.main, 0.1),
                            borderColor: theme.palette.secondary.dark,
                            color: theme.palette.secondary.dark
                          },
                          transition: 'all 0.3s ease'
                        }}
                      >
                        Contacter le support
                      </Button>
                    </CardContent>
                  </Card>
                </Slide>
              </Grid>
          </Grid>

            {/* Footer moderne */}
            <Fade in timeout={1600}>
              <Box 
                sx={{ 
                  textAlign: 'center', 
                  mt: 6,
                  p: 4,
                  borderRadius: 3,
                  background: `linear-gradient(135deg, ${alpha(theme.palette.background.paper, 0.8)} 0%, ${alpha(theme.palette.background.paper, 0.6)} 100%)`,
                  backdropFilter: 'blur(10px)',
                  border: `1px solid ${alpha(theme.palette.divider, 0.1)}`
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 2, mb: 2 }}>
                  <Avatar
                    sx={{
                      width: 40,
                      height: 40,
                      background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`
                    }}
                  >
                    <SupportIcon />
                  </Avatar>
                  <Typography variant="h6" fontWeight="bold" color="primary.main">
                    Support Client
                  </Typography>
                </Box>
                
                <Box sx={{ display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, gap: 3, justifyContent: 'center', alignItems: 'center' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <EmailIcon color="primary" />
                    <Typography variant="body1" fontWeight="medium">
                      contact.ateliergestion@gmail.com
                    </Typography>
                  </Box>
                  
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <ScheduleIcon color="success" />
                    <Typography variant="body1" fontWeight="medium" color="success.main">
                      Délai : 24h maximum
                    </Typography>
                  </Box>
                </Box>
                
                <Typography variant="body2" color="text.secondary" sx={{ mt: 2, opacity: 0.8 }}>
                  Notre équipe est disponible pour vous accompagner dans l'activation de votre compte
                </Typography>
              </Box>
            </Fade>
          </Box>
        </Fade>
      </Container>
    </Box>
  );
};

export default SubscriptionBlocked;

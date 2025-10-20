import React from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  CardMedia,
  Stack,
  Chip,
  useTheme,
  useMediaQuery,
  Fade,
  Slide,
  Link
} from '@mui/material';
import {
  Build as BuildIcon,
  Schedule as ScheduleIcon,
  People as PeopleIcon,
  Assessment as AssessmentIcon,
  Inventory as InventoryIcon,
  Message as MessageIcon,
  ArrowForward as ArrowForwardIcon,
  CheckCircle as CheckCircleIcon,
  PlayArrow as PlayArrowIcon,
  Star as StarIcon,
  TrendingUp as TrendingUpIcon,
  Handyman as HandymanIcon,
  Archive as ArchiveIcon,
  Loyalty as LoyaltyIcon,
  Receipt as ReceiptIcon,
  Description as DescriptionIcon,
  LocalShipping as ShippingIcon,
  Warning as WarningIcon,
  DeviceHub as DeviceHubIcon,
  AccountBalance as AccountBalanceIcon,
  AdminPanelSettings as AdminIcon,
  ShoppingCart as ShoppingCartIcon,
  Memory as MemoryIcon,
  Inventory2 as Inventory2Icon
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import LandingNavbar from '../../components/LandingNavbar';

const Landing: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isSmallMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const navigate = useNavigate();

  // CSS Keyframes for animations
  React.useEffect(() => {
    const style = document.createElement('style');
    style.textContent = `
      @keyframes float1 {
        0%, 100% { transform: translateY(0px) rotate(0deg); }
        50% { transform: translateY(-20px) rotate(180deg); }
      }
      @keyframes float2 {
        0%, 100% { transform: translateY(0px) rotate(0deg); }
        50% { transform: translateY(-20px) rotate(180deg); }
      }
      @keyframes pulse {
        0%, 100% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.05); opacity: 0.8; }
      }
      @keyframes orbit0 {
        0% { transform: translate(-50%, -50%) rotate(0deg) translateY(-120px) rotate(0deg); }
        100% { transform: translate(-50%, -50%) rotate(0deg) translateY(-120px) rotate(360deg); }
      }
      @keyframes orbit1 {
        0% { transform: translate(-50%, -50%) rotate(60deg) translateY(-120px) rotate(0deg); }
        100% { transform: translate(-50%, -50%) rotate(60deg) translateY(-120px) rotate(360deg); }
      }
      @keyframes orbit2 {
        0% { transform: translate(-50%, -50%) rotate(120deg) translateY(-120px) rotate(0deg); }
        100% { transform: translate(-50%, -50%) rotate(120deg) translateY(-120px) rotate(360deg); }
      }
      @keyframes orbit3 {
        0% { transform: translate(-50%, -50%) rotate(180deg) translateY(-120px) rotate(0deg); }
        100% { transform: translate(-50%, -50%) rotate(180deg) translateY(-120px) rotate(360deg); }
      }
      @keyframes orbit4 {
        0% { transform: translate(-50%, -50%) rotate(240deg) translateY(-120px) rotate(0deg); }
        100% { transform: translate(-50%, -50%) rotate(240deg) translateY(-120px) rotate(360deg); }
      }
      @keyframes orbit5 {
        0% { transform: translate(-50%, -50%) rotate(300deg) translateY(-120px) rotate(0deg); }
        100% { transform: translate(-50%, -50%) rotate(300deg) translateY(-120px) rotate(360deg); }
      }
    `;
    document.head.appendChild(style);
    return () => {
      if (document.head.contains(style)) {
        document.head.removeChild(style);
      }
    };
  }, []);

  const features = [
    {
      icon: <BuildIcon sx={{ fontSize: 40, color: '#FF6B6B' }} />,
      title: 'Suivi des Réparations',
      description: 'Gérez vos réparations avec le système Kanban intuitif et suivez l\'état en temps réel',
      bgColor: '#FFF5F5',
      borderColor: '#FF6B6B'
    },
    {
      icon: <HandymanIcon sx={{ fontSize: 40, color: '#16a34a' }} />,
      title: 'SAV (Service Après-Vente)',
      description: 'Gérez les retours et les garanties avec un système SAV complet et organisé',
      bgColor: '#F0FFF4',
      borderColor: '#16a34a'
    },
    {
      icon: <ScheduleIcon sx={{ fontSize: 40, color: '#4ECDC4' }} />,
      title: 'Calendrier & Rendez-vous',
      description: 'Planifiez et gérez vos rendez-vous clients avec un calendrier intégré',
      bgColor: '#F0FFFD',
      borderColor: '#4ECDC4'
    },
    {
      icon: <PeopleIcon sx={{ fontSize: 40, color: '#45B7D1' }} />,
      title: 'Gestion Clients',
      description: 'Centralisez les informations de vos clients et leur historique de réparations',
      bgColor: '#F0F8FF',
      borderColor: '#45B7D1'
    },
    {
      icon: <DeviceHubIcon sx={{ fontSize: 40, color: '#2196f3' }} />,
      title: 'Gestion des Appareils',
      description: 'Catalogue complet des modèles d\'appareils avec gestion centralisée',
      bgColor: '#F0F8FF',
      borderColor: '#2196f3'
    },
    {
      icon: <BuildIcon sx={{ fontSize: 40, color: '#ff9800' }} />,
      title: 'Services de Réparation',
      description: 'Catalogue des services proposés avec tarification et durée estimée',
      bgColor: '#FFF8E1',
      borderColor: '#ff9800'
    },
    {
      icon: <MemoryIcon sx={{ fontSize: 40, color: '#4caf50' }} />,
      title: 'Pièces Détachées',
      description: 'Gestion complète du stock de pièces détachées avec alertes de rupture',
      bgColor: '#F0FFF4',
      borderColor: '#4caf50'
    },
    {
      icon: <Inventory2Icon sx={{ fontSize: 40, color: '#9c27b0' }} />,
      title: 'Produits & Accessoires',
      description: 'Gestion des produits et accessoires en vente avec suivi des stocks',
      bgColor: '#F3E5F5',
      borderColor: '#9c27b0'
    },
    {
      icon: <WarningIcon sx={{ fontSize: 40, color: '#f44336' }} />,
      title: 'Alertes de Rupture',
      description: 'Surveillance automatique des ruptures de stock avec notifications',
      bgColor: '#FFEBEE',
      borderColor: '#f44336'
    },
    {
      icon: <ReceiptIcon sx={{ fontSize: 40, color: '#4caf50' }} />,
      title: 'Ventes & Facturation',
      description: 'Gestion complète des ventes, factures et encaissements',
      bgColor: '#F0FFF4',
      borderColor: '#4caf50'
    },
    {
      icon: <DescriptionIcon sx={{ fontSize: 40, color: '#ff9800' }} />,
      title: 'Devis & Estimations',
      description: 'Création et gestion des devis avec suivi des conversions',
      bgColor: '#FFF8E1',
      borderColor: '#ff9800'
    },
    {
      icon: <ShippingIcon sx={{ fontSize: 40, color: '#607d8b' }} />,
      title: 'Suivi des Commandes',
      description: 'Gestion des commandes fournisseurs avec suivi des livraisons',
      bgColor: '#F5F5F5',
      borderColor: '#607d8b'
    },
    {
      icon: <AssessmentIcon sx={{ fontSize: 40, color: '#FFEAA7' }} />,
      title: 'Statistiques & Rapports',
      description: 'Tableaux de bord détaillés et analyses de performance',
      bgColor: '#FFFBEB',
      borderColor: '#FFEAA7'
    },
    {
      icon: <ArchiveIcon sx={{ fontSize: 40, color: '#3b82f6' }} />,
      title: 'Archives',
      description: 'Conservation et consultation des données historiques',
      bgColor: '#EFF6FF',
      borderColor: '#3b82f6'
    },
    {
      icon: <LoyaltyIcon sx={{ fontSize: 40, color: '#f59e0b' }} />,
      title: 'Points de Fidélité',
      description: 'Programme de fidélité pour récompenser vos clients réguliers',
      bgColor: '#FFFBEB',
      borderColor: '#f59e0b'
    },
    {
      icon: <AccountBalanceIcon sx={{ fontSize: 40, color: '#8b5cf6' }} />,
      title: 'Gestion des Dépenses',
      description: 'Suivi des dépenses et coûts de l\'atelier pour un meilleur contrôle',
      bgColor: '#F3E8FF',
      borderColor: '#8b5cf6'
    },
    {
      icon: <DescriptionIcon sx={{ fontSize: 40, color: '#06b6d4' }} />,
      title: 'Demandes de Devis',
      description: 'Gestion des demandes de devis clients avec suivi personnalisé',
      bgColor: '#ECFEFF',
      borderColor: '#06b6d4'
    },
    {
      icon: <AdminIcon sx={{ fontSize: 40, color: '#6366f1' }} />,
      title: 'Administration',
      description: 'Outils d\'administration complets pour gérer votre atelier',
      bgColor: '#EEF2FF',
      borderColor: '#6366f1'
    }
  ];

  const benefits = [
    'Interface moderne et intuitive',
    'Synchronisation en temps réel',
    'Gestion complète de l\'atelier',
    'Système Kanban pour le suivi des réparations',
    'SAV et gestion des garanties',
    'Calendrier intégré pour les rendez-vous',
    'Base de données clients centralisée',
    'Gestion complète des stocks',
    'Alertes de rupture automatiques',
    'Facturation et devis intégrés',
    'Programme de fidélité clients',
    'Archives et historique complet',
    'Statistiques et rapports détaillés',
    'Support multi-appareils',
    'Sécurisé et fiable'
  ];

  const handleAccessApp = () => {
    navigate('/auth');
  };

  const handleRepairTracking = () => {
    navigate('/repair-tracking');
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* Navbar */}
      <LandingNavbar />
      
      {/* Hero Section */}
      <Box
        id="home"
        sx={{
          background: 'linear-gradient(135deg, #6b7280 0%, #4b5563 50%, #374151 100%)',
          color: 'white',
          minHeight: { xs: '100vh', md: '100vh' },
          pt: { xs: 8, md: 0 },
          pb: { xs: 4, md: 0 },
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: `
              radial-gradient(circle at 20% 80%, rgba(99, 102, 241, 0.15) 0%, transparent 50%),
              radial-gradient(circle at 80% 20%, rgba(16, 185, 129, 0.15) 0%, transparent 50%),
              radial-gradient(circle at 40% 40%, rgba(245, 158, 11, 0.1) 0%, transparent 50%)
            `,
            zIndex: 1
          }
        }}
      >
        {/* Animated background elements */}
        <Box
          sx={{
            position: 'absolute',
            top: { xs: '5%', md: '10%' },
            left: { xs: '2%', md: '5%' },
            width: { xs: 120, md: 250 },
            height: { xs: 120, md: 250 },
            borderRadius: '50%',
            background: 'rgba(255, 255, 255, 0.05)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            backdropFilter: 'blur(10px)',
            animation: 'float1 8s ease-in-out infinite',
            zIndex: 2
          }}
        />
        <Box
          sx={{
            position: 'absolute',
            bottom: { xs: '10%', md: '20%' },
            right: { xs: '5%', md: '10%' },
            width: { xs: 100, md: 180 },
            height: { xs: 100, md: 180 },
            borderRadius: '50%',
            background: 'rgba(255, 255, 255, 0.03)',
            border: '1px solid rgba(255, 255, 255, 0.08)',
            backdropFilter: 'blur(15px)',
            animation: 'float2 10s ease-in-out infinite reverse',
            zIndex: 2
          }}
        />
        <Box
          sx={{
            position: 'absolute',
            top: { xs: '60%', md: '50%' },
            left: { xs: '80%', md: '75%' },
            width: { xs: 60, md: 120 },
            height: { xs: 60, md: 120 },
            borderRadius: '50%',
            background: 'rgba(99, 102, 241, 0.1)',
            border: '1px solid rgba(99, 102, 241, 0.2)',
            backdropFilter: 'blur(8px)',
            animation: 'pulse 4s ease-in-out infinite',
            zIndex: 2
          }}
        />
        
        {/* Grid pattern overlay */}
        <Box
          sx={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: `
              url("data:image/svg+xml,%3Csvg width='40' height='40' viewBox='0 0 40 40' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.05'%3E%3Ccircle cx='20' cy='20' r='1'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E"),
              linear-gradient(45deg, transparent 25%, rgba(255,255,255,0.02) 25%, rgba(255,255,255,0.02) 50%, transparent 50%, transparent 75%, rgba(255,255,255,0.02) 75%)
            `,
            backgroundSize: '40px 40px, 20px 20px',
            opacity: 0.8,
            zIndex: 1
          }}
        />

        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 2, px: { xs: 2, md: 3 } }}>
          <Grid container spacing={{ xs: 3, md: 4 }} alignItems="center">
            {/* Left side - Content */}
            <Grid item xs={12} md={7}>
              <Fade in timeout={1000}>
                <Box>
                  {/* Badge */}
                  <Box sx={{ mb: { xs: 2, md: 3 } }}>
                    <Chip
                      icon={<StarIcon />}
                      label="Solution Professionnelle"
                      sx={{
                        background: 'linear-gradient(135deg, rgba(255, 255, 255, 0.15) 0%, rgba(255, 255, 255, 0.05) 100%)',
                        color: 'white',
                        fontSize: { xs: '0.8rem', md: '0.9rem' },
                        fontWeight: 600,
                        backdropFilter: 'blur(20px)',
                        border: '1px solid rgba(255, 255, 255, 0.2)',
                        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
                        '&:hover': {
                          background: 'linear-gradient(135deg, rgba(255, 255, 255, 0.2) 0%, rgba(255, 255, 255, 0.1) 100%)'
                        }
                      }}
                    />
                  </Box>

                  {/* Main title */}
                  <Typography
                    variant="h1"
                    component="h1"
                    sx={{
                      fontWeight: 900,
                      mb: { xs: 2, md: 3 },
                      fontSize: { xs: '2.5rem', sm: '3rem', md: '4rem', lg: '4.5rem' },
                      lineHeight: { xs: 1.1, md: 1.05 },
                      background: 'linear-gradient(135deg, #ffffff 0%, #f7fafc 30%, #e2e8f0 70%, #cbd5e0 100%)',
                      backgroundClip: 'text',
                      WebkitBackgroundClip: 'text',
                      WebkitTextFillColor: 'transparent',
                      textShadow: '0 4px 8px rgba(0,0,0,0.2)',
                      textAlign: { xs: 'center', md: 'left' },
                      filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.3))'
                    }}
                  >
                    Atelier Gestion
                  </Typography>

                  {/* Subtitle */}
                  <Typography
                    variant="h4"
                    sx={{
                      mb: { xs: 3, md: 4 },
                      opacity: 0.95,
                      fontWeight: 400,
                      fontSize: { xs: '1rem', sm: '1.1rem', md: '1.3rem', lg: '1.5rem' },
                      lineHeight: 1.4,
                      maxWidth: { xs: '100%', md: 500 },
                      textAlign: { xs: 'center', md: 'left' }
                    }}
                  >
                    La solution complète pour gérer votre atelier de réparation d'appareils électroniques
                  </Typography>

                  {/* Features highlights */}
                  <Box sx={{ mb: { xs: 3, md: 4 } }}>
                    <Stack 
                      direction={{ xs: 'column', sm: 'row' }} 
                      spacing={{ xs: 1, sm: 3 }} 
                      flexWrap="wrap" 
                      useFlexGap
                      alignItems={{ xs: 'center', sm: 'flex-start' }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: { xs: 0.5, sm: 1 } }}>
                        <CheckCircleIcon sx={{ mr: 1, fontSize: { xs: 18, md: 20 }, color: '#4CAF50' }} />
                        <Typography variant="body1" sx={{ fontWeight: 500, fontSize: { xs: '0.9rem', md: '1rem' } }}>
                          Gestion complète
                        </Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: { xs: 0.5, sm: 1 } }}>
                        <CheckCircleIcon sx={{ mr: 1, fontSize: { xs: 18, md: 20 }, color: '#4CAF50' }} />
                        <Typography variant="body1" sx={{ fontWeight: 500, fontSize: { xs: '0.9rem', md: '1rem' } }}>
                          Interface intuitive
                        </Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: { xs: 0.5, sm: 1 } }}>
                        <CheckCircleIcon sx={{ mr: 1, fontSize: { xs: 18, md: 20 }, color: '#4CAF50' }} />
                        <Typography variant="body1" sx={{ fontWeight: 500, fontSize: { xs: '0.9rem', md: '1rem' } }}>
                          Temps réel
                        </Typography>
                      </Box>
                    </Stack>
                  </Box>

                  {/* CTA Button */}
                  <Box sx={{ mb: { xs: 3, md: 4 }, textAlign: { xs: 'center', md: 'left' } }}>
                    <Button
                      variant="contained"
                      size="large"
                      onClick={handleAccessApp}
                      sx={{
                        bgcolor: 'white',
                        color: theme.palette.primary.main,
                        px: { xs: 3, md: 4 },
                        py: { xs: 1.5, md: 2 },
                        fontSize: { xs: '1rem', md: '1.1rem' },
                        fontWeight: 700,
                        borderRadius: 3,
                        boxShadow: '0 8px 32px rgba(0,0,0,0.2)',
                        transition: 'all 0.3s ease',
                        width: { xs: '100%', sm: 'auto' },
                        '&:hover': {
                          bgcolor: 'grey.100',
                          transform: 'translateY(-2px)',
                          boxShadow: '0 12px 40px rgba(0,0,0,0.3)'
                        }
                      }}
                      endIcon={<ArrowForwardIcon />}
                    >
                      Accéder à l'Atelier
                    </Button>
                  </Box>

                  {/* Stats */}
                  <Box sx={{ 
                    display: 'flex', 
                    gap: { xs: 2, md: 4 }, 
                    flexWrap: 'wrap',
                    justifyContent: { xs: 'center', md: 'flex-start' }
                  }}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" sx={{ 
                        fontWeight: 700, 
                        color: '#4CAF50',
                        fontSize: { xs: '1.5rem', md: '2.125rem' }
                      }}>
                        100%
                      </Typography>
                      <Typography variant="body2" sx={{ 
                        opacity: 0.8,
                        fontSize: { xs: '0.75rem', md: '0.875rem' }
                      }}>
                        Satisfaction
                      </Typography>
                    </Box>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" sx={{ 
                        fontWeight: 700, 
                        color: '#4CAF50',
                        fontSize: { xs: '1.5rem', md: '2.125rem' }
                      }}>
                        <TrendingUpIcon sx={{ 
                          fontSize: { xs: 24, md: 32 }, 
                          verticalAlign: 'middle', 
                          mr: 0.5 
                        }} />
                        50%
                      </Typography>
                      <Typography variant="body2" sx={{ 
                        opacity: 0.8,
                        fontSize: { xs: '0.75rem', md: '0.875rem' }
                      }}>
                        Gain de temps
                      </Typography>
                    </Box>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" sx={{ 
                        fontWeight: 700, 
                        color: '#4CAF50',
                        fontSize: { xs: '1.5rem', md: '2.125rem' }
                      }}>
                        24/7
                      </Typography>
                      <Typography variant="body2" sx={{ 
                        opacity: 0.8,
                        fontSize: { xs: '0.75rem', md: '0.875rem' }
                      }}>
                        Disponible
                      </Typography>
                    </Box>
                  </Box>
                </Box>
              </Fade>
            </Grid>

            {/* Right side - Visual elements */}
            <Grid item xs={12} md={5}>
              <Fade in timeout={1500}>
                <Box sx={{ textAlign: 'center', position: 'relative', mt: { xs: 4, md: 0 } }}>
                  {/* Main visual element */}
                  <Box
                    sx={{
                      width: { xs: 200, sm: 250, md: 350 },
                      height: { xs: 200, sm: 250, md: 350 },
                      mx: 'auto',
                      position: 'relative',
                      animation: 'pulse 2s ease-in-out infinite'
                    }}
                  >
                    {/* Central icon */}
                    <Box
                      sx={{
                        position: 'absolute',
                        top: '50%',
                        left: '50%',
                        transform: 'translate(-50%, -50%)',
                        width: { xs: 80, sm: 100, md: 120 },
                        height: { xs: 80, sm: 100, md: 120 },
                        borderRadius: '50%',
                        bgcolor: 'rgba(255, 255, 255, 0.15)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        backdropFilter: 'blur(10px)',
                        border: '2px solid rgba(255, 255, 255, 0.3)'
                      }}
                    >
                      <BuildIcon sx={{ fontSize: { xs: 40, sm: 50, md: 60 }, color: 'white' }} />
                    </Box>

                    {/* Orbiting elements */}
                    {[0, 1, 2, 3, 4, 5].map((index) => (
                      <Box
                        key={index}
                        sx={{
                          position: 'absolute',
                          top: '50%',
                          left: '50%',
                          width: { xs: 40, sm: 50, md: 60 },
                          height: { xs: 40, sm: 50, md: 60 },
                          borderRadius: '50%',
                          bgcolor: 'rgba(255, 255, 255, 0.1)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          transform: `translate(-50%, -50%) rotate(${index * 60}deg) translateY(${isMobile ? '-80px' : '-120px'})`,
                          animation: `orbit${index} ${8 + index}s linear infinite`
                        }}
                      >
                        <Box
                          sx={{
                            width: { xs: 15, sm: 18, md: 20 },
                            height: { xs: 15, sm: 18, md: 20 },
                            borderRadius: '50%',
                            bgcolor: 'rgba(255, 255, 255, 0.8)',
                            animation: `pulse ${2 + index * 0.5}s ease-in-out infinite`
                          }}
                        />
                      </Box>
                    ))}
                  </Box>

                  {/* Floating cards */}
                  <Box
                    sx={{
                      position: 'absolute',
                      top: { xs: '10%', md: '20%' },
                      right: { xs: '5%', md: '10%' },
                      bgcolor: 'rgba(255, 255, 255, 0.1)',
                      borderRadius: 2,
                      p: { xs: 1, md: 2 },
                      backdropFilter: 'blur(10px)',
                      border: '1px solid rgba(255, 255, 255, 0.2)',
                      animation: 'float1 4s ease-in-out infinite',
                      display: { xs: 'none', sm: 'block' }
                    }}
                  >
                    <Typography variant="body2" sx={{ 
                      fontWeight: 600,
                      fontSize: { xs: '0.75rem', md: '0.875rem' }
                    }}>
                      📊 +25% efficacité
                    </Typography>
                  </Box>

                  <Box
                    sx={{
                      position: 'absolute',
                      bottom: { xs: '20%', md: '30%' },
                      left: { xs: '2%', md: '5%' },
                      bgcolor: 'rgba(255, 255, 255, 0.1)',
                      borderRadius: 2,
                      p: { xs: 1, md: 2 },
                      backdropFilter: 'blur(10px)',
                      border: '1px solid rgba(255, 255, 255, 0.2)',
                      animation: 'float2 6s ease-in-out infinite reverse',
                      display: { xs: 'none', sm: 'block' }
                    }}
                  >
                    <Typography variant="body2" sx={{ 
                      fontWeight: 600,
                      fontSize: { xs: '0.75rem', md: '0.875rem' }
                    }}>
                      ⚡ Temps réel
                    </Typography>
                  </Box>
                </Box>
              </Fade>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Features Section */}
      <Container maxWidth="lg" sx={{ py: { xs: 6, md: 8 }, px: { xs: 2, md: 3 } }} id="features">
        <Slide direction="up" in timeout={800}>
          <Box>
            <Typography
              variant="h3"
              component="h2"
              sx={{
                textAlign: 'center',
                mb: { xs: 4, md: 6 },
                fontWeight: 600,
                color: theme.palette.text.primary,
                fontSize: { xs: '2rem', md: '3rem' }
              }}
            >
              Fonctionnalités Principales
            </Typography>
            
            <Grid container spacing={{ xs: 3, md: 4 }}>
              {features.map((feature, index) => (
                <Grid item xs={12} sm={6} md={4} key={index}>
                  <Fade in timeout={800 + index * 200}>
                    <Card
                      sx={{
                        height: '100%',
                        transition: 'transform 0.3s ease-in-out, box-shadow 0.3s ease-in-out',
                        backgroundColor: feature.bgColor,
                        border: `2px solid ${feature.borderColor}`,
                        '&:hover': {
                          transform: 'translateY(-8px)',
                          boxShadow: `0 8px 25px ${feature.borderColor}40`,
                          borderColor: feature.borderColor
                        }
                      }}
                    >
                      <CardContent sx={{ textAlign: 'center', p: { xs: 2, md: 3 } }}>
                        <Box 
                          sx={{ 
                            mb: { xs: 1.5, md: 2 },
                            display: 'inline-flex',
                            p: { xs: 1.5, md: 2 },
                            borderRadius: '50%',
                            backgroundColor: `${feature.borderColor}20`,
                            border: `2px solid ${feature.borderColor}40`
                          }}
                        >
                          {React.cloneElement(feature.icon, { 
                            sx: { 
                              fontSize: { xs: 30, md: 40 }, 
                              color: feature.icon.props.sx.color 
                            } 
                          })}
                        </Box>
                        <Typography
                          variant="h6"
                          component="h3"
                          sx={{ 
                            mb: { xs: 1.5, md: 2 }, 
                            fontWeight: 600,
                            fontSize: { xs: '1.1rem', md: '1.25rem' }
                          }}
                        >
                          {feature.title}
                        </Typography>
                        <Typography
                          variant="body2"
                          color="text.secondary"
                          sx={{ 
                            lineHeight: 1.6,
                            fontSize: { xs: '0.875rem', md: '0.875rem' }
                          }}
                        >
                          {feature.description}
                        </Typography>
                      </CardContent>
                    </Card>
                  </Fade>
                </Grid>
              ))}
            </Grid>
          </Box>
        </Slide>
      </Container>

      {/* Benefits Section */}
      <Box sx={{ bgcolor: 'grey.50', py: { xs: 6, md: 8 } }} id="benefits">
        <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 } }}>
          <Slide direction="up" in timeout={1000}>
            <Box>
              <Typography
                variant="h3"
                component="h2"
                sx={{
                  textAlign: 'center',
                  mb: { xs: 4, md: 6 },
                  fontWeight: 600,
                  fontSize: { xs: '2rem', md: '3rem' }
                }}
              >
                Pourquoi Choisir Atelier Gestion ?
              </Typography>
              
              <Grid container spacing={{ xs: 2, md: 3 }} justifyContent="center">
                {benefits.map((benefit, index) => (
                  <Grid item xs={12} sm={6} md={4} key={index}>
                    <Fade in timeout={1000 + index * 150}>
                      <Box
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          p: { xs: 1.5, md: 2 },
                          bgcolor: 'white',
                          borderRadius: 2,
                          boxShadow: theme.shadows[1],
                          transition: 'box-shadow 0.3s ease-in-out',
                          '&:hover': {
                            boxShadow: theme.shadows[3]
                          }
                        }}
                      >
                        <CheckCircleIcon
                          sx={{
                            color: theme.palette.success.main,
                            mr: { xs: 1.5, md: 2 },
                            fontSize: { xs: 20, md: 24 }
                          }}
                        />
                        <Typography variant="body1" sx={{ 
                          fontWeight: 500,
                          fontSize: { xs: '0.9rem', md: '1rem' }
                        }}>
                          {benefit}
                        </Typography>
                      </Box>
                    </Fade>
                  </Grid>
                ))}
              </Grid>
            </Box>
          </Slide>
        </Container>
      </Box>

      {/* Pricing Section */}
      <Box sx={{ bgcolor: 'grey.50', py: { xs: 6, md: 8 } }} id="pricing">
        <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 } }}>
          <Slide direction="up" in timeout={1200}>
            <Box>
              <Typography
                variant="h3"
                component="h2"
                sx={{
                  textAlign: 'center',
                  mb: { xs: 1.5, md: 2 },
                  fontWeight: 600,
                  fontSize: { xs: '2rem', md: '3rem' }
                }}
              >
                Tarifs Simples et Transparents
              </Typography>
              <Typography
                variant="h6"
                color="text.secondary"
                sx={{
                  textAlign: 'center',
                  mb: { xs: 4, md: 6 },
                  maxWidth: 600,
                  mx: 'auto',
                  fontSize: { xs: '1rem', md: '1.25rem' }
                }}
              >
                Un seul plan, toutes les fonctionnalités incluses. Pas de surprise, pas de frais cachés.
              </Typography>
              
              <Box sx={{ display: 'flex', justifyContent: 'center' }}>
                <Card
                  sx={{
                    maxWidth: { xs: '100%', md: 450 },
                    width: '100%',
                    textAlign: 'center',
                    position: 'relative',
                    overflow: 'visible',
                    transition: 'all 0.4s ease',
                    background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)',
                    color: '#495057',
                    borderRadius: { xs: '16px', md: '24px' },
                    border: '2px solid #dee2e6',
                    '&:hover': {
                      transform: { xs: 'none', md: 'translateY(-12px) scale(1.02)' },
                      boxShadow: { xs: theme.shadows[2], md: '0 20px 40px rgba(0, 0, 0, 0.15)' },
                      borderColor: '#adb5bd'
                    }
                  }}
                >
                  {/* Popular Badge */}
                  <Box
                    sx={{
                      position: 'absolute',
                      top: { xs: -15, md: -20 },
                      left: '50%',
                      transform: 'translateX(-50%)',
                      background: 'linear-gradient(45deg, #6c757d, #495057)',
                      color: 'white',
                      px: { xs: 3, md: 4 },
                      py: { xs: 1, md: 1.5 },
                      borderRadius: '25px',
                      fontSize: { xs: '0.875rem', md: '1rem' },
                      fontWeight: 700,
                      boxShadow: '0 8px 20px rgba(108, 117, 125, 0.3)',
                      border: '2px solid rgba(255, 255, 255, 0.2)',
                      backdropFilter: 'blur(10px)'
                    }}
                  >
                    ⭐ Plan Recommandé
                  </Box>
                  
                                     {/* Decorative elements */}
                   <Box
                     sx={{
                       position: 'absolute',
                       top: 20,
                       right: 20,
                       width: 60,
                       height: 60,
                       borderRadius: '50%',
                       background: 'rgba(108, 117, 125, 0.1)',
                       animation: 'pulse 2s ease-in-out infinite'
                     }}
                   />
                   <Box
                     sx={{
                       position: 'absolute',
                       bottom: 40,
                       left: 20,
                       width: 40,
                       height: 40,
                       borderRadius: '50%',
                       background: 'rgba(108, 117, 125, 0.08)',
                       animation: 'pulse 3s ease-in-out infinite'
                     }}
                   />
                  
                  <CardContent sx={{ p: { xs: 3, md: 5 }, position: 'relative', zIndex: 2 }}>
                    <Typography 
                      variant="h4" 
                      component="h3" 
                      sx={{ 
                        mb: { xs: 2, md: 3 }, 
                        fontWeight: 800,
                        color: '#495057',
                        fontSize: { xs: '1.5rem', md: '2.125rem' }
                      }}
                    >
                      Atelier Pro
                    </Typography>
                    
                    <Box sx={{ mb: { xs: 3, md: 4 }, position: 'relative' }}>
                      <Typography 
                        variant="h1" 
                        component="span" 
                        sx={{ 
                          fontWeight: 900, 
                          color: '#495057',
                          fontSize: { xs: '2.5rem', sm: '3rem', md: '4rem' }
                        }}
                      >
                        19,99€
                      </Typography>
                      <Typography 
                        variant="h5" 
                        component="span" 
                        sx={{ 
                          color: '#6c757d',
                          fontWeight: 600,
                          ml: 1,
                          fontSize: { xs: '1.25rem', md: '1.5rem' }
                        }}
                      >
                        /mois
                      </Typography>
                       <Box
                         sx={{
                           position: 'absolute',
                           top: '50%',
                           right: -20,
                           transform: 'translateY(-50%)',
                           width: 4,
                           height: 60,
                           background: 'linear-gradient(180deg, #6c757d, transparent)',
                           borderRadius: '2px'
                         }}
                       />
                    </Box>

                    {/* Option Annuelle */}
                    <Box sx={{ 
                      mb: 4, 
                      p: 2, 
                      backgroundColor: 'rgba(255, 255, 255, 0.8)', 
                      borderRadius: '16px',
                      border: '2px solid #28a745',
                      position: 'relative'
                    }}>
                      <Chip 
                        label="Économie 40€" 
                        color="success"
                        size="small"
                        sx={{ 
                          position: 'absolute',
                          top: -10,
                          right: 10,
                          fontWeight: 'bold',
                          fontSize: '0.75rem'
                        }} 
                      />
                      <Box sx={{ textAlign: 'center' }}>
                        <Typography variant="h6" color="text.secondary" gutterBottom>
                          Ou abonnement annuel
                        </Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 1 }}>
                          <Typography 
                            variant="h2" 
                            component="span" 
                            sx={{ 
                              fontWeight: 900, 
                              color: '#28a745',
                              fontSize: { xs: '2.5rem', md: '3rem' }
                            }}
                          >
                            200€
                          </Typography>
                          <Typography 
                            variant="h6" 
                            component="span" 
                            sx={{ 
                              color: '#28a745',
                              fontWeight: 600,
                              ml: 1
                            }}
                          >
                            /an
                          </Typography>
                        </Box>
                        <Typography variant="body1" color="success.main" fontWeight="bold">
                          Soit 16,67€/mois
                        </Typography>
                      </Box>
                    </Box>
                    
                                         <Typography 
                       variant="h6" 
                       sx={{ 
                         mb: 4,
                         color: '#6c757d',
                         fontWeight: 500,
                         lineHeight: 1.4
                       }}
                     >
                       Accès complet à toutes les fonctionnalités pour votre atelier
                     </Typography>
                    
                    <Box sx={{ mb: 5 }}>
                      <Stack spacing={2.5}>
                        {[
                          'Suivi des réparations avec système Kanban',
                          'SAV et gestion des garanties',
                          'Calendrier et rendez-vous illimités',
                          'Base de données clients illimitée',
                          'Gestion complète des appareils',
                          'Catalogue des services de réparation',
                          'Inventaire et gestion des pièces détachées',
                          'Produits et accessoires en vente',
                          'Alertes de rupture automatiques',
                          'Ventes et facturation intégrées',
                          'Devis et estimations personnalisées',
                          'Suivi des commandes fournisseurs',
                          'Statistiques et rapports détaillés',
                          'Archives et historique complet',
                          'Programme de fidélité clients',
                          'Gestion des dépenses atelier',
                          'Demandes de devis clients',
                          'Outils d\'administration complets',
                          'Support technique prioritaire',
                          'Sauvegarde automatique des données',
                          'Mises à jour gratuites',
                          'Accès multi-appareils'
                        ].map((feature, index) => (
                          <Box 
                            key={index} 
                                                         sx={{ 
                               display: 'flex', 
                               alignItems: 'center', 
                               textAlign: 'left',
                               p: 1.5,
                               borderRadius: '12px',
                               background: 'rgba(255, 255, 255, 0.7)',
                               border: '1px solid #dee2e6',
                               transition: 'all 0.3s ease',
                               '&:hover': {
                                 background: 'rgba(255, 255, 255, 0.9)',
                                 transform: 'translateX(5px)',
                                 borderColor: '#adb5bd'
                               }
                             }}
                          >
                                                         <Box
                               sx={{
                                 width: 24,
                                 height: 24,
                                 borderRadius: '50%',
                                 background: 'linear-gradient(45deg, #6c757d, #495057)',
                                 display: 'flex',
                                 alignItems: 'center',
                                 justifyContent: 'center',
                                 mr: 2,
                                 flexShrink: 0
                               }}
                             >
                               <Typography variant="body2" sx={{ color: 'white', fontWeight: 700, fontSize: '0.8rem' }}>
                                 ✓
                               </Typography>
                             </Box>
                                                         <Typography 
                               variant="body1" 
                               sx={{ 
                                 fontWeight: 500,
                                 color: '#495057'
                               }}
                             >
                               {feature}
                             </Typography>
                          </Box>
                        ))}
                      </Stack>
                    </Box>
                    
                    <Button
                      variant="contained"
                      size="large"
                      onClick={handleAccessApp}
                      sx={{
                        width: '100%',
                        py: { xs: 2, md: 3 },
                        fontSize: { xs: '1rem', md: '1.2rem' },
                        fontWeight: 700,
                        borderRadius: '50px',
                        background: 'linear-gradient(45deg, #6c757d, #495057)',
                        color: 'white',
                        boxShadow: '0 8px 25px rgba(108, 117, 125, 0.4)',
                        border: '2px solid rgba(255, 255, 255, 0.3)',
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          background: 'linear-gradient(45deg, #495057, #343a40)',
                          boxShadow: '0 12px 35px rgba(108, 117, 125, 0.6)',
                          transform: { xs: 'none', md: 'translateY(-3px) scale(1.02)' }
                        }
                      }}
                      endIcon={<ArrowForwardIcon />}
                    >
                      Commencer
                    </Button>
                    
                    
                  </CardContent>
                </Card>
              </Box>
              
              {/* Additional Info */}
              <Box sx={{ mt: 6, textAlign: 'center' }}>
                <Typography variant="h6" sx={{ mb: 3, fontWeight: 600 }}>
                  Pourquoi choisir Atelier Pro ?
                </Typography>
                <Grid container spacing={3} justifyContent="center">
                  {[
                    {
                      icon: '💳',
                      title: 'Paiement Sécurisé',
                      description: 'Paiement sécurisé par Stripe, vos données sont protégées'
                    },
                    {
                      icon: '🔄',
                      title: 'Annulation Simple',
                      description: 'Annulez à tout moment, sans frais ni engagement'
                    },
                    {
                      icon: '📞',
                      title: 'Support 24/7',
                      description: 'Notre équipe est là pour vous aider à tout moment'
                    }
                  ].map((item, index) => (
                    <Grid item xs={12} sm={4} key={index}>
                      <Box sx={{ textAlign: 'center', p: 2 }}>
                        <Typography variant="h4" sx={{ mb: 1 }}>
                          {item.icon}
                        </Typography>
                        <Typography variant="h6" sx={{ mb: 1, fontWeight: 600 }}>
                          {item.title}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {item.description}
                        </Typography>
                      </Box>
                    </Grid>
                  ))}
                </Grid>
              </Box>
            </Box>
          </Slide>
        </Container>
      </Box>

      {/* About Section */}
      <Box sx={{ 
        bgcolor: 'grey.50', 
        py: { xs: 8, md: 12 }, 
        position: 'relative',
        overflow: 'hidden'
      }} id="about">
        {/* Background decorative elements */}
        <Box
          sx={{
            position: 'absolute',
            top: '10%',
            left: '5%',
            width: { xs: 100, md: 200 },
            height: { xs: 100, md: 200 },
            borderRadius: '50%',
            background: 'linear-gradient(45deg, rgba(99, 102, 241, 0.1), rgba(16, 185, 129, 0.1))',
            animation: 'float1 8s ease-in-out infinite'
          }}
        />
        <Box
          sx={{
            position: 'absolute',
            bottom: '15%',
            right: '8%',
            width: { xs: 80, md: 150 },
            height: { xs: 80, md: 150 },
            borderRadius: '50%',
            background: 'linear-gradient(45deg, rgba(245, 158, 11, 0.1), rgba(239, 68, 68, 0.1))',
            animation: 'float2 10s ease-in-out infinite reverse'
          }}
        />
        
        <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 }, position: 'relative', zIndex: 2 }}>
          <Slide direction="up" in timeout={1200}>
            <Box>
              {/* Header Section */}
              <Box sx={{ textAlign: 'center', mb: { xs: 6, md: 8 } }}>
                <Chip
                  label="À Propos"
                  sx={{
                    bgcolor: 'primary.main',
                    color: 'white',
                    px: 3,
                    py: 1,
                    fontSize: '0.9rem',
                    fontWeight: 600,
                    mb: 3,
                    borderRadius: '25px'
                  }}
                />
                <Typography
                  variant="h3"
                  component="h2"
                  sx={{
                    fontWeight: 800,
                    fontSize: { xs: '2.5rem', md: '3.5rem', lg: '4rem' },
                    background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                    backgroundClip: 'text',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                    mb: 3,
                    lineHeight: 1.2
                  }}
                >
                  Notre Histoire
                </Typography>
                <Typography
                  variant="h6"
                  sx={{
                    color: 'text.secondary',
                    maxWidth: 600,
                    mx: 'auto',
                    fontSize: { xs: '1.1rem', md: '1.25rem' },
                    lineHeight: 1.6
                  }}
                >
                  Une solution pensée par des professionnels, pour des professionnels
                </Typography>
              </Box>

              <Grid container spacing={{ xs: 4, md: 6 }} alignItems="center">
                {/* Left side - Content */}
                <Grid item xs={12} md={6}>
                  <Box sx={{ pr: { xs: 0, md: 4 } }}>
                    {/* Mission Card */}
                    <Card
                      sx={{
                        p: 4,
                        mb: 4,
                        background: 'linear-gradient(135deg, #ffffff 0%, #f8fafc 100%)',
                        border: '1px solid rgba(99, 102, 241, 0.1)',
                        borderRadius: 3,
                        boxShadow: '0 10px 40px rgba(0, 0, 0, 0.1)',
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          transform: 'translateY(-5px)',
                          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.15)'
                        }
                      }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                        <Box
                          sx={{
                            width: 50,
                            height: 50,
                            borderRadius: '50%',
                            background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            mr: 3
                          }}
                        >
                          <StarIcon sx={{ color: 'white', fontSize: 24 }} />
                        </Box>
                        <Typography variant="h5" sx={{ fontWeight: 700, color: 'text.primary' }}>
                          Notre Mission
                        </Typography>
                      </Box>
                      <Typography variant="body1" sx={{ lineHeight: 1.7, color: 'text.secondary' }}>
                        Simplifier la gestion quotidienne des ateliers de réparation grâce à une solution 
                        moderne et intuitive. Nous comprenons les défis des techniciens et propriétaires d'ateliers.
                      </Typography>
                    </Card>

                    {/* Vision Card */}
                    <Card
                      sx={{
                        p: 4,
                        mb: 4,
                        background: 'linear-gradient(135deg, #ffffff 0%, #f0fdf4 100%)',
                        border: '1px solid rgba(16, 185, 129, 0.1)',
                        borderRadius: 3,
                        boxShadow: '0 10px 40px rgba(0, 0, 0, 0.1)',
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          transform: 'translateY(-5px)',
                          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.15)'
                        }
                      }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                        <Box
                          sx={{
                            width: 50,
                            height: 50,
                            borderRadius: '50%',
                            background: 'linear-gradient(135deg, #10b981, #059669)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            mr: 3
                          }}
                        >
                          <TrendingUpIcon sx={{ color: 'white', fontSize: 24 }} />
                        </Box>
                        <Typography variant="h5" sx={{ fontWeight: 700, color: 'text.primary' }}>
                          Notre Vision
                        </Typography>
                      </Box>
                      <Typography variant="body1" sx={{ lineHeight: 1.7, color: 'text.secondary' }}>
                        Devenir la référence en matière de gestion d'atelier, en accompagnant la transformation 
                        digitale des professionnels de la réparation.
                      </Typography>
                    </Card>

                    {/* Values Card */}
                    <Card
                      sx={{
                        p: 4,
                        background: 'linear-gradient(135deg, #ffffff 0%, #fef3c7 100%)',
                        border: '1px solid rgba(245, 158, 11, 0.1)',
                        borderRadius: 3,
                        boxShadow: '0 10px 40px rgba(0, 0, 0, 0.1)',
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          transform: 'translateY(-5px)',
                          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.15)'
                        }
                      }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                        <Box
                          sx={{
                            width: 50,
                            height: 50,
                            borderRadius: '50%',
                            background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            mr: 3
                          }}
                        >
                          <CheckCircleIcon sx={{ color: 'white', fontSize: 24 }} />
                        </Box>
                        <Typography variant="h5" sx={{ fontWeight: 700, color: 'text.primary' }}>
                          Nos Valeurs
                        </Typography>
                      </Box>
                      <Typography variant="body1" sx={{ lineHeight: 1.7, color: 'text.secondary' }}>
                        Innovation, simplicité, fiabilité et accompagnement personnalisé sont au cœur 
                        de notre démarche pour vous offrir la meilleure expérience possible.
                      </Typography>
                    </Card>
                  </Box>
                </Grid>

                {/* Right side - Visual elements */}
                <Grid item xs={12} md={6}>
                  <Box sx={{ textAlign: 'center', position: 'relative' }}>
                    {/* Main visual container */}
                    <Box
                      sx={{
                        position: 'relative',
                        width: { xs: 280, sm: 350, md: 400 },
                        height: { xs: 280, sm: 350, md: 400 },
                        mx: 'auto'
                      }}
                    >
                      {/* Central icon with gradient background */}
                      <Box
                        sx={{
                          position: 'absolute',
                          top: '50%',
                          left: '50%',
                          transform: 'translate(-50%, -50%)',
                          width: { xs: 120, sm: 150, md: 180 },
                          height: { xs: 120, sm: 150, md: 180 },
                          borderRadius: '50%',
                          background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #10b981 100%)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          boxShadow: '0 20px 60px rgba(99, 102, 241, 0.3)',
                          animation: 'pulse 3s ease-in-out infinite'
                        }}
                      >
                        <BuildIcon sx={{ 
                          fontSize: { xs: 60, sm: 80, md: 100 }, 
                          color: 'white',
                          filter: 'drop-shadow(0 4px 8px rgba(0,0,0,0.2))'
                        }} />
                      </Box>

                      {/* Floating feature icons */}
                      {[
                        { icon: <PeopleIcon />, color: '#3b82f6', delay: 0 },
                        { icon: <ScheduleIcon />, color: '#10b981', delay: 1 },
                        { icon: <InventoryIcon />, color: '#f59e0b', delay: 2 },
                        { icon: <AssessmentIcon />, color: '#ef4444', delay: 3 }
                      ].map((item, index) => (
                        <Box
                          key={index}
                          sx={{
                            position: 'absolute',
                            width: { xs: 60, sm: 80, md: 100 },
                            height: { xs: 60, sm: 80, md: 100 },
                            borderRadius: '50%',
                            background: 'white',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            boxShadow: '0 10px 30px rgba(0, 0, 0, 0.1)',
                            border: `3px solid ${item.color}20`,
                            top: index < 2 ? '10%' : '70%',
                            left: index % 2 === 0 ? '10%' : '70%',
                            animation: `float1 ${4 + index}s ease-in-out infinite`,
                            animationDelay: `${item.delay}s`,
                            '&:hover': {
                              transform: 'scale(1.1)',
                              boxShadow: `0 15px 40px ${item.color}30`
                            }
                          }}
                        >
                          {React.cloneElement(item.icon, {
                            sx: { 
                              fontSize: { xs: 30, sm: 40, md: 50 }, 
                              color: item.color 
                            }
                          })}
                        </Box>
                      ))}
                    </Box>

                    {/* Stats section */}
                    <Box sx={{ mt: 6 }}>
                      <Grid container spacing={3}>
                        {[
                          { number: '18', label: 'Modules Complets', color: '#6366f1' },
                          { number: '100%', label: 'Satisfaction', color: '#10b981' },
                          { number: '24/7', label: 'Disponible', color: '#f59e0b' }
                        ].map((stat, index) => (
                          <Grid item xs={4} key={index}>
                            <Box
                              sx={{
                                textAlign: 'center',
                                p: 3,
                                background: 'white',
                                borderRadius: 2,
                                boxShadow: '0 5px 20px rgba(0, 0, 0, 0.08)',
                                border: `2px solid ${stat.color}20`,
                                transition: 'all 0.3s ease',
                                '&:hover': {
                                  transform: 'translateY(-5px)',
                                  boxShadow: `0 10px 30px ${stat.color}30`
                                }
                              }}
                            >
                              <Typography
                                variant="h4"
                                sx={{
                                  fontWeight: 800,
                                  color: stat.color,
                                  fontSize: { xs: '1.5rem', md: '2rem' }
                                }}
                              >
                                {stat.number}
                              </Typography>
                              <Typography
                                variant="body2"
                                sx={{
                                  color: 'text.secondary',
                                  fontWeight: 600,
                                  fontSize: { xs: '0.75rem', md: '0.875rem' }
                                }}
                              >
                                {stat.label}
                              </Typography>
                            </Box>
                          </Grid>
                        ))}
                      </Grid>
                    </Box>
                  </Box>
                </Grid>
              </Grid>

              {/* Bottom CTA */}
              <Box sx={{ textAlign: 'center', mt: { xs: 6, md: 8 } }}>
                <Typography
                  variant="h5"
                  sx={{
                    mb: 3,
                    fontWeight: 600,
                    color: 'text.primary'
                  }}
                >
                  Prêt à transformer votre atelier ?
                </Typography>
                <Button
                  variant="contained"
                  size="large"
                  onClick={handleAccessApp}
                  sx={{
                    px: 6,
                    py: 2,
                    fontSize: '1.1rem',
                    fontWeight: 600,
                    borderRadius: 3,
                    background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                    boxShadow: '0 10px 30px rgba(99, 102, 241, 0.3)',
                    '&:hover': {
                      transform: 'translateY(-2px)',
                      boxShadow: '0 15px 40px rgba(99, 102, 241, 0.4)'
                    }
                  }}
                  endIcon={<ArrowForwardIcon />}
                >
                  Découvrir la Solution
                </Button>
              </Box>
            </Box>
          </Slide>
        </Container>
      </Box>

      {/* CTA Section */}
      <Container maxWidth="md" sx={{ py: { xs: 6, md: 8 }, px: { xs: 2, md: 3 }, textAlign: 'center' }}>
        <Fade in timeout={1200}>
          <Box>
            <Typography
              variant="h4"
              component="h2"
              sx={{
                mb: { xs: 2, md: 3 },
                fontWeight: 600,
                fontSize: { xs: '1.75rem', md: '2.125rem' }
              }}
            >
              Prêt à Optimiser Votre Atelier ?
            </Typography>
            <Typography
              variant="h6"
              color="text.secondary"
              sx={{ 
                mb: { xs: 3, md: 4 }, 
                maxWidth: 600, 
                mx: 'auto',
                fontSize: { xs: '1rem', md: '1.25rem' }
              }}
            >
              Rejoignez les ateliers qui ont déjà transformé leur gestion quotidienne avec notre solution complète.
            </Typography>
            <Button
              variant="contained"
              size="large"
              onClick={handleAccessApp}
              sx={{
                px: { xs: 4, md: 6 },
                py: { xs: 1.5, md: 2 },
                fontSize: { xs: '1rem', md: '1.2rem' },
                fontWeight: 600,
                borderRadius: 3,
                width: { xs: '100%', sm: 'auto' }
              }}
              endIcon={<ArrowForwardIcon />}
            >
              Commencer Maintenant
            </Button>
          </Box>
        </Fade>
      </Container>

      {/* Footer */}
      <Box
        sx={{
          bgcolor: '#2c3e50',
          color: 'white',
          py: { xs: 4, md: 6 },
          position: 'relative',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            height: '1px',
            background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)'
          }
        }}
      >
        <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 } }}>
          <Grid container spacing={{ xs: 3, md: 4 }}>
            {/* Company Info */}
            <Grid item xs={12} md={4}>
              <Box sx={{ mb: 3 }}>
                <Typography 
                  variant="h5" 
                  sx={{ 
                    fontWeight: 700, 
                    mb: 2,
                    background: 'linear-gradient(45deg, #3498db, #2ecc71)',
                    backgroundClip: 'text',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent'
                  }}
                >
                  Atelier Gestion
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.8, mb: 3, lineHeight: 1.6 }}>
                  Solution complète de gestion d'atelier avec 18 modules intégrés : suivi Kanban, SAV, calendrier, 
                  clients, inventaire, facturation, devis, statistiques, fidélité, archives et bien plus encore.
                </Typography>
                <Box sx={{ display: 'flex', gap: 2 }}>
                  <Box
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: '50%',
                      background: 'rgba(255,255,255,0.1)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        background: '#3498db',
                        transform: 'translateY(-2px)'
                      }
                    }}
                  >
                    <Typography variant="body2">📧</Typography>
                  </Box>
                  <Box
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: '50%',
                      background: 'rgba(255,255,255,0.1)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        background: '#3498db',
                        transform: 'translateY(-2px)'
                      }
                    }}
                  >
                    <Typography variant="body2">📞</Typography>
                  </Box>
                  <Box
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: '50%',
                      background: 'rgba(255,255,255,0.1)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        background: '#3498db',
                        transform: 'translateY(-2px)'
                      }
                    }}
                  >
                    <Typography variant="body2">💬</Typography>
                  </Box>
                </Box>
              </Box>
            </Grid>



            {/* Support */}
            <Grid item xs={12} md={2}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
                Support
              </Typography>
              <Stack spacing={1.5}>
                {[
                  { name: 'Contact Support', path: '/support' },
                  { name: 'FAQ', path: '/faq' }
                ].map((link, index) => (
                  <Link
                    key={index}
                    href={link.path}
                    sx={{ 
                      opacity: 0.8, 
                      cursor: 'pointer',
                      color: 'inherit',
                      textDecoration: 'none',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        opacity: 1,
                        color: '#3498db',
                        transform: 'translateX(5px)'
                      }
                    }}
                  >
                    <Typography variant="body2">
                      {link.name}
                    </Typography>
                  </Link>
                ))}
              </Stack>
            </Grid>

            {/* Legal */}
            <Grid item xs={12} md={2}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
                Légal
              </Typography>
              <Stack spacing={1.5}>
                {[
                  { name: 'Conditions d\'Utilisation', path: '/terms-of-service' },
                  { name: 'Politique de Confidentialité', path: '/privacy-policy' },
                  { name: 'CGV', path: '/cgv' },
                  { name: 'RGPD', path: '/rgpd' }
                ].map((link, index) => (
                  <Link
                    key={index}
                    href={link.path}
                    sx={{ 
                      opacity: 0.8, 
                      cursor: 'pointer',
                      color: 'inherit',
                      textDecoration: 'none',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        opacity: 1,
                        color: '#3498db',
                        transform: 'translateX(5px)'
                      }
                    }}
                  >
                    <Typography variant="body2">
                      {link.name}
                    </Typography>
                  </Link>
                ))}
              </Stack>
            </Grid>

            {/* Contact Info */}
            <Grid item xs={12} md={2}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
                Contact
              </Typography>
              <Stack spacing={1.5}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Typography variant="body2" sx={{ opacity: 0.8 }}>📧</Typography>
                  <Typography variant="body2" sx={{ opacity: 0.8, fontSize: '0.8rem' }}>
                    contact.ateliergestion@gmail.com
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Typography variant="body2" sx={{ opacity: 0.8 }}>📞</Typography>
                  <Typography variant="body2" sx={{ opacity: 0.8, fontSize: '0.8rem' }}>
                    07 59 23 91 70
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Typography variant="body2" sx={{ opacity: 0.8 }}>📍</Typography>
                  <Typography variant="body2" sx={{ opacity: 0.8, fontSize: '0.8rem' }}>
                    France
                  </Typography>
                </Box>
              </Stack>
            </Grid>
          </Grid>

          {/* Bottom Section */}
          <Box 
            sx={{ 
              mt: 4, 
              pt: 3, 
              borderTop: '1px solid rgba(255,255,255,0.1)',
              display: 'flex',
              flexDirection: { xs: 'column', md: 'row' },
              justifyContent: 'space-between',
              alignItems: 'center',
              gap: 2
            }}
          >
            <Typography variant="body2" sx={{ opacity: 0.7 }}>
              © 2025 Atelier Gestion. Tous droits réservés.
            </Typography>
            <Box sx={{ display: 'flex', gap: 3 }}>
              <Link
                href="/privacy-policy"
                sx={{ 
                  opacity: 0.7,
                  cursor: 'pointer',
                  color: 'inherit',
                  textDecoration: 'none',
                  '&:hover': { opacity: 1, color: '#3498db' }
                }}
              >
                <Typography variant="body2">
                  Politique de Confidentialité
                </Typography>
              </Link>
              <Link
                href="/terms-of-service"
                sx={{ 
                  opacity: 0.7,
                  cursor: 'pointer',
                  color: 'inherit',
                  textDecoration: 'none',
                  '&:hover': { opacity: 1, color: '#3498db' }
                }}
              >
                <Typography variant="body2">
                  Conditions d'Utilisation
                </Typography>
              </Link>
            </Box>
          </Box>
        </Container>
      </Box>
    </Box>
  );
};

export default Landing;

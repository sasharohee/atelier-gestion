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
  Slide
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
  TrendingUp as TrendingUpIcon
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import LandingNavbar from '../../components/LandingNavbar';

const Landing: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
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
      icon: <BuildIcon sx={{ fontSize: 40, color: theme.palette.primary.main }} />,
      title: 'Gestion des Réparations',
      description: 'Suivez l\'état de vos réparations en temps réel avec notre système Kanban intuitif'
    },
    {
      icon: <ScheduleIcon sx={{ fontSize: 40, color: theme.palette.primary.main }} />,
      title: 'Calendrier & Rendez-vous',
      description: 'Planifiez et gérez vos rendez-vous clients avec un calendrier intégré'
    },
    {
      icon: <PeopleIcon sx={{ fontSize: 40, color: theme.palette.primary.main }} />,
      title: 'Gestion Clients',
      description: 'Centralisez les informations de vos clients et leur historique de réparations'
    },
    {
      icon: <InventoryIcon sx={{ fontSize: 40, color: theme.palette.primary.main }} />,
      title: 'Inventaire & Pièces',
      description: 'Gérez votre stock de pièces détachées et vos produits en vente'
    },
    {
      icon: <AssessmentIcon sx={{ fontSize: 40, color: theme.palette.primary.main }} />,
      title: 'Statistiques & Rapports',
      description: 'Analysez vos performances avec des tableaux de bord détaillés'
    },
    {
      icon: <MessageIcon sx={{ fontSize: 40, color: theme.palette.primary.main }} />,
      title: 'Communication',
      description: 'Communiquez directement avec vos clients depuis l\'application'
    }
  ];

  const benefits = [
    'Interface moderne et intuitive',
    'Synchronisation en temps réel',
    'Gestion complète de l\'atelier',
    'Rapports détaillés',
    'Support multi-appareils',
    'Sécurisé et fiable'
  ];

  const handleAccessApp = () => {
    navigate('/auth');
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* Navbar */}
      <LandingNavbar />
      
      {/* Hero Section */}
      <Box
        id="home"
        sx={{
          background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 50%, ${theme.palette.secondary.main} 100%)`,
          color: 'white',
          minHeight: '100vh',
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center'
        }}
      >
        {/* Animated background elements */}
        <Box
          sx={{
            position: 'absolute',
            top: '10%',
            left: '5%',
            width: 200,
            height: 200,
            borderRadius: '50%',
            background: 'rgba(255, 255, 255, 0.1)',
            animation: 'float1 6s ease-in-out infinite'
          }}
        />
        <Box
          sx={{
            position: 'absolute',
            bottom: '20%',
            right: '10%',
            width: 150,
            height: 150,
            borderRadius: '50%',
            background: 'rgba(255, 255, 255, 0.08)',
            animation: 'float2 8s ease-in-out infinite reverse'
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
            background: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.03'%3E%3Ccircle cx='30' cy='30' r='1.5'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
            opacity: 0.6
          }}
        />

        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 2 }}>
          <Grid container spacing={4} alignItems="center">
            {/* Left side - Content */}
            <Grid item xs={12} md={7}>
              <Fade in timeout={1000}>
                <Box>
                  {/* Badge */}
                  <Box sx={{ mb: 3 }}>
                    <Chip
                      icon={<StarIcon />}
                      label="Solution Professionnelle"
                      sx={{
                        bgcolor: 'rgba(255, 255, 255, 0.2)',
                        color: 'white',
                        fontSize: '0.9rem',
                        fontWeight: 600,
                        backdropFilter: 'blur(10px)',
                        border: '1px solid rgba(255, 255, 255, 0.3)'
                      }}
                    />
                  </Box>

                  {/* Main title */}
                  <Typography
                    variant="h1"
                    component="h1"
                    sx={{
                      fontWeight: 800,
                      mb: 3,
                      fontSize: { xs: '2.5rem', sm: '3.5rem', md: '4rem' },
                      lineHeight: 1.1,
                      background: 'linear-gradient(45deg, #ffffff 30%, #f0f0f0 90%)',
                      backgroundClip: 'text',
                      WebkitBackgroundClip: 'text',
                      WebkitTextFillColor: 'transparent',
                      textShadow: '0 2px 4px rgba(0,0,0,0.1)'
                    }}
                  >
                    Atelier Gestion
                  </Typography>

                  {/* Subtitle */}
                  <Typography
                    variant="h4"
                    sx={{
                      mb: 4,
                      opacity: 0.95,
                      fontWeight: 400,
                      fontSize: { xs: '1.2rem', md: '1.5rem' },
                      lineHeight: 1.4,
                      maxWidth: 500
                    }}
                  >
                    La solution complète pour gérer votre atelier de réparation d'appareils électroniques
                  </Typography>

                  {/* Features highlights */}
                  <Box sx={{ mb: 4 }}>
                    <Stack direction="row" spacing={3} flexWrap="wrap" useFlexGap>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                        <CheckCircleIcon sx={{ mr: 1, fontSize: 20, color: '#4CAF50' }} />
                        <Typography variant="body1" sx={{ fontWeight: 500 }}>
                          Gestion complète
                        </Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                        <CheckCircleIcon sx={{ mr: 1, fontSize: 20, color: '#4CAF50' }} />
                        <Typography variant="body1" sx={{ fontWeight: 500 }}>
                          Interface intuitive
                        </Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                        <CheckCircleIcon sx={{ mr: 1, fontSize: 20, color: '#4CAF50' }} />
                        <Typography variant="body1" sx={{ fontWeight: 500 }}>
                          Temps réel
                        </Typography>
                      </Box>
                    </Stack>
                  </Box>

                  {/* CTA Buttons */}
                  <Stack
                    direction={{ xs: 'column', sm: 'row' }}
                    spacing={2}
                    sx={{ mb: 4 }}
                  >
                    <Button
                      variant="contained"
                      size="large"
                      onClick={handleAccessApp}
                      sx={{
                        bgcolor: 'white',
                        color: theme.palette.primary.main,
                        px: 4,
                        py: 2,
                        fontSize: '1.1rem',
                        fontWeight: 700,
                        borderRadius: 3,
                        boxShadow: '0 8px 32px rgba(0,0,0,0.2)',
                        transition: 'all 0.3s ease',
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
                    <Button
                      variant="outlined"
                      size="large"
                      sx={{
                        borderColor: 'rgba(255, 255, 255, 0.5)',
                        color: 'white',
                        px: 4,
                        py: 2,
                        fontSize: '1rem',
                        fontWeight: 600,
                        borderRadius: 3,
                        backdropFilter: 'blur(10px)',
                        '&:hover': {
                          borderColor: 'white',
                          bgcolor: 'rgba(255, 255, 255, 0.1)'
                        }
                      }}
                      startIcon={<PlayArrowIcon />}
                    >
                      Voir la Démo
                    </Button>
                  </Stack>

                  {/* Stats */}
                  <Box sx={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" sx={{ fontWeight: 700, color: '#4CAF50' }}>
                        100%
                      </Typography>
                      <Typography variant="body2" sx={{ opacity: 0.8 }}>
                        Satisfaction
                      </Typography>
                    </Box>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" sx={{ fontWeight: 700, color: '#4CAF50' }}>
                        <TrendingUpIcon sx={{ fontSize: 32, verticalAlign: 'middle', mr: 0.5 }} />
                        50%
                      </Typography>
                      <Typography variant="body2" sx={{ opacity: 0.8 }}>
                        Gain de temps
                      </Typography>
                    </Box>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" sx={{ fontWeight: 700, color: '#4CAF50' }}>
                        24/7
                      </Typography>
                      <Typography variant="body2" sx={{ opacity: 0.8 }}>
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
                <Box sx={{ textAlign: 'center', position: 'relative' }}>
                  {/* Main visual element */}
                  <Box
                    sx={{
                      width: { xs: 280, md: 350 },
                      height: { xs: 280, md: 350 },
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
                        width: 120,
                        height: 120,
                        borderRadius: '50%',
                        bgcolor: 'rgba(255, 255, 255, 0.15)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        backdropFilter: 'blur(10px)',
                        border: '2px solid rgba(255, 255, 255, 0.3)'
                      }}
                    >
                      <BuildIcon sx={{ fontSize: 60, color: 'white' }} />
                    </Box>

                    {/* Orbiting elements */}
                    {[0, 1, 2, 3, 4, 5].map((index) => (
                      <Box
                        key={index}
                        sx={{
                          position: 'absolute',
                          top: '50%',
                          left: '50%',
                          width: 60,
                          height: 60,
                          borderRadius: '50%',
                          bgcolor: 'rgba(255, 255, 255, 0.1)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          transform: `translate(-50%, -50%) rotate(${index * 60}deg) translateY(-120px)`,
                          animation: `orbit${index} ${8 + index}s linear infinite`
                        }}
                      >
                        <Box
                          sx={{
                            width: 20,
                            height: 20,
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
                      top: '20%',
                      right: '10%',
                      bgcolor: 'rgba(255, 255, 255, 0.1)',
                      borderRadius: 2,
                      p: 2,
                      backdropFilter: 'blur(10px)',
                      border: '1px solid rgba(255, 255, 255, 0.2)',
                      animation: 'float1 4s ease-in-out infinite'
                    }}
                  >
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      📊 +25% efficacité
                    </Typography>
                  </Box>

                  <Box
                    sx={{
                      position: 'absolute',
                      bottom: '30%',
                      left: '5%',
                      bgcolor: 'rgba(255, 255, 255, 0.1)',
                      borderRadius: 2,
                      p: 2,
                      backdropFilter: 'blur(10px)',
                      border: '1px solid rgba(255, 255, 255, 0.2)',
                      animation: 'float2 6s ease-in-out infinite reverse'
                    }}
                  >
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
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
      <Container maxWidth="lg" sx={{ py: 8 }} id="features">
        <Slide direction="up" in timeout={800}>
          <Box>
            <Typography
              variant="h3"
              component="h2"
              sx={{
                textAlign: 'center',
                mb: 6,
                fontWeight: 600,
                color: theme.palette.text.primary
              }}
            >
              Fonctionnalités Principales
            </Typography>
            
            <Grid container spacing={4}>
              {features.map((feature, index) => (
                <Grid item xs={12} sm={6} md={4} key={index}>
                  <Fade in timeout={800 + index * 200}>
                    <Card
                      sx={{
                        height: '100%',
                        transition: 'transform 0.3s ease-in-out, box-shadow 0.3s ease-in-out',
                        '&:hover': {
                          transform: 'translateY(-8px)',
                          boxShadow: theme.shadows[8]
                        }
                      }}
                    >
                      <CardContent sx={{ textAlign: 'center', p: 3 }}>
                        <Box sx={{ mb: 2 }}>
                          {feature.icon}
                        </Box>
                        <Typography
                          variant="h6"
                          component="h3"
                          sx={{ mb: 2, fontWeight: 600 }}
                        >
                          {feature.title}
                        </Typography>
                        <Typography
                          variant="body2"
                          color="text.secondary"
                          sx={{ lineHeight: 1.6 }}
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
      <Box sx={{ bgcolor: 'grey.50', py: 8 }} id="benefits">
        <Container maxWidth="lg">
          <Slide direction="up" in timeout={1000}>
            <Box>
              <Typography
                variant="h3"
                component="h2"
                sx={{
                  textAlign: 'center',
                  mb: 6,
                  fontWeight: 600
                }}
              >
                Pourquoi Choisir Atelier Gestion ?
              </Typography>
              
              <Grid container spacing={3} justifyContent="center">
                {benefits.map((benefit, index) => (
                  <Grid item xs={12} sm={6} md={4} key={index}>
                    <Fade in timeout={1000 + index * 150}>
                      <Box
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          p: 2,
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
                            mr: 2,
                            fontSize: 24
                          }}
                        />
                        <Typography variant="body1" sx={{ fontWeight: 500 }}>
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
      <Box sx={{ bgcolor: 'grey.50', py: 8 }} id="pricing">
        <Container maxWidth="lg">
          <Slide direction="up" in timeout={1200}>
            <Box>
              <Typography
                variant="h3"
                component="h2"
                sx={{
                  textAlign: 'center',
                  mb: 2,
                  fontWeight: 600
                }}
              >
                Tarifs Simples et Transparents
              </Typography>
              <Typography
                variant="h6"
                color="text.secondary"
                sx={{
                  textAlign: 'center',
                  mb: 6,
                  maxWidth: 600,
                  mx: 'auto'
                }}
              >
                Un seul plan, toutes les fonctionnalités incluses. Pas de surprise, pas de frais cachés.
              </Typography>
              
              <Box sx={{ display: 'flex', justifyContent: 'center' }}>
                <Card
                  sx={{
                    maxWidth: 400,
                    width: '100%',
                    textAlign: 'center',
                    position: 'relative',
                    overflow: 'visible',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      transform: 'translateY(-8px)',
                      boxShadow: theme.shadows[8]
                    }
                  }}
                >
                  {/* Popular Badge */}
                  <Box
                    sx={{
                      position: 'absolute',
                      top: -15,
                      left: '50%',
                      transform: 'translateX(-50%)',
                      bgcolor: theme.palette.primary.main,
                      color: 'white',
                      px: 3,
                      py: 1,
                      borderRadius: '20px',
                      fontSize: '0.9rem',
                      fontWeight: 600,
                      boxShadow: theme.shadows[2]
                    }}
                  >
                    ⭐ Plan Recommandé
                  </Box>
                  
                  <CardContent sx={{ p: 4 }}>
                    <Typography variant="h4" component="h3" sx={{ mb: 2, fontWeight: 700 }}>
                      Atelier Pro
                    </Typography>
                    
                    <Box sx={{ mb: 3 }}>
                      <Typography variant="h2" component="span" sx={{ fontWeight: 800, color: theme.palette.primary.main }}>
                        15,99€
                      </Typography>
                      <Typography variant="h6" component="span" sx={{ color: 'text.secondary' }}>
                        /mois
                      </Typography>
                    </Box>
                    
                    <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
                      Accès complet à toutes les fonctionnalités pour votre atelier
                    </Typography>
                    
                    <Box sx={{ mb: 4 }}>
                      <Stack spacing={2}>
                        {[
                          '✅ Gestion complète des réparations',
                          '✅ Calendrier et rendez-vous illimités',
                          '✅ Base de données clients illimitée',
                          '✅ Inventaire et gestion des pièces',
                          '✅ Rapports et statistiques détaillés',
                          '✅ Support technique prioritaire',
                          '✅ Sauvegarde automatique des données',
                          '✅ Mises à jour gratuites',
                          '✅ Accès multi-appareils',
                          '✅ Formation et support inclus'
                        ].map((feature, index) => (
                          <Box key={index} sx={{ display: 'flex', alignItems: 'center', textAlign: 'left' }}>
                            <Typography variant="body1" sx={{ fontWeight: 500 }}>
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
                        py: 2,
                        fontSize: '1.1rem',
                        fontWeight: 600,
                        borderRadius: '50px',
                        boxShadow: theme.shadows[3],
                        '&:hover': {
                          boxShadow: theme.shadows[6],
                          transform: 'translateY(-2px)'
                        }
                      }}
                      endIcon={<ArrowForwardIcon />}
                    >
                      Commencer l'Essai Gratuit
                    </Button>
                    
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                      Essai gratuit de 14 jours • Aucune carte de crédit requise
                    </Typography>
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
      <Container maxWidth="lg" sx={{ py: 8 }} id="about">
        <Slide direction="up" in timeout={1200}>
          <Box>
            <Typography
              variant="h3"
              component="h2"
              sx={{
                textAlign: 'center',
                mb: 6,
                fontWeight: 600
              }}
            >
              À Propos d'Atelier Gestion
            </Typography>
            
            <Grid container spacing={4} alignItems="center">
              <Grid item xs={12} md={6}>
                <Typography variant="h6" sx={{ mb: 3, fontWeight: 600 }}>
                  Notre Mission
                </Typography>
                <Typography variant="body1" sx={{ mb: 3, lineHeight: 1.7 }}>
                  Atelier Gestion est né de la volonté de simplifier la gestion quotidienne des ateliers de réparation. 
                  Nous comprenons les défis auxquels font face les techniciens et propriétaires d'ateliers.
                </Typography>
                <Typography variant="body1" sx={{ mb: 3, lineHeight: 1.7 }}>
                  Notre solution offre une approche moderne et intuitive pour gérer les clients, les réparations, 
                  l'inventaire et les rendez-vous, le tout depuis une interface unifiée.
                </Typography>
                <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
                  Que vous soyez un petit atelier ou une chaîne de réparation, notre plateforme s'adapte à vos besoins 
                  et évolue avec votre entreprise.
                </Typography>
              </Grid>
              <Grid item xs={12} md={6}>
                <Box sx={{ textAlign: 'center' }}>
                  <Box
                    sx={{
                      width: 300,
                      height: 300,
                      mx: 'auto',
                      borderRadius: '50%',
                      background: `linear-gradient(135deg, ${theme.palette.primary.light} 0%, ${theme.palette.secondary.light} 100%)`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      position: 'relative',
                      '&::before': {
                        content: '""',
                        position: 'absolute',
                        top: -10,
                        left: -10,
                        right: -10,
                        bottom: -10,
                        borderRadius: '50%',
                        background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                        zIndex: -1,
                        opacity: 0.3,
                        animation: 'pulse 2s ease-in-out infinite'
                      }
                    }}
                  >
                    <BuildIcon sx={{ fontSize: 120, color: 'white' }} />
                  </Box>
                </Box>
              </Grid>
            </Grid>
          </Box>
        </Slide>
      </Container>

      {/* CTA Section */}
      <Container maxWidth="md" sx={{ py: 8, textAlign: 'center' }}>
        <Fade in timeout={1200}>
          <Box>
            <Typography
              variant="h4"
              component="h2"
              sx={{
                mb: 3,
                fontWeight: 600
              }}
            >
              Prêt à Optimiser Votre Atelier ?
            </Typography>
            <Typography
              variant="h6"
              color="text.secondary"
              sx={{ mb: 4, maxWidth: 600, mx: 'auto' }}
            >
              Rejoignez les ateliers qui ont déjà transformé leur gestion quotidienne avec notre solution complète.
            </Typography>
            <Button
              variant="contained"
              size="large"
              onClick={handleAccessApp}
              sx={{
                px: 6,
                py: 2,
                fontSize: '1.2rem',
                fontWeight: 600,
                borderRadius: 3
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
          bgcolor: theme.palette.grey[900],
          color: 'white',
          py: 4,
          textAlign: 'center'
        }}
      >
        <Container maxWidth="lg">
          <Typography variant="body2" sx={{ opacity: 0.8 }}>
            © 2024 Atelier Gestion - Laast.io. Tous droits réservés.
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.6, mt: 1 }}>
            Solution de gestion d'atelier de réparation d'appareils électroniques
          </Typography>
        </Container>
      </Box>
    </Box>
  );
};

export default Landing;

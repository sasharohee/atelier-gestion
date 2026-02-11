import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Chip,
} from '@mui/material';
import {
  ArrowForward as ArrowForwardIcon,
  Lock as LockIcon,
  Autorenew as AutorenewIcon,
  HeadsetMic as HeadsetMicIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { colors, gradients, glassCard } from '../constants/landingColors';
import { useScrollAnimation } from '../constants/landingAnimations';

const features = [
  'Suivi Kanban des réparations',
  'SAV et gestion des garanties',
  'Calendrier et rendez-vous',
  'Base de données clients',
  'Gestion des appareils',
  'Inventaire pièces & produits',
  'Ventes et facturation',
  'Devis et estimations',
  'Statistiques et rapports',
  'Programme de fidélité',
  'Support technique prioritaire',
  'Mises à jour gratuites',
];

const trustItems = [
  {
    icon: LockIcon,
    title: 'Paiement Sécurisé',
    description: 'Paiement sécurisé par Stripe, vos données sont protégées.',
  },
  {
    icon: AutorenewIcon,
    title: 'Annulation Simple',
    description: 'Annulez à tout moment, sans frais ni engagement.',
  },
  {
    icon: HeadsetMicIcon,
    title: 'Support 24/7',
    description: 'Notre équipe est là pour vous aider à tout moment.',
  },
];

const PricingSection: React.FC = () => {
  const [isAnnual, setIsAnnual] = useState(false);
  const navigate = useNavigate();
  const { ref, isVisible } = useScrollAnimation();

  const handleAccessApp = () => navigate('/auth');

  return (
    <Box
      id="pricing"
      ref={ref}
      sx={{
        background: colors.navy.dark,
        py: { xs: 8, md: 12 },
        position: 'relative',
      }}
    >
      <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 } }}>
        {/* Section Title */}
        <Box
          sx={{
            textAlign: 'center',
            mb: { xs: 2, md: 3 },
            opacity: isVisible ? 1 : 0,
            transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
            transition: 'all 0.6s ease-out',
          }}
        >
          <Typography
            variant="h3"
            component="h2"
            sx={{
              fontFamily: '"Outfit", sans-serif',
              fontWeight: 700,
              color: colors.text.white,
              fontSize: { xs: '2rem', md: '3rem' },
              mb: 2,
            }}
          >
            Tarifs{' '}
            <Box component="span" sx={{ color: colors.gold.primary }}>
              Simples
            </Box>{' '}
            et Transparents
          </Typography>
          <Typography
            sx={{
              color: colors.text.muted,
              fontSize: { xs: '1rem', md: '1.15rem' },
              maxWidth: 500,
              mx: 'auto',
              fontFamily: '"Inter", sans-serif',
              mb: { xs: 4, md: 5 },
            }}
          >
            Un seul plan, toutes les fonctionnalités. Pas de surprise.
          </Typography>
        </Box>

        {/* Toggle mensuel/annuel */}
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            mb: { xs: 4, md: 6 },
            opacity: isVisible ? 1 : 0,
            transition: 'all 0.6s ease-out 0.1s',
          }}
        >
          <Box
            sx={{
              display: 'inline-flex',
              borderRadius: '12px',
              background: 'rgba(15, 23, 42, 0.6)',
              border: `1px solid ${colors.glass.border}`,
              p: 0.5,
            }}
          >
            <Button
              onClick={() => setIsAnnual(false)}
              sx={{
                px: 3,
                py: 1,
                borderRadius: '10px',
                fontWeight: 600,
                fontSize: '0.9rem',
                fontFamily: '"Inter", sans-serif',
                textTransform: 'none',
                transition: 'all 0.3s ease',
                ...(isAnnual
                  ? {
                      color: colors.text.muted,
                      background: 'transparent',
                    }
                  : {
                      background: gradients.gold,
                      color: colors.navy.deep,
                    }),
              }}
            >
              Mensuel
            </Button>
            <Button
              onClick={() => setIsAnnual(true)}
              sx={{
                px: 3,
                py: 1,
                borderRadius: '10px',
                fontWeight: 600,
                fontSize: '0.9rem',
                fontFamily: '"Inter", sans-serif',
                textTransform: 'none',
                transition: 'all 0.3s ease',
                display: 'flex',
                alignItems: 'center',
                gap: 1,
                ...(isAnnual
                  ? {
                      background: gradients.gold,
                      color: colors.navy.deep,
                    }
                  : {
                      color: colors.text.muted,
                      background: 'transparent',
                    }),
              }}
            >
              Annuel
              <Chip
                label="-17%"
                size="small"
                sx={{
                  height: 20,
                  fontSize: '0.7rem',
                  fontWeight: 700,
                  bgcolor: '#22c55e',
                  color: 'white',
                }}
              />
            </Button>
          </Box>
        </Box>

        {/* Pricing card */}
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            opacity: isVisible ? 1 : 0,
            transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
            transition: 'all 0.6s ease-out 0.2s',
          }}
        >
          <Box
            sx={{
              maxWidth: 480,
              width: '100%',
              position: 'relative',
              borderRadius: '24px',
              p: '2px',
              background: gradients.borderAnimated,
              backgroundSize: '300% 300%',
              animation: 'landing-borderRotate 4s ease infinite',
            }}
          >
            <Box
              sx={{
                background: colors.navy.dark,
                borderRadius: '22px',
                p: { xs: 4, md: 5 },
                textAlign: 'center',
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              {/* Badge */}
              <Box
                sx={{
                  position: 'absolute',
                  top: 0,
                  left: '50%',
                  transform: 'translateX(-50%)',
                  background: gradients.gold,
                  color: colors.navy.deep,
                  px: 3,
                  py: 0.8,
                  borderRadius: '0 0 12px 12px',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  fontFamily: '"Inter", sans-serif',
                }}
              >
                Plan Recommandé
              </Box>

              {/* Plan name */}
              <Typography
                sx={{
                  fontFamily: '"Outfit", sans-serif',
                  fontWeight: 700,
                  color: colors.text.white,
                  fontSize: { xs: '1.5rem', md: '1.8rem' },
                  mt: 3,
                  mb: 3,
                }}
              >
                Atelier Pro
              </Typography>

              {/* Price */}
              <Box sx={{ mb: 1 }}>
                <Typography
                  component="span"
                  sx={{
                    fontFamily: '"Outfit", sans-serif',
                    fontWeight: 800,
                    color: colors.text.white,
                    fontSize: { xs: '3rem', md: '4rem' },
                    lineHeight: 1,
                  }}
                >
                  {isAnnual ? '200€' : '19,99€'}
                </Typography>
                <Typography
                  component="span"
                  sx={{
                    color: colors.text.dim,
                    fontWeight: 500,
                    fontSize: { xs: '1.1rem', md: '1.3rem' },
                    ml: 0.5,
                    fontFamily: '"Inter", sans-serif',
                  }}
                >
                  {isAnnual ? '/an' : '/mois'}
                </Typography>
              </Box>

              {isAnnual && (
                <Typography
                  sx={{
                    color: '#22c55e',
                    fontWeight: 600,
                    fontSize: '0.95rem',
                    mb: 1,
                    fontFamily: '"Inter", sans-serif',
                  }}
                >
                  Soit 16,67€/mois — Économie de 40€
                </Typography>
              )}

              <Typography
                sx={{
                  color: colors.text.dim,
                  fontSize: '0.9rem',
                  mb: 4,
                  fontFamily: '"Inter", sans-serif',
                }}
              >
                Accès complet à toutes les fonctionnalités
              </Typography>

              {/* Features list - 2 columns */}
              <Grid container spacing={1.5} sx={{ mb: 4, textAlign: 'left' }}>
                {features.map((f) => (
                  <Grid item xs={12} sm={6} key={f}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Box
                        sx={{
                          width: 20,
                          height: 20,
                          borderRadius: '50%',
                          background: colors.gold.subtle,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          flexShrink: 0,
                        }}
                      >
                        <Typography
                          sx={{
                            color: colors.gold.primary,
                            fontWeight: 700,
                            fontSize: '0.7rem',
                          }}
                        >
                          ✓
                        </Typography>
                      </Box>
                      <Typography
                        sx={{
                          color: colors.text.muted,
                          fontSize: '0.85rem',
                          fontFamily: '"Inter", sans-serif',
                        }}
                      >
                        {f}
                      </Typography>
                    </Box>
                  </Grid>
                ))}
              </Grid>

              {/* CTA */}
              <Button
                variant="contained"
                size="large"
                onClick={handleAccessApp}
                fullWidth
                sx={{
                  background: gradients.gold,
                  color: colors.navy.deep,
                  py: 2,
                  fontSize: '1.1rem',
                  fontWeight: 700,
                  fontFamily: '"Inter", sans-serif',
                  borderRadius: '14px',
                  textTransform: 'none',
                  boxShadow: `0 8px 32px ${colors.gold.glow}`,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%)',
                    transform: 'translateY(-2px)',
                    boxShadow: `0 12px 40px ${colors.gold.glow}`,
                  },
                }}
                endIcon={<ArrowForwardIcon />}
              >
                Commencer Maintenant
              </Button>
            </Box>
          </Box>
        </Box>

        {/* Trust cards */}
        <Grid
          container
          spacing={3}
          sx={{
            mt: { xs: 5, md: 7 },
            opacity: isVisible ? 1 : 0,
            transition: 'all 0.6s ease-out 0.4s',
          }}
        >
          {trustItems.map((item) => {
            const IconComponent = item.icon;
            return (
              <Grid item xs={12} sm={4} key={item.title}>
                <Box
                  sx={{
                    ...glassCard,
                    p: 3,
                    textAlign: 'center',
                  }}
                >
                  <IconComponent
                    sx={{ fontSize: 32, color: colors.gold.primary, mb: 1.5 }}
                  />
                  <Typography
                    sx={{
                      fontFamily: '"Outfit", sans-serif',
                      fontWeight: 600,
                      color: colors.text.white,
                      fontSize: '1rem',
                      mb: 0.5,
                    }}
                  >
                    {item.title}
                  </Typography>
                  <Typography
                    sx={{
                      color: colors.text.dim,
                      fontSize: '0.85rem',
                      fontFamily: '"Inter", sans-serif',
                    }}
                  >
                    {item.description}
                  </Typography>
                </Box>
              </Grid>
            );
          })}
        </Grid>
      </Container>
    </Box>
  );
};

export default PricingSection;

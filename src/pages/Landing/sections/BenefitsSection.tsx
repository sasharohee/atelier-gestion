import React from 'react';
import { Box, Container, Typography, Grid } from '@mui/material';
import {
  Devices as DevicesIcon,
  AllInclusive as AllInclusiveIcon,
  Sync as SyncIcon,
  ViewKanban as ViewKanbanIcon,
  Security as SecurityIcon,
  SupportAgent as SupportAgentIcon,
} from '@mui/icons-material';
import { colors, glassCard, glassCardHover } from '../constants/landingColors';
import { useScrollAnimation } from '../constants/landingAnimations';

const benefits = [
  {
    icon: DevicesIcon,
    title: 'Interface Moderne',
    description: 'Design intuitif et épuré, optimisé pour une utilisation sur ordinateur.',
  },
  {
    icon: AllInclusiveIcon,
    title: 'Tout-en-Un',
    description: '18 modules intégrés pour couvrir 100% des besoins de votre atelier.',
  },
  {
    icon: SyncIcon,
    title: 'Temps Réel',
    description: 'Synchronisation instantanée des données entre tous les postes.',
  },
  {
    icon: ViewKanbanIcon,
    title: 'Kanban Visuel',
    description: 'Suivez vos réparations d\'un coup d\'œil avec le tableau Kanban intuitif.',
  },
  {
    icon: SecurityIcon,
    title: 'Sécurisé',
    description: 'Données chiffrées, sauvegardes automatiques et hébergement sécurisé.',
  },
  {
    icon: SupportAgentIcon,
    title: 'Support Réactif',
    description: 'Une équipe dédiée pour vous accompagner au quotidien.',
  },
];

const BenefitsSection: React.FC = () => {
  const { ref, isVisible } = useScrollAnimation();

  return (
    <Box
      id="benefits"
      ref={ref}
      sx={{
        background: colors.navy.deep,
        py: { xs: 8, md: 12 },
        position: 'relative',
      }}
    >
      {/* Subtle glow */}
      <Box
        sx={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(ellipse at 50% 100%, rgba(245, 158, 11, 0.03) 0%, transparent 60%)',
        }}
      />

      <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 2, px: { xs: 2, md: 3 } }}>
        {/* Section Title */}
        <Box
          sx={{
            textAlign: 'center',
            mb: { xs: 5, md: 7 },
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
            Pourquoi Choisir{' '}
            <Box component="span" sx={{ color: colors.gold.primary }}>
              Atelier Gestion
            </Box>{' '}
            ?
          </Typography>
        </Box>

        {/* Benefit cards */}
        <Grid container spacing={3}>
          {benefits.map((b, index) => {
            const IconComponent = b.icon;
            return (
              <Grid item xs={12} sm={6} md={4} key={b.title}>
                <Box
                  sx={{
                    ...glassCard,
                    p: { xs: 3, md: 4 },
                    height: '100%',
                    textAlign: 'center',
                    transition: 'all 0.3s ease',
                    opacity: isVisible ? 1 : 0,
                    transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
                    transitionDelay: `${0.1 + index * 0.08}s`,
                    '&:hover': {
                      ...glassCardHover,
                      transform: 'translateY(-6px)',
                    },
                  }}
                >
                  <Box
                    sx={{
                      width: 56,
                      height: 56,
                      borderRadius: '14px',
                      background: colors.gold.subtle,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      mx: 'auto',
                      mb: 2.5,
                    }}
                  >
                    <IconComponent sx={{ fontSize: 28, color: colors.gold.primary }} />
                  </Box>
                  <Typography
                    variant="h6"
                    sx={{
                      fontFamily: '"Outfit", sans-serif',
                      fontWeight: 600,
                      color: colors.text.white,
                      fontSize: { xs: '1.05rem', md: '1.15rem' },
                      mb: 1,
                    }}
                  >
                    {b.title}
                  </Typography>
                  <Typography
                    variant="body2"
                    sx={{
                      color: colors.text.muted,
                      lineHeight: 1.6,
                      fontFamily: '"Inter", sans-serif',
                      fontSize: '0.9rem',
                    }}
                  >
                    {b.description}
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

export default BenefitsSection;

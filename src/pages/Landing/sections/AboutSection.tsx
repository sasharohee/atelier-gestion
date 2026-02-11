import React from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Button,
} from '@mui/material';
import {
  Star as StarIcon,
  TrendingUp as TrendingUpIcon,
  CheckCircle as CheckCircleIcon,
  ArrowForward as ArrowForwardIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { colors, gradients, glassCard, glassCardHover } from '../constants/landingColors';
import { useScrollAnimation } from '../constants/landingAnimations';

const cards = [
  {
    icon: StarIcon,
    title: 'Notre Mission',
    description:
      'Simplifier la gestion quotidienne des ateliers de réparation grâce à une solution moderne et intuitive. Nous comprenons les défis des techniciens et propriétaires d\'ateliers.',
  },
  {
    icon: TrendingUpIcon,
    title: 'Notre Vision',
    description:
      'Devenir la référence en matière de gestion d\'atelier, en accompagnant la transformation digitale des professionnels de la réparation.',
  },
  {
    icon: CheckCircleIcon,
    title: 'Nos Valeurs',
    description:
      'Innovation, simplicité, fiabilité et accompagnement personnalisé sont au cœur de notre démarche pour vous offrir la meilleure expérience possible.',
  },
];

const AboutSection: React.FC = () => {
  const navigate = useNavigate();
  const { ref, isVisible } = useScrollAnimation();

  const handleAccessApp = () => navigate('/auth');

  return (
    <Box
      id="about"
      ref={ref}
      sx={{
        background: colors.navy.deep,
        py: { xs: 8, md: 12 },
        position: 'relative',
      }}
    >
      <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 } }}>
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
            Notre{' '}
            <Box component="span" sx={{ color: colors.gold.primary }}>
              Histoire
            </Box>
          </Typography>
          <Typography
            sx={{
              color: colors.text.muted,
              fontSize: { xs: '1rem', md: '1.15rem' },
              maxWidth: 500,
              mx: 'auto',
              fontFamily: '"Inter", sans-serif',
            }}
          >
            Une solution pensée par des professionnels, pour des professionnels
          </Typography>
        </Box>

        {/* Mission / Vision / Values cards */}
        <Grid container spacing={3} sx={{ mb: { xs: 6, md: 8 } }}>
          {cards.map((card, index) => {
            const IconComponent = card.icon;
            return (
              <Grid item xs={12} md={4} key={card.title}>
                <Box
                  sx={{
                    ...glassCard,
                    p: { xs: 3.5, md: 4 },
                    height: '100%',
                    transition: 'all 0.3s ease',
                    opacity: isVisible ? 1 : 0,
                    transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
                    transitionDelay: `${0.1 + index * 0.12}s`,
                    '&:hover': {
                      ...glassCardHover,
                      transform: 'translateY(-6px)',
                    },
                  }}
                >
                  <Box
                    sx={{
                      width: 50,
                      height: 50,
                      borderRadius: '50%',
                      background: colors.gold.subtle,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      mb: 2.5,
                    }}
                  >
                    <IconComponent sx={{ color: colors.gold.primary, fontSize: 24 }} />
                  </Box>
                  <Typography
                    variant="h5"
                    sx={{
                      fontFamily: '"Outfit", sans-serif',
                      fontWeight: 700,
                      color: colors.text.white,
                      mb: 1.5,
                      fontSize: { xs: '1.15rem', md: '1.3rem' },
                    }}
                  >
                    {card.title}
                  </Typography>
                  <Typography
                    sx={{
                      color: colors.text.muted,
                      lineHeight: 1.7,
                      fontFamily: '"Inter", sans-serif',
                      fontSize: '0.95rem',
                    }}
                  >
                    {card.description}
                  </Typography>
                </Box>
              </Grid>
            );
          })}
        </Grid>

        {/* CTA */}
        <Box
          sx={{
            textAlign: 'center',
            opacity: isVisible ? 1 : 0,
            transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
            transition: 'all 0.6s ease-out 0.5s',
          }}
        >
          <Typography
            variant="h4"
            sx={{
              fontFamily: '"Outfit", sans-serif',
              fontWeight: 700,
              color: colors.text.white,
              mb: 2,
              fontSize: { xs: '1.5rem', md: '2rem' },
            }}
          >
            Prêt à Optimiser Votre Atelier ?
          </Typography>
          <Typography
            sx={{
              color: colors.text.muted,
              mb: 4,
              fontSize: '1rem',
              maxWidth: 500,
              mx: 'auto',
              fontFamily: '"Inter", sans-serif',
            }}
          >
            Rejoignez les ateliers qui ont déjà transformé leur gestion quotidienne.
          </Typography>
          <Button
            variant="contained"
            size="large"
            onClick={handleAccessApp}
            sx={{
              background: gradients.gold,
              color: colors.navy.deep,
              px: { xs: 5, md: 6 },
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
            Découvrir la Solution
          </Button>
        </Box>
      </Container>
    </Box>
  );
};

export default AboutSection;

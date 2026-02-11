import React from 'react';
import { Box, Container, Typography, Grid } from '@mui/material';
import { Star as StarIcon } from '@mui/icons-material';
import { colors, glassCard } from '../constants/landingColors';
import { useScrollAnimation } from '../constants/landingAnimations';

// TODO: Remplacer par de vrais témoignages clients
const testimonials = [
  {
    name: 'Marc C.',
    role: 'Gérant, TechRepair Lyon',
    quote:
      "Depuis qu'on utilise Atelier Gestion, on a réduit notre temps administratif de moitié. Le Kanban est un vrai game-changer.",
    initials: 'MC',
  },
  {
    name: 'Sophie L.',
    role: 'Technicienne, iFix Paris',
    quote:
      "L'interface est intuitive et le suivi client est impeccable. Mes clients reçoivent des notifications en temps réel.",
    initials: 'SL',
  },
  {
    name: 'Karim B.',
    role: 'Fondateur, PhoneClinic Marseille',
    quote:
      "La gestion des stocks et la facturation intégrée m'ont permis de professionnaliser mon atelier en quelques semaines.",
    initials: 'KB',
  },
];

const SocialProofSection: React.FC = () => {
  const { ref, isVisible } = useScrollAnimation();

  return (
    <Box
      ref={ref}
      sx={{
        background: colors.navy.dark,
        py: { xs: 8, md: 10 },
        position: 'relative',
      }}
    >
      <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 } }}>
        {/* Counter */}
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
            sx={{
              fontFamily: '"Outfit", sans-serif',
              fontWeight: 700,
              fontSize: { xs: '1.8rem', md: '2.5rem' },
              color: colors.text.white,
            }}
          >
            Fait confiance par{' '}
            <Box component="span" sx={{ color: colors.gold.primary }}>
              +200
            </Box>{' '}
            ateliers en France
          </Typography>
        </Box>

        {/* Testimonials */}
        <Grid container spacing={3}>
          {testimonials.map((t, index) => (
            <Grid item xs={12} md={4} key={t.name}>
              <Box
                sx={{
                  ...glassCard,
                  p: { xs: 3, md: 3.5 },
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  opacity: isVisible ? 1 : 0,
                  transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
                  transition: `all 0.6s ease-out ${0.1 + index * 0.15}s`,
                }}
              >
                {/* Stars */}
                <Box sx={{ display: 'flex', gap: 0.5, mb: 2 }}>
                  {[...Array(5)].map((_, i) => (
                    <StarIcon
                      key={i}
                      sx={{ fontSize: 18, color: colors.gold.primary }}
                    />
                  ))}
                </Box>

                {/* Quote */}
                <Typography
                  sx={{
                    color: colors.text.light,
                    fontFamily: '"Inter", sans-serif',
                    fontStyle: 'italic',
                    fontSize: '0.95rem',
                    lineHeight: 1.7,
                    flex: 1,
                    mb: 3,
                  }}
                >
                  "{t.quote}"
                </Typography>

                {/* Author */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Box
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: '50%',
                      background: `linear-gradient(135deg, ${colors.gold.primary}, ${colors.gold.dark})`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Typography
                      sx={{
                        fontSize: '0.8rem',
                        fontWeight: 700,
                        color: colors.navy.deep,
                        fontFamily: '"Outfit", sans-serif',
                      }}
                    >
                      {t.initials}
                    </Typography>
                  </Box>
                  <Box>
                    <Typography
                      sx={{
                        fontWeight: 600,
                        fontSize: '0.9rem',
                        color: colors.text.white,
                        fontFamily: '"Outfit", sans-serif',
                      }}
                    >
                      {t.name}
                    </Typography>
                    <Typography
                      sx={{
                        fontSize: '0.75rem',
                        color: colors.text.dim,
                        fontFamily: '"Inter", sans-serif',
                      }}
                    >
                      {t.role}
                    </Typography>
                  </Box>
                </Box>
              </Box>
            </Grid>
          ))}
        </Grid>
      </Container>
    </Box>
  );
};

export default SocialProofSection;

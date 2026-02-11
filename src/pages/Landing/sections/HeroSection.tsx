import React from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Stack,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import {
  ArrowForward as ArrowForwardIcon,
  CheckCircle as CheckCircleIcon,
  Search as SearchIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { colors, gradients } from '../constants/landingColors';
import { useScrollAnimation, animations } from '../constants/landingAnimations';

const HeroSection: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const { ref, isVisible } = useScrollAnimation(0.1);

  const handleAccessApp = () => navigate('/auth');
  const handleRepairTracking = () => navigate('/repair-tracking');

  return (
    <Box
      id="home"
      ref={ref}
      sx={{
        background: gradients.navyBg,
        color: colors.text.white,
        minHeight: '100vh',
        pt: { xs: 12, md: 0 },
        pb: { xs: 6, md: 0 },
        position: 'relative',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        // Mesh gradient overlay
        '&::before': {
          content: '""',
          position: 'absolute',
          inset: 0,
          background: gradients.heroMesh,
          zIndex: 1,
        },
      }}
    >
      {/* Dot grid pattern */}
      <Box
        sx={{
          position: 'absolute',
          inset: 0,
          background: `url("data:image/svg+xml,%3Csvg width='40' height='40' viewBox='0 0 40 40' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none'%3E%3Cg fill='%23ffffff' fill-opacity='0.03'%3E%3Ccircle cx='20' cy='20' r='1'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
          backgroundSize: '40px 40px',
          zIndex: 1,
        }}
      />

      <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 2, px: { xs: 2, md: 3 } }}>
        <Box
          sx={{
            display: 'flex',
            flexDirection: { xs: 'column', md: 'row' },
            alignItems: 'center',
            gap: { xs: 4, md: 6 },
          }}
        >
          {/* Left - Content */}
          <Box
            sx={{
              flex: { md: '0 0 55%' },
              opacity: isVisible ? 1 : 0,
              transform: isVisible ? 'translateY(0)' : 'translateY(30px)',
              transition: 'all 0.8s ease-out',
            }}
          >
            {/* Title */}
            <Typography
              variant="h1"
              component="h1"
              sx={{
                fontFamily: '"Outfit", sans-serif',
                fontWeight: 800,
                mb: { xs: 2, md: 3 },
                fontSize: { xs: '2.5rem', sm: '3.2rem', md: '4rem', lg: '5.5rem' },
                lineHeight: 1.05,
                textAlign: { xs: 'center', md: 'left' },
                color: colors.text.white,
              }}
            >
              Gérez Votre Atelier{' '}
              <br />
              Comme un{' '}
              <Box
                component="span"
                sx={{
                  background: gradients.goldText,
                  backgroundClip: 'text',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                }}
              >
                Pro
              </Box>
            </Typography>

            {/* Subtitle */}
            <Typography
              variant="h5"
              sx={{
                mb: { xs: 3, md: 4 },
                color: colors.text.muted,
                fontFamily: '"Inter", sans-serif',
                fontWeight: 400,
                fontSize: { xs: '1rem', sm: '1.1rem', md: '1.25rem' },
                lineHeight: 1.6,
                maxWidth: 520,
                textAlign: { xs: 'center', md: 'left' },
              }}
            >
              La solution complète pour gérer votre atelier de réparation d'appareils électroniques
            </Typography>

            {/* 3 feature highlights */}
            <Box sx={{ mb: { xs: 3, md: 4 } }}>
              <Stack
                direction={{ xs: 'column', sm: 'row' }}
                spacing={{ xs: 1, sm: 3 }}
                alignItems={{ xs: 'center', sm: 'flex-start' }}
              >
                {['Gestion complète', 'Interface intuitive', 'Temps réel'].map((text) => (
                  <Box key={text} sx={{ display: 'flex', alignItems: 'center' }}>
                    <CheckCircleIcon
                      sx={{ mr: 1, fontSize: 20, color: colors.gold.primary }}
                    />
                    <Typography
                      variant="body1"
                      sx={{
                        fontWeight: 500,
                        fontSize: { xs: '0.9rem', md: '1rem' },
                        color: colors.text.light,
                      }}
                    >
                      {text}
                    </Typography>
                  </Box>
                ))}
              </Stack>
            </Box>

            {/* CTA Buttons */}
            <Box
              sx={{
                display: 'flex',
                flexDirection: { xs: 'column', sm: 'row' },
                gap: 2,
                mb: { xs: 4, md: 5 },
                justifyContent: { xs: 'center', md: 'flex-start' },
              }}
            >
              <Button
                variant="contained"
                size="large"
                onClick={handleAccessApp}
                sx={{
                  background: gradients.gold,
                  color: colors.navy.deep,
                  px: { xs: 4, md: 5 },
                  py: { xs: 1.5, md: 2 },
                  fontSize: { xs: '1rem', md: '1.1rem' },
                  fontWeight: 700,
                  fontFamily: '"Inter", sans-serif',
                  borderRadius: '12px',
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
                Commencer
              </Button>
              <Button
                variant="outlined"
                size="large"
                onClick={handleRepairTracking}
                sx={{
                  color: colors.text.muted,
                  borderColor: colors.glass.border,
                  px: { xs: 3, md: 4 },
                  py: { xs: 1.5, md: 2 },
                  fontSize: { xs: '0.95rem', md: '1rem' },
                  fontWeight: 600,
                  fontFamily: '"Inter", sans-serif',
                  borderRadius: '12px',
                  textTransform: 'none',
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    borderColor: colors.text.muted,
                    color: colors.text.white,
                    background: 'rgba(148, 163, 184, 0.1)',
                  },
                }}
                startIcon={<SearchIcon />}
              >
                Suivre une Réparation
              </Button>
            </Box>

            {/* Stats */}
            <Box
              sx={{
                display: 'flex',
                gap: { xs: 3, md: 0 },
                justifyContent: { xs: 'center', md: 'flex-start' },
              }}
            >
              {[
                { value: '100%', label: 'SATISFACTION' },
                { value: '50%', label: 'GAIN DE TEMPS' },
                { value: '24/7', label: 'DISPONIBLE' },
              ].map((stat, i) => (
                <React.Fragment key={stat.label}>
                  {i > 0 && (
                    <Box
                      sx={{
                        display: { xs: 'none', md: 'block' },
                        width: '1px',
                        height: 50,
                        background: 'rgba(148, 163, 184, 0.2)',
                        mx: 4,
                        alignSelf: 'center',
                      }}
                    />
                  )}
                  <Box sx={{ textAlign: 'center' }}>
                    <Typography
                      sx={{
                        fontFamily: '"Outfit", sans-serif',
                        fontWeight: 700,
                        fontSize: { xs: '1.5rem', md: '2rem' },
                        color: colors.text.white,
                        lineHeight: 1,
                      }}
                    >
                      {stat.value}
                    </Typography>
                    <Typography
                      sx={{
                        fontFamily: '"Inter", sans-serif',
                        fontSize: '0.7rem',
                        fontWeight: 600,
                        letterSpacing: '0.1em',
                        color: colors.text.dim,
                        mt: 0.5,
                      }}
                    >
                      {stat.label}
                    </Typography>
                  </Box>
                </React.Fragment>
              ))}
            </Box>
          </Box>

          {/* Right - App Mockup */}
          {!isMobile && (
            <Box
              sx={{
                flex: { md: '0 0 42%' },
                opacity: isVisible ? 1 : 0,
                transform: isVisible ? 'translateY(0)' : 'translateY(30px)',
                transition: 'opacity 1s ease-out 0.3s, transform 1s ease-out 0.3s',
              }}
            >
              {/* Wrapper: seule cette box est animée (pas de repaint) */}
              <Box
                sx={{
                  animation: animations.float,
                  willChange: 'transform',
                }}
              >
              {/* Card visuelle: statique, effets visuels lourds isolés */}
              <Box
                sx={{
                  background: 'rgba(30, 41, 59, 0.7)',
                  border: `1px solid ${colors.glass.border}`,
                  borderRadius: '20px',
                  p: 0,
                  overflow: 'hidden',
                  boxShadow: '0 30px 60px rgba(0,0,0,0.3)',
                }}
              >
                {/* Window title bar */}
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 1,
                    px: 2,
                    py: 1.5,
                    borderBottom: `1px solid ${colors.glass.border}`,
                    background: 'rgba(15, 23, 42, 0.5)',
                  }}
                >
                  <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: '#ef4444' }} />
                  <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: '#f59e0b' }} />
                  <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: '#22c55e' }} />
                  <Typography
                    sx={{
                      ml: 2,
                      fontSize: '0.7rem',
                      color: colors.text.dim,
                      fontFamily: '"JetBrains Mono", monospace',
                    }}
                  >
                    Atelier Gestion — Dashboard
                  </Typography>
                </Box>

                {/* Mini Kanban content */}
                <Box sx={{ p: 2.5 }}>
                  {/* Mini stat cards row */}
                  <Box sx={{ display: 'flex', gap: 1.5, mb: 2 }}>
                    {[
                      { label: 'En cours', count: '12', color: colors.gold.primary },
                      { label: 'Terminées', count: '45', color: '#22c55e' },
                      { label: 'En attente', count: '3', color: '#3b82f6' },
                    ].map((s) => (
                      <Box
                        key={s.label}
                        sx={{
                          flex: 1,
                          p: 1.5,
                          borderRadius: '10px',
                          background: 'rgba(15, 23, 42, 0.4)',
                          border: `1px solid ${colors.glass.border}`,
                        }}
                      >
                        <Typography
                          sx={{
                            fontSize: '1.2rem',
                            fontWeight: 700,
                            fontFamily: '"Outfit", sans-serif',
                            color: s.color,
                          }}
                        >
                          {s.count}
                        </Typography>
                        <Typography sx={{ fontSize: '0.6rem', color: colors.text.dim }}>
                          {s.label}
                        </Typography>
                      </Box>
                    ))}
                  </Box>

                  {/* Mini Kanban columns */}
                  <Box sx={{ display: 'flex', gap: 1.5 }}>
                    {[
                      {
                        title: 'Nouveau',
                        color: '#3b82f6',
                        items: ['iPhone 15 Pro', 'Samsung S24'],
                      },
                      {
                        title: 'En cours',
                        color: colors.gold.primary,
                        items: ['iPad Air', 'MacBook Pro'],
                      },
                      {
                        title: 'Terminé',
                        color: '#22c55e',
                        items: ['Pixel 8'],
                      },
                    ].map((col) => (
                      <Box
                        key={col.title}
                        sx={{
                          flex: 1,
                          borderRadius: '10px',
                          background: 'rgba(15, 23, 42, 0.3)',
                          p: 1,
                        }}
                      >
                        <Typography
                          sx={{
                            fontSize: '0.65rem',
                            fontWeight: 600,
                            color: col.color,
                            mb: 1,
                            textTransform: 'uppercase',
                            letterSpacing: '0.05em',
                          }}
                        >
                          {col.title}
                        </Typography>
                        {col.items.map((item) => (
                          <Box
                            key={item}
                            sx={{
                              p: 1,
                              mb: 0.5,
                              borderRadius: '6px',
                              background: 'rgba(30, 41, 59, 0.6)',
                              border: `1px solid ${colors.glass.border}`,
                            }}
                          >
                            <Typography sx={{ fontSize: '0.6rem', color: colors.text.muted }}>
                              {item}
                            </Typography>
                          </Box>
                        ))}
                      </Box>
                    ))}
                  </Box>
                </Box>
              </Box>
              </Box>
            </Box>
          )}
        </Box>
      </Container>
    </Box>
  );
};

export default HeroSection;

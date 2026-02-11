import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Chip,
  Grid,
} from '@mui/material';
import { colors, glassCard, glassCardHover } from '../constants/landingColors';
import { useScrollAnimation } from '../constants/landingAnimations';
import { featureCategories } from '../constants/featureData';

const FeaturesSection: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const { ref, isVisible } = useScrollAnimation();

  const activeCategory = featureCategories[activeTab];

  return (
    <Box
      id="features"
      ref={ref}
      sx={{
        background: colors.navy.deep,
        py: { xs: 8, md: 12 },
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Subtle background gradient */}
      <Box
        sx={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(ellipse at 50% 0%, rgba(245, 158, 11, 0.04) 0%, transparent 60%)',
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
            Fonctionnalités{' '}
            <Box component="span" sx={{ color: colors.gold.primary }}>
              Principales
            </Box>
          </Typography>
          <Typography
            sx={{
              color: colors.text.muted,
              fontSize: { xs: '1rem', md: '1.15rem' },
              maxWidth: 550,
              mx: 'auto',
              fontFamily: '"Inter", sans-serif',
            }}
          >
            18 modules intégrés pour couvrir tous les besoins de votre atelier
          </Typography>
        </Box>

        {/* Tab chips */}
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            flexWrap: 'wrap',
            gap: 1.5,
            mb: { xs: 4, md: 6 },
            opacity: isVisible ? 1 : 0,
            transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
            transition: 'all 0.6s ease-out 0.15s',
          }}
        >
          {featureCategories.map((cat, index) => (
            <Chip
              key={cat.id}
              label={cat.label}
              clickable
              onClick={() => setActiveTab(index)}
              sx={{
                px: 2,
                py: 2.5,
                fontSize: { xs: '0.85rem', md: '0.95rem' },
                fontWeight: 600,
                fontFamily: '"Inter", sans-serif',
                borderRadius: '10px',
                transition: 'all 0.3s ease',
                ...(activeTab === index
                  ? {
                      background: `linear-gradient(135deg, ${colors.gold.primary}, ${colors.gold.dark})`,
                      color: colors.navy.deep,
                      boxShadow: `0 4px 20px ${colors.gold.glow}`,
                      '&:hover': {
                        background: `linear-gradient(135deg, ${colors.gold.light}, ${colors.gold.primary})`,
                      },
                    }
                  : {
                      background: colors.glass.bg,
                      color: colors.text.muted,
                      border: `1px solid ${colors.glass.border}`,
                      '&:hover': {
                        borderColor: colors.text.dim,
                        color: colors.text.white,
                        background: 'rgba(30, 41, 59, 0.7)',
                      },
                    }),
              }}
            />
          ))}
        </Box>

        {/* Feature Cards Grid */}
        <Grid
          container
          spacing={3}
          sx={{
            opacity: isVisible ? 1 : 0,
            transform: isVisible ? 'translateY(0)' : 'translateY(20px)',
            transition: 'all 0.6s ease-out 0.3s',
          }}
        >
          {activeCategory.features.map((feature, index) => {
            const IconComponent = feature.icon;
            return (
              <Grid item xs={12} sm={6} key={`${activeCategory.id}-${index}`}>
                <Box
                  sx={{
                    ...glassCard,
                    p: { xs: 3, md: 3.5 },
                    height: '100%',
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: 2.5,
                    transition: 'all 0.3s ease',
                    cursor: 'default',
                    '&:hover': {
                      ...glassCardHover,
                      transform: 'translateY(-4px)',
                    },
                  }}
                >
                  <Box
                    sx={{
                      width: 48,
                      height: 48,
                      borderRadius: '12px',
                      background: colors.gold.subtle,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                    }}
                  >
                    <IconComponent sx={{ fontSize: 26, color: colors.gold.primary }} />
                  </Box>
                  <Box>
                    <Typography
                      variant="h6"
                      sx={{
                        fontFamily: '"Outfit", sans-serif',
                        fontWeight: 600,
                        color: colors.text.white,
                        fontSize: { xs: '1.05rem', md: '1.15rem' },
                        mb: 0.5,
                      }}
                    >
                      {feature.title}
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
                      {feature.description}
                    </Typography>
                  </Box>
                </Box>
              </Grid>
            );
          })}
        </Grid>
      </Container>
    </Box>
  );
};

export default FeaturesSection;

import React from 'react';
import { Box } from '@mui/material';
import LandingNavbar from '../../components/LandingNavbar';
import HeroSection from './sections/HeroSection';
import FeaturesSection from './sections/FeaturesSection';

import BenefitsSection from './sections/BenefitsSection';
import PricingSection from './sections/PricingSection';
import AboutSection from './sections/AboutSection';
import FooterSection from './sections/FooterSection';
import { useLandingAnimations } from './constants/landingAnimations';

const Landing: React.FC = () => {
  useLandingAnimations();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        bgcolor: '#0f172a',
        position: 'relative',
        // Subtle noise overlay
        '&::after': {
          content: '""',
          position: 'fixed',
          inset: 0,
          opacity: 0.03,
          pointerEvents: 'none',
          zIndex: 9999,
          background: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")`,
        },
      }}
    >
      <LandingNavbar />
      <HeroSection />
      <FeaturesSection />

      <BenefitsSection />
      <PricingSection />
      <AboutSection />
      <FooterSection />
    </Box>
  );
};

export default Landing;

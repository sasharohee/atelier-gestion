import React from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Stack,
  Link,
} from '@mui/material';
import { Build as BuildIcon } from '@mui/icons-material';
import { colors, gradients } from '../constants/landingColors';

const FooterSection: React.FC = () => {
  return (
    <Box
      sx={{
        background: colors.navy.darker,
        color: colors.text.white,
        py: { xs: 5, md: 7 },
        position: 'relative',
        // Gold gradient line on top
        '&::before': {
          content: '""',
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          height: '1px',
          background: gradients.footerLine,
        },
      }}
    >
      <Container maxWidth="lg" sx={{ px: { xs: 2, md: 3 } }}>
        <Grid container spacing={{ xs: 4, md: 5 }}>
          {/* Company Info */}
          <Grid item xs={12} md={4}>
            <Box sx={{ mb: 3 }}>
              {/* Logo */}
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Box
                  sx={{
                    width: 36,
                    height: 36,
                    borderRadius: '50%',
                    background: colors.gold.subtle,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mr: 1.5,
                  }}
                >
                  <BuildIcon sx={{ fontSize: 18, color: colors.gold.primary }} />
                </Box>
                <Typography
                  variant="h6"
                  sx={{
                    fontFamily: '"Outfit", sans-serif',
                    fontWeight: 700,
                    background: gradients.goldText,
                    backgroundClip: 'text',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                  }}
                >
                  Atelier Gestion
                </Typography>
              </Box>
              <Typography
                variant="body2"
                sx={{
                  color: colors.text.dim,
                  lineHeight: 1.7,
                  mb: 3,
                  fontFamily: '"Inter", sans-serif',
                  fontSize: '0.85rem',
                }}
              >
                Solution complète de gestion d'atelier avec 18 modules intégrés : suivi Kanban, SAV, calendrier,
                clients, inventaire, facturation, devis, statistiques et bien plus.
              </Typography>
              {/* Social icons */}
              <Box sx={{ display: 'flex', gap: 1.5 }}>
                {[
                  { emoji: '\u{1F4E7}', label: 'Email' },
                  { emoji: '\u{1F4DE}', label: 'Phone' },
                  { emoji: '\u{1F4AC}', label: 'Chat' },
                ].map((item) => (
                  <Box
                    key={item.label}
                    sx={{
                      width: 38,
                      height: 38,
                      borderRadius: '50%',
                      border: `1px solid ${colors.glass.border}`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        borderColor: colors.gold.primary,
                        background: colors.gold.subtle,
                      },
                    }}
                  >
                    <Typography sx={{ fontSize: '0.9rem' }}>{item.emoji}</Typography>
                  </Box>
                ))}
              </Box>
            </Box>
          </Grid>

          {/* Support */}
          <Grid item xs={6} md={2}>
            <Typography
              variant="subtitle1"
              sx={{
                fontFamily: '"Outfit", sans-serif',
                fontWeight: 600,
                color: colors.text.white,
                mb: 2.5,
                fontSize: '0.95rem',
              }}
            >
              Support
            </Typography>
            <Stack spacing={1.5}>
              {[
                { name: 'Contact Support', path: '/support' },
                { name: 'FAQ', path: '/faq' },
              ].map((link) => (
                <Link
                  key={link.name}
                  href={link.path}
                  sx={{
                    color: colors.text.dim,
                    textDecoration: 'none',
                    transition: 'all 0.3s ease',
                    fontSize: '0.85rem',
                    fontFamily: '"Inter", sans-serif',
                    '&:hover': {
                      color: colors.gold.primary,
                    },
                  }}
                >
                  {link.name}
                </Link>
              ))}
            </Stack>
          </Grid>

          {/* Legal */}
          <Grid item xs={6} md={3}>
            <Typography
              variant="subtitle1"
              sx={{
                fontFamily: '"Outfit", sans-serif',
                fontWeight: 600,
                color: colors.text.white,
                mb: 2.5,
                fontSize: '0.95rem',
              }}
            >
              Légal
            </Typography>
            <Stack spacing={1.5}>
              {[
                { name: "Conditions d'Utilisation", path: '/terms-of-service' },
                { name: 'Politique de Confidentialité', path: '/privacy-policy' },
                { name: 'CGV', path: '/cgv' },
                { name: 'RGPD', path: '/rgpd' },
              ].map((link) => (
                <Link
                  key={link.name}
                  href={link.path}
                  sx={{
                    color: colors.text.dim,
                    textDecoration: 'none',
                    transition: 'all 0.3s ease',
                    fontSize: '0.85rem',
                    fontFamily: '"Inter", sans-serif',
                    '&:hover': {
                      color: colors.gold.primary,
                    },
                  }}
                >
                  {link.name}
                </Link>
              ))}
            </Stack>
          </Grid>

          {/* Contact */}
          <Grid item xs={12} md={3}>
            <Typography
              variant="subtitle1"
              sx={{
                fontFamily: '"Outfit", sans-serif',
                fontWeight: 600,
                color: colors.text.white,
                mb: 2.5,
                fontSize: '0.95rem',
              }}
            >
              Contact
            </Typography>
            <Stack spacing={1.5}>
              {[
                { icon: '\u{1F4E7}', text: 'contact.ateliergestion@gmail.com' },
                { icon: '\u{1F4DE}', text: '07 59 23 91 70' },
                { icon: '\u{1F4CD}', text: 'France' },
              ].map((item) => (
                <Box key={item.text} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Typography sx={{ fontSize: '0.85rem' }}>{item.icon}</Typography>
                  <Typography
                    sx={{
                      color: colors.text.dim,
                      fontSize: '0.8rem',
                      fontFamily: '"Inter", sans-serif',
                    }}
                  >
                    {item.text}
                  </Typography>
                </Box>
              ))}
            </Stack>
          </Grid>
        </Grid>

        {/* Bottom bar */}
        <Box
          sx={{
            mt: 5,
            pt: 3,
            borderTop: `1px solid ${colors.glass.border}`,
            display: 'flex',
            flexDirection: { xs: 'column', md: 'row' },
            justifyContent: 'space-between',
            alignItems: 'center',
            gap: 2,
          }}
        >
          <Typography
            variant="body2"
            sx={{
              color: colors.text.dim,
              fontSize: '0.8rem',
              fontFamily: '"Inter", sans-serif',
            }}
          >
            &copy; {new Date().getFullYear()} Atelier Gestion. Tous droits réservés.
          </Typography>
          <Box sx={{ display: 'flex', gap: 3 }}>
            {[
              { name: 'Politique de Confidentialité', path: '/privacy-policy' },
              { name: "Conditions d'Utilisation", path: '/terms-of-service' },
            ].map((link) => (
              <Link
                key={link.name}
                href={link.path}
                sx={{
                  color: colors.text.dim,
                  textDecoration: 'none',
                  fontSize: '0.8rem',
                  fontFamily: '"Inter", sans-serif',
                  transition: 'color 0.3s ease',
                  '&:hover': { color: colors.gold.primary },
                }}
              >
                {link.name}
              </Link>
            ))}
          </Box>
        </Box>
      </Container>
    </Box>
  );
};

export default FooterSection;

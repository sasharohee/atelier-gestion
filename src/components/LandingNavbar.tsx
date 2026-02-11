import React, { useState, useEffect } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Box,
  Container,
  IconButton,
  Drawer,
  List,
  ListItem,
  ListItemText,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  Build as BuildIcon,
  Menu as MenuIcon,
  Close as CloseIcon,
  ArrowForward as ArrowForwardIcon,
  Search as SearchIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const GOLD = '#f59e0b';
const GOLD_DARK = '#d97706';
const NAVY = '#0f172a';
const NAVY_DARK = '#0b1120';

const LandingNavbar: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 50);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleDrawerToggle = () => setMobileOpen(!mobileOpen);
  const handleAccessApp = () => navigate('/auth');
  const handleRepairTracking = () => navigate('/repair-tracking');

  const menuItems = [
    { label: 'Fonctionnalités', href: '#features' },
    { label: 'Avantages', href: '#benefits' },
    { label: 'Tarifs', href: '#pricing' },
  ];

  const scrollToSection = (href: string) => {
    const el = document.querySelector(href);
    if (el) el.scrollIntoView({ behavior: 'smooth' });
    setMobileOpen(false);
  };

  const drawer = (
    <Box
      sx={{
        width: 280,
        pt: 2,
        height: '100%',
        background: NAVY_DARK,
      }}
    >
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', px: 2, mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <Box
            sx={{
              width: 32,
              height: 32,
              borderRadius: '50%',
              background: 'rgba(245, 158, 11, 0.15)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              mr: 1.5,
            }}
          >
            <BuildIcon sx={{ fontSize: 16, color: GOLD }} />
          </Box>
          <Typography
            variant="h6"
            sx={{
              fontFamily: '"Outfit", sans-serif',
              fontWeight: 700,
              color: '#fff',
              fontSize: '1rem',
            }}
          >
            Atelier Gestion
          </Typography>
        </Box>
        <IconButton onClick={handleDrawerToggle} sx={{ color: '#94a3b8' }}>
          <CloseIcon />
        </IconButton>
      </Box>
      <List>
        {menuItems.map((item) => (
          <ListItem
            key={item.label}
            component="li"
            onClick={() => scrollToSection(item.href)}
            sx={{
              py: 2,
              cursor: 'pointer',
              '&:hover': { background: 'rgba(148, 163, 184, 0.08)' },
            }}
          >
            <ListItemText
              primary={item.label}
              sx={{
                '& .MuiListItemText-primary': {
                  fontWeight: 500,
                  fontSize: '1rem',
                  color: '#94a3b8',
                  fontFamily: '"Inter", sans-serif',
                },
              }}
            />
          </ListItem>
        ))}
        <ListItem sx={{ pt: 3, flexDirection: 'column', gap: 1.5 }}>
          <Button
            variant="outlined"
            fullWidth
            onClick={handleRepairTracking}
            startIcon={<SearchIcon />}
            sx={{
              py: 1.5,
              fontWeight: 600,
              borderRadius: '10px',
              color: '#94a3b8',
              borderColor: 'rgba(148, 163, 184, 0.2)',
              fontFamily: '"Inter", sans-serif',
              textTransform: 'none',
              '&:hover': {
                borderColor: '#94a3b8',
                color: '#fff',
                background: 'rgba(148, 163, 184, 0.08)',
              },
            }}
          >
            Suivre Réparation
          </Button>
          <Button
            variant="contained"
            fullWidth
            onClick={handleAccessApp}
            endIcon={<ArrowForwardIcon />}
            sx={{
              py: 1.5,
              fontWeight: 700,
              borderRadius: '10px',
              background: `linear-gradient(135deg, ${GOLD}, ${GOLD_DARK})`,
              color: NAVY,
              fontFamily: '"Inter", sans-serif',
              textTransform: 'none',
              '&:hover': {
                background: `linear-gradient(135deg, #fbbf24, ${GOLD})`,
              },
            }}
          >
            Accéder à l'App
          </Button>
        </ListItem>
      </List>
    </Box>
  );

  return (
    <>
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          background: scrolled ? `rgba(15, 23, 42, 0.95)` : `rgba(15, 23, 42, 0.7)`,
          backdropFilter: 'blur(20px)',
          borderBottom: `1px solid rgba(148, 163, 184, ${scrolled ? '0.1' : '0.05'})`,
          borderRadius: '50px',
          margin: '0 20px',
          marginTop: '10px',
          left: '20px',
          right: '20px',
          width: 'auto',
          top: '10px',
          zIndex: 1200,
          transition: 'all 0.3s ease',
          boxShadow: scrolled ? '0 4px 30px rgba(0, 0, 0, 0.3)' : 'none',
        }}
      >
        <Container maxWidth="lg" sx={{ px: 0 }}>
          <Toolbar sx={{ px: { xs: 2, md: 3 } }}>
            {/* Logo */}
            <Box sx={{ flexGrow: 1 }}>
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  textDecoration: 'none',
                  cursor: 'pointer',
                  py: 1,
                }}
                onClick={() => scrollToSection('#home')}
              >
                <Box
                  sx={{
                    width: 36,
                    height: 36,
                    borderRadius: '50%',
                    background: 'rgba(245, 158, 11, 0.15)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mr: 1.5,
                  }}
                >
                  <BuildIcon sx={{ fontSize: 20, color: GOLD }} />
                </Box>
                <Typography
                  variant="h6"
                  sx={{
                    fontFamily: '"Outfit", sans-serif',
                    fontWeight: 700,
                    color: '#ffffff',
                    fontSize: { xs: '1rem', md: '1.15rem' },
                  }}
                >
                  Atelier Gestion
                </Typography>
              </Box>
            </Box>

            {/* Desktop Menu */}
            {!isMobile && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                {menuItems.map((item) => (
                  <Button
                    key={item.label}
                    onClick={() => scrollToSection(item.href)}
                    sx={{
                      color: '#94a3b8',
                      fontWeight: 500,
                      fontSize: '0.9rem',
                      fontFamily: '"Inter", sans-serif',
                      textTransform: 'none',
                      px: 2,
                      py: 1,
                      borderRadius: '10px',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        color: '#ffffff',
                        background: 'rgba(148, 163, 184, 0.08)',
                      },
                    }}
                  >
                    {item.label}
                  </Button>
                ))}
                <Button
                  variant="outlined"
                  onClick={handleRepairTracking}
                  startIcon={<SearchIcon sx={{ fontSize: 18 }} />}
                  sx={{
                    ml: 2,
                    color: '#94a3b8',
                    borderColor: 'rgba(148, 163, 184, 0.2)',
                    px: 2.5,
                    py: 1,
                    fontWeight: 600,
                    borderRadius: '10px',
                    fontSize: '0.85rem',
                    fontFamily: '"Inter", sans-serif',
                    textTransform: 'none',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      borderColor: '#94a3b8',
                      color: '#ffffff',
                      background: 'rgba(148, 163, 184, 0.08)',
                    },
                  }}
                >
                  Suivre Réparation
                </Button>
                <Button
                  variant="contained"
                  onClick={handleAccessApp}
                  endIcon={<ArrowForwardIcon sx={{ fontSize: 18 }} />}
                  sx={{
                    ml: 1,
                    background: `linear-gradient(135deg, ${GOLD}, ${GOLD_DARK})`,
                    color: NAVY,
                    px: 3,
                    py: 1,
                    fontWeight: 700,
                    borderRadius: '10px',
                    fontSize: '0.85rem',
                    fontFamily: '"Inter", sans-serif',
                    textTransform: 'none',
                    boxShadow: `0 4px 20px rgba(245, 158, 11, 0.25)`,
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      background: `linear-gradient(135deg, #fbbf24, ${GOLD})`,
                      transform: 'translateY(-1px)',
                      boxShadow: `0 6px 24px rgba(245, 158, 11, 0.35)`,
                    },
                  }}
                >
                  Accéder à l'App
                </Button>
              </Box>
            )}

            {/* Mobile Menu Button */}
            {isMobile && (
              <IconButton
                aria-label="open drawer"
                edge="end"
                onClick={handleDrawerToggle}
                sx={{ color: '#94a3b8' }}
              >
                <MenuIcon />
              </IconButton>
            )}
          </Toolbar>
        </Container>
      </AppBar>

      {/* Mobile Drawer */}
      <Drawer
        variant="temporary"
        anchor="right"
        open={mobileOpen}
        onClose={handleDrawerToggle}
        ModalProps={{ keepMounted: true }}
        sx={{
          display: { xs: 'block', md: 'none' },
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: 280,
            bgcolor: NAVY_DARK,
            borderLeft: '1px solid rgba(148, 163, 184, 0.1)',
          },
        }}
      >
        {drawer}
      </Drawer>
    </>
  );
};

export default LandingNavbar;

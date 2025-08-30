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
  Fade,
  Slide
} from '@mui/material';
import {
  Build as BuildIcon,
  Menu as MenuIcon,
  Close as CloseIcon,
  ArrowForward as ArrowForwardIcon
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

interface NavbarProps {
  transparent?: boolean;
}

const LandingNavbar: React.FC<NavbarProps> = ({ transparent = true }) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  // Handle scroll effect
  useEffect(() => {
    const handleScroll = () => {
      const isScrolled = window.scrollY > 50;
      setScrolled(isScrolled);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleAccessApp = () => {
    navigate('/app/dashboard');
  };

  const handleRepairTracking = () => {
    navigate('/repair-tracking');
  };

  const menuItems = [
    { label: 'Fonctionnalités', href: '#features' },
    { label: 'Avantages', href: '#benefits' },
    { label: 'Tarifs', href: '#pricing' }
  ];

  const scrollToSection = (href: string) => {
    const element = document.querySelector(href);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
    setMobileOpen(false);
  };

  const navbarStyle = {
    background: transparent && !scrolled 
      ? 'rgba(255, 255, 255, 0.9)' 
      : 'rgba(255, 255, 255, 0.95)',
    backdropFilter: 'blur(20px)',
    borderBottom: transparent && !scrolled 
      ? '1px solid rgba(255, 255, 255, 0.3)' 
      : '1px solid rgba(0, 0, 0, 0.1)',
    transition: 'all 0.3s ease',
    boxShadow: scrolled ? '0 4px 20px rgba(0, 0, 0, 0.15)' : '0 4px 15px rgba(0, 0, 0, 0.1)',
    borderRadius: '50px',
    margin: '0 20px',
    marginTop: '10px',
    '&:hover': {
      background: transparent && !scrolled 
        ? 'rgba(255, 255, 255, 1)' 
        : 'rgba(255, 255, 255, 1)',
      boxShadow: scrolled 
        ? '0 8px 30px rgba(0, 0, 0, 0.2)' 
        : '0 6px 20px rgba(0, 0, 0, 0.15)',
      transform: 'translateY(2px)'
    }
  };

  const logoStyle = {
    display: 'flex',
    alignItems: 'center',
    textDecoration: 'none',
    color: '#1976D2',
    textShadow: 'none',
    transition: 'all 0.3s ease',
    padding: '12px 18px',
    borderRadius: '50px',
    '&:hover': {
      color: '#1565C0',
      background: 'rgba(25, 118, 210, 0.1)',
      transform: 'scale(1.05)',
      boxShadow: '0 6px 20px rgba(0, 0, 0, 0.15)'
    }
  };

  const menuItemStyle = {
    color: transparent && !scrolled ? '#1976D2' : '#1976D2',
    fontWeight: 600,
    fontSize: '1rem',
    textShadow: 'none',
    transition: 'all 0.3s ease',
    padding: '12px 20px',
    borderRadius: '50px',
    margin: '0 4px',
    '&:hover': {
      color: '#1565C0',
      background: transparent && !scrolled 
        ? 'rgba(25, 118, 210, 0.1)' 
        : 'rgba(25, 118, 210, 0.15)',
      transform: 'translateY(-3px)',
      boxShadow: '0 6px 20px rgba(0, 0, 0, 0.2)'
    }
  };

  const drawer = (
    <Box sx={{ width: 280, pt: 2 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', px: 2, mb: 2 }}>
        <Box sx={logoStyle}>
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 36,
              height: 36,
              borderRadius: '50%',
              background: 'rgba(25, 118, 210, 0.1)',
              border: '2px solid #1976D2',
              mr: 1.5,
              transition: 'all 0.3s ease'
            }}
          >
            <BuildIcon 
              sx={{ 
                fontSize: 20, 
                color: '#1976D2'
              }} 
            />
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 700, color: '#1976D2' }}>
            Atelier Gestion
          </Typography>
        </Box>
        <IconButton onClick={handleDrawerToggle}>
          <CloseIcon />
        </IconButton>
      </Box>
      <List>
        {menuItems.map((item) => (
          <ListItem 
            key={item.label} 
            button 
            onClick={() => scrollToSection(item.href)}
            sx={{ py: 2 }}
          >
            <ListItemText 
              primary={item.label} 
              sx={{ 
                '& .MuiListItemText-primary': {
                  fontWeight: 500,
                  fontSize: '1.1rem'
                }
              }}
            />
          </ListItem>
        ))}
        <ListItem sx={{ pt: 2 }}>
          <Button
            variant="contained"
            fullWidth
            onClick={handleRepairTracking}
            sx={{
              py: 1.5,
              fontWeight: 600,
              borderRadius: 2,
              mb: 1,
              bgcolor: '#FF6B6B',
              color: 'white',
              boxShadow: '0 4px 15px rgba(255, 107, 107, 0.3)',
              '&:hover': {
                bgcolor: '#FF5252',
                boxShadow: '0 6px 20px rgba(255, 107, 107, 0.4)'
              }
            }}
          >
            Suivre ma Réparation
          </Button>
        </ListItem>
        <ListItem>
          <Button
            variant="contained"
            fullWidth
            onClick={handleAccessApp}
            sx={{
              py: 1.5,
              fontWeight: 600,
              borderRadius: 2
            }}
            endIcon={<ArrowForwardIcon />}
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
            ...navbarStyle,
            left: '20px',
            right: '20px',
            width: 'auto',
            top: '10px',
            zIndex: 1200
          }}
        >
        <Container maxWidth="lg" sx={{ px: 0 }}>
          <Toolbar sx={{ px: { xs: 2, md: 3 } }}>
            {/* Logo */}
            <Fade in timeout={800}>
                          <Box sx={{ flexGrow: 1 }}>
              <Box sx={logoStyle}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 40,
                    height: 40,
                    borderRadius: '50%',
                    background: transparent && !scrolled 
                      ? 'rgba(74, 144, 226, 0.2)' 
                      : 'rgba(25, 118, 210, 0.1)',
                    border: `2px solid ${transparent && !scrolled ? '#4A90E2' : '#1976D2'}`,
                    mr: 2,
                    transition: 'all 0.3s ease'
                  }}
                >
                  <BuildIcon 
                    sx={{ 
                      fontSize: 24, 
                      color: transparent && !scrolled ? '#4A90E2' : '#1976D2'
                    }} 
                  />
                </Box>
                <Typography 
                  variant="h6" 
                  sx={{ 
                    fontWeight: 700,
                    fontSize: { xs: '1.1rem', md: '1.25rem' }
                  }}
                >
                  Atelier Gestion
                </Typography>
              </Box>
            </Box>
            </Fade>

            {/* Desktop Menu */}
            {!isMobile && (
              <Fade in timeout={1000}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                  {menuItems.map((item) => (
                    <Button
                      key={item.label}
                      onClick={() => scrollToSection(item.href)}
                      sx={menuItemStyle}
                    >
                      {item.label}
                    </Button>
                  ))}
                  <Button
                    variant="contained"
                    onClick={handleRepairTracking}
                    sx={{
                      bgcolor: transparent && !scrolled ? 'rgba(255, 255, 255, 0.9)' : '#FF6B6B',
                      color: transparent && !scrolled ? '#1976D2' : 'white',
                      px: 3,
                      py: 1.5,
                      fontWeight: 600,
                      borderRadius: '50px',
                      fontSize: '0.9rem',
                      border: transparent && !scrolled ? '2px solid rgba(255, 255, 255, 0.3)' : 'none',
                      transition: 'all 0.3s ease',
                      boxShadow: transparent && !scrolled 
                        ? '0 4px 15px rgba(0, 0, 0, 0.15)' 
                        : '0 4px 15px rgba(255, 107, 107, 0.3)',
                      '&:hover': {
                        bgcolor: transparent && !scrolled ? 'rgba(255, 255, 255, 1)' : '#FF5252',
                        transform: 'translateY(-2px)',
                        boxShadow: transparent && !scrolled 
                          ? '0 6px 20px rgba(0, 0, 0, 0.2)' 
                          : '0 6px 20px rgba(255, 107, 107, 0.4)'
                      }
                    }}
                  >
                    Suivre Réparation
                  </Button>
                  <Button
                    variant="contained"
                    onClick={handleAccessApp}
                    sx={{
                      bgcolor: transparent && !scrolled ? 'white' : theme.palette.primary.main,
                      color: transparent && !scrolled ? theme.palette.primary.main : 'white',
                      px: 4,
                      py: 1.5,
                      fontWeight: 700,
                      borderRadius: '50px',
                      fontSize: '0.95rem',
                      boxShadow: transparent && !scrolled 
                        ? '0 4px 15px rgba(0, 0, 0, 0.2)' 
                        : '0 4px 15px rgba(0, 0, 0, 0.15)',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        bgcolor: transparent && !scrolled ? 'rgba(255, 255, 255, 0.95)' : theme.palette.primary.dark,
                        transform: 'translateY(-2px)',
                        boxShadow: transparent && !scrolled 
                          ? '0 6px 20px rgba(0, 0, 0, 0.3)' 
                          : '0 6px 20px rgba(0, 0, 0, 0.25)'
                      }
                    }}
                    endIcon={<ArrowForwardIcon />}
                  >
                    Accéder à l'App
                  </Button>
                </Box>
              </Fade>
            )}

            {/* Mobile Menu Button */}
            {isMobile && (
              <IconButton
                color="inherit"
                aria-label="open drawer"
                edge="end"
                onClick={handleDrawerToggle}
                sx={{ 
                  color: transparent && !scrolled ? 'white' : theme.palette.text.primary 
                }}
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
        ModalProps={{
          keepMounted: true // Better open performance on mobile.
        }}
        sx={{
          display: { xs: 'block', md: 'none' },
          '& .MuiDrawer-paper': { 
            boxSizing: 'border-box', 
            width: 280,
            bgcolor: 'background.paper'
          },
        }}
      >
        {drawer}
      </Drawer>


    </>
  );
};

export default LandingNavbar;
